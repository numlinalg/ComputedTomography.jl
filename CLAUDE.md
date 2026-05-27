# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`ComputedTomography.jl` is a Julia package for simulating CT (computed tomography) scanner behavior: modeling X-ray source emission, scan geometries (beam configurations), and detector readings. The longer-term goal is to produce system matrices for image reconstruction.

## Commands

```bash
# Run all tests
julia --project=. -e "using Pkg; Pkg.test()"

# Run tests from within Julia REPL (after activating project)
using Pkg; Pkg.test()

# Run a single test file
julia --project=test test/src/chromatic.jl   # won't work standalone — tests use module scoping
# Instead, run the full suite; individual testsets are named for filtering

# Build docs
julia --project=docs docs/make.jl

# Start Julia REPL with the package loaded
julia --project=. -e "using ComputedTomography"
```

## Architecture

The package has three conceptual layers, each in its own source file:

**`src/chromatic.jl`** — X-ray source modeling  
Defines `Chromatic` (abstract), `Monochromatic` (single energy), and `Polychromatic` (energy range + discretization). The `generate(light, photons=)` function returns photon counts: a single `Int64` for monochromatic, a `Vector{Int64}` for polychromatic. Energy is bounded to `[1.0, 120.0]` keV. `source_intensity` models Bremsstrahlung radiation plus four tungsten characteristic radiation peaks.

**`src/scan_geometry.jl`** — Beam geometry  
Defines `ScanGeometry` (abstract), `ParallelBeam`, and `FanBeam`. Both store `num_sources` and `rotation_step ∈ (0, π)`. The `Beam` struct (mutable) holds a 2D source position and direction as `Tuple{Float64,Float64}` in absolute Cartesian coordinates. `generate(geometry, radius)` produces a `Vector{Beam}` covering half a rotation (0 to π exclusive) by rotating a baseline configuration via `generate_from_baseline`. The scan covers only half a rotation because opposite angles produce the same line through the object.

**`src/detector.jl`** (in-progress, on `detector` branch)  
Defines `Detector` (abstract), `SingleChannel`, and `MultiChannel`. A channel is a `Tuple{Float64,Float64}` energy sensitivity range. The `read` functions (not yet exported) take photon counts and return detector readings, with optional noise (3–5 photon read noise). `detector_location(beam, radius)` computes where on the scanning circle the beam hits the detector opposite its source.

**`src/ComputedTomography.jl`** — module root  
Currently includes `chromatic.jl` and `scan_geometry.jl`. Exports: `Monochromatic`, `Polychromatic`, `ParallelBeam`, `FanBeam`, `generate`. `Beam`, `generate_from_baseline`, `source_intensity` are internal (accessed as `ComputedTomography.Beam`, etc. in tests).

## Test structure

Tests live in `test/src/` as submodules (`module testchromatic`, `module testscangeometry`) and are included from `test/runtests.jl`. Each module uses `using ..Test` and `using ..ComputedTomography` — they rely on the parent test environment, so they cannot be run in isolation.

## Coordinate system conventions

- All positions and directions are in a 2D absolute Cartesian coordinate system.
- Sources are placed on a circle of the given `radius`.
- Beam directions must be unit vectors pointing inward (toward the origin side).
- `ParallelBeam`: sources span `[-radius*width_ratio, radius*width_ratio]` along x at the bottom of the circle, all directed upward (y-direction).
- `FanBeam`: all sources at a single point at the bottom of the circle, directions fanning out symmetrically around the upward direction.
