using SIMD


"""
    chipsort_medium!(data, Val(V), Val(J), Val(K))

Sort a medium array in-place. The data is divided between `K` blocks of `J` SIMD vectors of size `V`. The array should typically fit inside lower levels of cache memory (L1 or L2), for instance 8192 Int32 values on an conventional desktop computer. Our recipe is:
 - Generate small sorted vectors.
 - Use vectorized Comb sort.
 - Transpose in-place.
 - Finish with insertion sort over the nearly sorted array.

# Examples
```jldoctest
julia> chipsort_medium!(Int32[1:2^13...] .* 0xf0ca .%0x10000, Val(8), Val(8), Val(64))'
1×8192 LinearAlgebra.Adjoint{Int32,Array{Int32,1}}:
 30  32  34  36  38  70  72  74  76  108  110  112  114  116  …  65488  65490  65492  65494  65496  65528  65530  65532  65534
```
"""
function chipsort_medium!(input::AbstractVector{T}, ::Val{V}, ::Val{J}, ::Val{K}) where {T,V,J,K}

    sort_vecs!(input, Val(J), Val(V), Val(true))

    vectorized_combsort!(input, Val(J))

    transpose_blocks!(input, Val(V), Val(J))

    transpose!(input, Val(V), Val(K), Val(J))

    vectorized_combsort!(input, Val(J))

    sort_vecs!(input, Val(V), Val(J), Val(false))

    insertion_sort!(input)

    input
end

function vectorized_combsort!(input::AbstractArray{T,1}, ::Val{V}) where {T,V}
    la = length(input)

    interval = 3 * div(la, 32) * 8

    logV = mylog(V)
    interval = (la >> (2+logV)) * (3 * V)

    while interval > 0
        ap = pointer(input,1)
        finalp = pointer(input, la-interval)
        while ap < finalp
            a1 = vloada(Vec{V,T}, ap)
            a2 = vloada(Vec{V,T}, ap + interval*sizeof(T))
            b1 = min(a1, a2)
            b2 = max(a1, a2)
            vstorea(b1, ap)
            vstorea(b2, ap + interval*sizeof(T))
            ap = ap + V * sizeof(T)
        end
        interval = if interval==V 0 else max(V, (interval >> (2+logV)) * (3 * V)) end
    end

    input
end


"""Insertion sort, adapted from the Julia codebase."""
@inline function insertion_sort!(v::AbstractVector)
    lo, hi = 1, length(v)
    @inbounds for i = lo+1:hi
        j = i
        x = v[i]
        while j > lo
            if x <= v[j-1]
                v[j] = v[j-1]
                j -= 1
                continue
            end
            break
        end
        v[j] = x
    end
    return v
end


"""Regular version of Comb sort."""
function combsort!(input::AbstractArray{T,1}, initial_interval=nothing::Union{Nothing,Int}) where T

    la = length(input)
    interval = if (initial_interval == nothing)
        (3 * la) >> 2
    else
        initial_interval
    end

    @inbounds while interval > 1
        for i in 1:la-interval
            a1 = input[i]
            a2 = input[i+interval]
            input[i] = min(a1, a2)
            input[i+interval] = max(a1, a2)
        end
        interval = (3 * interval) >> 2
    end

    change = true
    interval=1
    @inbounds while change
        change = false
        for i in 1:la-1
            if input[i] > input[i+1]
                change = true
                a1 = input[i]
                a2 = input[i+interval]
                input[i] = min(a1, a2)
                input[i+interval] = max(a1, a2)
            end
        end
    end

    input
end
