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

    # Unrestricted
    # Function of L_RD guess and parameters
    w::Array{Float64}

    # Non-compete wage
    wNC::Array{Float64}

    # Entrants wage
    wE::Array{Float64}

    # Spinout entry threshold
    idxM::Int64

    # Drift due to non-competing spinouts
    driftNC::Float64

    # Spinout and entrant R&D effort
    #zS::Array{Float64}

    #zE::Array{Float64}

end
