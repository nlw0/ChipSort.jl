function randa(T, K)
    data = valloc(T, div(32, sizeof(T)), K)
    data .= rand(T, K)
    data
end
