#---------------------------#
# Plot V,W,zI,zS/m
#---------------------------#

Plots.scalefontsizes(0.8)

Plots.scalefontsizes(0.8)
p = plot(mGrid,[V[:] W[:] zI[:] zS[:]], legend = :bottomright, title = ["Incumbent value" "Spinout value" "Incumbent policy" "Aggregated spinout policy"], xlabel = "Mass of spinouts", label = ["V(m)" "W(m)" "z_I(m)" "z_S(m)"], layout = (2,2))
savefig(p,"figures/plotsGR/HJB_solutions_plot.pdf")
savefig(p,"figures/plotsGR/HJB_solutions_plot.png")
Plots.scalefontsizes(0.8^(-1))
#---------------------------#
# Plot V and m * W(m) , aggregate spinout value
#---------------------------#

p = plot(mGrid,[V[:] mGrid[:].*W[:]], title = "Incumbent and aggregate high-type entrant values", ylabel = "Value", xlabel = "Mass of spinouts", label = ["V(m)" "W(m) * m"])
png("figures/plotsGR/Incumbent_AggSpinout_Values.png")

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



err = (r .+ τSE) .* V .- Π .- ν * aTotal .* Vprime .- zI .* (χI .* ϕI(zI) .* (λ .* V[1] .- V) .- (w .* (1 .- noncompete) + wNC .* noncompete ))
err2 = (r .+ τSE) .* V1 .- Π .- ν * aTotal .* V1prime .- zI .* (χI .* ϕI(zI) .* (λ .* V1[1] .- V1) .- (w .* (1 .- noncompete) + wNC .* noncompete ))

p = plot(mGrid,[[err[:] err2[:]]], title = ["HJB error 1" "HJB error 2"], label = ["Error" "Error"], layout = (2,1))
png("figures/plotsGR/HJB_tests.png")

#----------------------------------------#
# Plot innovation hazard rates
#----------------------------------------#

if modelPar.CNC == true
    p = plot(mGrid,[τI[:] τS[:] τE[:] (τS[:] + τE[:]) τ[:]], legend = :topleft, layout = (1), xlabel = "Mass of spinouts", ylabel = "Yearly hazard rate of innovation", title = "Noncompetes", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Ordinary entrants + spinouts" "Total"])
else
    p = plot(mGrid,[τI[:] τS[:] τE[:] (τS[:] + τE[:])  τ[:]], legend = :topleft, layout = (1), xlabel = "Mass of spinouts", ylabel = "Yearly hazard rate of innovation", title = "Innovation rates", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Ordinary entrants + spinouts" "Total"])
end
savefig(p,"figures/plotsGR/innovation_rates_m.pdf")
savefig(p,"figures/plotsGR/innovation_rates_m.png")


if modelPar.CNC == true
    p = plot(t,[τI[:] τS[:] τE[:] τ[:]], legend = :topleft, layout = (1), xlabel = "Years since last innovation", ylabel = "Yearly hazard rate of innovation", title = "Noncompetes", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Total"])
else
    p = plot(t,[τI[:] τS[:] τE[:] τ[:]], layout = (1), xlabel = "Years since last innovation", ylabel = "Yearly hazard rate of innovation", title = "Innovation hazard rates", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Total"])
end
savefig(p,"figures/plotsGR/innovation_rates_t.pdf")
savefig(p,"figures/plotsGR/innovation_rates_t.png")

#-----------------------------------------#
# Plot wage
#-----------------------------------------#


wbars = ones(size(mGrid)) * EndogenousGrowthWithSpinouts.Cβ(β)
p = plot(mGrid, [w wbars], title = "Wages", legend = :bottomright, linestyle = [:dash :solid], label = ["R&D wage (incumbents)" "Production wage"], xlabel = "Mass of spinouts", ylabel = "Units of final consumption")
savefig(p,"figures/plotsGR/wages_m.pdf")
savefig(p,"figures/plotsGR/wages_m.png")



if modelPar.CNC == true
    p = plot(t, [w wageSpinouts wageEntrants (wNC - (1-θ) * (1-modelPar.ζ)*ν*W) wbars], title = "Noncompetes", linestyle = [:dash :dash :dash :solid :solid], legend = :bottomright, label = ["R&D wage (incumbents)" "R&D wage (spinouts)" "R&D wage (entrants)" "Production wage minus employee flow value of knowledge" "Production wage"], xlabel = "Years since last innovation", ylabel = "Units of final consumption")
else
    p = plot(t, [w wbars], title = "Baseline", linestyle = [:dash :solid], legend = :bottomright, label = ["R&D wage (incumbents)" "Production wage"], xlabel = "Years since last innovation", ylabel = "Units of final consumption")
end
savefig(p,"figures/plotsGR/wages_t.pdf")
savefig(p,"figures/plotsGR/wages_t.png")



#-----------------------------------------#
# Plot a(m)
#-----------------------------------------#

p = plot(mGrid,ν * aTotal, title = "Eq. drift in m-space", label = "a(m)", xlabel = "Mass of spinouts", ylabel = "Expected mass of spinouts formed per year")
savefig(p,"figures/plotsGR/drift.pdf")
savefig(p,"figures/plotsGR/drift.png")

#-----------------------------------------#
# Plot aI(m),aE(m),aS(m)
#-----------------------------------------#
aI = (1-θ) * ν * zI .* (1 .- noncompete)
aS = (1-θ) * sFromS * ν * zS
aE = (1-θ) * sFromE * ν * zE

if modelPar.CNC == true
    p = plot(ξ*mGrid,[ξ*ν*a ξ*aI ξ*aS ξ*aE ξ*(aI + aS + aE + ν * aBar * ones(size(mGrid))) ξ * ν *  aBarIncumbents * ones(size(mGrid)) ξ * (aBar - aBarIncumbents) * ones(size(mGrid))], title = "Noncompetes", label = ["a(m)" "Incumbent" "Spinouts" "Entrants" "checksum" "Incumbent NC" "Spinouts NC"], xlabel = "Effective mass of spinouts (m * xi)", ylabel = "Effective mass of spinouts per year")
else
    p = plot(ξ*mGrid,[ξ*ν*a ξ*aI ξ*aS ξ*aE ξ*(aI + aS + aE + ν * aBar * ones(size(mGrid))) ξ * ν *  aBarIncumbents * ones(size(mGrid)) ξ * (aBar - aBarIncumbents) * ones(size(mGrid))], title = "Baseline", label = ["a(m)" "Incumbent" "Spinouts" "Entrants" "checksum" "Incumbent NC" "Spinouts NC"], xlabel = "Effective mass of spinouts (m * xi)", ylabel = "Effective mass of spinouts per year")
end
png("figures/plotsGR/drift_sources_m.png")


if modelPar.CNC == true
    p = plot(t,[ξ*ν*a ξ*aI ξ*aS ξ*aE ξ * (aI + aS + aE + ν * aBar * ones(size(mGrid))) ξ * ν * aBarIncumbents * ones(size(mGrid)) ξ * (aBar - aBarIncumbents) * ones(size(mGrid))], xlims = (0,35), title = "Noncompetes", label = ["a(m)" "Incumbent" "Spinouts" "Entrants" "checksum" "Incumbent NC" "Spinouts NC"], xlabel = "Years since last innovation", ylabel = "Effective mass of spinouts per year")
else
    p = plot(t,[ξ*ν*a ξ*aI ξ*aS ξ*aE ξ * (aI + aS + aE + ν * aBar * ones(size(mGrid))) ξ * ν * aBarIncumbents * ones(size(mGrid)) ξ * (aBar - aBarIncumbents) * ones(size(mGrid))], title = "Baseline", label = ["a(m)" "Incumbent" "Spinouts" "Entrants" "checksum" "Incumbent NC" "Spinouts NC"], xlabel = "Years since last innovation", ylabel = "Effective mass of spinouts per year")
end

png("figures/plotsGR/drift_sources_t.png")



#-----------------------------------------#
# Plot the construction of μ(m)
#-----------------------------------------#

integrand =  (ν .* aPrime .+ τ) ./ (ν .* a)
summand = integrand .* Δm
integral = cumsum(summand[:])

p = plot(mGrid,[μ integrand summand integral], label = ["\\mu\\(m\\)" "integrand" "summand" "integral"], layout = (2,2), legend = :bottomright)
png("figures/plotsGR/mushape.png")

#-----------------------------------------#
# Plot μ(m),γ(m),t(m)
#-----------------------------------------#

Plots.scalefontsizes(0.8)

p = plot(mGrid, [μ γ t], label = ["\\mu\\(m\\)" "\\Gamma\\(m\\)" "s(m)"], ylabel = ["Density" "Quality (relative)" "Years"], xlabel = "Mass of spinouts", layout = (3,1))
savefig(p,"figures/plotsGR/gamma_t_mu_vs_m_plots.pdf")
savefig(p,"figures/plotsGR/gamma_t_mu_vs_m_plots.png")


#-----------------------------------------#
# Plot μ(t),γ(t),m(t)
#-----------------------------------------#

if modelPar.CNC == true
    p = plot(t, [μ .* ν .* a γ], xlims = (0,35), label = ["\\mu\\(t\\)" "\\Gamma\\(t\\)"], title = "Noncompetes", ylabel = ["Density" "Quality (relative)"], xlabel = "Years since last innovation", layout = (2,1))
else
    p = plot(t, [μ .* ν .* a γ], xlims = (0,35), label = ["\\mu\\(t\\)" "\\Gamma\\(t\\)"], title = "Baseline", ylabel = ["Density" "Quality (relative)"], xlabel = "Years since last innovation", layout = (2,1))
end

savefig(p, "figures/plotsGR/gamma_t_mu_vs_t_plots.pdf")
savefig(p, "figures/plotsGR/gamma_t_mu_vs_t_plots.png")


Plots.scalefontsizes(0.8^(-1))

if modelPar.CNC == true
    p = plot(t, μ .* ν .* a, xlims = (0,35), ylims = (0,0.35), label = "\\mu\\(t\\)", title = "Noncompetes", ylabel = "Density", xlabel = "Years since last innovation")
else
    p = plot(t, μ .* ν .* a, xlims = (0,35), ylims = (0,0.35), label = "\\mu\\(t\\)", title = "Baseline", ylabel = "Density", xlabel = "Years since last innovation")
end

savefig(p,"figures/plotsGR/mu_vs_t_plots.png")
savefig(p,"figures/plotsGR/mu_vs_t_plots.pdf")




#-----------------------------------------#
# Plot "effective R&D wage" vs m :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

p = plot(mGrid, [(1-θ) * ν*V1prime (1-θ) * ν*(1-ζ) *  W (1-θ) * ν*(V1prime .+ (1-ζ) *W)], label = ["Firm" "R&D employee" "Net"], title = "Flow value of knowledge transfer", xlabel = "Mass of spinouts", ylabel = "Value", legend = :bottomright)
savefig(p,"figures/plotsGR/effectiveRDWage_vs_m.pdf")
savefig(p,"figures/plotsGR/effectiveRDWage_vs_m.png")

#-----------------------------------------#
# Plot "effective R&D wage"  vs t :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

p = plot(t, [(1-θ) * ν*V1prime (1-θ) * ν*(1-ζ) *  W (1-θ) * ν*(V1prime .+ (1-ζ) *W)], label = ["Firm" "Employee" "Net"], title = "Knowledge spillover", xlabel = "Years since last innovation", ylabel = "Value", legend = :bottomright)
savefig(p,"figures/plotsGR/effectiveRDWage_vs_t.pdf")
savefig(p,"figures/plotsGR/effectiveRDWage_vs_t.png")

#-----------------------------------------#
# Plot decomposition of difference in R\&D spending
# versus m
#-----------------------------------------#

χE = modelPar.χE
κ = modelPar.κ
relativeProductivity = χE / χI
businessStealing = λ / (λ - 1) * ones(size(V))
creativeDestructionCost = (1-κ) * ones(size(V))
DRS = 1/(1-modelPar.ψI) * ones(size(V))
wageDifference = w ./ wageEntrants
cannibalizationBySpinouts = (w .- (1-θ) * ν * min.(V1prime,0)) ./ w  # min to avoid some instabilities - in equilibrium, V is strictly decreasing anyway.
nonCompetesEffect = (wNC .* noncompete) ./ (w .- (1-θ) * ν * min.(V1prime,0)) + (1 .- noncompete)
escapeCompetition = max.(ones(size(V)) * (λ * V[1] - V[1]) ./ (λ * V[1] * ones(size(V)) - V),0)  #max to avoid instabilities, see above
total = relativeProductivity .* businessStealing .* creativeDestructionCost .* DRS .* wageDifference .* cannibalizationBySpinouts .* nonCompetesEffect .* escapeCompetition
real = ((zE + zS) ./ zI).^(ψI)

p = plot(t,[total real],label = ["Aggregated decomp." "Actual model"], title = "Check-sum of decomposition")
png("figures/plotsGR/diagnostics/zEzIRatioDecomp_checksum.png")

plotArray = [businessStealing creativeDestructionCost DRS wageDifference cannibalizationBySpinouts nonCompetesEffect escapeCompetition]
labels = ["Business stealing" "creativeDestructionCost" "DRS" "Wage ratio" "Cannibalization by spinouts" "Noncompetes effect" "Escape competition"]
p = plot(t,plotArray, label = labels)
png("figures/plotsGR/diagnostics/zEzIRatioDecomp.png")

#-----------------------------------------#
# Non-compete usage
#-----------------------------------------#

if modelPar.CNC == true

    p = plot(mGrid,noncompete,title = "Noncompete usage", xlabel = "Mass of spinouts", ylabel = "Usage = 1")
    savefig(p,"figures/plotsGR/noncompete_usage_m.pdf")
    savefig(p,"figures/plotsGR/noncompete_usage_m.png")

end

if modelPar.CNC == true
    p = plot(t,noncompete,title = "Noncompetes", xlabel = "Years since last innovation", ylabel = "Usage = 1")
else
    p = plot(t,noncompete,title = "Baseline", xlabel = "Years since last innovation", ylabel = "Usage = 1")
end

savefig(p,"figures/plotsGR/noncompete_usage_t.pdf")
savefig(p,"figures/plotsGR/noncompete_usage_t.png")


Plots.scalefontsizes(0.8^(-1))
