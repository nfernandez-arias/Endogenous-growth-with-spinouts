#---------------------------------
# Name: CalibrationModule.jl
#
# Module containing functions for calibrating the model
#

__precompile__()

module CalibrationModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule, ModelSolver, AuxiliaryModule
using LinearAlgebra, Statistics, Compat, Optim, ForwardDiff, ReverseDiff

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

function computeModelMoments(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess)

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

    wbar = AuxiliaryModule.Cβ(β)

    #-----------------------------------#
    # Build mGrid
    #-----------------------------------#
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    #-----------------------------------#
    # Solve model
    #-----------------------------------#

    results,factor_zS,factor_zE,spinoutFlow = solveModel(algoPar,modelPar,guess)

    #-----------------------------------#
    # Extract aggregate equilibrium variables
    #-----------------------------------#
    g = results.finalGuess.g
    L_RD = results.finalGuess.L_RD
    w = results.finalGuess.w
    zS = results.finalGuess.zS
    zE = results.finalGuess.zE

    #-----------------------------------#
    # Modify guess in place...will this work? we'll see..
    #-----------------------------------#

    guess.g = g
    guess.L_RD = L_RD
    guess.w = w
    guess.zS = zS
    guess.zE = zE

    γ = results.auxiliary.γ
    t = results.auxiliary.t

    Π = AuxiliaryModule.profit(results.finalGuess.L_RD,modelPar)

    #-----------------------------------#
    # Extract individual policies
    #-----------------------------------#
    V = results.incumbent.V
    zI = results.incumbent.zI
    W = results.spinoutValue

    #-----------------------------------#
    # Extract derived equilibrium variables
    #-----------------------------------#
    τI = AuxiliaryModule.τI(modelPar,zI)
    τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
    τE = AuxiliaryModule.τE(modelPar,zS,zE)
    τS = zeros(size(τE))
    τS = τSE - τE
    τ = τI + τSE
    z = zS + zE + zI
    finalGoodsLabor = AuxiliaryModule.LF(L_RD,modelPar)

    #-----------------------------------#
    # Viewing z as drift a, also compute aPrime
    #-----------------------------------#

    #a = copy(z)
    aPrime = zeros(length(z))

    for i = 1:length(aPrime)-1

        aPrime[i] = (z[i+1] - z[i]) / Δm[i]

    end
    println(aPrime[length(z)])

    #x = aPrime[end-1]
    #println(aPrime[length(z) - 1])
    #aPrime[end] = aPrime[end-1]

    #-----------------------------------#
    # Calculate
    #-----------------------------------#

    # Compute μ
    integrand =  (ν .* aPrime .+ τ) ./ (ν .* z)
    summand = integrand .* Δm
    integral = cumsum(summand[:])
    μ = exp.(-integral)
    μ = μ / sum(μ .* Δm)

    innovationRateIncumbent = sum(τI .* μ .* Δm)
    entryRateOrdinary = sum(τE .* μ .* Δm)
    entryRateSpinouts = sum(τS .* μ .* Δm)
    entryRate = entryRateOrdinary + entryRateSpinouts

    internalPatentShare = innovationRateIncumbent / (innovationRateIncumbent + entryRate)

    spinoutShare = entryRateSpinouts / entryRate

    aggregateSales = finalGoodsLabor
    aggregateRDSpending = sum(w .* z .* γ .* μ .* Δm)
    RDintensity = aggregateRDSpending / aggregateSales

    modelMoments = zeros(6)

    modelMoments[1] = RDintensity
    modelMoments[2] = internalPatentShare
    modelMoments[3] = entryRateSpinouts
    modelMoments[4] = spinoutShare
    modelMoments[5] = g
    modelMoments[6] = L_RD

    return modelMoments

end

function computeScore(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,targets::Vector{Float64},weights::Vector{Float64})

    #--------------------------------#
    # Comute model moments
    #--------------------------------#

    # Eventually, would be cool if this could adapt to what fields are in the struct calibPar...

    modelMoments = computeModelMoments(algoPar,modelPar,guess)

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

    #----------------------------------#
    # Calibrate model based on weights
    #----------------------------------#

    # First, define objective function f in format that can
    # be used with ReverseDiff.jl

    function f(x::Vector{Float64})

        # Unpack x vector into modelPar struct for inputting into model solver

        #modelPar.ρ = x[1]
        modelPar.χI = x[1]
        modelPar.χS = x[2]
        modelPar.χE = x[3] * x[2]
        modelPar.λ = x[4]
        modelPar.ν = x[5]

        f = open("./figures/log.txt","a")

        write(f,"Iteration: χI = $(x[1]); χS = $(x[2]); χE = $(x[2] * x[3]); λ = $(x[4]); ν = $(x[5])\n")

        close(f)

        output = computeScore(algoPar,modelPar,guess,targets,weights)

    end

    # Next, define gradient using ReverseDiff.jl

    #function g!(G,x)

        #G = ReverseDiff.gradient(f,x)
        #ReverseDiff.gradient!(G,f,x)
    #    ForwardDiff.gradient!(G,f,x)

    #end

    # Finally, use Optim.jl to optimize the objective function

    initial_x = [ modelPar.χI;
                  modelPar.χS;
                  modelPar.χE / modelPar.χS;
                  modelPar.λ;
                  modelPar.ν ]
    lower = [1, 1, 0.2, 1.01, 0.02]
    upper = [6, 6, 0.9, 1.08, 0.09]

    #inner_optimizer = GradientDescent()
    inner_optimizer = LBFGS()

    results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(iterations = 50, store_trace = true, show_trace = true))
    #results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer))
    #results = optimize(f,initial_x,inner_optimizer,Optim.Options(iterations = 1, store_trace = true, show_trace = true))
    #results = optimize(f,initial_x,method = inner_optimizer,iterations = 1,store_trace = true, show_trace = false)

    x = results.minimizer

    #modelPar.ρ = x[1]
    modelPar.χI = x[1]
    modelPar.χS = x[2]
    modelPar.χE = x[3] * x[2]
    modelPar.λ = x[4]
    modelPar.ν = x[5]

    finalMoments = computeModelMoments(algoPar,modelPar,guess)
    finalScore = computeScore(algoPar,modelPar,guess,targets,weights)
    return results,finalMoments,finalScore


end


end
