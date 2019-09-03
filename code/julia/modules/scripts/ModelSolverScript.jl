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

import Base.deepcopy

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

function update_idxM(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, incumbentHJBSolution::IncumbentSolution)

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
    #println("old_idxM = $old_idxM")
    w = guess.w
    #wE = guess.wE
    wbar = wbarFunc(modelPar.β) * ones(size(w))

    #println("V[1] = $(V[1])")

    # Compute implied zS, zE
    #old_zS = zSFunc(algoPar,modelPar,old_idxM)
    #old_zE = zEFunc(modelPar,incumbentHJBSolution,wE,old_zS)

    #########
    ## Compute new guesses

    wS = (sFromS * w .+ (1-sFromS) * wbar)

    if modelPar.spinoutsSamePool == true

        #temp = modelPar.χS * ϕI(zI + ξ*mGrid) * (modelPar.λ * (1-modelPar.ζ) * V[1]) - wS
        temp = modelPar.χS * ϕI(zI + ξ*mGrid) * (modelPar.λ * (1-modelPar.κ) * V[1]) - wS

    else

        #temp = modelPar.χS * ϕSE(ξ*mGrid) * (modelPar.λ * (1 - modelPar.ζ) * V[1]) - wS
        temp = modelPar.χS * ϕSE(ξ*mGrid) * (modelPar.λ * (1-modelPar.κ)  *  V[1]) - wS

    end

    # Now allowing

    if maximum(temp) >= 0
        idxM = findlast( (temp .>= 0)[:] )
    else
        idxM = 1   # if spinouts should simply not be entering, set idxM = 0
    end

    #factor_zS = χS .* ϕSE(old_zS + old_zE) .* λ .* V[1] ./ wS
    #factor_zE = χE .* ϕSE(old_zS + old_zE) .* λ .* V[1] ./ wS

    idxM = ceil(Int64,algoPar.idxM.updateRate * idxM + (1 - algoPar.idxM.updateRate) * old_idxM)

    #return idxM,factor_zS,factor_zE
    return idxM

end

function update_g_L_RD(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,incumbentHJBSolution::IncumbentSolution)

    ## Build grid
    mGrid,Δm = mGridBuild(algoPar.mGrid);

    g = guess.g
    w = guess.w
    wNC = guess.wNC
    wE = guess.wE
    idxM = guess.idxM
    driftNC = guess.driftNC

    zI = incumbentHJBSolution.zI
    V = incumbentHJBSolution.V
    noncompete = incumbentHJBSolution.noncompete
    idxCNC = findfirst( (noncompete .> 0)[:] )

    zS = zSFunc(algoPar,modelPar,idxM)
    zE = zEFunc(modelPar,incumbentHJBSolution,w,wE,zS)
    τI = τIFunc(modelPar,zI,zS,zE)
    τSE = τSEFunc(modelPar,zI,zS,zE)

    ν = modelPar.ν
    λ = modelPar.λ
    θ = modelPar.θ
    sFromS = modelPar.spinoutsFromSpinouts
    sFromE = modelPar.spinoutsFromEntrants

    μ = zeros(size(mGrid))

    τ = τI .+ τSE

    a = driftNC * ones(size(mGrid)) + (1-θ ) * ν .* (sFromE .* zE .+ sFromS .* zS .+ zI .* (1 .- noncompete))   # No spinouts from zE or from incumbents using non-competes.

    #print("a = $a\n")
    RDlabor = zS .+ zE .+ zI

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

    #----------------------#
    # Compute μ(m)
    #----------------------#

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

    #----------------------#
    # Compute implied L_RD
    #----------------------#

    L_RD = sum(γ .* μ .* RDlabor .* Δm)

    #----------------------#
    # Compute implied g
    #----------------------#

    g = (λ - 1) .* sum(γ .* μ .* τ .* Δm)

    #----------------------#
    # Compute drift due to non-competing spinouts
    #----------------------#

    driftNC = abarFunc(algoPar,modelPar,zI,zS,zE,μ,γ)

    #----------------------#
    # Return output
    #----------------------#

    return g,L_RD,μ,γ,t,driftNC

end

function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::Guess)

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    V = initialGuessIncumbentHJB(algoPar,modelPar,initGuess)
    zI = zeros(size(mGrid))
    noncompete = zeros(size(mGrid))

    incumbentSolution = IncumbentSolution(V,zI,noncompete)

    return solveModel(algoPar,modelPar,initGuess,incumbentSolution)

end


function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::Guess,incumbentSolution::IncumbentSolution)

    ν = modelPar.ν
    ζ = modelPar.ζ
    θ = modelPar.θ
    sFromE = modelPar.spinoutsFromEntrants

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
    wNC = initGuess.wNC
    wE = initGuess.wE
    idxM = initGuess.idxM
    driftNC = initGuess.driftNC

    # Construct new guess object - this will be the object
    # that will be updated throughout the algorithm

    guess = Guess(g,L_RD,w,wNC,wE,idxM,driftNC)

    # Initialize outside of loops for returning
    V = initialGuessIncumbentHJB(algoPar,modelPar,initGuess)
    W = zeros(size(mGrid))
    zI = zeros(size(mGrid))
    noncompete = zeros(size(mGrid))
    γ = zeros(size(mGrid))
    μ = zeros(size(mGrid))
    t = zeros(size(mGrid))


    # Iniital incument solution guess
    sol = incumbentSolution
    sol1 = incumbentSolution

    factor_zE = zeros(size(mGrid))
    factor_zS = zeros(size(mGrid))

    spinoutFlow = zeros(size(mGrid))

    #incumbentHJBSolution = sol



    # In case shit hits the fan

    tempAlgoPar = Base.deepcopy(algoPar)

    tempAlgoPar.incumbentHJB.timeStep = 5
    tempAlgoPar.incumbentHJB.maxIter = 500

    # Diagnostics

    #diagStoreNumPoints = 100

    #w_diag = zeros(length(mGrid),diagStoreNumPoints)
    #V_diag = zeros(length(mGrid),diagStoreNumPoints)
    #noncompete_diag = zeros(length(mGrid),diagStoreNumPoints)
    #W_diag = zeros(length(mGrid),diagStoreNumPoints)
    #μ_diag = zeros(length(mGrid),diagStoreNumPoints)

    #g_diag = zeros(1,diagStoreNumPoints)
    #L_RD_diag = zeros(1,diagStoreNumPoints)


    while (iterate_g_L_RD_w < algoPar.g.maxIter && error_g > algoPar.g.tolerance) || (iterate_g_L_RD_w < algoPar.L_RD.maxIter && error_L_RD > algoPar.L_RD.tolerance) || (iterate_g_L_RD_w < algoPar.w.maxIter && error_w > algoPar.w.tolerance)

        #iterate_g_L_RD_w += 1

        if !(algoPar.idxM_Log.verbose in (0,1,2))
            throw(ArgumentError("algoPar.idxM_Log.verbose should be 0, 1 or 2"))
        end

        #guess.zS = initGuess.zS;g_diag = zeros(1,diagStoreNumPoints)
        #guess.zE = initGuess.zE;

        #anim = Animation()

        cleanGuess = Guess(guess.g,guess.L_RD,guess.w,guess.wNC,guess.wE,guess.idxM,guess.driftNC)

        # Initialize while loop variables
        iterate_idxM = 1
        error_idxM = 1

        while iterate_idxM < algoPar.idxM.maxIter && error_idxM > algoPar.idxM.tolerance

            #y = [guess.zS guess.zE factor_zS factor_zE]
            #x = mGrid[:]
            #Plots.plot(x,y,label=["zS" "zE" "zS factor" "zE factor"])
            #frame(anim)

            #sol = IncumbentSolution(initialGuessIncumbentHJB(algoPar,modelPar,guess),zI,noncompete)

            # Solve HJB - output contains incumbent value V and policy zI

            try

                sol1 = solveIncumbentHJB(algoPar,modelPar,guess,sol)

            catch err
                print("Caught an error: $(typeof(err))\n")
                sol1 = solveIncumbentHJB(tempAlgoPar,modelPar,guess,sol)

            finally

                # Update zS and zE given solution HJB and optimality / free entry conditions

                # Record initial values
                old_idxM = guess.idxM
                zS = zSFunc(algoPar,modelPar,old_idxM)
                zE = zEFunc(modelPar,sol,w,wE,zS)

                # Update guess object (faster than making new one)
                guess.idxM = update_idxM(algoPar,modelPar,guess,sol1)

                # Check convergence
                error_idxM = max(maximum(abs,guess.idxM - old_idxM),maximum(abs,guess.idxM - old_idxM));

                if algoPar.idxM_Log.verbose == 2
                    if iterate_idxM % algoPar.idxM_Log.print_skip == 0
                        println("idxM fixed point: Computed iterate $iterate_idxM with error $error_idxM")
                    end
                end

                # Increase iterator
                iterate_idxM += 1

                sol = sol1

            end

        end

        if algoPar.idxM_Log.verbose >= 1
            if error_idxM > algoPar.idxM.tolerance
                @warn("maxIter attained in zSzE computation")
            elseif algoPar.idxM_Log.verbose == 2
                println("idxM fixed point: Converged in $iterate_idxM steps with error $error_idxM")
            end
        end

        ######## Checking for convergence of L_RD and w

        #### Updating L_RD,w

        ## Updating w

        #print("Type: $(typeof(incumbentHJBSolution))")

        V = sol.V
        zI = sol.zI
        noncompete = sol.noncompete

        # Solve spinout HJB using incumbent HJB
        W,spinoutFlow = solveSpinoutHJB(algoPar,modelPar,guess,sol)

        ## Updating g,L_RD
        temp_g,temp_L_RD,μ,γ,t,driftNC = update_g_L_RD(algoPar,modelPar,guess,sol)

        # Use spinout value to compute implied no-CNC R&D wage
        ν = modelPar.ν
        wbar = wbarFunc(modelPar.β)
        Wcal = WcalFunc(algoPar,modelPar,guess,W,μ,γ)

        # Calculate non-compete wage
        temp_wE = (ones(size(mGrid)) .* wbar) .- (1- θ) * (sFromE * (1-ζ) * ν) * W
        temp_wNC = ones(size(mGrid)) .* (wbar - θ * (1-ζ) * ν * Wcal)
        temp_w = temp_wNC .- (1-θ) * (1-ζ) *  ν .* W

        # Calculate updated w
        wE = algoPar.w.updateRate .* temp_wE .+ (1 .- algoPar.w.updateRate) .* guess.wE
        w = algoPar.w.updateRate .* temp_w .+ (1 .- algoPar.w.updateRate) .* guess.w
        wNC = algoPar.w.updateRate .* temp_wNC .+ (1 .- algoPar.w.updateRate) .* guess.wNC
        g = algoPar.g.updateRate .* temp_g .+ (1 .- algoPar.g.updateRate) .* guess.g
        L_RD = algoPar.L_RD.updateRate .* temp_L_RD .+ (1 .- algoPar.L_RD.updateRate) .* guess.L_RD




        #### Error

        ## Compute error

        #newGuess = Guess(guess.L_RD, guess.w, guess.zS, guess.zE)

        error_g = abs(temp_g - guess.g)
        error_L_RD = abs(temp_L_RD - guess.L_RD)
        error_w = maximum(abs,temp_w .- guess.w)
        error_wE = maximum(abs,temp_wE .- guess.wE)
        error_wNC = maximum(abs,temp_wNC .- guess.wNC)

        ## Log

        if algoPar.g_L_RD_w_Log.verbose == 2
            if iterate_g_L_RD_w % algoPar.g_L_RD_w_Log.print_skip == 0
                println("g,L_RD,w fixed point: Computed iterate $iterate_g_L_RD_w with error: (g, $error_g; L_RD, $error_L_RD; w, $error_w; wE: $error_wE; wNC: $error_wNC)")
            end
        end

        iterate_g_L_RD_w += 1

        #### Update guesses

        guess.g = g
        guess.L_RD = L_RD
        guess.w = w
        guess.wNC = wNC
        guess.wE = wE
        guess.driftNC = driftNC

        #g_diag[1,iterate_g_L_RD_w - 1] = g
        #L_RD_diag[1,iterate_g_L_RD_w - 1] = L_RD

        #w_diag[:,iterate_g_L_RD_w - 1] = w
        #V_diag[:,iterate_g_L_RD_w - 1] = V
        #noncompete_diag[:,iterate_g_L_RD_w - 1] = noncompete
        #W_diag[:,iterate_g_L_RD_w - 1] = W
        #μ_diag[:,iterate_g_L_RD_w - 1] = μ

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

    #return w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,ModelSolution(guess,IncumbentSolution(V,zI,noncompete),W,AuxiliaryEquilibriumVariables(μ,γ,t)),factor_zS,factor_zE,spinoutFlow
    #return w_diag,V_diag,noncompete_diag,W_diag,μ_diag,g_diag,L_RD_diag,ModelSolution(guess,IncumbentSolution(V,zI,noncompete),W,AuxiliaryEquilibriumVariables(μ,γ,t)),factor_zS,factor_zE,spinoutFlow
    return ModelSolution(guess,IncumbentSolution(V,zI,noncompete),W,AuxiliaryEquilibriumVariables(μ,γ,t)),factor_zS,factor_zE,spinoutFlow

end
