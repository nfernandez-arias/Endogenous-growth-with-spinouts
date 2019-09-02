#------------------------------------------------#
#
# File name: constructSpinoutAttributes.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This file construct database of spinouts and their attributes:
# e.g. (1) whether they achieve revenue, (2) how much funding they receive, (3) whether they IPO, (4) IPO market capitalization
#
#------------------------------------------------#

library(lubridate)

rm(list = ls())

data <- fread("data/parentsSpinouts.csv")

deals <- fread("raw/VentureSource/01Deals.csv")[order(EntityID,RoundNo)][, .(EntityID,EntityName,StartDate,CloseDate,RoundNo,RoundID,RoundType,RoundBusinessStatus,RaisedDA,RaisedUSD,PostValueDA,PostValUSD,IndustryCode,SubcodeDesc,IndustryCodeDesc,Competition)]

#revenue <- fread("raw/VentureSource/06CoRevenue.csv")[order(EntityID,CoFiscalYear)]

# Extract deal year - for use later
deals[,dealYear := year(ymd(CloseDate))]
deals[,foundingYear := year(ymd(StartDate))]

# Flag rounds as exits or non-exits 
deals[RoundType == "IPO" | RoundType == "ACQ", exit  := 1]

deals[is.na(exit), exit := 0]
deals[!is.na(PostValUSD), fundingEvent := 1]

# Compute whether there is an exit at all for the EntityID: if maxExit == 1, there is an exit. Otherwise no exit.
deals[, maxExit := max(exit), by = EntityID]
deals[, maxFunding := max(fundingEvent), by = EntityID]

# Cumulate, so that we can flag first exit 
deals[,cumExit := cumsum(exit), by = EntityID]
deals[,cumFunding := cumsum(fundingEvent), by = EntityID]


## Compute statistics of first exit
# Exit year
deals[exit == 1 & cumExit == 1, exitYear := dealYear]
deals[fundingEvent == 1 & cumFunding == 1, firstFundingYear := dealYear]
# Compute post-money valuation at first exit 
deals[exit == 1 & cumExit == 1, valAtExit := PostValUSD]
deals[fundingEvent == 1 & cumFunding == 1, valAtFirstFunding := PostValUSD]
# Compute amount of money raised at exit
deals[exit == 1 & cumExit == 1, raisedAtExit_USD := RaisedUSD]
deals[fundingEvent == 1 & cumFunding == 1, raisedAtFirstFunding_USD := RaisedUSD]



firstFundingEvents <- deals[fundingEvent == 1 & cumFunding == 1, .(EntityID,EntityName,maxFunding,foundingYear,firstFundingYear,valAtFirstFunding,raisedAtFirstFunding_USD,RoundType)]
noFundingData  <- unique(deals[maxFunding != 1], by = "EntityID")[,.(EntityID,EntityName,maxFunding,foundingYear,firstFundingYear,valAtFirstFunding,raisedAtFirstFunding_USD,RoundType)]

exits <- deals[exit == 1 & cumExit == 1, .(EntityID,EntityName,maxExit,foundingYear,exitYear,valAtExit,raisedAtExit_USD,RoundType)]
noexits <- unique(deals[maxExit != 1], by = "EntityID")[,.(EntityID,EntityName,maxExit,foundingYear,exitYear,valAtExit,raisedAtExit_USD,RoundType)]
noexits[, RoundType := NA]


exits <- rbind(exits,noexits)
firstFundingEvents <- rbind(firstFundingEvents,noFundingData)


# Get unique record for each EntityID

exits <- unique(exits, by = "EntityID")[ , .(EntityID,EntityName,maxExit,foundingYear,exitYear,valAtExit,raisedAtExit_USD,RoundType)]
firstFundingEvents <- unique(firstFundingEvents, by = "EntityID")[ , .(EntityID,EntityName,maxFunding,foundingYear,firstFundingYear,valAtFirstFunding,raisedAtFirstFunding_USD,RoundType)]

exits[ , timeToExit := exitYear - foundingYear]
exits[ , discountedExitValue := (1.06)^(-timeToExit) * valAtExit]

firstFundingEvents[ , timeToFirstFunding := firstFundingYear - foundingYear]
firstFundingEvents[ , discountedFirstFundingValue := (1.06)^(-timeToFirstFunding) * valAtFirstFunding]


## Now export csv.

fwrite(exits,"data/VentureSource/exits.csv")
fwrite(firstFundingEvents,"data/VentureSource/firstFundingEvents.csv")




