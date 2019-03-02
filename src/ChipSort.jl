module ChipSort
import Base.pop!

export sort_net, transpose_vecs, bitonic_merge, merge_multiple_vecs, DataBuffer, MergeNode, pop!

include("utils.jl")
include("sorting-networks.jl")
include("transpose-vecs.jl")
include("bitonic-merge-network.jl")
include("data-buffers.jl")

end # module
