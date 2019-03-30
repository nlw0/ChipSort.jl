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


Km=2^5
Vm=2^3
Jm=36
vj=Vm*Jm
multi_sort!(data) = for n in 1:Km
    sort!(@view data[:,n])
end
multi_chipsort_small!(data) = for n in 1:Km
    chipsort_small!((@view data[:,n]), Val(8), Val(8))
end
multi_combsort!(data) = for n in 1:Km
    combsort!(@view data[:,n])
end
multi_insertion_sort!(data) = for n in 1:Km
    insertion_sort!(@view data[:,n])
end
SUITE["Array$(Km)x$vj$T"] = BenchmarkGroup(["size-small", "Int32"])
SUITE["Array$(Km)x$vj$T"]["JuliaStd"] = @benchmarkable multi_sort!(data) setup=(data = randa($T, $vj, $Km))
SUITE["Array$(Km)x$vj$T"]["ChipSort"] = @benchmarkable multi_chipsort_small!(data) setup=(data = randa($T, $vj, $Km))
SUITE["Array$(Km)x$vj$T"]["CombSort"] = @benchmarkable multi_combsort!(data) setup=(data = randa($T, $vj, $Km))
SUITE["Array$(Km)x$vj$T"]["InsertionSort"] = @benchmarkable multi_insertion_sort!(data) setup=(data = randa($T, $vj, $Km))


T=Int32
Ka=2^5
Va=2^3
Ja=2^12
lena = Va*Ja*Ka
SUITE["Array1MInt32"] = BenchmarkGroup(["size-large", "Int32"])
SUITE["Array1MInt32"]["JuliaStd"] = @benchmarkable sort!(data) setup=(data = randa($T, $lena))
SUITE["Array1MInt32"]["ChipSort"] = @benchmarkable chipsort_large(data, Val(Va), Val(Ka)) setup=(data = randa($T, $lena))
# SUITE["Array1MInt32"]["CombSort"] = @benchmarkable combsort!(data) setup=(data = randa($T, $len))
# SUITE["Array1MInt32"]["InsertionSort"] = @benchmarkable insertion_sort!(data) setup=(data = randa($T, $len))
