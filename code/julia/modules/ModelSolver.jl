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

using AlgorithmParametersModule, ModelParametersModule, GuessModule, HJBModule, InitializationModule
#using Plots, GR
import AuxiliaryModule,Base.deepcopy

export solveModel,ModelSolution,AuxiliaryEquilibriumVariables

struct AuxiliaryEquilibriumVariables

    μ::Array{Float64}
    γ::Array{Float64}
    t::Array{Float64}

end

struct ModelSolution

    finalGuess::Guess
    incumbent::IncumbentSolution
    spinoutValue::Array{Float64}
    auxiliary::AuxiliaryEquilibriumVariables

end

function update_L_RD_w(algoPar::AlgorithmParameters, modelPar::ModelParameters, initGuess::Guess, incumbentHJBSolution::IncumbentSolution)

    # Unpack incumbentHJBSolution
    V = incumbentHJBSolution.V
    zI = incumbentHJBSolution.zI

    ## Update w
    # Load parameters and model constants
    ν = modelPar.ν
    wbar = AuxiliaryModule.wbar(modelPar.β)

    # First compute W, value of spinout, for computing R&D wage update
    W,spinoutFlow = solveSpinoutHJB(algoPar,modelPar,initGuess,V)
    # Compute new wage
    temp_w = wbar .* ones(size(W)) .- ν .* W
    w = algoPar.w.updateRate .* temp_w .+ (1 .- algoPar.w.updateRate) .* initGuess.w

    ## Update L_RD

    # Need to solve KF equation - easy given tau.
    # Then need to aggregate back up to L_RD

    return Guess(initGuess.L_RD, w, initGuess.zS, initGuess.zE),W

end

function update_idxM_zE(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, incumbentHJBSolution::IncumbentSolution, W::Array{Float64})

    ## Build grid
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    ## Unpack modelPar

    # General
    ρ = modelPar.ρ
    β = modelPar.β
    L = modelPar.L

    # Innovation
    χI = modelPar.χI
    χS = modelPar.χS
    χE = modelPar.χE
    ψI = modelPar.ψI
    ψSE = modelPar.ψSE
    λ = modelPar.λ

    # Spinouts
    ν = modelPar.ν
    ξ = modelPar.ξ
    sFromS = modelPar.spinoutsFromSpinouts

    # Some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    #########
    ## Unpack incumbent HJB solution
    V = incumbentHJBSolution.V
    zI = incumbentHJBSolution.zI

    ## Unpack guesses

    old_idxM = guess.idxM
    old_zE = guess.zE

    w = guess.w
    wbar = AuxiliaryModule.wbar(modelPar.β) * ones(size(w))

    #########
    ## Compute new guesses

    wS = (sFromS * w .+ (1-sFromS) * wbar)

    temp = modelPar.χS * ϕI(zI + ξ*mGrid) * (modelPar.λ * V[1] - modelPar.ζ) - wS

    # Now allowing

    if maximum(temp) >= 0
        idxM = findlast( (temp .>= 0)[:] )
    else
        idxM = 1   # if spinouts should simply not be entering, set idxM = 0
    end

    #factor_zS = χS .* ϕSE(old_zS + old_zE) .* λ .* V[1] ./ wS
    #factor_zE = χE .* ϕSE(old_zS + old_zE) .* λ .* V[1] ./ wS

    idxM = ceil(Int64,algoPar.idxM.updateRate * idxM + (1 - algoPar.idxM.updateRate) * old_idxM)

    zE = old_zE * (algoPar.zE.updateRate *  ( (χE * λ * V[1]) / wbar[1] ) + (1 - algoPar.zE.updateRate) )

    #return idxM,factor_zS,factor_zE
    return idxM,zE

end

function update_g_L_RD(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,incumbentHJBSolution::IncumbentSolution)

    ## Build grid
    mGrid,Δm = mGridBuild(algoPar.mGrid);

    g = guess.g
    w = guess.w
    idxM = guess.idxM
    zE = guess.zE

    zI = incumbentHJBSolution.zI
    V = incumbentHJBSolution.V
    noncompete = incumbentHJBSolution.noncompete
    idxCNC = findfirst( (noncompete .> 0)[:] )

    zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)
    τI = AuxiliaryModule.τI(modelPar,zI,zS)
    τSE = AuxiliaryModule.τSE(modelPar,zI,zS,zE)

    ν = modelPar.ν
    λ = modelPar.λ
    sFromS = modelPar.spinoutsFromSpinouts

    μ = zeros(size(mGrid))

    τ = τI .+ τSE

    a = ν .* (sFromS .* zS .+ zI .* (1 .- noncompete))   # No spinouts from zE or from incumbents using non-competes.

    #print("a = $a\n")
    RDlabor = zS .+ zE * ones(size(zS)) .+ zI

    if noncompete[1] == 1

        L_RD = zI[1] + zE
        g = (λ - 1) * τ[1]
        γ = zeros(1,1)
        t = zeros(1,1)

        μ[1] = 1/Δm[1]
        μ[2:end] .= 0

    else

        #----------------------#
        # Solve KF equation
        #----------------------#

        # Compute derivative of a for calculating stationary distribution
        aPrime = zeros(size(a))
        for i = 1:length(aPrime)-1

            aPrime[i] = (a[i+1] - a[i]) / Δm[i]

        end
        aPrime[end] = aPrime[end-1]

        # Integrate ODE to compute shape of μ
        integrand =  (aPrime .+ τ) ./ a
        summand = integrand .* Δm
        integral = cumsum(summand[:])
        μ = exp.(-integral)

        #print("a: $(a[1:10])\n")
        #print("aPrime: $(aPrime[1:10])\n")
        #print("Integrand: $(integrand[1:10])\n")
        #print("Summand: $(summand[1:10])\n")
        #print("Integral: $(integral[1:10])\n")
        #print("μ: $(μ[1:10])\n")

        #println("type of variable idxCNC: $(typeof(idxCNC))")

        #println("Noncompetes used? $(maximum(noncompete))")

        if sFromS == 0

            #----------------------#
            # Compute μ(m)
            #----------------------#

            if maximum(noncompete) > 0

                # Compute mass at mass point (divided by Δm there)
                # This allow a "density" to encode a mass point.
                μ[idxCNC] = (μ[idxCNC] / τ[idxCNC])/ Δm[idxCNC]
                μ[idxCNC+1:end] .= 0

                #a[idxCNC:end] .= 0

                # Rescale to obtain density
                μ = μ / sum(μ .* Δm)

            else

                μ = μ / sum(μ .* Δm)

            end

            #----------------------#
            # Compute γ(m)
            #----------------------#

            # First step: compute t(m), equilibrium time it takes to reach state m

            t = zeros(size(mGrid))
            t[2:end] = cumsum(Δm[1:end-1] ./ a[1:end-1])

            # Next step: compute shape of γ(m)

            γShape = exp.(- guess.g .* t)

            # Take into account mass point:

            if maximum(noncompete) == 1
                γShape[idxCNC] = γShape[idxCNC] * τ[idxCNC] / (g + τ[idxCNC])
            end

            # Compute C_gamma

            γScale = sum(γShape .* μ .* Δm)^(-1)

            # Finally compute γ

            γ = γScale * γShape

        else

            μ = μ / sum(μ .* Δm)

            #----------------------#
            # Compute γ(m)
            #----------------------#

            # First step: compute t(m), equilibrium time it takes to reach state m

            t = zeros(size(mGrid))
            t[2:end] = cumsum(Δm[1:end-1] ./ a[1:end-1])

            # Next step: compute shape of γ(m)

            γShape = exp.(- guess.g .* t)

            # Compute C_gamma

            γScale = sum(γShape .* μ .* Δm)^(-1)

            # Finally compute γ

            γ = γScale * γShape

        end

        #----------------------#
        # Compute implied L_RD
        #----------------------#

        L_RD = sum(γ .* μ .* RDlabor .* Δm)

        #----------------------#
        # Compute implied g
        #----------------------#

        g = (λ - 1) .* sum(γ .* μ .* τ .* Δm)

        #----------------------#
        # Return output
        #----------------------#

    end

    return g,L_RD,μ,γ,t

end


function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::Guess)

    # For plotting - use GR backend
    #gr()

    # Error message
    if !(algoPar.g_L_RD_w_Log.verbose in (0,1,2))
        throw(ArgumentError("verbose should be 0, 1 or 2"))
    end

    # Construct grid - useful for making plots
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # While loop to compute fixed point
    iterate_g_L_RD_w = 1
    error_g = 1
    error_L_RD = 1
    error_w = 1

    # Unpack initial guesses

    g = initGuess.g
    L_RD = initGuess.L_RD
    w = initGuess.w
    idxM = initGuess.idxM
    zE = initGuess.zE

    # Construct new guess object - this will be the object
    # that will be updated throughout the algorithm

    guess = Guess(g,L_RD,w,idxM,zE);

    # Initialize outside of loops for returning
    V = AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,initGuess)
    W = zeros(size(mGrid))
    zI = zeros(size(mGrid))
    noncompete = zeros(size(mGrid))
    γ = zeros(size(mGrid))
    μ = zeros(size(mGrid))
    t = zeros(size(mGrid))


    # Iniital guess
    sol = IncumbentSolution(V,zI,noncompete)


    factor_zE = zeros(size(mGrid))
    factor_zS = zeros(size(mGrid))

    spinoutFlow = zeros(size(mGrid))

    incumbentHJBSolution = zeros(size(mGrid))

    # In case shit hits the fan

    tempAlgoPar = Base.deepcopy(algoPar)

    tempAlgoPar.incumbentHJB.timeStep = 1
    #tempAlgoPar.incumbentHJB.maxIter = 500

    # Diagnostics

    diagStoreNumPoints = 1

    w_diag = zeros(length(mGrid),diagStoreNumPoints)
    V_diag = zeros(length(mGrid),diagStoreNumPoints)
    W_diag = zeros(length(mGrid),diagStoreNumPoints)
    μ_diag = zeros(length(mGrid),diagStoreNumPoints)

    g_diag = zeros(1,diagStoreNumPoints)
    L_RD_diag = zeros(1,diagStoreNumPoints)


    while (iterate_g_L_RD_w < algoPar.g.maxIter && error_g > algoPar.g.tolerance) || (iterate_g_L_RD_w < algoPar.L_RD.maxIter && error_L_RD > algoPar.L_RD.tolerance) || (iterate_g_L_RD_w < algoPar.w.maxIter && error_w > algoPar.w.tolerance)

        #iterate_g_L_RD_w += 1

        if !(algoPar.idxM_zE_Log.verbose in (0,1,2))
            throw(ArgumentError("algoPar.idxM_zE_Log.verbose should be 0, 1 or 2"))
        end

        #guess.zS = initGuess.zS;g_diag = zeros(1,diagStoreNumPoints)
        #guess.zE = initGuess.zE;

        #anim = Animation()

        cleanGuess = Guess(guess.g,guess.L_RD,guess.w,guess.idxM,guess.zE)

        # Initialize while loop variables
        iterate_idxM = 0
        error_idxM = 1

        iterate_zE = 0
        error_zE = 1

        try

            while (iterate_idxM < algoPar.idxM.maxIter && error_idxM > algoPar.idxM.tolerance) | (iterate_zE < algoPar.zE.maxIter && error_zE > algoPar.zE.tolerance)

                #y = [guess.zS guess.zE factor_zS factor_zE]
                #x = mGrid[:]
                #Plots.plot(x,y,label=["zS" "zE" "zS factor" "zE factor"])
                #frame(anim)

                #sol = IncumbentSolution(AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,guess),zI,noncompete)
                sol = IncumbentSolution(V,zI,noncompete)

                # Solve HJB - output contains incumbent value V and policy zI

                incumbentHJBSolution = solveIncumbentHJB(algoPar,modelPar,guess,sol)

                # Update zS and zE given solution HJB and optimality / free entry conditions

                # Record initial values
                old_idxM = guess.idxM

                zS = AuxiliaryModule.zS(algoPar,modelPar,old_idxM)
                #zE = AuxiliaryModule.zE(modelPar,incumbentHJBSolution,w,zS)

                #println("zS = $zS")
                #println("zE = $zE")


                # Update guess object (faster than making new one)
                guess.idxM, guess.zE = update_idxM_zE(algoPar,modelPar,guess,incumbentHJBSolution,W)

                # Increase iterator
                iterate_idxM += 1;
                # Check convergence
                error_idxM = max(maximum(abs,guess.idxM - old_idxM),maximum(abs,guess.idxM - old_idxM));

                if algoPar.idxM_zE_Log.verbose == 2
                    if iterate_idxM % algoPar.idxM_zE_Log.print_skip == 0
                        println("idxM fixed point: Computed iterate $iterate_idxM with error: (idxM, $error_idxM; zE, $error_zE)")
                    end
                end

            end

        catch err

            println("-----------------Caught an Error!-------------------------")
            #println("Error: $err")
            println(typeof(err))
            #sleep(2)

            guess = cleanGuess

            # While loop to compute fixed point
            iterate_idxM = 0
            error_idxM = 1

            iterate_zE = 0
            error_zE = 1

            #print("$iterate_zSzE")
            #print("$error_zSzE")

            while (iterate_idxM < tempAlgoPar.idxM.maxIter && error_idxM > tempAlgoPar.idxM.tolerance) | (iterate_zE < algoPar.zE.maxIter && error_zE > algoPar.zE.tolerance)

                #y = [guess.zS guess.zE factor_zS factor_zE]
                #x = mGrid[:]
                #Plots.plot(x,y,label=["zS" "zE" "zS factor" "zE factor"])
                #frame(anim)

                #sol = IncumbentSolution(AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,guess),zI,noncompete)
                sol = IncumbentSolution(V,zI,noncompete)

                # Solve HJB - output contains incumbent value V and policy zI

                incumbentHJBSolution = solveIncumbentHJB(tempAlgoPar,modelPar,guess,sol)

                # Update zS and zE given solution HJB and optimality / free entry conditions

                # Record initial values
                old_idxM = guess.idxM
                old_zE = guess.zE

                #println("V = $(incumbentHJBSolution.V)")
                #println("w = $(guess.w)")

                # Update guess object (faster than allocating new one)
                guess.idxM,guess.zE = update_idxM_zE(tempAlgoPar,modelPar,guess,incumbentHJBSolution,W)

                # Increase iterator
                iterate_idxM += 1
                # Check convergence
                error_idxM = maximum(abs,guess.idxM - old_idxM)

                iterate_zE += 1
                error_zE = abs(guess.zE - old_zE)

                if algoPar.idxM_zE_Log.verbose == 2
                    if iterate_idxM % tempAlgoPar.idxM_zE_Log.print_skip == 0
                        println("idxM,zE fixed point: Computed iterate $iterate_idxM with error: (idxM, $error_idxM; zE, $error_zE)")
                    end
                end

            end

        finally

        #gif(anim, "./figures/animation.gif", fps = 15)

            if algoPar.idxM_zE_Log.verbose >= 1
                if error_idxM > algoPar.idxM.tolerance
                    @warn("TWO ERRORS -- OR, maxIter attained in zSzE computation")
                elseif algoPar.idxM_zE_Log.verbose == 2
                    println("idxM,zE fixed point: Converged in $iterate_idxM steps with error: (idxM, $error_idxM; zE, $error_zE)")
                end
            end

            ######## Checking for convergence of L_RD and w

            #### Updating L_RD,w

            ## Updating w

            #print("Type: $(typeof(incumbentHJBSolution))")

            V = incumbentHJBSolution.V
            zI = incumbentHJBSolution.zI
            noncompete = incumbentHJBSolution.noncompete

            # Solve spinout HJB using incumbent HJB
            W,spinoutFlow = solveSpinoutHJB(algoPar,modelPar,guess,incumbentHJBSolution)

            # Use spinout value to compute implied no-CNC R&D wage
            ν = modelPar.ν
            wbar = AuxiliaryModule.wbar(modelPar.β)
            temp_w = wbar .* ones(size(W)) .- ν .* W

            # Calculate updated w
            w = algoPar.w.updateRate .* temp_w .+ (1 .- algoPar.w.updateRate) .* guess.w

            ## Updating g,L_RD
            temp_g,temp_L_RD,μ,γ,t = update_g_L_RD(algoPar,modelPar,guess,incumbentHJBSolution)

            g = algoPar.g.updateRate .* temp_g .+ (1 .- algoPar.g.updateRate) .* guess.g
            L_RD = algoPar.L_RD.updateRate .* temp_L_RD .+ (1 .- algoPar.L_RD.updateRate) .* guess.L_RD

            #### Error

            ## Compute error

            #newGuess = Guess(guess.L_RD, guess.w, guess.zS, guess.zE)

            error_g = abs(temp_g - guess.g)
            error_L_RD = abs(temp_L_RD - guess.L_RD)
            error_w = maximum(abs,temp_w .- guess.w)

            ## Log

            if algoPar.g_L_RD_w_Log.verbose == 2
                if iterate_g_L_RD_w % algoPar.g_L_RD_w_Log.print_skip == 0
                    println("g,L_RD,w fixed point: Computed iterate $iterate_g_L_RD_w with error: (g, $error_g; L_RD, $error_L_RD; w, $error_w)")
                end
            end

            iterate_g_L_RD_w += 1

            #### Update guess        #### Update guess

            guess.g = g
            guess.L_RD = L_RD
            guess.w = w

            g_diag[1,iterate_g_L_RD_w - 1] = g
            L_RD_diag[1,iterate_g_L_RD_w - 1] = L_RD

            w_diag[:,iterate_g_L_RD_w - 1] = w
            V_diag[:,iterate_g_L_RD_w - 1] = V
            W_diag[:,iterate_g_L_RD_w - 1] = W
            μ_diag[:,iterate_g_L_RD_w - 1] = μ

        end

    end

    ### Log some stuff when algorithm ends

    if algoPar.g_L_RD_w_Log.verbose >= 1
        if (error_g > algoPar.g.tolerance) || (error_L_RD > algoPar.L_RD.tolerance) || (error_w > algoPar.w.tolerance)
            if error_g > algoPar.g.tolerance
                @warn("maxIter attained in (g,L_RD,w) fixed point without g converging")
                println("Final Error: (g, $error_g; L_RD, $error_L_RD; w, $error_w)")
                println("g error minus tolerance is $(error_g - algoPar.g.tolerance)")
                println("g max iter equals $(algoPar.g.maxIter)")
            end
            if error_L_RD > algoPar.L_RD.tolerance
                @warn("maxIter attained in (g,L_RD,w) fixed point without L_RD converging")
                println("Final Error: (g, $error_g; L_RD, $error_L_RD; w, $error_w)")
            end
            if error_w > algoPar.w.tolerance
                @warn("maxIter attained in (g,L_RD,w) fixed point without w converging")
                println("Final Error: (g, $error_g; L_RD, $error_L_RD; w, $error_w)")
            end
        elseif algoPar.g_L_RD_w_Log.verbose == 2
            println("g,L_RD,w fixed point: Converged in $iterate_g_L_RD_w steps")
            println("Final Error: (g, $error_g; L_RD, $error_L_RD; w, $error_w)")
        end
    end

    return w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,ModelSolution(guess,IncumbentSolution(V,zI,noncompete),W,AuxiliaryEquilibriumVariables(μ,γ,t)),factor_zS,factor_zE,spinoutFlow

end

end
