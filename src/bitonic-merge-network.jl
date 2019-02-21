## Implements bitonic merge networks that can merge two sorted SIMD vectors.
## The generated function supports any possible type and size.

using SIMD


mylog(n) = if n == 1 0 else 1 + mylog(n>>1) end


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


@generated function bitonic_merge(input_a::Vec{N,T}, input_b::Vec{N,T}) where {N,T}

    pat = Val{ntuple(x->N-x, N)}

    ex = [
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


## Function draft based on arrays
#
# function bitonic_network(la, lb)
#     G = size(la, 1)
#     lb = lb[end:-1:1]
#     L = min.(la, lb)
#     H = max.(la, lb)
#     p = mylog(G)
#     for n in 1:p
#         ih = inverse_shuffle(bitonic_step(2^(n), 2^(p-n+1)))
#         sh = bitonic_step(2^(n+1), 2^(p-n))
#         la = [L;H][ih[sh[1:G]]]
#         lb = [L;H][ih[sh[(G+1):end]]]
#         L = min.(la, lb)
#         H = max.(la, lb)
#     end
#     ih = inverse_shuffle(bitonic_step(2G, 1))
#     la = [L;H][ih[1:G]]
#     lb = [L;H][ih[(G+1):end]]
#     la, lb
# end
