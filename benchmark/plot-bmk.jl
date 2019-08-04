using Statistics
using Plots
pyplot()

using SIMD
using BenchmarkTools
using ChipSort
using Unrolled
using JLD


data = load("chip-medium-bench.jld")
bmk = data["bmk"]

T=Dict("Int32"=>UInt32, "Int64"=>UInt64, "UInt32"=>UInt32, "UInt64"=>UInt64)[data["T"]]
V=data["V"]
J=data["J"]

plot()
sizes = sort!(collect(keys(bmk)))
for srt in [:CombSortMix, :JuliaStd, :ChipSortM, :ChipSortL, :InsertionSort]
    xa = hcat(
        filter(
            x->x[2]<0.3 && x[1]<=2^20,
        [[l, median(bmk[l][srt].times * 1e-9)] for l in sizes if srt in keys(bmk[l])]
    )...)

    @show xa
    if length(xa)==0
        continue
    end

    lab = if srt == :ChipSortM "ChipSort-M"
    elseif srt == :ChipSortL "ChipSort-L"
    elseif srt == :CombSortMix "ChipSort"
    else srt end
    # plot!(xa[1,:], xa[2,:], l=2, m=4, label=srt)
    plot!(xa[1,:], xa[2,:] ./ xa[1,:], l=2, m=4, label=lab)
end

srt= :JuliaStd
xa = hcat(
        filter(
            x->x[2]<0.3 && x[1]<=2^20,
            [[l, median(bmk[l][srt].times * 1e-9)] for l in sizes if srt in keys(bmk[l])]
        )...)
plot!(xa[1,:], log.(xa[1,:]) * 5e-9, l=1, label="n⋅log(n)", color=:black, ls=:dash)

cache = 2^10 * [32, 256, 1024+512, 4*(1024+512)] * (1/sizeof(T))
for c in 1:3
    # plot!([cache[c], cache[c]], [10^4, 10^12], color=:black, ls=:dot)
    plot!([cache[c], cache[c]], [1e-8, 1e-7], color=:black, ls=:dot,label="")
end

plot!(xaxis=:log, yaxis=:log,
      yticks=([(1:10)*1e-8;], [(1:10);]),
      xticks=(2 .^(6:20), 2 .^(6:20)),
      title="Performance of sorting methods relative to input size",
      xlabel="Input size [n]",
      ylabel="Time / input size [1E8 × s/n]",
      size=(800,450)
      )

savefig("chipsort-bench-curves.pdf")
savefig("chipsort-bench-curves.svg")
savefig("chipsort-bench-curves.png")

plot(size=(800,600))
sizes = sort!(collect(keys(bmk)))
for srt in [:CombSortMix, :JuliaStd, :ChipSortM, :ChipSortL, :InsertionSort]
    xa = hcat(
        filter(
            x->x[2]<0.3 && x[1]<=2^20,
        [[l, median(bmk[l][srt].times * 1e-9)] for l in sizes if srt in keys(bmk[l])]
    )...)

    @show xa
    if length(xa)==0
        continue
    end

    lab = if srt == :ChipSortM "ChipSort-M"
    elseif srt == :ChipSortL "ChipSort-L"
    elseif srt == :CombSortMix "ChipSort"
    else srt end
    plot!(xa[1,:], xa[2,:], l=2, m=4, label=lab)
end

srt= :JuliaStd
xa = hcat(
        filter(
            x->x[2]<0.3 && x[1]<=2^20,
            [[l, median(bmk[l][srt].times * 1e-9)] for l in sizes if srt in keys(bmk[l])]
        )...)
plot!(xa[1,:], xa[1,:] .* log.(xa[1,:]) * 5e-9, l=1, label="n⋅log(n)", color=:black, ls=:dash)

plot!(xaxis=:log, yaxis=:log,
      # yticks=([(1:10)*1e-8;], [(1:10);]),
      xticks=(2 .^(6:20), 2 .^(6:20)),
      title="Running time of sorting methods",
      xlabel="Input size [n]",
      ylabel="Time [s]"
      )

savefig("chipsort-bench-time.pdf")
savefig("chipsort-bench-time.png")
savefig("chipsort-bench-time.svg")
