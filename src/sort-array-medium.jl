using SIMD


function chipsort_merge_medium(input::AbstractArray{T,1}, ::Val{V}, ::Val{J}, ::Val{K}) where {T,V,J,K}
    output = valloc(T, div(32,sizeof(T)), V*J*K)

    if J>1
        output .= input
        sort_blocks!(output, Val(J), Val(V))
    else
        for cc in 1:K
            block = ntuple(v->input[v+(cc-1)*V], Val(V))
            srt = Vec(sort_net(block...)) ::Vec{V*J,T}
            vstorea(srt, output, 1+(cc-1)*V*J)
        end
    end

    new_input = reshape(output, V, J, K)

    blocks_a = [(@view new_input[:,1:end,c*2-1]) for c in 1:K>>1]
    blocks_b = [(@view new_input[:,1:end,c*2]) for c in 1:K>>1]

    do_merge_pass(
        new_input,
        reshape(valloc(T, div(32,sizeof(T)), V*J*K), V, J<<1, K>>1),
        blocks_a, blocks_b,
        Val(V), Val(J<<1), Val(K>>1)
    )
end

@inline function do_merge_pass(input::AbstractArray{T,3}, output::AbstractArray{T,3}, blocks_a, blocks_b,::Val{V}, ::Val{J}, ::Val{K}) where {T,V,J,K}

    for c in 1:K
        output[:,1,c] .= blocks_a[c][:,1]
    end
    next_inputs = [pointer(c) for c in blocks_b]

    bitonic_merge_interleaved(
        output,
        next_inputs,
        Val(V), 1, Val(K)
    )

    for c in 1:K
        blocks_a[c] = (@view (blocks_a[c][:,2:end]))
        blocks_b[c] = (@view (blocks_b[c][:,2:end]))
    end

    for iter in 2:(J-1)
        for c in 1:K
            if length(blocks_a[c]) > 0 && (length(blocks_b[c]) == 0 || blocks_a[c][1,1] < blocks_b[c][1,1])
                next_inputs[c] = pointer(blocks_a[c], 1)
                blocks_a[c] = (@view (blocks_a[c][:,2:end]))
            else
                next_inputs[c] = pointer(blocks_b[c], 1)
                blocks_b[c] = (@view (blocks_b[c][:,2:end]))
            end
        end

        bitonic_merge_interleaved(
            output,
            next_inputs,
            Val(V), iter, Val(K)
        )
    end

    if K == 1
        reshape(output, :)
    else

        for c in 1:K>>1
            blocks_a[c] = @view output[:,1:end,c*2-1]
            blocks_b[c] = @view output[:,1:end,c*2]
        end

        do_merge_pass(
            output,
            reshape(input, V,J<<1,K>>1),
            blocks_a, blocks_b,
            Val(V), Val(J<<1), Val(K>>1)
        )
    end
end
