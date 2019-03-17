using SIMD

sort_small_array(chunk::NTuple{L, Vec{N,T}}) where {L,N,T} =
    merge_vecs(transpose_vecs(sort_net(chunk...)...)...)

function sort_chunks(output, data::Array{T, 1}, ::Val{L}, ::Val{N}) where {L,N,T}
    chunk_size = N*L
    num_chunks = div(length(data), chunk_size)

    for m in 1:num_chunks
        # chunk = @view chunks[:, m]
        # ntuple(l->vload(Vec{N, T}, chunk, 1+(l-1)*N), L)

        chunk = ntuple(l->vload(Vec{N, T}, data, 1 + (m-1)*chunk_size + (l-1)*N), L)
        sorted_chunk = sort_small_array(chunk)
        vstorent(sorted_chunk, output, 1 + (m-1)*(N*L))
    end
    output
end

function sort_vecs!(data::AbstractVector{T}, ::Val{L}, ::Val{N}, ::Val{Transpose}) where {L,N,T,Transpose}
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

function chipsort(data::Vector{T}, ::Val{N}, ::Val{L}, ::Val{N2}) where {T, N, L, N2}
    chunk_size = L * N
    L2 = div(chunk_size, N2)

    Nchunks = div(size(data, 1), chunk_size)

    output1 = valloc(T, div(32, sizeof(T)), length(data))
    output2 = valloc(T, div(32, sizeof(T)), length(data))
    sort_chunks(output1, data, Val(L), Val(N))
    merge_chunks(output2, output1, Val(L2), Val(N2))
    output2
end
