using SIMD

"""
    chipsort_small!(data, Val(V), Val(J))

Sort a small array using a vectorized sorting network and bitonic merge networks. The initial sort is over `J` SIMD vectors of size `V`. The array should typically fit inside register memory, for instance 64 Int32 values on an AVX2 machine.

# Examples
```jldoctest
julia> chipsort_small!(Int32[1:16...] .* Int32(1729) .%0x100, Val(4), Val(4))'
1×16 LinearAlgebra.Adjoint{Int32,Array{Int32,1}}:
 4  8  12  16  67  71  75  79  130  134  138  142  193  197  201  205
```
"""
chipsort_small!(data::AbstractVector{T}, ::Val{V}, ::Val{J}) where {T,V,J} = sort_block!(data, Val(V), Val(J))

@generated function sort_block!(data::AbstractVector{T}, ::Val{V}, ::Val{J}) where {T,V,J}
    ex = [Expr(:meta, :inline)]

    for j in 1:J
        v = Symbol("input_", j)
        push!(ex, :($v = vload(Vec{V,T}, pointer(data, 1+($j-1)*V))))
    end
    vecs=[Symbol("input_", j) for j in 1:J]
    append!(ex, [
        :(output = merge_vecs(transpose_vecs(sort_net($(vecs...))...)...)),
        :(vstore(output, pointer(data, 1))),
        :(return data)
    ])
    quote $(ex...) end
end

function sort_blocks!(data::AbstractVector{T}, ::Val{L}, ::Val{N}) where {L,N,T}
    block_size = N*L
    num_blocks = div(length(data), block_size)

    for m in 1:num_blocks
        sort_block!((@view data[1 + (m-1)*block_size:m*block_size]), Val(N), Val(L))
    end
    data
end

"""Sort blocks from the input array, optionally transposing to generate sorted sequences of size V (default), or further
merging those into sequences of size V*L."""
function sort_vecs!(input::AbstractVector{T}, ::Val{J}, ::Val{V}, ::Val{Transpose}=Val(true), ::Val{Merge}=Val(false)) where {V,J,T,Transpose,Merge}
    block_size = V*J
    num_blocks = div(length(input), block_size)

    for m in 1:num_blocks
        block = ntuple(j->vload(Vec{V, T}, input, 1 + (m-1)*block_size + (j-1)*V), J)
        sorted_vecs = if Merge
            merge_vecs(transpose_vecs(sort_net(block...)...)...)
        elseif Transpose
            transpose_vecs(sort_net(block...)...)
        else
            sort_net(block...)
        end

        if Merge
            vstorent(sorted_vecs, input, 1 + (m-1)*(V*J))
        elseif Transpose
            for v in 1:V
                vstorent(sorted_vecs[v], input, 1 + (m-1)*(V*J) + (v-1)*J)
            end
        else
            for j in 1:J
                vstorent(sorted_vecs[j], input, 1 + (m-1)*(V*J) + (j-1)*V)
            end
        end
    end
    input
end

function merge_blocks(output, data, ::Val{L}, ::Val{N}) where {L,N}
    blocks = reshape((@view data[:]), L*N, :)
    M = div(length(data), L*N)

    merger = build_multi_merger(Val(N), ntuple(m->(@view blocks[:, m]), M)...)

    for itr in 1:L*M
        new_buffer = pop!(merger)
        vstorent(new_buffer, output, 1 + (itr-1)*N)
    end
    output
end
