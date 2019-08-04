using Statistics

using SIMD
using BenchmarkTools
using ChipSort
using JLD

const SUITE = BenchmarkGroup()

function randa(T, K...)
    data = reshape(valloc(T, div(64, sizeof(T)), prod(K)), K...)
    data .= rand(T, K...)
    data
end


T=UInt32
V = 2^4
J = 2^4
kk = 2 .^ (0:16)

for K in kk
    len = V*J*K
    SUITE[len] = BenchmarkGroup(["size-$len"])
    SUITE[len][:JuliaStd] = @benchmarkable sort!(data) setup=(data = randa($T, $len)) seconds=4
    if K >= 2^2
        SUITE[len][:ChipSortM] = @benchmarkable chipsort_medium!(data, Val($V), Val($J), Val($K)) setup=(data = randa($T, $len)) seconds=4
    end

    if len <= 2^18
        SUITE[len][:CombSort] = @benchmarkable combsort!(data) setup=(data = randa($T, $len)) seconds=4
    end
    SUITE[len][:CombSortMix] = @benchmarkable chipsort_serial!(data) setup=(data = randa($T, $len)) seconds=4

    if len > 2^10
        SUITE[len][:ChipSortL] = @benchmarkable chipsort_large(data, Val($V), Val(2^4)) setup=(data = randa($T, $len)) seconds=4
    end
    if K <= 2^3
        SUITE[len][:InsertionSort] = @benchmarkable insertion_sort!(data) setup=(data = randa($T, $len)) seconds=4
    end
end

bmk = run(SUITE)
save("chip-medium-bench.jld", "bmk", bmk, "T", string(T), "V", V, "J", J)
