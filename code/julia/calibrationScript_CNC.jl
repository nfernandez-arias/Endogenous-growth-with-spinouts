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

#RDintensity = CalibrationTarget(0.041,1)
InternalPatentShare = CalibrationTarget(0.7,1)
SpinoutEntryRate = CalibrationTarget(0.025,1)
SpinoutShare = CalibrationTarget(0.25,1)
g = CalibrationTarget(0.02,1)
#RDLaborAllocation = CalibrationTarget(.08,1)
#WageRatio = CalibrationTarget(0.9,1)
#WageRatioIncumbents = CalibrationTarget(0.7,0)
#SpinoutsNCShare = CalibrationTarget(0.5,1)

calibPar = CalibrationParameters(InternalPatentShare,SpinoutEntryRate,SpinoutShare,g)

#-------------------------------#
# Run calibration
#-------------------------------#

@time calibrationResults,modelMoments,modelResults,score = calibrateModel(algoPar,modelPar,initGuess,calibPar)

println(calibrationResults)

println("Score: $score")

println("\nMinimizer: \n\n")

println("χI = $(calibrationResults.minimizer[1])")
println("χE = $(calibrationResults.minimizer[2] * calibrationResults.minimizer[1])")
println("λ = $(calibrationResults.minimizer[3])")
println("ν = $(calibrationResults.minimizer[4])")

println("Moments: $modelMoments\n\n")

println("Format : (target, model)\n")

#println("R&D Intensity: ($(RDintensity.value) , $(modelMoments.RDintensity))")
println("Internal innovation share: ($(InternalPatentShare.value) , $(modelMoments.InternalPatentShare))")
println("Spinout Entry Rate: ($(SpinoutEntryRate.value) , $(modelMoments.SpinoutEntryRate))")
println("Spinout Fractions of entry: ($(SpinoutShare.value) , $(modelMoments.SpinoutShare))")
println("growth rate: ($(g.value) , $(modelMoments.g))")
#println("R&D Labor allocation: ($(RDLaborAllocation.value) , $(modelMoments.RDLaborAllocation))")
#println("Wage ratio (average R&D wage to production wage): ($(WageRatio.value) , $(modelMoments.WageRatio))")
#println("Wage ratio incumbents (same but only incumbents): ($(WageRatioIncumbents.value) , $(modelMoments.WageRatioIncumbents))")
#println("Spinouts NC Share: ($(SpinoutsNCShare.value) , $(modelMoments.SpinoutsNCShare))")


#-------------------------------#
# Display diagnostics
#-------------------------------#

if modelPar.CNC == true
    f = open("./figures/calibration_output_CNC.txt","w")
else
    f = open("./figures/calibration_output_noCNC.txt","w")
end

write(f,"$calibrationResults\n\n")

write(f,"Score: $score\n")

write(f,"\nMinimizer: \n\n\n")

write(f,"χI = $(calibrationResults.minimizer[1])\n")
#write(f,"χS = $(calibrationResults.minimizer[2])\n")
write(f,"χE = $(calibrationResults.minimizer[2] * calibrationResults.minimizer[1])\n")
write(f,"λ = $(calibrationResults.minimizer[3])\n")
write(f,"ν = $(calibrationResults.minimizer[4])\n")
#write(f,"θ = $(calibrationResults.minimizer[8])\n")
#write(f,"ζ = $(calibrationResults.minimizer[6])\n")
#write(f,"κ = $(calibrationResults.minimizer[7])\n\n")

write(f,"Moments: $modelMoments\n\n\n")


write(f,"Format : (target, model)\n\n")

#write(f,"R&D Intensity: ($(RDintensity.value) , $(modelMoments.RDintensity))\n")
write(f,"Internal innovation share: ($(InternalPatentShare.value) , $(modelMoments.InternalPatentShare))\n")
write(f,"Spinout Entry Rate: ($(SpinoutEntryRate.value) , $(modelMoments.SpinoutEntryRate))\n")
write(f,"Spinout Fractions of entry: ($(SpinoutShare.value) , $(modelMoments.SpinoutShare))\n")
write(f,"growth rate: ($(g.value) , $(modelMoments.g))\n")
#write(f,"R&D Labor allocation: ($(RDLaborAllocation.value) , $(modelMoments.RDLaborAllocation))\n")
#write(f,"Wage ratio (average R&D wage to production wage): ($(WageRatio.value) , $(modelMoments.WageRatio))\n")
#write(f,"Wage ratio incumbents (same but only incumbents): ($(WageRatioIncumbents.value) , $(modelMoments.WageRatioIncumbents))\n")
#write(f,"Spinouts NC Share: ($(SpinoutsNCShare.value) , $(modelMoments.SpinoutsNCShare))\n")

close(f)


# Store results in JLD2 file
if modelPar.CNC == true
    @save "output/calibrationResults_CNC.jld2" modelMoments modelResults score
else
    @save "output/calibrationResults_noCNC.jld2" modelMoments modelResults score
end


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
