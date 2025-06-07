using ComputedTomography
using Test

@testset "ComputedTomography.jl" begin
    include("src/chromatic.jl")
    include("src/scan_geometry.jl")
end
