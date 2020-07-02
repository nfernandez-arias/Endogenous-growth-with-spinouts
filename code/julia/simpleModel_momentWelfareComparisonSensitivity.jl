#----------------------------------------------------#
# Name: simpleModel_momentWelfareComparisonSensitivity.jl
#
# Function: Constructs plots showing semi elasticity of
# welfare improvement of reducing κC to 0 to values of
# target moments used in calibration.
#
#
#----------------------------------------------------#


using Revise
#using JLD2, FileIO

using EndogenousGrowthWithSpinouts_SimpleModel, LaTeXStrings, Measures, Plots, LinearAlgebra
gr()

modelPar = initializeSimpleModel()


gradient = constructWelfareComparisonFullGradient(modelPar)

x = Vector{Float64}(undef,9)

x[1] = log(modelPar.ρ)
x[2] = log(modelPar.θ)
x[3] = log(modelPar.β)
x[4] = log(modelPar.ψ)
x[5] = log(modelPar.λ)
x[6] = log(modelPar.χI)
x[7] = log(modelPar.χE)
x[8] = log(modelPar.κE)
x[9] = log(modelPar.ν)

grad = gradient(x)

fnt = Plots.font("sans-serif", 9)
fnt2 = Plots.font("sans-serif", 18)
fnt3 = Plots.font("sans-serif", 24)

# Plot gradient

xAxisLabels = ["\$ \\rho \$"; "\$ \\theta \$"; "\$ \\beta \$"; "\$ \\psi \$"; "\$ \\lambda \$"; "\$ \\chi_I \$"; "\$ \\chi_E \$"; "\$ \\kappa_E \$"; "\$ \\nu \$"]

p = bar(xAxisLabels,grad,xticks = :all, title = "\$ \\nabla_p \\log (\\textrm{CEV Welfare chg. \\%}) \$",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)
savefig(p,"figures/simpleModel/welfareComparisonParameterSensitivityFull.png")

jacobian = constructFullJacobian(modelPar)
jac = jacobian(x)
invjac = inv(float.(jac))

sensitivity = transpose(invjac) * grad

# Plot results

xAxisLabels = ["r"; "g"; "OI"; "E"; "S"; "RD"; "\$ \\Large \\theta \$"; "\$ \\Large  \\beta \$"; "\$ \\Large  \\psi \$"]


p = bar(xAxisLabels, transpose(invjac) * grad, xticks = :all, title = "\$ \\nabla_m \\log (\\textrm{CEV Welfare chg. \\%}) \$",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)

savefig(p,"figures/simpleModel/welfareComparisonSensitivityFull.png")

# Standard deviation of log of each parameter
σ = 0.1

# Standard error
var = transpose(sensitivity) * (σ^2 * I) * sensitivity
sd_logs = sqrt(var)




## Semi-elasticity

fnt = Plots.font("sans-serif", 9)
fnt2 = Plots.font("sans-serif", 18)
fnt3 = Plots.font("sans-serif", 24)

gradient = constructLevelsWelfareComparisonFullGradient(modelPar)

grad = gradient(x)

xAxisLabels = ["\$ \\rho \$"; "\$ \\theta \$"; "\$ \\beta \$"; "\$ \\psi \$"; "\$ \\lambda \$"; "\$ \\chi_I \$"; "\$ \\chi_E \$"; "\$ \\kappa_E \$"; "\$ \\nu \$"]
p = bar(xAxisLabels,grad,xticks = :all, title = "\$ \\nabla_p (\\textrm{CEV Welfare chg. \\%}) \$",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)
savefig(p,"figures/simpleModel/levelsWelfareComparisonParameterSensitivityFull.png")

jacobian = constructFullJacobian(modelPar)
jac = jacobian(x)
invjac = inv(float.(jac))

sensitivity = transpose(invjac) * grad

# Plot results

xAxisLabels = ["r"; "g"; "OI"; "E"; "S"; "RD"; "\$ \\Large \\theta \$"; "\$ \\Large  \\beta \$"; "\$ \\Large  \\psi \$"]

fnt = Plots.font("sans-serif", 9)
fnt2 = Plots.font("sans-serif", 18)
fnt3 = Plots.font("sans-serif", 24)
p = bar(xAxisLabels, sensitivity, xticks = :all, title = "\$ \\nabla_m (\\textrm{CEV Welfare chg. \\%}) \$",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)

savefig(p,"figures/simpleModel/levelsWelfareComparisonSensitivityFull.png")

## Calculation of standard errors

# Standard deviation of log of each parameter
σ = 0.1

# Standard error
var = transpose(sensitivity) * (σ^2 * I) * sensitivity
sd_levels = sqrt(var)
