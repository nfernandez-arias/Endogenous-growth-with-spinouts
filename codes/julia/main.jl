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

using Revise
using AlgorithmParametersModule
using ModelParametersModule
using AuxiliaryModule
using GuessModule
using ModelSolver
using HJBModule
using DataFrames
using Gadfly

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

@time results,zSfactor,zEfactor = solveModel(algoPar,modelPar,initGuess)

## Unpack

L_RD = results.finalGuess.L_RD
w = results.finalGuess.w
zS = results.finalGuess.zS
zE = results.finalGuess.zE
V = results.incumbent.V
zI = results.incumbent.zI
W = results.spinoutValue

τI = AuxiliaryModule.τI(modelPar,zI)
τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
τ = τI + τSE

mGrid,Δm = mGridBuild(algoPar.mGrid)



#--------------------------------#
# Make some plots                #
#--------------------------------#

# V
plot(x = mGrid, y = V, Geom.line, Guide.xlabel("m"), Guide.ylabel("V"), Guide.title("Incumbent value V"))
# zI
plot(x = mGrid, y = zI, Geom.line, Guide.xlabel("m"), Guide.ylabel("zI"), Guide.title("Incumbent R&D effort zI"))

# W
plot(x = mGrid, y = W, Geom.line, Guide.xlabel("m"), Guide.ylabel("W"), Guide.title("Spinout value density W"))

# zS
plot(layer(x = mGrid, y = zS, Geom.line),layer(x = mGrid, y = zSfactor, Geom.line),
    Guide.xlabel("m"), Guide.ylabel("zS"), Guide.title("Spinout R&D effort zS"))
# zE
plot(layer(x = mGrid, y = zE, Geom.line),layer(x = mGrid, y = zEfactor, Geom.line),
    Guide.xlabel("m"), Guide.ylabel("zE"), Guide.title("Non-spinout Entrant R&D effort zE"))

# τ

df1 = DataFrame(x = mGrid[:], y = τSE[:], label = "Creative Destruction")
df2 = DataFrame(x = mGrid, y = τI[:], label = "Incumbent innovation")
df3 = DataFrame(x = mGrid[:], y = τ[:], label = "Aggregate")
df = vcat(df1,df2,df3)

plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("Innovation Arrival Rates"), Guide.xlabel("m"),
                        Guide.ylabel("Annual Poisson intensity"),
                        Theme(major_label_color = colorant"white", minor_label_color = colorant"white", ))

# τSE
plot(x = mGrid, y = τ, Geom.line, Guide.xlabel("m"), Guide.ylabel("τ"), Guide.title("Aggregate rate of creative destruction"))

# zEfactor
plot(x = mGrid, y = zEfactor, Geom.line, Guide.xlabel("m"), Guide.ylabel("zE factor"), Guide.title("zE Update Factor"))



# w
plot(x = mGrid, y = w, Geom.line, Guide.xlabel("m"), Guide.ylabel("w"), Guide.title("Wage w"))
