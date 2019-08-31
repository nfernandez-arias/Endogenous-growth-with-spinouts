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

include("loadPath.jl")
using EndogenousGrowthWithSpinouts

#-------------------------------#
# Set initial parameter settings, guess
#-------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

modelPar.CNC = true

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

calibPar = CalibrationParameters(RDintensity,InternalPatentShare,SpinoutEntryRate,SpinoutShare,g,RDLaborAllocation,WageRatio)

#-------------------------------#
# Run calibration
#-------------------------------#

@time calibrationResults,modelMoments,modelResults,score = calibrateModel(algoPar,modelPar,initGuess,calibPar)

#gradient = calibrateModel(algoPar,modelPar,initGuess,calibPar)


println(calibrationResults)

println("Score: $score")

println("\nMinimizer: \n\n")

println("χI = $(calibrationResults.minimizer[1])")
println("χS = $(calibrationResults.minimizer[2])")
println("χE = $(calibrationResults.minimizer[3] * calibrationResults.minimizer[3])")
println("λ = $(calibrationResults.minimizer[4])")
println("ν = $(calibrationResults.minimizer[5])")
println("ζ = $(calibrationResults.minimizer[6])")
println("κ = $(calibrationResults.minimizer[7])")
println("spinoutsFromSpinouts = $(calibrationResults.minimizer[8])")
println("spinoutsFromEntrants = $(calibrationResults.minimizer[9])\n\n")

println("Moments: $moments\n\n")


println("Format : (target, model)\n")

println("R&D Intensity: ($(RDintensity.value) , $(modelMoments.RDintensity))")
println("Internal innovation share: ($(InternalPatentShare.value) , $(modelMoments.InternalPatentShare))")
println("R&D Intensity: ($(SpinoutEntryRate.value) , $(modelMoments.SpinoutEntryRate))")
println("R&D Intensity: ($(SpinoutShare.value) , $(modelMoments.SpinoutShare))")
println("R&D Intensity: ($(g.value) , $(modelMoments.g))")
println("R&D Intensity: ($(RDLaborAllocation.value) , $(modelMoments.RDLaborAllocation))")
println("R&D Intensity: ($(WageRatio.value) , $(modelMoments.WageRatio))")


#-------------------------------#
# Display diagnostics
#-------------------------------#

f = open("./figures/calibration_output_noCNC.txt","w")

write(f,"$results\n\n")

write(f,"Score: $score\n")

write(f,"\nMinimizer: \n\n\n")

write(f,"χI = $(calibrationResults.minimizer[1])\n")
write(f,"χS = $(calibrationResults.minimizer[2])\n")
write(f,"χE = $(calibrationResults.minimizer[3] * calibrationResults.minimizer[3])\n")
write(f,"λ = $(calibrationResults.minimizer[4])\n")
write(f,"ν = $(calibrationResults.minimizer[5])\n")
write(f,"ζ = $(calibrationResults.minimizer[6])\n")
write(f,"κ = $(calibrationResults.minimizer[7])\n")
write(f,"spinoutsFromSpinouts = $(calibrationResults.minimizer[8])\n")
write(f,"spinoutsFromEntrants = $(calibrationResults.minimizer[9])\n\n\n")

write(f,"Moments: $moments\n\n\n")


write(f,"Format : (target, model)\n\n")

write(f,"R&D Intensity: ($(RDintensity.value) , $(modelMoments.RDintensity))\n")
write(f,"Internal innovation share: ($(InternalPatentShare.value) , $(modelMoments.InternalPatentShare))\n")
write(f,"R&D Intensity: ($(SpinoutEntryRate.value) , $(modelMoments.SpinoutEntryRate))\n")
write(f,"R&D Intensity: ($(SpinoutShare.value) , $(modelMoments.SpinoutShare))\n")
write(f,"R&D Intensity: ($(g.value) , $(modelMoments.g))\n")
write(f,"R&D Intensity: ($(RDLaborAllocation.value) , $(modelMoments.RDLaborAllocation))\n")
write(f,"R&D Intensity: ($(WageRatio.value) , $(modelMoments.WageRatio))\n")

close(f)

using Plots
gr()

#--------------------------------#
# Make plots and compute statistics
#--------------------------------#

# rename here so I can reuse script..

results = modelResults

include("testPlots_calibration_noCNC.jl")

#--------------------------------#
# Compute diagnostics
#--------------------------------#

#include("testDiags.jl")
