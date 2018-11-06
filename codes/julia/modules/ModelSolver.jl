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

using AlgorithmParametersModule, ModelParametersModule, GuessModule, HJBModule
import AuxiliaryModule

export solveModel

function update_L_RD_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, incumbentHJBSolution::IncumbentSolution)

    # Unpack incumbentHJBSolution
    V = incumbentHJBSolution.V;
    zI = incumbentHJBSolution.zI;

    ## Update w
    # Load parameters and model constants
    ν = modelPar.ν;
    wbar = AuxiliaryModule.wbar(modelPar.β);

    # First compute W, value of spinout, for computing R&D wage update
    W = solveSpinoutHJB(algoPar,modelPar,initGuess,V)
    # Compute new wage
    temp_w = wbar * ones(size(W)) - ν * W;
    w = algoPar.w.updateRate * temp_w + (1 - algoPar.w.updateRate) * initGuess.w;

    ## Update L_RD
    # Need to solve KF equation - easy given tau.
    # Then need to aggregate back up to L_RD

    return InitialGuess(initGuess.L_RD, w, initGuess.zS, initGuess.zE),W

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
    w = initGuess.w;

    ## Compute new guesses

    temp_zS = min.(ξ*mGrid, old_zS .* (χS * ϕSE(old_zS + old_zE) * V[1] ./ w));
    temp_zE = old_zE .* (χE * ϕSE(old_zS + old_zE) * V[1] ./ w)

    zS = temp_zS * algoPar.zSzE.updateRate + old_zS * (1 - algoPar.zSzE.updateRate);
    zE = temp_zE * algoPar.zSzE.updateRate + old_zE * (1 - algoPar.zSzE.updateRate);

    # Placeholder...
    return InitialGuess(initGuess.L_RD, initGuess.w, zS, zE)

end

function iterate_zSzE(algoPar::AlgorithmParameters, modelPar::ModelParameters,initGuess::InitialGuess)

    #vProfit = ones(pa.mGridParameters.numPoints,1) * AuxiliaryModule.profit(guess.L_RD);

    # Solve HJB given guesses
    incumbentHJBSolution = solveIncumbentHJB(algoPar,modelPar,initGuess)
    #W = V;
    # W = solveSpinoutHJB(algoPar,modelPar,initGuess,V)

    # Compute new zS, based on V and W
    # Return InitialGuess object
    newGuess = update_zSzE(algoPar,modelPar,initGuess,incumbentHJBSolution.V);
    return newGuess,incumbentHJBSolution

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
    error = 1;

    oldGuess = initGuess;

    while iterate < maxIter && error > tolerance

        newGuess,incumbentHJBSolution = iterate_zSzE(algoPar,modelPar,oldGuess);
        incumbentHJBSolution
        sleep(5)
        iterate += 1;
        # Check distance
        error = max(maximum(abs,newGuess.zS - oldGuess.zS),maximum(abs,newGuess.zE - oldGuess.zE));

        if verbose == 2
            if iterate % print_skip == 0
                println("Compute iterate $iterate with error $error")
            end
        end

        oldGuess = newGuess;

    end

    if verbose >= 1
        if error > tolerance
            warn("maxIter attained in computeFixedPoint_zSzE")
        elseif verbose == 2
            println("Converged in $iterate steps")
        end
    end

    newGuess,incumbentHJBSolution = iterate_zSzE(algoPar,modelPar,oldGuess);

    return oldGuess,incumbentHJBSolution

end

function iterate_L_RD_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess)

    #vProfit = ones(pa.mGridParameters.numPoints,1) * AuxiliaryModule.profit(guess.L_RD);

    # Solve model conditional on L_RD guess
    guessTemp,incumbentHJBSolution = computeFixedPoint_zSzE(algoPar,modelPar,initGuess,0)

    newGuess,W = update_L_RD_w(algoPar,modelPar,guessTemp,incumbentHJBSolution);

    # Aggregate to compute new L_RD
    return newGuess,incumbentHJBSolution,W

end

function computeFixedPoint_L_RD_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::InitialGuess, verbose = 2, print_skip = 10)

    # Error message
    if !(verbose in (0,1,2))
        throw(ArgumentError("verbose should be 0, 1 or 2"))
    end

    # While loop to compute fixed point
    iterate = 0;
    error_L_RD = 1;
    error_w = error_L_RD;

    oldGuess = initGuess;

    while (iterate < algoPar.L_RD.maxIter && error_L_RD > algoPar.L_RD.tolerance) || (iterate < algoPar.w.maxIter && error_w > algoPar.w.tolerance)

        newGuess,incumbentHJBSolution,W = iterate_L_RD_w(algoPar,modelPar,oldGuess);
        iterate += 1;
        error_L_RD = abs(newGuess.L_RD - oldGuess.L_RD);
        error_w = maximum(abs,newGuess.w - oldGuess.w);

        if verbose == 2
            if iterate % print_skip == 0
                println("Compute iterate $iterate with error $error")
            end
        end

        oldGuess = newGuess;

    end

    if verbose >= 1
        if error_L_RD > algoPar.L_RD.tolerance || error_w > algoPar.w.tolerance
            if error_L_RD > algoPar.L_RD.tolerance
                warn("maxIter attained in computeFixedPoint_L_RD_w without L_RD converging")
            end
            if error_w > algoPar.w.tolerance
                warn("maxIter attained in computeFixedPoint_L_RD_w without w converging")
            end
        elseif verbose == 2
            println("Converged in $iterate steps")incumbentHJBSolution
        end
    end

    newGuess,incumbentHJBSolution,W = iterate_L_RD_w(algoPar,modelPar,oldGuess);

    return oldGuess,incumbentHJBSolution,W

end

function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::InitialGuess)

    # Compute high-level fixed point
    return computeFixedPoint_L_RD_w(algoPar,modelPar,initGuess,0)

end

end
