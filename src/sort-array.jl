using Profile
using ProfileView
using BenchmarkTools

using SIMD

using Revise
using ChipSort

sort_small_array(chunk::NTuple{L, Vec{N,T}}) where {L,N,T} =
    merge_vecs(transpose_vecs(sort_net(chunk...)...)...)

# function sort_small_array(chunk, ::Val{N}, ::Val{L}) where {L,N}
#     srt = sort_net(ntuple(l->vload(Vec{N, T}, chunk, 1+(l-1)*N), L)...)
#     @show srt
#     trn = transpose_vecs(srt...)
#     @show trn
#     merge_vecs(trn...)
# end

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

function merge_chunks(output, data, ::Val{L}, ::Val{N}) where {L,N}
    chunks = reshape((@view data[:]), L * N, :)
    M = size(chunks,2)

    merger = build_multi_merger(Val(N), ntuple(m->(@view chunks[:, m]), M)...)

    for itr in 1:L*M
        new_buffer = pop!(merger)
        vstorent(new_buffer, output, 1 + (itr-1)*N)
    end
    output
end

function chipsort(data::Array{T, 1}, ::Val{N}, ::Val{L}, ::Val{N2}) where {T, N, L, N2}
    chunk_size = L * N
    L2 = div(chunk_size, N2)

    Nchunks = div(size(data, 1), chunk_size)

    output1 = valloc(T, div(32, sizeof(T)), length(data))
    output2 = valloc(T, div(32, sizeof(T)), length(data))
    sort_chunks(output1, data, Val(L), Val(N))
    merge_chunks(output2, output1, Val(L2), Val(N2))
    output2
end

# function sort(data)
#     sorted_chunks = sort_chunks(data)
#     merge_chunks(sorted_chunks)
# end
# srt = merge_chunks(sc, Val(L2), Val(N2), Val(M));
# srt'



# function run_test_stage1(::Val{N}, ::Val{L}) where {N,L}
#     data_size = 2^10
#     data = rand(T, data_size)
#     chunk_size = L * N
#     M = div(data_size, chunk_size)
#     output = valloc(T, div(32, sizeof(T)), L*N*M)

#     stat = @benchmark sort_chunks($output, $data, Val($L), Val($N), Val($M))
#     stat
# end



function run_test(::Val{N}, ::Val{L}) where {N, L}
    TT = Float64
    data_size=2^14
    data = rand(TT, data_size)

    chipsort(data, Val(N), Val(L), Val(N))
end


function run_bench(::Val{N}, ::Val{L}) where {N, L}
    TT = Float64
    data_size=2^14
    data = rand(TT, data_size)

    stat = @benchmark chipsort($data, Val($N), Val($L), Val($N))
    stat
end

function run_bench_ref() where {N, L}
    TT = Float64
    data_size=2^14
    data = rand(TT, data_size)

    stat = @benchmark sort($data)
    stat
end

N = Val(4)

# run_test(N, Val(8))
# Profile.clear()  # in case we have any previous profiling data
# @profile run_test(N, Val(8))
# ProfileView.view()

@show run_bench(N, Val(4))
@show run_bench(N, Val(8))
@show run_bench(N, Val(16))
@show run_bench(N, Val(32))
@show run_bench_ref()
