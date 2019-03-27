using BenchmarkTools

using SIMD
using ChipSort


const SUITE = BenchmarkGroup()

function randa(T, K...)
    data = reshape(valloc(T, div(32, sizeof(T)), prod(K)), K...)
    data .= rand(T, K...)
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


multi_sort!(data) = for n in 1:128
    sort!(@view data[:,n])
end
multi_chipsort_small!(data) = for n in 1:128
    chipsort_small!((@view data[:,n]), Val(8), Val(8))
end
multi_combsort!(data) = for n in 1:128
    combsort!(@view data[:,n])
end
multi_insertion_sort!(data) = for n in 1:128
    insertion_sort!(@view data[:,n])
end

vj=V*J
SUITE["Array128x64Int32"] = BenchmarkGroup(["size-small", "Int32"])
SUITE["Array128x$vj$T"]["JuliaStd"] = @benchmarkable multi_sort!(data) setup=(data = randa($T, $vj,$K))
SUITE["Array128x$vj$T"]["ChipSort"] = @benchmarkable multi_chipsort_small!(data) setup=(data = randa($T, $vj,$K))
SUITE["Array128x$vj$T"]["CombSort"] = @benchmarkable multi_combsort!(data) setup=(data = randa($T, $vj,$K))
SUITE["Array128x$vj$T"]["InsertionSort"] = @benchmarkable multi_insertion_sort!(data) setup=(data = randa($T, $vj,$K))


T=Int32
K=32
V=2^3
len = V*J*K
SUITE["Array1MInt32"] = BenchmarkGroup(["size-large", "Int32"])
SUITE["Array1MInt32"]["JuliaStd"] = @benchmarkable sort!(data) setup=(data = randa($T, $len))
SUITE["Array1MInt32"]["ChipSort"] = @benchmarkable chipsort_large(data, Val(V), Val(K)) setup=(data = randa($T, $len))
SUITE["Array1MInt32"]["CombSort"] = @benchmarkable combsort!(data) setup=(data = randa($T, $len))
SUITE["Array1MInt32"]["InsertionSort"] = @benchmarkable insertion_sort!(data) setup=(data = randa($T, $len))
