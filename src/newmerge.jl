using SIMD
using StaticArrays

using Revise
using ChipSort


include("../test/testutils.jl")

# T = Int8;V = 4;J = 4; K=8
# T = Int16;V = 4;J = 4;K = 4
T = Int32;V = 8;J = 32; K = 32
# T = UInt32;V = 32;J = 2^6; K = 32
# T = Float64;V = 4;J = 8;K = 8
# T = UInt64;V = 16; J = 128; K = 32

data = randa(T, V*J*K)
for k ∈ 1:K
    sort!(@view data[1+(k-1)*J*V:k*J*V])
end

mutable struct VecMergeTree{A<:AbstractVector, B<:AbstractMatrix, C<:AbstractMatrix, T,V,K}   #{T,V,K,I}
    data::A
    cache::B
    ranges::C
    over::Vector{Bool}

    # function VecMergeTree{T,V,K,I}(data, cache, ranges, over) where {T,V,K,I}
        # new{T,V,K,I}(data, cache, ranges, over)
    # end

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
            if ds.over[k]
                nothing
            else
                state = vloada(Vec{V,T}, pointer(ds.cache, 1+(k-1)*size(ds.cache,1)))
                ds.over[k] = true
                state
            end
        else
            km = if ds.over[kb]>0 || ds.over[ka]==0 && ds.cache[1,ka] < ds.cache[1,kb] ka else kb end
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
            ds.over[k]=true
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

# data = valloc(T, div(32, sizeof(T)), K)
# cache = Size(V,2*K-1)(reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1))
cache = reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1)
ranges = reshape([1:J:K*J; J:J:K*J+J-1],:,2)'


# ds = VecMergeTree{T,V,K,Int8}(data, cache, ranges, over)
ds = VecMergeTree(data, cache, ranges, Val(V), Val(K))

display(reshape(data,V,:));
display(reshape(sort(data),V,:));
display(reshape(ds.cache,V,:));display(ds.ranges);
# pop!(ds, 4)
# pop!(ds, 5)
# pop!(ds, 6)
# pop!(ds, 7)

# @show out1=pop!(ds, 2);
# display(reshape(ds.cache,V,:))
# display(ds.ranges)
# @show out2=pop!(ds, 3);
# display(reshape(ds.cache,V,:))
# display(ds.ranges)
@show out=fill_tree!(ds, 1)
display(reshape(ds.cache,V,:));display(ds.ranges);

for it in 1:(J*K-1)
    @show pop!(ds, 1)
    # display(reshape(ds.cache,V,:));display(ds.ranges);
    # @show ds.over'
end

# @code_warntype pop!(ds, 1)
# @code_native pop!(ds, 1)
