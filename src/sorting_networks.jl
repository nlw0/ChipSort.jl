# @inline function sort4(a1::Vec{4, T}, a2::Vec{4, T}, a3::Vec{4, T}, a4::Vec{4, T}) where T
#     b1 = min(a1,a2)
#     b2 = max(a1,a2)
#     b3 = min(a3,a4)
#     b4 = max(a3,a4)

#     c1 = min(b1,b3)
#     c3 = max(b1,b3)
#     c2 = min(b2,b4)
#     c4 = max(b2,b4)

#     d2 = min(c2,c3)
#     d3 = max(c2,c3)

#     (c1, d2, d3, c4)
# end

function nested_calls(name, n)
    if n == 0
        :input
    else
        Expr(:call, Symbol(name,n) , nested_calls(name, n-1))
    end
end

nets = (
    (4, (((1,2), (3,4)), ((1,3), (2,4)), ((2,3),))),
    (8, (((1, 2), (3, 4), (5, 6), (7, 8)),
         ((1, 3), (2, 4), (5, 7), (6, 8)),
         ((2, 3), (6, 7), (1, 5), (4, 8)),
         ((2, 6), (3, 7)),
         ((2, 5), (4, 7)),
         ((3, 5), (4, 6)),
         ((4, 5),)
         )),
    # by END algoritm http://www.cs.brandeis.edu/~hugues/sorting_networks.html
    (16, (
        ((4, 11), (12, 15), (5, 14), (3, 13), (1, 7), (9, 10), (2,8), (6, 16)),
        ((1, 2), (3, 5), (7, 8), (13, 14), (4, 6), (9, 12), (11, 16), (10, 15)),
        ((1, 4), (7, 11), (14, 15), (2, 6), (8, 16), (3, 9), (10, 13), (5, 12)),
        ((1, 3), (8, 14), (15, 16), (2, 5), (6, 12), (4, 9), (11, 13), (7, 10)),
        ((2, 3), (4, 7), (8, 9), (12, 14), (6, 10), (13, 15), (5, 11)),
        ((3, 7), (12, 13), (2, 4), (6, 8), (9, 10), (14, 15)),
        ((3, 4), (5, 7), (11, 12), (13, 14)),
        ((9, 11), (5, 6), (7, 8), (10, 12)),
        ((4, 5), (6, 7), (8, 9), (10, 11), (12, 13)),
        ((7, 8), (9, 10))
    ))

)


for nn in 1:length(nets)
    inlen, net_params = nets[nn]
    nsteps = length(net_params)

    for st in 1:nsteps
        aa = [:(@inbounds input[$n]) for n in 1:inlen]
        for t in net_params[st]
            aa[t[1]] = :(@inbounds min(input[$(t[1])],input[$(t[2])]))
            aa[t[2]] = :(@inbounds max(input[$(t[1])],input[$(t[2])]))
        end
        eval(Expr(:(=),
                  Expr(:call, Symbol("sort_", inlen, "_step_", st), :input),
                  Expr(:call, :tuple, aa...)))
        eval(Expr(:(=),
                  Expr(:call, Symbol("sort_", inlen), :input),
                  nested_calls("sort_$(inlen)_step_", nsteps)))
    end
end

for x in 1:100000
    aa = sort_16(rand(16))
    @assert all(aa[2:end] .> aa[1:end-1])
end
