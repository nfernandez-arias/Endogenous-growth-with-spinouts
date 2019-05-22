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
compustat <- compustat[ , .(gvkey,conml,fyear,datadate,state,xrd,emp,revt,ni,sic,naics)]
compustat <- compustat[!is.na(fyear)]
compustat <- compustat[!duplicated(compustat,by = c("gvkey","fyear"))]

setindex(compustat,gvkey,fyear)

# Construct moving average of R&D
compustat[,xrd_ma3 := (1/3) * Reduce(`+`, shift(xrd, 0L:(3L-1L), type = "lag")), by = gvkey]
compustat[,xrd_ma5 := (1/5) * Reduce(`+`, shift(xrd, 0L:(5L-1L), type = "lag")), by = gvkey]

compustat <- compustat[order(gvkey,fyear)]

parentsSpinoutCounts <- fread("data/parentsSpinoutCounts.csv")

setkey(compustat,gvkey,fyear)
setkey(parentsSpinoutCounts,gvkey,year)

output <- parentsSpinoutCounts[compustat]

output[is.na(spinoutCount) == TRUE, spinoutCount := 0]
output[is.na(spinoutCountUnweighted) == TRUE, spinoutCountUnweighted := 0]

output[,spinoutCountUnweighted_ma2 := (1/2) * Reduce(`+`, shift(spinoutCountUnweighted, 0L:(2L-1L), type = "lead")), by = gvkey]
output[,spinoutCountUnweighted_ma3 := (1/3) * Reduce(`+`, shift(spinoutCountUnweighted, 0L:(3L-1L), type = "lead")), by = gvkey]

output[,spinoutCount_ma2 := (1/2) * Reduce(`+`, shift(spinoutCount, 0L:(2L-1L), type = "lead")), by = gvkey]
output[,spinoutCount_ma3 := (1/3) * Reduce(`+`, shift(spinoutCount, 0L:(3L-1L), type = "lead")), by = gvkey]

output[ , spinoutIndicator := (spinoutCount > 0)]
output[ , spinoutma2_Indicator := (spinoutCount_ma2 > 0)]
output[ , spinoutma3_Indicator := (spinoutCount_ma3 > 0)]

fwrite(output,"data/compustat-spinouts.csv")











