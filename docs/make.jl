using ComputedTomography
using Documenter

DocMeta.setdocmeta!(ComputedTomography, :DocTestSetup, :(using ComputedTomography); recursive=true)

makedocs(;
    modules=[ComputedTomography],
    authors="Vivak Patel <vp314@users.noreply.github.com>",
    sitename="ComputedTomography.jl",
    format=Documenter.HTML(;
        canonical="https://numlinalg.github.io/ComputedTomography.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Introduction" => "manual/introduction.md",
        ],
        "API" => [
            "Light Sources" => "api/chromatic.md",
            "Scan Geometry" => "api/geometry.md",
        ]
    ],
)

deploydocs(;
    repo="github.com/numlinalg/ComputedTomography.jl",
    devbranch="main",
)
