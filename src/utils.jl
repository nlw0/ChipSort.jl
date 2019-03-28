using SIMD

@inline mylog(n) = if n == 1 0 else 1 + mylog(n>>1) end

@inline vallog(::Val{N}) where N = if N == 1 0 else 1 + vallog(Val(N>>1)) end

@inline concat(a::Vec{N,T}, b::Vec{M,T}) where {N,M,T} =  Vec((NTuple{N,T}(a)..., NTuple{M,T}(b)...))
