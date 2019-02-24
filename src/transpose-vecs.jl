using SIMD


mylog(n) = if n == 1 0 else 1 + mylog(n>>1) end


@generated function transpose_vecs(input::Vararg{Vec{N,T}, L}) where {L,N,T}

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
