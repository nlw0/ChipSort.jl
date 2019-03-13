## Implements bitonic merge networks that can merge two sorted SIMD vectors.
## The generated function supports any possible type and size.

using SIMD


function inverse_shuffle(tt)
    out = copy(tt)
    for n in 1:length(tt)
        out[tt[n]] = n
    end
    out
end


function bitonic_step(G, Glen)
    N = G * Glen
    gg = reshape(1:N, Glen, G)
    t_lh = [gg[:,1:2:end][:]; gg[:,2:2:end][:]]
end

"""
    bitonic_merge(input_a::Vec{N,T}, input_b::Vec{N,T}) where {N,T}

Merges two `SIMD.Vec` objects of the same type and size using a bitonic sort network. The inputs are assumed to be sorted. Returns a pair of vectors with the first and second halves of the merged sequence.
"""
@generated function bitonic_merge(input_a::Vec{N,T}, input_b::Vec{N,T}) where {N,T}

    pat = Val{ntuple(x->N-x, N)}

    ex = [
        Expr(:meta, :inline),
        :(la_0 = input_a),
        :(lb_0 = shufflevector(input_b, $pat)),
        :(L_0 = min(la_0, lb_0)),
        :(H_0 = max(la_0, lb_0))
    ]

    p = mylog(N)
    for n in 1:p
        la = Symbol("la_", n)
        lb = Symbol("lb_", n)
        Lp = Symbol("L_", n-1)
        Hp = Symbol("H_", n-1)
        L = Symbol("L_", n)
        H = Symbol("H_", n)

        ih = inverse_shuffle(bitonic_step(2^(n), 2^(p-n+1)))
        sh = bitonic_step(2^(n+1), 2^(p-n))
        pat_a = Val{tuple((ih[sh[1:N]].-1)...)}
        pat_b = Val{tuple((ih[sh[(N+1):end]].-1)...)}

        append!(ex, [
            :($la = shufflevector($Lp, $Hp, $pat_a)),
            :($lb = shufflevector($Lp, $Hp, $pat_b)),
            :($L = min($la, $lb)),
            :($H = max($la, $lb))
        ])
    end

    la = Symbol("la_", p+1)
    lb = Symbol("lb_", p+1)
    Lp = Symbol("L_", p)
    Hp = Symbol("H_", p)

    ih = inverse_shuffle(bitonic_step(2N, 1))
    pat_a = Val{tuple((ih[1:N].-1)...)}
    pat_b = Val{tuple((ih[(N+1):end].-1)...)}

    append!(ex, [
        :($la = shufflevector($Lp, $Hp, $pat_a)),
        :($lb = shufflevector($Lp, $Hp, $pat_b)),
        :(($la, $lb))
    ])

    quote $(ex...) end
end


"""
    bitonic_merge(input_a::Vec{N,T}, input_b::Vec{N,T}) where {N,T}

Merges two `SIMD.Vec` objects of the same type and size using a bitonic sort network. The inputs are assumed to be sorted. Returns a pair of vectors with the first and second halves of the merged sequence.
"""
@generated function bitonic_merge2(input_a::Vec{N,T}, input_b, output) where {N,T}

    pat = Val{ntuple(x->N-x, N)}

    ex = [
        Expr(:meta, :inline),
        :(la_0 = input_a),
        :(lb_0 = shufflevector(vload(Vec{N,T},input_b), $pat)),
        :(L_0 = min(la_0, lb_0)),
        :(H_0 = max(la_0, lb_0))
    ]

    p = mylog(N)
    for n in 1:p
        la = Symbol("la_", n)
        lb = Symbol("lb_", n)
        Lp = Symbol("L_", n-1)
        Hp = Symbol("H_", n-1)
        L = Symbol("L_", n)
        H = Symbol("H_", n)

        ih = inverse_shuffle(bitonic_step(2^(n), 2^(p-n+1)))
        sh = bitonic_step(2^(n+1), 2^(p-n))
        pat_a = Val{tuple((ih[sh[1:N]].-1)...)}
        pat_b = Val{tuple((ih[sh[(N+1):end]].-1)...)}

        append!(ex, [
            :($la = shufflevector($Lp, $Hp, $pat_a)),
            :($lb = shufflevector($Lp, $Hp, $pat_b)),
            :($L = min($la, $lb)),
            :($H = max($la, $lb))
        ])
    end

    la = Symbol("la_", p+1)
    lb = Symbol("lb_", p+1)
    Lp = Symbol("L_", p)
    Hp = Symbol("H_", p)

    ih = inverse_shuffle(bitonic_step(2N, 1))
    pat_a = Val{tuple((ih[1:N].-1)...)}
    pat_b = Val{tuple((ih[(N+1):end].-1)...)}

    append!(ex, [
        :($la = shufflevector($Lp, $Hp, $pat_a)),
        :($lb = shufflevector($Lp, $Hp, $pat_b)),
        :(vstore($la, output)),
        :(return $lb)
    ])

    quote $(ex...) end
end


@inline function bitonic_merge_concat(input_a::Vec{N,T}, input_b::Vec{N,T})::Vec{2*N,T} where {N,T}
    m_a, m_b = bitonic_merge(input_a, input_b)
    concat(m_a, m_b)
end


## These brave functions merge 4, 8 vectors or even more. Relies on the great ability from SIMD.jl and LLVM to handle
## large vectors. Performance not yet tested.
@generated function merge_vecs(input::Vararg{Vec{N,T}, L}) where {L,N,T}

    ex = [Expr(:meta, :inline)]

    for l in 1:L
        m = Symbol("m_0_", l)
        push!(ex, :($m = input[$l]))
    end

    p = mylog(L)
    for l in 1:p
        for b in 1:2^(p-l)
            m = Symbol("m_", l, "_", b)
            a1 = Symbol("m_", l-1, "_", b*2-1)
            a2 = Symbol("m_", l-1, "_", b*2)
            push!(ex, :($m = bitonic_merge_concat($a1, $a2)))
        end
    end

    m = Symbol("m_", p, "_", 1)
    push!(ex, :(return $m))

    quote $(ex...) end
end

"""
    bitonic_merge_interleaved(input::Vec{N,T}...)

Merges multiple pairs of `SIMD.Vec` objects of the same type and size using a bitonic sort network, with interleaved execution. The inputs are assumed to be sorted. Returns a tuple with pairs of vectors with the first and second halves of the merged sequences.
"""
@generated function bitonic_merge_interleaved(input::Vararg{Vec{N,T}, L}) where {L,N,T}

    allex = []
    out_tuple = []
    for indy in 1:div(L,2)
        iSymbol(x...) = Symbol("indy_", indy, "_", x...)
        pat = Val{ntuple(x->N-x, N)}

        n = 0
        la = iSymbol("la_", n)
        lb = iSymbol("lb_", n)
        L = iSymbol("L_", n)
        H = iSymbol("H_", n)
        ex = [

            :($la = input[$(indy*2-1)]),
            :($lb = shufflevector(input[$(indy*2)], $pat)),
            :($L = min($la, $lb)),
            :($H = max($la, $lb))
        ]

        p = mylog(N)
        for n in 1:p
            la = iSymbol("la_", n)
            lb = iSymbol("lb_", n)
            Lp = iSymbol("L_", n-1)
            Hp = iSymbol("H_", n-1)
            L = iSymbol("L_", n)
            H = iSymbol("H_", n)

            ih = inverse_shuffle(bitonic_step(2^(n), 2^(p-n+1)))
            sh = bitonic_step(2^(n+1), 2^(p-n))
            pat_a = Val{tuple((ih[sh[1:N]].-1)...)}
            pat_b = Val{tuple((ih[sh[(N+1):end]].-1)...)}

            append!(ex, [
                :($la = shufflevector($Lp, $Hp, $pat_a)),
                :($lb = shufflevector($Lp, $Hp, $pat_b)),
                :($L = min($la, $lb)),
                :($H = max($la, $lb))
            ])
        end

        la = iSymbol("la_", p+1)
        lb = iSymbol("lb_", p+1)
        Lp = iSymbol("L_", p)
        Hp = iSymbol("H_", p)

        ih = inverse_shuffle(bitonic_step(2N, 1))
        pat_a = Val{tuple((ih[1:N].-1)...)}
        pat_b = Val{tuple((ih[(N+1):end].-1)...)}

        append!(ex, [
            :($la = shufflevector($Lp, $Hp, $pat_a)),
            :($lb = shufflevector($Lp, $Hp, $pat_b)),
        ])
        push!(allex, ex)
        append!(out_tuple, [la, lb])
    end

    inteleaved = [x for xx in zip(allex...) for x in xx]

    final_ex = [
        Expr(:meta, :inline),
        inteleaved...,
        Expr(:tuple, out_tuple...)
    ]

    quote $(final_ex...) end
end
