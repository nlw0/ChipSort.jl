using SIMD
using StaticArrays

using BenchmarkTools
using Revise
using ChipSort


mutable struct VecMergeTree{A<:AbstractVector, B<:AbstractMatrix, C<:AbstractMatrix, T,V,K}   #{T,V,K,I}
    data::A
    cache::B
    ranges::C
    over::Vector{Bool}

    function VecMergeTree(data::AbstractVector{T}, cache::AbstractArray{T}, ranges::AbstractArray{I}, ::Val{V},::Val{K}) where {T,V,K,I}
        over = zeros(Bool, 2*K-1)
        new{typeof(data), typeof(cache), typeof(ranges),T,V,K}(data, cache, ranges, over)
    end
end

function fill_tree!(ds::VecMergeTree{A,B,C,T,V,K}, k::Int64) where {A,B,C,T,V,K}
    if k < K
        ka = k<<1
        kb = ka+1
        va=fill_tree!(ds, ka)
        vb=fill_tree!(ds, kb)
        out,state = bitonic_merge(va,vb)
        vstore(state, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
        out
    else
        datak = k-K+1
        vout = vloada(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V))
        vstate = vloada(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak])*V))
        vstorea(vstate, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
        ds.ranges[1,datak] += 1
        vout
    end
end

@inline function pop!(ds::VecMergeTree{A,B,C,T,V,K}, k::Int) where {A,B,C,T,V,K}
    @inbounds if k < K
        ka = k<<1
        kb = ka+1

        if ds.over[ka] && ds.over[kb]
            ds.over[k] = true
            vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
        else
            km = if ds.over[kb] || !ds.over[ka] && ds.cache[1,ka] < ds.cache[1,kb] ka else kb end
            input = pop!(ds, km)
            state = vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
            out,new_state = bitonic_merge(state, input)
            vstorea(new_state, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
            out
        end
    else
        datak = k-K+1
        if (ds.ranges[1,datak]>=ds.ranges[2,datak])
            vstate = vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
            ds.over[k] = true
            vstate
        else
            ds.ranges[1,datak] += 1
            vstate = vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
            vnew_state = vloada(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V))
            vstorea(vnew_state, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
            vstate
        end
    end
end

@inline function pop2!(ds::VecMergeTree{A,B,C,T,V,K}, k::Int) where {A,B,C,T,V,K}
    @inbounds begin
    # Find next leaf to merge and update
    k = 1
    ka = k<<1
    kb = ka+1
    while k < K && !(ds.over[ka] && ds.over[kb])
        k = if ds.over[kb] || !ds.over[ka] && ds.cache[1,ka] <= ds.cache[1,kb] ka else kb end
        ka = k<<1
        kb = ka+1
    end

    ## First vector to be merged descending the tree, from the leaves to root.
    out = vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*V))

    @inbounds if k >= K && ds.ranges[1,k-K+1] < ds.ranges[2,k-K+1]
        datak = k-K+1
        vnew_state = vloada(Vec{V,T}, pointer(ds.data, 1+ds.ranges[1,datak]*V))
        ds.ranges[1,datak] += 1
        vstorea(vnew_state, pointer(ds.cache, 1+(k-1)*V))
    else  # implies `ds.over[ka] && ds.over[kb]` or ds.ranges[1,k-K+1] >= ds.ranges[2,k-K+1]
        ds.over[k] = true
    end

    k = k>>1
    @inbounds while k>0
        state = vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*V))
        out, new_state = bitonic_merge(state, out)
        vstorea(new_state, pointer(ds.cache, 1+(k-1)*V))
        k = k>>1
    end
    end
    out
end

include("../test/testutils.jl")

# T = Int8;V = 4;J = 4; K=4
# T = Int16;V = 8;J = 4;K = 8
# T = Int32;V = 8;J = 32; K = 32
T = UInt32;V = 32;J = 8; K = 128
# T = Float32;V = 32;J = 16; K = 8
# T = Float64;V = 4;J = 8;K = 8
# T = UInt64;V = 16; J = 128; K = 32

# data = randa(T, V*J*K)
# for k ∈ 1:K
#     sort!(@view data[1+(k-1)*J*V:k*J*V])
# end

# cache = reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1)
# ranges = copy(reshape([1:J:K*J; J:J:K*J+J-1],:,2)')
# ds = VecMergeTree(data, cache, ranges, Val(V), Val(K))

# display(reshape(data,V,:));
# display(reshape(sort(data),V,:));

# @show out=fill_tree!(ds, 1)
# display(reshape(ds.cache,V,:));display(ds.ranges);
# for it in 1:(J*K-2)
#     @show pop2!(ds, 1)
# end


data = randa(T, V*J*K)
cache = reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1)
ranges = copy(reshape([1:J:K*J; J:J:K*J+J-1],:,2)')
for k ∈ 1:K
    sort!(@view data[1+(k-1)*J*V:k*J*V])
end
ds = VecMergeTree(data, cache, ranges, Val(V), Val(K))
fill_tree!(ds, 1)

function f1(ds,J,K)
    for it in 1:(J*K-2)
        pop!(ds, 1)
    end
    pop!(ds, 1)
end

function f2(ds,J,K)
    for it in 1:(J*K-2)
        pop2!(ds, 1)
    end
    pop2!(ds, 1)
end

@time f2(ds,J,K)

data = randa(T, V*J*K)
cache = reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1)
ranges = copy(reshape([1:J:K*J; J:J:K*J+J-1],:,2)')
for k ∈ 1:K
    sort!(@view data[1+(k-1)*J*V:k*J*V])
end
ds = VecMergeTree(data, cache, ranges, Val(V), Val(K))
fill_tree!(ds, 1)
@time f1(ds,J,K)

# @code_warntype pop!(ds, 1)
# @code_native debuginfo=:none pop!(ds, 1)
# @code_warntype pop2!(ds, 1)
# @code_native pop2!(ds, 1)
# @code_native debuginfo=:none pop2!(ds, 1)
