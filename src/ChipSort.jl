module ChipSort
import Base.pop!

export
    sort_net,
    transpose_vecs, transpose_chunks!, transpose_vecs_tall, transpose_vecs_wide, transpose!,
    bitonic_merge, merge_vecs, build_multi_merger, bitonic_merge_interleaved,
    DataBuffer, MergeNode, pop!,
    chipsort, chipsort_medium!, chipsort_medium_old, sort_chunks, sort_chunks!, sort_vecs!,
    merge_vecs_tree, sort_small_array, combsort!, insertion_sort!,
    chipsort_merge_medium


include("utils.jl")
include("sorting-networks.jl")
include("transpose-vecs.jl")
include("bitonic-merge-network.jl")
include("data-buffers.jl")
include("sort-array.jl")
include("comb-sort.jl")
include("sort-array-medium.jl")

end # module
