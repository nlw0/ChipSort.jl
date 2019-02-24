using Test

# using MergeSortSIMD
using SIMD

include("../src/matrix-transpose.jl")

function test_transpose(T, L)
    uu = ntuple(a->Vec(ntuple(i->convert(T, mod(a*(L)+i, 2^(8*T.size-2))), L)), L)
    tt = ntuple(a->Vec(ntuple(i->convert(T, mod(i*(L)+a, 2^(8*T.size-2))), L)), L)
    ee = transpose_vecs(uu)
    tthat = eval(ee)
    @test all(all(j) for j in (tthat.==tt))
end

@testset for T in [UInt8, UInt16, UInt32, UInt64, Float32, Float64]
    for L in 2 .^ (1:4)
        transpose_vecs(T, L)
    end
end
