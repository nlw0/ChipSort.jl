module ChipSort
import Base.pop!

export
    sort_net,
    transpose_vecs, transpose_vecs_tall, transpose_vecs_wide,
    bitonic_merge, merge_vecs, build_multi_merger,
    DataBuffer, MergeNode, pop!

include("utils.jl")
include("sorting-networks.jl")
include("transpose-vecs.jl")
include("bitonic-merge-network.jl")
include("data-buffers.jl")

end # module
