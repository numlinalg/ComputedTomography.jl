# ComputedTomography

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://numlinalg.github.io/ComputedTomography.jl/dev/)
[![Status](https://github.com/numlinalg/ComputedTomography.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/numlinalg/ComputedTomography.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/numlinalg/ComputedTomography.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/numlinalg/ComputedTomography.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

 A Julia library for simulating CT detector results of a given image, and specifying the mathematical problem for reconstructing the original image.

## Development Roadmap

The package is built in five sequential phases. Each phase corresponds to one source file and depends on all previous phases.

### Phase 1 — Detector (`src/detector.jl`) ✅ in progress

Models what a detector records after a beam traverses the object.

| Type / Function | Description |
|---|---|
| `Detector` | Abstract type |
| `SingleChannel` | Detector sensitive to a single `(lower, upper)` keV energy window |
| `MultiChannel` | Detector with multiple energy windows |
| `detector_location(beam, radius)` | Computes the exit point of a beam on the scanning circle |
| `read(photons; light::Monochromatic, detector::SingleChannel)` | Returns photon count ± noise |
| `read(photons; light::Polychromatic, detector::MultiChannel)` | Returns per-channel photon counts ± noise |

**Design note:** A channel reading is the sum of all photons whose energy falls within the channel's `[lower, upper]` range. Noise (if enabled) adds a random 0–5 photon offset per channel. `detector_location` uses the chord-exit formula: given a source on a circle of radius `r` with an inward unit direction `d`, the exit point is `source + 2·(−source·d)·d`.

---

### Phase 2 — Image representation (`src/image.jl`)

Bridges the continuous beam geometry (Cartesian coordinates) with the discrete pixel grid.

| Type / Function | Description |
|---|---|
| `CTImage` | Holds the pixel array and the physical extent (e.g. field of view in cm) |
| `pixel_at(image, x, y)` | Returns the pixel value at absolute Cartesian coordinate `(x, y)` |
| `attenuation(image, x, y, energy)` | Returns the linear attenuation coefficient μ (cm⁻¹) at `(x, y)` for a given energy |

**Design note:** The physical extent maps grid index `(i, j)` to Cartesian `(x, y)` via a simple affine transform. Attenuation can be represented as a lookup from grayscale intensity to μ at each energy, or as a per-pixel material label with a reference table.

---

### Phase 3 — Ray tracing (`src/ray_tracing.jl`)

For each `Beam`, determines which pixels it crosses and the chord length through each. This is the computational core of both the forward model and the system matrix.

| Type / Function | Description |
|---|---|
| `intersect(beam, image)` | Returns a list of `(pixel_index, chord_length)` pairs for the beam's path through the image |

**Design note:** The standard algorithm is **Siddon's algorithm** — it computes exact intersections on a regular grid in O(rows + cols) per ray. Joseph's method is an alternative that bilinearly interpolates instead of taking exact intersections. Correctness over performance for the initial implementation.

---

### Phase 4 — Forward model (`src/forward_model.jl`)

Given a beam and a light source, simulates the photon count reaching the detector after attenuation through the object.

| Type / Function | Description |
|---|---|
| `attenuate(beam, light, image)` | Returns photon count at the detector after Beer–Lambert attenuation |
| `scan(geometry, light, image, detector, radius)` | Returns the full vector of detector readings for every beam in the scan |

**Design note:** Beer–Lambert: `I = I₀ · exp(−Σ μᵢ · lᵢ)` where `lᵢ` are chord lengths from `intersect` and `μᵢ` are attenuation coefficients at each pixel. For `Polychromatic` sources, apply per energy level then sum — this naturally models beam hardening (lower energies attenuate more strongly and are preferentially removed).

---

### Phase 5 — System matrix (`src/system_matrix.jl`)

Assembles the matrix `A` such that `b ≈ Ax`, where `b` is the measurement vector and `x` is the vectorized image. This is the input to reconstruction algorithms.

| Type / Function | Description |
|---|---|
| `system_matrix(geometry, image, radius)` | Returns a sparse matrix with one row per beam and one column per pixel; entry is chord length |

**Design note:** Each row is the output of `intersect` for one beam, stored sparsely. The return type is `SparseArrays.SparseMatrixCSC{Float64, Int64}` — add `SparseArrays` as a package dependency. Reconstruction algorithms (FBP, SART, CGLS, etc.) are out of scope; this matrix is the handoff point.