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
compustat <- compustat[ , .(gvkey,fyear,state,xrd,emp,sic,naics)]

# Use 4-digit NAICS codes
compustat[, naics := str_extract(naics,"")]

parentsSpinoutCounts <- fread("data/parentsSpinoutCounts.csv")

setkey(compustat,gvkey,fyear)
setkey(parentsSpinoutCounts,gvkey,year)

output <- parentsSpinoutCounts[compustat]

output[is.na(V1) == TRUE, V1 := 0]

setnames(output,"V1","spinoutCount")

output[ , spinoutIndicator := (spinoutCount >= 0.5)]

fwrite(output,"data/compustat-spinouts.csv")











