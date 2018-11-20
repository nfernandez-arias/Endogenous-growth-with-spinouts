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
# ModelSolution composite type

__precompile__()

module ModelSolver

using AlgorithmParametersModule, ModelParametersModule, GuessModule, HJBModule
import AuxiliaryModule

export solveModel, solveModel2

struct ModelSolution

    finalGuess::Guess
    incumbent::IncumbentSolution
    spinoutValue::Array{Float64}

end

function update_L_RD_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::Guess, incumbentHJBSolution::IncumbentSolution)

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

    return Guess(initGuess.L_RD, w, initGuess.zS, initGuess.zE),W

end

function update_zSzE(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, V::Array{Float64})

    ## Build grid
    mGrid,Δm = mGridBuild(algoPar.mGrid);

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
    old_zS = guess.zS;
    old_zE = guess.zE;
    w = guess.w;

    ## Compute new guesses
    temp_zS = min.(ξ .* mGrid, old_zS .* (χS .* ϕSE(old_zS + old_zE) * V[1]) ./ w);
    temp_zE = old_zE .* (χE * ϕSE(old_zS + old_zE) * V[1] ./ w)

    #factor_zE = (χE * ϕSE(old_zS + old_zE) * V[1] ./ w)
    #println("factor_zE[1] is equal to $(factor_zE[1])")
    #println("factor_zE[100] is equal to $(factor_zE[100])")
    #println("factor_zE[200] is equal to $(factor_zE[200])")

    #factor_zS = (χS .* ϕSE(old_zS + old_zE) * V[1]) ./ w
    #println("factor_zS[1] is equal to $(factor_zS[1])")
    #println("factor_zS[100] is equal to $(factor_zS[100])")
    #println("factor_zS[200] is equal to $(factor_zS[200])")

    ## Update
    zS = temp_zS * algoPar.zSzE.updateRate + old_zS * (1 - algoPar.zSzE.updateRate);
    zE = temp_zE * algoPar.zSzE.updateRate + old_zE * (1 - algoPar.zSzE.updateRate);

    ## Return output

    #return Guess(guess.L_RD, guess.w, zS, zE)

    return zS,zE

end

function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::Guess)

    # Error message
    if !(algoPar.L_RD_w_Log.verbose in (0,1,2))
        throw(ArgumentError("verbose should be 0, 1 or 2"))
    end

    # While loop to compute fixed point
    iterate_L_RD_w = 0;
    error_L_RD = 1;
    error_w = error_L_RD;

    guess = initGuess;

    # Initialize outside of loops for returning
    V = zeros(algoPar.mGrid.numPoints,1)
    W = V
    zI = V

    while (iterate_L_RD_w < algoPar.L_RD.maxIter && error_L_RD > algoPar.L_RD.tolerance) || (iterate_L_RD_w < algoPar.w.maxIter && error_w > algoPar.w.tolerance)

        iterate_L_RD_w += 1;

        if !(algoPar.zSzE_Log.verbose in (0,1,2))
            throw(ArgumentError("algoPar.zSzE_Log.verbose should be 0, 1 or 2"))
        end

        # While loop to compute fixed point
        iterate_zSzE = 0;
        error_zSzE = 1;

        guess.zS = initGuess.zS;
        guess.zE = initGuess.zE;

        while iterate_zSzE < algoPar.zSzE.maxIter && error_zSzE > algoPar.zSzE.tolerance

            iterate_zSzE += 1;

            # Solve HJB
            incumbentHJBSolution = solveIncumbentHJB(algoPar,modelPar,guess)
            # Update zS and zE given solution HJB and optimality / free entry conditions

            # Constructing new Guess object each time...maybe this is suboptimal
            #newGuess = update_zSzE(algoPar,modelPar,guess,incumbentHJBSolution.V)

            old_zS = guess.zS
            old_zE = guess.zE

            guess.zS,guess.zE = update_zSzE(algoPar,modelPar,guess,incumbentHJBSolution.V)

            #sleep(5)
            iterate_zSzE += 1;
            # Check convergence
            error_zSzE = max(maximum(abs,guess.zS - old_zS),maximum(abs,guess.zE - old_zE));

            if algoPar.zSzE_Log.verbose == 2
                if iterate_zSzE % algoPar.zSzE_Log.print_skip == 0
                    println("Compute iterate $iterate_zSzE with error $error_zSzE")
                end
            end

            #guess = newGuess;

        end

        if algoPar.zSzE_Log.verbose >= 1
            if error_zSzE > algoPar.zSzE.tolerance
                @warn("maxIter attained in zSzE computation noooo!")
            elseif algoPar.zSzE_Log.verbose == 2
                println("zSzE fixed point: converged in $iterate_zSzE steps")
            end
        end

        ######## Checking for convergence of L_RD and w

        #### Updating L_RD,w

        ## Updating w

        # Solve incumbent HJB one more time...
        incumbentHJBSolution = solveIncumbentHJB(algoPar,modelPar,guess)
        V = incumbentHJBSolution.V
        zI = incumbentHJBSolution.zI

        # Solve spinout HJB using incumbent HJB
        W = solveSpinoutHJB(algoPar,modelPar,guess,V)

        # Use spinout value to compute implied R&D wage
        ν = modelPar.ν;
        wbar = AuxiliaryModule.wbar(modelPar.β);
        temp_w = wbar * ones(size(W)) - ν * W;
        w = algoPar.w.updateRate * temp_w + (1 - algoPar.w.updateRate) * guess.w;

        ## Updating L_RD

        # Solve KF equation






        # Aggregate up to compute implied L_RD


        #### Error

        ## Compute error

        #newGuess = Guess(guess.L_RD, guess.w, guess.zS, guess.zE)

        #error_L_RD = abs(newGuess.L_RD - guess.L_RD);
        #error_w = maximum(abs,newGuess.w - guess.w);

        ## Log

        if algoPar.L_RD_w_Log.verbose == 2
            if iterate_L_RD_w % algoPar.L_RD_w_Log.print_skip == 0
                println("Compute iterate $iterate_L_RD_w with error: (L_RD, $error_L_RD; w, $error_w")
            end
        end

        #### Update guess

        guess.L_RD = initGuess.L_RD
        guess.w = w

    end

    ### Log some stuff when algorithm ends

    if algoPar.L_RD_w_Log.verbose >= 1
        if error_L_RD > algoPar.L_RD.tolerance || error_w > algoPar.w.tolerance
            if error_L_RD > algoPar.L_RD.tolerance
                @warn("maxIter attained in computeFixedPoint_L_RD_w without L_RD converging")
            end
            if error_w > algoPar.w.tolerance
                @warn("maxIter attained in computeFixedPoint_L_RD_w without w converging")
            end
        elseif algoPar.L_RD_w_Log.verbose == 2
            println("Converged in $iterate_L_RD_w steps")
        end
    end

    return ModelSolution(guess,IncumbentSolution(V,zI),W)


end

end
