#----------------------------------------------------#
# Name: calibrationScript.jl
#
# Function: runs (very preliminary) calibration using
# six moments and six parameters.
#
#----------------------------------------------------#

#-------------------------------#
# Import modules
#-------------------------------#

using Revise
using JLD2, FileIO

include("loadPath.jl")
using EndogenousGrowthWithSpinouts

#-------------------------------#
# Set initial parameter settings, guess
#-------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#-------------------------------#
# Enter calibration targets
#-------------------------------#

RDintensity = CalibrationTarget(0.11,1)
InternalPatentShare = CalibrationTarget(0.5,0.5)
SpinoutEntryRate = CalibrationTarget(0.03,1)
SpinoutShare = CalibrationTarget(0.3,1)
g = CalibrationTarget(0.015,1)
RDLaborAllocation = CalibrationTarget(.1,1)
WageRatio = CalibrationTarget(0.7,1)
SpinoutsNCShare = CalibrationTarget(0.5,1)

calibPar = CalibrationParameters(RDintensity,InternalPatentShare,SpinoutEntryRate,SpinoutShare,g,RDLaborAllocation,WageRatio,SpinoutsNCShare)

#-------------------------------#
# Run calibration
#-------------------------------#

@time calibrationResults,modelMoments,modelResults,score = calibrateModel(algoPar,modelPar,initGuess,calibPar)

# Store results in JLD2 file
@save "output/calibrationResults_noCNC.jld2" calibrationResults modelMoments modelResults score

println(calibrationResults)

println("Score: $score")

println("\nMinimizer: \n\n")

println("χI = $(calibrationResults.minimizer[1])")
println("χS = $(calibrationResults.minimizer[2])")
println("χE = $(calibrationResults.minimizer[3] * calibrationResults.minimizer[3])")
println("λ = $(calibrationResults.minimizer[4])")
println("ν = $(calibrationResults.minimizer[5])")
println("θ = $(calibrationResults.minimizer[10])")
println("ζ = $(calibrationResults.minimizer[6])")
println("κ = $(calibrationResults.minimizer[7])")
println("spinoutsFromSpinouts = $(calibrationResults.minimizer[8])")
println("spinoutsFromEntrants = $(calibrationResults.minimizer[9])\n\n")

println("Moments: $modelMoments\n\n")


println("Format : (target, model)\n")

println("R&D Intensity: ($(RDintensity.value) , $(modelMoments.RDintensity))")
println("Internal innovation share: ($(InternalPatentShare.value) , $(modelMoments.InternalPatentShare))")
println("Spinout Entry Rate: ($(SpinoutEntryRate.value) , $(modelMoments.SpinoutEntryRate))")
println("Spinout Fractions of entry: ($(SpinoutShare.value) , $(modelMoments.SpinoutShare))")
println("growth rate: ($(g.value) , $(modelMoments.g))")
println("R&D Labor allocation: ($(RDLaborAllocation.value) , $(modelMoments.RDLaborAllocation))")
println("Wage ratio (R&D to production): ($(WageRatio.value) , $(modelMoments.WageRatio))")
println("Spinouts NC Share: ($(SpinoutsNCShare.value) , $(modelMoments.SpinoutsNCShare))")


#-------------------------------#
# Display diagnostics
#-------------------------------#

f = open("./figures/calibration_output_noCNC.txt","w")

write(f,"$calibrationResults\n\n")

write(f,"Score: $score\n")

write(f,"\nMinimizer: \n\n\n")

write(f,"χI = $(calibrationResults.minimizer[1])\n")
write(f,"χS = $(calibrationResults.minimizer[2])\n")
write(f,"χE = $(calibrationResults.minimizer[3] * calibrationResults.minimizer[3])\n")
write(f,"λ = $(calibrationResults.minimizer[4])\n")
write(f,"ν = $(calibrationResults.minimizer[5])\n")
write(f,"θ = $(calibrationResults.minimizer[10])\n")
write(f,"ζ = $(calibrationResults.minimizer[6])\n")
write(f,"κ = $(calibrationResults.minimizer[7])\n")
write(f,"spinoutsFromSpinouts = $(calibrationResults.minimizer[8])\n")
write(f,"spinoutsFromEntrants = $(calibrationResults.minimizer[9])\n\n\n")

write(f,"Moments: $modelMoments\n\n\n")


write(f,"Format : (target, model)\n\n")

write(f,"R&D Intensity: ($(RDintensity.value) , $(modelMoments.RDintensity))\n")
write(f,"Internal innovation share: ($(InternalPatentShare.value) , $(modelMoments.InternalPatentShare))\n")
write(f,"Spinout Entry Rate: ($(SpinoutEntryRate.value) , $(modelMoments.SpinoutEntryRate))\n")
write(f,"Spinout Fractions of entry: ($(SpinoutShare.value) , $(modelMoments.SpinoutShare))\n")
write(f,"growth rate: ($(g.value) , $(modelMoments.g))\n")
write(f,"R&D Labor allocation: ($(RDLaborAllocation.value) , $(modelMoments.RDLaborAllocation))\n")
write(f,"Wage ratio (R&D to production): ($(WageRatio.value) , $(modelMoments.WageRatio))\n")
write(f,"Spinouts NC Share: ($(SpinoutsNCShare.value) , $(modelMoments.SpinoutsNCShare))\n")

close(f)

#using Plots
#gr()

#--------------------------------#
# Make plots and compute statistics
#--------------------------------#

# rename here so I can reuse script..

#results = modelResults

#include("testPlots_calibration_noCNC.jl")

#--------------------------------#
# Compute diagnostics
#--------------------------------#

#include("testDiags.jl")
