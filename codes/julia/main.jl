#--------------------------------#
# Name: main.jl                  #
#                                #
# Main function for testing      #
# my suite for solving           #
# endogenous growth model        #
# with spinouts.                 #
#--------------------------------#

#--------------------------------#
#   Loading packages             #
#--------------------------------#

## Using basic modules

@time using AlgorithmParametersModule
@time using ModelParametersModule
@time using InitialGuessModule
@time using ModelSolver

## Include functions specific to THIS main script

include("functions/setAlgorithmParameters.jl")
include("functions/setModelParameters.jl")
include("functions/setInitialGuess.jl")

#--------------------------------#
# Set algorithm parameters,
# model parameters, and
# initial guesses
#--------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
initGuess = setInitialGuess(algoPar,modelPar)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

model = solveModel(algoPar,modelPar,initGuess)

#--------------------------------#
# Show results of solved model
#--------------------------------#
