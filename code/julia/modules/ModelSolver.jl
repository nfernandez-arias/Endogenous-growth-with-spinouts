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
    V = incumbentHJBSolution.V;
    zI = incumbentHJBSolution.zI;

    ## Update w
    # Load parameters and model constants
    ν = modelPar.ν;
    wbar = AuxiliaryModule.wbar(modelPar.β);

    # First compute W, value of spinout, for computing R&D wage update
    W,spinoutFlow = solveSpinoutHJB(algoPar,modelPar,initGuess,V)
    # Compute new wage
    temp_w = wbar .* ones(size(W)) .- ν .* W;
    w = algoPar.w.updateRate .* temp_w .+ (1 .- algoPar.w.updateRate) .* initGuess.w;

    ## Update L_RD

    # Need to solve KF equation - easy given tau.
    # Then need to aggregate back up to L_RD

    return Guess(initGuess.L_RD, w, initGuess.zS, initGuess.zE),W

end

function update_idxM(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, V::Array{Float64}, W::Array{Float64})

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

    # Some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    #########
    ## Unpack guesses

    old_idxM = guess.idxM
    #println("old_idxM = $old_idxM")
    w = guess.w
    #println("wage = $w")

    #println("V[1] = $(V[1])")

    # Compute implied zS, zE
    old_zS = AuxiliaryModule.zS(algoPar,modelPar,old_idxM)
    old_zE = AuxiliaryModule.zE(modelPar,V[1],w,old_zS)

    #########
    ## Compute new guesses

    temp = modelPar.χS * ϕSE(ξ*mGrid) * modelPar.λ * V[1] - w
    idxM = findlast( (temp .>= 0)[:] )

    #pause(2)

    factor_zS = χS .* ϕSE(old_zS + old_zE) .* λ .* V[1] ./ w
    factor_zE = χE .* ϕSE(old_zS + old_zE) .* λ .* V[1] ./ w

    idxM = ceil(Int64,algoPar.idxM.updateRate * idxM + (1 - algoPar.idxM.updateRate) * old_idxM)

    #println("new idxM = $idxM")

    return idxM,factor_zS,factor_zE

end

function update_g_L_RD(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,incumbentHJBSolution::IncumbentSolution)

    ## Build grid
    mGrid,Δm = mGridBuild(algoPar.mGrid);

    g = guess.g
    w = guess.w
    idxM = guess.idxM

    zI = incumbentHJBSolution.zI
    V = incumbentHJBSolution.V
    noncompete = incumbentHJBSolution.noncompete

    zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)
    zE = AuxiliaryModule.zE(modelPar,V[1],w,zS)

    τI = AuxiliaryModule.τI(modelPar,zI)
    τSE = AuxiliaryModule.τSE(modelPar,zS,zE)

    ν = modelPar.ν
    λ = modelPar.λ

    τ = τI .+ τSE

    a = ν .* (zS .+ zE .+ zI .* (1 .- noncompete))
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

    # Rescale to obtain density
    μ = μ / sum(μ .* Δm)

    #----------------------#
    # Compute γ(m)
    #----------------------#

    # First step: compute t(m), equilibrium time it takes to reach state m

    t = cumsum(Δm[:] ./ a[:])

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
    # Return output
    #----------------------#

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
    iterate_g_L_RD_w = 0
    error_g = 1
    error_L_RD = 1
    error_w = 1

    # Unpack initial guesses

    g = initGuess.g
    L_RD = initGuess.L_RD
    w = initGuess.w
    idxM = initGuess.idxM

    # Construct new guess object - this will be the object
    # that will be updated throughout the algorithm

    guess = Guess(g,L_RD,w,idxM);

    # Initialize outside of loops for returning
    V = zeros(algoPar.mGrid.numPoints,1)
    W = zeros(algoPar.mGrid.numPoints,1)
    zI = zeros(algoPar.mGrid.numPoints,1)
    noncompete = zeros(size(zI))
    γ = zeros(algoPar.mGrid.numPoints,1)
    t = zeros(algoPar.mGrid.numPoints,1)

    factor_zE = zeros(algoPar.mGrid.numPoints,1)
    factor_zS = zeros(algoPar.mGrid.numPoints,1)

    spinoutFlow = zeros(algoPar.mGrid.numPoints,1)

    incumbentHJBSolution = zeros(algoPar.mGrid.numPoints,1)


    # In case shit hits the fan

    tempAlgoPar = Base.deepcopy(algoPar)

    tempAlgoPar.incumbentHJB.timeStep = 2


    while (iterate_g_L_RD_w < algoPar.g.maxIter && error_g > algoPar.g.tolerance) || (iterate_g_L_RD_w < algoPar.L_RD.maxIter && error_L_RD > algoPar.L_RD.tolerance) || (iterate_g_L_RD_w < algoPar.w.maxIter && error_w > algoPar.w.tolerance)

        iterate_g_L_RD_w += 1

        if !(algoPar.idxM_Log.verbose in (0,1,2))
            throw(ArgumentError("algoPar.idxM_Log.verbose should be 0, 1 or 2"))
        end

        #guess.zS = initGuess.zS;
        #guess.zE = initGuess.zE;

        #anim = Animation()

        cleanGuess = Guess(guess.g,guess.L_RD,guess.w,guess.idxM)

        # Initialize while loop variables
        iterate_idxM = 0;
        error_idxM = 1;

        try

            while iterate_idxM < algoPar.idxM.maxIter && error_idxM > algoPar.idxM.tolerance

                #y = [guess.zS guess.zE factor_zS factor_zE]
                #x = mGrid[:]
                #Plots.plot(x,y,label=["zS" "zE" "zS factor" "zE factor"])
                #frame(anim)


                # Solve HJB - output contains incumbent value V and policy zI

                incumbentHJBSolution = solveIncumbentHJB(algoPar,modelPar,guess)

                #println("V = $(incumbentHJBSolution.V)")



                # Update zS and zE given solution HJB and optimality / free entry conditions

                # Record initial values
                old_idxM = guess.idxM

                zS = AuxiliaryModule.zS(algoPar,modelPar,old_idxM)
                zE = AuxiliaryModule.zE(modelPar,incumbentHJBSolution.V,w,zS)

                #println("zS = $zS")
                #println("zE = $zE")


                # Update guess object (faster than allocating new one)500


                guess.idxM,factor_zS,factor_zE = update_idxM(algoPar,modelPar,guess,incumbentHJBSolution.V,W)

                # Increase iterator
                iterate_idxM += 1;
                # Check convergence
                error_idxM = max(maximum(abs,guess.idxM - old_idxM),maximum(abs,guess.idxM - old_idxM));

                if algoPar.idxM_Log.verbose == 2
                    if iterate_idxM % algoPar.idxM_Log.print_skip == 0
                        println("idxM fixed point: Computed iterate $iterate_idxM with error $error_idxM")
                    end
                end

            end

        catch err

            #if isa(err,LinearAlgebra.SingularException)

                println("-----------------Caught an Error!-------------------------")
                #println("Error: $err")
                #println(typeof(err))
                #sleep(2)

                guess = cleanGuess

                # While loop to compute fixed point
                iterate_idxM = 0;
                error_idxM = 1;

                #print("$iterate_zSzE")
                #print("$error_zSzE")

                while iterate_idxM < algoPar.idxM.maxIter && error_idxM > algoPar.idxM.tolerance

                    #y = [guess.zS guess.zE factor_zS factor_zE]
                    #x = mGrid[:]
                    #Plots.plot(x,y,label=["zS" "zE" "zS factor" "zE factor"])
                    #frame(anim)


                    # Solve HJB - output contains incumbent value V and policy zI

                    incumbentHJBSolution = solveIncumbentHJB(tempAlgoPar,modelPar,guess)



                    # Update zS and zE given solution HJB and optimality / free entry conditions

                    # Record initial values
                    old_idxM = guess.idxM

                    # Update guess object (faster than allocating new one)
                    guess.idxM,factor_zS,factor_zE = update_idxM(algoPar,modelPar,guess,incumbentHJBSolution.V,W)

                    # Increase iterator
                    iterate_idxM += 1;
                    # Check convergence
                    error_idxM = maximum(abs,guess.idxM - old_idxM)

                    if algoPar.idxM_Log.verbose == 2
                        if iterate_idxM % algoPar.idxM_Log.print_skip == 0
                            println("idxM fixed point: Computed iterate $iterate_idxM with error $error_idxM")
                        end
                    end

                end

                #algoPar = setAlgorithmParameters()

            #end

        finally

        #gif(anim, "./figures/animation.gif", fps = 15)

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

            # Solve incumbent HJB one more time...
            #incumbentHJBSolution = solveIncumbentHJB(algoPar,modelPar,guess)
            println(typeof(incumbentHJBSolution))

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

            iterate_g_L_RD_w += 1

            if algoPar.g_L_RD_w_Log.verbose == 2
                if iterate_g_L_RD_w % algoPar.g_L_RD_w_Log.print_skip == 0
                    println("g,L_RD,w fixed point: Computed iterate $iterate_g_L_RD_w with error: (g, $error_g; L_RD, $error_L_RD; w, $error_w)")
                end
            end

            #### Update guess        #### Update guess

            guess.g = g
            guess.L_RD = L_RD
            guess.w = w

        end

    end

    #algoPar = setAlgorithmParameters()

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

    return ModelSolution(guess,IncumbentSolution(V,zI,noncompete),W,AuxiliaryEquilibriumVariables(γ,t)),factor_zS,factor_zE,spinoutFlow

end

end
