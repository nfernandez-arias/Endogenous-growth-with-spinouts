#---------------------------------
# Name: CalibrationModule.jl
#
# Module containing functions for calibrating the model
#

using LinearAlgebra, Statistics, Optim

export CalibrationTarget,CalibrationParameters,calibrateModel,computeModelMoments,computeScore

struct CalibrationTarget

    value::Float64
    weight::Float64

end


struct CalibrationParameters

    RDintensity::CalibrationTarget
    InternalPatentShare::CalibrationTarget
    EntryRate::CalibrationTarget
    SpinoutShare::CalibrationTarget
    g::CalibrationTarget
    RDLaborAllocation::CalibrationTarget

end

function computeModelMoments(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,incumbentSolution::IncumbentSolution)

    #-----------------------------------#
    # Extract model parameters
    #-----------------------------------#
    ρ = modelPar.ρ
    β = modelPar.β
    L = modelPar.L

    χI = modelPar.χI
    χS = modelPar.χS
    χE = modelPar.χE
    λ = modelPar.λ
    ψI = modelPar.ψI
    ψSE = modelPar.ψSE
    ϕI(z) = z .^(-modelPar.ψI)
    ϕSE(z) = z .^(-modelPar.ψSE)

    ν = modelPar.ν
    ξ = modelPar.ξ
    ζ = modelPar.ζ
    κ = modelPar.κ

    CNC = modelPar.CNC

    sFromS = modelPar.spinoutsFromSpinouts
    sFromE = modelPar.spinoutsFromEntrants

    wbar = Cβ(β)

    #-----------------------------------#name
    # Build mGrid
    #-----------------------------------#
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    #-----------------------------------#
    # Solve model
    #-----------------------------------#

    #results,factor_zS,factor_zE,spinoutFlow = solveModel(algoPar,modelPar,guess)
    results,factor_zS,factor_zE,spinoutFlow = solveModel(algoPar,modelPar,guess,incumbentSolution)


    g = results.finalGuess.g
    L_RD = results.finalGuess.L_RD
    w = results.finalGuess.w
    idxM = results.finalGuess.idxM

    t = results.auxiliary.t
    μ = results.auxiliary.μ
    γ = results.auxiliary.γ


    Π = profit(results.finalGuess.L_RD,modelPar)



    #-----------------------------------#
    # Extract individual policies
    #-----------------------------------#
    V = results.incumbent.V
    zI = results.incumbent.zI
    noncompete = results.incumbent.noncompete

    W = results.spinoutValue


    wageEntrants = sFromE * w + (1-sFromE) * wbar * ones(size(w))
    wageSpinouts = sFromS * w + (1-sFromS) * wbar * ones(size(w))




    zS = zSFunc(algoPar,modelPar,idxM)
    zE = zEFunc(modelPar,results.incumbent,w,zS)

    #-----------------------------------#
    # Extract derived equilibrium variables
    #-----------------------------------#
    τI = τIFunc(modelPar,zI)
    τSE = τSEFunc(modelPar,zI,zS,zE)
    τE = τEFunc(modelPar,zI,zS,zE)
    τS = zeros(size(τE))
    τS = τSE - τE
    τ = τI + τSE
    z = zS + zE + zI
    a = sFromE .* zE .+ sFromS .* zS .+ zI
    finalGoodsLabor = LF(L_RD,modelPar)

    #-----------------------------------#
    # Viewing z as drift a, also compute aPrime
    #-----------------------------------#

    #a = copy(z)
    aPrime = zeros(length(z))

    for i = 1:length(aPrime)-1

        aPrime[i] = (a[i+1] - a[i]) / Δm[i]

    end

    #x = aPrime[end-1]
    #println(aPrime[length(z) - 1])
    #aPrime[end] = aPrime[end-1]

    #-----------------------------------#
    # Calculate entry rates
    #-----------------------------------#

    ## Decompose high type entrants into spinouts from incumbents, spinouts from spinouts, and non-spinouts (i.e. former ordinary entrants)

    mIFrac,mSFrac,mEFrac = spinoutMassDecomposition(algoPar,modelPar,guess,incumbentSolution)


    ## Using the above, calculate entry rates by each group

    if noncompete[1] == 1
        innovationRateIncumbent = τI[1]
        entryRateOrdinary = τE[1]
        entryRateSpinouts = 0
    else
        innovationRateIncumbent = sum(τI .* μ .* Δm)
        entryRateOrdinary = sum(τE .* μ .* Δm)
        entryRateSpinouts = sum(τS .* μ .* Δm)
        entryRateSpinoutsFromIncumbents = sum(mIFrac .* τS .* μ .* Δm)
        entryRateSpinoutsFromSpinouts = sum(mSFrac .* τS .* μ .* Δm)
        entryRateSpinoutsFromEntrants = sum(mEFrac .* τS .* μ .* Δm)
    end

    innovationRateIncumbent = sum(τI .* μ .* Δm)
    entryRateOrdinary = sum(τE .* μ .* Δm)
    entryRateSpinouts = sum(τS .* μ .* Δm)
    entryRate = entryRateOrdinary + entryRateSpinouts

    internalPatentShare = innovationRateIncumbent / (innovationRateIncumbent + entryRate)

    spinoutShare = (entryRateSpinoutsFromIncumbents + entryRateSpinoutsFromSpinouts) / entryRate

    ## Calculate RD intensity for incumbents

    aggregateSales = finalGoodsLabor

    aggregateRDSpendingByIncumbents = sum(w .* zI .* γ .* μ .* Δm)
    aggregateRDSpendingBySpinouts = sum(wageSpinouts .* zS .* γ .* μ .* Δm)
    aggregateRDSpendingByEntrants = sum(wageEntrants .* zE .* γ .* μ .* Δm)

    aggregateRDSpending = aggregateRDSpendingByIncumbents + aggregateRDSpendingBySpinouts + aggregateRDSpendingByEntrants

    RDintensity = aggregateRDSpendingByIncumbents / aggregateSales



    ## Return model moments

    modelMoments = zeros(6)

    modelMoments[1] = RDintensity
    modelMoments[2] = internalPatentShare
    modelMoments[3] = entryRateSpinoutsFromIncumbents + entryRateSpinoutsFromSpinouts
    modelMoments[4] = spinoutShare
    modelMoments[5] = g
    modelMoments[6] = L_RD

    return modelMoments,results

end

function computeScore(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,targets::Vector{Float64},weights::Vector{Float64},incumbentSolution::IncumbentSolution)

    #--------------------------------#
    # Comute model moments
    #--------------------------------#

    # Eventually, would be cool if this could adapt to what fields are in the struct calibPar...

    modelMoments,results = computeModelMoments(algoPar,modelPar,guess,incumbentSolution)

    #-----------------------------------#
    # Modify guesses in place
    #-----------------------------------#

    guess.g = results.finalGuess.g
    guess.L_RD = results.finalGuess.L_RD
    guess.w = results.finalGuess.w
    guess.idxM = results.finalGuess.idxM

    incumbentSolution.V = results.incumbent.V
    incumbentSolution.zI = results.incumbent.zI
    incumbentSolution.noncompete = results.incumbent.noncompete

    #--------------------------------#
    # Compute score
    #--------------------------------#

    score = (modelMoments - targets)' * Diagonal(weights) * (modelMoments - targets)

    return score

end

function calibrateModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,calibPar::CalibrationParameters)

    targets = zeros(length(fieldnames(typeof(calibPar))))
    weights = zeros(length(targets))

    namesVec = fieldnames(typeof(calibPar))

    for i = 1:length(namesVec)

        temp = getfield(calibPar,namesVec[i])
        targets[i] = temp.value
        weights[i] = temp.weight

    end

    # Normalize weights
    weights = weights / sum(weights)

    # Initial incumbent guess
    V = initialGuessIncumbentHJB(algoPar,modelPar,guess)
    zI = zeros(size(V))
    noncompete = zeros(size(V))
    incumbentSolution = IncumbentSolution(V,zI,noncompete)

    #----------------------------------#
    # Calibrate model based on weights
    #----------------------------------#

    # First, define objective function f in format that can
    # be used with ReverseDiff.jl

    function f(x::Array{Float64})

        # Unpack x vector into modelPar struct for inputting into model solver

        #modelPar.ρ = x[1]
        modelPar.χI = x[1]
        modelPar.χS = x[2]
        modelPar.χE = x[3] * x[2]
        modelPar.λ = x[4]
        modelPar.ν = x[5]

        log_file = open("./figures/CalibrationLog.txt","a")

        write(log_file,"Iteration: χI = $(x[1]); χS = $(x[2]); χE = $(x[2] * x[3]); λ = $(x[4]); ν = $(x[5])\n")

        close(log_file)

        output = computeScore(algoPar,modelPar,guess,targets,weights,incumbentSolution)

    end

    # Next, define gradient using ReverseDiff.jl

    #function g!(G,x)

        #G = ReverseDiff.gradient(f,x)
        #ReverseDiff.gradient!(G,f,x)
    #    ForwardDiff.gradient!(G,f,x)

    #end

    # Finally, use Optim.jl to optimize the objective function

    initial_x = [ modelPar.χI,
                  modelPar.χS,
                  modelPar.χE / modelPar.χS,
                  modelPar.λ,
                  modelPar.ν ]

    #x0 = Param(initial_x)

    lower = [1, 1, 0.1, 1.01, 0.008]
    upper = [10, 6, 0.7, 1.12, 0.05]

    #inner_optimizer = GradientDescent()
    inner_optimizer = LBFGS()

    results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(iterations = 1, store_trace = true, show_trace = true))
    #results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer))
    #results = optimize(f,initial_x,inner_optimizer,Optim.Options(iterations = 1, store_trace = true, show_trace = true))
    #results = optimize(f,initial_x,method = inner_optimizer,iterations = 1,store_trace = true, show_trace = false)

    x = results.minimizer

    # UMake some plots and return

    modelPar.ρ = x[1]
    modelPar.χI = x[1]
    modelPar.χS = x[2]
    modelPar.χE = x[3] * x[2]
    modelPar.λ = x[4]
    modelPar.ν = x[5]

    finalMoments = computeModelMoments(algoPar,modelPar,guess)
    finalScore = computeScore(algoPar,modelPar,guess,targets,weights)
    return results,finalMoments,finalScore

    #g = @diff f(x0)

    #println("g is : $([g])")

    #temp = collect(g.list)

    #dump(temp[5],maxdepth = 1)

    #dump(temp[5],maxdepth = 2)

    #gradient = grad(g,x0)

    #println("Gradient at x0 is: $gradient")

end
