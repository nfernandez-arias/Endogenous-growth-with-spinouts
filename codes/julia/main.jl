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
@time using GuessModule
@time using ModelSolver

## Include functions specific to THIS main script

@time include("functions/setAlgorithmParameters.jl")
@time include("functions/setModelParameters.jl")
@time include("functions/setInitialGuess.jl")

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

#@time finalGuess,incumbentHJBSolution,W = solveModel(algoPar,modelPar,initGuess)
@time results = solveModel2(algoPar,modelPar,initGuess)

## Unpack

L_RD = results.finalGuess.L_RD
w = results.finalGuess.w
zS = results.finalGuess.zS
zE = results.finalGuess.zE
V = results.incumbent.V
zI = results.incumbent.zI
W = results.spinoutValue

mGrid,Δm = mGridBuild(algoPar.mGrid)

#--------------------------------#
# Plot results of solved model
#--------------------------------#

# Import package Plots and define
# Plotly backend with plotly() command

@time using Gadfly
