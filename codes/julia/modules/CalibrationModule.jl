#---------------------------------
# Name: CalibrationModule.jl
#
# Module containing functions for calibrating the model
#

__precompile__()

module CalibrationModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule, ModelSolver, AuxiliaryModule
using LinearAlgebra, Statistics, Compat, Optim, ReverseDiff

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
    modelMoments[3] = entryRate
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

        modelPar.ρ = x[1]
        modelPar.χI = x[2]
        modelPar.χS = x[3]
        modelPar.χE = x[4] * x[3]
        modelPar.λ = x[5]
        modelPar.ν = x[6]

        output = computeScore(algoPar,modelPar,guess,targets,weights)

    end

    # Next, define gradient using ReverseDiff.jl

    #function g!(G,x)

        #G = ReverseDiff.gradient(f,x)
    #    ReverseDiff.gradient!(G,f,x)

    #end

    # Finally, use Optim.jl to optimize the objective function

    initial_x = [ modelPar.ρ;
                  modelPar.χI;
                  modelPar.χS;
                  modelPar.χE / modelPar.χS;
                  modelPar.λ;
                  modelPar.ν ]

    lower = [0.01, 0.1, 0.1, 0.01, 1.001, 0.01]
    upper = [0.1, 6, 6, 0.99, 1.5, 0.5]

    inner_optimizer = GradientDescent()
    results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer))
    #results = optimize(f,g!,lower,upper,initial_x,Fminbox(inner_optimizer))


end


end
