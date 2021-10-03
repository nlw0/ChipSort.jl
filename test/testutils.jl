function randa(T, K)
    data = valloc(T, 64, K)
    data .= rand(T, K)
    data
end
