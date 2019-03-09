# Algorithms in detail

Most of ChipSort.jl was implemented as generated functions, a very interesting and powerful Julia feature for meta-programming. Programming can be difficult, but meta-programming takes it to another level! It may be hard to figure out how our functions work by just reading the code. Something that might help is to look at some of the generated code instead.

## Sorting networks

Sorting networks are built from a fundamental operation, the comparator, that takes two values in and outputs them in order. By organizing these operations correctly we can build a network that takes a sequence of multiple values in and outputs them in order. For the sake of efficiency, when designing such a network we usually try to use as few operations as possible and also allow them to occur in parallel.

```@raw html
<center><img src="../assets/sorting-network-4.svg" width="70%"/></center>
```

Figure 1 shows a sorting network for 4 elements. It has three steps, inside of which all operations might be carried out in parallel. These steps form a pipeline where a sequence output by one step is the input to the next one.

The topology of a network is described by a list of lists of pairs. Each inner list describes one of the steps from the pipeline. This is how the network from Figure 1 is described [in our codebase](https://github.com/nlw0/ChipSort.jl/blob/5f919bd33e63d188b750b3809c299c46afae62c3/src/sorting-network-parameters.jl#L7).

```julia
[[(1,2), (3,4)], [(1,3), (2,4)], [(2,3)]
```

We could implement a function that implements this network like this:



```
julia> sort_net(rand(4)...)
(0.38853316133037974, 0.5797414421267342, 0.6886307923331891, 0.976193242415401)
```


julia> include("/home/user/src/ChipSort.jl/src/sorting-networks.jl")
quote
    #= /home/user/src/ChipSort.jl/src/sorting-networks.jl:50 =#
    $(Expr(:meta, :inline))
    input_0_1 = input[1]
    input_0_2 = input[2]
    input_0_3 = input[3]
    input_0_4 = input[4]
    input_1_1 = min(input_0_1, input_0_2)
    input_1_2 = max(input_0_1, input_0_2)
    input_1_3 = min(input_0_3, input_0_4)
    input_1_4 = max(input_0_3, input_0_4)
    input_2_1 = min(input_1_1, input_1_3)
    input_2_3 = max(input_1_1, input_1_3)
    input_2_2 = min(input_1_2, input_1_4)
    input_2_4 = max(input_1_2, input_1_4)
    input_3_1 = input_2_1
    input_3_4 = input_2_4
    input_3_2 = min(input_2_2, input_2_3)
    input_3_3 = max(input_2_2, input_2_3)
    (input_3_1, input_3_2, input_3_3, input_3_4)
end
