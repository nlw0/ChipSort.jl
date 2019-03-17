using Test
using ChipSort
using SIMD

@testset "Array sorting" begin

data = randa(Int32, 256)
@test chipsort(data,Val(8),Val(8),Val(8)) == sort(data)

data = randa(Int32, 2^13)
ref = sort(data)
@test chipsort_medium!(data,Val(8),Val(8),Val(128)) == ref

data = tuple((Vec(tuple(sort(randa(Int8,4))...)) for _ in 1:4)...)
stream_to_array(data) = [k[i] for i in 1:length(data), k in data][:]
@test stream_to_array(merge_vecs_tree(data...)) == sort(stream_to_array(data))

end
