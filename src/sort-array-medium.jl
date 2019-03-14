using SIMD


function merge_streams(input_1::NTuple{L1, Vec{N,T}}, input_2::NTuple{L2, Vec{N,T}})::NTuple{L1+L2, Vec{N,T}} where {L1,L2,N,T}
    out, state = bitonic_merge(input_1[1], input_2[1])
    (out, merge_streams(input_1[2:end], input_2[2:end], state)...)
end

function merge_streams(input_1::NTuple{L1, Vec{N,T}}, input_2::NTuple{L2, Vec{N,T}}, state::Vec{N,T})::NTuple{1+L1+L2, Vec{N,T}} where {L1,L2,N,T}
    if L1 == 0 && L2 == 0
        (state, )
    elseif L2 == 0 || L1 > 0 && input_1[1][1] < input_2[1][1]
        out, new_state = bitonic_merge(state, input_1[1])
        (out, merge_streams(input_1[2:end], input_2, new_state)...)
    else
        out, new_state = bitonic_merge(state, input_2[1])
        (out, merge_streams(input_1, input_2[2:end], new_state)...)
    end
end

function merge_vecs_tree(input::Vararg{Vec{N,T}, L})::NTuple{L, Vec{N,T}} where {N,T,L}
    if L==2
        bitonic_merge(input[1], input[2])
    else
        merge_streams(merge_vecs_tree(input[1:div(L,2)]...), merge_vecs_tree(input[1+div(L,2):L]...))
    end
end

function merge_vecs_tree(input::AbstractArray{T,A}, ::Val{C}, ::Val{N}, ::Val{L})::NTuple{C,Vec{N*L,T}} where {C,N,T,A,L}
    if C==2
        chunk_1 = ntuple(l->vload(Vec{N, T}, input, 1 + (l-1)*N), L)::NTuple{L,Vec{N,T}}
        chunk_2 = ntuple(l->vload(Vec{N, T}, input, N*L + 1 + (l-1)*N), L)::NTuple{L,Vec{N,T}}
        bitonic_merge(sort_small_array(chunk_1), sort_small_array(chunk_2))
    else
        merge_streams(
            merge_vecs_tree((@view input[1:div(C,2)*N*L]), Val(div(C,2)), Val(N), Val(L)),
            merge_vecs_tree((@view input[1+div(C,2)*N*L:C*N*L]), Val(div(C,2)), Val(N), Val(L))
        )
    end
end

function chipsort_medium_old(input::AbstractArray{T,A}, ::Val{C}, ::Val{N}, ::Val{L}) where {A,T,C,N,L}
    output = valloc(T, div(32, sizeof(T)), size(input,1))
    p=1
    for chunk in merge_vecs_tree(input, Val(C), Val(N), Val(L))
        vstore(chunk, output, p)
        p+=N*L
    end
    output
end


function chipsort_medium(input::AbstractArray{T,1}, ::Val{V}, ::Val{J}, ::Val{K}) where {T,V,J,K}
    output = valloc(T, div(32,sizeof(T)), V*J*K)

    if J>1
        for cc in 1:K
            chunks = ntuple(l->vloada(Vec{V, T}, input, 1+(cc-1)*V*J + (l-1)*V), J) ::NTuple{J, Vec{V,T}}
            srt = sort_small_array(chunks) ::Vec{V*J,T}
            vstorea(srt, output, 1+(cc-1)*V*J)
        end
    else
        for cc in 1:K
            chunk = ntuple(v->input[v+(cc-1)*V], V)
            srt = Vec(sort_net(chunk...)) ::Vec{V*J,T}
            vstorea(srt, output, 1+(cc-1)*V*J)
        end
    end

    new_input = reshape(output, V, J, K)

    chunks_a = [(@view new_input[:,1:end,c*2-1]) for c in 1:K>>1]
    chunks_b = [(@view new_input[:,1:end,c*2]) for c in 1:K>>1]

    do_merge_pass(
        new_input,
        reshape(valloc(T, div(32,sizeof(T)), V*J*K), V, J<<1, K>>1),
        chunks_a, chunks_b,
        Val(V), Val(J<<1), Val(K>>1)
    )
end

@inline function do_merge_pass(input::AbstractArray{T,3}, output::AbstractArray{T,3}, chunks_a, chunks_b,::Val{V}, ::Val{J}, ::Val{K}) where {T,V,J,K}

    for c in 1:K
        output[:,1,c] .= chunks_a[c][:,1]
    end
    next_inputs = [pointer(c) for c in chunks_b]

    bitonic_merge_interleaved(
        output,
        next_inputs,
        Val(V), 1, Val(K)
    )

    for c in 1:K
        chunks_a[c] = (@view (chunks_a[c][:,2:end]))
        chunks_b[c] = (@view (chunks_b[c][:,2:end]))
    end

    for iter in 2:(J-1)
        for c in 1:K
            if length(chunks_a[c]) > 0 && (length(chunks_b[c]) == 0 || chunks_a[c][1,1] < chunks_b[c][1,1])
                next_inputs[c] = pointer(chunks_a[c], 1)
                chunks_a[c] = (@view (chunks_a[c][:,2:end]))
            else
                next_inputs[c] = pointer(chunks_b[c], 1)
                chunks_b[c] = (@view (chunks_b[c][:,2:end]))
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
            chunks_a[c] = @view output[:,1:end,c*2-1]
            chunks_b[c] = @view output[:,1:end,c*2]
        end

        do_merge_pass(
            output,
            reshape(input, V,J<<1,K>>1),
            chunks_a, chunks_b,
            Val(V), Val(J<<1), Val(K>>1)
        )
    end
end
