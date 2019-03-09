using Test
using SIMD
using ChipSort

@testset "Data buffers" begin

# types_to_test = [Int8, Int16, Int32, Int64, Float32, Float64]
types_to_test = [Int8, Float64]

function test_data_buffer(T, ::Val{N}) where N
    data = sort!(rand(T, N*N))
    db = DataBuffer(Val(N), data)
    @test all(all.([pop!(db) for k in 1:N] .== [Vec(tuple(data[k:k+N-1]...)) for k in 1:N:N*N]))
    @test pop!(db) == nothing
end

@testset for T in types_to_test
    for N in [4, 8]
        test_data_buffer(T, Val(N))
    end
end


function test_merge_node(T, ::Val{N}) where N
    data_a = sort!(rand(T, N*N))
    data_b = sort!(rand(T, N*N))
    alldata = sort!(vcat(data_a, data_b))

    left = DataBuffer(Val(N), data_a)
    right = DataBuffer(Val(N), data_b)
    mrg = MergeNode(left, right)

    @test all(all.([pop!(mrg) for k in 1:2*N] .== [Vec(tuple(alldata[k:k+N-1]...)) for k in 1:N:2*N*N]))
    @test pop!(mrg) == nothing
end

@testset for T in types_to_test
    for N in [4, 8]
        test_merge_node(T, Val(N))
    end
end


function test_multi_way_merge(T, ::Val{N}, ::Val{M}) where {N,M}
    data = [sort!(rand(T, N*N)) for _ in 1:M]
    alldata = sort!(vcat(data...))

    mrg = build_multi_merger(Val(N), data...)

    srt_hat = [pop!(mrg) for k in 1:M*N]
    srt_ref = [Vec(tuple(alldata[k:k+N-1]...)) for k in 1:N:M*N*N]

    @test all(all.(srt_hat .== srt_ref))
    @test pop!(mrg) == nothing
end

@testset for T in types_to_test
    for N in [4, 32]
        for M in [4, 32]
            test_multi_way_merge(T, Val(N), Val(M))
        end
    end
end

end
