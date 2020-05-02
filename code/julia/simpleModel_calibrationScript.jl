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
#using JLD2, FileIO

using EndogenousGrowthWithSpinouts

#-------------------------------#
# Set initial parameter settings, guess
#-------------------------------#

modelPar = initializeSimpleModel()

#-------------------------------#
# Enter calibration targets
#-------------------------------#

interestRate = SimpleCalibrationTarget(0.06,1)
growthRate = SimpleCalibrationTarget(0.013,1)
growthShareOI = SimpleCalibrationTarget(0.70,1)
youngFirmEmploymentShare = SimpleCalibrationTarget(0.06,1)
spinoutEmploymentShare = SimpleCalibrationTarget(0.0667,1)
rdShare = SimpleCalibrationTarget(0.015,1)

calibPar = SimpleCalibrationParameters(interestRate,growthRate,growthShareOI,youngFirmEmploymentShare,spinoutEmploymentShare,rdShare)

#-------------------------------#
# Run calibration
#-------------------------------#

@time calibrationResults,finalMoments,sol,finalScore = calibrateModel(modelPar,calibPar)

println(calibrationResults)

println("Score: $finalScore")

println("\nMinimizer: \n\n")

println("ρ = $(calibrationResults.minimizer[1])")
println("λ = $(calibrationResults.minimizer[2])")
println("χI = $(calibrationResults.minimizer[3])")
println("χE = $(calibrationResults.minimizer[4] * calibrationResults.minimizer[3])")
println("κE = $(calibrationResults.minimizer[5])")
println("ν = $(calibrationResults.minimizer[6] * calibrationResults.minimizer[3]))")

println("Moments: $finalMoments\n\n")

println("Format : (target, model)\n")

println("Interest rate: ($(interestRate.value) , $(finalMoments.interestRate))")
println("Growth rate: ($(growthRate.value) , $(finalMoments.growthRate))")
println("Growth share OI: ($(growthShareOI.value) , $(finalMoments.growthShareOI))")
println("Young firm emp. share: ($(youngFirmEmploymentShare.value) , $(finalMoments.youngFirmEmploymentShare))")
println("Spinout emp. share: ($(spinoutEmploymentShare.value) , $(finalMoments.spinoutEmploymentShare))")
println("RD share: ($(rdShare.value) , $(finalMoments.rdShare))")

#println("Wage ratio (average R&D wage to production wage): ($(WageRatio.value) , $(modelMoments.WageRatio))")
#println("Wage ratio incumbents (same but only incumbents): ($(WageRatioIncumbents.value) , $(modelMoments.WageRatioIncumbents))")
#println("Spinouts NC Share: ($(SpinoutsNCShare.value) , $(modelMoments.SpinoutsNCShare))")


#-------------------------------#
# Display diagnostics
#-------------------------------#


f = open("./figures/SimpleModelcalibration_output.txt","w")

write(f,"$calibrationResults\n\n")

write(f,"Score: $finalScore\n")

write(f,"\nMinimizer: \n\n\n")

write(f,"ρ = $(calibrationResults.minimizer[1])\n")
write(f,"λ = $(calibrationResults.minimizer[2])\n")
write(f,"χI = $(calibrationResults.minimizer[3])\n")
write(f,"χE = $(calibrationResults.minimizer[4] * calibrationResults.minimizer[3])\n")
write(f,"κE = $(calibrationResults.minimizer[5])\n")
write(f,"ν = $(calibrationResults.minimizer[6] * calibrationResults.minimizer[3]))\n\n")

write(f,"Moments: $finalMoments\n\n\n")

write(f,"Format : (target, model)\n\n")

write(f,"Interest rate: ($(interestRate.value) , $(finalMoments.interestRate))\n")
write(f,"Growth rate: ($(growthRate.value) , $(finalMoments.growthRate))\n")
write(f,"Growth share OI: ($(growthShareOI.value) , $(finalMoments.growthShareOI))\n")
write(f,"Young firm emp. share: ($(youngFirmEmploymentShare.value) , $(finalMoments.youngFirmEmploymentShare))\n")
write(f,"Spinout emp. share: ($(spinoutEmploymentShare.value) , $(finalMoments.spinoutEmploymentShare))\n")
write(f,"RD share: ($(rdShare.value) , $(finalMoments.rdShare))\n")

#write(f,"Wage ratio (average R&D wage to production wage): ($(WageRatio.value) , $(modelMoments.WageRatio))\n")
#write(f,"Wage ratio incumbents (same but only incumbents): ($(WageRatioIncumbents.value) , $(modelMoments.WageRatioIncumbents))\n")
#write(f,"Spinouts NC Share: ($(SpinoutsNCShare.value) , $(modelMoments.SpinoutsNCShare))\n")

close(f)
