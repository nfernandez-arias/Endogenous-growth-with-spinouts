

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




mass_spinoutsFromIncumbents = zeros(size(mGrid))
mass_spinoutsFromSpinouts = zeros(size(mGrid))
mass_spinoutsFromEntrants = zeros(size(mGrid))

fraction_spinoutsFromIncumbents = zeros(size(mGrid))
fraction_spinoutsFromSpinouts = zeros(size(mGrid))
fraction_spinoutsFromEntrants = zeros(size(mGrid))

for i = 2:length(mGrid)

    mass_spinoutsFromIncumbents[i] = ν * sum( zI[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])
    mass_spinoutsFromSpinouts[i] = sFromS * ν * sum( zS[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])
    mass_spinoutsFromEntrants[i] = sFromE * ν * sum( zE[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])

end

totalMass = mass_spinoutsFromIncumbents + mass_spinoutsFromSpinouts + mass_spinoutsFromEntrants

# Leave the first index equal to zero - does not matter, since
# only using to compute integrals where it is multiplied by
# τS, and τS[1] = 0 as well.

fraction_spinoutsFromIncumbents[2:end] = mass_spinoutsFromIncumbents[2:end] ./ mGrid[2:end]
fraction_spinoutsFromSpinouts[2:end] = mass_spinoutsFromSpinouts[2:end] ./ mGrid[2:end]
fraction_spinoutsFromEntrants[2:end] = mass_spinoutsFromEntrants[2:end] ./ mGrid[2:end]

if noncompete[1] == 1
    innovationRateIncumbent = τI[1]
    entryRateOrdinary = τE[1]
    entryRateSpinouts = 0
else
    innovationRateIncumbent = sum(τI .* μ .* Δm)
    entryRateOrdinary = sum(τE .* μ .* Δm)
    entryRateSpinouts = sum(τS .* μ .* Δm)
    entryRateSpinoutsFromIncumbents = sum(fraction_spinoutsFromIncumbents .* τS .* μ .* Δm)
    entryRateSpinoutsFromSpinouts = sum(fraction_spinoutsFromSpinouts .* τS .* μ .* Δm)
    entryRateSpinoutsFromEntrants = sum(fraction_spinoutsFromEntrants .* τS .* μ .* Δm)
end




entryRateTotal = entryRateOrdinary + entryRateSpinouts

println("\n--------------------------------------------------------------")
println("Innovation rates----------------------------------------------")
println("--------------------------------------------------------------\n")
println("$innovationRateIncumbent (Incumbents)")
println("$entryRateTotal (Total - Entrants + All Spinouts)")
println("\nof which:\n")
println("$entryRateOrdinary (Entrants)")
println("$entryRateSpinouts (Spinouts)")
println("\nof which:\n")
println("$entryRateSpinoutsFromIncumbents (Spinouts from Incumbents)")
println("$entryRateSpinoutsFromSpinouts (Spinouts from Spinouts)")
println("$entryRateSpinoutsFromEntrants (Spinouts from Entrants)")
println("\nIn percentages:\n")
println("$(entryRateSpinoutsFromIncumbents / entryRateSpinouts) (Spinouts from Incumbents)")
println("$(entryRateSpinoutsFromSpinouts / entryRateSpinouts) (Spinouts from Spinouts)")
println("$(entryRateSpinoutsFromEntrants / entryRateSpinouts) (Spinouts from Entrants)")


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
wageEntrants = (modelPar.spinoutsFromEntrants * w + (1 - modelPar.spinoutsFromEntrants) * EndogenousGrowthWithSpinouts.wbarFunc(modelPar.β) * ones(size(mGrid)))

if noncompete[1] == 1
    aggregateRDSpending = wbar * z[1]
else
    incumbentRDSpending = sum(w .* zI .* γ .* μ .* Δm)
    incumbentRDSpending2 = sum(wageEntrants .* zI .* γ .* μ .* Δm)
    entrantRDSpending = sum(wageEntrants .* zE .* γ .* μ .* Δm)
    spinoutRDSpending = sum(wageSpinouts.* zS .* γ .* μ .* Δm)
    aggregateRDSpending = incumbentRDSpending + entrantRDSpending + spinoutRDSpending
end

aggregateRDSalesRatio = aggregateRDSpending / aggregateSales
incumbentRDSalesRatio = incumbentRDSpending / aggregateSales
incumbentRDSalesRatio2 = incumbentRDSpending2 / aggregateSales
entrantRDSalesRatio = entrantRDSpending / aggregateSales
spinoutRDSalesRatio = spinoutRDSpending / aggregateSales

println("\n--------------------------------------------------------------")
println("R&D Intensity-------------------------------------------------")
println("--------------------------------------------------------------\n")
println("$aggregateRDSalesRatio (Total R&D spending / Total revenue from sales of intermediate goods)\n")
println("$incumbentRDSalesRatio (Incumbent R&D spending / Total sales revenue from intermediate goods)\n")
println("$incumbentRDSalesRatio2 (Incumbent R&D spending (if paid spinout R&D wages) / Total sales revenue from intermediate goods)\n")
println("$entrantRDSalesRatio (Entrant R&D spending / Total sales revenue from intermediate goods)\n")
println("$spinoutRDSalesRatio (Spinout R&D spending / Total sales revenue from intermediate goods)\n")

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



#--------------------------------#
# Decomposing ratio of zI[1] and zE[1]
#--------------------------------#

VPrime2 = (V[3] - V[2]) / Δm[2]

χE = modelPar.χE
κ = modelPar.κ
relativeProductivity = χE / χI
businessStealing = λ / (λ - 1)
wageDifference = w[1] / wageEntrants[1]
cannibalizationBySpinouts = (w[1] - ν * VPrime2) / w[1]
total = (1-κ) * (1 / (1-modelPar.ψI)) * relativeProductivity * businessStealing * wageDifference * cannibalizationBySpinouts

println("\n--------------------------------------------------------------")
println("Difference in R&D effort ---------------------------------------")
println("--------------------------------------------------------------\n")
println("Relative productivity: $relativeProductivity")
println("Business stealing: $businessStealing")
println("Nominal wage ratio: $wageDifference")
println("Cannibalization by spinouts: $cannibalizationBySpinouts")
println("Total: $total")
println("Real: $((zE[1] / zI[1])^(modelPar.ψI))")


#include("presentationPlots.jl")
