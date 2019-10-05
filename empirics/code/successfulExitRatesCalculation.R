#------------------------------------------------#
#
# File name: successfulExitRatesCalculation.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose: 
#
# This program computes the ratio of the fraction of spinouts who eventually successfully exit
# to the fraction of entrants who eventually successfully exit, for use in calibrating the model.
#------------------------------------------------#

rm(list = ls())

startupsExits <- fread("data/VentureSource/startupsExits.csv")

output <- startupsExits[ , sum(maxExit) / .N, by = "isSpinout"]



