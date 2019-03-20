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

function sort_vecs!(data::AbstractVector{T}, ::Val{L}, ::Val{N}, ::Val{Transpose}=Val{true}) where {L,N,T,Transpose}
    chunk_size = N*L
    num_chunks = div(length(data), chunk_size)

    for m in 1:num_chunks
        chunk = ntuple(l->vload(Vec{N, T}, data, 1 + (m-1)*chunk_size + (l-1)*N), L)
        sorted_vecs = if Transpose
            transpose_vecs(sort_net(chunk...)...)
        else
            sort_net(chunk...)
        end

        if Transpose
            for n in 1:N
                vstorent(sorted_vecs[n], data, 1 + (m-1)*(N*L) + (n-1)*L)
            end
        else
            for n in 1:L
                vstorent(sorted_vecs[n], data, 1 + (m-1)*(N*L) + (n-1)*N)
            end
        end
    end
    nothing
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
