#----------------------------------------------------#
# Name: simpleModel_identificationSourcesCalibrationSensitivity.jl
#
# Function: Constructs plots showing elasticity of
# moments to parameters and elasticity of parameters to moments
# Both are based on the jacobian of computeSimpleModelMoments,
# which is calculated using the funciton constructJacobian.
#
#
# This means for each of the 6 moments, I show the
# effect of increasing each of the 6 indirectly
# estimated parameters on that moment. This tells me
# how my identification is working.
#
#----------------------------------------------------#


using Revise
#using JLD2, FileIO

using EndogenousGrowthWithSpinouts_SimpleModel, LaTeXStrings, Measures, Plots
gr()

modelPar = initializeSimpleModel()

# Compute and display identification sources matrix
# based on jacobian of computeSimpleModelMoments
# computed using automatic differntiation in function constructJacobian(modelPar::SimpleModelParameters)

jacobian = constructJacobian(modelPar)
fullJacobian = constructFullJacobian(modelPar)

x = Vector{Float64}(undef,8)

x[1] = log(modelPar.ρ)
x[2] = log(modelPar.λ)
x[3] = log(modelPar.χI)
x[4] = log(modelPar.χE)
x[5] = log(modelPar.κE)
x[6] = log(modelPar.ν)
x[7] = log(modelPar.L)
x[8] = log(modelPar.β)

jac = jacobian(x)
jacSmall = jac[1:6,1:6]

x = Vector{Float64}(undef,10)

x[1] = log(modelPar.ρ)
x[2] = log(modelPar.θ)
x[3] = log(modelPar.ψ)
x[4] = log(modelPar.λ)
x[5] = log(modelPar.χI)
x[6] = log(modelPar.χE)
x[7] = log(modelPar.κE)
x[8] = log(modelPar.ν)
x[9] = log(modelPar.L)
x[10] = log(modelPar.β)

jac2 = fullJacobian(x)
jac2Small = jac2[1:9,1:9]


fnt = Plots.font("sans-serif", 9)
fnt2 = Plots.font("sans-serif", 13)

fnt_legend = Plots.font("computer modern", 7)
fnt_ticksGuides = Plots.font("computer modern", 9)
fnt_ticksGuides2 = Plots.font("computer modern",13)
fnt_title = Plots.font("computer modern",9)


#xAxisLabels = ["\$ \\rho \$"; "\$ \\lambda \$"; "\$ \\chi \$"; L"\chi_e"; "\$ \\kappa_e \$"; "\$ \\nu \$"]

xAxisLabels = [L"\rho"; L"\lambda"; L"\chi"; L"\hat{\chi}"; L"\kappa_e"; L"\nu"]

p1 = bar(xAxisLabels, jacSmall[1,:], xticks = :all, title = "Interest rate")
p2 = bar(xAxisLabels, jacSmall[2,:], xticks = :all, title = "Growth rate")
p3 = bar(xAxisLabels, jacSmall[3,:], xticks = :all, title = "Firm age > 6 growth share")
p4 = bar(xAxisLabels, jacSmall[4,:], xticks = :all, title = "Firm age < 6 employment share")
p5 = bar(xAxisLabels, jacSmall[5,:], xticks = :all, title = "Spinout employment share")
p6 = bar(xAxisLabels, jacSmall[6,:], xticks = :all, title = "R&D (% GDP)")

p = plot(p1,p2,p3,p4,p5,p6, bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (666,500), legend = false)

savefig(p,"figures/simpleModel/identificationSources.pdf")
savefig(p,"figures/simpleModel/identificationSources.png")

xAxisLabels = [L"\rho"; L"\lambda"; L"\chi"; L"\hat{\chi}"; L"\kappa_e"; L"\nu"; L"L_{RD}"; L"\beta"]

p1 = bar(xAxisLabels, jac[1,:], xticks = :all, title = "Interest rate")
p2 = bar(xAxisLabels, jac[2,:], xticks = :all, title = "Growth rate")
p3 = bar(xAxisLabels, jac[3,:], xticks = :all, title = "Firm age > 6 growth share")
p4 = bar(xAxisLabels, jac[4,:], xticks = :all, title = "Firm age < 6 employment share")
p5 = bar(xAxisLabels, jac[5,:], xticks = :all, title = "Spinout employment share")
p6 = bar(xAxisLabels, jac[6,:], xticks = :all, title = "R&D (% GDP)")
p7 = bar(xAxisLabels, jac[7,:], xticks = :all, title = "R&D (% Employment)")
p8 = bar(xAxisLabels, jac[8,:], xticks = :all, title = "Profit (%GDP)")

p = plot(p1,p2,p3,p4,p5,p6,p7,p8, bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (666,500), legend = false)

savefig(p,"figures/simpleModel/identificationSourcesAll.pdf")
savefig(p,"figures/simpleModel/identificationSourcesAll.png")

######
# Compute and display calibration sensitivity matrix
# based on inverse of jac
#
# This matrix shows the sensitivity of the calibrated
# parameters to to the various moments used to calibrate them
# (also in elasticity terms)

jacInv = inv(float.(jac))
jacInvSmall = jacInv[1:6,1:6]
fnt2 = Plots.font("sans-serif", 7)
fnt3 = Plots.font("sans-serif", 17)
xAxisLabels = ["r"; "g"; "I"; "E"; "S"; "RD"]

p1 = bar(xAxisLabels, jacInvSmall[1,:], xticks = :all, title = "\$ \\rho \$", rotation = 0)
p2 = bar(xAxisLabels, jacInvSmall[2,:], xticks = :all, title = "\$ \\lambda \$", rotation = 0)
p3 = bar(xAxisLabels, jacInvSmall[3,:], xticks = :all, title = "\$ \\chi \$", rotation = 0)
p4 = bar(xAxisLabels, jacInvSmall[4,:], xticks = :all, title = L"\hat{\chi}", rotation = 0)
p5 = bar(xAxisLabels, jacInvSmall[5,:], xticks = :all, title = "\$ \\kappa_E \$", rotation = 0)
p6 = bar(xAxisLabels, jacInvSmall[6,:], xticks = :all, title = "\$ \\nu \$", rotation = 0)

p = plot(p1,p2,p3,p4,p5,p6,bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (800,600), legend = false)

savefig(p,"figures/simpleModel/calibrationSensitivity.pdf")
savefig(p,"figures/simpleModel/calibrationSensitivity.png")


xAxisLabels = ["r"; "g"; "I"; "E"; "S"; "RD/Y"; "RD/Emp"; "Prof/GDP"]

p1 = bar(xAxisLabels, jacInv[1,:], xticks = :all, title = "\$ \\rho \$", xrotation = 90)
p2 = bar(xAxisLabels, jacInv[2,:], xticks = :all, title = "\$ \\lambda \$", xrotation = 90)
p3 = bar(xAxisLabels, jacInv[3,:], xticks = :all, title = "\$ \\chi \$", xrotation = 90)
p4 = bar(xAxisLabels, jacInv[4,:], xticks = :all, title = L"\hat{\chi}", xrotation = 90)
p5 = bar(xAxisLabels, jacInv[5,:], xticks = :all, title = "\$ \\kappa_E \$", xrotation = 90)
p6 = bar(xAxisLabels, jacInv[6,:], xticks = :all, title = "\$ \\nu \$", xrotation = 90)
p7 = bar(xAxisLabels, jacInv[7,:], xticks = :all, title = L"L_{RD}", xrotation = 90)
p8 = bar(xAxisLabels, jacInv[8,:], xticks = :all, title = "\$ \\beta \$", xrotation = 90)

p = plot(p1,p2,p3,p4,p5,p6,p7,p8,bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (800,600), legend = false)

savefig(p,"figures/simpleModel/calibrationSensitivityAll.pdf")
savefig(p,"figures/simpleModel/calibrationSensitivityAll.png")


######
# Compute and display identification sources matrix
# based on jac2, i.e. see effect of uncalibrated parameters
# on the equilibrium.
#

xAxisLabels = ["\$ \\rho \$"; "\$ \\theta \$"; "\$ \\psi \$"; "\$ \\lambda \$"; "\$ \\chi \$"; L"\hat{\chi} "; "\$ \\kappa_E \$"; "\$ \\nu \$"; L"L_{RD}"]

p1 = bar(xAxisLabels, jac2Small[1,:], xticks = :all, title = "Interest rate", titlefont = Plots.font("sans-serif", 12))
p2 = bar(xAxisLabels, jac2Small[2,:], xticks = :all, title = "\$ \\theta \$", titlefont = Plots.font("sans-serif", 15))
p3 = bar(xAxisLabels, jac2Small[3,:], xticks = :all, title = "\$ \\psi \$", titlefont = Plots.font("sans-serif", 15))
p4 = bar(xAxisLabels, jac2Small[4,:], xticks = :all, title = "Growth rate", titlefont = Plots.font("sans-serif", 12))
p5 = bar(xAxisLabels, jac2Small[5,:], xticks = :all, title = "Firm age > 6 growth share", titlefont = Plots.font("sans-serif", 12))
p6 = bar(xAxisLabels, jac2Small[6,:], xticks = :all, title = "Firm age < 6 employment share", titlefont = Plots.font("sans-serif", 12))
p7 = bar(xAxisLabels, jac2Small[7,:], xticks = :all, title = "Spinout employment share", titlefont = Plots.font("sans-serif", 12))
p8 = bar(xAxisLabels, jac2Small[8,:], xticks = :all, title = "R&D (% GDP)", titlefont = Plots.font("sans-serif", 12))
p9 = bar(xAxisLabels, jac2Small[9,:], xticks = :all, title = "R&D (% Employment)", titlefont = Plots.font("sans-serif", 12))

p = plot(p1,p2,p3,p4,p5,p6,p7,p8,p9,bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (800,600), legend = false)

savefig(p,"figures/simpleModel/identificationSourcesFull_withRDEmp.pdf")
savefig(p,"figures/simpleModel/identificationSourcesFull_withRDEmp.png")


xAxisLabels = ["\$ \\rho \$"; "\$ \\theta \$"; "\$ \\psi \$"; "\$ \\lambda \$"; "\$ \\chi \$"; L"\hat{\chi} "; "\$ \\kappa_E \$"; "\$ \\nu \$"; "\$ L_{RD} \$"; "\$ \\beta \$"]

p1 = bar(xAxisLabels, jac2[1,:], xticks = :all, title = "Interest rate", titlefont = Plots.font("sans-serif", 12), xrotation = 90)
p2 = bar(xAxisLabels, jac2[2,:], xticks = :all, title = "\$ \\theta \$", titlefont = Plots.font("sans-serif", 15), xrotation = 90)
p3 = bar(xAxisLabels, jac2[3,:], xticks = :all, title = "\$ \\psi \$", titlefont = Plots.font("sans-serif", 15), xrotation = 90)
p4 = bar(xAxisLabels, jac2[4,:], xticks = :all, title = "Growth rate", titlefont = Plots.font("sans-serif", 12), xrotation = 90)
p5 = bar(xAxisLabels, jac2[5,:], xticks = :all, title = "Firm age > 6 growth share", titlefont = Plots.font("sans-serif", 12), xrotation = 90)
p6 = bar(xAxisLabels, jac2[6,:], xticks = :all, title = "Firm age < 6 employment share", titlefont = Plots.font("sans-serif", 12), xrotation = 90)
p7 = bar(xAxisLabels, jac2[7,:], xticks = :all, title = "Spinout employment share", titlefont = Plots.font("sans-serif", 12), xrotation = 90)
p8 = bar(xAxisLabels, jac2[8,:], xticks = :all, title = "R&D (% GDP)", titlefont = Plots.font("sans-serif", 12), xrotation = 90)
p9 = bar(xAxisLabels, jac2[9,:], xticks = :all, title = "R&D (% Employment)", titlefont = Plots.font("sans-serif", 15), xrotation = 90)
p10 = bar(xAxisLabels, jac2[10,:], xticks = :all, title = "Profit (%GDP)", titlefont = Plots.font("sans-serif", 15), xrotation = 90)


p = plot(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (800,600), legend = false)

savefig(p,"figures/simpleModel/identificationSourcesFull_All.pdf")
savefig(p,"figures/simpleModel/identificationSourcesFull_All.png")



######
# Compute and display calibration sensitivity matrix
# based on inverse of jac2, i.e. including sensitivity
# to uncalibrated parameters (those based on literature)
#

jac2Inv = inv(float.(jac2))
jac2InvSmall = jac2Inv[1:9,1:9]
fnt2 = Plots.font("sans-serif", 10)
fnt3 = Plots.font("sans-serif", 17)
xAxisLabels = ["r"; "g"; "I"; "E"; "S"; "RD"; L"\theta"; L"\beta"; L"\psi"]

p1 = bar(xAxisLabels, jac2Inv[1,:], xticks = :all, title = "\$ \\rho \$", xrotation = 0)
p2 = bar(xAxisLabels, jac2Inv[2,:], xticks = :all, title = "\$ \\theta \$", xrotation = 0)
p3 = bar(xAxisLabels, jac2Inv[3,:], xticks = :all, title = "\$ \\psi \$", xrotation = 0)
p4 = bar(xAxisLabels, jac2Inv[4,:], xticks = :all, title = "\$ \\lambda \$", xrotation = 0)
p5 = bar(xAxisLabels, jac2Inv[5,:], xticks = :all, title = "\$ \\chi \$", xrotation = 0)
p6 = bar(xAxisLabels, jac2Inv[6,:], xticks = :all, title = L"\hat{\chi}", xrotation = 0)
p7 = bar(xAxisLabels, jac2Inv[7,:], xticks = :all, title = "\$ \\kappa_E \$", xrotation = 0)
p8 = bar(xAxisLabels, jac2Inv[8,:], xticks = :all, title = "\$ \\nu \$", xrotation = 0)
p9 = bar(xAxisLabels, jac2Inv[9,:], xticks = :all, title = "\$ \\beta \$", xrotation = 0)

p = plot(p1,p2,p3,p4,p5,p6,p7,p8,p9,bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (800,600), legend = false)

savefig(p,"figures/simpleModel/calibrationSensitivityFull.pdf")
savefig(p,"figures/simpleModel/calibrationSensitivityFull.png")




jac2Inv = inv(float.(jac2))
fnt2 = Plots.font("sans-serif", 10)
fnt3 = Plots.font("sans-serif", 17)
xAxisLabels = ["r"; "g"; "I"; "E"; "S"; "RD"; L"\theta"; L"\beta"; L"\psi"]

p1 = bar(xAxisLabels, jac2Inv[1,:], xticks = :all, title = "\$ \\rho \$", xrotation = 0)
p2 = bar(xAxisLabels, jac2Inv[2,:], xticks = :all, title = "\$ \\theta \$", xrotation = 0)
p3 = bar(xAxisLabels, jac2Inv[3,:], xticks = :all, title = "\$ \\beta \$", xrotation = 0)
p4 = bar(xAxisLabels, jac2Inv[4,:], xticks = :all, title = "\$ \\psi \$", xrotation = 0)
p5 = bar(xAxisLabels, jac2Inv[5,:], xticks = :all, title = "\$ \\lambda \$", xrotation = 0)
p6 = bar(xAxisLabels, jac2Inv[6,:], xticks = :all, title = "\$ \\chi \$", xrotation = 0)
p7 = bar(xAxisLabels, jac2Inv[7,:], xticks = :all, title = L"\hat{\chi}", xrotation = 0)
p8 = bar(xAxisLabels, jac2Inv[8,:], xticks = :all, title = "\$ \\kappa_E \$", xrotation = 0)
p9 = bar(xAxisLabels, jac2Inv[9,:], xticks = :all, title = "\$ \\nu \$", xrotation = 0)

p = plot(p1,p2,p3,p4,p5,p6,p7,p8,p9,bottom_margin = 10mm, xguidefontsize = 16, yguidefont = fnt_ticksGuides, titlefont = fnt_title, xtickfont = fnt_ticksGuides, ytickfont = fnt_ticksGuides, size = (800,600), legend = false)

savefig(p,"figures/simpleModel/calibrationSensitivityFull_All.pdf")
savefig(p,"figures/simpleModel/calibrationSensitivityFull_All.png")
