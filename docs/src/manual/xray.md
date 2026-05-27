CT images are formed by evaluating the interaction between X-rays and an object.
This page discusses X-rays and how they are simulated in the library.

## Simplified X-ray Physics

X-rays are electromagnetic radiation whose frequency ranges from 
$3\times 10^{16}$ Hz to $3 \times 10^{20}$ Hz, which corresponds to 
energies ranging from $124$ eV to $1.24$ MeV. 
X-rays with low energy interact ($\leq 10$ keV) readily with objects and do not 
penetrate deeply into materials, making them less useful for computed tomography
(CT).
X-rays with high energy ($>250$ keV) do not interact strongly with objects
and often pass through them, making them less useful for CT. 

Hence, producing X-rays within the $10$ keV to $250$ keV range is ideal for 
computed tomography applications. 
The typical production of x-rays occurs by creating a voltage difference between
a source (typically Tungsten) and target (typically Tungsten), 
then thermally exciting the source
causing it to release electrons.
These electrons are then influenced by the potential difference between the 
source and target, which forces them to accelerate towards the target. 
When these electrons strike the target, they interact in two distinct ways
that causes them to release X-rays.

- Bremsstrahlung: When passing by a nucleus in the target, the electrons slow 
    down by attraction to the positively charged nucleus. The electrons release 
    the kinetic energy as x-ray radiation called Bremsstrahlung. 
    Bremsstrahlung accounts for 80% of the X-ray photons produced from 
    this process. It has a continuous spectrum from about 10 keV to 
    120 keV which loosely looks like it follows Planck's law.
- Characteristic Radiation: When passing by an atom in the target, 
    the incoming electrons may knock loose an inner shell electron in 
    the target. When an outer shell electron drops to the inner shell to fill 
    this gap, it releases energy known as characteristic radiation. 


## Simulation of 120 keV X-ray Tube

X-ray generation is simulated in `src/chromatic.jl`. 
There are two types of X-rays that are generated [`Monochromatic`](@ref)
and [`Polychromatic`](@ref).

- The monochromatic type is used to simulate the number of photons released by 
    the Tungsten target at its specified `energy`.
    The number of photons released at this specific energy is computed relative 
    to mode of the number of photons released because of Bremsstrahlung 
    (by default, it is set to $1e12$, but this can be changed. 
    See [`generate`](@ref)).
- The polychromatic type is used to simulate the number of photons released by a 
    Tungsten target over a discretization of an energy range. 
    This discretization and energy range is specified by the 
    fields of the polychromatic type. Just as for the monochromatic types, the 
    number of photons simulated at each energy is simulated relative to the 
    mode of the number of photons released because of Bremsstrahlung.

If we assume the mode of the number of photons released from Bremsstrahlung 
is given by `photons`, then the following table indicates the number of photons 
released by the different characteristic radiation energy ranges for Tungsten.

| Energy Range (keV) | Photons | 
|:-------------------|:--------|
| (57.8, 58)         | `photons` |
| (59.2, 59.4)       | `1.33*photons` |
| (67.1, 67.3)       | `0.8*photons` |
| (69, 69.2)         | `0.8*photons` |

Otherwise, the number of photons released is determined by taking the 
energy of the x-ray, `e`, and evaluating 

```math 
\frac{e^3 \cdot \text{photons}/1400}{ \exp( e/10) - 1}.
```