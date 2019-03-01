# ChipSort

ChipSort is sorting module containing SIMD- and cache-aware techniques. It is mostly based on ideas taken from academic literature.

## Introduction

Processing power in computers has been growing faster than memory bandwidth for many years. To attain high performance, some of the main priorities for a programmer today should be:
- Exploit multi-threaded programming
- Exploit SIMD parallelism
- Access memory as little and sequentially as possible
- Make use of cache memory

Algorithms like Quicksort dominated sorting benchmarks for years, but they tend to result in too frequent and unordered accesses to main memory. Interestingly, this means merge-sort, which was suitable for linear media like punched cards and magnetic tapes, became hip again. This and other considerations were taken in account when developing ChipSort.


## Methodology

The strategy used in ChipSort has two stages, but only the first one is necessary if the array is small enough.

For small arrays, the strategy is to use non-branching and SIMD-friendly sorting and bitonic merge networks. This is pretty much the best that can be done in this case, and even a Quicksort implementation will switch to something like this when the array is small enough. One important detail is that in this situation we try our best to load the input data into the processor registers, and do as much as we can there before putting any data back into memory. At this step we are sorting only _in the chip_.

For larger arrays, the first stage is to employ these techniques to create many small ordered sequences. The size of what is considered small is how much data we can fit in the register memory before we start having to move (too much) stuff to the stack in order to carry out the sorting network calculations. Modern processors can already offer kilobytes of register memory.

The second stage is just to perform a multi-way merge of all these small sequences. We really merge many sequences at the same time, using small buffers that are merged with the bitonic merge network. This procedure requires us to keep a large binary tree of intermediate merged sub-sequences, which is supposed to fit in the cache memory.

With this approach, only two passes trough the whole data are necessary. If the array is so large that the merge tree is too big for the cache, we just perform more multi-way merge stages with increasingly larger chunks.


## Implementation

One interesting feature of ChipSort is the heavy use of meta-programming. Our implementation of the sorting network, bitonic merge network and matrix transpose are based on generated functions.

This library relies on SIMD.jl whenever necessary. In special, the `shufflevector` function is used in the transpose and bitonic merge, but the sorting network just uses the `min` and `max` functions, which are supported by the `Vec` class.

One important detail is that non-temporal memory access is used to prevent cache pollution and improve writing throughput.

## References

### Scientific publications
- _Efficient Implementation of Sorting on Multi-Core SIMD CPU Architecture_, Jatin Chhugani et al. (2008)
- _SIMD- and Cache-Friendly Algorithm for Sorting an Array of Structures_, Hiroshi Inoue and Kenjiro Taura (2007)

### Related packages

https://github.com/eschnett/SIMD.jl
https://github.com/JeffreySarnoff/SortingNetworks.jl
https://github.com/JuliaCollections/SortingAlgorithms.jl
https://github.com/xiaodaigh/SortingLab.jl
