###################################
# Data Structures
###################################
"""
    Beam 

A data structure representing a single X-ray beam direction. 

# Fields 
- `source::Tuple{Float64, Float64}`, the source position of an X-ray beam in 2D 
    space specified by a pair (x, y) that assumes an (absolute) underlying Cartesian 
    coordinate system. 
- `direction::Tuple{Float64, Float64}`, the direction of the beam in 2D space 
    specified by a pair (x, y) that assuming an (absolute) underlying Cartesian coordinate 
    system. 
"""
mutable struct Beam 
    source::Tuple{Float64, Float64}
    direction::Tuple{Float64, Float64}
end

"""
    ScanGeometry 

An abstract type representing a scan geometry used in the CT simulation.
"""
abstract type ScanGeometry end 

"""
    ParallelBeam <: ScanGeometry 

A data structure specifying a 2-dimensional parallel beam scan geometry.
    The scan geometry is a parallel set of beams. These are then rotated around 
    the object being scanned.

# Fields
- `width_ratio::Float64`, a value in `[0, 1]` that specifies the width of the 
    distance between the two furtherest sources (along the secant) as a fraction 
    of the width of the diameter of rotation. 
- `num_sources::Int64`, the number of sources spread out along the indicated 
    width ratio. 
- `rotation_step::Float64`, a value in `(0, π)` that specifies the amount the 
    source is rotated in a single increment around the object being scanned 
    in radians.

!!! info 
    The width ratio must be zero if the number of sources is one. 
"""
struct ParallelBeam <: ScanGeometry 
    width_ratio::Float64 # Width ratio of the scan geometry
    num_sources::Int64 # Number of sources in the scan geometry
    rotation_step::Float64 # Rotation step in radians 
    
    ParallelBeam(
        width_ratio::Float64, 
        num_sources::Int64, 
        rotation_step::Float64
    ) = begin 
        (width_ratio < 0 || width_ratio > 1) && throw(
            DomainError("Width ratio must be in [0, 1].")
        )
        (num_sources <= 0) && throw(
            DomainError("Number of sources must be a positive integer.")
        )

        (num_sources == 1 && width_ratio != 0.0) && throw(
            DomainError("Width ratio must be zero if the number of sources is one.")
        )

        (num_sources != 1 && width_ratio == 0.0) && throw(
            DomainError(
                "Width ratio must be non-zero if the number of sources is \
                greater than one."
            )
        )

        (rotation_step <= 0 || rotation_step >= π) && throw(
            DomainError("Rotation step must be in (0, π).")
        )

        new(width_ratio, num_sources, rotation_step)
    end
end

"""
    FanBeam <: ScanGeometry 

A data structure specifying a 2-dimensional fan beam scan geometry. 
    The scan geometry is assumed to generate a fan shape that is then rotated 
    around the object being scanned. 

# Fields 
- `angle::Float64`, a value in `[0, π]` that specifies the angle (radians) of the fan 
    beam.
- `num_sources::Int64``, the number of beams emanating from the source.
- `rotation_step::Float64`, a value in `(0, π)` that specifies the amount the 
    source is rotated in a single increment around the object being scanned 
    in radians.
"""
struct FanBeam <: ScanGeometry 
    angle::Float64 #Angle of the fan beam in radians 
    num_sources::Int64 # Number of sources in the scan geometry
    rotation_step::Float64 # Rotation step in radians 

    FanBeam(angle::Float64, num_sources::Int64, rotation_step::Float64) = begin 
        (angle < 0 || angle > π) && throw(
            DomainError("Angle must be in [0, π].")
        )

        (num_sources <= 0) && throw(
            DomainError("Number of sources must be a positive integer.")
        )

        (num_sources == 1 && angle != 0.0) && throw(
            DomainError("Angle must be zero if the number of sources is one.")
        )

        (num_sources != 1 && angle == 0.0) && throw(
            DomainError(
                "Angle must be non-zero if the number of sources is greater than one."
            )
        )

        (rotation_step <= 0 || rotation_step >= π) && throw(
            DomainError("Rotation step must be in (0, π).")
        )

        new(angle, num_sources, rotation_step)
    end
end

###################################
# Methods 
###################################
"""
    generate_from_baseline(
        baseline_x_positions::Vector{Float64},
        baseline_y_positions::Vector{Float64},
        baseline_x_directions::Vector{Float64},
        baseline_y_directions::Vector{Float64},
        rotation_angles::Vector{Float64},
    )

Generates a vector of `Beam` objects from the baseline positions and directions
    by rotating the baselines through the angles specified in `rotation_angles`.
"""
function generate_from_baseline(
    baseline_x_positions::Vector{Float64},
    baseline_y_positions::Vector{Float64},
    baseline_x_directions::Vector{Float64},
    baseline_y_directions::Vector{Float64},
    rotation_angles::Vector{Float64},
)

    # Check that all vectors are of the same length
    num_sources = length(baseline_x_positions)
    (
        length(baseline_y_positions) != num_sources ||
        length(baseline_x_directions) != num_sources ||
        length(baseline_y_directions) != num_sources
    ) && throw(
        DomainError("All baseline vectors must have the same length.")
    )

    # Generate Beams for each rotation angle 
    beams = Vector{Beam}(undef, length(rotation_angles) * num_sources)

    counter = 1
    for angle in rotation_angles
        for source in Base.OneTo(num_sources)
            # Calculate x-y position 
            x_pos = cos(angle) * baseline_x_positions[source] - 
                sin(angle) * baseline_y_positions[source]

            y_pos = sin(angle) * baseline_x_positions[source] + 
                cos(angle) * baseline_y_positions[source]
           
            # Calculate beam direction
            x_dir = cos(angle) * baseline_x_directions[source] - 
                sin(angle) * baseline_y_directions[source]

            y_dir = sin(angle) * baseline_x_directions[source] +
                cos(angle) * baseline_y_directions[source]

            # Create Beam 
            beams[counter] = Beam((x_pos, y_pos), (x_dir, y_dir))
            counter += 1
        end
    end

    return beams
end

"""
    generate(geometry::G, radius::Float64) where G<:ScanGeometry

Determines the source positions and beam directions of the scan geometry specified 
    by `geometry` and the radius of rotation specified by `radius`.

# Arguments 
- `geometry<:ScanGeometry`, the scan geometry for which to generate the beams.
- `radius::Float64`, the radius of rotation around the object being scanned. 
    This value must be positive and cannot be zero.

# Returns 
- `::Vector{Beam}`, a vector of `Beam` objects representing the source 
    positions and beam directions of the scan geometry.

# Throws 
- `DomainError`, if the radius of rotation is not positive.
"""
function generate(geometry::ParallelBeam, radius::Float64)

    (radius <= 0) && throw(
        DomainError("Radius of rotation must be a positive value.")
    )

    # Generate Baseline values (angle of rotation is 0) 
    
    ## Determine x-positions 
    baseline_x_positions = range(
        -radius*geometry.width_ratio, 
        radius*geometry.width_ratio, 
        length=geometry.num_sources
    ) |> collect 

    ## Determine y-positions 
    baseline_y_positions = Float64[ -sqrt(radius^2 - x^2) for x in baseline_x_positions]

    ## Generate beam directions 
    baseline_x_directions = zeros(Float64, geometry.num_sources)
    baseline_y_directions = ones(Float64, geometry.num_sources)

    # Rotation Angles; do not repeat collection at π since we already collect
    # at 0 radians. 
    rotation_angles = collect(0:geometry.rotation_step:(π-eps(Float64(π))))

    # Generate Beams for each rotation angle     
    return generate_from_baseline(
        baseline_x_positions,
        baseline_y_positions,
        baseline_x_directions,
        baseline_y_directions,
        rotation_angles
    )
end
function generate(geometry::FanBeam, radius::Float64)
    
    (radius <= 0) && throw(
        DomainError("Radius of rotation must be a positive value.")
    )

    # Generate Baseline x-positions and y-positions 
    baseline_x_positions = zeros(Float64, geometry.num_sources)
    baseline_y_positions = -radius.* ones(Float64, geometry.num_sources)

    # Generate Beam Directions 
    beam_angle = range(-geometry.angle/2, geometry.angle/2, geometry.num_sources) .+ π/2
    baseline_x_directions = cos.(beam_angle) 
    baseline_y_directions = sin.(beam_angle)

    # Rotation Angles; do not repeat collection at π since we already collect
    # at 0 radians. 
    rotation_angles = collect(0:geometry.rotation_step:(π-eps(Float64(π))))

    # Generate Beams for each rotation angle     
    return generate_from_baseline(
        baseline_x_positions,
        baseline_y_positions,
        baseline_x_directions,
        baseline_y_directions,
        rotation_angles
    )
end

