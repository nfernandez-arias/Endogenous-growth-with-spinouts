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
exits <- fread("data/VentureSource/exits.csv")

parentsSpinouts[ , year := pmin(na.omit(year(ymd(JoinDate))),na.omit(year(ymd(StartDate)))), by = .(gvkey,EntityID)]
parentsSpinouts <- parentsSpinouts[!is.na(year)]

setkey(parentsSpinouts,EntityID)
setkey(exits,EntityID)

parentsSpinouts <- exits[parentsSpinouts]
  
parentsSpinouts[ , yearError := foundingYear - year]
parentsSpinouts <- parentsSpinouts[yearError == 0]

temp <- parentsSpinouts[ , sum(Weight), by = .(gvkey,year)]

setnames(temp,"V1","spinoutCount")

temp[is.na(spinoutCount) == TRUE, spinoutCount := 0]

temp[ , spinoutCountUnweighted := parentsSpinouts[ , .N, by = .(gvkey,year)]$N ]

temp[ , spinoutCountUnweighted_onlyExits := parentsSpinouts[ , sum(maxExit), by = .(gvkey,year)]$V1 ]
temp[ , spinoutsDiscountedExitValue := parentsSpinouts[ , sum(na.omit(Weight) * na.omit(discountedExitValue)), by = .(gvkey,year)]$V1 ]
temp[ , spinoutCountUnweighted_discountedByTimeToExit :=  parentsSpinouts[ , mean(1.06^(-na.omit(timeToExit))), by = .(gvkey,year)]$V1 ]

fwrite(temp,"data/parentsSpinoutCounts.csv")





