using SIMD

mylog(n) = if n == 1 0 else 1 + mylog(n>>1) end

vallog(::Val{N}) where N = if N == 1 0 else 1 + vallog(Val(N>>1)) end

#@inline concat(a::Vec{N,T}, b::Vec{M,T}) where {N,M,T} =  Vec((NTuple{N,T}(a)..., NTuple{M,T}(b)...))
# @inline concat(a::Vec{N,T}, b::Vec{M,T}) where {N,M,T} = Vec(ntuple(j->if j<=N a[j] else b[j-N]end, N+M))

@inline concat(a::Vararg{Vec{N,T},M}) where {N,M,T} = Vec(concat_tup(a...))
@inline concat_tup(a::Vararg{Vec{N,T},M}) where {N,M,T} =
    if length(a) == 1
        NTuple{N,T}(a[1])
    else
        (NTuple{N,T}(a[1])..., concat_tup(a[2:end]...)...)
    end
