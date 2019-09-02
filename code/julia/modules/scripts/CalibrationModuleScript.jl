#---------------------------------
# Name: CalibrationModule.jl
#
# Module containing functions for calibrating the model
#

using LinearAlgebra, Statistics, Optim

export CalibrationTarget,ModelMoments,CalibrationParameters,calibrateModel,computeModelMoments,computeScore

struct CalibrationTarget

    value::Float64
    weight::Float64

end


struct CalibrationParameters

    RDintensity::CalibrationTarget
    InternalPatentShare::CalibrationTarget
    SpinoutEntryRate::CalibrationTarget
    SpinoutShare::CalibrationTarget
    g::CalibrationTarget
    RDLaborAllocation::CalibrationTarget
    WageRatio::CalibrationTarget
    SpinoutsNCShare::CalibrationTarget

end

mutable struct ModelMoments

    RDintensity::Float64
    InternalPatentShare::Float64
    SpinoutEntryRate::Float64
    SpinoutShare::Float64
    g::Float64
    RDLaborAllocation::Float64
    WageRatio::Float64
    SpinoutsNCShare::Float64

    ModelMoments() = new()

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

    mIFrac,mSFrac,mEFrac,mI_NC_Frac,mS_NC_Frac = spinoutMassDecomposition(algoPar,modelPar,guess,incumbentSolution,μ,γ,t)


    ## Using the above, calculate entry rates by each group

    innovationRateIncumbent = sum(τI .* μ .* Δm)
    entryRateOrdinary = sum(τE .* μ .* Δm)
    entryRateSpinouts = sum(τS .* μ .* Δm)
    entryRateSpinoutsFromIncumbents = sum(mIFrac .* τS .* μ .* Δm)
    entryRateSpinoutsFromSpinouts = sum(mSFrac .* τS .* μ .* Δm)
    entryRateSpinoutsFromEntrants = sum(mEFrac .* τS .* μ .* Δm)

    entryRateNonCompetingSpinoutsFromIncumbents = sum(mI_NC_Frac .* τS .* μ .* Δm)
    entryRateNonCompetingSpinoutsFromSpinouts = sum(mS_NC_Frac .* τS .* μ .* Δm)

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

    # Average wage of RD employee / average wage of production employee (of same human capital)
    WageRatio = (aggregateRDSpending / L_RD)  / wbar

    # Non-competing spinouts share of spinout entry (i.e. successful innovations)

    SpinoutsNCShare = (entryRateNonCompetingSpinoutsFromIncumbents +entryRateNonCompetingSpinoutsFromSpinouts) / entryRateSpinouts



    ## Return model moments

    modelMoments = ModelMoments()

    modelMoments.RDintensity  = RDintensity
    modelMoments.InternalPatentShare = internalPatentShare
    modelMoments.SpinoutEntryRate = entryRateSpinoutsFromIncumbents + entryRateSpinoutsFromSpinouts
    modelMoments.SpinoutShare = spinoutShare
    modelMoments.g = g
    modelMoments.RDLaborAllocation = L_RD
    modelMoments.WageRatio = WageRatio
    modelMoments.SpinoutsNCShare = SpinoutsNCShare

    return modelMoments,results

end

function computeScore(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,calibPar::CalibrationParameters,targets::Array{Float64},weights::Array{Float64},incumbentSolution::IncumbentSolution)

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
    guess.wNC = results.finalGuess.wNC
    guess.wE = results.finalGuess.wE
    guess.idxM = results.finalGuess.idxM
    guess.driftNC = results.finalGuess.driftNC

    incumbentSolution.V = results.incumbent.V
    incumbentSolution.zI = results.incumbent.zI
    incumbentSolution.noncompete = results.incumbent.noncompete

    #--------------------------------#
    # Compute score
    #--------------------------------#

    modelMomentsVec = zeros(length(fieldnames(typeof(modelMoments))),1)

    modelMomentsVec[1] = modelMoments.RDintensity
    modelMomentsVec[2] = modelMoments.InternalPatentShare
    modelMomentsVec[3] = modelMoments.SpinoutEntryRate
    modelMomentsVec[4] = modelMoments.SpinoutShare
    modelMomentsVec[5] = modelMoments.g
    modelMomentsVec[6] = modelMoments.RDLaborAllocation
    modelMomentsVec[7] = modelMoments.WageRatio
    modelMomentsVec[8] = modelMoments.SpinoutsNCShare

    # divide error by target moment -- "unit free" errors. Weights can then reflect purely imoportance of the moment.
    score = ((modelMomentsVec - targets)./targets)' * Diagonal(weights) * ((modelMomentsVec - targets)./targets)

    return score[1]

end

function calibrateModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,calibPar::CalibrationParameters)

    # Initial incumbent guess
    V = initialGuessIncumbentHJB(algoPar,modelPar,guess)
    zI = zeros(size(V))
    noncompete = zeros(size(V))
    incumbentSolution = IncumbentSolution(V,zI,noncompete)

    targets = zeros(length(fieldnames(typeof(calibPar))),1)
    weights = zeros(size(targets))

    for (i,field) = enumerate(fieldnames(typeof(calibPar)))

        temp = getfield(calibPar,field)

        targets[i] = temp.value
        weights[i] = temp.weight

    end

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
        modelPar.ζ = x[6]
        modelPar.κ = x[7]
        modelPar.spinoutsFromSpinouts = x[8]
        modelPar.spinoutsFromEntrants = x[9]
        modelPar.θ = x[10]

        log_file = open("./figures/CalibrationLog.txt","a")

        write(log_file,"Iteration: χI = $(x[1]); χS = $(x[2]); χE = $(x[2] * x[3]); λ = $(x[4]); ν = $(x[5])\n; ζ = $(x[6]); κ = $(x[7]); sFromS = $(x[8]); sFromE = $(x[9])\n; θ = $(x[10])\n")

        close(log_file)

        output = computeScore(algoPar,modelPar,guess,calibPar,targets,weights,incumbentSolution)

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
                  modelPar.ν,
                  modelPar.ζ,
                  modelPar.κ,
                  modelPar.spinoutsFromSpinouts,
                  modelPar.spinoutsFromEntrants,
                  modelPar.θ ]


    lower = [1, 1, 0.1, 1.01, 0.008, 0, 0, 0.05, 0.05, 0.05]
    upper = [10, 6, 0.9, 1.12, 0.05, 1, 0.8, 1, 1, 0.95]

    #inner_optimizer = GradientDescent()
    inner_optimizer = LBFGS()


    calibrationResults = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(iterations = 1, store_trace = true, show_trace = true))
    #results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer))
    #results = optimize(f,initial_x,inner_optimizer,Optim.Options(iterations = 1, store_trace = true, show_trace = true))
    #results = optimize(f,initial_x,method = inner_optimizer,iterations = 1,store_trace = true, show_trace = false)

    x = calibrationResults.minimizer

    # UMake some plots and return

    modelPar.χI = x[1]
    modelPar.χS = x[2]
    modelPar.χE = x[3] * x[2]
    modelPar.λ = x[4]
    modelPar.ν = x[5]
    modelPar.ζ = x[6]
    modelPar.κ = x[7]
    modelPar.spinoutsFromSpinouts = x[8]
    modelPar.spinoutsFromEntrants = x[9]

    modelSolution,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,guess)

    finalMoments,finalResults = computeModelMoments(algoPar,modelPar,guess,modelSolution.incumbent)

    finalScore = computeScore(algoPar,modelPar,guess,calibPar,targets,weights,modelSolution.incumbent)
    return calibrationResults,finalMoments,finalResults,finalScore

    #g = @diff f(x0)

    #println("g is : $([g])")

    #temp = collect(g.list)

    #dump(temp[5],maxdepth = 1)

    #dump(temp[5],maxdepth = 2)

    #gradient = grad(g,x0)

    #println("Gradient at x0 is: $gradient")

end
