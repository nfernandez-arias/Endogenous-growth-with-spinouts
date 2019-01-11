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
using Cairo, Fontconfig

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

algoPar = setAlgorithmParameters()
initGuess.zS = results.finalGuess.zS
initGuess.zE = results.finalGuess.zE
initGuess.w = results.finalGuess.w
modelPar.ψI = 0.5
modelPar.ψSE = 0.2

@time results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)


#--------------------------------#
# Unpack - using unpackScript.jl
#--------------------------------#

include("unpackScript.jl")

#--------------------------------#
# Make some plots                #
#--------------------------------#

include("plotScript.jl")

#--------------------------------#
# DO some testing for troubleshooting #
#------------------------------


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
