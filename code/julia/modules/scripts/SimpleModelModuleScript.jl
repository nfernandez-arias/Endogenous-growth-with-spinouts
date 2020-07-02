# This file contains the code
# for plotting the solution to the simple expository model

using Plots, Measures
gr()

export SimpleModelParameters, SimpleModelSolution, solveSimpleModel, computeWelfareComparison, initializeSimpleModel, makePlots, makePlotsRDSubsidy, makePlotsKappaCRDSubsidy, makePlotsEntryTax, makePlotsRDSubsidyTargeted, makePlotsALL
export SimpleCalibrationTarget,SimpleCalibrationParameters,SimpleModelMoments,SimpleModelParameterLimit,SimpleModelParameterLimitList,welfareComparison

mutable struct SimpleModelParameters

    ## General parameters
    #################
    # Discount rate
    ρ::Real
    # IES
    θ::Real
    # 1/(1-β) is markup
    β::Real
    # Labor allocated to RD
    L::Real

    ## Returns to R&D
    ##################
    # Scale
    χE::Real
    χI::Real
    # Curvature
    ψ::Real
    # Step size of quality ladder
    λ::Real

    ## Spinouts
    ###############

    # Knowledge spillover rate
    ν::Real

    # Creative destruction deadweight loss discount
    κE::Real

    ## Noncompetes

    # Noncompete enforcement cost
    κC::Real

end

#Base.copy(modelPar::SimpleModelParameters) = SimpleModelParameters([ deepcopy(getfield(m, k)) for k = 1:length(fieldnames(typeof(modelPar))) ]...)

struct SimpleModelParameterLimit

    lower::Real
    upper::Real

end

struct SimpleModelParameterLimitList

    ρ::SimpleModelParameterLimit
    θ::SimpleModelParameterLimit
    β::SimpleModelParameterLimit
    χE::SimpleModelParameterLimit
    χI::SimpleModelParameterLimit
    ψ::SimpleModelParameterLimit
    λ::SimpleModelParameterLimit
    ν::SimpleModelParameterLimit
    κE::SimpleModelParameterLimit

end

function initializeSimpleModel()

    ρ = 0.0339999
    θ = 2
    β = 0.094
    L = 0.05
    χE = 0.11633
    χI = 1.85744
    ψ = 0.5
    λ = 1.165946
    ν = 0.04875
    κE = 0.7376
    κC = 0

    modelPar = SimpleModelParameters(ρ,θ,β,L,χE,χI,ψ,λ,ν,κE,κC)

    return modelPar

end

function Cβ(β::Real)

    return β^β * (1-β)^(1-2*β)

end

struct SimpleModelSolution

    # Incumbent value
    V::Real
    # Incumbent RD effort
    zI::Real
    # Incumbent innovation rate
    τI::Real
    # Entrant RD effort
    zE::Real
    # Entrant innovation rate
    τE::Real
    # Spinout innovation rate
    τS::Real
    # Noncompete usage
    x::Real
    # RD wage (ignoring employee value from spinout)
    wRD_NCA::Real
    # Interest rate
    r::Real
    # Growth rate
    g::Real
    # Output
    Y::Real
    # Final goods labor
    LF::Real
    # Entry cost
    entryCost::Real
    # NCA cost
    NCACost::Real
    # Consumption
    C::Real
    # Welfare
    W::Real
    # Welfare 2 (not considering costs of entry or NCA enforcement)
    W2::Real

end

function solveSimpleModel(κC::Real, T_RD::Real, T_E::Real, T_RD_I::Real, T_NCA::Real, modelPar::SimpleModelParameters)

    # Unpack parameT_Ers

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

    # CompuT_E final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # CompuT_E x
    x = ((1 - (1-T_RD-T_RD_I)*(1-(1+T_E)*κE)*λ) > κC + T_NCA)

    denom = χI * (λ - 1) - x * ν * (κC + T_NCA) - (1-x) * ν * (1 - (1 - T_RD - T_RD_I)*(1-(1+T_E)*κE)*λ)

    # CompuT_E zE,τE - robustness to zero value
    if (1+T_E)*κE < 1
        zE = min(L,((((1-T_RD - T_RD_I)/(1-T_RD))* χE * (1-(1+T_E)*κE) * λ)/ denom)^(1/ψ))
        τE = χE * zE^(1-ψ)
    else
        zE = 0
        τE = 0
    end
    # CompuT_E zI
    zI = max(0,L - zE)

    # CompuT_E τI
    τI = χI * zI

    # CompuT_E τS
    τS = ν * zI * (1-x)

    # CompuT_E g
    g = (λ-1) * (τI + τS + τE)

    # CompuT_E r
    r = θ*g + ρ

    # CompuT_E profit
    π0 = Cβ(β)*(1-β) * LF

    # CompuT_E V
    V = π0 / (r + τE)

    # CompuT_E wage
    if zE < L
        wRD_NCA = (V * denom) / (1-T_RD-T_RD_I)
    else
        wRD_NCA = (1-T_RD)^(-1) * χE * zE^(-ψ) * (1 - (1 + T_E) * κE ) *λ *  V
    end

    # CompuT_E final goods labor
    LF = (1 - L) / (1 + ( (1 - β) ./ Cβ(β))^(1/β))

    # CompuT_E output
    Y = ((1-β)^(1-2*β)) / (β^(1-β)) * LF

    # Entry cost

    entryCost = (τE + τS) * κE * λ * V

    # NCA cost

    NCACost = x * zI * ν * κC * V

    # Consumption
    C = Y - entryCost - NCACost

    # CompuT_E welfare
    W = (C)^(1-θ) / ((1-θ) * ( ρ - g * (1-θ)))

    # CompuT_E welfare
    W2 = (Y)^(1-θ) / ((1-θ)*( ρ - g * (1-θ)))

    sol = SimpleModelSolution(V,zI,τI,zE,τE,τS,x,wRD_NCA,r,g,Y,LF,entryCost,NCACost,C,W,W2)
    return sol

end

function solveSimpleModel(modelPar::SimpleModelParameters)

    sol = solveSimpleModel(modelPar.κC,0,0,0,0,modelPar)

    return sol

end

function solveSimpleModel(κC::Real,modelPar::SimpleModelParameters)

    sol = solveSimpleModel(κC,0,0,0,0,modelPar)

    return sol

end

function computeWelfare(modelPar::SimpleModelParameters)

    sol = solveSimpleModel(modelPar)

    return sol.W

end

function computeWelfareComparison(modelPar::SimpleModelParameters,κC0::Real,κC1::Real)

    modelParTemp = deepcopy(modelPar)

    sol0 = solveSimpleModel(κC0,modelParTemp)
    W0 = sol0.W

    sol1 = solveSimpleModel(κC1,modelParTemp)
    W1 = sol1.W

    out = -((abs(W1) / abs(W0)) - 1) * 100 / abs(1-modelParTemp.θ)

    return out

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
    entryCost = zeros(size(κC_grid))
    NCACost = zeros(size(κC_grid))
    C = zeros(size(κC_grid))
    W = zeros(size(κC_grid))
    W2 = zeros(size(κC_grid))
    W3 = zeros(size(κC_grid))
    W4 = zeros(size(κC_grid))

    Wbenchmark = solveSimpleModel(κC_max, 0, 0, 0, 0, modelPar).W

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
        entryCost[i] = sol.entryCost
        NCACost[i] = sol.NCACost
        C[i] = sol.C
        W[i] = sol.W
        W2[i] = sol.W2

        W3[i] = -((abs(W[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)
        W4[i] = -((abs(W2[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)

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

    effortPlot = plot(κC_grid,[zI zE], title = "Innovation effort", legend = :bottomright, xlabel = "\\kappa_c", label = ["Incumbent" "Entrant"])

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

    staticCostPlot = plot(κC_grid,[entryCost NCACost], title = "Entry and NCA costs", xlabel = "\\kappa_c", label = ["Entry cost" "NCA cost"])

    consumptionPlot = plot(κC_grid,C,title = "Consumption", xlabel = "\\kappa_c", legend = false)

    welfarePlot = plot(κC_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "\\kappa_{c}", label = "\$\\tilde{C}^*\$", legend = false)
    #savefig(welfarePlot,"figures/simpleModel/$(string)_CEwelfare.pdf")

    p = plot(κC_grid,W4, title = "CE Welfare chg.", ylabel = "% chg", xlabel = "(Cost of NCAs) (\\kappa_{c})", label = "\$\\tilde{C}^*\$")
    #savefig(p,"figures/simpleModel/$(string)_CEwelfare_nocosts.pdf")


    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, size = (800,750))
    savefig(summaryPlot,"figures/simpleModel/$(string)_summaryPlot.pdf")
    Plots.scalefontsizes(0.6^(-1))
end

function makePlotsRDSubsidy(modelPar::SimpleModelParameters,string::String)

    κC = 1.2*(1 - (1-modelPar.κE)*modelPar.λ)
    τRD_grid = -1:0.001:0.75

    V = zeros(size(τRD_grid))
    zI = zeros(size(τRD_grid))
    τI = zeros(size(τRD_grid))
    zE = zeros(size(τRD_grid))
    τE = zeros(size(τRD_grid))
    τS = zeros(size(τRD_grid))
    x = zeros(size(τRD_grid))
    wRD_NCA = zeros(size(τRD_grid))
    r = zeros(size(τRD_grid))
    g = zeros(size(τRD_grid))
    Y = zeros(size(τRD_grid))
    entryCost = zeros(size(τRD_grid))
    NCACost = zeros(size(τRD_grid))
    C = zeros(size(τRD_grid))
    W = zeros(size(τRD_grid))
    W2 = zeros(size(τRD_grid))
    W3 = zeros(size(τRD_grid))
    W4 = zeros(size(τRD_grid))

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    for i in 1:length(τRD_grid)

        sol = solveSimpleModel(κC,τRD_grid[i],0, 0, 0, modelPar)

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
        entryCost[i] = sol.entryCost
        NCACost[i] = sol.NCACost
        C[i] = sol.C
        W[i] = sol.W
        W2[i] = sol.W2

        W3[i] = -((abs(W[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)
        W4[i] = -((abs(W2[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)

    end

    Plots.scalefontsizes(0.6)
    fnt = Plots.font("sans-serif", 9)
    guideFont = Plots.font("sans-serif",11)

    valuePlot = plot(τRD_grid,V,title = "Incumbent value", xlabel = "\$T_{RD}\$", label = "V", legend = false)
    #savefig(valuePlot,"figures/simpleModel/$(string)_V.pdf")

    p = plot(τRD_grid,zI, title = "Incumbent R&D Effort", xlabel = "\$T_{RD}\$", label = "\$z_I\$", legend = false)
    savefig(p,"figures/simpleModel/$(string)_zI.pdf")

    incumbentInnovationPlot = plot(τRD_grid,τI, title = "Incumbent innovation rate", ylabel = "Innovations per year", xlabel = "\$T_{RD}\$", label = "\$\\tau_I\$")
    #savefig(incumbentInnovationPlot,"figures/simpleModel/$(string)_tauI.pdf")

    p = plot(τRD_grid,zE, title = "Entrant R&D Effort", xlabel = "\$T_{RD}\$", label = "\$z_E\$")
    #savefig(p,"figures/simpleModel/$(string)_zE.pdf")

    effortPlot = plot(τRD_grid,[zI zE], title = "Innovation effort", legend = :bottomright, xlabel = "\$T_{RD}\$", label = ["Incumbent" "Entrant"])

    entrantInnovationPlot = plot(τRD_grid,τE, title = "Entrant innovation rate", ylabel = "Innovations per year", xlabel = "\$T_{RD}\$", label = "\$\\tau_E\$")
    #savefig(entrantInnovationPlot,"figures/simpleModel/$(string)_tauE.pdf")

    spinoutInnovationPlot = plot(τRD_grid,τS, title = "Spinout innovation rate", ylabel = "Innovations per year", xlabel = "\$T_{RD}\$", label = "\$\\tau_S\$")
    #savefig(p,"figures/simpleModel/$(string)_tauS.pdf")

    innovationRatesPlot = plot(τRD_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = "\$T_{RD}\$", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    p = plot(τRD_grid,x, title = "NCA usage", xlabel = "\$T_{RD}\$", label = "x")
    #savefig(p,"figures/simpleModel/$(string)_NCA.pdf")

    wagePlot = plot(τRD_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "\$T_{RD}\$", label = ["Entrant" "Incumbent"])
    #savefig(p,"figures/simpleModel/$(string)_wageRD.pdf")

    interestRatePlot = plot(τRD_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = "\$T_{RD}\$", label = "r", legend = false)
    #savefig(p,"figures/simpleModel/$(string)_interestrate.pdf")

    growthPlot = plot(τRD_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = "\$T_{RD}\$", label = "g", legend = false)
    #savefig(growthPlot,"figures/simpleModel/$(string)_growth.pdf")

    staticCostPlot = plot(τRD_grid,[entryCost NCACost], title = "Entry and NCA costs", xlabel = "\$T_{RD}\$", label = ["Entry cost" "NCA cost"])

    consumptionPlot = plot(τRD_grid,C,title = "Consumption", xlabel = "\$T_{RD}\$", legend = false)

    welfarePlot = plot(τRD_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "\$T_{RD}\$", label = "\$\\tilde{C}^*\$", legend = false)
    #savefig(welfarePlot,"figures/simpleModel/$(string)_CEwelfare.pdf")


    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = guideFont, size = (800,750))
    savefig(summaryPlot,"figures/simpleModel/$(string)_RDSubsidy_summaryPlot.pdf")
    Plots.scalefontsizes(0.6^(-1))
end

function makePlotsEntryTax(modelPar::SimpleModelParameters,string::String)

    κC = 1.2*(1 - (1-modelPar.κE)*modelPar.λ)
    Te_grid = -0.5:0.001:0.5

    V = zeros(size(Te_grid))
    zI = zeros(size(Te_grid))
    τI = zeros(size(Te_grid))
    zE = zeros(size(Te_grid))
    τE = zeros(size(Te_grid))
    τS = zeros(size(Te_grid))
    x = zeros(size(Te_grid))
    wRD_NCA = zeros(size(Te_grid))
    r = zeros(size(Te_grid))
    g = zeros(size(Te_grid))
    Y = zeros(size(Te_grid))
    entryCost = zeros(size(Te_grid))
    NCACost = zeros(size(Te_grid))
    C = zeros(size(Te_grid))
    W = zeros(size(Te_grid))
    W2 = zeros(size(Te_grid))
    W3 = zeros(size(Te_grid))
    W4 = zeros(size(Te_grid))

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    for i in 1:length(Te_grid)

        sol = solveSimpleModel(κC,0,Te_grid[i],0,0,modelPar)

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
        entryCost[i] = sol.entryCost
        NCACost[i] = sol.NCACost
        C[i] = sol.C
        W[i] = sol.W
        W2[i] = sol.W2

        W3[i] = -((abs(W[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)
        W4[i] = -((abs(W2[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)

    end

    Plots.scalefontsizes(0.6)
    fnt = Plots.font("sans-serif", 9)
    guideFont = Plots.font("sans-serif",11)

    valuePlot = plot(Te_grid,V,title = "Incumbent value", xlabel = "\$T_e\$", label = "V", legend = false)
    #savefig(valuePlot,"figures/simpleModel/$(string)_V.pdf")

    p = plot(Te_grid,zI, title = "Incumbent R&D Effort", xlabel = "\$T_e\$", label = "\$z_I\$", legend = false)
    savefig(p,"figures/simpleModel/$(string)_zI.pdf")

    incumbentInnovationPlot = plot(Te_grid,τI, title = "Incumbent innovation rate", ylabel = "Innovations per year", xlabel = "\$T_e\$", label = "\$\\tau_I\$")
    #savefig(incumbentInnovationPlot,"figures/simpleModel/$(string)_tauI.pdf")

    p = plot(Te_grid,zE, title = "Entrant R&D Effort", xlabel = "\$T_e\$", label = "\$z_E\$")
    #savefig(p,"figures/simpleModel/$(string)_zE.pdf")

    effortPlot = plot(Te_grid,[zI zE], title = "Innovation effort", legend = :bottomright, xlabel = "\$T_e\$", label = ["Incumbent" "Entrant"])

    entrantInnovationPlot = plot(Te_grid,τE, title = "Entrant innovation rate", ylabel = "Innovations per year", xlabel = "\$T_e\$", label = "\$\\tau_E\$")
    #savefig(entrantInnovationPlot,"figures/simpleModel/$(string)_tauE.pdf")

    spinoutInnovationPlot = plot(Te_grid,τS, title = "Spinout innovation rate", ylabel = "Innovations per year", xlabel = "\$T_e\$", label = "\$\\tau_S\$")
    #savefig(p,"figures/simpleModel/$(string)_tauS.pdf")

    innovationRatesPlot = plot(Te_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = "\$T_e\$", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    p = plot(Te_grid,x, title = "NCA usage", xlabel = "\$T_e\$", label = "x")
    #savefig(p,"figures/simpleModel/$(string)_NCA.pdf")

    wagePlot = plot(Te_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "\$T_e\$", label = ["Entrant" "Incumbent"])
    #savefig(p,"figures/simpleModel/$(string)_wageRD.pdf")

    interestRatePlot = plot(Te_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = "\$T_e\$", label = "r", legend = false)
    #savefig(p,"figures/simpleModel/$(string)_interestrate.pdf")

    growthPlot = plot(Te_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = "\$T_e\$", label = "g", legend = false)
    #savefig(growthPlot,"figures/simpleModel/$(string)_growth.pdf")

    staticCostPlot = plot(Te_grid,[entryCost NCACost], title = "Entry and NCA costs", xlabel = "\$T_e\$", label = ["Entry cost" "NCA cost"])

    consumptionPlot = plot(Te_grid,C,title = "Consumption", xlabel = "\$T_e\$", legend = false)

    welfarePlot = plot(Te_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "\$T_e\$", label = "\$\\tilde{C}^*\$", legend = false)
    #savefig(welfarePlot,"figures/simpleModel/$(string)_CEwelfare.pdf")

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = guideFont, size = (800,750))
    savefig(summaryPlot,"figures/simpleModel/$(string)_EntryTax_summaryPlot.pdf")
    Plots.scalefontsizes(0.6^(-1))
end

function makePlotsRDSubsidyTargeted(modelPar::SimpleModelParameters,string::String)

    κC = 1.2*(1 - (1-modelPar.κE)*modelPar.λ)
    τRD_I_grid = -.8:0.001:0.8

    V = zeros(size(τRD_I_grid))
    zI = zeros(size(τRD_I_grid))
    τI = zeros(size(τRD_I_grid))
    zE = zeros(size(τRD_I_grid))
    τE = zeros(size(τRD_I_grid))
    τS = zeros(size(τRD_I_grid))
    x = zeros(size(τRD_I_grid))
    wRD_NCA = zeros(size(τRD_I_grid))
    r = zeros(size(τRD_I_grid))
    g = zeros(size(τRD_I_grid))
    Y = zeros(size(τRD_I_grid))
    entryCost = zeros(size(τRD_I_grid))
    NCACost = zeros(size(τRD_I_grid))
    C = zeros(size(τRD_I_grid))
    W = zeros(size(τRD_I_grid))
    W2 = zeros(size(τRD_I_grid))
    W3 = zeros(size(τRD_I_grid))
    W4 = zeros(size(τRD_I_grid))

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    for i in 1:length(τRD_I_grid)

        sol = solveSimpleModel(κC,0, 0, τRD_I_grid[i], 0, modelPar)

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
        entryCost[i] = sol.entryCost
        NCACost[i] = sol.NCACost
        C[i] = sol.C
        W[i] = sol.W
        W2[i] = sol.W2

        W3[i] = -((abs(W[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)
        W4[i] = -((abs(W2[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)

    end

    Plots.scalefontsizes(0.6)
    fnt = Plots.font("sans-serif", 9)
    fnt2 = Plots.font("sans-serif", 8)
    guideFont = Plots.font("sans-serif",11)

    valuePlot = plot(τRD_I_grid,V,title = "Incumbent value", xlabel = "\$T_{RD,I}\$", label = "V", legend = false)
    #savefig(valuePlot,"figures/simpleModel/$(string)_V.pdf")

    p = plot(τRD_I_grid,zI, title = "Incumbent R&D Effort", xlabel = "\$T_{RD,I}\$", label = "\$z_I\$", legend = false)
    savefig(p,"figures/simpleModel/$(string)_zI.pdf")

    incumbentInnovationPlot = plot(τRD_I_grid,τI, title = "Incumbent innovation rate", ylabel = "Innovations per year", xlabel = "\$T_{RD,I}\$", label = "\$\\tau_I\$")
    #savefig(incumbentInnovationPlot,"figures/simpleModel/$(string)_tauI.pdf")

    p = plot(τRD_I_grid,zE, title = "Entrant R&D Effort", xlabel = "\$T_{RD,I}\$", label = "\$z_E\$")
    #savefig(p,"figures/simpleModel/$(string)_zE.pdf")

    effortPlot = plot(τRD_I_grid,[zI zE], title = "Innovation effort", legend = :bottomright, xlabel = "\$T_{RD,I}\$", label = ["Incumbent" "Entrant"])

    entrantInnovationPlot = plot(τRD_I_grid,τE, title = "Entrant innovation rate", ylabel = "Innovations per year", xlabel = "\$T_{RD,I}\$", label = "\$\\tau_E\$")
    #savefig(entrantInnovationPlot,"figures/simpleModel/$(string)_tauE.pdf")

    spinoutInnovationPlot = plot(τRD_I_grid,τS, title = "Spinout innovation rate", ylabel = "Innovations per year", xlabel = "\$T_{RD,I}\$", label = "\$\\tau_S\$")
    #savefig(p,"figures/simpleModel/$(string)_tauS.pdf")

    innovationRatesPlot = plot(τRD_I_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = "\$T_{RD,I}\$", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    p = plot(τRD_I_grid,x, title = "NCA usage", xlabel = "\$T_{RD,I}\$", label = "x")
    #savefig(p,"figures/simpleModel/$(string)_NCA.pdf")

    wagePlot = plot(τRD_I_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "\$T_{RD,I}\$", label = ["Entrant" "Incumbent"])
    #savefig(p,"figures/simpleModel/$(string)_wageRD.pdf")

    interestRatePlot = plot(τRD_I_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = "\$T_{RD,I}\$", label = "r", legend = false)
    #savefig(p,"figures/simpleModel/$(string)_interestrate.pdf")

    growthPlot = plot(τRD_I_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = "\$T_{RD,I}\$", label = "g", legend = false)
    #savefig(growthPlot,"figures/simpleModel/$(string)_growth.pdf")

    staticCostPlot = plot(τRD_I_grid,[entryCost NCACost], title = "Entry and NCA costs", xlabel = "\$T_{RD,I}\$", label = ["Entry cost" "NCA cost"])

    consumptionPlot = plot(τRD_I_grid,C,title = "Consumption", xlabel = "\$T_{RD,I}\$", legend = false)

    welfarePlot = plot(τRD_I_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "\$T_{RD,I}\$", label = "\$\\tilde{C}^*\$", legend = false)
    #savefig(welfarePlot,"figures/simpleModel/$(string)_CEwelfare.pdf")


    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt, guidefont = guideFont, size = (800,750))
    savefig(summaryPlot,"figures/simpleModel/$(string)_RDSubsidyTargeted_summaryPlot.pdf")
    Plots.scalefontsizes(0.6^(-1))
end

function makePlotsALL(modelPar::SimpleModelParameters,string::String)

    κC = 1.2*(1 - (1-modelPar.κE)*modelPar.λ)

    κCmin = 0.5 * κC

    T_NCA_max = κC * 1.5

    T_RD_I_grid = 0:0.01:0.8
    T_NCA_grid = 0:0.01:T_NCA_max

    fnt = Plots.font("sans-serif", 9)
    fnt2 = Plots.font("sans-serif", 8)
    fnt3 = Plots.font("sans-serif", 8)
    guideFont = Plots.font("sans-serif",9)

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    valuePlot = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> solveSimpleModel(κCmin,0,0,x,y,modelPar).V,title = "Incumbent value", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = "V", legend = false)
    #savefig(valuePlot,"figures/simpleModel/$(string)_V.pdf")

    #p = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> makePlotsALL(κCmin,0,0,x,y,modelPar).zI, title = "Incumbent R&D Effort", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = "\$z_I\$", legend = false)
    #savefig(p,"figures/simpleModel/$(string)_zI.pdf")

    xPlot = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> solveSimpleModel(κCmin,0,0,x,y,modelPar).x,title = "Noncompete usage", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = "x", legend = false)

    #incumbentInnovationPlot = surface(T_RD_I_grid,T_NCA_grid,τI, title = "Incumbent innovation rate", ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = "\$\\tau_I\$")
    #savefig(incumbentInnovationPlot,"figures/simpleModel/$(string)_tauI.pdf")

    #p = surface(T_RD_I_grid,T_NCA_grid,zE, title = "Entrant R&D Effort", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = "\$z_E\$")
    #savefig(p,"figures/simpleModel/$(string)_zE.pdf")

    #effortPlot = surface(T_RD_I_grid,T_NCA_grid,[zI zE], title = "Innovation effort", legend = :bottomright, xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = ["Incumbent" "Entrant"])

    #entrantInnovationPlot = surface(T_RD_I_grid,T_NCA_grid,τE, title = "Entrant innovation rate", ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = "\$\\tau_E\$")
    #savefig(entrantInnovationPlot,"figures/simpleModel/$(string)_tauE.pdf")

    #spinoutInnovationPlot = surface(T_RD_I_grid,T_NCA_grid,τS, title = "Spinout innovation rate", ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = "\$\\tau_S\$")
    #savefig(p,"figures/simpleModel/$(string)_tauS.pdf")

    #innovationRatesPlot = surface(T_RD_I_grid,T_NCA_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    #p = surface(T_RD_I_grid,T_NCA_grid,x, title = "NCA usage", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = "x")
    #savefig(p,"figures/simpleModel/$(string)_NCA.pdf")

    #wagePlot = surface(T_RD_I_grid,T_NCA_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = ["Entrant" "Incumbent"])
    #savefig(p,"figures/simpleModel/$(string)_wageRD.pdf")

    interestRatePlot = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> 100*solveSimpleModel(κCmin,0,0,x,y,modelPar).r,title = "Interest rate", ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = "r", legend = false)
    #savefig(p,"figures/simpleModel/$(string)_interestrate.pdf")

    growthPlot = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> solveSimpleModel(κCmin,0,0,x,y,modelPar).g*100, title = "Growth rate", ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = "g", legend = false)
    #savefig(growthPlot,"figures/simpleModel/$(string)_growth.pdf")

    #staticCostPlot = surface(T_RD_I_grid,T_NCA_grid,[entryCost NCACost], title = "Entry and NCA costs", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", label = ["Entry cost" "NCA cost"])

    consumptionPlot = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> solveSimpleModel(κCmin,0,0,x,y,modelPar).C,title = "Consumption", xlabel = "\$T_{RD,I}\$", ylabel = "\$T_{NCA}\$", legend = false)

    welfarePlot = surface(T_RD_I_grid,T_NCA_grid,(x,y) -> -((abs(solveSimpleModel(κCmin,0,0,x,y,modelPar).W)/abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ), title = "CE welfare chg. (%)", ylabel = "\$T_{NCA}\$", xlabel = "\$T_{RD,I}\$", label = "\$\\tilde{C}^*\$", legend = false)
    #savefig(welfarePlot,"figures/simpleModel/$(string)_CEwelfare.pdf")

    summaryPlot = plot(growthPlot,valuePlot,xPlot,interestRatePlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt3, guidefont = guideFont, size = (1000,900))
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot.png")
end


# Function for doing welfare comparative static for every parameter setting

function welfareComparison(parameterLimits::SimpleModelParameterLimitList, numPoints::Int64)

    ρLimits = parameterLimits.ρ
    θLimits = parameterLimits.θ
    βLimits = parameterLimits.β
    χELimits = parameterLimits.χE
    χILimits = parameterLimits.χI
    ψLimits = parameterLimits.ψ
    λLimits = parameterLimits.λ
    νLimits = parameterLimits.ν
    κELimits = parameterLimits.κE

    ρStep = (ρLimits.upper - ρLimits.lower) / (numPoints - 1)
    θStep = (θLimits.upper - θLimits.lower) / (numPoints - 1)
    βStep = (βLimits.upper - βLimits.lower) / (numPoints - 1)
    χEStep = (χELimits.upper - χELimits.lower) / (numPoints - 1)
    χIStep = (χILimits.upper - χILimits.lower) / (numPoints - 1)
    ψStep = (ψLimits.upper - ψLimits.lower) / (numPoints - 1)
    λStep = (λLimits.upper - λLimits.lower) / (numPoints - 1)
    νStep = (νLimits.upper - νLimits.lower) / (numPoints - 1)
    κEStep = (κELimits.upper - κELimits.lower) / (numPoints - 1)

    # Construct grids

    ρGrid = ρLimits.lower:ρStep:ρLimits.upper
    θGrid = θLimits.lower:θStep:θLimits.upper
    βGrid = βLimits.lower:βStep:βLimits.upper
    χEGrid = χELimits.lower:χEStep:χELimits.upper
    χIGrid = χILimits.lower:χIStep:χILimits.upper
    ψGrid = ψLimits.lower:ψStep:ψLimits.upper
    λGrid = λLimits.lower:λStep:λLimits.upper
    νGrid = νLimits.lower:νStep:νLimits.upper
    κEGrid = κELimits.lower:κEStep:κELimits.upper


    # Now loop through grids of all values

    println(typeof(Iterators.product(ρGrid,θGrid,βGrid,χEGrid,χIGrid,ψGrid,λGrid,νGrid,κEGrid)))

    A = Iterators.product(ρGrid,θGrid,βGrid,χEGrid,χIGrid,ψGrid,λGrid,νGrid,κEGrid)

    welfareGainResultsArray = zeros(size(A))

    for (i,x) in enumerate(A)

        println("x equals: $x")

        # Welfare when NCAs are enforced
        modelPar0 = SimpleModelParameters(x[1],x[2],x[3],0.05,x[4],x[5],x[6],x[7],x[8],x[9],0.0)
        sol0 = solveSimpleModel(modelPar0)

        println("With NCA enforcement, welfare is: $(sol0.W)")

        # Welfare when NCAs are not enforced

        # First, calculate κC that guarantees NCAs are prohibitively expensive
        # and then interpret this as no enforcement

        # maximum of zero and the actual threshold, in case threshold is negative i.e. no one uses NCAs even when they are free.
        κC_max = max(0,2*(1 - (1-modelPar0.κE)*modelPar0.λ))

        println("κC_max equals $κC_max")

        # Solve model
        sol1 = solveSimpleModel(κC_max,modelPar0)


        println("Without NCA enforcement, welfare is: $(sol1.W)")

        CEWelfareBoostNCAEnforcement = ((abs(sol1.W) / abs(sol0.W)) - 1) * 100 * abs(1-modelPar0.θ)

        println("CE Welfare gain from κC = 0: $CEWelfareBoostNCAEnforcement \n\n")

        idx = CartesianIndices(welfareGainResultsArray)[i]

        welfareGainResultsArray[idx] = CEWelfareBoostNCAEnforcement

    end

    return welfareGainResultsArray


end
