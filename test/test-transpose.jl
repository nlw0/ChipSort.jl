using Test

using ChipSort
using SIMD


@testset "Transpose" begin

# types_to_test = [UInt8, UInt16, UInt32, UInt64, Float32, Float64]
types_to_test = [UInt16, Float64]

function test_transpose_vecs(T, N, L)
    uu = ntuple(l->Vec(tuple([convert(T, mod(l*N+n-N, 2^(8*T.size-2))) for n in 1:N]...)), L)
    ttref = ntuple(l->Vec(tuple([convert(T, mod(n*N+l-N, 2^(8*T.size-2))) for n in 1:L]...)), N)
    tthat = transpose_vecs(uu...)
    @test all(all(j) for j in (tthat.==ttref))
end

@testset for T in types_to_test
    for N in 2 .^ (1:2:5)
        for L in 2 .^ (1:2:5)
            test_transpose_vecs(T, N, L)
        end
    end
end

end
