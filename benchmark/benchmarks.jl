using BenchmarkTools

using SIMD
using ChipSort


const SUITE = BenchmarkGroup()

function randa(T, K)
    data = valloc(T, div(32, sizeof(T)), K)
    data .= rand(T, K)
    data
end


T=Int32
K=2^7
V=2^3
J=2^3
len = V*J*K
SUITE["Array8kInt32"] = BenchmarkGroup(["size-medium", "Int32"])
SUITE["Array8kInt32"]["JuliaStd"] = @benchmarkable sort!(data) setup=(data = randa($T, $len))
SUITE["Array8kInt32"]["ChipSort"] = @benchmarkable chipsort_medium!(data, Val(V), Val(J), Val(K)) setup=(data = randa($T, $len))
SUITE["Array8kInt32"]["CombSort"] = @benchmarkable combsort!(data) setup=(data = randa($T, $len))
SUITE["Array8kInt32"]["InsertionSort"] = @benchmarkable insertion_sort!(data) setup=(data = randa($T, $len))


function sort_chunks_baseline!(data, chunk_size)
    num_chunks = div(length(data), chunk_size)
    for m in 1:num_chunks
        sort!(@view data[1 + (m-1)*chunk_size:(m)*chunk_size])
    end
end

T=Int32
K=128
V=2^3
J=2^3
len = V*J*K
SUITE["Array64Int32"] = BenchmarkGroup(["size-small", "Int32"])
SUITE["Array64Int32"]["JuliaStd"] = @benchmarkable sort_chunks_baseline!(data, V*J) setup=(data = randa($T, $len))
SUITE["Array64Int32"]["ChipSort"] = @benchmarkable sort_chunks!(data, Val(V), Val(J)) setup=(data = randa($T, $len))
