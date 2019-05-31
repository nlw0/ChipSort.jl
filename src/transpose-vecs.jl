using SIMD


function transpose_blocks!(data::AbstractVector{T}, ::Val{V}, ::Val{J}) where {T,V,J}
    block_size = V*J
    num_blocks = div(length(data), block_size)

    for k in 1:num_blocks
        block = ntuple(l->vload(Vec{V, T}, data, 1 + (k-1)*block_size + (l-1)*V), Val(J))
        transposed_block = transpose_vecs(block...)
        for v in 1:V
            vstore(transposed_block[v], data, 1 + (k-1)*block_size + (v-1)*J)
        end
    end
    data
end

"""In-place transpose of a 3 dimensional array VKJ into VJK."""
@generated function transpose!(data::AbstractVector{T}, ::Val{V}, ::Val{J}, ::Val{K}) where {T,V,J,K}
    seeds = find_transpose_cycles(Val(K), Val(J))
    :(transpose!(data, Val(V), Val(J), Val(K), $seeds))
end

@inline function transpose!(data::AbstractVector{T}, ::Val{V}, ::Val{J}, ::Val{K}, cycle_seeds) where {T,V,J,K}
    kjm = K*J-1
    @inbounds for c in cycle_seeds
        a = c
        base = pointer(data)
        vlen = V * sizeof(T)
        v1 = vloada(Vec{V, T}, base + vlen * a)
        while true
            pa = (a * K) % kjm
            if pa == c break end
            vpa = vload(Vec{V, T}, base + vlen * pa)
            vstore(vpa, base + vlen * a)
            a = pa
        end
        vstore(v1, base + vlen * a)
    end
    nothing
end

"""Find the cycle seeds to transpose a matrix with K rows and J columns into J rows and K columns."""
function find_transpose_cycles(::Val{J}, ::Val{K}) where {J,K}
    cycles = BitSet(1:K*J-2)
    cycle_seeds = Int32[]
    while length(cycles) > 0
        a = popfirst!(cycles)
        cmin = a
        while true
            pa = (a * K) % (K*J-1)
            if pa ∉ cycles break end
            cmin = min(cmin, pa)
            setdiff!(cycles, Set([pa]))
            a = pa
        end
        push!(cycle_seeds, cmin)
    end
    (cycle_seeds...,)
end


"""
    transpose_vecs(input::Vararg{Vec{N,T}, L}) where {L,N,T}

Transposes a matrix of L vectors of size N into N vectors of size L. Sizes should be powers of 2.
"""
@generated function transpose_vecs(input::Vararg{Vec{N,T}, L})::Vararg{N, Vec{L,T}} where {L,N,T}

    ex = Expr[Expr(:meta, :inline)]

    pa = Val{ntuple(a->((a-1)*N)%(2*N-1), Val(N))}
    pb = Val{ntuple(a->div(N,2)+((a-1)*N)%(2*N-1), Val(N))}

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

    ## Reshape matrix if not square
    if N < L

        outsteps = mylog(div(L,N))
        for st in 1:outsteps
            pcat = Val{ntuple(a->a-1, N*2^st)}
            for t in 1:N*2^(outsteps-st)
                a1 = Symbol("input_", nsteps+st-1, "_", t*2-1)
                a2 = Symbol("input_", nsteps+st-1, "_", t*2)
                b1 = Symbol("input_", nsteps+st, "_", t)
                push!(ex, :($b1 = shufflevector($a1, $a2, $pcat)))
            end
        end

        push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps+outsteps, "_", t), Val(N))...))

    elseif N > L

        outsteps = mylog(div(N,L))
        for st in 1:outsteps
            pleft = Val{ntuple(a->a-1, div(N,2^st))}
            pright = Val{ntuple(a->a-1+div(N,2^st), div(N,2^st))}
            for t in 1:L*2^(st-1)
                a1 = Symbol("input_", nsteps+st-1, "_", t)
                b1 = Symbol("input_", nsteps+st, "_", t*2-1)
                b2 = Symbol("input_", nsteps+st, "_", t*2)
                append!(ex, [:($b1 = shufflevector($a1, $pleft)),
                             :($b2 = shufflevector($a1, $pright))])
            end
        end

        push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps+outsteps, "_", t), Val(N))...))

    else

        push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps, "_", t), Val(L))...))

    end

    quote $(ex...) end
end
