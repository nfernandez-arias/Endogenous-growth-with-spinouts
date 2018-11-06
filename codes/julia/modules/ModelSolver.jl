#---------------------------------
# Name: ModelSolver.jl
#
# Module containing functions for
# solving the model given:
#
# Algorithm parameters
# Model parameters
# Initial guesses
#
# For detailed documentation
# of contained functions, see ModelSolver Readme
# in the Readme folder
#
# Contains definitions of
# modelParameters composite type

__precompile__()

module ModelSolver

using AlgorithmParametersModule, ModelParametersModule, GuessModule
import AuxiliaryModule

export solveModel, solveIncumbentHJB

function update_L_RD(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess)

    # Calculate L_RD based on results from inner fixed points
    # Essentially, aggregating based on KF equation etc.

    # Placeholder...

    return InitialGuess(initGuess.L_RD, initGuess.w, initGuess.zS, initGuess.zE)

end

function update_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess)

    # Placeholder...
    return InitialGuess(initGuess.L_RD, initGuess.w, initGuess.zS, initGuess.zE)

end

function update_zSzE(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, V::Array{Float64})

    ## Build grid
    mGrid = mGridBuild(algoPar.mGrid);

    ## Unpack modelPar

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

    # Some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack guesses
    old_zS = initGuess.zS;
    old_zE = initGuess.zE;

    ## Compute new guesses

    temp_zS = min.(ξ*mGrid, old_zS .* (χS * ϕSE(old_zS + old_zE) * V[1] ./ initGuess.w));
    temp_zE = old_zE .* (χE * ϕSE(old_zS + old_zE) * V[1] ./ initGuess.w)

    new_zS = temp_zS * algoPar.zSzE.updateRate + old_zS * (1 - algoPar.zSzE.updateRate);
    new_zE = temp_zE * algoPar.zSzE.updateRate + old_zE * (1 - algoPar.zSzE.updateRate);

    # Placeholder...
    return InitialGuess(initGuess.L_RD, initGuess.w, initGuess.zS, initGuess.zE)

end


function solveIncumbentHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, verbose = 2, print_skip = 10)

    # do stuff to sovle for V, including potentially calling other functions
    V0 = AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,initGuess)

    # Build grid
    mGrid = mGridBuild(algoPar.mGrid);

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

    # Some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ϕI_inv(z) = z .^(-1/ψI)
    ϕSE_inv(z) = z .^(-1/ψSE)



    # Temporary - just for testing high-level structure of my code
    return zeros(algoPar.mGrid.numPoints,1)

end

function iterate_zSzE(algoPar::AlgorithmParameters, modelPar::ModelParameters,initGuess::InitialGuess)

    #vProfit = ones(pa.mGridParameters.numPoints,1) * AuxiliaryModule.profit(guess.L_RD);

    # Solve HJB given guesses
    V = solveIncumbentHJB(algoPar,modelPar,initGuess)
    #W = V;
    # W = solveSpinoutHJB(algoPar,modelPar,initGuess,V)

    # Compute new zS, based on V and W
    # Return InitialGuess object
    return update_zSzE(algoPar,modelPar,initGuess,V)

end

function computeFixedPoint_zSzE(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, verbose = 2, print_skip = 10)

    # Error message
    if !(verbose in (0,1,2))
        throw(ArgumentError("verbose should be 0, 1 or 2"))
    end

    # Unpack relevant algorithm parameters
    tolerance = algoPar.zSzE.tolerance;
    maxIter = algoPar.zSzE.maxIter;
    updateRate = algoPar.zSzE.updateRate;
    updateRateExponent = algoPar.zSzE.updateRateExponent;

    # While loop to compute fixed point
    iterate = 0;
    error = tolerance + 1;

    oldGuess = initGuess;

    while iterate < maxIter && error > tolerance

        newGuess = iterate_zSzE(algoPar,modelPar,oldGuess);
        iterate += 1;
        error = maximum(abs,newGuess.zS - oldGuess.zS);

        if verbose == 2
            if iterate % print_skip == 0
                println("Compute iterate $iterate with error $error")
            end
        end

        oldGuess = newGuess;

    end

    if verbose >= 1
        if error > tolerance
            warn("maxIter attained in computeFixedPoint_L_RD")
        elseif verbose == 2
            println("Converged in $iterate steps")
        end
    end

    return oldGuess

end


function iterate_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess)

    #vProfit = ones(pa.mGridParameters.numPoints,1) * AuxiliaryModule.profit(guess.L_RD);

    # Solve model conditional on L_RD
    guessTemp = computeFixedPoint_zSzE(algoPar,modelPar,initGuess,0)

    # Aggregate to compute new w
    # Return InitialGuess object
    return update_w(algoPar,modelPar,guessTemp)

end

function computeFixedPoint_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, verbose = 2, print_skip = 10)

    # Error message
    if !(verbose in (0,1,2))
        throw(ArgumentError("verbose should be 0, 1 or 2"))
    end

    # Unpack relevant algorithm parameters
    tolerance = algoPar.w.tolerance;
    maxIter = algoPar.w.maxIter;
    updateRate = algoPar.w.updateRate;
    updateRateExponent = algoPar.w.updateRateExponent;

    # While loop to compute fixed point
    iterate = 0;
    error = tolerance + 1;

    oldGuess = initGuess;

    while iterate < maxIter && error > tolerance

        newGuess = iterate_w(algoPar,modelPar,oldGuess);
        iterate += 1;
        error = maximum(abs,newGuess.w - oldGuess.w);

        if verbose == 2
            if iterate % print_skip == 0
                println("Compute iterate $iterate with error $error")
            end
        end

        oldGuess = newGuess;

    end

    if verbose >= 1
        if error > tolerance
            warn("maxIter attained in computeFixedPoint_L_RD")
        elseif verbose == 2
            println("Converged in $iterate steps")
        end
    end

    return oldGuess

end


#--------------------------#
## Function: iterate_L_RD
# This function takes
# as input the parameters and initial guess
#
# It then runs one iteration of the outermost loop of
#

function iterate_L_RD(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess)

    #vProfit = ones(pa.mGridParameters.numPoints,1) * AuxiliaryModule.profit(guess.L_RD);

    # Solve model conditional on L_RD guess
    guessTemp = computeFixedPoint_w(algoPar,modelPar,initGuess,0)

    # Aggregate to compute new L_RD
    return update_L_RD(algoPar,modelPar,guessTemp)

end

function computeFixedPoint_L_RD(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, verbose = 2, print_skip = 10)

    # Error message
    if !(verbose in (0,1,2))
        throw(ArgumentError("verbose should be 0, 1 or 2"))
    end

    # Unpack relevant algorithm parameters
    tolerance = algoPar.L_RD.tolerance;
    maxIter = algoPar.L_RD.maxIter;
    updateRate = algoPar.L_RD.updateRate;
    updateRateExponent = algoPar.L_RD.updateRateExponent;

    # While loop to compute fixed point
    iterate = 0;
    error = tolerance + 1;

    oldGuess = initGuess;

    while iterate < maxIter && error > tolerance

        newGuess = iterate_L_RD(algoPar,modelPar,oldGuess);
        iterate += 1;
        error = abs(newGuess.L_RD - oldGuess.L_RD);

        if verbose == 2
            if iterate % print_skip == 0
                println("Compute iterate $iterate with error $error")
            end
        end

        oldGuess = newGuess;

    end

    if verbose >= 1
        if error > tolerance
            warn("maxIter attained in computeFixedPoint_L_RD")
        elseif verbose == 2
            println("Converged in $iterate steps")
        end
    end

    return oldGuess

end

function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::InitialGuess)

    # Compute high-level fixed point
    return computeFixedPoint_L_RD(algoPar,modelPar,initGuess,0)

end

end
