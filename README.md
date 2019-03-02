# ChipSort.jl

ChipSort is a sorting module containing SIMD and cache-aware techniques. It's based on a couple of [research papers](#references) from 2008.

## Introduction

Processing power in computers has been growing faster than memory bandwidth for years. To reach high performance, some of the main priorities for a programmer today should be:
- Exploit thread parallelism
- Exploit SIMD parallelism
- Exploit cache memory
- Access memory as little and sequentially as possible

Algorithms like Quicksort dominated sorting benchmarks for years, but they tend to result in too frequent and unordered accesses to main memory. This means merge-sort, which was suitable for linear media like punched cards and magnetic tapes, became hip again. The strategy used in ChipSort takes this and other facts into account.


## Methods

For small arrays, our strategy is to use non-branching and SIMD-friendly [sorting](http://www.cs.brandeis.edu/~hugues/sorting_networks.html) and [bitonic merge](https://en.wikipedia.org/wiki/Bitonic_sorter) networks. This is pretty much the best approach in this case, and even practical Quicksort implementations use something like this for small arrays. In this situation we try our best to load all the input data into the processor registers, and do as much as we can there before putting any data back into memory. In other words, we sort small sequences _in the chip_.

For larger arrays, ChipSort employs two stages. The first stage utilizes the same methods for small arrays to create an initial set of ordered sequences. They're made as big as it fits inside register memory before we have to start moving (too much) stuff back to the stack to carry out the calculations. A modern processor core can already offer kilobytes of register memory.

The second stage is to perform a multi-way merge of all these small sequences. They are all processed at the same time, split in small buffers which are input to the bitonic merge network. This procedure requires a binary tree to keep intermediate merged sub-sequences. This structure should fit in the cache memory.

With just two passes over the whole data in the RAM this approach can already handle thousands of entries. If the input array is so large that the merge tree is too big for the cache, then we perform more multi-way merge stages with an increasingly large chunk size.


## Implementation

One interesting aspect from the ChipSort implementation is the extensive use of meta-programming. Our implementation of the sorting network, bitonic merge network and matrix transpose are all based on generated functions.

This module relies on SIMD.jl whenever necessary. In special, the transpose and bitonic merge use the `shufflevector` function. The sorting network uses the `min` and `max` functions, which the `Vec` class supports.

Another notable implementation aspect is the use of non-temporal memory access, which prevents cache pollution and also improves writing throughput.

## References

### Scientific publications
- _Efficient Implementation of Sorting on Multi-Core SIMD CPU Architecture_, Jatin Chhugani et al. (2008)
- _SIMD- and Cache-Friendly Algorithm for Sorting an Array of Structures_, Hiroshi Inoue and Kenjiro Taura (2007)

### Related packages

- https://github.com/eschnett/SIMD.jl
- https://github.com/JeffreySarnoff/SortingNetworks.jl
- https://github.com/JuliaCollections/SortingAlgorithms.jl
- https://github.com/xiaodaigh/SortingLab.jl
