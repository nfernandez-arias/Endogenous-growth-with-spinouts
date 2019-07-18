#---------------------------#
# Plot V,W,zI,zS/m
#---------------------------#

gr()
#Plots.scalefontsizes(1.2)
p = plot(mGrid,[V[:] W[:] zI[:] zS_density[:]], title = ["Incumbent value" "Spinout value" "Incumbent policy" "Spinout policy"], label = ["V(m)" "W(m)" "z_I(m)" "z_S(m) / m"], layout = (2,2))
png("figures/plotsGR/HJB_solutions_plot.png")

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
png("figures/plotsGR/HJB_tests.png")

#----------------------------------------#
# Plot innovation hazard rates
#----------------------------------------#

plot(mGrid,[τI[:] τS[:] τE[:] τ[:]], layout = (1), xlabel = "Mass of spinouts", ylabel = "Yearly hazard rate of innovation", title = "Hazard rates of innovation", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Total"])
png("figures/plotsGR/innovation_rates_m")

plot(t,[τI[:] τS[:] τE[:] τ[:]], layout = (1), xlabel = "Years since last innovation", ylabel = "Yearly hazard rate of innovation", title = "Hazard rates of innovation", label = ["Incumbent" "Spinouts" "Ordinary Entrants" "Total"])
png("figures/plotsGR/innovation_rates_t")

#-----------------------------------------#
# Plot wage
#-----------------------------------------#


wbar = AuxiliaryModule.Cβ(β)
p = plot(mGrid, [w[:] (ones(size(mGrid)) * wbar - ν * W) wbar * ones(size(mGrid))], title = "Wages", linestyle = [:solid :dash :solid], label = ["R&D wage" "Production wage minus flow value of knowledge" "Production wage"], xlabel = "Mass of spinouts", ylabel = "Units of final consumption")
png("figures/plotsGR/wages.png")

#-----------------------------------------#
# Plot a(m)
#-----------------------------------------#

p = plot(mGrid,a, title = "Eq. drift in m-space", label = "a(m)", xlabel = "Mass of spinouts", ylabel = "Expected mass of spinouts formed per year")
png("figures/plotsGR/drift.png")

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

p = plot(mGrid, [μ γ t], label = ["\\mu\\(m\\)" "\\gamma\\(m\\)" "t(m)"], title = "Stationary distributions and misc.", layout = (3,1))
png("figures/plotsGR/gamma_t_μ_vs_m_plots.png")

#-----------------------------------------#
# Plot μ(t),γ(t),m(t)
#-----------------------------------------#

p = plot(t, [μ .* ν .* a γ t], label = ["\\mu\\(m\\)" "\\gamma\\(m\\)" "t(m)"], title = "Stationary distributions and misc.", layout = (3,1))
png("figures/plotsGR/gamma_t_μ_vs_t_plots.png")

#-----------------------------------------#
# Plot "effective R&D wage" vs m :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

p = plot(mGrid, [ν*V1prime ν*W ν*(V1prime .+ W)], label = ["Firm" "R&D employee" "Net"], title = "Flow value of knowledge transfer", xlabel = "Mass of spinouts", ylabel = "Value")
png("figures/plotsGR/effectiveRDWage_vs_m.png")

#-----------------------------------------#
# Plot "effective R&D wage"  vs t :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

p = plot(t, [ν*V1prime ν*W ν*(V1prime .+ W)], label = ["Firm" "R&D employee" "Net"], title = "Flow value of knowledge transfer", xlabel = "Years since last innovation", ylabel = "Value")
png("figures/plotsGR/effectiveRDWage_vs_t.png")

#-----------------------------------------#
# Non-compete usage
#-----------------------------------------#

p = plot(mGrid,noncompete,title = "Noncompete usage", xlabel = "Mass of spinouts", ylabel = "Usage = 1")
png("figures/plotsGR/noncompete_usage_m.png")

p = plot(t,noncompete,title = "Noncompete usage", xlabel = "Years since last innovation", ylabel = "Usage = 1")
png("figures/plotsGR/noncompete_usage_t.png")
