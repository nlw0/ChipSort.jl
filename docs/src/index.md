```@raw html
<center><img src="assets/logo.svg" width="50%"></center>
```

# ChipSort.jl Documentation

[ChipSort](https://github.com/nlw0/ChipSort.jl) is a Julia module that implements SIMD and cache-aware sorting techniques.

This documentation contains:
- A description of the [API](api.md) and how to use the Julia functions defined in the module.
- A presentation of the [theory](theory.md) behind ChipSort.
- A report with some [benchmark](benchmark.md) results.


## Installation and basic usage

Like any experimental Julia package on GitHub you can install ChipSort by first  typing `]` to enter the package management shell, and then

```
pkg> add https://github.com/nlw0/ChipSort.jl
```

You can now try out the basic functions offered by the package such as `sort_net()` to use a sorting network, or use the complete array sorting function prototype `chipsort()`.

```
julia> using ChipSort

julia> using SIMD

julia> data = [Vec(tuple(rand(Int8, 4)...)) for _ in 1:4]
4-element Array{Vec{4,Int8},1}:
 <4 x Int8>[-15, 98, 5, -28]
 <4 x Int8>[47, -112, 98, -14]
 <4 x Int8>[-18, -3, -111, 85]
 <4 x Int8>[79, -12, -44, -85]

julia> x = sort_net(data...)
(<4 x Int8>[-18, -112, -111, -85], <4 x Int8>[-15, -12, -44, -28], <4 x Int8>[47, -3, 5, -14], <4 x Int8>[79, 98, 98, 85])

julia> y = transpose_vecs(x...)
(<4 x Int8>[-18, -15, 47, 79], <4 x Int8>[-112, -12, -3, 98], <4 x Int8>[-111, -44, 5, 98], <4 x Int8>[-85, -28, -14, 85])

julia> z = merge_vecs(y...)
<16 x Int8>[-112, -111, -85, -44, -28, -18, -15, -14, -12, -3, 5, 47, 79, 85, 98, 98]

julia> bigdata = rand(Int16, 256);

julia> chipsort(bigdata, Val(8), Val(8), Val(8)) == sort(bigdata)
true
```
