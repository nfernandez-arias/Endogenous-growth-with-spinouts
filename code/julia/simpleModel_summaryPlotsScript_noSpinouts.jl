

using Revise, EndogenousGrowthWithSpinouts_SimpleModel


#modelPar = initializeSimpleModel()

#makePlots(modelPar,"noSpinouts")
makePlotsRDSubsidy(modelPar,"noSpinouts")
makePlotsEntryTax(modelPar,"noSpinouts")
makePlotsRDSubsidyTargeted(modelPar,"noSpinouts")
#makePlotsALL(modelPar,"noSpinouts")

#interestRate = SimpleCalibrationTarget(0.06,1)
#growthRate = SimpleCalibrationTarget(0.013,1)
#growthShareOI = SimpleCalibrationTarget(0.7,1)
#youngFirmEmploymentShare = SimpleCalibrationTarget(0.04,1)
#spinoutEmploymentShare = SimpleCalibrationTarget(0.137,1)
#rdShare = SimpleCalibrationTarget(0.015,1)

#calibPar = SimpleCalibrationParameters(interestRate,growthRate,growthShareOI,youngFirmEmploymentShare,spinoutEmploymentShare,rdShare)
#calibrationResults,finalMoments,sol,finalScore = calibrateModel(modelPar,calibPar)
#makePlots(modelPar,"calibration3_lowEntry")
