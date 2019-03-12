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

function chipsort_medium(input::AbstractArray{T,1}, ::Val{C}, ::Val{N}, ::Val{L}) where {T,C,N,L}
    output = valloc(T, div(32,sizeof(T)), N*L*C)

    K = N*L

    for cc in 1:C
        chunks = ntuple(l->vloada(Vec{N, T}, input, 1+(cc-1)*N*L + (l-1)*N), L)::NTuple{L,Vec{N,T}}
        if L>1
            srt = sort_small_array(chunks)
        else
            srt=chunks[1]
        end
        vstorea(srt, output, 1+(cc-1)*N*L)
    end

    input, output = output, valloc(T, div(32,sizeof(T)), N*L*C)

    pairs = C
    l = 1#L
    n = N*L#N
    while pairs > 1
        K = n*l
        pairs = pairs >> 1
        for cc in 0:pairs-1
            p1 = cc*2*K+1
            p2 = cc*2*K+1+K
            end1 = cc*2*K+1+K
            end2 = cc*2*K+1+2*K
            pout = cc*2*K+1
            merge_pair2(output, input, pout, p1, p2, end1, end2, l,n,T)
        end
        l = l<<1
        input, output = output, input
    end
    input
end

function merge_pair2(output, input, pout, p1, p2, end1, end2, L,N,T)
    h1 = vloada(Vec{N, T}, input, p1)
    h2 = vloada(Vec{N, T}, input, p2)

    out, state = bitonic_merge(h1, h2)
    vstorea(out, output, pout)
    pout += N

    p1 += N
    p2 += N
    h1 = vloada(Vec{N, T}, input, p1)
    h2 = vloada(Vec{N, T}, input, p2)

    for ii in 1:2*L-2
        if p2>=end2 || p1 < end1 && h1[1] < h2[1]
            out, state = bitonic_merge(state, h1)
            p1 += N
            h1 = vloada(Vec{N, T}, input, p1)
        else
            out, state = bitonic_merge(state, h2)
            p2 += N
            h2 = vloada(Vec{N, T}, input, p2)
        end
        vstorea(out, output, pout)
        pout+=N
    end
    vstorea(state, output, pout)
    nothing
end
