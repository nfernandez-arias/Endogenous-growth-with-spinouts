using Revise
using EndogenousGrowthWithSpinouts

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

#include("testWelfarePlots.jl")

#@timev w_diag,V_diag,noncompete_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)
#@timev w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,results.finalGuess,results.incumbent)

@timev results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)

using Plots
gr()

using JLD2, FileIO, Optim
@load "output/calibrationResults_noCNC.jld2" modelMoments modelResults score
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



results1 = results
results2 = results
aNC = a
aNoNC =
## Random stuff

p = plot(t, [results1.auxiliary.μ.*ν.*a results2.auxiliary.μ.*ν.*aNC], xlims = (0,35), title = "Stationary distribution", label = ["Baseline" "Noncompetes"], ylabel = "Density", xlabel = "Years since last innovation", linestyle = [:solid :dash])

png("figures/plotsGR/compStatNC_mu.png")
