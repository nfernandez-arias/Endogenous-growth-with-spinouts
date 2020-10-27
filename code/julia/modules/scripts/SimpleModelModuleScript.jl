# This file contains the code
# for plotting the solution to the simple expository model

using Plots, Measures, LaTeXStrings
gr()

export SimpleModelParameters, SimpleModelSolution, solveSimpleModel, computeWelfareComparison, initializeSimpleModel, makePlots
export makePlotsRDSubsidy, makePlotsKappaCRDSubsidy, makePlotsEntryTax, makePlotsRDSubsidyTargeted, makePlotsALL, makePlotsALL_contour, makePlotsALL_contour_noSpinouts
export SimpleCalibrationTarget,SimpleCalibrationParameters,SimpleModelMoments,SimpleModelParameterLimit,SimpleModelParameterLimitList,welfareComparison, computeOptimalPolicy

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

    ρ = 0.030259936
    θ = 2
    β = 0.094
    L = 0.01
    χE = 0.5536343
    χI = 21.21660
    ψ = 0.5
    λ = 1.08377
    ν = 0.3447904
    κE = 0.85940929
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

    # Compute final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # Compute x
    x = ((1 - (1-T_RD-T_RD_I)*(1-(1+T_E)*κE)*λ) > κC + T_NCA)

    denom = χI * (λ - 1) - x * ν * (κC + T_NCA) - (1-x) * ν * (1 - (1 - T_RD - T_RD_I)*(1-(1+T_E)*κE)*λ)

    # Compute zE,τE - robustness to zero value
    if (1+T_E)*κE < 1
        zE = min(L,((((1-T_RD - T_RD_I)/(1-T_RD))* χE * (1-(1+T_E)*κE) * λ)/ denom)^(1/ψ))
        τE = χE * zE^(1-ψ)
    else
        zE = 0
        τE = 0
    end
    # Compute zI
    zI = max(0,L - zE)

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
    if zE < L
        wRD_NCA = (V * denom) / (1-T_RD-T_RD_I)
    else
        wRD_NCA = (1-T_RD)^(-1) * χE * zE^(-ψ) * (1 - (1 + T_E) * κE ) *λ *  V
    end

    # Compute final goods labor
    LF = (1 - L) / (1 + ( (1 - β) ./ Cβ(β))^(1/β))

    # Compute output
    Y = ((1-β)^(1-2*β)) / (β^(1-β)) * LF

    # Entry cost
    entryCost = (τE + τS) * κE * λ * V

    # NCA cost
    NCACost = x * zI * ν * κC * V

    # Consumption
    C = Y - entryCost - NCACost

    C2 = Y - NCACost

    # Compute welfare
    W = (C)^(1-θ) / ((1-θ) * ( ρ - g * (1-θ)))

    # Compute welfare treating entry costs as transfers
    W2 = (C2)^(1-θ) / ((1-θ)*( ρ - g * (1-θ)))

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
    C2 = zeros(size(κC_grid))
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
        C2[i] = sol.C + sol.entryCost
        W[i] = sol.W
        W2[i] = sol.W2

        W3[i] = -((abs(W[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)
        W4[i] = -((abs(W2[i]) / abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)

    end

    fnt_legend = Plots.font("times", 7)
    fnt_ticksGuides = Plots.font("times", 9)
    fnt_ticksGuides2 = Plots.font("times",13)
    fnt_title = Plots.font("times",10)

    valuePlot = plot(κC_grid,V,title = "Incumbent value", xlabel = L"\kappa_c", label = "V", legend = false)

    effortPlot = plot(κC_grid,[zI zE], title = "R&D labor", legend = :bottomright, xlabel = L"\kappa_c", label = ["Incumbent" "Entrant"])

    innovationRatesPlot = plot(κC_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = L"\kappa_c", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    wagePlot = plot(κC_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = L"\kappa_c", label = ["Entrant" "Incumbent"])

    interestRatePlot = plot(κC_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = L"\kappa_c", label = "r", legend = false)

    growthPlot = plot(κC_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = L"\kappa_c", label = "g", legend = false)

    staticCostPlot = plot(κC_grid,[100*(entryCost./Y) 100*(NCACost./Y) 100*((entryCost + NCACost)./Y)], title = "Entry and NCA costs (% GDP)", xlabel = L"\kappa_c", label = ["Entry cost" "NCA cost" "Total"])

    staticCost2Plot = plot(κC_grid,100*(NCACost./Y), title = "Entry and NCA costs (% GDP)", xlabel = L"\kappa_c", label = ["NCA cost" "Total"])

    consumptionPlot = plot(κC_grid,C,title = "Consumption", xlabel = L"\kappa_c", legend = false)

    consumption2Plot = plot(κC_grid,C2,title = "Consumption", xlabel = L"\kappa_c", legend = false)

    welfarePlot = plot(κC_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"\kappa_c", label = L"\tilde{C}^*", legend = false)

    welfare2Plot = plot(κC_grid,W4, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"\kappa_c", label = L"\tilde{C}^*", legend = false)

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, yguidefont = fnt_ticksGuides, titlefont = fnt_title, legendfont = fnt_legend, size = (800,800))
    savefig(summaryPlot,"figures/simpleModel/$(string)_summaryPlot.pdf")
  
    effortPlot = plot(effortPlot, legend = :right)
       
    smallSummaryPlot = plot(effortPlot,growthPlot,staticCostPlot,consumptionPlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot,"figures/simpleModel/$(string)_smallSummaryPlot.pdf")
 
    smallSummaryPlot_entryCostsAreTransfers = plot(effortPlot,growthPlot,staticCost2Plot,consumption2Plot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot_entryCostsAreTransfers,"figures/simpleModel/$(string)_smallSummaryPlot_entryCostsAreTransfers.pdf")

    growthDecomp = plot(effortPlot,innovationRatesPlot, bottom_margin = 10mm, left_margin = 10mm, right_margin = 5mm, top_margin = 10mm, size = (1600,600), titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16)
    savefig(growthDecomp,"figures/simpleModel/$(string)_growthDecomp.pdf")

    consumptionDecomp = plot(innovationRatesPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(consumptionDecomp,"figures/simpleModel/$(string)_consumptionDecomp.pdf")

    welfareDecomp = plot(consumptionPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfareDecomp,"figures/simpleModel/$(string)_welfareDecomp.pdf")

    welfarePlot = plot(welfarePlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfarePlot,"figures/simpleModel/$(string)_welfarePlot.pdf")
end

function makePlotsRDSubsidy(modelPar::SimpleModelParameters,string::String)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)
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

    fnt_legend = Plots.font("times", 7)
    fnt_ticksGuides = Plots.font("times", 9)
    fnt_ticksGuides2 = Plots.font("times",9)
    fnt_title = Plots.font("times",10)

    valuePlot = plot(100* τRD_grid,V,title = "Incumbent value", xlabel = "R&D Subsidy (%)", label = "V", legend = false)

    effortPlot = plot(100* τRD_grid,[zI zE], title = "R&D labor", legend = :bottomright, xlabel = "R&D Subsidy (%)", label = ["Incumbent" "Entrant"])

    innovationRatesPlot = plot(100* τRD_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = "R&D Subsidy (%)", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    wagePlot = plot(100* τRD_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "R&D Subsidy (%)", label = ["Entrant" "Incumbent"])

    interestRatePlot = plot(100* τRD_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = "R&D Subsidy (%)", label = "r", legend = false)

    growthPlot = plot(100* τRD_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = "R&D Subsidy (%)", label = "g", legend = false)

    staticCostPlot = plot(100* τRD_grid,[100*(entryCost./Y) 100*(NCACost./Y) 100*((entryCost + NCACost)./Y)], title = "Entry and NCA costs (% GDP)", xlabel = "R&D Subsidy (%)", label = ["Entry cost" "NCA cost" "Total"])

    consumptionPlot = plot(100* τRD_grid,C,title = "Consumption", xlabel = "R&D Subsidy (%)", legend = false)

    welfarePlot = plot(100* τRD_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "R&D Subsidy (%)", label = "\$\\tilde{C}^*\$", legend = false)

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, yguidefont = fnt_ticksGuides, titlefont = fnt_title, legendfont = fnt_legend, size = (800,800))
    savefig(summaryPlot,"figures/simpleModel/$(string)_RDSubsidy_summaryPlot.pdf")

    effortPlot = plot(effortPlot, legend = :right)
    
    smallSummaryPlot = plot(effortPlot,growthPlot,staticCostPlot,consumptionPlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, yguidefont = fnt_ticksGuides, titlefont = fnt_title, legendfont = fnt_legend, size = (666,500))
    savefig(smallSummaryPlot,"figures/simpleModel/$(string)_RDSubsidy_smallSummaryPlot.pdf")
    
    growthDecomp = plot(innovationRatesPlot,growthPlot, bottom_margin = 10mm, left_margin = 10mm, right_margin = 5mm, top_margin = 10mm, size = (1600,600), titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16)
    savefig(growthDecomp,"figures/simpleModel/$(string)_RDSubsidy_growthDecomp.pdf")

    consumptionDecomp = plot(innovationRatesPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(consumptionDecomp,"figures/simpleModel/$(string)_RDSubsidy_consumptionDecomp.pdf")

    welfareDecomp = plot(consumptionPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfareDecomp,"figures/simpleModel/$(string)_RDSubsidy_welfareDecomp.pdf")

end

function makePlotsEntryTax(modelPar::SimpleModelParameters,string::String)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)
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

    fnt = Plots.font("sans-serif", 9)
    guideFont = Plots.font("sans-serif",11)

    valuePlot = plot(Te_grid,V,title = "Incumbent value", xlabel = L"T_e", label = "V", legend = false)

    effortPlot = plot(Te_grid,[zI zE], title = "R&D labor", legend = :bottomright, xlabel = L"T_e", label = ["Incumbent" "Entrant"])

    innovationRatesPlot = plot(Te_grid,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = L"T_e", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    wagePlot = plot(Te_grid,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = L"T_e", label = ["Entrant" "Incumbent"])

    interestRatePlot = plot(Te_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = L"T_e", label = "r", legend = false)

    growthPlot = plot(Te_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = L"T_e", label = "g", legend = false)

    staticCostPlot = plot(Te_grid,[entryCost NCACost], title = "Entry and NCA costs", xlabel = L"T_e", label = ["Entry cost" "NCA cost"])

    consumptionPlot = plot(Te_grid,C,title = "Consumption", xlabel = L"T_e", legend = false)

    welfarePlot = plot(Te_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"T_e", label = "\$\\tilde{C}^*\$", legend = false)

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = guideFont, size = (800,750))
    savefig(summaryPlot,"figures/simpleModel/$(string)_EntryTax_summaryPlot.pdf")

    smallSummaryPlot = plot(growthPlot,consumptionPlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, size = (1600,600))
    savefig(smallSummaryPlot,"figures/simpleModel/$(string)_EntryTax_smallSummaryPlot.pdf")

    growthDecomp = plot(innovationRatesPlot,growthPlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, size = (1600,600))
    savefig(growthDecomp,"figures/simpleModel/$(string)_EntryTax_growthDecomp.pdf")

    consumptionDecomp = plot(innovationRatesPlot,growthPlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, size = (1600,600))
    savefig(consumptionDecomp,"figures/simpleModel/$(string)_EntryTax_consumptionDecomp.pdf")

    welfareDecomp = plot(consumptionPlot,growthPlot, bottom_margin = 5mm, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, size = (1600,600))
    savefig(welfareDecomp,"figures/simpleModel/$(string)_EntryTax_welfareDecomp.pdf")

end

function makePlotsRDSubsidyTargeted(modelPar::SimpleModelParameters,string::String)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)
    τRD_I_grid = -.3:0.001:0.9

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

    fnt_legend = Plots.font("times", 7)
    fnt_ticksGuides = Plots.font("times", 9)
    fnt_ticksGuides2 = Plots.font("times",9)
    fnt_title = Plots.font("times",10)

    valuePlot = plot(τRD_I_grid*100,V,title = "Incumbent value", xlabel = "Targeted R&D Subsidy (%)", label = "V", legend = false)

    effortPlot = plot(τRD_I_grid*100,[zI zE], title = "R&D labor", legend = :bottomright, xlabel = "Targeted R&D Subsidy (%)", label = ["Incumbent" "Entrant"])

    innovationRatesPlot = plot(τRD_I_grid*100,[τI τE τS (τI + τE + τS)], title = "Innovation rate", legend = :bottomright, ylabel = "Innovations per year", xlabel = "Targeted R&D Subsidy (%)", label = ["Incumbent" "Entrant" "Spinout" "Total"])

    wagePlot = plot(τRD_I_grid*100,[wRD_NCA wRD_NCA .- (1 .- x) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = "Targeted R&D Subsidy (%)", label = ["Entrant" "Incumbent"])

    interestRatePlot = plot(τRD_I_grid*100,100*r,title = "Interest rate", ylabel = "% per year", xlabel = "Targeted R&D Subsidy (%)", label = "r", legend = false)

    growthPlot = plot(τRD_I_grid*100,g*100, title = "Growth rate", ylabel = "% per year", xlabel = "Targeted R&D Subsidy (%)", label = "g", legend = false)

    staticCostPlot = plot(τRD_I_grid*100,[100*(entryCost./Y) 100*(NCACost./Y) 100*((entryCost + NCACost)./Y)], title = "Entry and NCA costs", xlabel = "Targeted R&D Subsidy (%)", label = ["Entry cost" "NCA cost" "Total"], legend = :left)

    consumptionPlot = plot(τRD_I_grid*100,C,title = "Consumption", xlabel = "Targeted R&D Subsidy (%)", legend = false)

    welfarePlot = plot(τRD_I_grid*100,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = "Targeted R&D Subsidy (%)", label = "\$\\tilde{C}^*\$", legend = false)

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, yguidefont = fnt_ticksGuides, titlefont = fnt_title, legendfont = fnt_legend, size = (800,800))
    savefig(summaryPlot,"figures/simpleModel/$(string)_RDSubsidyTargeted_summaryPlot.pdf")

    effortPlot = plot(effortPlot, legend = :right)
       
    smallSummaryPlot = plot(effortPlot,growthPlot,staticCostPlot,consumptionPlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot,"figures/simpleModel/$(string)_RDSubsidyTargeted_smallSummaryPlot.pdf")
    
    growthDecomp = plot(innovationRatesPlot,growthPlot, bottom_margin = 10mm, left_margin = 10mm, right_margin = 5mm, top_margin = 10mm, size = (1600,600), titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16)
    savefig(growthDecomp,"figures/simpleModel/$(string)_RDSubsidyTargeted_growthDecomp.pdf")

    consumptionDecomp = plot(innovationRatesPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(consumptionDecomp,"figures/simpleModel/$(string)_RDSubsidyTargeted_consumptionDecomp.pdf")

    welfareDecomp = plot(consumptionPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfareDecomp,"figures/simpleModel/$(string)_RDSubsidyTargeted_welfareDecomp.pdf")

end

function makePlotsALL(modelPar::SimpleModelParameters,string::String)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)

    κCmin = 0
    κCmax = 2*κC

    T_RD_I_grid = 0:0.01:.9999
    κC_grid = κCmin:0.01:κCmax

    fnt = Plots.font("sans-serif", 9)
    fnt2 = Plots.font("sans-serif", 8)
    fnt3 = Plots.font("sans-serif", 8)
    guideFont = Plots.font("sans-serif",9)

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    valuePlot = surface(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).V,title = "Incumbent value", xlabel = L"T_{RD,I}", ylabel = L"\kappa_c", label = "V", legend = false)

    xPlot = surface(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).x,title = "Noncompete usage", xlabel = L"T_{RD,I}", ylabel = L"\kappa_c", label = "x", legend = false)

    interestRatePlot = surface(T_RD_I_grid,κC_grid,(x,y) -> 100*solveSimpleModel(y,0,0,x,0,modelPar).r,title = "Interest rate", ylabel = L"\kappa_c", xlabel = L"T_{RD,I}", label = "r", legend = false)

    growthPlot = surface(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).g*100, title = "Growth rate", ylabel = L"\kappa_c", xlabel = L"T_{RD,I}", label = "g", legend = false)

    consumptionPlot = surface(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).C,title = "Consumption", xlabel = L"T_{RD,I}", ylabel = L"\kappa_c", legend = false)

    welfarePlot = surface(T_RD_I_grid,κC_grid,(x,y) -> -((abs(solveSimpleModel(y,0,0,x,0,modelPar).W)/abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ), title = "CE welfare chg. (%)", ylabel = L"\kappa_c", xlabel = L"T_{RD,I}", label = "\$\\tilde{C}^*\$", legend = false)

    #summaryPlot = plot(growthPlot,valuePlot,xPlot,interestRatePlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt3, guidefont = guideFont, size = (1000,900))
    summaryPlot = plot(welfarePlot,growthPlot,consumptionPlot,xPlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt3, guidefont = guideFont, size = (800,600))
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot.pdf")
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot.png")
end

function makePlotsALL_contour(modelPar::SimpleModelParameters,string::String)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)

    κCmin = 0
    κCmax = 2*κC

    T_RD_I_grid = (0:0.001:.9999)*100
    κC_grid = κCmin:0.001:κCmax

    fnt = Plots.font("sans-serif", 9)
    fnt2 = Plots.font("sans-serif", 8)
    fnt3 = Plots.font("sans-serif", 8)
    guideFont = Plots.font("serif",12)

    fnt_legend = Plots.font("times", 7)
    fnt_ticksGuides = Plots.font("times", 9)
    fnt_ticksGuides2 = Plots.font("times",13)
    fnt_title = Plots.font("times",10)

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W
    Wbenchmark2 = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W2

    valuePlot = contour(κC_grid,T_RD_I_grid,(x,y) -> solveSimpleModel(x,0,0,y/100,0,modelPar).V,title = "Incumbent value", ylabel = "Targeted R&D Subsidy", xlabel = L"\kappa_c", label = "V", legend = false, fill = true, fillcolor = cgrad(:Blues_9, rev = true))

    xPlot = contour(κC_grid,T_RD_I_grid,(x,y) -> solveSimpleModel(x,0,0,y/100,0,modelPar).x,title = "Noncompete usage", ylabel = "Targeted R&D Subsidy", xlabel = L"\kappa_c", label = "x", legend = false, fill = true, fillcolor = cgrad(:Blues_9, rev = true))

    interestRatePlot = contour(κC_grid,T_RD_I_grid,(x,y) -> 100*solveSimpleModel(x,0,0,y/100,0,modelPar).r,title = "Interest rate", xlabel = L"\kappa_c", ylabel = "Targeted R&D Subsidy", label = "r", legend = false, fill = true, fillcolor = cgrad(:Blues_9, rev = true))

    growthPlot = contour(κC_grid,T_RD_I_grid,(x,y) -> solveSimpleModel(x,0,0,y/100,0,modelPar).g*100, title = "Growth rate", xlabel = L"\kappa_c", ylabel = "Targeted R&D Subsidy", label = "g", legend = false, contour_labels = true, fill = true, fillcolor = cgrad(:Blues_9, rev = true), levels = 20)

    consumptionPlot = contour(κC_grid,T_RD_I_grid,(x,y) -> solveSimpleModel(x,0,0,y/100,0,modelPar).C,title = "Consumption", ylabel = "Targeted R&D Subsidy", xlabel = L"\kappa_c", legend = false, fill = true, fillcolor = cgrad(:Blues_9, rev = true))

    welfarePlot = contour(κC_grid,T_RD_I_grid,(x,y) -> -((abs(solveSimpleModel(x,0,0,y/100,0,modelPar).W)/abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ), title = "CE welfare chg. (%)", xlabel = L"\kappa_c", ylabel = "Targeted R&D Subsidy (%)", label = "\$\\tilde{C}^*\$", legend = false, fill = true, fillcolor = cgrad(:Blues_9, rev = true), levels = [0,1,2,3,4,5,6,7,8,8.25,8.5,8.75,9,9.04,9.08])

    welfarePlot2 = contour(κC_grid,T_RD_I_grid,(x,y) -> -((abs(solveSimpleModel(x,0,0,y/100,0,modelPar).W2)/abs(Wbenchmark2)) - 1) * 100 * abs(1-modelPar.θ), title = "CE welfare chg. (%)", xlabel = L"\kappa_c", ylabel = "Targeted R&D Subsidy (%)", label = "\$\\tilde{C}^*\$", legend = false, fill = true, fillcolor = cgrad(:Blues_9, rev = true), levels = [0,1,2,3,4,5,6,7,8,8.25,8.5,8.75,9,9.04,9.08])

    #summaryPlot = plot(growthPlot,valuePlot,xPlot,interestRatePlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt3, guidefont = guideFont, size = (1000,900))
    summaryPlot = plot(welfarePlot,growthPlot,consumptionPlot,xPlot, size = (666,500), titlefont = fnt_title, xguidefont = fnt_ticksGuides2, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, yguidefont = fnt_ticksGuides)
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot_contour.pdf")
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot_contour.png")

    welfare = plot(welfarePlot,title = "Change in Welfare (% CE)", levels = [0,1,2,3,4,5,6,7,8,8.5,8.8,9,9.08,10], contour_labels = true, legend = true, size = (666,500), titlefont = fnt_title, xguidefont = fnt_ticksGuides2, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, yguidefont = fnt_ticksGuides)

    savefig(welfare,"figures/simpleModel/$(string)_ALL_welfarePlot_contour.png")
    savefig(welfare,"figures/simpleModel/$(string)_ALL_welfarePlot_contour.pdf")   

    welfare_entryCostsAreTransfers = plot(welfarePlot2,title = "Change in Welfare (% CE)", levels = [0,1,2,3,4,5,6,6.5,7,7.15,8], contour_labels = true, legend = true, size = (666,500), titlefont = fnt_title, xguidefont = fnt_ticksGuides2, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, yguidefont = fnt_ticksGuides)

    savefig(welfare_entryCostsAreTransfers,"figures/simpleModel/$(string)_ALL_welfarePlot_entryCostsAreTransfers_contour.png")
    savefig(welfare_entryCostsAreTransfers,"figures/simpleModel/$(string)_ALL_welfarePlot_entryCostsAreTransfers_contour.pdf")   
     
end

function makePlotsALL_contour_noSpinouts(modelPar::SimpleModelParameters,string::String)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)

    κCmin = 0
    κCmax = 2*κC

    T_RD_I_grid = 0:0.001:.9999
    κC_grid = κCmin:0.001:κCmax

    fnt = Plots.font("sans-serif", 9)
    fnt2 = Plots.font("sans-serif", 8)
    fnt3 = Plots.font("sans-serif", 8)
    guideFont = Plots.font("sans-serif",9)

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    #valuePlot = surface(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).V,title = "Incumbent value", xlabel = L"T_{RD,I}", ylabel = L"\kappa_c", label = "V", legend = false, fill = true)

    #xPlot = surface(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).x,title = "Noncompete usage", xlabel = L"T_{RD,I}", ylabel = L"\kappa_c", label = "x", legend = false, fill = true)

    #interestRatePlot = surface(T_RD_I_grid,κC_grid,(x,y) -> 100*solveSimpleModel(y,0,0,x,0,modelPar).r,title = "Interest rate", ylabel = L"\kappa_c", xlabel = L"T_{RD,I}", label = "r", legend = false, fill = true)

    growthPlot = contour(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).g*100, title = "Growth rate", ylabel = L"\kappa_c", xlabel = L"T_{RD,I}", label = "g", legend = false, fill = true, levels = 20)

    consumptionPlot = contour(T_RD_I_grid,κC_grid,(x,y) -> solveSimpleModel(y,0,0,x,0,modelPar).C,title = "Consumption", xlabel = L"T_{RD,I}", ylabel = L"\kappa_c", legend = false, fill = true)

    welfarePlot = contour(T_RD_I_grid,κC_grid,(x,y) -> -((abs(solveSimpleModel(y,0,0,x,0,modelPar).W)/abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ), title = "CE welfare chg. (%)", ylabel = L"\kappa_c", xlabel = L"T_{RD,I}", label = "\$\\tilde{C}^*\$", legend = false, fill = true)

    #summaryPlot = plot(growthPlot,valuePlot,xPlot,interestRatePlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt3, guidefont = guideFont, size = (1000,900))
    summaryPlot = plot(growthPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt2, ytickfont = fnt3, guidefont = guideFont, size = (800,600))
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot_contour.pdf")
    savefig(summaryPlot,"figures/simpleModel/$(string)_ALL_summaryPlot_contour.png")
end


function computeOptimalPolicy(modelPar::SimpleModelParameters)

    κC = 1.1*(1 - (1-modelPar.κE)*modelPar.λ)

    κCmin = 0
    κCmax = 2*κC

    T_RD_I_grid = 0:0.01:0.8
    κC_grid = κCmin:0.01:κCmax

    Wbenchmark = solveSimpleModel(κC, 0, 0, 0, 0, modelPar).W

    function f(x::Array{Float64})


        return ((abs(solveSimpleModel(x[1],0,0,x[2],0,modelPar).W)/abs(Wbenchmark)) - 1) * 100 * abs(1-modelPar.θ)


    end

    initial = [2.5, 0.8]

    lower = [0.0, 0.0]

    upper = [3.0, .999999] 

    inner_optimizer = LBFGS()

    result = optimize(f,lower,upper,initial,Fminbox(inner_optimizer),Optim.Options(outer_iterations = 1000000, iterations = 10000000, store_trace = true))

    x = result.minimizer

    print(result)
    print(x)
    
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
