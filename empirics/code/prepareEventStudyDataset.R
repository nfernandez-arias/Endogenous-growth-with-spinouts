#------------------------------------------------#
#
# File name: prepareEventStudyDataset.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# Combines the CRSP daily dataset with the parents-spinouts 
# and the deals dataset to be able to do event study analysis
# on the effect of funding on parent firm stock prices
#
#------------------------------------------------#

rm(list = ls())
library(lubridate)
library(quantmod)

parentsSpinouts <- unique(fread("data/parentsSpinoutsExits_naics4.csv"), by = c("gvkey","EntityID"))

deals <- fread("raw/VentureSource/01Deals.csv")[order(EntityID,RoundNo)][, .(EntityID,RoundID,EntityName,CloseDate,RoundNo,RoundType,RoundBusinessStatus,RaisedUSD)]

setkey(parentsSpinouts,EntityID)
setkey(deals,EntityID)

out <- deals[parentsSpinouts]
  
rm(list = c("parentsSpinouts","deals"))

CRSP <- fread("raw/CRSP/crsp_monthly_reduced.csv")

CRSP[ , RET := as.numeric(RET)]

# Translate returns into dollar terms
CRSP[ , marketValue := SHROUT * abs(PRC)]
CRSP[ , marketValueLag := shift(marketValue, n = 1L, fill = NA, type = "lag")]
CRSP[ , retDollars := RET * marketValueLag]

out[, year := year(ymd(CloseDate))]
CRSP[ , year := year(ymd(date))]

out[, month := month(ymd(CloseDate))]
CRSP[ , month := month(ymd(date))]

CRSP[ , date := substr(date,1,6)]

out <- out[ , .(year,month,EntityID,RoundID,RoundType,RaisedUSD,gvkey,cusip)]
out <- unique(out, by = c("gvkey","EntityID","RoundID"))
CRSP <- CRSP[ , .(date,year,month,CUSIP,retDollars,RET,marketValueLag)]

# Compustat drops 9th digit checksum
out[, cusip := substr(cusip,1,8)]

setkey(out,cusip,year,month)
setkey(CRSP,CUSIP,year,month)

# Merge on CUSIP
CRSP <- out[CRSP]

CRSP <- CRSP[order(gvkey,year,month)]

## Add up all funding events

CRSP[, totalFunding := sum(na.omit(RaisedUSD)), by = c("cusip","year","month")]
CRSP <- unique(CRSP, by = c("cusip","year","month"))

CRSP[ , RaisedUSD := NULL]

CRSP[is.na(totalFunding) , totalFunding := 0]

# Put into same units as totalFunding

CRSP[,retDollars := retDollars / 1000000] 

#####
# Load in Fama-French factors
####

factors <- fread("raw/fama-french-factors/fama-french-factors.csv") 

setkey(factors,date)
setkey(CRSP,date)

CRSP <- factors[CRSP]

CRSP[ , `:=` (RF = as.numeric(RF), mktExcess = as.numeric(mktExcess), SMB = as.numeric(SMB), HML = as.numeric(HML))]

CRSP[, retPercentExcess := RET * 100 - RF]

CRSP <- CRSP[cusip != "" & !is.na(cusip)]
CRSP <- CRSP[!is.na(retPercentExcess)]
  
## Compute fama French coefficients by running regression by group

famaFrenchCoefficients <- CRSP[, as.list(coef(lm(retPercentExcess ~ mktExcess + SMB + HML))), by = cusip]

setnames(famaFrenchCoefficients,"(Intercept)","coef_intercept")
setnames(famaFrenchCoefficients,"mktExcess","coef_mktExcess")
setnames(famaFrenchCoefficients,"SMB","coef_SMB")
setnames(famaFrenchCoefficients,"HML","coef_HML")


## Now merge back into CRSP

setkey(famaFrenchCoefficients,cusip)
setkey(CRSP,cusip)

CRSP <- famaFrenchCoefficients[CRSP]

## Now can compute abnormal excess return
      
## Expected return for holding period 

CRSP[, expectedExcessReturn := coef_intercept + coef_mktExcess * mktExcess + coef_SMB * SMB + coef_HML * HML]
CRSP[, abnormalExcessReturn := retPercentExcess - expectedExcessReturn]
CRSP[, abnormalRetDollars := marketValueLag * (abnormalExcessReturn / 100) / 1000000]

CRSP <- CRSP[ , .(cusip,date,year,month,gvkey,abnormalRetDollars,totalFunding)][!is.na(gvkey)]

CRSP[ , abnormalRetDollars_z := (abnormalRetDollars - mean(abnormalRetDollars, na.rm = TRUE)) / sd(abnormalRetDollars, na.rm = TRUE)]
CRSP[ , totalFunding_z := (totalFunding - mean(totalFunding, na.rm = TRUE)) / sd(totalFunding, na.rm = TRUE)]

## Some plots

plot(CRSP$totalFunding_z,CRSP$abnormalRetDollars_z)
plot(CRSP$totalFunding,CRSP$abnormalRetDollars)

CRSP <- CRSP[ year <= 2014]

# Save data for use in Stata for regressions    
fwrite(CRSP,"data/funding_stockReturns.csv")
  
    
  
  
  









