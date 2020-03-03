using Revise
using EndogenousGrowthWithSpinouts
using LaTeXStrings
using Plots
gr()

cd("/home/nico/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/code/julia")

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

@timev sol,A,results = solveModel(algoPar,modelPar,initGuess)

#using JLD2, FileIO, Optim
#@load "output/calibrationResults_noCNC.jld2" modelMoments modelResults score
#results = modelResult

#--------------------------------#
# Make plots and compute statistics
#--------------------------------#

#include("testPlots_calibration_noCNC.jl")
include("testPlots.jl")

#-----------------------------true---#
# Compute diagnostics
#--------------------------------#

include("testDiags.jl")

results1 = results
results2 = results
aNC = a
#aNoNC =
## Random stuff

p = plot(t, [results1.auxiliary.μ.*ν.*a results2.auxiliary.μ.*ν.*aNC], xlims = (0,35), title = "Stationary distribution", label = ["Baseline" "Noncompetes"], ylabel = "Density", xlabel = "Years since last innovation", linestyle = [:solid :dash])

png("figures/plotsGR/compStatNC_mu.png")
