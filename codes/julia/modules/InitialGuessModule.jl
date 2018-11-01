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

struct InitialGuess

    # R&D labor supply
    L_RD::Float64

    # R&D wage
    w::Array{Float64}

    # Incumbent flow profit
    profit::Float64

    # Spinout entry threshold
    idxM::Int64

    # Spinout and entrant R&D effort
    zS::Array{Float64}
    zE::Array{Float64}

end

export InitialGuess

end
