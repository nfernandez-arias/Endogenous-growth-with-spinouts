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
using InitializationModule
using DataFrames
using Gadfly

#--------------------------------#
# Set algorithm parameters,
# model parameters, and
# initial guesses
#--------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

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
zIfromFOC = zeros(size(zI))
W = results.spinoutValue

τI = AuxiliaryModule.τI(modelPar,zI)
τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
τ = τI + τSE

a = zS + zE + zI

mGrid,Δm = mGridBuild(algoPar.mGrid)

ϕSE(z) = z .^(-modelPar.ψSE)
ϕI(z) = z .^(-modelPar.ψI)
χS = modelPar.χS
λ = modelPar.λ
ρ = modelPar.ρ
ν = modelPar.ν
ξ = modelPar.ξ
ψI = modelPar.ψI
χI = modelPar.χI

Π = AuxiliaryModule.profit(results.finalGuess.L_RD,modelPar)

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




df1 = DataFrame(x = mGrid[:], y = zS[:], label = "zS")
df2 = DataFrame(x = mGrid[:], y = zSfactor[:], label = "zSfactor")
df = vcat(df1,df2)

# zS
plot(df, x = "x", y = "y", color = "label", Geom.line)

# zS(m) / m - individual effort
plot(x = mGrid[2:end], y = zS[2:end] ./ mGrid[2:end], Geom.line, Guide.xlabel("x"), Guide.ylabel("zS(m) / m"))

# zS(m) / m * spinoutFlow
plot(x = mGrid[2:end], y = spinoutFlow[2:end] .* zS[2:end] ./ mGrid[2:end], Geom.line, Guide.xlabel("x"), Guide.ylabel("(zS(m) / m) * spinoutFlow"))

# zE
plot(layer(x = mGrid, y = zE, Geom.line),layer(x = mGrid, y = zEfactor, Geom.line),
    Guide.xlabel("m"), Guide.ylabel("zE"), Guide.title("Non-spinout Entrant R&D effort zE"))

# τ
df1 = DataFrame(x = mGrid[:], y = τSE[:], label = "Creative Destruction")
df2 = DataFrame(x = mGrid[:], y = τI[:], label = "Incumbent innovation")
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




#--------------------------------#
# DO some testing for troubleshooting #
#--------------------------------#

# Test HJB on V

err = zeros(size(mGrid))
V1 = copy(V)
V1[1] = V[2]


for i = 1:length(mGrid)-1

    Vprime = (V1[i+1] - V1[i]) / Δm[i]

    err[i] = (ρ + τSE[i]) * V1[i] - Π - a[i] * ν * Vprime - zI[i] * (χI * ϕI(zI[i]) * (λ * V1[1] - V1[i]) - w[i])

end

plot(x = mGrid, y = err, Geom.line, Guide.xlabel("m"), Guide.ylabel("error"), Guide.title("Error in Incumbent HJB"))






# zI calculated from FOC to test

using Optim
function reoptimZ(V0)

    zI = zeros(size(mGrid))

    for i= 1:length(mGrid)-1

        rhs(z) = -z[1] * (χI * ϕI(z[1]) * (λ * V0[1] - V0[i]) - (w[i] - ν * (V0[i+1] - V0[i]) / Δm[i]))

        # Guess not necessary for univariate optimization with Optim.jl using Brent algorithm
        #zIguess = [0.1]

        # Need to restrict search to positive numbers, or else getting a complex number error!
        result = optimize(rhs,0,100)

        zI[i] = result.minimizer[1];

        #zI[i] = 0.1

    end

    zI[end] = zI[end-1]

    return zI

end


function zFOCcalc(V)

    zI = zeros(size(mGrid))

    for i= 1:length(mGrid)-1

        Vprime = (V[i+1] - V[i]) / Δm[i]

        numerator = w[i] - ν * Vprime
        denominator = (1- ψI) * χI * ( λ * V[1] - V[i])
        ratio = numerator / denominator

        if ratio > 0
            zIfromFOC[i] = ratio^(-1/ψI)
        else
            zIfromFOC[i] = 0
        end
    end

    zI[end] = zI[end-1]

    return zI

end

@time reoptimZ(V)
@time zFOCcalc(V)


@time HJBModule.constructMatrixA(algoPar,modelPar,results.finalGuess,results.incumbent.zI)




zIfromFOC[end] = zIfromFOC[end-1]

df1 = DataFrame(x = mGrid[2:end], y = zI[2:end], label = "zI")
df2 = DataFrame(x = mGrid[2:end], y = zIfromFOC[2:end], label = "zI from FOC")
df = vcat(df1,df2)

plot(x = mGrid, y = zIfromFOC, Geom.line, Guide.xlabel("m"), Guide.ylabel("zI from FOC"))

plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("zI from numerical optimization and FOC"), Guide.xlabel("m"),
                        Guide.ylabel("Innovation intensity"),
                        Theme(major_label_color = colorant"white", minor_label_color = colorant"white", key_title_color = colorant"white",
                        key_label_color = colorant"white"))
