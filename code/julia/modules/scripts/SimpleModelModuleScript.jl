# This file contains the code
# for plotting the solution to the simple expository model

using Plots
gr()

export solveSimpleModel, initializeSimpleModel, makePlots

mutable struct SimpleModelParameters

    ## General parameters
    #################
    # Discount rate
    ρ::Float64
    # IES
    θ::Float64
    # 1/(1-β) is markup
    β::Float64
    # Labor allocated to RD
    L::Float64

    ## Returns to R&D
    ##################
    # Scale
    χE::Float64
    χI::Float64
    # Curvature
    ψ::Float64
    # Step size of quality ladder
    λ::Float64

    ## Spinouts
    ###############

    # Knowledge spillover rate
    ν::Float64

    # Creative destruction deadweight loss discount
    κE::Float64

    ## Noncompetes

    # Noncompete enforcement cost
    κC::Float64

end

function initializeSimpleModel()

    ρ = 0.01
    θ = 2
    β = 0.06
    L = 0.05
    χE = 0.13
    χI = 3.5
    ψ = 0.5
    λ = 1.2
    ν = 0.3
    κE = 0.8
    κC = 0

    modelPar = SimpleModelParameters(ρ,θ,β,L,χE,χI,ψ,λ,ν,κE,κC)

    return modelPar

end

struct SimpleModelSolution

    # Incumbent value
    V::Float64
    # Incumbent RD effort
    zI::Float64
    # Incumbent innovation rate
    τI::Float64
    # Entrant RD effort
    zE::Float64
    # Entrant innovation rate
    τE::Float64
    # Spinout innovation rate
    τS::Float64
    # Noncompete usage
    x::Float64
    # RD wage (ignoring employee value from spinout)
    wRD_NCA::Float64
    # Interest rate
    r::Float64
    # Growth rate
    g::Float64
    # Output
    Y::Float64
    # Welfare
    W::Float64
    # Welfare 2 (not considering costs of entry or NCA enforcement)
    W2::Float64

end

function solveSimpleModel(modelPar::SimpleModelParameters)

    # Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψ = modelPar.ψ
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE
    κC = modelPar.κC

    # Compute final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # Compute x
    x = ((1 - (1-κE)*λ) > κC)

    denom = χI * (λ - 1) - x * ν * κC - (1-x) * ν * (1 - (1-κE)*λ)

    # Compute zE
    zE = ((χE * (1-κE) * λ)/ denom)^(1/ψ)

    # Compute τE
    τE = χE * zE^(1-ψ)

    # Compute zI
    zI = L - zE

    # Compute τI
    τI = χI * zI

    # Compute τS
    τS = ν * zI * (1-x)

    # Compute g
    g = (λ-1) * (τI + τS + τE)

    # Compute r
    r = θ*g + ρ

    # Compute profit
    π0 = Cβ(β)*(1-β) * LF

    # Compute V
    V = π0 / (r + τE)

    # Compute wage
    wRD_NCA = V * denom

    # Compute output
    Y = ((1-β)^(1-2*β)) / (β^(1-β)) * (1-L)

    # Compute welfare
    W = (Y - τE * κE * λ * V - x * zI * ν * κC * V - τS * κE * λ * V)^(1-θ) / ((1-θ) * ( ρ - g * (1-θ)))

    # Compute welfare
    W2 = (Y)^(1-θ) / ((1-θ)*( ρ - g * (1-θ)))

    sol = SimpleModelSolution(V,zI,τI,zE,τE,τS,x,wRD_NCA,r,g,Y,W,W2)

    return sol

end

function solveSimpleModel(κC::Float64,modelPar::SimpleModelParameters)

    modelPar.κC = κC

    sol = solveSimpleModel(modelPar)

    return sol

end

function makePlots(modelPar::SimpleModelParameters,string::String)

    κC_max = 2*(1 - (1-modelPar.κE)*modelPar.λ)
    κC_grid = 0:0.001:κC_max

    V = zeros(size(κC_grid))
    zI = zeros(size(κC_grid))
    τI = zeros(size(κC_grid))
    zE = zeros(size(κC_grid))
    τE = zeros(size(κC_grid))
    τS = zeros(size(κC_grid))
    x = zeros(size(κC_grid))
    wRD_NCA = zeros(size(κC_grid))
    r = zeros(size(κC_grid))
    g = zeros(size(κC_grid))
    Y = zeros(size(κC_grid))
    W = zeros(size(κC_grid))
    W2 = zeros(size(κC_grid))
    W3 = zeros(size(κC_grid))
    W4 = zeros(size(κC_grid))


    for i in 1:length(κC_grid)

        sol = solveSimpleModel(κC_grid[i],modelPar)

        V[i] = sol.V
        zI[i] = sol.zI
        τI[i] = sol.τI
        zE[i] = sol.zE
        τE[i] = sol.τE
        τS[i] = sol.τS
        x[i] = sol.x
        wRD_NCA[i] = sol.wRD_NCA
        r[i] = sol.r
        g[i] = sol.g
        Y[i] = sol.Y
        W[i] = sol.W
        W2[i] = sol.W2

        W3[i] = -((abs(W[i]) / abs(W[1])) - 1) * 100 * abs(1-modelPar.θ)
        W4[i] = -((abs(W2[i]) / abs(W2[1])) - 1) * 100 * abs(1-modelPar.θ)

    end

    Plots.scalefontsizes(0.6)
    fnt = Plots.font("sans-serif", 9)

    valuePlot = plot(κC_grid,V,title = "Incumbent value", xlabel = "\\kappa_c", label = "V", legend = false)
    #savefig(valuePlot,"figures/simpleModel/$(string)_V.pdf")

    p = plot(κC_grid,zI, title = "Incumbent R&D Effort", xlabel = "\\kappa_c", label = "\$z_I\$", legend = false)
    savefig(p,"figures/simpleModel/$(string)_zI.pdf")

    incumbentInnovationPlot = plot(κC_grid,τI, title = "Incumbent innovation rate", ylabel = "Innovations per year", xlabel = "\\kappa_c", label = "\$\\tau_I\$")
    #savefig(incumbentInnovationPlot,"figures/simpleModel/$(string)_tauI.pdf")

    p = plot(κC_grid,zE, title = "Entrant R&D Effort", xlabel = "\\kappa_c", label = "\$z_E\$")
    #savefig(p,"figures/simpleModel/$(string)_zE.pdf")

    entrantInnovationPlot = plot(κC_grid,τE, title = "Entrant innovation rate", ylabel = "Innovations per year", xlabel = "\\kappa_c", label = "\$\\tau_E\$")
    #savefig(entrantInnovationPlot,"figures/simpleModel/$(string)_tauE.pdf")

    spinoutInnovationPlot = plot(κC_grid,τS, title = "Spinout innovation rate", ylabel = "Innovations per year", xlabel = "\\kappa_c", label = "\$\\tau_S\$")
    #savefig(p,"figures/simpleModel/$(string)_tauS.pdf")

    innovationRatesPlot = plot(κC_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = "\\kappa_c", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    p = plot(κC_grid,x, title = "NCA usage", xlabel = "\\kappa_c", label = "x")
    #savefig(p,"figures/simpleModel/$(string)_NCA.pdf")

    wagePlot = plot(κC_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "\\kappa_c", label = ["Entrant" "Incumbent"])
    #savefig(p,"figures/simpleModel/$(string)_wageRD.pdf")

    interestRatePlot = plot(κC_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = "\\kappa_c", label = "r", legend = false)
    #savefig(p,"figures/simpleModel/$(string)_interestrate.pdf")

    growthPlot = plot(κC_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = "\\kappa_c", label = "g", legend = false)
    #savefig(growthPlot,"figures/simpleModel/$(string)_growth.pdf")

    #plot(κC_grid,W)
    #plot(κC_grid,W2)

    welfarePlot = plot(κC_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "\\kappa_{c}", label = "\$\\tilde{C}^*\$", legend = false)
    #savefig(welfarePlot,"figures/simpleModel/$(string)_CEwelfare.pdf")

    p = plot(κC_grid,W4, title = "CE Welfare chg.", ylabel = "% chg", xlabel = "(Cost of NCAs) (\\kappa_{c})", label = "\$\\tilde{C}^*\$")
    #savefig(p,"figures/simpleModel/$(string)_CEwelfare_nocosts.pdf")


    summaryPlot = plot(valuePlot,innovationRatesPlot,wagePlot,interestRatePlot,growthPlot,welfarePlot, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, size = (800,450))
    savefig(summaryPlot,"figures/simpleModel/$(string)_summaryPlot.pdf")
    Plots.scalefontsizes(0.6^(-1))
end
