using SIMD

mylog(n) = if n == 1 0 else 1 + mylog(n>>1) end

@inline concat(a::Vec{N,T}, b::Vec{M,T}) where {N,M,T} =  Vec((NTuple{N,T}(a)..., NTuple{M,T}(b)...))
# @inline concat(a::Vec{N,T}, b::Vec{M,T}) where {N,M,T} = Vec(ntuple(j->if j<=N a[j] else b[j-N]end, N+M))
