using Test

using ChipSort
using SIMD


function test_merge_types_sizes(T, N)
    va = Vec(tuple(sort(rand(T, N))...))
    vb = Vec(tuple(sort(rand(T, N))...))
    a, b = bitonic_merge(va, vb)
    ab = [[a[n] for n in 1:N]; [b[n] for n in 1:N]]
    abref = sort([[va[n] for n in 1:N]; [vb[n] for n in 1:N]])
    @test ab == abref
    @test all(ab[2:end] .>= ab[1:end-1])
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for N in 2 .^ (1:3)
        test_merge_types_sizes(T, N)
    end
end


function test_merge_heaviside(N, Na, Nb)
    va = Vec(ntuple(n->if n<=Na 0x0 else 0x1 end, N))
    vb = Vec(ntuple(n->if n<=Nb 0x0 else 0x1 end, N))
    a, b = bitonic_merge(va, vb)
    ab = [[a[n] for n in 1:N]; [b[n] for n in 1:N]]
    @test all(ab[1:Na+Nb] .== 0)
    @test all(ab[Na+Nb+1:end] .== 1)
end

@testset for N in 2 .^ (1:8)
    for Na in 0:N
        for Nb in 0:N
            test_merge_heaviside(N, Na, Nb)
        end
    end
end


function test_merge_brave(T, N)
    T=Int64
    N=8
    aa = sort(rand(T, N, N); dims=1)
    va = ntuple(k->Vec(ntuple(j->aa[j,k],N)), N)
    srtref = sort(aa[:])

    srthat = merge_multiple_vecs(va...)
    srthat_arr = [srthat[n] for n in 1:N*N]
    @test all(srthat_arr .== srtref)
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for N in [4, 8]
        test_merge_brave(T, N)
    end
end
