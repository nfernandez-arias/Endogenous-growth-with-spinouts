#---------------------------#
# Plot V,W,zI,zS/m
#---------------------------#
Plots.scalefontsizes(0.9)
p = plot(mGrid,[V[:] W[:] zI[:] zS[:]], legend = :bottomright, title = ["Incumbent and Aggregate Spinout value" "Spinout value" "Incumbent policy" "Aggregated spinout policy"], xlabel = "Mass of spinouts", label = ["V(m)" "W(m)" "z_I(m)" "z_S(m)"], layout = (2,2))
png("figures/plotsGR/calibration_CNC/HJB_solutions_plot.png")
Plots.scalefontsizes(0.9^(-1))
#---------------------------#
# Plot V and m * W(m) , aggregate spinout value
#---------------------------#

p = plot(mGrid,[V[:] mGrid[:].*W[:]], title = "Incumbent and aggregate high-type entrant values", ylabel = "Value", xlabel = "Mass of spinouts", label = ["V(m)" "W(m) * m"])
png("figures/plotsGR/calibration_CNC/Incumbent_AggSpinout_Values.png")

#---------------------------#
# Plot HJB Error
#---------------------------#

err = zeros(size(mGrid))
V1 = copy(V)
Vprime = zeros(size(V))
V1prime = copy(Vprime)
#V1[1] = V1[2]

for i = 1:length(mGrid)-1

    Vprime[i] = (V[i+1] - V[i]) / Δm[i]
    V1prime[i] = (V1[i+1] - V1[i]) / Δm[i]

end

Vprime[end] = Vprime[end-1]
V1prime[end] = V1prime[end-1]
V1prime[1] = V1prime[2]

err = (ρ .+ τSE) .* V .- Π .- a .* ν .* Vprime .- zI .* (χI .* ϕI(zI) .* (λ .* V[1] .- V) .- w)
err2 = (ρ .+ τSE) .* V1 .- Π .- a .* ν .* V1prime .- zI .* (χI .* ϕI(zI) .* (λ .* V1[1] .- V1) .- w)

p = plot(mGrid,[[err[:] err2[:]]], title = ["HJB error 1" "HJB error 2"], label = ["Error" "Error"], layout = (2,1))
png("figures/plotsGR/calibration_CNC/HJB_tests.png")

#----------------------------------------#
# Plot innovation hazard rates
#----------------------------------------#

plot(mGrid,[τI[:] τS[:] τE[:] τ[:]], layout = (1), xlabel = "Mass of spinouts", ylabel = "Yearly hazard rate of innovation", title = "Hazard rates of innovation", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Total"])
png("figures/plotsGR/calibration_CNC/innovation_rates_m")

plot(t,[τI[:] τS[:] τE[:] τ[:]], layout = (1), xlabel = "Years since last innovation", ylabel = "Yearly hazard rate of innovation", title = "Hazard rates of innovation", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Total"])
png("figures/plotsGR/calibration_CNC/innovation_rates_t")

#-----------------------------------------#
# Plot wage
#-----------------------------------------#


wbars = ones(size(mGrid)) * EndogenousGrowthWithSpinouts.Cβ(β)
p = plot(mGrid, [w wageSpinouts wageEntrants (wbars - (1-modelPar.ζ)*ν*W) wbars], title = "Wages", legend = :bottomright, linestyle = [:dash :dash :dash :solid :solid], label = ["R&D wage (incumbents)" "R&D wage (spinouts)" "R&D wage (entrants)" "Production wage minus employee flow value of knowledge" "Production wage"], xlabel = "Mass of spinouts", ylabel = "Units of final consumption")
png("figures/plotsGR/calibration_CNC/wages_m.png")


p = plot(t, [w wageSpinouts wageEntrants (wbars - (1-modelPar.ζ)*ν*W) wbars], title = "Wages", linestyle = [:dash :dash :dash :solid :solid], legend = :bottomright, label = ["R&D wage (incumbents)" "R&D wage (spinouts)" "R&D wage (entrants)" "Production wage minus employee flow value of knowledge" "Production wage"], xlabel = "Years since last innovation", ylabel = "Units of final consumption")
png("figures/plotsGR/calibration_CNC/wages_t.png")



#-----------------------------------------#
# Plot a(m)
#-----------------------------------------#

p = plot(mGrid,ν * a, title = "Eq. drift in m-space", label = "a(m)", xlabel = "Mass of spinouts", ylabel = "Expected mass of spinouts formed per year")
png("figures/plotsGR/calibration_CNC/drift.png")

#-----------------------------------------#
# Plot aI(m),aE(m),aS(m)
#-----------------------------------------#
aI = ν * zI .* (1 .- noncompete)
aS = sFromS * ν * zS
aE = sFromE * ν * zE

p = plot(ξ*mGrid,[ξ*ν * a ξ*aI ξ*aS ξ*aE ξ*(aI + aS + aE)], title = "Eq. drift in m-space", label = ["a(m)" "Incumbent" "Spinouts" "Entrants" "checksum"], xlabel = "Effective mass of spinouts (m * xi)", ylabel = "Effective mass of spinouts per year")
png("figures/plotsGR/calibration_CNC/drift_sources_m.png")

p = plot(t,[ξ*ν * a ξ*aI ξ*aS ξ*aE ξ * (aI + aS + aE)], title = "Eq. drift in m-space", label = ["a(m)" "Incumbent" "Spinouts" "Entrants" "checksum"], xlabel = "Years since last innovation", ylabel = "Effective mass of spinouts per year")
png("figures/plotsGR/calibration_CNC/drift_sources_t.png")



#-----------------------------------------#
# Plot the construction of μ(m)
#-----------------------------------------#

integrand =  (ν .* aPrime .+ τ) ./ (ν .* a)
summand = integrand .* Δm
integral = cumsum(summand[:])

p = plot(mGrid,[μ integrand summand integral], label = ["\\mu\\(m\\)" "integrand" "summand" "integral"], layout = (2,2), legend = :bottomright)
png("figures/plotsGR/calibration_CNC/mushape.png")

#-----------------------------------------#
# Plot μ(m),γ(m),t(m)
#-----------------------------------------#

if maximum(noncompete) == 0 || idxCNC > 1

    p = plot(mGrid, [μ γ t], label = ["\\mu\\(m\\)" "\\gamma\\(m\\)" "t(m)"], ylabel = ["Density" "Quality (relative)" "Years"], xlabel = "Mass of spinouts", layout = (3,1))
    png("figures/plotsGR/calibration_CNC/gamma_t_μ_vs_m_plots.png")

end

#-----------------------------------------#
# Plot μ(t),γ(t),m(t)
#-----------------------------------------#

if maximum(noncompete) == 0 || idxCNC > 1

    p = plot(t, [μ .* ν .* a γ], label = ["\\mu\\(t\\)" "\\gamma\\(t\\)"], ylabel = ["Density" "Quality (relative)"], xlabel = "Years since last innovation", layout = (2,1))
    png("figures/plotsGR/calibration_CNC/gamma_t_μ_vs_t_plots.png")

end

#-----------------------------------------#
# Plot "effective R&D wage" vs m :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

p = plot(mGrid, [ν*V1prime ν*W ν*(V1prime .+ W)], label = ["Firm" "R&D employee" "Net"], title = "Flow value of knowledge transfer", xlabel = "Mass of spinouts", ylabel = "Value")
png("figures/plotsGR/calibration_CNC/effectiveRDWage_vs_m.png")

#-----------------------------------------#
# Plot "effective R&D wage"  vs t :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

p = plot(t, [ν*V1prime ν*W ν*(V1prime .+ W)], label = ["Firm" "R&D employee" "Net"], title = "Flow value of knowledge transfer", xlabel = "Years since last innovation", ylabel = "Value")
png("figures/plotsGR/calibration_CNC/effectiveRDWage_vs_t.png")

#-----------------------------------------#
# Plot decomposition of difference in R\&D spending
# versus m
#-----------------------------------------#

χE = modelPar.χE
κ = modelPar.κ
relativeProductivity = χE / χI
businessStealing = λ / (λ - 1)
wageDifference = w ./ wageEntrants
cannibalizationBySpinouts = (w .- ν * V1prime) ./ w
escapeCompetition = ones(size(V)) * (λ * V[1] - V[1]) ./ (λ * V[1] * ones(size(V)) - V)
total = (1-κ) * (1 / (1-modelPar.ψI)) .* relativeProductivity .* businessStealing .* wageDifference .* cannibalizationBySpinouts .* escapeCompetition
real = ((zE + zS) ./ zI).^(ψI)

p = plot(t,[total real],label = ["Aggregated decomp." "Actual model"], title = "Check-sum of decomposition")
png("figures/plotsGR/calibration_CNC/diagnostics/zEzIRatioDecomp_checksum.png")

plotArray = [log(businessStealing)*ones(size(V)) log.(wageDifference) log.(cannibalizationBySpinouts) log.(escapeCompetition)]
labels = ["Business stealing" "Wage ratio" "Cannibalization by spinouts" "Escape competition"]
p = plot(t,plotArray, label = labels)
png("figures/plotsGR/calibration_CNC/diagnostics/zEzIRatioDecomp.png")

#-----------------------------------------#
# Non-compete usage
#-----------------------------------------#

p = plot(mGrid,noncompete,title = "Noncompete usage", xlabel = "Mass of spinouts", ylabel = "Usage = 1")
png("figures/plotsGR/calibration_CNC/noncompete_usage_m.png")

p = plot(t,noncompete,title = "Noncompete usage", xlabel = "Years since last innovation", ylabel = "Usage = 1")
png("figures/plotsGR/calibration_CNC/noncompete_usage_t.png")
