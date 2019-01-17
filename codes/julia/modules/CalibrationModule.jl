#---------------------------------
# Name: CalibrationModule.jl
#
# Module containing functions for calibrating the model
#

__precompile__()

module CalibrationModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule, ModelSolver

struct CalibrationTargets

    

end

struct CalibrationParameters

    targets::Vector{Float64}
    weights::Vector{Float64}

    #method::String

end

function calibrateModel(calibPar::CalibrationParameters,algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::Guess)

    weights = calibPar.weights
    targets = calibPar.targets


end









end
