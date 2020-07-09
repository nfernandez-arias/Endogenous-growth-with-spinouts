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

xAxisLabels = [L"\rho"; L"\theta"; L"\beta"; L"\psi"; L"\lambda"; L"\chi"; L"\hat{\chi}"; L"\kappa_E"; L"\nu"]

#L"\nabla_p \log ( \text{CEV Welfare chg. \%})"

p = bar(xAxisLabels,grad,xticks = :all, title = L"\nabla_p \log\ ( CEV\ Welfare\ chg. \%)",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)
savefig(p,"figures/simpleModel/welfareComparisonParameterSensitivityFull.pdf")

jacobian = constructFullJacobian(modelPar)
jac = jacobian(x)
invjac = inv(float.(jac))

sensitivity = transpose(invjac) * grad

# Plot results

xAxisLabels = ["r"; "g"; "OI"; "E"; "S"; "RD"; L"\theta"; L"\beta"; L"\psi"]

p = bar(xAxisLabels, transpose(invjac) * grad, xticks = :all, title = L"\nabla_m \log\ ( CEV\ Welfare\ chg. \%)",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)

savefig(p,"figures/simpleModel/welfareComparisonSensitivityFull.pdf")

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

xAxisLabels = [L"\rho"; L"\theta"; L"\beta"; L"\psi"; L"\lambda"; L"\chi"; L"\hat{\chi}"; L"\kappa_E"; L"\nu"]
p = bar(xAxisLabels,grad,xticks = :all, title = L"\nabla_p\ ( CEV\ Welfare\ chg. \%)",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)
savefig(p,"figures/simpleModel/levelsWelfareComparisonParameterSensitivityFull.pdf")

jacobian = constructFullJacobian(modelPar)
jac = jacobian(x)
invjac = inv(float.(jac))

sensitivity = transpose(invjac) * grad

# Plot results

xAxisLabels = ["r"; "g"; "OI"; "E"; "S"; "RD"; L"\theta"; L"\beta"; L"\psi"]

fnt = Plots.font("sans-serif", 9)
fnt2 = Plots.font("sans-serif", 18)
fnt3 = Plots.font("sans-serif", 24)
p = bar(xAxisLabels, sensitivity, xticks = :all, title = L"\nabla_m\ ( CEV\ Welfare\ chg. \%)",xtickfont = fnt2, titlefont = fnt3, ytickfont = Plots.font("sans-serif", 16), guidefont = fnt, size = (1200,600), bottom_margin = 10mm, legend = false)
savefig(p,"figures/simpleModel/levelsWelfareComparisonSensitivityFull.pdf")

## Calculation of standard errors

# Standard deviation of log of each parameter
σ = 0.1

# Standard error
var = transpose(sensitivity) * (σ^2 * I) * sensitivity
sd_levels = sqrt(var)
