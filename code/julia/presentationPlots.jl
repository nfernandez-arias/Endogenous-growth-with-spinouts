#---------------------------------
# Name: presentationPlots.jl
#
# Module containing scripts for making
# plots for presentation 3-7-2019
#

##---------------------------##
## Innovation Arrival Rates  ##
##---------------------------##

df1 = DataFrame(x = t[:], y = τI[:], label = "Incumbent")
df2 = DataFrame(x = t[:], y = τS[:], label = "Spinouts")
df3 = DataFrame(x = t[:], y = τE[:], label = "Entrants")
df4 = DataFrame(x = t[:], y = τ[:], label = "Aggregate")

df = vcat(df1,df2,df3,df4)

p = plot(df,x = "x", y = "y", color = "label", Geom.line, Guide.ColorKey(title = "Legend"),Guide.title("Innovation Arrival Rates vs Time since last innovation"), Guide.xlabel("time t (years) since last innovation"),
                        Guide.ylabel("Poisson intensity (annualized)"),
                        Theme(background_color = colorant"white", major_label_font_size = 18pt, minor_label_font_size = 12pt, key_label_font_size = 12pt))

draw(PNG("./figures/presentation/innovation_rates.png", 10inch, 5inch), p)

##---------------------------##
## Value functions ##
##---------------------------##

## Incumbent
p1 = plot(x = mGrid, y = V, Geom.line, Guide.xlabel("m"), Guide.ylabel("Value"), Guide.title("Incumbent value V"),
                Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))
p2 = plot(x = mGrid, y = zI, Geom.line, Guide.xlabel("m"), Guide.ylabel("Effort"), Guide.title("Incumbent RD effort zI"),
                Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))
p = hstack(p1,p2)

draw(PNG("./figures/presentation/plot_V_zI.png", 10inch, 5inch), p)


## Potential spinout
p1 = plot(x = mGrid, y = W, Geom.line, Guide.xlabel("m"), Guide.ylabel("Value"), Guide.title("Spinout value W (density)"),
                Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))
p2 = plot(x = mGrid, y = zS, Geom.line, Guide.xlabel("m"), Guide.ylabel("Effort"), Guide.title("Spinout RD effort zS (aggregate)"),
                Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))
p = hstack(p1,p2)

draw(PNG("./figures/presentation/plot_W_zSoverm.png", 10inch, 5inch), p)


##---------------------------##
## Stationary distribution μ and conditional mean γ
##---------------------------##

## vs. m

df = DataFrame(x = mGrid[:], y = μ[:], label = "μ(m)")
p1 = plot(df, x = "x", y = "y", Geom.line, Guide.title("Density of product lines in state m"), Guide.xlabel("m"), Guide.ylabel("μ(m)"),
            Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))

df = DataFrame(x = mGrid[:], y = γ[:], label = "γ(m)")
p2 = plot(df, x = "x", y = "y", Geom.line, Guide.title("E[q/Q|m]"), Guide.xlabel("m"), Guide.ylabel("γ(m)"),
            Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))

p = hstack(p1,p2)

draw(PNG("./figures/presentation/plot_mu_gamma_m.png", 10inch, 5inch), p)

## vs. t

df = DataFrame(x = t[:], y = μ[:] .* ν .* a[:], label = "μ(t)")
p1 = plot(df, x = "x", y = "y", Geom.line, Guide.title("Density of product lines t years since last innovation"), Guide.xlabel("t"), Guide.ylabel("μ(t)"),
            Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))

df = DataFrame(x = t[:], y = γ[:], label = "γ(t)")
p2 = plot(df, x = "x", y = "y", Geom.line, Guide.title("E[q/Q|t]"), Guide.xlabel("t"), Guide.ylabel("γ(t)"),
            Theme(background_color=colorant"white",major_label_font_size = 14pt, minor_label_font_size = 9pt, key_label_font_size = 9pt))

p = hstack(p1,p2)

draw(PNG("./figures/presentation/plot_mu_gamma_t.png", 10inch, 5inch), p)



##---------------------------##
## Effective R&D wage
##---------------------------##

df1 = DataFrame(x = t[:], y = wbar .* ones(size(w[:]))[:], label = "wbar = final goods wage")
df2 = DataFrame(x = t[:], y = w[:], label = "w(m(t)) = wbar - νW(m(t)) = RD wage")
df3 = DataFrame(x = t[:], y = w[:] - ν * V1prime[:], label = "w(m(t)) - νV'(m(t)) = effective RD wage")

df = vcat(df1,df2,df3)

#Coord.Cartesian(ymin = 0)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Effective RD wage"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Wage"), Guide.xlabel("t"),
                        Theme(background_color=colorant"white"))

df1 = DataFrame(x = t[:], y = ν * V1prime[:], label = "Incumbent: νV'(m(t))")
df2 = DataFrame(x = t[:], y = ν * W[:], label = "Spinout: νW(m(t))")
df3 = DataFrame(x = t[:], y = ν * (V1prime[:] .+ W[:]), label = "Bilateral: νW(m(t)) + νV'(m(t))")
df = vcat(df1,df2,df3)
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Value of knowledge transfer"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Knowledge value"), Guide.xlabel("t"),
                Theme(background_color=colorant"white"))

p = vstack(p1,p2)

draw(PNG("./figures/presentation/plot_effectiveRDWage_vs_t.png", 10inch, 7inch), p)




#draw(PNG("./figures/presentation/plot_flowValueKnowledgeTransfer.png", 10inch, 10inch), p)
