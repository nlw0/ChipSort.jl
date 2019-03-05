using Documenter, ChipSort

makedocs(
    sitename="ChipSort.jl",
    pages = [
        "index.md",
        "theory.md",
        "api.md",
        "benchmark.md"
    ],
    # format = Documenter.HTML(
    #     prettyurls = get(ENV, "CI", nothing) == "true"
    # )
)

deploydocs(
    repo = "github.com/nlw0/ChipSort.jl.git",
)
