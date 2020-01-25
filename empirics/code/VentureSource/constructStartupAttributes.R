#------------------------------------------------#
#
# File name: constructStartupAttributes.R
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
    

# Load funding information about all startups
deals <- fread("raw/VentureSource/01Deals.csv")[year(ymd(StartDate)) >= 1986][order(EntityID,RoundNo)][, .(EntityID,EntityName,State,StartDate,CloseDate,RoundNo,RoundID,RoundType,RoundBusinessStatus,RaisedDA,RaisedUSD,PostValueDA,PostValUSD,IndustryCode,SubcodeDesc,IndustryCodeDesc,Competition)]

#---------------------------#
# Impute SubcodeDesc from IndustryCodeDesc 
# when it is missing - by convention, I use this 
# in my match later
#---------------------------#

deals[ SubcodeDesc == "", SubcodeDesc := IndustryCodeDesc]


#---------------------------#
# Calculate attributes of startups related to funding 
# success and successful IPO or acquisition.
#---------------------------#

deals[ , PreValUSD := PostValUSD - RaisedUSD]
deals[ !is.na(PreValUSD), fundingEvent := 1]
deals[ is.na(fundingEvent) , fundingEvent := 0]

# Extract deal year - for use later
deals[ , dealYear := year(ymd(CloseDate))]
deals[ , foundingYear := year(ymd(StartDate))]

# Flag rounds as exits or non-exits
deals[RoundType == "IPO" | RoundType == "ACQ" & !is.na(PostValUSD), exit  := 1]
deals[is.na(exit), exit := 0]

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
deals[exit == 1 & cumExit == 1, valAtExit := PreValUSD]
deals[fundingEvent == 1 & cumFunding == 1, valAtFirstFunding := PreValUSD]
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


 # Probably deprecated
temp <- unique(deals[, .(EntityID, IndustryCodeDesc, State, foundingYear, noRevenue, genRevenue, profitable, maxExit)], by = "EntityID")
#temp <- unique(deals[  , .(EntityID, foundingYear, noRevenue, genRevenue, profitable)], by = "EntityID")

fwrite(temp,"data/VentureSource/startupOutcomes.csv")


#----------------------#
# Construct dataset of startup characteristis
#----------------------#

startupsData <- unique(deals, by = "EntityID")[ , .(EntityID, EntityName, State, IndustryCodeDesc, SubcodeDesc, 
                                                    foundingYear, noRevenue, genRevenue, profitable, 
                                                    maxFunding, firstFundingYear, valAtFirstFunding, raisedAtFirstFunding_USD, 
                                                    maxExit, exitYear, valAtExit, raisedAtExit_USD)]

startupsData[ , `:=` (timeToExit = exitYear - foundingYear, 
                       timeToFirstFunding = firstFundingYear - foundingYear)]

startupsData[ , discountedExitValue := (fundingDiscountFactor)^(-timeToExit) * valAtExit]
startupsData[ , discountedFFValue := (fundingDiscountFactor)^(-timeToFirstFunding) * valAtFirstFunding]


## Now export csvs

fwrite(startupsData,"data/VentureSource/startupsData.csv")


# Clean up
rm(deals,startupsData,temp)


