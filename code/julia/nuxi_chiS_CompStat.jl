using Revise
using InitializationModule
using AlgorithmParametersModule
using ModelSolver
using HJBModule
using GuessModule
using AuxiliaryModule
using DataFrames
using Gadfly
using Interpolations
using Cairo, Fontconfig
using JLD2

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
guess = setInitialGuess(algoPar,modelPar,mGrid)

νMin = 0.005
νMax = 0.1
νStep = 0.005

χSMin = 1.42 - 0.125
χSMax = χSMin + 0.5
χSStep = 0.125

νGrid = νMin:νStep:νMax#--------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)


χSGrid = χSMin:χSStep:χSMax

#resultsMatrix = zeros(length(νGrid),length(ξGrid),5)
#resultsMatrix = fill(Guess(guess.g,guess.L_RD,guess.w,guess.zS,guess.zE),(length(νGrid),length(ξGrid)))
resultsMatrix = Array{ModelSolution,2}(undef,length(χSGrid),length(νGrid))

#guess = Guess(initGuess.g,initGuess.L_RD,initGuess.w,initGuess.zS,initGuess.zE)

i_idx = 1
j_idx = 1

for i = 1:length(χSGrid)

    i_idx = i

    for j = 1:length(νGrid)

        j_idx = j

        modelPar.χS = χSGrid[i]
        modelPar.ν = νGrid[j]

        results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,guess)

        # Update guess in place for faster looping

        guess.g = results.finalGuess.g
        guess.L_RD = results.finalGuess.L_RD
        guess.w = results.finalGuess.w
        guess.zS = results.finalGuess.zS
        guess.zE = results.finalGuess.zE

        #resultsMatrix[i,j] = Guess(results.finalGuess.g,results.finalGuess.L_RD,results.finalGuess.w,results.finalGuess.zS,results.finalGuess.zE)
        resultsMatrix[i,j] = ModelSolution(results.finalGuess,results.incumbent,results.spinoutValue,results.auxiliary)

    end

end

## Save resultsMatrix as JLD file
#save("./output/nuxi_resultsMatrix.jld","resultsMatrix",resultsMatrix)using Revise
#using InitializationModule
#using AlgorithmParametersModule
#using ModelSolver
#using HJBModule
#using GuessModule
#using AuxiliaryModule
#using DataFrames
#using Gadfly
#using Interpolations
#using Cairo, Fontconfig
#using JLD2
@save "./output/nuxi_resultsMatrix.jld2" resultsMatrix
