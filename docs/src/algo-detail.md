# Algorithms in detail

Most of ChipSort.jl was implemented as generated functions, a very interesting and powerful Julia feature for meta-programming. Programming can be difficult, but meta-programming takes it to another level! It may be hard to figure out how our functions work by just reading the code. Something that might help is to look at some of the generated code instead.

## Sorting networks

Sorting networks are built from a fundamental operation, the comparator, that takes two values in and outputs them in order. By organizing these comparators correctly we can build a network that takes in a sequence of multiple values and outputs the sorted sequence. For the sake of efficiency, when designing such a network we try to use as few operations as possible and also allow them to occur in parallel.

```@raw html
<center><img src="../assets/sorting-network-4.svg" width="70%"/></center>
```

Figure 1 shows a sorting network for 4 elements. It has three steps, inside of which all operations might be carried out in parallel. These steps form a pipeline where a sequence output by one step is the input to the next one.

The topology of a network is described by a list of lists of pairs. Each inner list describes one of the steps from the pipeline. This is how the network from Figure 1 is described [in our codebase](https://github.com/nlw0/ChipSort.jl/blob/5f919bd33e63d188b750b3809c299c46afae62c3/src/sorting-network-parameters.jl#L7), using arrays.

```julia
network = [[(1,2), (3,4)], [(1,3), (2,4)], [(2,3)]
```

We could implement this sorting network like this:
```julia
for step in 1:N
	for (a,b) in network[step]
		seq[a], seq[b] = minmax(seq[a], seq[b])
	end
end
```
What we actually do in our generated function is essentially to unroll this loop, and represent each sequence value at each step as a transient program variable.

Generated functions work like this: it is a function that takes as arguments the types of the arguments of the function you are going to generate. We then output a Julia `Expr` object which is the body of the function. Julia then compiles and runs this function.

Another way to do the same thing in Julia would be to just have some function that builds definitions for the different sorting networks, for instance, and then `eval` them. This is perhaps a more explicit way to do things, and clearly shows that one thing is the meta-program that generates the expressions of new functions, and another thing are these generated functions. Julia's `@generated` functions are just a convenience that lets you declare this meta-programming function the same way as you would declare the functions it generates. It might seem to confuse things a bit, but once you start working with this kind of functions it becomes clear this is a very nice and handy concept.

Executing our sorting network function with 4 values outputs a sorted tuple.
```
julia> sort_net(43, 17, 81, 2)
(2, 17, 43, 81)
```
If we simply remove the `@generated` from our function declaration what we get instead is the function body that we generated.

```
julia> include("non-generated-sorting-networks.jl")
julia> sort_net(43, 17, 81, 2)
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
```
