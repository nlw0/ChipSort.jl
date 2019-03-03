using SIMD


@generated function transpose_vecs(input::Vararg{Vec{N,T}, N}) where {N,T}
    L = N
    ex = Expr[Expr(:meta, :inline)]

    pa = Val{ntuple(a->((a-1)*L)%(2*L-1), L)}
    pb = Val{ntuple(a->div(L,2)+((a-1)*L)%(2*L-1), L)}

    for t in 1:L
        a1 = Symbol("input_", 0, "_", t)
        push!(ex, :($a1 = input[$t]))
    end

    nsteps = mylog(L)

    L_2 = div(L,2)

    for st in 1:nsteps
        for t in 1:L_2
            a1 = Symbol("input_", st-1, "_", t)
            a2 = Symbol("input_", st-1, "_", t+L_2)
            b1 = Symbol("input_", st, "_", t*2-1)
            b2 = Symbol("input_", st, "_", t*2)
            append!(ex, [:($b1 = shufflevector($a1, $a2, $pa)),
                         :($b2 = shufflevector($a1, $a2, $pb))])
        end
    end

    push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps, "_", t), L)...))

    quote $(ex...) end
end

"""
Handles "tall" matrices by transposing each vertical half and concatenating horizontally.
"""
@inline function transpose_vecs_tall(input::Vararg{Vec{N,T}, L}) ::NTuple{N, Vec{L, T}} where {L,N,T}
    L2 = div(L,2)
    top = input[1:L2]
    bottom = input[1+L2:L]
    left = transpose_vecs(top...)
    right = transpose_vecs(bottom...)
    ntuple(l->concat(left[l], right[l]), L2)
end

"""
Handles "wide" matrices by transposing each horizontal half and concatenating vertically.
"""
@inline function transpose_vecs_wide(input::Vararg{Vec{N,T}, L}) ::NTuple{N, Vec{L, T}} where {L,N,T}
    N2 = div(N,2)
    half_l = Val{ntuple(n->n-1, N2)}
    half_r = Val{ntuple(n->N2+n-1, N2)}
    left = ntuple(l->shufflevector(input[l], half_l), L) ::NTuple{L, Vec{N2,T}}
    right = ntuple(l->shufflevector(input[l], half_r), L) ::NTuple{L, Vec{N2,T}}
    (transpose_vecs(left...)...,transpose_vecs(right...)...)
end
