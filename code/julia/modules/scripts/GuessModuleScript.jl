#---------------------------------
# Name: initialGuessModuleScript.jl
#
# Module relating to initial guesses
#
# Contains definitions of
# initialGuess composite type
#

export Guess

mutable struct Guess

    # Growth rate g
    g::Float64

    # R&D labor supply
    L_RD::Float64

    # R&D wage guess:
    # Function of L_RD guess and parameters
    w::Array{Float64}

    # Spinout entry threshold
    idxM::Int64

    # Drift due to non-competing spinouts
    driftNonCompeting::Float64

    # Spinout and entrant R&D effort
    #zS::Array{Float64}

    #zE::Array{Float64}

end
