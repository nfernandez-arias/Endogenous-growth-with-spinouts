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
parentsSpinouts[ , Weight := 1 / .N, by = "EntityID"]
exits <- fread("data/VentureSource/exits.csv")[ , .(EntityID,maxExit,exitYear,valAtExit,raisedAtExit_USD,RoundType,timeToExit,discountedExitValue)]
firstFundings <- fread("data/VentureSource/firstFundingEvents.csv")[ , .(EntityID,maxFunding,firstFundingYear,valAtFirstFunding,raisedAtFirstFunding_USD,RoundType,timeToFirstFunding,discountedFFValue)]
startupOutcomes <- fread("data/VentureSource/startupOutcomes.csv")

# First merge with information on exit values
setkey(parentsSpinouts,EntityID)
setkey(exits,EntityID)
setkey(firstFundings,EntityID)
setkey(startupOutcomes,EntityID)

# For usage in computing likelihood of eventual exit for spinouts vs entrants
temp <- parentsSpinouts
temp[ , isSpinout := 1]
temp <- temp[exits]
temp[ is.na(isSpinout), isSpinout := 0]
temp <- unique(temp, by = "EntityID")
fwrite(temp,"data/VentureSource/startupsExits.csv")

rm(temp)



# Now proceed with the rest of the script  
parentsSpinouts <- exits[parentsSpinouts]
parentsSpinouts <- firstFundings[parentsSpinouts]
parentsSpinouts <- startupOutcomes[ , .(EntityID,noRevenue,genRevenue,profitable)][parentsSpinouts]

fwrite(parentsSpinouts,"data/parentsSpinoutsFirstFundingsExitsOutcomes.csv")


# Impute first funding value for missing data -- important, because I want to capture all spinouts caused by R&D...
#parentsSpinouts[ is.na(discountedFFValue) , discountedFFValue := mean(discountedFFValue, na.rm = TRUE)]
#parentsSpinouts[ discountedFFValue == 65 , discountedFFValue := mean(na.exclude(discountedFFValue))]

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

parentsSpinouts[ , yearError := joinYear - foundingYear]
parentsSpinouts <- parentsSpinouts[yearError <= 3]
parentsSpinouts[,  year := joinYear]
#parentsSpinouts[, foundingYear := NULL]
parentsSpinouts[, joinYear := NULL]
parentsSpinouts[, yearError := NULL]

##########
# Compute the spinout count -- 
##########

## First, look at industry information. My cross-walk is far from perfect, but it's something...
parentsSpinouts_naics6 <- parentsSpinouts[(substr(NAICS1,1,6) == substr(naics,1,6)) | (substr(NAICS2,1,6) == substr(naics,1,6)) | (substr(NAICS3,1,6) == substr(naics,1,6)) | (substr(NAICS4,1,6) == substr(naics,1,6))]
parentsSpinouts_naics5 <- parentsSpinouts[(substr(NAICS1,1,5) == substr(naics,1,5)) | (substr(NAICS2,1,5) == substr(naics,1,5)) | (substr(NAICS3,1,5) == substr(naics,1,5)) | (substr(NAICS4,1,5) == substr(naics,1,5))]
parentsSpinouts_naics4 <- parentsSpinouts[(substr(NAICS1,1,4) == substr(naics,1,4)) | (substr(NAICS2,1,4) == substr(naics,1,4)) | (substr(NAICS3,1,4) == substr(naics,1,4)) | (substr(NAICS4,1,4) == substr(naics,1,4))]
parentsSpinouts_naics3 <- parentsSpinouts[(substr(NAICS1,1,3) == substr(naics,1,3)) | (substr(NAICS2,1,3) == substr(naics,1,3)) | (substr(NAICS3,1,3) == substr(naics,1,3)) | (substr(NAICS4,1,3) == substr(naics,1,3))]
parentsSpinouts_naics2 <- parentsSpinouts[(substr(NAICS1,1,2) == substr(naics,1,2)) | (substr(NAICS2,1,2) == substr(naics,1,2)) | (substr(NAICS3,1,2) == substr(naics,1,2)) | (substr(NAICS4,1,2) == substr(naics,1,2))]
parentsSpinouts_naics1 <- parentsSpinouts[(substr(NAICS1,1,1) == substr(naics,1,1)) | (substr(NAICS2,1,1) == substr(naics,1,1)) | (substr(NAICS3,1,1) == substr(naics,1,1)) | (substr(NAICS4,1,1) == substr(naics,1,1))]

parentsSpinouts[(substr(NAICS1,1,6) == substr(naics,1,6)) | (substr(NAICS2,1,6) == substr(naics,1,6)) | (substr(NAICS3,1,6) == substr(naics,1,6)) | (substr(NAICS4,1,6) == substr(naics,1,6)), wso6 := 1]
parentsSpinouts[(substr(NAICS1,1,5) == substr(naics,1,5)) | (substr(NAICS2,1,5) == substr(naics,1,5)) | (substr(NAICS3,1,5) == substr(naics,1,5)) | (substr(NAICS4,1,5) == substr(naics,1,5)), wso5 := 1]
parentsSpinouts[(substr(NAICS1,1,4) == substr(naics,1,4)) | (substr(NAICS2,1,4) == substr(naics,1,4)) | (substr(NAICS3,1,4) == substr(naics,1,4)) | (substr(NAICS4,1,4) == substr(naics,1,4)), wso4 := 1]
parentsSpinouts[(substr(NAICS1,1,3) == substr(naics,1,3)) | (substr(NAICS2,1,3) == substr(naics,1,3)) | (substr(NAICS3,1,3) == substr(naics,1,3)) | (substr(NAICS4,1,3) == substr(naics,1,3)), wso3 := 1]
parentsSpinouts[(substr(NAICS1,1,2) == substr(naics,1,2)) | (substr(NAICS2,1,2) == substr(naics,1,2)) | (substr(NAICS3,1,2) == substr(naics,1,2)) | (substr(NAICS4,1,2) == substr(naics,1,2)), wso2 := 1]
parentsSpinouts[(substr(NAICS1,1,1) == substr(naics,1,1)) | (substr(NAICS2,1,1) == substr(naics,1,1)) | (substr(NAICS3,1,1) == substr(naics,1,1)) | (substr(NAICS4,1,1) == substr(naics,1,1)), wso1 := 1]

parentsSpinouts[ is.na(wso6), wso6 := 0]
parentsSpinouts[ is.na(wso5), wso5 := 0]
parentsSpinouts[ is.na(wso4), wso4 := 0]
parentsSpinouts[ is.na(wso3), wso3 := 0]
parentsSpinouts[ is.na(wso2), wso2 := 0]
parentsSpinouts[ is.na(wso1), wso1 := 0]

## Record for use elsewhere

fwrite(parentsSpinouts_naics4,"data/parentsSpinoutsExits_naics4.csv")
fwrite(parentsSpinouts_naics3,"data/parentsSpinoutsExits_naics3.csv")
fwrite(parentsSpinouts_naics2,"data/parentsSpinoutsExits_naics2.csv")
fwrite(parentsSpinouts_naics1,"data/parentsSpinoutsExits_naics1.csv")

## Save main dataset

fwrite(parentsSpinouts,"data/parentsSpinoutsWSO.csv")
  
# adding up individual weights; equivalently, unweighted at STARTUP level
temp <- parentsSpinouts[ , sum(Weight), by = .(gvkey,year)]
setnames(temp,"V1","spinoutCount")

temp[is.na(spinoutCount) == TRUE, spinoutCount := 0]

# Now unweighted at individual level - equiv, WEIGHTED at STARTUP level (startups with more founders are counted proportionally more)

temp[ , spinoutCountUnweighted := parentsSpinouts[ , .N, by = .(gvkey,year)]$N ]
# Now only consider spinouts that are successful exits
temp[ , spinoutCountUnweighted_onlyExits := parentsSpinouts[ , sum(maxExit), by = .(gvkey,year)]$V1 ]
temp[ , spinoutsDiscountedExitValue := parentsSpinouts[ , sum(na.omit(Weight * discountedExitValue)), by = .(gvkey,year)]$V1 ]
temp[ , spinoutCountUnweighted_discountedByTimeToExit :=  parentsSpinouts[ , mean(1.05^(-na.omit(timeToExit))), by = .(gvkey,year)]$V1 ]
temp[ , spinoutsDiscountedFFValue := parentsSpinouts[ , sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1 ]
# Now only consider spinouts that are successful exits
temp[ , spinoutsDiscountedFFValue := parentsSpinouts[ , sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1 ]

## Spinout counts (i.e., weighted inversely by number of founders to avoid double counting)

wso1 <- parentsSpinouts[wso1 == 1, sum(Weight), by = .(gvkey,year)]
wso2 <- parentsSpinouts[wso2 == 1, sum(Weight), by = .(gvkey,year)]
wso3 <- parentsSpinouts[wso3 == 1, sum(Weight), by = .(gvkey,year)]
wso4 <- parentsSpinouts[wso4 == 1, sum(Weight), by = .(gvkey,year)]
nonwso4 <- parentsSpinouts[wso4 == 0, sum(Weight), by = .(gvkey,year)]
wso5 <- parentsSpinouts[wso5 == 1, sum(Weight), by = .(gvkey,year)]
wso6 <- parentsSpinouts[wso6 == 1, sum(Weight), by = .(gvkey,year)]

setnames(wso1,"V1","spinouts_wso1")
setnames(wso2,"V1","spinouts_wso2")
setnames(wso3,"V1","spinouts_wso3")
setnames(wso4,"V1","spinouts_wso4")
setnames(nonwso4,"V1","spinouts_nonwso4")
setnames(wso5,"V1","spinouts_wso5")
setnames(wso6,"V1","spinouts_wso6")



wso1[ , spinoutsUnweighted_wso1 := parentsSpinouts[wso1 == 1, .N, by = .(gvkey,year)]$N]
wso2[ , spinoutsUnweighted_wso2 := parentsSpinouts[wso2 == 1, .N, by = .(gvkey,year)]$N]
wso3[ , spinoutsUnweighted_wso3 := parentsSpinouts[wso3 == 1, .N, by = .(gvkey,year)]$N]
wso4[ , spinoutsUnweighted_wso4 := parentsSpinouts[wso4 == 1, .N, by = .(gvkey,year)]$N]
nonwso4[ , spinoutsUnweighted_nonwso4 := parentsSpinouts[wso4 == 0, .N, by = .(gvkey,year)]$N]
wso5[ , spinoutsUnweighted_wso5 := parentsSpinouts[wso5 == 1, .N, by = .(gvkey,year)]$N]
wso6[ , spinoutsUnweighted_wso6 := parentsSpinouts[wso6 == 1, .N, by = .(gvkey,year)]$N]

wso1[ , spinoutsDFFV_wso1 := parentsSpinouts[wso1 == 1, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]
wso2[ , spinoutsDFFV_wso2 := parentsSpinouts[wso2 == 1, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]
wso3[ , spinoutsDFFV_wso3 := parentsSpinouts[wso3 == 1, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]
wso4[ , spinoutsDFFV_wso4 := parentsSpinouts[wso4 == 1, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]
nonwso4[ , spinoutsDFFV_nonwso4 := parentsSpinouts[wso4 == 0, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]
wso5[ , spinoutsDFFV_wso5 := parentsSpinouts[wso5 == 1, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]
wso6[ , spinoutsDFFV_wso6 := parentsSpinouts[wso6 == 1, sum(na.omit(Weight * discountedFFValue)), by = .(gvkey,year)]$V1]

setkey(wso1,gvkey,year)
setkey(wso2,gvkey,year)
setkey(wso3,gvkey,year)
setkey(wso4,gvkey,year)
setkey(nonwso4,gvkey,year)
setkey(wso5,gvkey,year)
setkey(wso6,gvkey,year)

setkey(temp,gvkey,year)

temp <- wso1[temp]
temp <- wso2[temp]
temp <- wso3[temp]
temp <- wso4[temp]
temp <- nonwso4[temp]
temp <- wso5[temp]
temp <- wso6[temp]


fwrite(temp,"data/parentsSpinoutCounts.csv")





