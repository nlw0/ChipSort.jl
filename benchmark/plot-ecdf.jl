using Statistics
using Plots
pyplot()

using SIMD
using BenchmarkTools
using ChipSort
using Unrolled
using JLD

pc(n) = (1:length(n))./length(n)


data = load("chip-medium-bench.jld")
bmk = data["bmk"]

T=Dict("Int32"=>UInt32, "Int64"=>UInt64, "UInt32"=>UInt32, "UInt64"=>UInt64)[data["T"]]
V=data["V"]
J=data["J"]

rj = bmk[2^13][:JuliaStd]
ra = bmk[2^13][:CombSortMix]
rm = bmk[2^13][:ChipSortM]
rx = bmk[2^13][:ChipSortL]

@show ra
@show rx
@show minimum(ra.times)/minimum(rm.times)
@show median(ra.times)/median(rm.times)

plot(size=(600,400))
plot!(ra.times*1e-3, pc(ra.times), l=2, label="ChipSort")
plot!(rj.times*1e-3, pc(rj.times), l=2, label="Julia std")
plot!(rm.times*1e-3, pc(rm.times), l=2, label="ChipSort-M")
plot!(rx.times*1e-3, pc(rx.times), l=2, label="ChipSort-L")
plot!(xlim=(000e0,400e0), ylabel="Fraction of trials", xlabel="Time [μs]", title="Running time eCDF sorting 8k UInt32 values")
rj = bmk[2^18][:JuliaStd]
ra = bmk[2^18][:CombSortMix]
rm = bmk[2^18][:ChipSortM]
rx = bmk[2^18][:ChipSortL]

savefig("chipsort-bench-8k.pdf")

@show ra
@show rx
@show minimum(ra.times)/minimum(rx.times)
@show median(ra.times)/median(rx.times)
plot(size=(600,400), reuse=false)
plot!(ra.times*1e-6, pc(ra.times), l=2, label="ChipSort")
plot!(rj.times*1e-6, pc(rj.times), l=2, label="Julia std")
plot!(rm.times*1e-6, pc(rm.times), l=2, label="ChipSort-M")
plot!(rx.times*1e-6, pc(rx.times), l=2, label="ChipSort-L")
plot!(xlim=(3,17), ylabel="Fraction of trials", xlabel="Time [ms]", title="Running time eCDF sorting 256k UInt32 values")
savefig("chipsort-bench-256k.pdf")
