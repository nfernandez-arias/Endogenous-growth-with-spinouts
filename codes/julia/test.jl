using Revise

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#



@time results,zSfactor,zEfactor,spinoutFlow,γ,t = solveModel(algoPar,modelPar,initGuess)

#--------------------------------#
# Display solution
#--------------------------------#

g = results.finalGuess.g
L_RD = results.finalGuess.L_RD

println("Solutions:")
println("g: $g; L_RD: $L_RD")

#--------------------------------#
# Unpack - using unpackScript.jl
#--------------------------------#

include("unpackScript.jl")

#--------------------------------#
# Make some plots                #
#--------------------------------#

include("plotScript.jl")
