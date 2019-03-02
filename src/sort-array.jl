using BenchmarkTools
using SIMD

using Revise
using ChipSort

sort_small_array(chunk, ::Val{N}, ::Val{L}) where {L,N} =
    merge_multiple_vecs(transpose_vecs(sort_net(ntuple(l->vload(Vec{N, T}, chunk, 1+(l-1)*N), L)...)...)...)

# function sort_small_array(chunk, ::Val{N}, ::Val{L}) where {L,N}
#     srt = sort_net(ntuple(l->vload(Vec{N, T}, chunk, 1+(l-1)*N), L)...)
#     @show srt
#     trn = transpose_vecs(srt...)
#     @show trn
#     merge_multiple_vecs(trn...)
# end

function sort_chunks(data, ::Val{L}, ::Val{N}, ::Val{M}) where {L,N,M}
    chunks = reshape((@view data[:]), L * N, M)
    T = eltype(data)
    output = valloc(T, div(32, sizeof(T)), L*N*M)

    for m in 1:M
        chunk = @view chunks[:, m]
        sorted_chunk = sort_small_array(chunk, Val(N), Val(L))
        vstorent(sorted_chunk, output, 1 + (m-1)*(N*L))
    end
    output
end

function merge_chunks(data, ::Val{L}, ::Val{N}, ::Val{M}) where {L,N,M}
    chunks = reshape((@view data[:]), L * N, M)
    T = eltype(data)
    output = valloc(T, div(32, sizeof(T)), L*N*M)
    merger = build_multi_merger(Val(N), ntuple(m->(@view chunks[:, m]), M)...)

    for itr in 1:L*M
        new_buffer = pop!(merger)
        vstorent(new_buffer, output, 1 + (itr-1)*N)
    end
    output
end


# function sort(data)
#     sorted_chunks = sort_chunks(data)
#     merge_chunks(sorted_chunks)
# end


T = Int32
L = 8 # buffers per chunk
N = 8 # buffer size

N2 = 8
L2 = div(N*L, N2)

M = 128 # chunks

data = rand(T, L*N*M)
# data = T[(1:L*N*M)...]

sc = sort_chunks(data, Val(L), Val(N), Val(M));
srt = merge_chunks(sc, Val(L2), Val(N2), Val(M));
srt'
