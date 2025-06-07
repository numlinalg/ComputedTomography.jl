module testchromatic 

using ..Test 
using ..ComputedTomography

@testset "Chromatic: Monochromatic Struct" begin 

    # Cannot be less than 1 keV 
    let energy=-10.0 
        @test_throws DomainError Monochromatic(energy)
    end

    # Cannot exceed maximum energy of 120 keV
    let energy=150.0
        @test_throws DomainError Monochromatic(energy)
    end

    # Correct functioning 
    let energy=10.0 
        light = Monochromatic(energy)
        @test light.energy == energy
    end

end

@testset "Chromatic: Polychromatic Struct" begin

    # Energy range must be between 1 keV and 120 keV
    let energy_range=(-10.0, 10.0), discretization=1.0
        @test_throws DomainError Polychromatic(energy_range, discretization)
    end

    let energy_range=(10.0, 150.0), discretization=1.0
        @test_throws DomainError Polychromatic(energy_range, discretization)
    end

    # Energy range's first argument must be less than the second argument 
    let energy_range=(10.0, 5.0), discretization=1.0
        @test_throws DomainError Polychromatic(energy_range, discretization)
    end

    # Discretization must be positive
    let energy_range=(10.0, 20.0), discretization=-1.0
        @test_throws DomainError Polychromatic(energy_range, discretization)
    end

    # Discretization cannot exceed the energy spectrum range 
    let energy_range=(10.0, 20.0), discretization=15.0
        @test_throws DomainError Polychromatic(energy_range, discretization)
    end

    # Correct functioning 
    let energy_range=(10.0, 20.0), discretization=1.0
        
        light = Polychromatic(energy_range, discretization)
        @test light.energy_range == energy_range
        @test light.discretization == discretization
    end
end

@testset "Chromatic: Source Intensity" begin 

    # Source Intensity for energy below 1 keV should be zero 
    let energy=0.5, photons=1
        @test ComputedTomography.source_intensity(energy, photons=photons) == 0
    end

    # Source intensity for energy above 120 keV should be zero 
    let energy=150.0, photons=1
        @test ComputedTomography.source_intensity(energy, photons=photons) == 0
    end

    # Source intensity for energy between 57.8 keV and 58 keV should be `photons`
    let energy=57.9, photons=1
        @test ComputedTomography.source_intensity(energy, photons=photons) == 1
    end

    # Source intensity for energy between 59.2 and 59.4 keV should be round(photons*1.33)
    let energy=59.3, photons=3
        @test ComputedTomography.source_intensity(energy, photons=photons) == 4
    end

    # Source intensity for energy between 67.1 and 67.3 keV should be round(photons*0.8)
    let energy=67.2, photons=5
        @test ComputedTomography.source_intensity(energy, photons=photons) == 4
    end

    # Source intensity for energy between 69 and 69.2 keV should be round(photons*0.8)
    let energy=69.1, photons=5
        @test ComputedTomography.source_intensity(energy, photons=photons) == 4
    end

    # Source intensity for energy between 1 keV and 120 keV excluding previous ranges should 
    # be Bremmstrahlung radiation. 
    let energy=30.0, photons=1
        @test ComputedTomography.source_intensity(energy, photons=photons) == 1
    end

end

@testset "Chromatic: Light Generation" begin 

    # Monochromatic light generation 
    let energy=30.0, photons=1, light=Monochromatic(energy)
        @test ComputedTomography.generate(light, photons=photons) == 1
    end

    # Polychromatic light generation 
    let energy_range=(11.0, 12.0), 
        discretization=1.0, 
        photons=1, 
        light=Polychromatic(energy_range, discretization)

        intensities = ComputedTomography.generate(light, photons=photons)
        @test length(intensities) == 2 
        @test intensities == [0, 1]
    end

end

end