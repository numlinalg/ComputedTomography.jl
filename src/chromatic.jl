###################################
# Constants 
###################################
"""
    ENERGY_MIN = 1.0 (keV)

The minimum energy of a simulate X-ray beam.
"""
const ENERGY_MIN = 1.0 #keV
"""
    ENERGY_MAX = 120.0 (keV)

The maximum energy of a simulate X-ray beam.
"""
const ENERGY_MAX = 120.0 #keV

###################################
# Data Structures
###################################
"""
    Chromatic 

An abstract type representing the type of X-ray spectrum used in the simulation.
"""
abstract type Chromatic end 

"""
    Monochromatic <: Chromatic

An immutable struct representing a monochromatic X-ray beam. 

# Fields 
- `energy::Float64`, the energy of the X-ray beam in keV between $ENERGY_MIN and 
    $ENERGY_MAX keV.
"""
struct Monochromatic <: Chromatic
    energy::Float64  # Energy in keV
    Monochromatic(energy::Float64) = begin 
        (energy < ENERGY_MIN || energy > ENERGY_MAX) && throw(
            DomainError("Energy must be between $ENERGY_MIN keV and $ENERGY_MAX keV.")
        )
        new(energy)
    end
end

"""
    Polychromatic <: Chromatic

An immutable struct representing a polychromatic X-ray beam.
    
# Fields 
- `energy_range::Tuple{Float64, Float64}`, the energy range of the X-ray beam in keV.
    This lower end of the range must be first and the larger end of the range is second. 
    The lower end of the range cannot be less than $ENERGY_MIN keV. 
    The upper end of the range cannot exceed $ENERGY_MAX keV. 
- `discretization::Float64`, the energy discretization for the energy range in keV.
    The discretization value must be positive and cannot exceed the difference between 
    the largest and smallest value in the energy range.

!!! info 
    Use `Monochromatic` for generating a single energy X-ray. 
"""
struct Polychromatic <: Chromatic 
    energy_range::Tuple{Float64, Float64} # Energy range in keV (min, max)
    discretization::Float64 # Energy discretization for the energy range 
    Polychromatic(energy_range::Tuple{Float64, Float64}, discretization::Float64) = begin
        
        # min < max ? 
        energy_range[1] >= energy_range[2] && throw(
            DomainError(
                "Energy range must start with a value smaller than the second value."
            )
        )

        # min > 1 && max < 120 ?
        (energy_range[1] < ENERGY_MIN || energy_range[2] > ENERGY_MAX) && throw(
            DomainError("Energy range must be between $ENERGY_MIN keV and $ENERGY_MAX keV.")
        )

        # Discretization must be positive 
        discretization < 0 && throw(
            DomainError("Discretization must be positive.")
        )

        # Discretization cannot exceed spectrum range 
        discretization > (energy_range[2] - energy_range[1]) && throw(
            DomainError("Discretization cannot exceed the energy range.")
        )
        
        new(energy_range, discretization)
    end
end

###################################
# Methods 
###################################
"""
    source_intensity(energy::Float64; photons::Int64=1e12)

The number of photons of the X-ray at a given energy level at the source. The 
number of photons is loosely based on a 120 keV X-ray tube with a tungsten target.
This function accounts for both Bremsstrahlung radiation and Characteristic radiation. 

# Arguments 
- `energy::Float64`, the energy of the X-ray in keV.

# Keyword Arguments 
- `photons::Int64=1e12`, the number of photons emitted at the mode of Bremsstrahlung 
    radiation. Defaults to `1e12` photons.

# Returns 
- `::Int64`, the number of photons generated at the source for the given energy level.
"""
function source_intensity(energy::Float64; photons::Int64=1e12)
    if energy < ENERGY_MIN
        return 0
    elseif energy > ENERGY_MAX 
        return 0 
    elseif (energy > 57.8 && energy < 58.0) # Tungsten characteristic radiation
        return round(Int64, photons)
    elseif (energy > 59.2 && energy < 59.4) # Tungsten characteristic radiation
        return round(Int64, photons * 1.33)
    elseif (energy > 67.1 && energy < 67.3) # Tungsten characteristic radiation 
        return round(Int64, photons * 0.8)
    elseif (energy > 69 && energy < 69.2) # Tungsten characteristic radiation 
        return round(Int64, photons * 0.8)
    else 
        # Loosely based on Plank's Law 
        # 1400 normalizes to the intensity of 1 
        return round(Int64, energy^3 * 1/(exp( energy / 10 ) - 1) * (photons / 1400))
    end 
end

"""
    generate(light::Chromatic; photons::Int64=1e12)

Returns the number of photons emitted at the source for a given X-ray light source.
    See [`source_intensity`](@ref) for more details on the `photons` argument.
    Returns an integer value representing the number of photons. 
"""
function generate(light::Monochromatic; photons::Int64=1e12)
    return source_intensity(light.energy, photons=photons)
end

"""
    generate(light::Polychromatic; photons::Int64=1e12)

Returns the number of photons emitted at the source for each energy in a polychromatic X-ray 
    light source as a vector of integers.
    See [`source_intensity`](@ref) for more details on the `photons` argument.
"""
function generate(light::Polychromatic; photons::Int64=1e12)
    # Generate a range of energies based on the discretization
    energies = light.energy_range[1]:light.discretization:light.energy_range[2]
    return Int64[source_intensity(energy, photons=photons) for energy in energies]
end