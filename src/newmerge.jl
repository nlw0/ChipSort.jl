using SIMD
using StaticArrays

using Revise
using ChipSort


include("../test/testutils.jl")

T = Int8;V = 4;J = 4; K=2
# T = Int32;V = 8;J = 8
# T = Float64;V = 64;J = 64

data = randa(T, V*J*K)
for k ∈ 1:K
    sort!(@view data[1+(k-1)*J*V:k*J*V])
end

mutable struct VecMergeTree{T,V,K,K2,I}
    data::AbstractVector{T}
    cache::SizedArray{Tuple{V,K2},T,2,2}
    ranges::SizedArray{Tuple{2,K},I,2,2}
    over::SizedArray{Tuple{K2},Bool,1,1}
end

# function pop!(ds::VecMergeTree{T,V,K,K2}, k::Int) where {T,V,K,K2}
#     if k < K
#         ka = k<<1
#         kb = ka+1
#         @show va = vloada(Vec{V,T}, pointer(ds.cache.data, 1+(ka-1)*size(ds.cache,1)))
#         @show vb = vloada(Vec{V,T}, pointer(ds.cache.data, 1+(kb-1)*size(ds.cache,1)))
#         @show out,state = bitonic_merge(va,vb)

#         vstore(state, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))

#         load!(ds, ka)
#         load!(ds, kb)
#         out
#     else
#         datak = k-K+1
#         vout = vloadnt(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V*sizeof(T)))
#         vstate = vloadnt(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak])*V*sizeof(T)))
#         vstore(vstate, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
#         ds.ranges[1,datak] += 2
#         vout
#     end
# end

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
        vout = vloadnt(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V*sizeof(T)))
        vstate = vloadnt(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak])*V*sizeof(T)))
        vstore(vstate, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
        ds.ranges[1,datak] += 2
        vout
    end
end

function pop!(ds::VecMergeTree{T,V,K,K2}, k::Int) where {T,V,K,K2}
    if ds.over[k]==true
        nothing
    elseif k < K
        ka = k<<1
        kb = ka+1
        input = if ds.over[ka] && ds.over[kb]
            nothing
        else
            km = if ds.over[kb] || ds.cache[1,ka] < ds.cache[1,kb] ka else kb end
            pop!(ds, km)
        end

        if input == nothing
            state = vloada(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            ds.over[k] = true
            state
        else
            state = vloada(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            out,new_state = bitonic_merge(state, input)
            vstore(new_state, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            out
        end
    else
        datak = k-K+1
        if !ds.over[k] && ds.ranges[1,datak]>ds.ranges[2,datak]
            vstate = vloada(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            ds.over[k] = true
            vstate
        else
            vstate = vloada(Vec{V,T}, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            vnew_state = vloadnt(Vec{V,T}, pointer(ds.data, 1+(ds.ranges[1,datak]-1)*V*sizeof(T)))
            vstore(vnew_state, pointer(ds.cache.data, 1+(k-1)*size(ds.cache,1)))
            ds.ranges[1,datak] += 1
            vstate
        end
    end
end

cache = Size(V,2*K-1)(zeros(T,V,2*K-1))
# ranges = Size(2,K)([1 5 9 13;
                    # 4 8 12 16])
ranges = Size(2,K)([1 5;
                    4 8])
over = Size(2*K-1)(zeros(Bool, 2*K-1))

ds = VecMergeTree(data, cache, ranges, over)

display(reshape(data,V,:));
display(reshape(sort(data),V,:));
display(reshape(ds.cache,V,:));display(ds.ranges);
# pop!(ds, 4)
# pop!(ds, 5)
# pop!(ds, 6)
# pop!(ds, 7)
#

# @show out1=pop!(ds, 2);
# display(reshape(ds.cache,V,:))
# display(ds.ranges)
# @show out2=pop!(ds, 3);
# display(reshape(ds.cache,V,:))
# display(ds.ranges)
@show out=fill_tree!(ds, 1)
display(reshape(ds.cache,V,:));display(ds.ranges);

for it ∈ 1:(J*K)
    @show pop!(ds, 1)
    # display(reshape(ds.cache,V,:));display(ds.ranges);
    # @show ds.over'
end
