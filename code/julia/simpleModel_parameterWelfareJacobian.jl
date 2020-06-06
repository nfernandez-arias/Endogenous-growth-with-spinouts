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


jacobian = constructWelfareComparisonGradient(modelPar)

x = Vector{Float64}(undef,6)

x[1] = log(modelPar.ρ)
x[2] = log(modelPar.λ)
x[3] = log(modelPar.χI)
x[4] = log(modelPar.χE)
x[5] = log(modelPar.κE)
x[6] = log(modelPar.ν)

jac = jacobian(x)
