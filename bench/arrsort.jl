using BenchmarkTools
using SIMD
using ChipSort

function chipsort_2_chunks(output1, output2, data::Array{T, 1}, ::Val{N}, ::Val{L}, ::Val{NB}) where {T, N, L, NB}
    chunk_size = L * N

    Nchunks = div(size(data, 1), chunk_size)
    @assert Nchunks == 2

    # output1 = valloc(T, div(32, sizeof(T)), length(data))
    # output2 = valloc(T, div(32, sizeof(T)), length(data))
    sort_chunks(output1, data, Val(L), Val(N))

    p1 = 1
    p2 = 1 + chunk_size
    h1 = vload(Vec{NB, T}, output1, p1)
    h2 = vload(Vec{NB, T}, output1, p2)

    pout = 1
    out, state = bitonic_merge(h1, h2)

    vstorent(out, output2, pout)
    pout+=NB

    end1 = chunk_size+1
    end2 = chunk_size*2+1
    p1 += NB
    p2 += NB
    h1 = vload(Vec{NB, T}, output1, p1)
    h2 = vload(Vec{NB, T}, output1, p2)
    while p1 < end1 || p2 < end2
        if p2 >= end2 || ((p1 < end1) && (h1[1] < h2[1]))
            out, state = bitonic_merge(state, h1)
            if p1 < end1
                p1 += NB
                h1 = vload(Vec{NB, T}, output1, p1)
            end
        else
            out, state = bitonic_merge(state, h2)
            if p2 < end2
                p2 += NB
                h2 = vload(Vec{NB, T}, output1, p2)
            end
        end
        vstorent(out, output2, pout)
        pout+=NB
    end
    vstorent(state, output2, pout)
    output2
end

# data = rand(UInt64, 64*2)
# srt_ref = sort(data)
# srt_hat = chipsort_2_chunks(data, Val(8), Val(8))
# @show srt_ref == srt_hat
# srt_hat'

data = rand(UInt64, 8*8*2)
srt_ref = sort(data)

baseline = @benchmark srt_hat = sort(data)

T=eltype(data)
output1 = valloc(T, div(32, sizeof(T)), length(data))
output2 = valloc(T, div(32, sizeof(T)), length(data))

propo = @benchmark srt_hat = chipsort_2_chunks(output1, output2, data, Val(8), Val(8), Val(8))
@show baseline
@show propo

#using ProfileView
# using Profile
# Profile.clear()
# mytest() = chipsort_2_chunks(rand(UInt64, 8*8*2), Val(8), Val(8))
# @profile [mytest() for _ in 1:1000]
# ProfileView.view()

# @code_native chipsort_2_chunks(output1, output2, data, Val(8), Val(8), Val(8))


times = []
for n in 1:20
    data = rand(UInt64, 2^n)
    qq = @benchmark sort($data)
    push!(times, qq)
end
using P
