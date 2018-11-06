#---------------------------------
# Name: AuxiliaryModule.jl
#
# Module containing auxiliary
# functions for solving model
#
# E.g., profit as funciton of L_RD guess


__precompile__()

module AuxiliaryModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule

export LF,profit,initialGuessIncumbentHJB

function LF(L_RD::Float64, modelPar::ModelParameters)

    β,L = modelPar.β, modelPar.L;
    return β * (L - L_RD) / (β + (1-β)^2);

end

function profit(L_RD::Float64, modelPar::ModelParameters)

    β = modelPar.β;
    return β * (1-β)^((2-β)/β) * β^(-1) * LF(L_RD,modelPar);

end

function wbar(β::Float64)

    return (β^β)*(1-β)^(2-2*β);

end

function initialGuessIncumbentHJB(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::InitialGuess)

    # Calculate initial guess for incumbent value function

    return (profit(guess.L_RD, modelPar) / modelPar.ρ) * ones(algoPar.mGrid.numPoints,1);

end

end
