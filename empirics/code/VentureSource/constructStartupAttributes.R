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
deals <- fread("raw/VentureSource/01Deals.csv")[year(ymd(StartDate)) >= 1986][, .(EntityID, EntityName,State, StartDate, CloseDate,
                                                                                  RoundNo, RoundID, RoundType, RoundBusinessStatus,
                                                                                  OwnershipStatus, OwnerStatDate, BusinessStatus, EmployeeCount,
                                                                                  RaisedDA, RaisedUSD, PostValueDA, PostValUSD, 
                                                                                  IndustryCode, SubcodeDesc, IndustryCodeDesc,Competition)]



#---------------------------#
# Impute SubcodeDesc from IndustryCodeDesc 
# when it is missing - by convention, I use this 
# in my match later
#---------------------------#

deals[ SubcodeDesc == "", SubcodeDesc := IndustryCodeDesc]

#---------------------------#
# Construct REAL variables
# (instead of nominal)
#---------------------------#

# Extract deal year
deals[ , dealYear := year(ymd(CloseDate))]
deals[ , foundingYear := year(ymd(StartDate))]
setkey(deals,dealYear)

gdpDeflator <- fread("data/deflators/gdpDeflator.csv")
setkey(gdpDeflator,year)

deals <- gdpDeflator[deals]

setnames(deals,"year","dealYear")

# Put funding variables in real terms
# using GDP deflator
for (var in c("RaisedUSD","PostValUSD"))
{
  varString <- paste(var,"_nominal", sep = "")
  deals[ , (varString) := get(var)]
  deals[ , (var) := get(var) / gdpDeflator]
}

#---------------------------#
# Calculate attributes of startups related to funding 
# success and successful IPO or acquisition.
#---------------------------#

deals[ , PreValUSD := PostValUSD - RaisedUSD]

deals[ !is.na(PreValUSD), fundingEvent := 1]
deals[ is.na(fundingEvent) , fundingEvent := 0]

# Flag rounds as exits or non-exits
deals[RoundType == "IPO" | RoundType == "ACQ" & !is.na(PreValUSD), exit  := 1]
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
deals[exit == 1 & cumExit == 1, prevalAtExit := PreValUSD]
deals[exit == 1 & cumExit == 1, postvalAtExit := PostValUSD]
deals[exit == 1 & cumExit == 1, empAtExit := EmployeeCount]

deals[fundingEvent == 1 & cumFunding == 1, valAtFirstFunding := PreValUSD]
deals[fundingEvent == 1 & cumFunding == 1, empAtFirstFunding := EmployeeCount]
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
# Construct dataset of employment, funding and exit evolution for each startup
#----------------------#

entityPaths <- deals[ , .(EntityID,dealYear,foundingYear,exitYear,EmployeeCount,PreValUSD,PostValUSD,RaisedUSD,StartDate,OwnershipStatus,OwnerStatDate,RoundType,RoundBusinessStatus,BusinessStatus)]

entityPaths <- entityPaths[ order(EntityID,dealYear)]

entityPaths[ , EntityAge := dealYear - foundingYear]

entityPaths <- data.table(complete(entityPaths,EntityID,EntityAge = 0:30))

entityPaths[ , foundingYear := mean(na.omit(foundingYear)) , by = EntityID]

entityPaths[ , year := foundingYear + EntityAge]

setcolorder(entityPaths,c("EntityID","year"))

entityPaths[ , lEmployeeCount := log(EmployeeCount)]
entityPaths[ lEmployeeCount == -Inf, lEmployeeCount := NA]
entityPaths[ , lPreValUSD := log(PreValUSD)]
entityPaths[ , lPostValUSD := log(PostValUSD)]

entityPaths[ EntityAge == 0, lEmployeeCount := 0]

setkey(entityPaths,EntityID,EntityAge)

entityPaths[ , lEmployeeCount := na.approx(lEmployeeCount, na.rm = FALSE), by = "EntityID"]
entityPaths[ , lPreValUSD := na.approx(lPreValUSD, na.rm = FALSE), by = "EntityID"]
entityPaths[ , lPostValUSD := na.approx(lPostValUSD, na.rm = FALSE), by = "EntityID"]

fwrite(entityPaths,"data/VentureSource/startupsPaths.csv")

#----------------------#
# Construct dataset of startup characteristis
#----------------------#

startupsData <- unique(deals, by = "EntityID")[ , .(EntityID, EntityName, State, IndustryCodeDesc, SubcodeDesc, 
                                                    foundingYear, noRevenue, genRevenue, profitable, 
                                                    maxFunding, firstFundingYear, valAtFirstFunding, raisedAtFirstFunding_USD, 
                                                    maxExit, exitYear, prevalAtExit, postvalAtExit, raisedAtExit_USD)]

startupsData[ , `:=` (timeToExit = exitYear - foundingYear, 
                       timeToFirstFunding = firstFundingYear - foundingYear)]

startupsData[ , discountedExitPreValue := (fundingDiscountFactor)^(-timeToExit) * prevalAtExit]
startupsData[ , discountedExitPostValue := (fundingDiscountFactor)^(-timeToExit) * postvalAtExit]
startupsData[ , discountedFFValue := (fundingDiscountFactor)^(-timeToFirstFunding) * valAtFirstFunding]

## Now export csvs

fwrite(startupsData,"data/VentureSource/startupsData.csv")


# Clean up
rm(deals,startupsData,temp,gdpDeflator)


