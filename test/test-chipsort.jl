using Test
using ChipSort


data = rand(256)
@test chipsort(data,Val(8),Val(8),Val(8)) == sort(data)
