

#---------------------------#
# First plot! V,W,zI,zS/m
#---------------------------#

# Incumbent
p1 = plot(x = mGrid, y = V, Geom.line, Guide.xlabel("m"), Guide.ylabel("V"), Guide.title("Incumbent value V"), Theme(background_color=colorant"white"))
p2 = plot(x = mGrid, y = zI, Geom.line, Guide.xlabel("m"), Guide.ylabel("zI"), Guide.title("Incumbent RD effort zI"), Theme(background_color=colorant"white"))
p_incumbent = vstack(p1,p2)



# Spinout

#p1 = plot(x = mGrid, y = W, Geom.line, Guide.xlabel("m"), Guide.ylabel("W"), Guide.title("Individual spinout value W (density)"), Theme(background_color=colorant"white"))
p1 = plot(x = mGrid, y = W, Geom.line, Guide.xlabel("m"), Guide.ylabel("W"), Guide.title("Individual spinout value W (density)"), Theme(background_color=colorant"white"))


zS_density = zeros(size(zS))
zS_density[2:end] = (zS ./ mGrid)[2:end]
zS_density[1] = ξ

df1 = DataFrame(x = mGrid, y = zS_density[:], label = "zS(m) / m")
df2 = DataFrame(x = mGrid, y = zS[:], label = "zS(m)")
df = vcat(df1,df2)

p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.xlabel("x"), Guide.ylabel("zS(m) / m"), Guide.title("Individual spinout RD intensity (density)"), Theme(background_color=colorant"white"))
p_spinout = vstack(p1,p2)

# Print plot
p = hstack(p_incumbent,p_spinout)
draw(PNG("./figures/HJB_solutions_plot.png", 16inch, 8inch), p)

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

df = DataFrame(x = mGrid[:], y = err[:], label = "Raw test")
p1 = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("HJB tests"), Guide.ColorKey(title = "Raw Test"), Theme(background_color = colorant"white"))

df = DataFrame(x = mGrid[:], y = err2[:], label = "Modified test")
p2 = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("HJB tests"), Guide.ColorKey(title = "ModifiedTest"), Theme(background_color = colorant"white"))

p = vstack(p1,p2)

draw(PNG("./figures/HJB_tests.png", 10inch, 5inch), p)

#---------------------------#
# V(m) + W(m) * m
#---------------------------#

Wagg = zeros(size(mGrid))
Wagg = W .* mGrid

df1 = DataFrame(x = mGrid[:], y = V[:], label = "V(m)")
df2 = DataFrame(x = mGrid[:], y = Wagg[:], label = "W(m)m")
df3 = DataFrame(x = mGrid[:], y = V[:] + Wagg[:], label = "V(m) + W(m)m")

df = vcat(df1,df2,df3)

p1 = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("Incumbent, Spinout and Total Values: Levels"), Guide.ColorKey(title = "Legend"), Theme(background_color = colorant"white"))

Wprime = zeros(size(W))

for i = 1:length(mGrid)-1

    Wprime[i] = (W[i+1] - W[i]) / Δm[i]

end

Wprime[end] = Wprime[end-1]

df1 = DataFrame(x = mGrid[:], y = Vprime[:], label = "V'(m)")
df2 = DataFrame(x = mGrid[:], y = W[:] + mGrid[:] .* Wprime[:], label = "W(m) + mW'(m)")
df3 = DataFrame(x = mGrid[:], y = Vprime[:] + W[:] + mGrid[:] .* Wprime[:], label = "V'(m) + W(m) + mW'(m)")

df = vcat(df1,df2,df3)

p2 = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("Incumbent, Spinout and Total Values: Rate of change"), Guide.ColorKey(title = "Legend"), Theme(background_color = colorant"white"))

p = vstack(p1,p2)

draw(PNG("./figures/Values.png", 16inch, 8inch), p)

#----------------------------------------#
# Plot innovation arrival rates
#----------------------------------------#

# As function of m

df1 = DataFrame(x = mGrid[:], y = τI[:], label = "Incumbent")
df2 = DataFrame(x = mGrid[:], y = τS[:], label = "Spinouts")
df3 = DataFrame(x = mGrid[:], y = τE[:], label = "Entrants")
df4 = DataFrame(x = mGrid[:], y = τ[:], label = "Aggregate")


df = vcat(df1,df2,df3,df4)

p1 = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.ColorKey(title = "Legend"),Guide.title("Innovation Arrival Rates"), Guide.xlabel("m"),
                        Guide.ylabel("Annual Poisson intensity"),
                        Theme(background_color = colorant"white"))

# As function of time

df1 = DataFrame(x = t[:], y = τI[:], label = "Incumbent")
df2 = DataFrame(x = t[:], y = τS[:], label = "Spinouts")
df3 = DataFrame(x = t[:], y = τE[:], label = "Entrants")
df4 = DataFrame(x = t[:], y = τ[:], label = "Aggregate")

df = vcat(df1,df2,df3,df4)

p2 = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.ColorKey(title = "Legend"),Guide.title("Innovation Arrival Rates vs Time since last innovation"), Guide.xlabel("time t (years) since last innovation"),
                        Guide.ylabel("Annual Poisson intensity"),
                        Theme(background_color = colorant"white"))

p = vstack(p1,p2)


draw(PNG("./figures/innovation_rates.png", 10inch, 5inch), p)




#-----------------------------------------#
# Plot diagnostics for zS and zE: zSfactor, zEfactor
#-----------------------------------------#

# zS
df1 = DataFrame(x = mGrid[:], y = zS_density[:], label = "zS")
df2 = DataFrame(x = mGrid[:], y = zSfactor[:], label = "zSfactor")
df3 = DataFrame(x = mGrid[:], y = modelPar.ξ * ones(size(mGrid))[:], label = "ξ")
df = vcat(df1,df2,df3)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("zS/m and zSfactor"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("zS,zSfactor"), Theme(background_color=colorant"white"))

# zE
df1 = DataFrame(x = mGrid[:], y = zE[:], label = "zE")
df2 = DataFrame(x = mGrid[:], y = zEfactor[:], label = "zEfactor")
df = vcat(df1,df2)
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("zE and zEfactor"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("zE,zEfactor"), Theme(background_color=colorant"white"))

# Draw plot
p = vstack(p1,p2)
draw(PNG("./figures/zS_zE_diagnostics.png", 10inch, 10inch), p)


#-----------------------------------------#
# Plot wage
#-----------------------------------------#


# Non R&D wage
#wbar = (β^β)*(1-β)^(2-2*β);
wbar = AuxiliaryModule.Cβ(β)

df1 = DataFrame(x = mGrid[:], y = w[:], label = "RD wage")
df2 = DataFrame(x = mGrid[:], y = wbar * ones(size(mGrid[:])), label = "Production wage")

df = vcat(df1,df2)
p = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Wages"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Wage"), Theme(background_color=colorant"white"))
draw(PNG("./figures/wages.png", 10inch, 10inch), p)

#-----------------------------------------#
# Plot a(m)
#-----------------------------------------#

df = DataFrame(x = mGrid[:], y = ν * a[:], label = "νa(m)")
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Equilibrium Rate of Drift in m-space"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Rate"), Theme(background_color=colorant"white"))

df = DataFrame(x = t[:], y = ν * a[:], label = "νa(t)")
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Equilibrium Rate of Drift in t-space"), Guide.ColorKey(title = "Legend"), Guide.xlabel("t: years since last innovation"), Guide.ylabel("Rate"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)

draw(PNG("./figures/drift.png", 10inch, 10inch), p)

#-----------------------------------------#
# Plot the construction of μ(m)
#-----------------------------------------#

integrand =  (ν .* aPrime .+ τ) ./ (ν .* a)
summand = integrand .* Δm
integral = cumsum(summand[:])
μ = exp.(-integral)
μ = μ / sum(μ .* Δm)
df = DataFrame(x = mGrid[:], y = μ, label = "μ(m)")
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Density μ(m)"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Density"), Theme(background_color=colorant"white"))

df = DataFrame(x = mGrid[:], y = integrand[:], label = "integrand")
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("(ν * a'(m) + τ(m)) / (ν * a(m))"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Integrand"), Theme(background_color=colorant"white"))

p1 = vstack(p1,p2)

df = DataFrame(x = mGrid[:], y = summand[:], label = "summand")
p3 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Δm(m) * (ν * a'(m) + τ(m)) / (ν * a(m))"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Summand"), Theme(background_color=colorant"white"))

df = DataFrame(x = mGrid[:], y = integral[:], label = "integral")
p4 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("cumulative sum of Δm(m) * (ν * a'(m) + τ(m)) / (ν * a(m))"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Integral"), Theme(background_color=colorant"white"))

p2 = vstack(p3,p4)

p = hstack(p1,p2)
draw(PNG("./figures/muShape.png", 10inch, 10inch), p)


#-----------------------------------------#
# Plot μ(m),γ(m),t(m)
#-----------------------------------------#


df = DataFrame(x = mGrid[:], y = μ[:], label = "μ(m)")
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("μ(m) = density of products in state m"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("μ(m)"), Theme(background_color=colorant"white"))

df = DataFrame(x = mGrid[:], y = γ[:], label = "γ(m)")
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("γ(m) = E[q/qbar | m]"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("γ(m)"), Theme(background_color=colorant"white"))

df = DataFrame(x = mGrid[:], y = t[:], label = "t(m)")
p3 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("t(m) = equilibrium years to state m"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("t(m)"), Theme(background_color=colorant"white"))

p = vstack(p1,p2,p3)
draw(PNG("./figures/gamma_t_μ_vs_m_plots.png", 10inch, 10inch), p)

#-----------------------------------------#
# Plot μ(t),γ(t),m(t)
#-----------------------------------------#

df = DataFrame(x = t[:], y = μ[:] .* ν .* a[:], label = "μ(t)")
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Distribution of products by years since last innovation"), Guide.ColorKey(title = "Legend"), Guide.xlabel("t: years since last innovation"), Guide.ylabel("Density"), Theme(background_color=colorant"white"))

df = DataFrame(x = t[:], y = γ[:], label = "γ(t)")
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("γ(t) = E[q/Q | t]"), Guide.ColorKey(title = "Legend"), Guide.xlabel("t: years since last innovation"), Guide.ylabel("E[q/Q]"), Theme(background_color=colorant"white"))

df = DataFrame(x = t[:], y = mGrid[:], label = "m(t)")
p3 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Mass of workers capable of forming spinouts"), Guide.ColorKey(title = "Legend"), Guide.xlabel("t: years since last innovation"), Guide.ylabel("Mass of workers"), Theme(background_color=colorant"white"))

p = vstack(p1,p2,p3)
draw(PNG("./figures/gamma_m_μ_vs_t_plots.png", 10inch, 10inch), p)




#-----------------------------------------#
# Plot "effective R&D wage" vs m :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#
df1 = DataFrame(x = mGrid[:], y = ν * V1prime[:], label = "Incumbent: νV'(m)")
df2 = DataFrame(x = mGrid[:], y = ν * W[:], label = "Spinout: νW(m)")
df3 = DataFrame(x = mGrid[:], y = ν * (V1prime[:] .+ W[:]), label = "Bilateral: νW(m + νV'(m")
df = vcat(df1,df2,df3)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Flow value of knowledge transfer"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Value"), Guide.xlabel("m"), Theme(background_color=colorant"white"))

df1 = DataFrame(x = mGrid[:], y = wbar .* ones(size(w[:]))[:], label = "wbar = final goods wage")
df2 = DataFrame(x = mGrid[:], y = w[:], label = "w(m = wbar - νW(m = RD wage")
df3 = DataFrame(x = mGrid[:], y = w[:] - ν * V1prime[:], label = "w(m - νV'(m = effective RD wage")

df = vcat(df1,df2,df3)
p2 = plot(df, x = "x", y = "y", color = "label", Coord.Cartesian(ymin = 0), Geom.line, Guide.title("Wages"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Wage"), Guide.xlabel("m"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)
draw(PNG("./figures/effectiveRDWage_vs_m.png", 10inch, 10inch), p)

#-----------------------------------------#
# Plot "effective R&D wage"  vs t :
# i.e. plot w(m), V'(m) and w(m) - V'(m)
#-----------------------------------------#

df1 = DataFrame(x = t[:], y = ν * V1prime[:], label = "Incumbent: νV'(m(t))")
df2 = DataFrame(x = t[:], y = ν * W[:], label = "Spinout: νW(m(t))")
df3 = DataFrame(x = t[:], y = ν * (V1prime[:] .+ W[:]), label = "Bilateral: νW(m(t)) + νV'(m(t))")
df = vcat(df1,df2,df3)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Flow value of knowledge transfer"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Value"), Guide.xlabel("t: years since last innovation"), Theme(background_color=colorant"white"))

df1 = DataFrame(x = t[:], y = wbar .* ones(size(w[:]))[:], label = "wbar = final goods wage")
df2 = DataFrame(x = t[:], y = w[:], label = "w(m(t)) = wbar - νW(m(t)) = RD wage")
df3 = DataFrame(x = t[:], y = w[:] - ν * V1prime[:], label = "w(m(t)) - νV'(m(t)) = effective RD wage")

df = vcat(df1,df2,df3)
p2 = plot(df, x = "x", y = "y", color = "label", Coord.Cartesian(ymin = 0), Geom.line, Guide.title("Wages"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Wage"), Guide.xlabel("t: years since last innovation"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)
draw(PNG("./figures/effectiveRDWage_vs_t.png", 10inch, 10inch), p)
