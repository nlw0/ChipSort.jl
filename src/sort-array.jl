using SIMD

chipsort_small!(data::AbstractVector{T}, ::Val{V}, ::Val{J}) where {T,V,J} = sort_chunk!(data, Val(V), Val(J))

@generated function sort_chunk!(data::AbstractVector{T}, ::Val{V}, ::Val{J}) where {T,V,J}
    ex = [Expr(:meta, :inline)]

    for j in 1:J
        v = Symbol("input_", j)
        push!(ex, :($v = vload(Vec{V,T}, pointer(data, 1+($j-1)*V))))
    end
    vecs=[Symbol("input_", j) for j in 1:J]
    append!(ex, [
        :(output = merge_vecs(transpose_vecs(sort_net($(vecs...))...)...)),
        :(vstore(output, pointer(data, 1))),
        :(return data)
    ])
    quote $(ex...) end
end

function sort_chunks!(data::AbstractVector{T}, ::Val{L}, ::Val{N}) where {L,N,T}
    chunk_size = N*L
    num_chunks = div(length(data), chunk_size)

    for m in 1:num_chunks
        sort_chunk!((@view data[1 + (m-1)*chunk_size:m*chunk_size]), Val(N), Val(L))
    end
    data
end

"""Sort chunks from the input array, optionally transposing to generate sorted sequences of size V (default), or further
merging those into sequences of size V*L."""
function sort_vecs!(input::AbstractVector{T}, ::Val{J}, ::Val{V}, ::Val{Transpose}=Val(true), ::Val{Merge}=Val(false)) where {V,J,T,Transpose,Merge}
    chunk_size = V*J
    num_chunks = div(length(input), chunk_size)

    for m in 1:num_chunks
        chunk = ntuple(j->vload(Vec{V, T}, input, 1 + (m-1)*chunk_size + (j-1)*V), J)
        sorted_vecs = if Merge
            merge_vecs(transpose_vecs(sort_net(chunk...)...)...)
        elseif Transpose
            transpose_vecs(sort_net(chunk...)...)
        else
            sort_net(chunk...)
        end

        if Merge
            vstorent(sorted_vecs, input, 1 + (m-1)*(V*J))
        elseif Transpose
            for v in 1:V
                vstorent(sorted_vecs[v], input, 1 + (m-1)*(V*J) + (v-1)*J)
            end
        else
            for j in 1:J
                vstorent(sorted_vecs[j], input, 1 + (m-1)*(V*J) + (j-1)*V)
            end
        end
    end
    input
end

function merge_chunks(output, data, ::Val{L}, ::Val{N}) where {L,N}
    chunks = reshape((@view data[:]), L*N, :)
    M = div(length(data), L*N)

    merger = build_multi_merger(Val(N), ntuple(m->(@view chunks[:, m]), M)...)

    for itr in 1:L*M
        new_buffer = pop!(merger)
        vstorent(new_buffer, output, 1 + (itr-1)*N)
    end
    output
end

function chipsort(data::AbstractVector{T}, ::Val{N}, ::Val{L}, ::Val{N2}) where {T, N, L, N2}
    chunk_size = L * N
    L2 = div(chunk_size, N2)

    Nchunks = div(size(data, 1), chunk_size)

    output1 = valloc(T, div(32, sizeof(T)), length(data))
    output1 .= data
    sort_chunks!(output1, Val(L), Val(N))

    output2 = valloc(T, div(32, sizeof(T)), length(data))
    merge_chunks(output2, output1, Val(L2), Val(N2))
    output2
end
