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
deals[RoundType == ]
deals[is.na(exit), exit := 0]

# Compute whether there is an exit at all for the EntityID: if maxExit == 1, there is an exit. Otherwise no exit.
deals[, maxExit := max(exit), by = EntityID]

# Cumulate, so that we can flag first exit 
deals[,cumExit := cumsum(exit), by = EntityID]


## Compute statistics of first exit
# Exit year
deals[exit == 1 & cumExit == 1, exitYear := dealYear]
# Compute post-money valuation at first exit 
deals[exit == 1 & cumExit == 1, valAtExit := PostValUSD]
# Compute amount of money raised at exit
deals[exit == 1 & cumExit == 1, raisedAtExit_USD := RaisedUSD]

exits <- deals[exit == 1 & cumExit == 1, .(EntityID,EntityName,maxExit,foundingYear,exitYear,valAtExit,raisedAtExit_USD,RoundType)]

noexits <- unique(deals[maxExit != 1], by = "EntityID")[,.(EntityID,EntityName,maxExit,foundingYear,exitYear,valAtExit,raisedAtExit_USD,RoundType)]

noexits[, RoundType := NA]

exits <- rbind(exits,noexits)


# Get unique record for each EntityID

exits <- unique(exits, by = "EntityID")[ , .(EntityID,EntityName,maxExit,foundingYear,exitYear,valAtExit,raisedAtExit_USD,RoundType)]

exits[ , timeToExit := exitYear - foundingYear]
exits[ , discountedExitValue := (1.06)^(-timeToExit) * valAtExit]


## Now export csv.

fwrite(exits,"data/VentureSource/exits.csv")




