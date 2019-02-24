using SIMD

function nested_calls(name, n, input)
    if n == 0
        input
    else
        Expr(:call, Symbol(name, n) , nested_calls(name, n-1, input))
    end
end

include("sorting-network-parameters.jl")

function gen_net_code(inlen, net_params)
    nsteps = length(net_params)

    aa = Expr(:block)

    for t in 1:inlen
        a1 = Symbol("input_", 0, "_", t)
        push!(aa.args, :($a1 = input[$t]))
    end

    for st in 1:nsteps

        touched = [x for t in net_params[st] for x in t]
        untouched = setdiff(1:inlen, touched)

        for t in untouched
            a1 = Symbol("input_", st-1, "_", t)
            b1 = Symbol("input_", st, "_", t)
            push!(aa.args, :($b1 = $a1))
        end

        for t in net_params[st]
            a1 = Symbol("input_", st-1, "_", t[1])
            a2 = Symbol("input_", st-1, "_", t[2])
            b1 = Symbol("input_", st, "_", t[1])
            b2 = Symbol("input_", st, "_", t[2])
            push!(aa.args, :($b1 = min($a1, $a2)))
            push!(aa.args, :($b2 = max($a1, $a2)))
        end
    end

    push!(aa.args,
          Expr(:tuple, ntuple(t->Symbol("input_", nsteps, "_", t), inlen)...))

    function_declaration = Expr(
        :(=),
        Expr(:call, Symbol("sort_", inlen), :input),
        aa
    )
    eval(
        Expr(:macrocall, Symbol("@inline"), LineNumberNode(63), function_declaration)
    )
end

for sn in sorting_network_parameters
    gen_net_code(sn...)
end

function run_test()
    for p in 2:5
        n = 2^p
        ee = Expr(:call, Symbol("sort_", n), :(rand($n)))
        println(ee)
        for x in 1:100000
            aa = eval(ee)
            @assert all(aa[2:end] .> aa[1:end-1])
        end
    end
end
# run_test()

mylog(n) = if n == 1 0 else 1 + mylog(n>>1) end

function gen_transpose_code(len)

    aa = Expr(:block)

    pa = Val{ntuple(a->((a-1)*len)%(2*len-1), len)}
    pb = Val{ntuple(a->div(len,2)+((a-1)*len)%(2*len-1), len)}

    for t in 1:len
        a1 = Symbol("input_", 0, "_", t)
        push!(aa.args, :($a1 = input[$t]))
    end

    nsteps = mylog(len)

    len_2 = div(len,2)

    for st in 1:nsteps
        for t in 1:len_2
            a1 = Symbol("input_", st-1, "_", t)
            a2 = Symbol("input_", st-1, "_", t+len_2)
            b1 = Symbol("input_", st, "_", t*2-1)
            b2 = Symbol("input_", st, "_", t*2)
            push!(aa.args, :($b1 = shufflevector($a1, $a2, $pa)))
            push!(aa.args, :($b2 = shufflevector($a1, $a2, $pb)))
        end
    end

    push!(aa.args,
          Expr(:tuple, ntuple(t->Symbol("input_", nsteps, "_", t), len)...))

    function_declaration = Expr(
        :(=),
        Expr(:call, Symbol("transpose_", len), :input),
        aa
    )
    eval(
        Expr(:macrocall, Symbol("@inline"), LineNumberNode(63), function_declaration)
    )
end

for n in 2:5
    gen_transpose_code(2^n)
end

function test_trans(n)
    uu = ntuple(a->Vec(ntuple(i->convert(Int16, a*100+i), n)), n)
    tt = ntuple(a->Vec(ntuple(i->convert(Int16, i*100+a), n)), n)
    ee = Expr(:call, Symbol("transpose_", n), :($uu))
    tthat = eval(ee)
    @assert all(all(j) for j in (tthat.==tt))
end

# for n in 2:5
#     test_trans(2^n)
# end

# T = Float64
# T = Float16
# T = Float16
# T = UInt32
T = Int32
N = 16
M = 8
a_in = rand(T, N * M)
a_out = valloc(T, div(32, sizeof(T)), N * M)
display(reshape(a_in, N, M))
aa = ntuple(i->vload(Vec{M, T}, a_in, i*M-(M-1)), N)

sr = sort_16(aa)
qq = (transpose_8(sr[1:M])..., transpose_8(sr[M+1:2*M])...)

for i in 1:M
    vstorent(qq[i], a_out, i*N-(N-1))
    vstorent(qq[i+M], a_out, i*N-(N-1)+M)
end
display(reshape(a_out, N, M))


function hh(x)
    sr = sort_16(x)
    (transpose_8(ntuple(a->sr[a], 8))...,
     transpose_8(ntuple(a->sr[a+8], 8)))
end

# hh(x) = transpose_8(sort_8(x))
# @code_native transpose_8(aa)
# @code_native sort_16(aa)
# @code_native hh(aa)


# @code_native sort_32(aa)
