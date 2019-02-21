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

function bitonic_network(la, lb)
    G = size(la, 1)

    lb = lb[end:-1:1]

    L = min.(la, lb)
    H = max.(la, lb)

    p = mylog(G)
    for n in 1:p
        ih = inverse_shuffle(bitonic_step(2^(n), 2^(p-n+1)))
        sh = bitonic_step(2^(n+1), 2^(p-n))

        la = [L;H][ih[sh[1:G]]]
        lb = [L;H][ih[sh[(G+1):end]]]
        L = min.(la, lb)
        H = max.(la, lb)
    end

    ih = inverse_shuffle(bitonic_step(2G, 1))
    la = [L;H][ih[1:G]]
    lb = [L;H][ih[(G+1):end]]

    la, lb
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


function test_merge_types_sizes(T, N)
    va = Vec(tuple(sort(rand(T, N))...))
    vb = Vec(tuple(sort(rand(T, N))...))
    println(va)
    println(vb)
    a, b = bitonic_merge(va, vb)
    ab = [[a[n] for n in 1:N]; [b[n] for n in 1:N]]
    println(ab)
    abref = sort([[va[n] for n in 1:N]; [vb[n] for n in 1:N]])
    @assert ab == abref
    @assert all(ab[2:end] .>= ab[1:end-1])
end

for T in [Int8, Int16, Int32, Int64, Float32, Float64]
    for Ne in 1:3#7
        N = 2^Ne
        test_merge_types_sizes(T, N)
    end
end


function test_merge_heaviside(N, Na, Nb)
    va = Vec(ntuple(n->if n<=Na 0x0 else 0x1 end, N))
    vb = Vec(ntuple(n->if n<=Nb 0x0 else 0x1 end, N))
    a, b = bitonic_merge(va, vb)
    ab = [[a[n] for n in 1:N]; [b[n] for n in 1:N]]
    @assert all(ab[1:Na+Nb] .== 0)
    @assert all(ab[Na+Nb+1:end] .== 1)
end

for Ne in 1:8
    N=2^Ne
    for Na in 0:N
        for Nb in 0:N
            test_merge_heaviside(N, Na, Nb)
        end
    end
end
