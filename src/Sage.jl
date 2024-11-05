module Snild

using LinearAlgebra, StatsBase, TextAnalysis, Languages, SparseArrays, DuckDB, Unicode
using LogExpFunctions: logsumexp
using Statistics: mean, std
using Printf: @sprintf

# Export all public functions
export JJAI, learn!, answer, cleanup!, reset_knowledge!, encode_text

# Include all the components
include("types.jl")
include("transformer.jl")
include("database.jl")
include("core.jl")

end # module
