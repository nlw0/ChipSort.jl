module ChipSort
import Base.pop!

export
    chipsort_small!, chipsort_medium!, chipsort_large, chipsort_serial!,
    sort_net,
    transpose_vecs, transpose_blocks!, transpose_vecs_tall, transpose_vecs_wide, transpose!,
    bitonic_merge, merge_vecs, build_multi_merger, bitonic_merge_interleaved, chipsort_merge_medium,
    DataBuffer, MergeNode, pop!,
    combsort!, insertion_sort!,
    sort_blocks!, sort_vecs!

include("utils.jl")
include("sorting-networks.jl")
include("transpose-vecs.jl")
include("bitonic-merge-network.jl")
include("sort-array.jl")
include("comb-sort.jl")
include("k-way-merge.jl")
include("sort-array-medium.jl")
include("data-buffers.jl")

end # module
