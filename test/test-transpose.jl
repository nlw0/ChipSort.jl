using Test

using ChipSort
using SIMD

include("testutils.jl")

@testset "Transpose" begin

# types_to_test = [UInt8, UInt16, UInt32, UInt64, Float32, Float64]
types_to_test = [UInt16, Float64]

function test_transpose(T, V, J, K)
    data = randa(T, V*J*K)
    sol = permutedims(reshape(data, V, K, J), [1,3,2])[:]
    # seed=find_transpose_cycles(Val(J), Val(K))
    # transpose!(aa, Val(V), Val(J), Val(K), seed)
    transpose!(data, Val(V), Val(J), Val(K))
    @test sol == data
end

@testset for T in types_to_test
    for V in 2 .^ (1:2:5)
        for J in 2 .^ (1:2:5)
            for K in 2 .^ (2:4:8)
                test_transpose(T, V, J, K)
            end
        end
    end
end


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
