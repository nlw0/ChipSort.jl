using SIMD
using StaticArrays

using Revise
using ChipSort


include("../test/testutils.jl")

# T = Int8;V = 4;J = 4; K=4
# T = Int16;V = 4;J = 4;K = 4
T = Int32;V = 8;J = 32; K = 32
# T = Float64;V = 4;J = 8;K = 8
# T = UInt64;V = 8; J = 16; K = 16

data = randa(T, V*J*K)
for k ∈ 1:K
    sort!(@view data[1+(k-1)*J*V:k*J*V])
end

mutable struct VecMergeTree{T,V,K,K2,I}
    data::AbstractVector{T}
    cache::SizedArray{Tuple{V,K2},T,2,2}
    ranges::SizedArray{Tuple{2,K},I,2,2}
    over::SizedArray{Tuple{K2},UInt8,1,1}
end

function fill_tree!(ds::VecMergeTree{T,V,K,K2}, k::Int) where {T,V,K,K2}
    if k < K
        ka = k<<1
        kb = ka+1
        va=fill_tree!(ds, ka)
        vb=fill_tree!(ds, kb)
        out,state = bitonic_merge(va,vb)
        vstore(state, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
        out
    else
        datak = k-K+1
        vout = vload(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V))
        vstate = vload(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak])*V))
        vstore(vstate, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
        ds.ranges[1,datak] += 1
        vout
    end
end

function pop!(ds::VecMergeTree{T,V,K,K2}, k::Int) where {T,V,K,K2}
    if k < K
        ka = k<<1
        kb = ka+1
        input = if ds.over[ka]==2 && ds.over[kb]==2
            nothing
        else
            km =
                if ((ds.over[kb]>0) ||
                    ((ds.over[ka]==0) &&
                     (ds.cache[1,ka] < ds.cache[1,kb])))
                    ka
                else
                    kb
                end
            pop!(ds, km)
        end

        if input == nothing && ds.over[k]>0
            ds.over[k]=2
            nothing
        elseif input == nothing && ds.over[k]==0
            state = vload(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            ds.over[k]=1
            state
        else
            state = vload(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            out,new_state = bitonic_merge(state, input)
            vstore(new_state, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            out
        end
    else
        datak = k-K+1
        if (ds.ranges[1,datak]>=ds.ranges[2,datak]) && ds.over[k]>0
            ds.over[k]=2
            nothing
        elseif (ds.ranges[1,datak]>=ds.ranges[2,datak]) && ds.over[k]==0
            ds.ranges[1,datak] += 1
            vstate = vload(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            ds.over[k]=1
            vstate
        else
            ds.ranges[1,datak] += 1
            vstate = vload(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            vnew_state = vload(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V))
            vstore(vnew_state, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            vstate
        end
    end
end

# data = valloc(T, div(32, sizeof(T)), K)
cache = Size(V,2*K-1)(copy(reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1)))
ranges = Size(2,K)(copy(reshape([1:J:K*J; J:J:K*J+J-1],:,2)'))
over = Size(2*K-1)(zeros(UInt8, 2*K-1))

ds = VecMergeTree(data, cache, ranges, over)

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

for it in 1:(J*K)
    @show pop!(ds, 1)
    # display(reshape(ds.cache,V,:));display(ds.ranges);
    # @show ds.over'
end
