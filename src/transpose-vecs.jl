using SIMD


"""
    transpose_vecs(input::Vararg{Vec{N,T}, L}) where {L,N,T}

Transposes a matrix of L vectors of size N into N vectors of size L. Sizes should be powers of 2.
"""
@generated function transpose_vecs(input::Vararg{Vec{N,T}, L}) where {L,N,T}

    ex = Expr[Expr(:meta, :inline)]

    pa = Val{ntuple(a->((a-1)*N)%(2*N-1), N)}
    pb = Val{ntuple(a->div(N,2)+((a-1)*N)%(2*N-1), N)}

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

        push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps+outsteps, "_", t), N)...))

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

        push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps+outsteps, "_", t), N)...))

    else

        push!(ex, Expr(:tuple, ntuple(t->Symbol("input_", nsteps, "_", t), L)...))

    end

    quote $(ex...) end
end
