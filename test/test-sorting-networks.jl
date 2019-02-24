using Test

using SIMD
using MergeSortSIMD

function test_sorting_networks(T, N)
    vv = rand(T, N)
    srtref = sort(vv)
    srthat = sort_net(vv...)

    @test all(srthat[2:end] .>= srthat[1:end-1])
    @test all(srthat .== srtref)
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for L in 2 .^ (2:5)
        test_sorting_networks(T, L)
    end
end


function test_sort_simd_vec(T, N)
    va = ntuple(n->Vec(tuple(rand(T, N)...)),N)
    srthat = sort_net(va...)

    xx = [va[j][k] for j in 1:N, k in 1:N]
    srtref = sort(xx; dims=1)
    srthat_arr = [srthat[j][k] for j in 1:N, k in 1:N]

    @test srthat_arr == srtref
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    Niterations = 16
    for L in 2 .^ (2:5)
        for it in 1:Niterations
            test_sort_simd_vec(T, L)
        end
    end
end

@testset for N in [16, 32]
    for it in 1:2^16
        test_sort_simd_vec(UInt32, N)
    end
end


function test_sort_heaviside(N, Na)
    va = ntuple(n->if (Na&(1<<(n-1))) > 0 1 else 0 end, N)
    srthat = sort_net(va...)
    srtref = sort([va...])
    @test srthat == tuple(srtref...)
end


@testset for N in 2 .^ (2:4)
    for Na in 0:(2^N-1)
            test_sort_heaviside(N, Na)
    end
end
