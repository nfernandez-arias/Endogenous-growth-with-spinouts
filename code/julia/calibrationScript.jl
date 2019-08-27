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

#-------------------------------#
# Enter calibration targets
#-------------------------------#

RDintensity = CalibrationTarget(0.11,1)
InternalPatentShare = CalibrationTarget(0.5,1)
SpinoutEntryRate = CalibrationTarget(0.03,1)
SpinoutShare = CalibrationTarget(0.3,1)
g = CalibrationTarget(0.015,1)
RDLaborAllocation = CalibrationTarget(.1,1)

calibPar = CalibrationParameters(RDintensity,InternalPatentShare,SpinoutEntryRate,SpinoutShare,g,RDLaborAllocation)

#-------------------------------#
# Run calibration
#-------------------------------#

@time results,moments,score = calibrateModel(algoPar,modelPar,initGuess,calibPar)

#gradient = calibrateModel(algoPar,modelPar,initGuess,calibPar)

println(results)
println("\nMinimizer: $(results.minimizer)")
println("Moments: $moments")
println("Score: $score")s

#-------------------------------#
# Display diagnostics
#-------------------------------#

f = open("./figures/calibration_output.txt","w")

write(f,"$results\n\n")
write(f,"Minimizer: $(results.minimizer)\n")
write(f,"Moments: $moments\n")
write(f,"Score: $score\n")

close(f)
