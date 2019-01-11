

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
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/HJB_solutions_plot.png", 16inch, 8inch), p)

#---------------------------#
# V(m) + W(m) * m
#---------------------------#

Wagg = zeros(size(mGrid))
Wagg = W .* mGrid

df1 = DataFrame(x = mGrid[:], y = V[:], label = "V(m)")
df2 = DataFrame(x = mGrid[:], y = Wagg[:], label = "W(m)m")
df3 = DataFrame(x = mGrid[:], y = V[:] + Wagg[:], label = "V(m) + W(m)m")

df = vcat(df1,df2,df3)

p = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("Incumbent, Spinout and Total Values"), Guide.ColorKey(title = "Legend"), Theme(background_color = colorant"white"))

draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/Values.png", 16inch, 8inch), p)

#---------------------------#
# Plot HJB Error
#---------------------------#

err = zeros(size(mGrid))
V1 = copy(V)
#V1[1] = V1[2]

for i = 1:length(mGrid)-1

    Vprime = (V1[i+1] - V1[i]) / Δm[i]

    err[i] = (ρ + τSE[i]) * V1[i] - Π - a[i] * ν * Vprime - zI[i] * (χI * ϕI(zI[i]) * (λ * V1[1] - V1[i]) - w[i])

end

err2 = zeros(size(mGrid))
V1 = copy(V)
V1[1] = V[2]

for i = 1:length(mGrid)-1

    Vprime = (V1[i+1] - V1[i]) / Δm[i]

    err2[i] = (ρ + τSE[i]) * V1[i] - Π - a[i] * ν * Vprime - zI[i] * (χI * ϕI(zI[i]) * (λ * V1[1] - V1[i]) - w[i])

end


df1 = DataFrame(x = mGrid, y = err, label = "Raw test")
df2 = DataFrame(x = mGrid, y = err2, label = "Modified test")
df = vcat(df1,df2)

p = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.title("HJB tests"), Guide.ColorKey(title = "Test"), Theme(background_color = colorant"white"))
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/HJB_tests.png", 10inch, 5inch), p)



#----------------------------------------#
# Plot innovation arrival rates
#----------------------------------------#

# τ
df1 = DataFrame(x = mGrid[:], y = τE[:], label = "Entrants")
df2 = DataFrame(x = mGrid[:], y = τS[:], label = "Spinouts")
df3 = DataFrame(x = mGrid[:], y = τI[:], label = "Incumbent")
df4 = DataFrame(x = mGrid[:], y = τ[:], label = "Aggregate")
df = vcat(df1,df2,df3,df4)

p = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.ColorKey(title = "Legend"),Guide.title("Innovation Arrival Rates"), Guide.xlabel("m"),
                        Guide.ylabel("Annual Poisson intensity"),
                        Theme(background_color = colorant"white"))

draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/innovation_rates.png", 10inch, 5inch), p)


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
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/zS_zE_diagnostics.png", 10inch, 10inch), p)


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
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/wages.png", 10inch, 10inch), p)

#-----------------------------------------#
# Plot a(m)
#-----------------------------------------#

df = DataFrame(x = mGrid[:], y = ν * a[:], label = "a(m)")
p = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Equilibrium Rate of Drift in m-space"), Guide.ColorKey(title = "Legend"), Guide.xlabel("m"), Guide.ylabel("Rate"), Theme(background_color=colorant"white"))
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/drift.png", 10inch, 10inch), p)

#-----------------------------------------#
# Plot shape of μ(m) without change of variables
#-----------------------------------------#

integrand = (ν * aPrime + τ) ./ (ν * a)
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
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/muShape.png", 10inch, 10inch), p)


#-----------------------------------------#
# Plot shape of gamma(m) γ(m)
#-----------------------------------------#
