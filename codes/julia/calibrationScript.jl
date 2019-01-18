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
using InitializationModule,AlgorithmParametersModule
using CalibrationModule

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

RDintensity = CalibrationTarget(0.2,1)
InternalPatentShare = CalibrationTarget(0.2,1)
EntryRate = CalibrationTarget(0.05,1)
SpinoutShare = CalibrationTarget(0.5,1)
g = CalibrationTarget(0.015,1)
RDLaborAllocation = CalibrationTarget(0.05,1)

calibPar = CalibrationParameters(RDintensity,InternalPatentShare,EntryRate,SpinoutShare,g,RDLaborAllocation)

#-------------------------------#
# Run calibration
#-------------------------------#

out = calibrateModel(algoPar,modelPar,initGuess,calibPar)

#-------------------------------#
# Display diagnostics
#-------------------------------#
