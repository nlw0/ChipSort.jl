using Test
using ChipSort
using SIMD

include("testutils.jl")

@testset "Array sorting" begin

data = randa(Int32, 64)
@test chipsort_small!(data,Val(8),Val(8)) == sort(data)

data = randa(Int32, 2^13)
ref = sort(data)
@test chipsort_medium!(data, Val(8), Val(8), Val(128)) == ref

data = randa(Int32, 2^20)
ref = sort(data)
@test chipsort_large(data,Val(8),Val(32)) == ref

data = randa(Int32, 2^7)
ref = sort(data)
@test combsort!(data, 2^6) == ref

data = randa(Int32, 2^7)
ref = sort(data)
@test chipsort!(data, 2^6) == ref

data = randa(Int32, 2^7)
ref = sort(data)
@test insertion_sort!(data) == ref

end
