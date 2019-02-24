module MergeSortSIMD

export transpose_vecs, bitonic_merge

include("sorting-network.jl")
include("transpose-vecs.jl")
include("bitonic-merge-network.jl")

end # module
