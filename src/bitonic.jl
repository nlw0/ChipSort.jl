using InteractiveUtils

using Revise
using SIMD

function simd_sort_in_place(a::Array{T,1}) where T
    N = size(a, 1) >> 4
    for n in 1:N
        aa = vload(Vec{16, T}, a, n * 16 - 15)
        qq = simd_sort_16(aa)
        vstorent(qq, a, n*16-15)
    end
end


function simd_sort_16(a::Vec{16, T}) where T
    a1 = Vec((a[1], a[2], a[3], a[4]))
    a2 = Vec((a[5], a[6], a[7], a[8]))
    a3 = Vec((a[9], a[10], a[11], a[12]))
    a4 = Vec((a[13], a[14], a[15], a[16]))

    bb = in_register_sorting(a1, a2, a3, a4)
    # bitonic_merge_4x4(bb...)
    c1,c2,c3,c4 = bitonic_merge_4x4(bb...)

    Vec((c1[1],c1[2],c1[3],c1[4],
         c2[1],c2[2],c2[3],c2[4],
         c3[1],c3[2],c3[3],c3[4],
         c4[1],c4[2],c4[3],c4[4]))
end

# @inline function bitonic_merge_4x4(a::Vec{4, T}, b::Vec{4, T}, c::Vec{4, T}, d::Vec{4, T}) where T
#     ab1, ab2 = bitonic_merge_2x4(a, b)
#     cd1, cd2 = bitonic_merge_2x4(c, d)

#     e1, ei2 = bitonic_merge_2x4(ab1, cd1)

#     if ab2[1] < cd2[1]
#         e2, ei3 = bitonic_merge_2x4(ei2, ab2)
#         e3, e4 = bitonic_merge_2x4(ei3, cd2)
#     else
#         e2, ei3 = bitonic_merge_2x4(ei2, cd2)
#         e3, e4 = bitonic_merge_2x4(ei3, ab2)
#     end
#     (e1, e2, e3, e4)
# end

@inline function bitonic_merge_4x4(a::Vec{4, T}, b::Vec{4, T}, c::Vec{4, T}, d::Vec{4, T}) where T
    ab1, ab2 = bitonic_merge_2x4(a, b)
    cd1, cd2 = bitonic_merge_2x4(c, d)

    bitonic_merge_2x2x4(ab1, ab2, cd1, cd2)
end

@inline function bitonic_merge_2x2x4(ab1::Vec{4, T}, ab2::Vec{4, T}, cd1::Vec{4, T}, cd2::Vec{4, T}) where T
    e1, ei2 = bitonic_merge_2x4(ab1, cd1)

    if ab2[1] < cd2[1]
        e2, ei3 = bitonic_merge_2x4(ei2, ab2)
        e3, e4 = bitonic_merge_2x4(ei3, cd2)
    else
        e2, ei3 = bitonic_merge_2x4(ei2, cd2)
        e3, e4 = bitonic_merge_2x4(ei3, ab2)
    end
    (e1, e2, e3, e4)
end


@inline function bitonic_merge_2xNx4(a::NTuple{Na, Vec{4, T}}, b::NTuple{Nb, Vec{4, T}}) where {Na,Nb}
    e1, ei2 = bitonic_merge_2x4(a[1], b[1])

end

@inline function bitonic_merge_2xNx4(c::Vec{4, T}, a::NTuple{Na, Vec{4, T}}, b::NTuple{Nb, Vec{4, T}}) where {Na,Nb}

    e1, ei2 = bitonic_merge_2x4(ab1, cd1)

    if ab2[1] < cd2[1]
        e2, ei3 = bitonic_merge_2x4(ei2, ab2)
        e3, e4 = bitonic_merge_2x4(ei3, cd2)
    else
        e2, ei3 = bitonic_merge_2x4(ei2, cd2)
        e3, e4 = bitonic_merge_2x4(ei3, ab2)
    end
    (e1, e2, e3, e4)


end






@inline function bitonic_merge_2x4(a::Vec{4, T}, b::Vec{4, T}) where T
    a1 = a
    b1 = shufflevector(b, Val{(3,2,1,0)})

    L1 = min(a1, b1)
    H1 = max(a1, b1)

    a2 = shufflevector(L1, H1, Val{(2,3,6,7)})
    b2 = shufflevector(L1, H1, Val{(0,1,4,5)})

    L2 = min(a2, b2)
    H2 = max(a2, b2)

    a3 = shufflevector(L2, H2, Val{(1,5,3,7)})
    b3 = shufflevector(L2, H2, Val{(0,4,2,6)})

    L3 = min(a3, b3)
    H3 = max(a3, b3)

    c1 = shufflevector(L3, H3, Val{(0,4,1,5)})
    c2 = shufflevector(L3, H3, Val{(2,6,3,7)})

    (c1, c2)
end

"From 'Efficient Implementation of Sorting on Multi-Core SIMD CPU Architecture', Chhugani et al. (2008)"
@inline function in_register_sorting(a1::Vec{4, T}, a2::Vec{4, T}, a3::Vec{4, T}, a4::Vec{4, T}) where T
    transpose_registers(in_register_sorting_t(a1, a2, a3, a4)...)
end

@inline function in_register_sorting_t(a1::Vec{4, T}, a2::Vec{4, T}, a3::Vec{4, T}, a4::Vec{4, T}) where T
    b1 = min(a1,a2)
    b2 = max(a1,a2)
    b3 = min(a3,a4)
    b4 = max(a3,a4)

    c1 = min(b1,b3)
    c3 = max(b1,b3)
    c2 = min(b2,b4)
    c4 = max(b2,b4)

    d2 = min(c2,c3)
    d3 = max(c2,c3)

    (c1, d2, d3, c4)
end

@inline function transpose_registers(a1::Vec{4, T}, a2::Vec{4, T}, a3::Vec{4, T}, a4::Vec{4, T}) where T
    b1 = shufflevector(a1,a3,Val{(0,1,4,5)})
    b2 = shufflevector(a2,a4,Val{(0,1,4,5)})
    b3 = shufflevector(a1,a3,Val{(2,3,6,7)})
    b4 = shufflevector(a2,a4,Val{(2,3,6,7)})

    c1 = shufflevector(b1,b2,Val{(0,4,2,6)})
    c2 = shufflevector(b1,b2,Val{(1,5,3,7)})
    c3 = shufflevector(b3,b4,Val{(0,4,2,6)})
    c4 = shufflevector(b3,b4,Val{(1,5,3,7)})

    (c1, c2, c3, c4)
end

dispv(jj) = display([x for x in jj])

function demo_stages()
    a_orig = rand(UInt32, 16)
    aa = [Vec(tuple(a_orig[k*4-3:k*4]...)) for k in 1:4]

    qq = in_register_sorting(aa...)
    jj = bitonic_merge_4x4(qq...)

    a_sort_mine = [jj[j][k] for j in 1:4 for k in 1:4]
    a_sort_ref = sort(a_orig)

    display(a_orig')

    display(aa)
    dispv(qq)
    dispv(jj)

    dispv(a_sort_ref')
    dispv(a_sort_mine')

    @assert a_sort_mine == a_sort_ref
end

function demo_array()
    T = UInt32
    a_in = rand(T, 16)
    display(a_in')
    @code_native vload(Vec{16, T}, a_in, 1)
    aa = vload(Vec{16, T}, a_in, 1)
    qq = simd_sort_16(aa)
    dispv(qq)
    vstore(qq, a_in, 1)
    display(a_in')
end

T = Int8
aa = rand(T, 16*16)

display(reshape(aa,16,:))
simd_sort_in_place(aa)
display(reshape(aa,16,:))
