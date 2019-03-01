using Test
using SIMD
using MergeSortSIMD


function test_data_buffer(T, ::Val{N})
    data = sort!(rand(T, N*N))
    db = DataBuffer(Vec(tuple(data[1:N]...)), (@view data[N+1:N*N]))
    @test all(all.([pop(Val(N), db) for k in 1:N] .== [Vec(tuple(data[k:k+N-1]...)) for k in 1:N:N*N]))
    @test pop(Val(N), db) == nothing
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for N in [4, 8]
        test_data_buffer(T, Val(N))
    end
end


function test_merge_node(T, ::Val{N})
    data_a = sort!(rand(T, N*N))
    data_b = sort!(rand(T, N*N))
    alldata = sort!(vcat(data_a, data_b))

    left = DataBuffer(Vec(tuple(data_a[1:N]...)), (@view data_a[N+1:N*N]))
    right = DataBuffer(Vec(tuple(data_b[1:N]...)), (@view data_b[N+1:N*N]))
    head = pop(Val(N), left)
    mrg = MergeNode(left, right, head)
    @test all(all.([pop(Val(N), mrg) for k in 1:2*N] .== [Vec(tuple(alldata[k:k+N-1]...)) for k in 1:N:2*N*N]))
    @test pop(Val(N), mrg) == nothing
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for N in [4, 8]
        test_merge_node(T, Val(N))
    end
end
