using SIMD


function chipsort_large(input::AbstractVector{T}, ::Val{V}, ::Val{K}) where {T,V,K}
    @inbounds begin
    J = div(length(input), V*K)
    chunks = reshape(valloc(T, div(32, sizeof(T)), V*J*K), V*J, K)
    output = valloc(T, div(32, sizeof(T)), V*J*K)
    chunks[:] .= input
    for k in 1:K
        chipsort_medium!((@view chunks[:,k]), Val(V), Val(V), Val(div(J,V)))
    end

    ds = VecMergeTree(chunks.parent, Val(V), Val(K))

    pout = pointer(output, 1)
    out = fill_tree!(ds, 1)
    vstorea(out, pout)
    pout += V*sizeof(T)
    for it in 1:(J*K-1)
        out = pop!(ds)
        vstorea(out, pout)
        pout += V*sizeof(T)
    end
    end
    output
end


struct VecMergeTree{A<:AbstractVector, B<:AbstractMatrix, C<:AbstractMatrix, T,V,K}   #{T,V,K,I}
    data::A
    cache::B
    ranges::C
    over::Vector{Bool}

    function VecMergeTree(data::AbstractVector{T}, ::Val{V},::Val{K}) where {T,V,K,I}
        cache = reshape(valloc(T, div(32, sizeof(T)), V*(2*K-1)), V, 2*K-1)
        J = div(length(data), V*K)
        ranges = copy(reshape([1:J:K*J; J:J:K*J+J-1],:,2)')
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

@inline function pop!(ds::VecMergeTree{A,B,C,T,V,K}) where {A,B,C,T,V,K}
    @inbounds begin
    ## Find next leaf to merge and update
    k = 1
    ka = k<<1
    kb = ka+1
    while k < K && !(ds.over[ka] && ds.over[kb])
        k = if ds.over[kb] || !ds.over[ka] && ds.cache[1+V*(ka-1)] <= ds.cache[1+V*(kb-1)] ka else kb end
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
# T = Int32;V = 8;J = 2^12; K = 32
T = Int32;V = 8;J = 2^12; K = 32
# T = UInt32;V = 32;J = 8; K = 128
# T = Float32;V = 32;J = 16; K = 8
# T = Float64;V = 4;J = 8;K = 8
# T = UInt64;V = 16; J = 128; K = 32

len=V*J*K
display(@benchmark sort(data) setup=(data = randa($T, $len)))
display(@benchmark chipsort_large(data, Val(V), Val(K))  setup=(data = randa($T, $len)))

using Profile
data = randa(T, len)
@profile for j in 1:100
    data = randa(T, len)
    chipsort_large(data, Val(V), Val(K))
end
Profile.print(maxdepth=8)

# @code_native debuginfo=:none chipsort_large(data, Val(V), Val(K))
# @code_warntype pop!(ds, 1)
# @code_native debuginfo=:none pop!(ds, 1)
