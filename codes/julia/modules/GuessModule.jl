#---------------------------------
# Name: initialGuessModule.jl
#
# Module relating to initial guesses
#
# Contains definitions of
# initialGuess composite type
#

__precompile__()

module GuessModule

export Guess

mutable struct Guess

    # R&D labor supply
    L_RD::Float64

    # R&D wage guess:
    # Function of L_RD guess and parameters
    w::Array{Float64}

    # Spinout entry threshold
    #idxM::Int64

    # Spinout and entrant R&D effort
    zS::Array{Float64}

    zE::Array{Float64}

end

end
