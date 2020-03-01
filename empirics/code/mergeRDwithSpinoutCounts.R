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

## First read in compustat and construct some variables

compustat <- fread("data/compustat/compustat_withBloomInstruments.csv")

## Construct Tobin's Q
# (following methodology from WRDS)
# https://wrds-www.wharton.upenn.edu/pages/support/applications/risk-and-valuation-measures/tobins-q-altman-z-score-and-companys-age/
compustat <- compustat[ seq > 0]
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


parentsSpinoutCounts <- fread("data/parentsSpinoutCounts.csv")

setkey(compustat,gvkey,fyear)
setkey(parentsSpinoutCounts,gvkey,year)  

output <- parentsSpinoutCounts[compustat]

# When a count is NA, set equal to 0

countCols <- grep("spinouts|founders|dev|dffv", names(output), value = T)

for (col in countCols)
{
  set(output, which(is.na(output[[col]])), col, 0)
}

# Save data
fwrite(output,"data/compustat-spinouts.csv")

# Clean up
rm(compustat,output,parentsSpinoutCounts)










