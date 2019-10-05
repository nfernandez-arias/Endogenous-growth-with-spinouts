using Revise
using EndogenousGrowthWithSpinouts

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

term1, noncompeteEffect, results, resultsNC = zI_CNC_decomp(algoPar,modelPar,initGuess)


modelPar.CNC = false

t = results.auxiliary.t
zI = results.incumbent.zI
zS = EndogenousGrowthWithSpinouts.zSFunc(algoPar,modelPar,results.finalGuess.idxM)
zE = EndogenousGrowthWithSpinouts.zEFunc(modelPar,results.incumbent,results.finalGuess.w,results.finalGuess.wE,zS)
τI = EndogenousGrowthWithSpinouts.τIFunc(modelPar,zI,zS,zE)
τSE = EndogenousGrowthWithSpinouts.τSEFunc(modelPar,zI,zS,zE)
τE = EndogenousGrowthWithSpinouts.τEFunc(modelPar,zI,zS,zE)
τS = τSE - τE

modelPar.CNC = true

t_NC = resultsNC.auxiliary.t
zI_NC = resultsNC.incumbent.zI
zS_NC = EndogenousGrowthWithSpinouts.zSFunc(algoPar,modelPar,resultsNC.finalGuess.idxM)
zE_NC = EndogenousGrowthWithSpinouts.zEFunc(modelPar,resultsNC.incumbent,resultsNC.finalGuess.w,resultsNC.finalGuess.wE,zS_NC)
τI_NC = EndogenousGrowthWithSpinouts.τIFunc(modelPar,zI_NC,zS_NC,zE_NC)
τSE_NC = EndogenousGrowthWithSpinouts.τSEFunc(modelPar,zI_NC,zS_NC,zE_NC)
τE_NC = EndogenousGrowthWithSpinouts.τEFunc(modelPar,zI_NC,zS_NC,zE_NC)
τS_NC = τSE_NC - τE_NC

plot(t,[τI τS τE], label = ["I" "S" "E"])
plot(t_NC,[τI_NC τS_NC τE_NC], label = ["I" "S" "E"])


plot(t,[zI zS zE], label = ["I" "S" "E"])
plot(t_NC,[zI_NC zS_NC zE_NC], label = ["I" "S" "E"])
