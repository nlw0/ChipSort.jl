@inline function sort4(a1::Vec{4, T}, a2::Vec{4, T}, a3::Vec{4, T}, a4::Vec{4, T}) where T
    b1 = min(a1,a2)
    b2 = max(a1,a2)
    b3 = min(a3,a4)
    b4 = max(a3,a4)

    c1 = min(b1,b3)
    c3 = max(b1,b3)
    c2 = min(b2,b4)
    c4 = max(b2,b4)

    d2 = min(c2,c3)
    d3 = max(c2,c3)

    (c1, d2, d3, c4)
end

function nested_calls(name, n)
    if n == 0
        :input
    else
        Expr(:call, Symbol(name,n) , nested_calls(name, n-1))
    end
end

nets = (
    (4, (((1,2), (3,4)), ((1,3), (2,4)), ((2,3),))),
)

for nn in 1:1
    inlen, net_params = nets[nn]
    nsteps = length(net_params)

    for st in 1:nsteps
        aa = [:(input[$n]) for n in 1:N]
        for t in net_params[st]
            aa[t[1]] = :(min(input[$(t[1])],input[$(t[2])]))
            aa[t[2]] = :(max(input[$(t[1])],input[$(t[2])]))
        end
        eval(Expr(:(=),
                  Expr(:call, Symbol("sort_", inlen, "_step_", st), :input),
                  Expr(:call, :tuple, aa...)))
        eval(Expr(:(=),
                  Expr(:call, Symbol("sort_", inlen), :input),
                  nested_calls("sort_$(inlen)_step_", nsteps)))
    end
end

tst = (5,3,2,0)
sort_4(tst)
