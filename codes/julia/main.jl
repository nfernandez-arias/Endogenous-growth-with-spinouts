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

using AlgorithmParametersModule
using ModelParametersModule
using GuessModule
using ModelSolver

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

#@time finalGuess,incumbentHJBSolution,W = solveModel(algoPar,modelPar,initGuess)
@time results = solveModel2(algoPar,modelPar,initGuess)

@time results2 = solveModel2(algoPar,modelPar,initGuess)

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

using Gadfly

# V
plot(x = mGrid, y = V, Geom.line, Guide.xlabel("m"), Guide.ylabel("V"), Guide.title("Incumbent value V"))

# zS
plot(x = mGrid, y = zS, Geom.line, Guide.xlabel("m"), Guide.ylabel("zS"), Guide.title("Spinout R&D effort zS"))
# zE
plot(x = mGrid, y = zE, Geom.line, Guide.xlabel("m"), Guide.ylabel("zE"), Guide.title("Non-spinout Entrant R&D effort zE"))

# w
plot(x = mGrid, y = w, Geom.line, Guide.xlabel("m"), Guide.ylabel("w"), Guide.title("Wage w"))
