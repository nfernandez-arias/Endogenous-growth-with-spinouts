# This file contains the code
# for plotting the solution to the simple expository model

using Plots
gr()

export SimpleModelParameters, SimpleModelSolution, solveSimpleModel, computeWelfareComparison, initializeSimpleModel, makePlots, SimpleCalibrationTarget,SimpleCalibrationParameters,SimpleModelMoments,SimpleModelParameterLimit,SimpleModelParameterLimitList,welfareComparison


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
    # Welfare
    W::Real
    # Welfare 2 (not considering costs of entry or NCA enforcement)
    W2::Real

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
    zE = min(L,((χE * (1-κE) * λ)/ denom)^(1/ψ))

    # Compute τE
    τE = χE * zE^(1-ψ)

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
    wRD_NCA = V * denom

    # Compute final goods labor
    LF = (1 - L) / (1 + ( (1 - β) ./ Cβ(β))^(1/β))

    # Compute output
    Y = ((1-β)^(1-2*β)) / (β^(1-β)) * LF

    # Compute welfare
    W = (Y - τE * κE * λ * V - x * zI * ν * κC * V - τS * κE * λ * V)^(1-θ) / ((1-θ) * ( ρ - g * (1-θ)))

    # Compute welfare
    W2 = (Y)^(1-θ) / ((1-θ)*( ρ - g * (1-θ)))

    sol = SimpleModelSolution(V,zI,τI,zE,τE,τS,x,wRD_NCA,r,g,Y,W,W2)
    return sol

end

function solveSimpleModel(κC::Real,modelPar::SimpleModelParameters)

    modelPar.κC = κC

    sol = solveSimpleModel(modelPar)

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
