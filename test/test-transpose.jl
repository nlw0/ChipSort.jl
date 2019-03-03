using Test

using ChipSort
using SIMD


# types_to_test = [UInt8, UInt16, UInt32, UInt64, Float32, Float64]
types_to_test = [UInt16, Float64]

function test_transpose_vecs(T, N)
    uu = ntuple(l->Vec(ntuple(n->convert(T, mod(l*N+n-N, 2^(8*T.size-2))), N)), N)
    ttref = ntuple(l->Vec(ntuple(n->convert(T, mod(n*N+l-N, 2^(8*T.size-2))), N)), N)
    tthat = transpose_vecs(uu...)
    @test all(all(j) for j in (tthat.==ttref))
end

@testset for T in types_to_test
    for L in 2 .^ (1:4)
        test_transpose_vecs(T, L)
    end
end


function test_transpose_vecs_nonsquare(T, N, L)
    uu = ntuple(l->Vec(tuple([convert(T, mod(l*N+n-N, 2^(8*T.size-2))) for n in 1:N]...)), L)
    ttref = ntuple(l->Vec(tuple([convert(T, mod(n*N+l-N, 2^(8*T.size-2))) for n in 1:L]...)), N)
    tthat = if L > N
        transpose_vecs_tall(uu...)
    elseif L < N
        transpose_vecs_wide(uu...)
    else
        transpose_vecs(uu...)
    end

    @test all(all(j) for j in (tthat.==ttref))
end

@testset for T in types_to_test
    for (N,L) in [(4,8),(8,4),(64,32),(32,64)]
            test_transpose_vecs_nonsquare(T, N, L)
    end
end
