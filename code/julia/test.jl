include("loadPath.jl")

using EndogenousGrowthWithSpinouts

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

@timev w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)
#@timev w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,results.finalGuess,results.incumbent)


using Plots
gr()

#--------------------------------#
# Compute diagnostics
#--------------------------------#

include("testDiags.jl")

#--------------------------------#
# Make plots and compute statistics
#--------------------------------#

include("testPlots.jl")
