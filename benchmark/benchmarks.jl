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

T=Int32
K=1
V=2^3
J=2^3
len = V*J*K
SUITE["Array64Int32"] = BenchmarkGroup(["size-small", "Int32"])
SUITE["Array64Int32"]["JuliaStd"] = @benchmarkable sort(data) setup=(data = randa($T, $len))
SUITE["Array64Int32"]["ChipSort"] = @benchmarkable chipsort(data, Val(V), Val(J), Val(K)) setup=(data = randa($T, $len))
SUITE["Array64Int32"]["CombSort"] = @benchmarkable combsort!(data) setup=(data = randa($T, $len))
SUITE["Array64Int32"]["InsertionSort"] = @benchmarkable insertion_sort!(data) setup=(data = randa($T, $len))
