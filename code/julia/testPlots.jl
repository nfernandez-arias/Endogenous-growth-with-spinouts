

V = results.incumbent.V
idxM = results.finalGuess.idxM
w = results.finalGuess.w
wNC = results.finalGuess.wNC
wE = results.finalGuess.wE
g = results.finalGuess.g
L_RD = results.finalGuess.L_RD
driftNC = results.finalGuess.driftNC
zS = EndogenousGrowthWithSpinouts.zSFunc(algoPar,modelPar,idxM)
zE = EndogenousGrowthWithSpinouts.zEFunc(modelPar,results.incumbent,w,wE,zS)



μ = results.auxiliary.μ
γ = results.auxiliary.γ
t = results.auxiliary.t

    #plot(mGrid,zE)
#--------------------------------#
# Unpack - using unpackScript.jl
#--------------------------------#

include("unpackScript.jl")

#--------------------------------#
# Display solution
#--------------------------------#



idxCNC = findfirst( (noncompete .> 0)[:] )


println("\n--------------------------------------------------------------")
println("Growth and RD Labor Allocation--------------------------------")
println("--------------------------------------------------------------\n")
println("g: $g (growth rate) \nL_RD: $L_RD (labor allocation to R&D)")

mass_competingSpinoutsFromIncumbents = zeros(size(mGrid))
mass_competingSpinoutsFromSpinouts = zeros(size(mGrid))
mass_competingSpinoutsFromEntrants = zeros(size(mGrid))
mass_nonCompetingSpinoutsFromIncumbents = zeros(size(mGrid))
mass_nonCompetingSpinoutsFromSpinouts = zeros(size(mGrid))

fraction_competingSpinoutsFromIncumbents = zeros(size(mGrid))
fraction_competingSpinoutsFromSpinouts = zeros(size(mGrid))
fraction_competingSpinoutsFromEntrants = zeros(size(mGrid))
fraction_nonCompetingSpinoutsFromIncumbents = zeros(size(mGrid))
fraction_nonCompetingSpinoutsFromSpinouts = zeros(size(mGrid))

for i = 2:length(mGrid)

    mass_competingSpinoutsFromIncumbents[i] =  (1-θ) * ν * sum( (1 .- noncompete[1:i-1]) .* zI[1:i-1] .* ((ν*aTotal[1:i-1]).^(-1)) .* Δm[1:i-1])
    mass_competingSpinoutsFromSpinouts[i] = (1-θ) * sFromS * ν * sum( zS[1:i-1] .* ((ν*aTotal[1:i-1]).^(-1)) .* Δm[1:i-1])
    mass_competingSpinoutsFromEntrants[i] = (1-θ) * sFromE * ν * sum( zE[1:i-1] .* ((ν*aTotal[1:i-1]).^(-1)) .* Δm[1:i-1])

end

# Easier to compute because constant flow in
mass_nonCompetingSpinoutsFromIncumbents = ν * aBarIncumbents * t
mass_nonCompetingSpinoutsFromSpinouts = ν * (aBar - aBarIncumbents) * t

totalMass = mass_competingSpinoutsFromIncumbents + mass_competingSpinoutsFromSpinouts + mass_competingSpinoutsFromEntrants + mass_nonCompetingSpinoutsFromIncumbents + mass_nonCompetingSpinoutsFromSpinouts

# Leave the first index equal to zero - does not matter, since
# only using to compute integrals where it is multiplied by
# τS, and τS[1] = 0 as well.

fraction_competingSpinoutsFromIncumbents[2:end] = mass_competingSpinoutsFromIncumbents[2:end] ./ mGrid[2:end]
fraction_competingSpinoutsFromSpinouts[2:end] = mass_competingSpinoutsFromSpinouts[2:end] ./ mGrid[2:end]
fraction_competingSpinoutsFromEntrants[2:end] = mass_competingSpinoutsFromEntrants[2:end] ./ mGrid[2:end]
fraction_nonCompetingSpinoutsFromIncumbents[2:end] = mass_nonCompetingSpinoutsFromIncumbents[2:end] ./ mGrid[2:end]
fraction_nonCompetingSpinoutsFromSpinouts[2:end] = mass_nonCompetingSpinoutsFromSpinouts[2:end] ./ mGrid[2:end]

innovationRateIncumbent = sum(τI .* μ .* Δm)
entryRateOrdinary = sum(τE .* μ .* Δm)
entryRateSpinouts = sum(τS .* μ .* Δm)
entryRateCompetingSpinoutsFromSpinouts = sum(fraction_competingSpinoutsFromSpinouts .* τS .* μ .* Δm)
entryRateCompetingSpinoutsFromIncumbents = sum(fraction_competingSpinoutsFromIncumbents .* τS .* μ .* Δm)
entryRateCompetingSpinoutsFromEntrants = sum(fraction_competingSpinoutsFromEntrants .* τS .* μ .* Δm)
entryRateNonCompetingSpinoutsFromIncumbents = sum(fraction_nonCompetingSpinoutsFromIncumbents .* τS .* μ .* Δm)
entryRateNonCompetingSpinoutsFromSpinouts = sum(fraction_nonCompetingSpinoutsFromSpinouts .* τS .* μ .* Δm)

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
println("$entryRateCompetingSpinoutsFromIncumbents (Competing Spinouts from Incumbents)")
println("$entryRateCompetingSpinoutsFromSpinouts (Competing Spinouts from Spinouts)")
println("$entryRateCompetingSpinoutsFromEntrants (Competing Spinouts from Entrants)")
println("$entryRateNonCompetingSpinoutsFromIncumbents (Noncompeting Spinouts from Incumbents)")
println("$entryRateNonCompetingSpinoutsFromSpinouts (Noncompeting Spinouts from Spinouts)")
println("\nIn percentages:\n")
println("$(entryRateCompetingSpinoutsFromIncumbents / entryRateSpinouts) (Competing Spinouts from Incumbents)")
println("$(entryRateCompetingSpinoutsFromSpinouts / entryRateSpinouts) (Competing Spinouts from Spinouts)")
println("$(entryRateCompetingSpinoutsFromEntrants / entryRateSpinouts) (Competing Spinouts from Entrants)")
println("$(entryRateNonCompetingSpinoutsFromIncumbents / entryRateSpinouts) (Noncompeting Spinouts from Incumbents)")
println("$(entryRateNonCompetingSpinoutsFromSpinouts / entryRateSpinouts) (Noncompeting Spinouts from Spinouts)")


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

wageSpinouts = (sFromS * w + (1-sFromS) * EndogenousGrowthWithSpinouts.wbarFunc(modelPar.β) * ones(size(mGrid)))
wageEntrants = wE

incumbentRDSpending = sum((w.*(1 .- noncompete) + wNC .* noncompete) .* zI .* γ .* μ .* Δm)
incumbentRDSpending2 = sum(wageEntrants .* zI .* γ .* μ .* Δm)
entrantRDSpending = sum(wageEntrants .* zE .* γ .* μ .* Δm)
spinoutRDSpending = sum(wageSpinouts.* zS .* γ .* μ .* Δm)
aggregateRDSpending = incumbentRDSpending + entrantRDSpending + spinoutRDSpending

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

growthContribution_incumbent = (λ - 1) * sum(τI .* γ .* μ .* Δm)
growthContribution_entrants = (λ - 1) * sum(τE .* γ .* μ .* Δm)
growthContribution_spinouts = (λ - 1) * sum(τS .* γ .* μ .* Δm)

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
creativeDestructionCost = (1-κ)
DRS = (1 / (1-modelPar.ψI))
wageDifference = w[1]  / wageEntrants[1]
cannibalizationBySpinouts = (w[1] - (1-θ) * ν * VPrime2) / w[1]
nonCompetesEffect = (wNC[1] * noncompete[1]) / (w[1] - (1-θ) * ν * VPrime2) + (1 - noncompete[1])
total = relativeProductivity * businessStealing * creativeDestructionCost * DRS * wageDifference * cannibalizationBySpinouts * nonCompetesEffect

println("\n--------------------------------------------------------------")
println("Difference in R&D effort ---------------------------------------")
println("--------------------------------------------------------------\n")
println("Relative productivity: $relativeProductivity")
println("Business stealing: $businessStealing")
println("Creative destruction cost: $creativeDestructionCost")
println("Decreasing returns: $DRS")
println("Nominal wage ratio: $wageDifference")
println("Cannibalization by spinouts: $cannibalizationBySpinouts")
println("Noncompetes effect: $nonCompetesEffect")
println("Total: $total")
println("Real: $((zE[1] / zI[1])^(modelPar.ψI))")


#include("presentationPlots.jl")
