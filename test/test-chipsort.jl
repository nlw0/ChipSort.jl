using Test
using ChipSort
using SIMD

include("testutils.jl")

@testset "Array sorting" begin

data = randa(Int32, 256)
@test chipsort(data,Val(8),Val(8),Val(8)) == sort(data)

data = randa(Int32, 2^13)
ref = sort(data)
@test chipsort_medium!(data, Val(8), Val(8), Val(128)) == ref

data = randa(Int32, 2^13)
ref = sort(data)
@test chipsort_merge_medium(data,Val(8),Val(8),Val(128)) == ref

data = randa(Int32, 2^7)
ref = sort(data)
@test combsort!(copy(data)) == ref
# @test combsort!(data, 2^6) == ref

data = randa(Int32, 2^6)
ref = sort(data)
@test chipsort_merge_medium(data,Val(8),Val(1),Val(8)) == ref

data = tuple((Vec(tuple(sort(randa(Int8,8))...)) for _ in 1:4)...)
stream_to_array(data) = [k[i] for k in data for i in 1:length(k)][:]
@test stream_to_array(merge_vecs_tree(data...)) == sort(stream_to_array(data))
# @test stream_to_array(merge_vecs_tree(stream_to_array(data), Val(4), Val(4), Val(2))) == sort(stream_to_array(data))

end
