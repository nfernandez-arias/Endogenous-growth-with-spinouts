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
# Also constructs information on whether they are ever in product development, generating revenue or profitable.
#
#------------------------------------------------#
    
library(lubridate)

rm(list = ls())

deals <- fread("raw/VentureSource/01Deals.csv")[year(ymd(StartDate)) >= 1986][order(EntityID,RoundNo)][, .(EntityID,EntityName,State,StartDate,CloseDate,RoundNo,RoundID,RoundType,RoundBusinessStatus,RaisedDA,RaisedUSD,PostValueDA,PostValUSD,IndustryCode,SubcodeDesc,IndustryCodeDesc,Competition)]


# First need to get measure of number of founders of each startup, 
# to properly deflate figures

entitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")[ year(ymd(JoinDate)) - foundingYear <= 3]
numFounders <- entitiesPrevEmployers[ , .(numFounders = .N), by = "EntityID"]

fwrite(numFounders,"data/VentureSource/EntitiesNumFounders.csv")

rm(entitiesPrevEmployers)

f
# Extract deal year - for use later
deals[,dealYear := year(ymd(CloseDate))]
deals[,foundingYear := year(ymd(StartDate))]

# Flag rounds as exits or non-exits
deals[RoundType == "IPO" | RoundType == "ACQ" & !is.na(PostValUSD), exit  := 1]

deals[is.na(exit), exit := 0]
deals[!is.na(PostValUSD), fundingEvent := 1]
deals[is.na(fundingEvent), fundingEvent := 0]

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

## Construct dataset of firms that that enter in product development and eventually generate revenue

deals[ RoundBusinessStatus != "Generating Revenue" & RoundBusinessStatus != "Profitable", noRevenue := 1 ]
deals[ is.na(noRevenue), noRevenue := 0]
deals[ , noRevenue := max(noRevenue), by = "EntityID"]

deals[ RoundBusinessStatus == "Generating Revenue" , `:=` (genRevenue = 1)]
deals[ is.na(genRevenue), genRevenue := 0]
deals[ , genRevenue := max(genRevenue), by = "EntityID"]

deals[ RoundBusinessStatus == "Profitable", profitable := 1]
deals[ is.na(profitable), profitable := 0]
deals[ , profitable := max(profitable), by = "EntityID"]

# Only consider years in my main sample, 1986 to 2007

temp <- unique(deals[, .(EntityID, IndustryCodeDesc, State, foundingYear, noRevenue, genRevenue, profitable)], by = "EntityID")
#temp <- unique(deals[  , .(EntityID, foundingYear, noRevenue, genRevenue, profitable)], by = "EntityID")

fwrite(temp,"data/VentureSource/startupOutcomes.csv")





### Now construct dataset of first funding events and exits

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
exits[ , discountedExitValue := (1.05)^(-timeToExit) * valAtExit]

firstFundingEvents[ , timeToFirstFunding := firstFundingYear - foundingYear]
firstFundingEvents[ , discountedFFValue := (1.05)^(-timeToFirstFunding) * valAtFirstFunding]


## Now export csvs

fwrite(exits,"data/VentureSource/exits.csv")
fwrite(firstFundingEvents,"data/VentureSource/firstFundingEvents.csv")



