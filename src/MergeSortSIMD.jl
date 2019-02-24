module MergeSortSIMD

export sort_net, transpose_vecs, bitonic_merge, merge_brave

include("sorting-networks.jl")
include("transpose-vecs.jl")
include("bitonic-merge-network.jl")

end # module
