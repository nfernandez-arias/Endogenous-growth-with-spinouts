using Revise
using EndogenousGrowthWithSpinouts

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

include("testWelfarePlots.jl")

#@timev w_diag,V_diag,noncompete_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)
#@timev w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,results.finalGuess,results.incumbent)

@timev wNC,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)

using Plots
gr()

using JLD2, FileIO, Optim
@load "output/calibrationResults.jld2" modelMoments modelResults score
results = modelResults

#--------------------------------#
# Make plots and compute statistics
#--------------------------------#


include("testPlots_calibration_noCNC.jl")
include("testPlots.jl")

#--------------------------------#
# Compute diagnostics
#--------------------------------#

include("testDiags.jl")
