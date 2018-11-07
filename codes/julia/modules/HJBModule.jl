#---------------------------------
# Name: HJBModule.jl
#
# Module relating to solving HJBs
#
# Contains:
#
# Functions:
#
# solveIncumbentHJB
# solveSpinoutHJB
#
# Types:
#
# incumbentSolution
#
#

__precompile__()

module HJBModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule
import AuxiliaryModule

export IncumbentSolution, solveIncumbentHJB, solveSpinoutHJB

struct IncumbentSolution

    V::Array{Float64}
    zI::Array{Float64}

end

function solveSpinoutHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::Guess, V::Array{Float64})

    # Placeholder
    return zeros(algoPar.mGrid.numPoints,1)

end

function solveIncumbentHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, verbose = 2, print_skip = 10)

    # do stuff to sovle for V, including potentially calling other functions
    V0 = AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,guess)

    # General
    ρ = modelPar.ρ;
    β = modelPar.β;
    L = modelPar.L;

    # Innovation
    χI = modelPar.χI;
    χS = modelPar.χS;
    χE = modelPar.χE;
    ψI = modelPar.ψI;
    ψSE = modelPar.ψSE;
    λ = modelPar.λ;

    # Spinouts
    ν = modelPar.ν;
    ξ = modelPar.ξ;

    # Guesses
    Π = AuxiliaryModule.profit(initGuess.L_RD,modelPar);
    w = initGuess.w;
    zS = initGuess.zS;
    zE = initGuess.zE;

    ## Load algorithm parameters
    


    # Some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ϕI_inv(z) = z .^(-1/ψI)
    ϕSE_inv(z) = z .^(-1/ψSE)

    # Temporary - just for testing high-level structure of my code
    return IncumbentSolution(zeros(algoPar.mGrid.numPoints,1),zeros(algoPar.mGrid.numPoints,1))

end


end
