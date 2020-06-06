#----------------------------------------------------#
# Name: simpleModel_exhaustiveComparison.jl
#
# Function: Runs the welfare comparison on a grid of
# parameter values for all parameters, and visualizes results
#
#----------------------------------------------------#

using Revise
#using JLD2, FileIO
using Plots
gr()

using EndogenousGrowthWithSpinouts_SimpleModel

#-------------------------------#
# Set parameter limits
#-------------------------------#

modelPar = initializeSimpleModel()

#κC_max_global = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))

#lowFrac = 0.85
#highFrac = 1.15

#ρLimits = SimpleModelParameterLimit(lowFrac * modelPar.ρ, highFrac * modelPar.ρ)
#θLimits = SimpleModelParameterLimit(lowFrac * modelPar.θ, highFrac * modelPar.θ)
#βLimits = SimpleModelParameterLimit(lowFrac * modelPar.β, highFrac * modelPar.β)
#χELimits = SimpleModelParameterLimit(lowFrac * modelPar.χE, highFrac * modelPar.χE)
#χILimits = SimpleModelParameterLimit(lowFrac * modelPar.χI, highFrac * modelPar.χI)
#ψLimits = SimpleModelParameterLimit(lowFrac * modelPar.ψ, highFrac * modelPar.ψ)
#λLimits = SimpleModelParameterLimit(max(1.03,lowFrac * modelPar.λ), highFrac * modelPar.λ)
#νLimits = SimpleModelParameterLimit(lowFrac * modelPar.ν, highFrac * modelPar.ν)
#κELimits = SimpleModelParameterLimit(lowFrac * modelPar.κE, highFrac * modelPar.κE)

#parameterLimits = SimpleModelParameterLimitList(ρLimits,θLimits,βLimits,χELimits,χILimits,ψLimits,λLimits,νLimits,κELimits)

#results = welfareComparison(parameterLimits,3)


# Simple thing, with more grid points
numPoints = 500

# ρPlot
minVal = 0.01
maxVal = 0.05
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.ρ)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.ρ = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = ((abs(sol1.W) / abs(sol0.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end

ρPlot = plot(grid,resultsGrid, title = "Discount factor", xlabel = "\\rho", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()

# θPlot
minVal = 1.5
maxVal = 3.5
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.θ)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.θ = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = ((abs(sol1.W) / abs(sol0.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
θPlot = plot(grid,resultsGrid, title = "IES", xlabel = "\\theta", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()

# βPlot
minVal = 0.05
maxVal = 0.3
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.β)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.β = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = ((abs(sol1.W) / abs(sol0.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
βPlot = plot(grid,resultsGrid, title = "EOS across intermediates, labor share", xlabel = "\\beta", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()


# χEPlot
minVal = .05
maxVal = .4
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.χE)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.χE = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = -((abs(sol0.W) / abs(sol1.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
χEPlot = plot(grid,resultsGrid, title = "Entrant R&D prod.", xlabel = "\\chiE", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()



# χIPlot
minVal = 1.3
maxVal = 2.5
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.χI)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.χI = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = -((abs(sol0.W) / abs(sol1.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
χIPlot = plot(grid,resultsGrid, title = "Incumbent R&D prod.", xlabel = "\\chiI", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()



# ψPlot
minVal = 0.2
maxVal = 0.8
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.ψ)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.ψ = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = -((abs(sol0.W) / abs(sol1.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
ψPlot = plot(grid,resultsGrid, title = "Entrant R&D elasticity", xlabel = "\\psi", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()

# λPlot
minVal = 1.02
maxVal = 1.3
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.λ)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.λ = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = -((abs(sol0.W) / abs(sol1.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
λPlot = plot(grid,resultsGrid, title = "Quality ladder step size", xlabel = "\\lambda", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()



# νPlot
minVal = 0.01
maxVal = 0.1
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.ν)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.ν = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = -((abs(sol0.W) / abs(sol1.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
νPlot = plot(grid,resultsGrid, title = "Spinout formation parameter", xlabel = "nu", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()



# κEPlot
minVal = 0
maxVal = 0.99
step = (maxVal - minVal)/(numPoints -1)
grid = minVal:step:maxVal
calibratedVal = copy(modelPar.κE)
resultsGrid = zeros(size(grid))
for (i,val) in enumerate(grid)

    modelPar.κC = 0.0
    modelPar.κE = val
    sol0 = solveSimpleModel(modelPar)

    κC_max = max(0,2*(1 - (1-modelPar.κE)*modelPar.λ))
    modelPar.κC = κC_max

    sol1 = solveSimpleModel(modelPar)

    CEWelfareBoostNCAEnforcement = -((abs(sol0.W) / abs(sol1.W)) - 1) * 100 / abs(1-modelPar.θ)

    resultsGrid[i] = CEWelfareBoostNCAEnforcement

end
κEPlot = plot(grid,resultsGrid, title = "Cost of creative destruction", xlabel = "\\kappaE", ylabel = "% CE improvement")
vline!([calibratedVal])
modelPar = initializeSimpleModel()

fnt = Plots.font("sans-serif", 10)
p1 = plot(ρPlot,θPlot,βPlot,χEPlot,χIPlot,ψPlot,λPlot,νPlot,κEPlot, legend = false, xtickfont = fnt, ytickfont = fnt, guidefont = fnt, titlefont = fnt, size = (1000,730))

savefig(p1,"figures/simpleModel/welfareComparisonRobustness.pdf")


# Most important
# Hold n-1 parameters constant (at calibrated values), and show the plot when we move the remaining parameter



# Next, hold n-2 parameters constant (at calibrated values), and show the plot when we move the remaining parameter
# Problem is, this might be too much bc it means there would be 9*8/2 = 36 plots. But maybe doable.
