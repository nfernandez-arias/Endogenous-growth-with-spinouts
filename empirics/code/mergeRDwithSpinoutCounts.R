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

## First read in compustat and construct some variables

compustat <- fread("data/compustat/compustat_withBloomInstruments.csv")

## Construct Tobin's Q
# (following methodology from WRDS)
compustat <- compustat[ seq > 0]
coalesce <- dplyr::coalesce
compustat[ , pref := coalesce(pstkrv,pstkl,pstk)]
compustat[ , BE := seq + txdb + itcb - pref]
compustat[ , ME := prcc_c * csho]
compustat[ is.na(re), re := 0]
compustat[ is.na(act), act := 0]
compustat[ BE > 0 , MtB := ME / BE]
compustat[ , Tobin_Q := (at + ME - BE) / at]

setnames(compustat,"year","fyear")
compustat <- compustat[ , .(gvkey,fyear,Tobin_Q,datadate,loc,state,xrd,sale,lfirm,lfirm_bloom,lstate,lstate_bloom,capx,capxv,sppe,ppent,ebitda,ni,ch,emp,revt,intan,at,sic,naics)]
compustat <- compustat[!is.na(fyear)]

# Use 4-digit NAICS codes
#compustat[, naics := str_extract(naics,"")]

parentsSpinoutCounts <- fread("data/parentsSpinoutCounts.csv")

setkey(compustat,gvkey,fyear)
setkey(parentsSpinoutCounts,gvkey,year)  

output <- parentsSpinoutCounts[compustat]

#----------------------------------------#
# Clean up the resulting dataset
#----------------------------------------#

output[is.na(spinoutCount) == TRUE, spinoutCount := 0]
output[is.na(spinoutCountUnweighted) == TRUE, spinoutCountUnweighted := 0]
output[is.na(spinoutsDiscountedFFValue) == TRUE, spinoutsDiscountedFFValue := 0]

for (i in 1:6)
{
  wsoFlag <- paste("wso",i,sep = "")
  spinoutCountVar <- paste("spinoutCount_",wsoFlag,sep = "")
  spinoutCountUnweightedVar <- paste("spinoutCountUnweighted_",wsoFlag,sep = "")
  spinoutsDiscountedFFValueVar <- paste("spinoutsDiscountedFFValue_",wsoFlag,sep = "")
  
  output[is.na(get(spinoutCountVar)), (spinoutCountVar) := 0]
  output[is.na(get(spinoutCountUnweightedVar)), (spinoutCountUnweightedVar) := 0]
  output[is.na(get(spinoutsDiscountedFFValueVar)), (spinoutsDiscountedFFValueVar) := 0]
}


#--------------------------#
# Compute spinout counts for nonwso1,nonwso2,nonwso3,nonwso4
# This is just a simple difference of columns
#--------------------------#

for (i in 1:4)
{
  wsoFlag <- paste("wso",i,sep = "")
  
  spinoutCountVar <- paste("spinoutCount_",wsoFlag,sep = "")
  spinoutCountUnweightedVar <- paste("spinoutCountUnweighted_",wsoFlag,sep = "")
  spinoutsDiscountedFFValueVar <- paste("spinoutsDiscountedFFValue_",wsoFlag,sep = "")
  
  spinoutCountVar_new <- paste("spinoutCount_non",wsoFlag,sep = "")
  spinoutCountUnweightedVar_new <- paste("spinoutCountUnweighted_non",wsoFlag,sep = "")
  spinoutsDiscountedFFValueVar_new <- paste("spinoutsDiscountedFFValue_non",wsoFlag,sep = "")  
  
  output[ , c(spinoutCountVar_new,spinoutCountUnweightedVar_new,spinoutsDiscountedFFValueVar_new) := list(spinoutCount - get(spinoutCountVar), 
                                                                                                       spinoutCountUnweighted - get(spinoutCountUnweightedVar), spinoutsDiscountedFFValue - get(spinoutsDiscountedFFValueVar))]
}

fwrite(output,"data/compustat-spinouts.csv")











