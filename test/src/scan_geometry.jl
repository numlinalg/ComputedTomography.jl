module testscangeometry 

using ..Test 
using ..ComputedTomography 
CT = ComputedTomography

@testset "Scan Geometry: Beam" begin

    # Test Beam constructor with valid inputs 
    let beam = CT.Beam((1.0, 2.0), (0.0, 1.0))
        @test beam.source == (1.0, 2.0)
        @test beam.direction == (0.0, 1.0)
    end

    # Test overwriting of beam 
    let beam = CT.Beam((1.0, 2.0), (0.0, 1.0)),
        new_source = (3.0, 4.0),
        new_direction = (1.0, 0.0)
        
        beam.source = new_source
        beam.direction = new_direction 

        @test beam.source == new_source
        @test beam.direction == new_direction
    end
end

@testset "Scan Geometry: Parallel Beam" begin

    error_arguments = [
        (-1.0, 10, 0.1), # Negative width ratio
        (1.5, 10, 0.1), # Width ratio larger than 1
        (0.5, 0, 0.1), # Non-positive number of sources
        (0.5, 1, 0.1), # One source with non-zero width ratio
        (0.0, 2, 0.1), # More than one source with zero width
        (0.5, 2, 0.0), # Non-positive rotation step
        (0.5, 2, 3.2) # Rotation step exceeds π
    ]

    for (width_ratio, num_sources, rotation_step) in error_arguments
        @test_throws DomainError ParallelBeam(width_ratio, num_sources, rotation_step)
    end

    # Correct functioning of constructor 
    let width_ratio = 0.5, num_sources = 10, rotation_step = 0.1 

        beam = ParallelBeam(width_ratio, num_sources, rotation_step)
        @test beam.width_ratio == width_ratio
        @test beam.num_sources == num_sources
        @test beam.rotation_step == rotation_step
    end
end

@testset "Scan Geometry: Fan Beam" begin 

    error_arguments = [
        (0.0, 10, 0.1), # Zero angle
        (3.2, 10, 0.1), # Angle exceeds π
        (1.0, 0, 0.1), # Non-positive number of sources
        (1.0, 1, 0.1), # One source with non-zero angle 
        (0.0, 2, 0.1), # More than one source with zero angle 
        (1.0, 2, 0.0), # Non-positive rotation step
        (1.0, 2, 3.2) # Rotation step exceeds π
    ]

    for (angle, num_sources, rotation_step) in error_arguments
        @test_throws DomainError FanBeam(angle, num_sources, rotation_step)
    end

    # Correct functioning of constructor 
    let angle = 1.0, num_sources = 10, rotation_step = 0.1 

        beam = FanBeam(angle, num_sources, rotation_step)
        @test beam.angle == angle
        @test beam.num_sources == num_sources
        @test beam.rotation_step == rotation_step
    end

end

@testset "Scan Geometry: Generate Beams from Baseline" begin
    
    # Tests that all positions and directions are same length
    let x_positions = [0.0, 1.0, 2.0], 
        y_positions = [-1.0, 0.0],
        x_directions = [-1.0, 0.0],
        y_directions = [0.0, 1.0],
        rotation_angles = [0.0, π/2]

        @test_throws DomainError CT.generate_from_baseline(
            x_positions, 
            y_positions, 
            x_directions, 
            y_directions, 
            rotation_angles
        )
    end

    # Tests that all positions and directions are correctly generated 
    let x_positions = [0.0, 1.0], 
        y_positions = [-1.0, 0.0],
        x_directions = [-1.0, 0.0],
        y_directions = [0.0, 1.0],
        rotation_angles = [π/2]

        beams = CT.generate_from_baseline(
            x_positions, 
            y_positions, 
            x_directions, 
            y_directions, 
            rotation_angles
        )

        @test length(beams) == 2 
        @test beams[1].source[1] ≈ 1.0 
        @test beams[1].source[2] ≈ 0.0 atol=eps()
        @test beams[1].direction[1] ≈ 0.0 atol=eps()
        @test beams[1].direction[2] ≈ -1.0
        @test beams[2].source[1] ≈ 0.0 atol=eps()
        @test beams[2].source[2] ≈ 1.0
        @test beams[2].direction[1] ≈ -1.0 
        @test beams[2].direction[2] ≈ 0.0 atol=eps()
    end
end

@testset "Scan Geometry: Generate Parallel Beams" begin 

    # Incorrect Radius Argument 
    let geometry = ParallelBeam(0.0, 1, π/2), radius = 0.0 
        @test_throws DomainError generate(geometry, radius)
    end

    # Correct functioning of parallel beam generation 
    let geometry = ParallelBeam(0.0, 1, π/2), radius = 1.0

        beams = generate(geometry, radius)

        @test length(beams) == 2
        @test beams[1].source[1] ≈ 0.0 atol=eps()
        @test beams[1].source[2] ≈ -1.0 atol=eps()
        @test beams[2].source[1] ≈ 1.0 atol=eps()
        @test beams[2].source[2] ≈ 0.0 atol=eps()
        @test beams[1].direction[1] ≈ 0.0 atol=eps()
        @test beams[1].direction[2] ≈ 1.0 atol=eps() 
        @test beams[2].direction[1] ≈ -1.0 atol=eps()
        @test beams[2].direction[2] ≈ 0.0 atol=eps()
    end
end

@testset "Scan Geometry: Generate Fan Beams" begin 

    # Incorrect Radius Argument 
    let geometry = FanBeam(0.0, 1, π/2), radius = 0.0 
        @test_throws DomainError generate(geometry, radius)
    end
    
    # Correct Functioning 
    let geometry = FanBeam(0.0, 1, π/2), radius = 1.0

        beams = generate(geometry, radius)

        @test length(beams) == 2
        @test beams[1].source[1] ≈ 0.0 atol=eps()
        @test beams[1].source[2] ≈ -1.0 atol=eps()
        @test beams[2].source[1] ≈ 1.0 atol=eps()
        @test beams[2].source[2] ≈ 0.0 atol=eps()
        @test beams[1].direction[1] ≈ 0.0 atol=eps()
        @test beams[1].direction[2] ≈ 1.0 atol=eps() 
        @test beams[2].direction[1] ≈ -1.0 atol=eps()
        @test beams[2].direction[2] ≈ 0.0 atol=eps()
    end
end

end # module testscangeometry