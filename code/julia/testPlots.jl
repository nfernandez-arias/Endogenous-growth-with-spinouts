
V = results.incumbent.V
idxM = results.finalGuess.idxM
w = results.finalGuess.w
zS = EndogenousGrowthWithSpinouts.zSFunc(algoPar,modelPar,idxM)
zE = EndogenousGrowthWithSpinouts.zEFunc(modelPar,results.incumbent,w,zS)

#plot(mGrid,zE)
#--------------------------------#
# Unpack - using unpackScript.jl
#--------------------------------#

include("unpackScript.jl")

#--------------------------------#
# Display solution
#--------------------------------#

g = results.finalGuess.g
L_RD = results.finalGuess.L_RD
μ = results.auxiliary.μ
γ = results.auxiliary.γ
t = results.auxiliary.t

idxCNC = findfirst( (noncompete .> 0)[:] )

println("\n--------------------------------------------------------------")
println("Growth and RD Labor Allocation--------------------------------")
println("--------------------------------------------------------------\n")
println("g: $g (growth rate) \nL_RD: $L_RD (labor allocation to R&D)")

if noncompete[1] == 1
    innovationRateIncumbent = τI[1]
    entryRateOrdinary = τE[1]
    entryRateSpinouts = 0
else
    innovationRateIncumbent = sum(τI .* μ .* Δm)
    entryRateOrdinary = sum(τE .* μ .* Δm)
    entryRateSpinouts = sum(τS .* μ .* Δm)
end

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

wageSpinouts = (modelPar.spinoutsFromSpinouts * w + (1 - modelPar.spinoutsFromSpinouts) * EndogenousGrowthWithSpinouts.wbarFunc(modelPar.β) * ones(size(mGrid)))
wageEntrants = EndogenousGrowthWithSpinouts.wbarFunc(modelPar.β) * ones(size(mGrid))

if noncompete[1] == 1
    aggregateRDSpending = wbar * z[1]
else
    incumbentRDSpending = sum(w .* zI .* γ .* μ .* Δm)
    entrantRDSpending = sum( wageEntrants .* zE .* γ .* μ .* Δm)
    spinoutRDSpending = sum(wageSpinouts.* zS .* γ .* μ .* Δm)
    aggregateRDSpending = incumbentRDSpending + entrantRDSpending + spinoutRDSpending
end

aggregateRDSalesRatio = aggregateRDSpending / aggregateSales
incumbentRDSalesRatio = incumbentRDSpending / aggregateSales

println("\n--------------------------------------------------------------")
println("R&D Intensity-------------------------------------------------")
println("--------------------------------------------------------------\n")
println("$aggregateRDSalesRatio (Total R&D spending / Total revenue from sales of intermediate goods)\n")
println("$incumbentRDSalesRatio (Incumbent R&D spending / Total sales revenue from intermediate goods)\n")


println("\n--------------------------------------------------------------")
println("NON-TARGETED MOMENTS--------------------------------------------")
println("--------------------------------------------------------------\n")


if noncompete[1] == 1
    growthContribution_incumbent = (λ - 1) * τI[1]
    growthContribution_entrants = (λ - 1) * τE[1]
    growthContribution_spinouts = 0
else
    growthContribution_incumbent = (λ - 1) * sum(τI .* γ .* μ .* Δm)
    growthContribution_entrants = (λ - 1) * sum(τE .* γ .* μ .* Δm)
    growthContribution_spinouts = (λ - 1) * sum(τS .* γ .* μ .* Δm)
end

# Sanity check
totalGrowth = growthContribution_incumbent + growthContribution_entrants + growthContribution_spinouts

growthShare_incumbent = growthContribution_incumbent / totalGrowth
growthShare_entrants = growthContribution_entrants / totalGrowth
growthShare_spinouts = growthContribution_spinouts / totalGrowth

#println("\n--------------------------------------------------------------")
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


#### Equilibrium evaluation

# Welfare
flowOutput = (((1-β) * wbar^(-1) )^(1-β))/(1-β) * L_F

if noncompete[1] == 1
    spinoutEntryCost = 0
else
    spinoutEntryCost = ζ * sum(τS .* γ .* μ .* Δm) * λ * V[1]
end

welfare = (flowOutput - spinoutEntryCost) / (ρ - g)
welfare2 = flowOutput / (ρ - g)

println("\n--------------------------------------------------------------")
println("Welfare---------------------------------------------------------")
println("--------------------------------------------------------------\n")
println("$welfare (Welfare)")
println("$welfare2 (Welfare with no deadweight loss of spinout entry)")

#--------------------------------#
# Make some plots                #
#--------------------------------#

include("plotScript.jl")


#include("presentationPlots.jl")
