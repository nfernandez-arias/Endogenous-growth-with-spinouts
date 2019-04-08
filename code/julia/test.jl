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
using Interpolations
using Cairo, Fontconfig

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

@timev results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)

#using Profile
#Profile.clear()

#using ProfileView
#ProfileView.view()


#--------------------------------#
# Unpack - using unpackScript.jl
#--------------------------------#

include("unpackScript.jl")

#--------------------------------#
# Display solution
#--------------------------------#

g = results.finalGuess.g
L_RD = results.finalGuess.L_RD
γ = results.auxiliary.γ
t = results.auxiliary.t
println("\n--------------------------------------------------------------")
println("Growth and RD Labor Allocation--------------------------------")
println("--------------------------------------------------------------\n")
println("g: $g (growth rate) \nL_RD: $L_RD (labor allocation to R&D)")

innovationRateIncumbent = sum(τI .* μ .* Δm)
entryRateOrdinary = sum(τE .* μ .* Δm)
entryRateSpinouts = sum(τS .* μ .* Δm)
entryRateTotal = entryRateOrdinary + entryRateSpinouts
println("\n--------------------------------------------------------------")
println("Innovation rates----------------------------------------------")
println("--------------------------------------------------------------\n")
println("$innovationRateIncumbent (Incumbents)")
println("$entryRateOrdinary (Entrants)")
println("$entryRateSpinouts (Spinouts)")
println("$entryRateTotal (Entrants + Spinouts)")

internalInnovationShare = innovationRateIncumbent / (innovationRateIncumbent + entryRateTotal)
println("\n--------------------------------------------------------------")
println("Internal vs. External Contributions to Innovations------------")
println("--------------------------------------------------------------\n")
println("$internalInnovationShare (Internal share)")
println("$(1-internalInnovationShare) (External share)")

spinoutFraction = entryRateSpinouts / entryRateTotal
println("\n--------------------------------------------------------------")
println("Makeup of firms-----------------------------------------------")
println("--------------------------------------------------------------\n")
println("$spinoutFraction (Steady state fraction firms that started as spinouts)")


aggregateSales = finalGoodsLabor
aggregateRDSpending = sum(w .* z .* γ .* μ .* Δm)
aggregateRDSalesRatio = aggregateRDSpending / aggregateSales
println("\n--------------------------------------------------------------")
println("R&D Intensity-------------------------------------------------")
println("--------------------------------------------------------------\n")
println("$aggregateRDSalesRatio (Total R&D spending / Total revenue from sales of intermediate goods)\n")



println("\n--------------------------------------------------------------")
println("NON-TARGETED MOMENTS--------------------------------------------")
println("--------------------------------------------------------------\n")



growthContribution_incumbent = (modelPar.λ - 1) * sum(τI .* γ .* μ .* Δm)
growthContribution_entrants = (modelPar.λ - 1) * sum(τE .* γ .* μ .* Δm)
growthContribution_spinouts = (modelPar.λ - 1) * sum(τS .* γ .* μ .* Δm)

# Sanity check
totalGrowth = growthContribution_incumbent + growthContribution_entrants + growthContribution_spinouts

growthShare_incumbent = growthContribution_incumbent / totalGrowth
growthShare_entrants = growthContribution_entrants / totalGrowth
growthShare_spinouts = growthContribution_spinouts / totalGrowth

println("\n--------------------------------------------------------------")
println("Growth contributions--------------------------------------------")
println("--------------------------------------------------------------\n")
println("$growthContribution_incumbent (Growth due to incumbents)\n")
println("$growthContribution_entrants (Growth due to ordinary entrants)\n")
println("$growthContribution_spinouts (Growth due to spinouts)\n")

println("\n--------------------------------------------------------------")
println("Growth shares---------------------------------------------------")
println("--------------------------------------------------------------\n")
println("$growthShare_incumbent (Growth share: incumbents)\n")
println("$growthShare_entrants (Growth share: ordinary entrants)\n")
println("$growthShare_spinouts (Growth share: spinouts)\n")

#--------------------------------#
# Make some plots                #
#--------------------------------#

include("plotScript.jl")

#include("presentationPlots.jl")