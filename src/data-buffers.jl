using SIMD
using ChipSort


abstract type AbstractDataStream end

mutable struct DataBuffer <: AbstractDataStream
    head
    tail
end

mutable struct MergeNode <: AbstractDataStream
    left
    right
    head
end

function pop(::Val{N}, dbuf::DataBuffer) where N
    output = dbuf.head
    new_head = dbuf.tail[1:min(N, length(dbuf.tail))]
    dbuf.head = if length(new_head)>0 Vec(tuple(new_head...)) else nothing end
    dbuf.tail = @view dbuf.tail[(N+1):end]
    output
end

function pop(::Val{N}, node::MergeNode) where N
    smallest_tail =
        if node.left.head == nothing && node.right.head == nothing
            nothing
        elseif node.left.head == nothing && node.right.head != nothing
            node.right
        elseif node.left.head != nothing && node.right.head == nothing
            node.left
        elseif node.left.head[1] < node.right.head[1]
            node.left
        else
            node.right
        end

    if smallest_tail == nothing
        output = node.head
        node.head = nothing
        output
    else
        input = pop(Val(N), smallest_tail)
        output, node.head = bitonic_merge(node.head, input)
        output
    end
end
