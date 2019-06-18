#------------------------------------------------#
#
# File name: mergeRDwithSpinoutCounts.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This merges the SpinoutCounts dataset with the 
# R&D and parent-firm location data from compustat. 
#------------------------------------------------#

rm(list = ls())

compustat <- fread("raw/compustat/compustat_annual.csv")
compustat <- compustat[indfmt=="INDL" & datafmt=="STD" & popsrc=="D" & consol=="C"]
compustat <- compustat[ , .(gvkey,fyear,datadate,state,xrd,emp,revt,intan,act,sic,naics)]
compustat <- compustat[!is.na(fyear)]

# Use 4-digit NAICS codes
#compustat[, naics := str_extract(naics,"")]

parentsSpinoutCounts <- fread("data/parentsSpinoutCounts.csv")

setkey(compustat,gvkey,fyear)
setkey(parentsSpinoutCounts,gvkey,year)  

output <- parentsSpinoutCounts[compustat]

output[is.na(spinoutCount) == TRUE, spinoutCount := 0]
output[is.na(spinoutCountUnweighted) == TRUE, spinoutCountUnweighted := 0]
output[is.na(spinoutCountUnweighted_onlyExits) == TRUE, spinoutCountUnweighted_onlyExits := 0]
output[is.na(spinoutsDiscountedExitValue) == TRUE, spinoutsDiscountedExitValue := 0]
output[is.na(spinoutCountUnweighted_discountedByTimeToExit) == TRUE, spinoutCountUnweighted_discountedByTimeToExit := 0]

output[spinoutCountUnweighted >= 1 , spinoutIndicator := 1]
output[spinoutCountUnweighted == 0, spinoutIndicator := 0]

output[spinoutCountUnweighted_onlyExits >= 1 , exitSpinoutIndicator := 1]
output[spinoutCountUnweighted_onlyExits == 0, exitSpinoutIndicator := 0]

output[spinoutsDiscountedExitValue >= 0.43 , valuableSpinoutIndicator := 1]
output[spinoutsDiscountedExitValue < 0.43, valuableSpinoutIndicator := 0]

fwrite(output,"data/compustat-spinouts.csv")
  










