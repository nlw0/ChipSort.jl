using Test
using SIMD
using MergeSortSIMD


function test_data_buffer(T, ::Val{N}) where N
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


function test_merge_node(T, ::Val{N}) where N
    data_a = sort!(rand(T, N*N))
    data_b = sort!(rand(T, N*N))
    alldata = sort!(vcat(data_a, data_b))

    left = DataBuffer(Vec(tuple(data_a[1:N]...)), (@view data_a[N+1:N*N]))
    right = DataBuffer(Vec(tuple(data_b[1:N]...)), (@view data_b[N+1:N*N]))
    head = pop(Val(N), if left.head[1] < right.head[1] left else right end)
    mrg = MergeNode(left, right, head)
    @test all(all.([pop(Val(N), mrg) for k in 1:2*N] .== [Vec(tuple(alldata[k:k+N-1]...)) for k in 1:N:2*N*N]))
    @test pop(Val(N), mrg) == nothing
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for N in [4, 8]
        test_merge_node(T, Val(N))
    end
end


function test_multi_way_merge(T, ::Val{N}) where N
    data_1 = sort!(rand(T, N*N))
    data_2 = sort!(rand(T, N*N))
    data_3 = sort!(rand(T, N*N))
    data_4 = sort!(rand(T, N*N))
    alldata = sort!(vcat(data_1, data_2, data_3, data_4))

    db1 = DataBuffer(Vec(tuple(data_1[1:N]...)), (@view data_1[N+1:N*N]))
    db2 = DataBuffer(Vec(tuple(data_2[1:N]...)), (@view data_2[N+1:N*N]))
    db3 = DataBuffer(Vec(tuple(data_3[1:N]...)), (@view data_3[N+1:N*N]))
    db4 = DataBuffer(Vec(tuple(data_4[1:N]...)), (@view data_4[N+1:N*N]))

    head5 = pop(Val(N), if db1.head[1] < db2.head[1] db1 else db2 end)
    head6 = pop(Val(N), if db3.head[1] < db4.head[1] db3 else db4 end)

    mrg5 = MergeNode(db1, db2, head5)
    mrg6 = MergeNode(db3, db4, head6)

    head7 = pop(Val(N), if mrg5.head[1] < mrg6.head[1] mrg5 else mrg6 end)
    mrg7 = MergeNode(mrg5, mrg6, head7)

    srt_hat = [pop(Val(N), mrg7) for k in 1:4*N]
    srt_ref = [Vec(tuple(alldata[k:k+N-1]...)) for k in 1:N:4*N*N]

    @test all(all.(srt_hat .== srt_ref))
    @test pop(Val(N), mrg7) == nothing
end

@testset for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for N in [4, 8]
        test_multi_way_merge(T, Val(N))
    end
end
