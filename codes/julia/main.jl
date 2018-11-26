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
@time results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)

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

a = zS + zE + zI

mGrid,Δm = mGridBuild(algoPar.mGrid)

ϕSE(z) = z .^(-modelPar.ψSE)
χS = modelPar.χS
λ = modelPar.λ
ρ = modelPar.ρ
ν = modelPar.ν
ξ = modelPar.ξ

#--------------------------------#
# Make some plots                #
#--------------------------------#



# V
plot(x = mGrid, y = V, Geom.line, Guide.xlabel("m"), Guide.ylabel("V"), Guide.title("Incumbent value V"))
# zI
plot(x = mGrid[2:end], y = zI[2:end], Geom.line, Guide.xlabel("m"), Guide.ylabel("zI"), Guide.title("Incumbent R&D effort zI"))
# W
plot(x = mGrid, y = W, Geom.line, Guide.xlabel("m"), Guide.ylabel("W"), Guide.title("Spinout value density W"))

# χϕ(zS + zE) λ V(0) - w
#spinoutFlow = χS * ϕSE(zS + zE) * λ * V[1] .- w
plot(x = mGrid, y = spinoutFlow, Geom.line, Guide.xlabel("m"), Guide.ylabel("χϕ(zS + zE) λ V(0) - w"))

zS_density = zeros(size(zS))
zS_density[2:end] = (zS ./ mGrid)[2:end]
zS_density[1] = ξ
# W'(m) - calculating the derivative - for testing
Wprime = ((ρ * ones(size(τ)) + τ) .* W - (zS_density) .* spinoutFlow) ./ (a * ν)
plot(x = mGrid, y = Wprime, Geom.line, Guide.xlabel("m"), Guide.ylabel("W'(m)"))

Wrecalc = zeros(size(W))
# Reconstruct W
for i = 1:length(Wprime) - 1

    j = length(Wprime) - i
    Wrecalc[j] = Wrecalc[j+1] - Wprime[j] * Δm[j]

end

Wprime1 = zeros(size(W))

for i = 1:length(W)-1

    Wprime1[i] = (W[i+1] - W[i]) / Δm[i]

end



# zS
plot(layer(x = mGrid, y = zS, Geom.line),layer(x = mGrid, y = zSfactor, Geom.line),
    Guide.xlabel("m"), Guide.ylabel("zS"), Guide.title("Spinout R&D effort zS"))

# zS(m) / m - individual effort
plot(x = mGrid, y = zS ./ mGrid, Geom.line, Guide.xlabel("x"), Guide.ylabel("zS(m) / m"))

# zS(m) / m * spinoutFlow
plot(x = mGrid, y = spinoutFlow .* zS ./ mGrid, Geom.line, Guide.xlabel("x"), Guide.ylabel("(zS(m) / m) * spinoutFlow"))

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
