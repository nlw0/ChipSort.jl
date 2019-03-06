# ChipSort.jl

<p align="center">
  <img src="docs/src/assets/logo.png" width="50%" title="ChipSort logo">
</p>

ChipSort is a sorting module containing SIMD and cache-aware techniques. It's based on a couple of academic papers from 2008. More details can be found in [our documentation](https://nlw0.github.io/ChipSort.jl).

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://nlw0.github.io/ChipSort.jl/dev)
<img src="https://travis-ci.org/nlw0/ChipSort.jl.svg?branch=master" />
[![codecov](https://codecov.io/gh/nlw0/ChipSort.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/nlw0/ChipSort.jl)

## Installation and usage

Like any experimental Julia package on GitHub you can install ChipSort by first  typing `]` to enter the package management shell, and then

```
pkg> add https://github.com/nlw0/ChipSort.jl
```

You can now try out the basic functions offered by the package such as `sort_net` to use a sorting network, or the initial sorting prototype implementation `chipsort`.

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
