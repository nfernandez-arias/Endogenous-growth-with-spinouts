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
# modelParameters composite type
#

__precompile__()

module ModelSolver

using AlgorithmParametersModule, ModelParametersModule, InitialGuessModule

function solveModel(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::InitialGuess)

    # Builds mGrid - log spacing or linear spacing,
    # depending on how pa was constructed.
    mGrid = mGridBuild(algoPar.mGrid);

end

end
