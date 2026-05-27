using ComputedTomography, Colors, TestImages, ImageView 

img = testimage("fabio_gray_256")
img_gray = Gray.(img)

# A CT Machine has a 
# - x-ray source: Chromatic  
# - scan geometry: Parallel or Fan 
# - detector: single channel or multi-channel detector 

# A single probing beam must leave the source from a particular location, 
# in a particular direction, with a particular set of photons at 
# a single or distinct energy levels, which are read by a detector 
# at a particular location 

# Data = (Vector{Beam}, Vector{Vector{Int64}}, Vector{Vector{Int64}})

# TODO: Change monochromatic's output to a vector 