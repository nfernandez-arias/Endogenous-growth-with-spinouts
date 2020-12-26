#---------------------------------
# Name: CalibrationModule.jl
#
# Module containing functions for calibrating the model
#

using LinearAlgebra, Statistics, Optim, ForwardDiff

export CalibrationTarget, CalibrationParameters, ModelMoments, calibrateModel, calibrateModel_noSpinouts, calibrateModel_noCreativeDestructionCost, computeModelMoments,computeScore
export constructJacobian, constructWelfareComparisonFullGradient, constructLevelsWelfareComparisonFullGradient, constructFullJacobian

struct CalibrationTarget

    value::Real
    weight::Real

end


struct CalibrationParameters

    interestRate::CalibrationTarget
    growthRate::CalibrationTarget
    growthShareOI::CalibrationTarget
    youngFirmEmploymentShare::CalibrationTarget
    spinoutEmploymentShare::CalibrationTarget
    rdShare::CalibrationTarget
    #WageRatio::SimpleCalibrationTarget
    #WageRatioIncumbents::SimpleCalibrationTarget
    #SpinoutsNCShare::SimpleCalibrationTarget

end

struct ModelMoments

    interestRate::Real
    growthRate::Real
    growthShareOI::Real
    youngFirmEmploymentShare::Real
    spinoutEmploymentShare::Real
    rdShare::Real

end


function computeModelMoments(modelPar::ModelParameters, algoPar::AlgorithmParameters, outerGuess::Guess)  

    #-----------------------------------#
    # Extract model parameters
    #-----------------------------------#

    # Solve model
    sol = solveModel(modelPar,algoPar,outerGuess)

    # Update outerGuess

    outerGuess.τE = sol.τE
    outerGuess.r = sol.r

    # Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψE = modelPar.ψE
    ψI = modelPar.ψI
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE
    κC = modelPar.κC

    #---------------------------#
    ## Compute model moments
    #---------------------------#

    #------------#
    # youngFirmEmploymentShare
    #------------#

    # incumbent innovation share
    τIhat = sol.τI / (sol.τI + sol.τS + sol.τE)

    # Share of incumbnet employment in firms age < 6
    Ξ = 1 - exp( ((τIhat - 1) * sol.g - (sol.τE + sol.τS) ) * 6)

    # share of overall employment

    #youngFirmEmploymentShare = (2/3) * ( Ξ * (1 - sol.LF - sol.zE) + sol.zE ) / (1 - sol.LF)

    youngFirmEmploymentShare = (2/3) * ( Ξ * (1 - sol.zE)   + sol.zE )

    spinoutEmploymentShare = (sol.τS / (sol.τS + (2/3) * sol.τE)) * (1 - sol.LF - (2/3) * sol.zE)/(1 - sol.LF)

    #------------#
    # growthShareOI
    #------------#

    growthShareOI = τIhat * (1 - Ξ)

    #------------#
    # rdShare
    #------------#

    rdShare = (sol.wRD_I * (sol.zI + sol.zE) + (1-sol.nca) * (1 - modelPar.κE) * modelPar.λ * modelPar.ν * sol.V * sol.zE ) / sol.Y

    #println(sol.r)
    #println(sol.g)
    #println(growthShareOI)
    #println(youngFirmEmploymentShare)
    #println(spinoutEmploymentShare)
    #println(rdShare)

    ## Return model moments

    simpleModelMoments = ModelMoments(sol.r, sol.g, growthShareOI, youngFirmEmploymentShare, spinoutEmploymentShare, rdShare)

    #print(typeof(simpleModelMoments))

    return simpleModelMoments

end

function computeScore(modelPar::ModelParameters,algoPar::AlgorithmParameters, outerGuess::Guess, targets::Array{Float64},weights::Array{Float64})

    #--------------------------------#
    # Comute model moments
    #--------------------------------#

    # Eventually, would be cool if this could adapt to what fields are in the struct calibPar...

    ModelMoments = computeModelMoments(modelPar,algoPar,outerGuess)

    #--------------------------------#
    # Compute score
    #--------------------------------#

    #SimpleModelMomentsVec = zeros(length(fieldnames(typeof(SimpleModelMoments))),1)
    ModelMomentsVec = zeros(6,1)

    ModelMomentsVec[1] = ModelMoments.interestRate
    ModelMomentsVec[2] = ModelMoments.growthRate
    ModelMomentsVec[3] = ModelMoments.growthShareOI
    ModelMomentsVec[4] = ModelMoments.youngFirmEmploymentShare
    ModelMomentsVec[5] = ModelMoments.spinoutEmploymentShare
    ModelMomentsVec[6] = ModelMoments.rdShare

    # divide error by target moment -- "unit free" errors. Weights can then reflect purely imoportance of the moment.

    score = [0]

    score = ((ModelMomentsVec - targets)./targets)' * Diagonal(weights) * ((ModelMomentsVec - targets)./targets)

    return score[1]

end

function calibrateModel(modelPar::ModelParameters,algoPar::AlgorithmParameters, calibPar::CalibrationParameters, outerGuess::Guess)

    ### First, construct outer guess for first solving of model

    # Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψE = modelPar.ψE
    ψI = modelPar.ψI
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE
    κC = modelPar.κC

    # Compute final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # Compute production wage
    wProd = Cβ(β)

    # Compute flow profits
    π0 = Cβ(β)*(1-β) * LF

    # Compute noncompete policy
    nca = (1 - (1-(1-κE)*λ) > κC )

    # Compute initial guesses
    # Begin with hypothesis that τE = 0. 

    # τE = 0
    # r = θg + ρ, where g = (λ-1) * χI * L^(1-ψ) 

    τE_init = 0
    r_init = θ * (λ-1)*(χI*L^(1-ψI) + (1-nca)*ν*L) + ρ

    # I do it this way so I can store outerGuess after calibration for easier plotting.

    outerGuess.τE = τE_init
    outerGuess.r = r_init


    ## Now extract calibration targets

    targets = zeros(length(fieldnames(typeof(calibPar))))
    weights = zeros(size(targets))

    for (i,field) = enumerate(fieldnames(typeof(calibPar)))

        temp = getfield(calibPar,field)

        targets[i] = temp.value
        weights[i] = temp.weight

    end

    #----------------------------------#
    # Calibrate model 
    #----------------------------------#

    # First, define objective function f in format that can
    # be used with ReverseDiff.jl

    function f(x::Array{Float64})

        # Unpack x vector into modelPar struct for inputting into model solver

        modelPar.ρ = x[1]
        modelPar.λ = x[2]
        modelPar.χI = x[3]
        modelPar.χE = x[4] * x[3]
        modelPar.κE = x[5]
        modelPar.ν = x[6] * x[3]

        modelPar.κC = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

        log_file = open("./figures/incumbentDRS_SimpleModelCalibrationLog.txt","a")
        write(log_file,"Iteration: ρ = $(modelPar.ρ); λ = $(modelPar.λ); χI = $(modelPar.χI); χE = $(modelPar.χE); κE = $(modelPar.κE); ν = $(modelPar.ν)\n")
        close(log_file)

        output = computeScore(modelPar,algoPar,outerGuess,targets,weights)

        log_file = open("./figures/incumbentDRS_SimpleModelCalibrationLog_objectiveValues.txt","a")
        write(log_file, "Value of objective: $output\n")
        close(log_file)

        return output

    end

    # Next, define gradient using ReverseDiff.jl

    #function g!(G,x)

        #G = ReverseDiff.gradient(f,x)
        #ReverseDiff.gradient!(G,f,x)
    #    ForwardDiff.gradient!(G,f,x)

    #end

    # Finally, use Optim.jl to optimize the objective function

    initial_x = [ modelPar.ρ,
                  modelPar.λ,
                  modelPar.χI,
                  modelPar.χE / modelPar.χI,
                  modelPar.κE,
                  modelPar.ν / modelPar.χI ]

    lower = [0.001, 1.02, 0.1, 0, 0, 0]
    upper = [0.1, 1.9, 30, 0.5, 0.999999, 0.5]

    #inner_optimizer = GradientDescent()
    inner_optimizer = LBFGS()


    calibrationResults = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(outer_iterations = 1000000, iterations = 10000000, store_trace = true))

    x = calibrationResults.minimizer

    # UMake some plots and return

    modelPar.ρ = x[1]
    modelPar.λ = x[2]
    modelPar.χI = x[3]
    modelPar.χE = x[4] * x[3]
    modelPar.κE = x[5]
    modelPar.ν = x[6] * x[3]

    modelPar.κC = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

    sol = solveModel(modelPar,algoPar,outerGuess)

    finalMoments = computeModelMoments(modelPar,algoPar,outerGuess)

    finalScore = computeScore(modelPar,algoPar,outerGuess,targets,weights)

    return calibrationResults,finalMoments,sol,finalScore

end

function calibrateModel_noSpinouts(modelPar::ModelParameters,calibPar::CalibrationParameters)

    targets = zeros(length(fieldnames(typeof(calibPar))))
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

        modelPar.ρ = x[1]
        modelPar.λ = x[2]
        modelPar.χI = x[3]
        modelPar.χE = x[4] * x[3]
        modelPar.κE = x[5]

        modelPar.κC = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

        log_file = open("./figures/SimpleModelCalibrationLog.txt","a")
        write(log_file,"Iteration: ρ = $(modelPar.ρ); λ = $(modelPar.λ); χI = $(modelPar.χI); χE = $(modelPar.χE); κE = $(modelPar.κE); ν = $(modelPar.ν)\n")
        close(log_file)

        output = computeScore(modelPar,targets,weights)

        log_file = open("./figures/SimpleModelCalibrationLog_objectiveValues.txt","a")
        write(log_file, "Value of objective: $output\n")
        close(log_file)

        return output

    end

    # Next, define gradient using ReverseDiff.jl

    #function g!(G,x)

        #G = ReverseDiff.gradient(f,x)
        #ReverseDiff.gradient!(G,f,x)
    #    ForwardDiff.gradient!(G,f,x)

    #end

    # Finally, use Optim.jl to optimize the objective function

    initial_x = [ modelPar.ρ,
                  modelPar.λ,
                  modelPar.χI,
                  modelPar.χE / modelPar.χI,
                  modelPar.κE ]

    lower = [0.001, 1.02, 0.1, 0, 0]
    upper = [0.05, 1.7, 30, 0.5, 0.999999]

    #inner_optimizer = GradientDescent()
    inner_optimizer = LBFGS()


    calibrationResults = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(outer_iterations = 1000000, iterations = 10000000, store_trace = true))

    x = calibrationResults.minimizer

    # UMake some plots and return

    modelPar.ρ = x[1]
    modelPar.λ = x[2]
    modelPar.χI = x[3]
    modelPar.χE = x[4] * x[3]
    modelPar.κE = x[5]

    modelPar.κC = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

    sol = solveSimpleModel(modelPar)

    finalMoments = computeSimpleModelMoments(modelPar)

    finalScore = computeScore(modelPar,targets,weights)

    return calibrationResults,finalMoments,sol,finalScore

end

function calibrateModel_noCreativeDestructionCost(modelPar::ModelParameters,calibPar::CalibrationParameters)

    targets = zeros(length(fieldnames(typeof(calibPar))))
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

        modelPar.ρ = x[1]
        modelPar.λ = x[2]
        modelPar.χI = x[3]
        modelPar.χE = x[4] * x[3]
        #modelPar.κE = x[5]
        modelPar.ν = x[5] * x[3]

        modelPar.κC = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

        log_file = open("./figures/SimpleModelCalibrationLog.txt","a")
        write(log_file,"Iteration: ρ = $(modelPar.ρ); λ = $(modelPar.λ); χI = $(modelPar.χI); χE = $(modelPar.χE); κE = $(modelPar.κE); ν = $(modelPar.ν)\n")
        close(log_file)

        output = computeScore(modelPar,targets,weights)

        log_file = open("./figures/SimpleModelCalibrationLog_objectiveValues.txt","a")
        write(log_file, "Value of objective: $output\n")
        close(log_file)

        return output

    end

    # Next, define gradient using ReverseDiff.jl

    #function g!(G,x)

        #G = ReverseDiff.gradient(f,x)
        #ReverseDiff.gradient!(G,f,x)
    #    ForwardDiff.gradient!(G,f,x)

    #end

    # Finally, use Optim.jl to optimize the objective function

    initial_x = [ modelPar.ρ,
                  modelPar.λ,
                  modelPar.χI,
                  modelPar.χE / modelPar.χI,
                  modelPar.ν / modelPar.χI ]

    lower = [0.001, 1.02, 0.1, 0, 0]
    upper = [0.07, 2.5, 30, 0.5, 0.5]

    #inner_optimizer = GradientDescent()
    inner_optimizer = LBFGS()


    calibrationResults = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(outer_iterations = 1000000, iterations = 10000000, store_trace = true))

    x = calibrationResults.minimizer

    # UMake some plots and return

    modelPar.ρ = x[1]
    modelPar.λ = x[2]
    modelPar.χI = x[3]
    modelPar.χE = x[4] * x[3]
    modelPar.ν = x[5] * x[3]

    modelPar.κC = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

    sol = solveModel(modelPar)

    finalMoments = computeModelMoments(modelPar)

    finalScore = computeScore(modelPar,targets,weights)

    return calibrationResults,finalMoments,sol,finalScore

end


function constructJacobian(modelPar::ModelParameters)

    # Set κC so that NCAs are not used -- always true in calibration,
    # because data has spinouts, and this is necessary for model
    # to generate any spinouts at all.

    modelPar.κC = 2*(1 - (1-modelPar.κE)*modelPar.λ)

    # Next, compute the log-log Jacobian, i.e. in elasticity terms
    # To do this, define six function, each taking as arguments the
    # logs of the parameters, and returns the log of the relevant
    # moment. Don't know how to do this simultaneously, but not
    # a huge deal because just six functions....

    function f(x::Vector{})

        # Make copy of modelParameters
        modelParTemp = deepcopy(modelPar)

        # Now assign x values to relevant parameters

        modelParTemp.ρ = exp(x[1])
        modelParTemp.λ = exp(x[2])
        modelParTemp.χI = exp(x[3])
        modelParTemp.χE = exp(x[4])
        modelParTemp.κE = exp(x[5])
        modelParTemp.ν = exp(x[6])

        # Now compute model moments
        moments = computeModelMoments(modelParTemp)

        # Return log of model moments

        # Has to be in vector form or automatic differentiation doesn't work

        outputVec = Vector{}(undef,6)

        outputVec[1] = log(moments.interestRate)
        outputVec[2] = log(moments.growthRate)
        outputVec[3] = log(moments.growthShareOI)
        outputVec[4] = log(moments.youngFirmEmploymentShare)
        outputVec[5] = log(moments.spinoutEmploymentShare)
        outputVec[6] = log(moments.rdShare)

        return outputVec

    end

    x = Vector{}(undef,6)

    x[1] = log(modelPar.ρ)
    x[2] = log(modelPar.λ)
    x[3] = log(modelPar.χI)
    x[4] = log(modelPar.χE)
    x[5] = log(modelPar.κE)
    x[6] = log(modelPar.ν)

    g = x -> ForwardDiff.jacobian(f,x)

    return g

end

function constructWelfareComparisonFullGradient(modelPar::ModelParameters)

    # Set κC so that NCAs are not used -- always true in calibration,
    # because data has spinouts, and this is necessary for model
    # to generate any spinouts at all.

    # Next, compute the log-log Jacobian, i.e. in elasticity terms
    # To do this, define six function, each taking as arguments the
    # logs of the parameters, and returns the log of the relevant
    # moment. Don't know how to do this simultaneously, but not
    # a huge deal because just six functions....

    function f(x::Vector{})

        # Make copy of modelParameters
        modelParTemp = deepcopy(modelPar)

        # Now assign x values to relevant parameters

        modelParTemp.ρ = exp(x[1])
        modelParTemp.θ = exp(x[2])
        modelParTemp.β = exp(x[3])
        modelParTemp.ψI = exp(x[4])
        modelParTemp.ψE = exp(x[5])
        modelParTemp.λ = exp(x[6])
        modelParTemp.χI = exp(x[7])
        modelParTemp.χE = exp(x[8])
        modelParTemp.κE = exp(x[9])
        modelParTemp.ν = exp(x[10])

        κC0 = 2*(1 - (1-modelParTemp.κE)*modelParTemp.λ)

        out = computeWelfareComparison(modelParTemp,κC0,0)
        # Return log of welfare improvement
        return log(out)

    end

    x = Vector{}(undef,9)

    x[1] = log(modelPar.ρ)
    x[2] = log(modelPar.θ)
    x[3] = log(modelPar.β)
    x[4] = log(modelPar.ψI)
    x[5] = log(modelPar.ψE)
    x[6] = log(modelPar.λ)
    x[7] = log(modelPar.χI)
    x[8] = log(modelPar.χE)
    x[9] = log(modelPar.κE)
    x[10] = log(modelPar.ν)

    g = x -> ForwardDiff.gradient(f,x)

    return g

end

function constructLevelsWelfareComparisonFullGradient(modelPar::ModelParameters)

    # Set κC so that NCAs are not used -- always true in calibration,
    # because data has spinouts, and this is necessary for model
    # to generate any spinouts at all.

    # Next, compute the log-log Jacobian, i.e. in elasticity terms
    # To do this, define six function, each taking as arguments the
    # logs of the parameters, and returns the log of the relevant
    # moment. Don't know how to do this simultaneously, but not
    # a huge deal because just six functions....

    function f(x::Vector{})

        # Make copy of modelParameters
        modelParTemp = deepcopy(modelPar)

        # Now assign x values to relevant parameters

        modelParTemp.ρ = exp(x[1])
        modelParTemp.θ = exp(x[2])
        modelParTemp.β = exp(x[3])
        modelParTemp.ψI = exp(x[4])
        modelParTemp.ψE = exp(x[5])
        modelParTemp.λ = exp(x[6])
        modelParTemp.χI = exp(x[7])
        modelParTemp.χE = exp(x[8])
        modelParTemp.κE = exp(x[9])
        modelParTemp.ν = exp(x[10])

        κC0 = 2*(1 - (1-modelParTemp.κE)*modelParTemp.λ)

        out = computeWelfareComparison(modelParTemp,κC0,0)
        # Return log of welfare improvement
        return out

    end

    x = Vector{}(undef,9)

    x[1] = log(modelPar.ρ)
    x[2] = log(modelPar.θ)
    x[3] = log(modelPar.β)
    x[4] = log(modelPar.ψI)
    x[5] = log(modelPar.ψE)
    x[6] = log(modelPar.λ)
    x[7] = log(modelPar.χI)
    x[8] = log(modelPar.χE)
    x[9] = log(modelPar.κE)
    x[10] = log(modelPar.ν)

    g = x -> ForwardDiff.gradient(f,x)

    return g

end




function constructFullJacobian(modelPar::ModelParameters)

    # Set κC so that NCAs are not used -- always true in calibration,
    # because data has spinouts, and this is necessary for model
    # to generate any spinouts at all.

    modelPar.κC = 2*(1 - (1-modelPar.κE)*modelPar.λ)

    # Next, compute the log-log Jacobian, i.e. in elasticity terms
    # To do this, define six function, each taking as arguments the
    # logs of the parameters, and returns the log of the relevant
    # moment. Don't know how to do this simultaneously, but not
    # a huge deal because just six functions....

    function f(x::Vector{})

        # Make copy of modelParameters
        modelParTemp = deepcopy(modelPar)

        # Now assign x values to relevant parameters

        modelParTemp.ρ = exp(x[1])
        modelParTemp.θ = exp(x[2])
        modelParTemp.β = exp(x[3])
        modelParTemp.ψI = exp(x[4])
        modelParTemp.ψE = exp(x[5])
        modelParTemp.λ = exp(x[6])
        modelParTemp.χI = exp(x[7])
        modelParTemp.χE = exp(x[8])
        modelParTemp.κE = exp(x[9])
        modelParTemp.ν = exp(x[10])

        # Now compute model moments
        moments = computeModelMoments(modelParTemp)

        # Return log of model moments

        # Has to be in vector form or automatic differentiation doesn't work

        outputVec = Vector{}(undef,9)

        outputVec[1] = log(moments.interestRate)
        outputVec[2] = log(moments.growthRate)
        outputVec[3] = log(moments.growthShareOI)
        outputVec[4] = log(moments.youngFirmEmploymentShare)
        outputVec[5] = log(moments.spinoutEmploymentShare)
        outputVec[6] = log(moments.rdShare)

        # Non-calibrated parameters

        outputVec[7] = x[2] # θ
        outputVec[8] = x[3] # β
        outputVec[9] = x[4] # ψI
        outputVec[10] = x[5] # ψE

        return outputVec

    end

    x = Vector{}(undef,9)

    x[1] = log(modelPar.ρ)
    x[2] = log(modelPar.θ)
    x[3] = log(modelPar.β)
    x[4] = log(modelPar.ψI)
    x[5] = log(modelPar.ψE)
    x[6] = log(modelPar.λ)
    x[7] = log(modelPar.χI)
    x[8] = log(modelPar.χE)
    x[9] = log(modelPar.κE)
    x[10] = log(modelPar.ν)

    g = x -> ForwardDiff.jacobian(f,x)

    return g

end
