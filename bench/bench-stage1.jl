using Profile
using ProfileView
using BenchmarkTools

using SIMD

using Revise
using ChipSort

sort_small_array(chunk::NTuple{L, Vec{N,T}}) where {L,N,T} =
    merge_vecs(transpose_vecs(sort_net(chunk...)...)...)

function sort_chunks(output, data::Array{T, 1}, ::Val{L}, ::Val{N}) where {L,N,T}
    chunk_size = N*L
    num_chunks = div(length(data), chunk_size)

    for m in 1:num_chunks
        chunk = ntuple(l->vload(Vec{N, T}, data, 1 + (m-1)*chunk_size + (l-1)*N), L)
        sorted_chunk = sort_small_array(chunk)
        vstorent(sorted_chunk, output, 1 + (m-1)*(N*L))
    end
    output
end

function chipsort_st1(data::Array{T, 1}, ::Val{N}, ::Val{L}) where {T, N, L, N2}
    chunk_size = L * N
    Nchunks = div(size(data, 1), chunk_size)
    output1 = valloc(T, div(32, sizeof(T)), length(data))
    sort_chunks(output1, data, Val(L), Val(N))
    output1
end

function sort_chunks_ref(output, data::Array{T, 1}, ::Val{L}, ::Val{N}) where {L,N,T}
    chunk_size = N*L
    num_chunks = div(length(data), chunk_size)

    for m in 1:num_chunks
        output[1 + (m-1)*chunk_size:(m)*chunk_size] = sort(data[1 + (m-1)*chunk_size:(m)*chunk_size])
    end
    output
end

function sort_st1(data::Array{T, 1}, ::Val{N}, ::Val{L}) where {T, N, L, N2}
    chunk_size = L * N

    Nchunks = div(size(data, 1), chunk_size)
    output1 = valloc(T, div(32, sizeof(T)), length(data))
    sort_chunks_ref(output1, data, Val(L), Val(N))
    output1
end


# function run_test(::Val{N}, ::Val{L}) where {N, L}
#     TT = Float64
#     data_size=2^14
#     data = rand(TT, data_size)

#     chipsort_st1(data, Val(N), Val(L))
# end

function run_bench_mine(::Val{N}, ::Val{L}) where {N, L}
    TT = Float64
    data_size=2^14
    data = rand(TT, data_size)

    stat = @benchmark chipsort_st1($data, Val($N), Val($L))
    stat
end

function run_bench_base(::Val{N}, ::Val{L}) where {N, L}
    TT = Float64
    data_size=2^14
    data = rand(TT, data_size)

    stat = @benchmark sort_st1($data, Val($N), Val($L))
    stat
end

function run_test(::Val{N}, ::Val{L}) where {N, L}
    TT = Float64
    data_size=2^14
    data = rand(TT, data_size)
    chip = chipsort_st1(data, Val(N), Val(L))
    ref = sort_st1(data, Val(N), Val(L))
    display(reshape(chip, N*L,:))
    display(reshape(ref, N*L,:))

    @assert chip==ref
end

N = Val(4)

# run_test(N, Val(8))

# run_test(N, Val(8))
# Profile.clear()  # in case we have any previous profiling data
# @profile run_test(N, Val(8))
# ProfileView.view()

@show run_bench_mine(Val(4), Val(4))
@show run_bench_base(Val(4), Val(4))
@show run_bench_mine(Val(4), Val(8))
@show run_bench_base(Val(4), Val(8))
@show run_bench_mine(Val(4), Val(16))
@show run_bench_base(Val(4), Val(16))
@show run_bench_mine(Val(4), Val(32))
@show run_bench_base(Val(4), Val(32))
@show run_bench_mine(Val(8), Val(4))
@show run_bench_base(Val(8), Val(4))
@show run_bench_mine(Val(8), Val(8))
@show run_bench_base(Val(8), Val(8))
@show run_bench_mine(Val(8), Val(16))
@show run_bench_base(Val(8), Val(16))
@show run_bench_mine(Val(8), Val(32))
@show run_bench_base(Val(8), Val(32))
run_test(Val(4), Val(2))
