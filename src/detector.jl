###################################
# Constants 
###################################

###################################
# Data Structures
###################################
"""
    Detector 

An abstract type representing detectors used in the CT simulation. 
"""
abstract type Detector end

"""
    SingleChannel <: Detector 

A data structure representing a single-channel detector. 

# Fields 
- `channel::Tuple{Float64,Float64}`, the energy range that the detector is 
    sensitive to in keV. 
- `noise::Bool`, an indicator for whether the detector has read noise. If
    `true`, then the detector will have read noise of 0 to 5 photons. If `false`,
    the detector will not have read noise.

!!! info 
    The channel's first value in the tuple is the lower energy sensitivity limit
    and the second value is the upper energy sensitivity limit. 
"""
struct SingleChannel <: Detector 
    channel::Tuple{Float64,Float64}
    noise::Bool 

    SingleChannel(channel::Tuple{Float64,Float64}, noise::Bool) = begin 
        (channel[1] < 0 || channel[2] <= channel[1]) && throw(
                DomainError("Each channel's energy range must be valid.")
        )

        new(channel, noise)
    end
end

"""
    MultiChannel <: Detector 

A data structure representing a multi-channel detector. 

# Fields 
- `channels::Vector{Tuple{Float64, Float64}}`, a vector of tuples where each tuple 
    represents a channel's energy sensitivity. 
- `noise::Bool`, an indicator for whether the detector has read noise. If
    `true`, then the detector will have read noise of 3 to 5 photons. If `false`,
    the detector will not have read noise.
- `reading::Int64`, the reading for thed etector. 

!!! info 
    For each channel, the first value in the tuple is the lower energy sensitivity limit
    and the second value is the upper energy sensitivity limit. 
"""
struct MultiChannel <: Detector 
    channels::Vector{Tuple{Float64, Float64}} 
    noise::Bool 

    MultiChannel(channels::Vector{Tuple{Float64, Float64}}, noise::Bool) = begin 
        (length(channels) == 0) && throw(
            DomainError("Channels vector must not be empty.")
        )

        for (lower, upper) in channels
            (lower < 0 || upper <= lower) && throw(
                DomainError("Each channel's energy range must be valid.")
            )
        end

        new(channels, noise)
    end
end

###################################
# Methods 
###################################
"""
    detector_location(beam::Beam, radius::Float64)

Calculates the location of the detector based on the beam's source and direction.

# Arguments 
- `beam::Beam`, the beam for which to calculate the detector location.
- `radius::Float64`, the radius of the circle on which the beam's source and detector 
    are located. This value must be positive and cannot be zero.

# Returns 
- `::Tuple{Float64, Float64}`, a tuple representing the x and y coordinates of the detector 
    location.

# Throws
- `DomainError`, if the radius of rotation is not positive, if the beam's source is not on 
    the circle of radius `radius`, if the beam's direction is not a unit vector, or if the 
    beam's direction points outside of the scanning region.
"""
function detector_location(beam::Beam, radius::Float64)

    # Verify that the radius is positive 
    (radius > 0) || throw(
        DomainError("Radius of rotation must be a positive value.")
    )

    # Verify that the beam is on the radius of the circle 
    (beam.source[1]^2 + beam.source[2]^2 ≈ radius^2) || throw(
        DomainError("Beam source must be on the circle of radius $radius.")
    )

    # Verify that the beam direction is a unit vector 
    (beam.direction[1]^2 + beam.direction[2]^2 ≈ 1.0) || throw(
        DomainError("Beam direction must be a unit vector.")
    )

    # Verify that the beam direction is not pointing outside of the circle 
    (beam.source[1] * beam.direction[1] + beam.source[2] * beam.direction[2] 
        <= 0 ) || throw(
            DomainError(
                "Beam direction must remain within the scanning region."
            )
        )
    
    # Calculate the detector location
    travel_length = -(beam.source[1] * beam.direction[1] + 
        beam.source[2] * beam.direction[2])
    
    x_location = beam.source[1] + 2*travel_length*beam.direction[1] 
    y_location = beam.source[2] + 2*travel_length*beam.direction[2]

    return (x_location, y_location)
end

function read(
    photons::Int64;
    light::Monochromatic,
    detector::SingleChannel
)
    # If outside of the detector's channel range, the photons have no effect 
    if (detector.channel[1] > light.energy || detector.channel[2] < light.energy)
        return detector.noise ? rand(0:5) : 0

    # If inside of the detector's channel range, then count the number of photons 
    else 
        return detector.noise ? rand(0:5) + photons : photons
    end
end

function read(
    photons::Vector{Int64};
    light::Polychromatic,
    detector::MultiChannel
)

    readings = zeros(Int64, length(detector.channels))

    for (photon, energy) in Iterators.zip(
        photons,
        light.energy_range[1]:light.discretization:light.energy_range[2]
    )
        

    end


end