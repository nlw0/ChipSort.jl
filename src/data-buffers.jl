using SIMD
using ChipSort


abstract type AbstractDataStream end

mutable struct DataBuffer{N} <: AbstractDataStream
    head
    tail
    DataBuffer(chunk_size::Val{N}, data) where N = new{N}(Vec(tuple(data[1:N]...)), (@view data[N+1:end]))
end

mutable struct MergeNode <: AbstractDataStream
    head
    left
    right
    MergeNode(left, right) = new(pop!(first_stream(left, right)), left, right)
end

function build_multi_merger(chunk_size, data...)
    k = length(data)
    if k == 1
        DataBuffer(chunk_size, data[1])
    elseif k == 2
        MergeNode(DataBuffer(chunk_size, data[1]), DataBuffer(chunk_size, data[2]))
    else
        MergeNode(build_multi_merger(chunk_size, data[1:div(k,2)]...),
                  build_multi_merger(chunk_size, data[1+div(k,2):end]...))
    end
end


"""
Returns the stream with the smallest first element. If the two streams are empty, returns `nothing`.
"""
function first_stream(left::AbstractDataStream, right::AbstractDataStream)
    if left.head == nothing && right.head == nothing
        nothing
    elseif left.head == nothing && right.head != nothing
        right
    elseif left.head != nothing && right.head == nothing
        left
    elseif left.head[1] < right.head[1]
        left
    else
        right
    end
end

function pop!(dbuf::DataBuffer{N}) where N
    output = dbuf.head
    new_head = dbuf.tail[1:min(N, length(dbuf.tail))]
    dbuf.head = if length(new_head)>0 Vec(tuple(new_head...)) else nothing end
    dbuf.tail = @view dbuf.tail[(N+1):end]
    output
end

function pop!(node::MergeNode)
    smallest_tail = first_stream(node.left, node.right)

    if smallest_tail == nothing
        output = node.head
        node.head = nothing
        output
    else
        input = pop!(smallest_tail)
        output, node.head = bitonic_merge(input, node.head)
        output
    end
end
