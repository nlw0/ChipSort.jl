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

function gen_bitonic_network(len)

    G = len

    aa = Expr(:block)

    # lb = lb[end:-1:1]
    pat = Val{ntuple(a->G-a,G)}
    push!(aa.args, :(la_0 = input_a))
    push!(aa.args, :(lb_0 = shufflevector(input_b, $pat)))

    # L = min.(la, lb)
    # H = max.(la, lb)
    push!(aa.args, :(L_0 = min(la_0, lb_0)))
    push!(aa.args, :(H_0 = max(la_0, lb_0)))

    p = mylog(G)
    for n in 1:p
        la = Symbol("la_", n)
        lb = Symbol("lb_", n)
        Lp = Symbol("L_", n-1)
        Hp = Symbol("H_", n-1)
        L = Symbol("L_", n)
        H = Symbol("H_", n)

        ih = inverse_shuffle(bitonic_step(2^(n), 2^(p-n+1)))
        sh = bitonic_step(2^(n+1), 2^(p-n))
        # la = [L;H][ih[sh[1:G]]]
        # lb = [L;H][ih[sh[(G+1):end]]]
        pat_a = Val{tuple((ih[sh[1:G]].-1)...)}
        pat_b = Val{tuple((ih[sh[(G+1):end]].-1)...)}
        push!(aa.args, :($la = shufflevector($Lp, $Hp, $pat_a)))
        push!(aa.args, :($lb = shufflevector($Lp, $Hp, $pat_b)))

        # L = min.(la, lb)
        # H = max.(la, lb)
        push!(aa.args, :($L = min($la, $lb)))
        push!(aa.args, :($H = max($la, $lb)))
    end

    la = Symbol("la_", p+1)
    lb = Symbol("lb_", p+1)
    Lp = Symbol("L_", p)
    Hp = Symbol("H_", p)

    ih = inverse_shuffle(bitonic_step(2G, 1))
    # la = [L;H][ih[1:G]]
    # lb = [L;H][ih[(G+1):end]]
    pat_a = Val{tuple((ih[1:G].-1)...)}
    pat_b = Val{tuple((ih[(G+1):end].-1)...)}
    push!(aa.args, :($la = shufflevector($Lp, $Hp, $pat_a)))
    push!(aa.args, :($lb = shufflevector($Lp, $Hp, $pat_b)))

    push!(aa.args, Expr(:tuple, la, lb))
    function_declaration = Expr(
        :(=),
        Expr(:call, Symbol("bitonic_merge_", G), :input_a, :input_b),
        aa
    )
    eval(Expr(:macrocall, Symbol("@inline"), LineNumberNode(63), function_declaration))
end

G = 8
gen_bitonic_network(G)
va = Vec(tuple(sort(rand(Int32, G))...))
vb = Vec(tuple(sort(rand(Int32, G))...))
bitonic_merge_32(va, vb)

@code_native bitonic_merge_8(va, vb)

# a,b = bitonic_network(la, lb)
# ab =[a;b]
# println(ab')
# @assert all(ab[2:end] .>= ab[1:end-1])
