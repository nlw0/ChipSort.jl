var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "ChipSort.jl Documentation",
    "title": "ChipSort.jl Documentation",
    "category": "page",
    "text": "<center><img src=\"assets/logo.svg\" width=\"50%\"></center>"
},

{
    "location": "#ChipSort.jl-Documentation-1",
    "page": "ChipSort.jl Documentation",
    "title": "ChipSort.jl Documentation",
    "category": "section",
    "text": "ChipSort is a Julia module that implements SIMD and cache-aware sorting techniques.This documentation contains:A description of the API and how to use the Julia functions defined in the module.\nA presentation of the theory behind ChipSort.\nA report with some benchmark results."
},

{
    "location": "#Installation-and-basic-usage-1",
    "page": "ChipSort.jl Documentation",
    "title": "Installation and basic usage",
    "category": "section",
    "text": "Like any experimental Julia package on GitHub you can install ChipSort from the Julia REPL by first typing ] to enter the package management prompt, and thenpkg> add https://github.com/nlw0/ChipSort.jlYou can now try out the basic functions offered by the package such as sort_net to use a sorting network, or try the full array sort function prototype chipsort.julia> using ChipSort\n\njulia> using SIMD\n\njulia> data = [Vec(tuple(rand(Int8, 4)...)) for _ in 1:4]\n4-element Array{Vec{4,Int8},1}:\n <4 x Int8>[-15, 98, 5, -28]\n <4 x Int8>[47, -112, 98, -14]\n <4 x Int8>[-18, -3, -111, 85]\n <4 x Int8>[79, -12, -44, -85]\n\njulia> x = sort_net(data...)\n(<4 x Int8>[-18, -112, -111, -85], <4 x Int8>[-15, -12, -44, -28], <4 x Int8>[47, -3, 5, -14], <4 x Int8>[79, 98, 98, 85])\n\njulia> y = transpose_vecs(x...)\n(<4 x Int8>[-18, -15, 47, 79], <4 x Int8>[-112, -12, -3, 98], <4 x Int8>[-111, -44, 5, 98], <4 x Int8>[-85, -28, -14, 85])\n\njulia> z = merge_vecs(y...)\n<16 x Int8>[-112, -111, -85, -44, -28, -18, -15, -14, -12, -3, 5, 47, 79, 85, 98, 98]\n\njulia> bigdata = rand(Int16, 256);\n\njulia> chipsort(bigdata, Val(8), Val(8), Val(8)) == sort(bigdata)\ntrue"
},

{
    "location": "theory/#",
    "page": "Theory",
    "title": "Theory",
    "category": "page",
    "text": ""
},

{
    "location": "theory/#Theory-1",
    "page": "Theory",
    "title": "Theory",
    "category": "section",
    "text": "This documentation section explains some of the ideas behind the sorting strategy implemented by ChipSort. It\'s all mostly based on a couple of academic papers from 2008, found in References.The overall strategy is to first use sorting networks to create small sorted arrays, and then merge them in a multi-way fashion in one or more stages, depending on the size of the input and the chip specs. The best strategy depends mostly on the size of register and cache memories."
},

{
    "location": "theory/#Introduction-1",
    "page": "Theory",
    "title": "Introduction",
    "category": "section",
    "text": "Processing power in computers has been growing faster than memory bandwidth for years. To reach high performance, some of the main priorities for a programmer today should be:Exploit thread parallelism\nExploit SIMD parallelism\nExploit cache memory\nAccess memory as little and sequentially as possibleAlgorithms like Quicksort dominated sorting benchmarks for years, but they tend to result in too frequent and unordered accesses to main memory. This means merge-sort, which was suitable for linear media like punched cards and magnetic tapes, became hip again. The strategy used in ChipSort takes this and other facts into account.More than exploiting paralelism and caching, this strategy also minimizes access to main memory, what can be especially advantageous if the objects being sorted are not just numbers, but larger structures."
},

{
    "location": "theory/#Methods-1",
    "page": "Theory",
    "title": "Methods",
    "category": "section",
    "text": "To sort small arrays we employ non-branching and SIMD-friendly sorting and bitonic merge networks. This is pretty much the best approach in this case, especially if only few different input sizes must be supported. In this situation we try our best to load all the input data into the processor registers, and do as much as we can there before putting any data back into memory. In other words, we sort small sequences in the chip.For larger arrays, ChipSort employs two stages. The first stage utilizes the same methods for small arrays to create an initial set of ordered sequences. They\'re made as big as it fits inside register memory before we have to start moving (too much) stuff back to the stack to carry out the calculations. A modern processor core can already offer kilobytes of register memory.The second stage is to perform a multi-way merge of all these small sequences. They are all processed at the same time, split in small buffers which are input to the bitonic merge network. This procedure requires a binary tree that stores intermediate merged sub-sequences. This structure should fit in the cache memory.With just two passes over the whole data in the RAM this approach can already handle thousands of entries. If the input array is so large that the merge tree is too big for the cache, then we perform more multi-way merge stages with an increasingly large chunk size."
},

{
    "location": "theory/#Implementation-details-1",
    "page": "Theory",
    "title": "Implementation details",
    "category": "section",
    "text": "One interesting aspect from the ChipSort implementation is the extensive use of meta-programming, one of the greatest and most unique Julia features. Our implementation of the sorting network, bitonic merge network and matrix transpose are all based on generated functions.This module relies on SIMD.jl whenever necessary. In special, the transpose and bitonic merge use the shufflevector function. The sorting network uses the min and max functions, which the Vec class supports.Another notable implementation aspect is the use of non-temporal memory access, which prevents cache pollution and also improves writing throughput."
},

{
    "location": "theory/#Results-1",
    "page": "Theory",
    "title": "Results",
    "category": "section",
    "text": "To find out more about the performance gains ChipSort can provide, check our benchmark documentation page. Note that this project is still young, and a lot of work is necessary to offer a reliable sort guaranteed to be as good as e.g. the one offered by the Julia standard library. Our first priority is to be a laboratory for implementing generic SIMD-based sorting techniques in Julia."
},

{
    "location": "theory/#References-1",
    "page": "Theory",
    "title": "References",
    "category": "section",
    "text": ""
},

{
    "location": "theory/#Scientific-publications-1",
    "page": "Theory",
    "title": "Scientific publications",
    "category": "section",
    "text": "Efficient Implementation of Sorting on Multi-Core SIMD CPU Architecture, Jatin Chhugani et al. (2008)\nSIMD- and Cache-Friendly Algorithm for Sorting an Array of Structures, Hiroshi Inoue and Kenjiro Taura (2007)"
},

{
    "location": "theory/#Related-packages-1",
    "page": "Theory",
    "title": "Related packages",
    "category": "section",
    "text": "SIMD.jl\nSortingNetworks.jl\nSortingAlgorithms.jl\nSortingLab.jl"
},

{
    "location": "api/#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api/#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": ""
},

{
    "location": "api/#ChipSort.bitonic_merge-Union{Tuple{T}, Tuple{N}, Tuple{Vec{N,T},Vec{N,T}}} where T where N",
    "page": "API",
    "title": "ChipSort.bitonic_merge",
    "category": "method",
    "text": "bitonic_merge(input_a::Vec{N,T}, input_b::Vec{N,T}) where {N,T}\n\nMerges two SIMD.Vec objects of the same type and size using a bitonic sort network. The inputs are assumed to be sorted. Returns a pair of vectors with the first and second halves of the merged sequence.\n\n\n\n\n\n"
},

{
    "location": "api/#ChipSort.sort_net-Union{Tuple{Vararg{T,L}}, Tuple{T}, Tuple{L}} where T where L",
    "page": "API",
    "title": "ChipSort.sort_net",
    "category": "method",
    "text": "sort_net(input::Vararg{T, L}) where {L,T}\n\nApplies a sorting network of size L to the input elements, returning a sorted tuple.\n\nThe elements must support the min and max functions. In the case of SIMD.Vec objects each \"lane\" across the vectors will be sorted. Therefore with L vectors of size N this function will produce N sorted sequences of size L, after the data is transposed (see transpose_vecs).\n\n\n\n\n\n"
},

{
    "location": "api/#ChipSort.transpose_vecs-Union{Tuple{Vararg{Vec{N,T},L}}, Tuple{T}, Tuple{N}, Tuple{L}} where T where N where L",
    "page": "API",
    "title": "ChipSort.transpose_vecs",
    "category": "method",
    "text": "transpose_vecs(input::Vararg{Vec{N,T}, L}) where {L,N,T}\n\nTransposes a matrix of L vectors of size N into N vectors of size L. Sizes should be powers of 2.\n\n\n\n\n\n"
},

{
    "location": "api/#ChipSort.first_stream-Union{Tuple{T}, Tuple{N}, Tuple{Union{DataBuffer{N,T}, MergeNode{N,T}},Union{DataBuffer{N,T}, MergeNode{N,T}}}} where T where N",
    "page": "API",
    "title": "ChipSort.first_stream",
    "category": "method",
    "text": "Returns the stream with the smallest first element. If the two streams are empty, returns nothing.\n\n\n\n\n\n"
},

{
    "location": "api/#Functions-1",
    "page": "API",
    "title": "Functions",
    "category": "section",
    "text": "CurrentModule = ChipSortModules = [ChipSort]"
},

{
    "location": "api/#Index-1",
    "page": "API",
    "title": "Index",
    "category": "section",
    "text": ""
},

{
    "location": "benchmark/#",
    "page": "Benchmark",
    "title": "Benchmark",
    "category": "page",
    "text": ""
},

{
    "location": "benchmark/#Benchmark-1",
    "page": "Benchmark",
    "title": "Benchmark",
    "category": "section",
    "text": "Some preliminary experiments comparing the ChipSort performance with the Julia standard sort. Here we are not yet sorting a full array, but just trying to verify that the sorting and merge networks with SIMD pay off in the right conditions, sorting a small chunk of data of an appropriate size. Too little elements and there is too much overhead for the parallelism to be relevant. Too many elements and we start hitting the limits of the processor. When does our chip perform best?This graphic shows the time eCDF from times measured in 10,000 trials using BenchmarkTools.jl. The task is to sort 4 consecutive groups of 64 Float32 numbers in a 256 array. \"Vector\" means a SIMD.jl Vec array, that is supposed to e.g. sit inside a YMM AVX register.<img src=\"../assets/chiptime-f32-256-8x8.png\">Because this is such a small task there is a lot of variation in the measured times. The curve for ChipSort is quite more to the left, though, indicating we do get a speedup in this situation. It is not always the case, though.In this next graphic we show the speed of ChipSort relative to the baseline. The task is different in each case, we are sorting the 256 values in groups of 8 times n, where n is the value in each column. As we can see, once we increase past 8x8 we lose the benefits from the techniques used in ChipSort.<img src=\"../assets/chipspeed-256-8.png\">By increasing the total size of the input array to 16k, although keeping the small size of the chunks we are sorting, the benchmark now results in less variation and also a larger speedup.<img src=\"../assets/chiptime-f32-16k-8x8.png\">The same bar chart with different chunk sizes still shows that performance might degrade, but at the right situation the proposed technique can reach a relative speed of more than 6 times over the baseline.<img src=\"../assets/chipspeed-16k-8.png\">"
},

]}
