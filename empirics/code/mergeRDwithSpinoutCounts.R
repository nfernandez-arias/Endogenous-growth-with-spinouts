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

output[is.na(spinoutCount) == TRUE, spinoutCount := 0]
output[is.na(spinoutCountUnweighted) == TRUE, spinoutCountUnweighted := 0]
output[is.na(spinoutCountUnweighted_onlyExits) == TRUE, spinoutCountUnweighted_onlyExits := 0]
output[is.na(spinoutsDiscountedExitValue) == TRUE, spinoutsDiscountedExitValue := 0]
output[is.na(spinoutCountUnweighted_discountedByTimeToExit) == TRUE, spinoutCountUnweighted_discountedByTimeToExit := 0]
output[is.na(spinoutsDiscountedFFValue) == TRUE, spinoutsDiscountedFFValue := 0]

output[is.na(spinouts_wso1), spinouts_wso1 := 0]
output[is.na(spinouts_wso2), spinouts_wso2 := 0]
output[is.na(spinouts_wso3), spinouts_wso3 := 0]
output[is.na(spinouts_wso4), spinouts_wso4 := 0]
output[is.na(spinouts_nonwso4), spinouts_nonwso4 := 0]
output[is.na(spinouts_wso5), spinouts_wso5 := 0]
output[is.na(spinouts_wso6), spinouts_wso6 := 0]

output[is.na(spinoutsUnweighted_wso1), spinoutsUnweighted_wso1 := 0]
output[is.na(spinoutsUnweighted_wso2), spinoutsUnweighted_wso2 := 0]
output[is.na(spinoutsUnweighted_wso3), spinoutsUnweighted_wso3 := 0]
output[is.na(spinoutsUnweighted_wso4), spinoutsUnweighted_wso4 := 0]
output[is.na(spinoutsUnweighted_nonwso4), spinoutsUnweighted_nonwso4 := 0]
output[is.na(spinoutsUnweighted_wso5), spinoutsUnweighted_wso5 := 0]
output[is.na(spinoutsUnweighted_wso6), spinoutsUnweighted_wso6 := 0]

output[is.na(spinoutsDFFV_wso1), spinoutsDFFV_wso1 := 0]
output[is.na(spinoutsDFFV_wso2), spinoutsDFFV_wso2 := 0]
output[is.na(spinoutsDFFV_wso3), spinoutsDFFV_wso3 := 0]
output[is.na(spinoutsDFFV_wso4), spinoutsDFFV_wso4 := 0]
output[is.na(spinoutsDFFV_nonwso4), spinoutsDFFV_nonwso4 := 0]
output[is.na(spinoutsDFFV_wso5), spinoutsDFFV_wso5 := 0]
output[is.na(spinoutsDFFV_wso6), spinoutsDFFV_wso6 := 0]

output[spinoutCountUnweighted >= 1 , spinoutIndicator := 1]
output[spinoutCountUnweighted == 0, spinoutIndicator := 0]

output[spinoutCountUnweighted_onlyExits >= 1 , exitSpinoutIndicator := 1]
output[spinoutCountUnweighted_onlyExits == 0, exitSpinoutIndicator := 0]

output[spinoutsDiscountedExitValue >= 0.43 , valuableSpinoutIndicator := 1]
output[spinoutsDiscountedExitValue < 0.43, valuableSpinoutIndicator := 0]

fwrite(output,"data/compustat-spinouts.csv")











