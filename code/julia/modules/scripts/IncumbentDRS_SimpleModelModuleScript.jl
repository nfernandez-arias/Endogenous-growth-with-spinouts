# This file contains the code
# for plotting the solution to an augmented model
# with a DRS technology for incumbent innovation

using NLsolve, Plots, Measures, LaTeXStrings
gr()


export Guess, InnerGuess, UpdatingParameters, ToleranceParameters, AlgorithmParameters, ModelParameters, ModelParameterLimit, ModelParameterLimitList, ModelSolution
export Cβ, initializeAlgorithmParameters, initializeModelParameters, solveModel, solveIncumbentHJB
export incWageAdjust, entrantWageAdjust
export makePlots, computeGrowthAttribution, computeWelfareImprovement

mutable struct Guess

	τE::Real
	r::Real
	#wRD_I::Real

end

mutable struct InnerGuess

	V::Real
	wRD_I::Real

end

mutable struct UpdatingParameters

	τE::Real
	r::Real
	#wRD_I::Real

end

mutable struct ToleranceParameters

	τE::Real
	r::Real
	#wRD_I::Real

end


struct AlgorithmParameters


	# Algorithm Parameters

	updateWeights::UpdatingParameters
	tolerance::ToleranceParameters

end

mutable struct ModelParameters

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
    ψE::Real
    ψI::Real

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

struct ModelParameterLimit

    lower::Real
    upper::Real

end

struct ModelParameterLimitList

    ρ::ModelParameterLimit
    θ::ModelParameterLimit
    β::ModelParameterLimit
    χE::ModelParameterLimit
    χI::ModelParameterLimit
    ψE::ModelParameterLimit
    ψI::ModelParameterLimit
    λ::ModelParameterLimit
    ν::ModelParameterLimit
    κE::ModelParameterLimit

end

function initializeModelParameters()

    ρ = 0.0559597
    θ = 2
    β = 0.094
    L = 0.01
    χE = .356
    χI = 2.73
    ψE = 0.5
    ψI = 0.5
    λ = 1.08377
    ν = 0.89
    κE = 0.58
    κC = 0

    modelPar = ModelParameters(ρ,θ,β,L,χE,χI,ψE,ψI,λ,ν,κE,κC)

    return modelPar

end

function Cβ(β::Real)

    return β^β * (1-β)^(1-2*β)

end

function initializeAlgorithmParameters()

	updateWeight = 0.3
	tolerance = 10e-11

	#updateWeights = UpdatingParameters(updateWeight,updateWeight,updateWeight)
	#tolerances = ToleranceParameters(tolerance,tolerance,tolerance)

	updateWeights = UpdatingParameters(updateWeight,updateWeight)
	tolerances = ToleranceParameters(tolerance,tolerance)

	algoPar = AlgorithmParameters(updateWeights,tolerances)

end



struct ModelSolution

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
    nca::Real
    # RD wage for incumbents 
    wRD_I::Real
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

# Some auxiliary functions first

# Construct functions which calculate the adjustments needed for wages
#
# Specifically, the incumbent wage adjustment adds to the incumbent R&D wage the capital loss of future spinout formation (first term) or the cost of NCAs (second term), 
# depending on whether nca == false or nca == true

function incWageAdjust(modelPar::ModelParameters,V::Real,nca::Real, κC::Real)

    λ = modelPar.λ
    ν = modelPar.ν

	return (1-nca) * ν * V + nca * κC * ν * V

end

# The entrant wage adjustment adds to the incumbent R&D wage an amount equal to the present value of future spinout formation IF nca == false. Otherwise, the entrant pays
# the same wage as the incumbent and the adjustment is zero.

function entrantWageAdjust(modelPar::ModelParameters, V::Real,nca::Real)

    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE

	return (1-nca) * (1-κE) * λ * ν * V

end


function solveIncumbentHJB(modelPar::ModelParameters, guess::Guess, innerGuess::InnerGuess, nca::Bool, π0::Real, κC::Real, T_RD::Real, T_RD_I::Real)

	# Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψE = modelPar.ψE
    ψI = modelPar.ψI
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE
    
    # Unpack guess

    τE = guess.τE
    r = guess.r

    # x[1] is V
    # x[2] is wRD_I - the wage incumbents pay
    # this solves for the equilibrium values of these that are consistent with 
    # incumbent optimization, entrant optimization, household optimization and labor market clearing
    # incumbent optimization and entrant optimization are computed in closed form given V and wRD_I and the 
    # fact that the entrant wage is related to wRD_I in equilibrium to the value of future spinouts, when ncas are not used.

    function incWageAdjust(V::Real,nca::Real)

    	return (1-nca) * ν * V + nca * κC * ν * V

    end

    function entrantWageAdjust(V::Real,nca::Real)

    	return (1-nca) * (1-κE) * λ * ν * V

    end


    function f!(F,x)

    	# incumbent HJB
    	F[1] = - (r + τE) * x[1] + π0 + χI * (((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^((1-ψI)/ψI) * (λ-1) * x[1] - (x[2] + incWageAdjust(x[1],nca) ) * (((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^(1/ψI) 

    	# labor market clearing
    	F[2] = -L + (((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^(1/ψI) + ( (χE * (1-κE) * λ * x[1]) / ( x[2] + entrantWageAdjust(x[1],nca) ) )^(1/ψE)

    end

    #function test(out)

    #	x = out.zero

    	# incumbent HJB
    #	out1 = - (r + τE) * x[1] + π0 + χI * (((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^((1-ψI)/ψI) * (λ-1) * x[1] - (x[2] + incWageAdjust(x[1],nca) ) * (((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^(1/ψI) 

    	# labor market clearing
    #	out2 = -L + (((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^(1/ψI) + ( (χE * (1-κE) * λ * x[1]) / ( x[2] + entrantWageAdjust(x[1],nca) ) )^(1/ψE)

    #	println(out1)
    #	println(out2)

    #	println((((1-ψI) * χI * (λ-1) * x[1])/ (x[2] + incWageAdjust(x[1],nca)))^(1/ψI))
    #	println(( (χE * (1-κE) * λ * x[1]) / ( x[2] + entrantWageAdjust(x[1],nca) ) )^(1/ψE))

    #end

    # Initial guesses are: permanent value of flow profits and production wage
    out = nlsolve(f!, [innerGuess.V, innerGuess.wRD_I], autodiff = :forward)


    #test(out)


    return out.zero[1], out.zero[2]
    #return out

end



function solveModel(modelPar::ModelParameters, algoPar::AlgorithmParameters, outerGuess::Guess, κC::Real, T_RD::Real, T_RD_I::Real)

    # Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψE = modelPar.ψE
    ψI = modelPar.ψI
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE

    # Compute final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # Compute production wage
    wProd = Cβ(β)

    # Compute flow profits
    π0 = Cβ(β)*(1-β) * LF

    # Compute noncompete policy
    nca = ((1 - (1-T_RD-T_RD_I)*(1-κE)*λ) > κC )

    # Compute initial guesses
    # Begin with hypothesis that τE = 0. 

    # τE = 0
    # r = θg + ρ, where g = (λ-1) * χI * L^(1-ψ) 
    # wRD_I = wProd - (1-nca) * κC * ν * π0 / r

    τE_init = outerGuess.τE
    r_init = outerGuess.r
    #wRD_I_init = wProd - (1-nca) * ν * (1 - κE) * λ *  π0 / r_init

    error_τE = 1.0
    error_r = 1.0
    #error_wRD_I_init = 1

    # Declare for output

    innerGuess = InnerGuess(π0 / (r_init + τE_init) , wProd)
    V = 0
    wRD_I = 0
    zI = 0
    zE = 0
    τI = 0
    τE = 0
    τS = 0
    g = 0
    r = 0


    while (error_τE > algoPar.tolerance.τE) || (error_r > algoPar.tolerance.r)

    	V,wRD_I = solveIncumbentHJB(modelPar, outerGuess, innerGuess, nca, π0, κC, T_RD, T_RD_I)

    	# Update inner guess for next iteration
    	innerGuess.V = V
    	innerGuess.wRD_I = wRD_I

    	# Compute implied zI,zE
    	zI = (((1-ψI) * χI * (λ-1) * V)/ (wRD_I + incWageAdjust(modelPar,V,nca,κC)))^(1/ψI)
    	zE = ( (χE * (1-κE) * λ * V) / (wRD_I + entrantWageAdjust(modelPar,V,nca)))^(1/ψE)

    	# Compute implied τI,τE,τS

    	τI = χI * zI^(1-ψI)
    	τE = χE * zE^(1-ψE)
    	τS = (1-nca) * ν * zI

    	# Compute implied growth rate, including spinouts
    	g = (λ-1) * (τI + τE + (1-nca) * ν * zI)


    	# Compute interest rate implied by Euler equation
    	r = θ * g + ρ

    	error_τE = abs(τE - outerGuess.τE)
    	error_r = abs(r - outerGuess.r)

    	#println("τE error is: $(error_τE)")
    	#println(error_τE)
    	#println("r error is: $(error_r)")
    	#println(error_r)

    	outerGuess.τE = algoPar.updateWeights.τE * τE + (1 - algoPar.updateWeights.τE) * outerGuess.τE
    	outerGuess.r = algoPar.updateWeights.r * r + (1 - algoPar.updateWeights.r) * outerGuess.r


    end

    # Compute output
    Y = ((1-β)^(1-2*β)) / (β^(1-β)) * LF

    # Entry cost
    entryCost = (τE + τS) * κE * λ * V

    # NCA cost
    NCACost = nca * zI * ν * κC * V

    # Consumption
    C = Y - entryCost - NCACost

    C2 = Y - NCACost

    # Compute welfare
    W = (C)^(1-θ) / ((1-θ) * ( ρ - g * (1-θ)))

    # Compute welfare treating entry costs as transfers
    W2 = (C2)^(1-θ) / ((1-θ)*( ρ - g * (1-θ)))

    sol = ModelSolution(V,zI,τI,zE,τE,τS,nca,wRD_I,r,g,Y,LF,entryCost,NCACost,C,W,W2)
    return sol

end


function solveModel(modelPar::ModelParameters, algoPar::AlgorithmParameters, outerGuess::Guess)

	return solveModel(modelPar,algoPar,outerGuess,modelPar.κC,0,0)

end


function solveModel(modelPar::ModelParameters,algoPar::AlgorithmParameters)

    # Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψE = modelPar.ψE
    ψI = modelPar.ψI
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE
    κC = modelPar.κC

    # Compute final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # Compute production wage
    wProd = Cβ(β)

    # Compute flow profits
    π0 = Cβ(β)*(1-β) * LF

    # Compute noncompete policy
    nca = (1 - (1-(1-κE)*λ) > κC )

    # Compute initial guesses
    # Begin with hypothesis that τE = 0. 

    # τE = 0
    # r = θg + ρ, where g = (λ-1) * χI * L^(1-ψ) 

    τE_init = 0
    r_init = θ * (λ-1)*(χI*L^(1-ψI) + (1-nca)*ν*L) + ρ
    
    outerGuess = Guess(τE_init,r_init)

	return solveModel(modelPar,algoPar,outerGuess)


end

function solveModel(modelPar::ModelParameters, algoPar::AlgorithmParameters, κC::Real, T_RD::Real, T_RD_I::Real)


    # Unpack parameters

    ρ = modelPar.ρ
    θ = modelPar.θ
    β = modelPar.β
    L = modelPar.L
    χE = modelPar.χE
    χI = modelPar.χI
    ψE = modelPar.ψE
    ψI = modelPar.ψI
    λ = modelPar.λ
    ν = modelPar.ν
    κE = modelPar.κE

    # Compute final goods labor allocation
    LF = (1-L)/(1+((1-β)/Cβ(β))^(1/β))

    # Compute production wage
    wProd = Cβ(β)

    # Compute flow profits
    π0 = Cβ(β)*(1-β) * LF

    # Compute noncompete policy
    nca = (1 - (1-(1-κE)*λ) > κC )

    # Compute initial guesses
    # Begin with hypothesis that τE = 0. 

    # τE = 0
    # r = θg + ρ, where g = (λ-1) * χI * L^(1-ψ) 

    τE_init = 0
    r_init = θ * (λ-1)*(χI*L^(1-ψI) + (1-nca)*ν*L) + ρ
    
    outerGuess = Guess(τE_init,r_init)

    return solveModel(modelPar, algoPar, outerGuess, κC, T_RD, T_RD_I)


end



function makePlots(modelPar::ModelParameters,algoPar::AlgorithmParameters,name::String)

    κC_max = 2*(1 - (1-modelPar.κE)*modelPar.λ)
    κC_grid = 0:0.001:κC_max

    V = zeros(size(κC_grid))
    zI = zeros(size(κC_grid))
    τI = zeros(size(κC_grid))
    zE = zeros(size(κC_grid))
    τE = zeros(size(κC_grid))
    τS = zeros(size(κC_grid))
    nca = zeros(size(κC_grid))
    wRD_I = zeros(size(κC_grid))
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



    Wbenchmark = solveModel(modelPar,algoPar,κC_max, 0, 0).W

    for i in 1:length(κC_grid)

        sol = solveModel(modelPar,algoPar,κC_grid[i],0,0)

        V[i] = sol.V
        zI[i] = sol.zI
        τI[i] = sol.τI
        zE[i] = sol.zE
        τE[i] = sol.τE
        τS[i] = sol.τS
        nca[i] = sol.nca
        wRD_I[i] = sol.wRD_I
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

    wagePlot = plot(κC_grid,[wRD_I wRD_I .+ (1 .- nca) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = L"\kappa_c", label = ["Incumbent" "Entrant"])

    interestRatePlot = plot(κC_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = L"\kappa_c", label = "r", legend = false)

    growthPlot = plot(κC_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = L"\kappa_c", label = "g", legend = false)

    staticCostPlot = plot(κC_grid,[100*(entryCost./Y) 100*(NCACost./Y) 100*((entryCost + NCACost)./Y)], title = "Entry and NCA costs (% GDP)", xlabel = L"\kappa_c", label = ["Entry cost" "NCA cost" "Total"])

    staticCost2Plot = plot(κC_grid,100*(NCACost./Y), title = "Entry and NCA costs (% GDP)", xlabel = L"\kappa_c", label = ["NCA cost" "Total"])

    consumptionPlot = plot(κC_grid,C,title = "Consumption", xlabel = L"\kappa_c", legend = false)

    consumption2Plot = plot(κC_grid,C2,title = "Consumption", xlabel = L"\kappa_c", legend = false)

    welfarePlot = plot(κC_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"\kappa_c", label = L"\tilde{C}^*", legend = false)

    welfare2Plot = plot(κC_grid,W4, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"\kappa_c", label = L"\tilde{C}^*", legend = false)

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, yguidefont = fnt_ticksGuides, titlefont = fnt_title, legendfont = fnt_legend, size = (800,800))
    savefig(summaryPlot,"figures/simpleModel/$(name)_incumbentDRS_summaryPlot.pdf")
  
    effortPlot = plot(effortPlot, legend = :right)
       
    smallSummaryPlot = plot(effortPlot,growthPlot,staticCostPlot,consumptionPlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot,"figures/simpleModel/$(name)_incumbentDRS_smallSummaryPlot.pdf")
 
    smallSummaryPlot_entryCostsAreTransfers = plot(effortPlot,growthPlot,staticCost2Plot,consumption2Plot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot_entryCostsAreTransfers,"figures/simpleModel/$(name)_incumbentDRS_smallSummaryPlot_entryCostsAreTransfers.pdf")

    growthDecomp = plot(effortPlot,innovationRatesPlot, bottom_margin = 10mm, left_margin = 10mm, right_margin = 5mm, top_margin = 10mm, size = (1600,600), titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16)
    savefig(growthDecomp,"figures/simpleModel/$(name)_incumbentDRS_growthDecomp.pdf")

    consumptionDecomp = plot(innovationRatesPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(consumptionDecomp,"figures/simpleModel/$(name)_incumbentDRS_consumptionDecomp.pdf")

    welfareDecomp = plot(consumptionPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfareDecomp,"figures/simpleModel/$(name)_incumbentDRS_welfareDecomp.pdf")

    welfarePlot = plot(welfarePlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfarePlot,"figures/simpleModel/$(name)_incumbentDRS_welfarePlot.pdf")
end



function makePlots(modelPar::ModelParameters, algoPar::AlgorithmParameters, outerGuess::Guess, name::String)


    κC_max = 2*(1 - (1-modelPar.κE)*modelPar.λ)
    κC_grid = 0:0.001:κC_max

    V = zeros(size(κC_grid))
    zI = zeros(size(κC_grid))
    τI = zeros(size(κC_grid))
    zE = zeros(size(κC_grid))
    τE = zeros(size(κC_grid))
    τS = zeros(size(κC_grid))
    nca = zeros(size(κC_grid))
    wRD_I = zeros(size(κC_grid))
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

    Wbenchmark = solveModel(modelPar,algoPar,outerGuess,κC_max, 0, 0).W

    for i in length(κC_grid):-1:1

        sol = solveModel(modelPar,algoPar,outerGuess,κC_grid[i],0,0)

        # Update guess
        #outerGuess.r = sol.r
        #outerGuess.τE = sol.τE

        # Unpack solution into plotting vectors

        V[i] = sol.V
        zI[i] = sol.zI
        τI[i] = sol.τI
        zE[i] = sol.zE
        τE[i] = sol.τE
        τS[i] = sol.τS
        nca[i] = sol.nca
        wRD_I[i] = sol.wRD_I
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

    wagePlot = plot(κC_grid,[wRD_I wRD_I .+ (1 .- nca) .* modelPar.ν .* (1-modelPar.κE) .* V], title = "R&D wage", xlabel = L"\kappa_c", label = ["Incumbent" "Entrant"])

    interestRatePlot = plot(κC_grid,100*r,title = "Interest rate", ylabel = "% per year", xlabel = L"\kappa_c", label = "r", legend = false)

    growthPlot = plot(κC_grid,g*100, title = "Growth rate", ylabel = "% per year", xlabel = L"\kappa_c", label = "g", legend = false)

    staticCostPlot = plot(κC_grid,[100*(entryCost./Y) 100*(NCACost./Y) 100*((entryCost + NCACost)./Y)], title = "Entry and NCA costs (% GDP)", xlabel = L"\kappa_c", label = ["Entry cost" "NCA cost" "Total"])

    staticCost2Plot = plot(κC_grid,100*(NCACost./Y), title = "Entry and NCA costs (% GDP)", xlabel = L"\kappa_c", label = ["NCA cost" "Total"])

    consumptionPlot = plot(κC_grid,C,title = "Consumption", xlabel = L"\kappa_c", legend = false)

    consumption2Plot = plot(κC_grid,C2,title = "Consumption", xlabel = L"\kappa_c", legend = false)

    welfarePlot = plot(κC_grid,W3, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"\kappa_c", label = L"\tilde{C}^*", legend = false)

    welfare2Plot = plot(κC_grid,W4, title = "CE welfare chg.", ylabel = "% chg", xlabel = L"\kappa_c", label = L"\tilde{C}^*", legend = false)

    summaryPlot = plot(effortPlot,innovationRatesPlot,growthPlot,valuePlot,interestRatePlot,wagePlot,staticCostPlot,consumptionPlot,welfarePlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, yguidefont = fnt_ticksGuides, titlefont = fnt_title, legendfont = fnt_legend, size = (800,800))
    savefig(summaryPlot,"figures/simpleModel/$(name)_incumbentDRS_summaryPlot.pdf")
  
    effortPlot = plot(effortPlot, legend = :right)
       
    smallSummaryPlot = plot(effortPlot,growthPlot,staticCostPlot,consumptionPlot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot,"figures/simpleModel/$(name)_incumbentDRS_smallSummaryPlot.pdf")
 
    smallSummaryPlot_entryCostsAreTransfers = plot(effortPlot,growthPlot,staticCost2Plot,consumption2Plot, bottom_margin = 5mm, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, xguidefont = fnt_ticksGuides2, titlefont = fnt_title, legendfont = fnt_legend, yguidefont = fnt_ticksGuides, size = (666,500))
    savefig(smallSummaryPlot_entryCostsAreTransfers,"figures/simpleModel/$(name)_incumbentDRS_smallSummaryPlot_entryCostsAreTransfers.pdf")

    growthDecomp = plot(effortPlot,innovationRatesPlot, bottom_margin = 10mm, left_margin = 10mm, right_margin = 5mm, top_margin = 10mm, size = (1600,600), titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16)
    savefig(growthDecomp,"figures/simpleModel/$(name)_incumbentDRS_growthDecomp.pdf")

    consumptionDecomp = plot(innovationRatesPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 12, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(consumptionDecomp,"figures/simpleModel/$(name)_incumbentDRS_consumptionDecomp.pdf")

    welfareDecomp = plot(consumptionPlot,growthPlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfareDecomp,"figures/simpleModel/$(name)_incumbentDRS_welfareDecomp.pdf")

    welfarePlot = plot(welfarePlot, left_margin = 10mm, bottom_margin = 10mm, right_margin = 5mm, top_margin = 10mm, titlefontsize = 18, legendfontsize = 10, xguidefontsize = 16, xtickfontsize = 12, ytickfontsize = 12, yguidefontsize = 16, size = (1600,600))
    savefig(welfarePlot,"figures/simpleModel/$(name)_incumbentDRS_welfarePlot.pdf")



end


function computeGrowthAttribution(modelPar::ModelParameters, sol::ModelSolution, wold::Real)

    λ = modelPar.λ

    growth = sol.g * 100
    consumption = sol.C 
    ncas = sol.nca
    welfare = -((abs(sol.W) / abs(wold)) - 1) * 100 * abs(1-modelPar.θ)
    welfare2 = -((abs(sol.W2) / abs(wold)) - 1) * 100 * abs(1-modelPar.θ)
    incumbents = (λ-1) * sol.τI * 100
    entrants = (λ-1) * sol.τE * 100
    spinouts = (λ-1) * sol.τS * 100

    incumbentsRD = 100 * sol.zI / modelPar.L
    entrantsRD = 100 * sol.zE / modelPar.L


    return [growth, consumption, ncas, welfare, welfare2, incumbents, entrants, spinouts, incumbentsRD, entrantsRD]


end

function computeWelfareImprovement(modelPar::ModelParameters,wold::Real,wnew::Real) 

    return -((abs(wnew) / abs(wold)) - 1) * 100 * abs(1-modelPar.θ)

end