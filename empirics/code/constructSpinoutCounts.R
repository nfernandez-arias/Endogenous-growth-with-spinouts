#------------------------------------------------#
#
# File name: constructSpinoutCounts.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This constructs the spinout counts dataset
#------------------------------------------------#

rm(list = ls())

library(lubridate)
library(tidyr)

parentsSpinouts <- fread("data/parentsSpinouts.csv") 
exits <- fread("data/VentureSource/exits.csv")[ , .(EntityID,maxExit,exitYear,valAtExit,raisedAtExit_USD,RoundType,timeToExit,discountedExitValue)]

# First merge with information on exit values
setkey(parentsSpinouts,EntityID)
setkey(exits,EntityID)
parentsSpinouts <- exits[parentsSpinouts]

# Next, add NAICS industry information using my homemade crosswalk
crosswalk <- fread("data/VentureSource-NAICS-Crosswalk.csv")
crosswalk[ , IndustrySegment := NULL]

setkey(crosswalk,IndustryCode,IndustrySubCode)
setkey(parentsSpinouts,IndustryCodeDesc,SubcodeDesc)

parentsSpinouts <- crosswalk[parentsSpinouts]

#parentsSpinouts[ , year := joinYear]
parentsSpinouts <- parentsSpinouts[!is.na(foundingYear)]
 
###############
# Who is a founder? 
#
# For now, only considering as founders those employees who joined during the founding year.
###########

parentsSpinouts[ , yearError := foundingYear - joinYear]
parentsSpinouts <- parentsSpinouts[yearError == 0]
parentsSpinouts[,  year := joinYear]
parentsSpinouts[, foundingYear := NULL]
parentsSpinouts[, joinYear := NULL]
parentsSpinouts[, yearError := NULL]

##########
# Compute the spinout count -- 
##

## First, look at industry information. My cross-walk is far from perfect, but it's something...
parentsSpinouts_naics4 <- parentsSpinouts[(substr(NAICS1,1,4) == substr(naics,1,4)) | (substr(NAICS2,1,4) == substr(naics,1,4))]
parentsSpinouts_naics3 <- parentsSpinouts[(substr(NAICS1,1,3) == substr(naics,1,3)) | (substr(NAICS2,1,3) == substr(naics,1,3))]
parentsSpinouts_naics2 <- parentsSpinouts[(substr(NAICS1,1,2) == substr(naics,1,2)) | (substr(NAICS2,1,2) == substr(naics,1,2))]
parentsSpinouts_naics1 <- parentsSpinouts[(substr(NAICS1,1,1) == substr(naics,1,1)) | (substr(NAICS2,1,1) == substr(naics,1,1))]

## Here decide which one to use

#parentsSpinouts <- parentsSpinouts_naics4

# adding up individual weights; equivalently, unweighted at STARTUP level
temp <- parentsSpinouts[ , sum(Weight), by = .(gvkey,year)]
setnames(temp,"V1","spinoutCount")

temp[is.na(spinoutCount) == TRUE, spinoutCount := 0]

# Now unweighted at individual level - equiv, WEIGHTED at STARTUP level (startups with more founders are counted proportionally more)
temp[ , spinoutCountUnweighted := parentsSpinouts[ , .N, by = .(gvkey,year)]$N ]

# Now only consider spinouts that are successful exits
temp[ , spinoutCountUnweighted_onlyExits := parentsSpinouts[ , sum(maxExit), by = .(gvkey,year)]$V1 ]
temp[ , spinoutsDiscountedExitValue := parentsSpinouts[ , sum(na.omit(Weight) * na.omit(discountedExitValue)), by = .(gvkey,year)]$V1 ]
temp[ , spinoutCountUnweighted_discountedByTimeToExit :=  parentsSpinouts[ , mean(1.06^(-na.omit(timeToExit))), by = .(gvkey,year)]$V1 ]

fwrite(temp,"data/parentsSpinoutCounts.csv")





