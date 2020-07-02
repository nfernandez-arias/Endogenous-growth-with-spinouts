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
deals <- fread("raw/VentureSource/01Deals.csv")[year (ymd(StartDate)) >= 1986][, .(EntityID, EntityName,State, StartDate, CloseDate,
                                                                                  RoundNo, RoundID, RoundClass, RoundType, RoundBusinessStatus,
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

# Extract deal year and founding year
deals[ , dealYear := year(ymd(CloseDate))]
deals[ , foundingYear := year(ymd(StartDate))]
setkey(deals,dealYear)

# Merge with GDP deflator
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
deals[RoundType == "IPO" | RoundType == "ACQ" | RoundClass == "Buyout" | RoundClass == "Merger", exit  := 1]
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
# Construct dataset of employment, funding, revenue, and exit evolution for each startup
#----------------------#

entityPaths <- deals[!is.na(foundingYear)][ , .(EntityID,State,CloseDate,dealYear,foundingYear,exitYear,EmployeeCount,
                          PostValUSD,RaisedUSD,StartDate,
                          OwnershipStatus,OwnerStatDate,RoundClass,RoundType,RoundBusinessStatus,BusinessStatus)][ order(EntityID,dealYear,CloseDate)]

#----------------#
# Take care of years with multiple funding rounds
#----------------#

entityPaths[ , `:=` (hasEmploymentInfo_year = any(!is.na(EmployeeCount)),
                     hasValuationInfo_year = any(!is.na(PostValUSD))), 
             by = .(EntityID,dealYear)]

# Store disaggregated data
#entityPaths[ , `:=` (PostValUSD_disaggregated = PostValUSD,
 #                    EmployeeCount_disaggregated = EmployeeCount)]

# Construct means across deals that year with data

entityPaths[ hasEmploymentInfo_year == TRUE , EmployeeCount_1 := mean(na.omit(EmployeeCount)), by = .(EntityID,dealYear) ]
entityPaths[ hasValuationInfo_year == TRUE, PostValUSD_1 := mean(na.omit(PostValUSD)), by = .(EntityID,dealYear) ]

entityPaths[ , `:=` (PostValUSD = NULL,
                     EmployeeCount = NULL)]

setnames(entityPaths,"PostValUSD_1","PostValUSD")
setnames(entityPaths,"EmployeeCount_1","EmployeeCount")

entityPaths <- unique(entityPaths, by = c("EntityID","dealYear"))

#----------------#
# Complete 

# Complete dataset

setnames(entityPaths,"dealYear","year")
entityPaths <- data.table(complete(entityPaths,EntityID,year = 1986:2019))


# Define time-invariant firm-specific variables
entityPaths[ , foundingYear := mean(na.omit(foundingYear)) , by = EntityID]

entityPaths[ , EntityAge := year - foundingYear]

entityPaths[ , State := max(na.omit(State)), by = EntityID]
entityPaths[ , OwnershipStatus := max(na.omit(OwnershipStatus)), by = EntityID]
entityPaths[ , lastDealYear := max(na.omit(year(ymd(CloseDate)))), by = EntityID]
entityPaths[ any(OwnerStatDate != ""), OwnerStatDate := max(NaRV.omit(OwnerStatDate)), by = EntityID]

# Drop data for each entity after last event (deal or going out of business) occurs
entityPaths <- entityPaths[ year <= pmin(pmax(year(ymd(OwnerStatDate)), lastDealYear, na.rm = TRUE),exitYear, na.rm = TRUE)  & EntityAge >= 0]

# Define exit dates
entityPaths[ OwnershipStatus == "Out of Business" & year == year(ymd(OwnerStatDate)), goingOutOfBusiness := 100 ]
entityPaths[ is.na(goingOutOfBusiness), goingOutOfBusiness := 0]

# Not sure why I did it this way
entityPaths[ is.na(exitYear), exitYear := -1]
entityPaths[ , exitYear := max(exitYear) , by = EntityID]

entityPaths[ year == exitYear, 
             successfullyExiting := 100]
entityPaths[ is.na(successfullyExiting), successfullyExiting := 0]



setcolorder(entityPaths,c("EntityID","year"))

# Bring in revenue information
revenue <- fread("raw/VentureSource/06CoRevenue.csv")[ , .(EntityID,CoFiscalYear,RevenueHighUSD)]

setnames(revenue,"RevenueHighUSD","revenue")

revenue[ , year := year(ymd(CoFiscalYear))]

# Take mean when multiple sources in same year
revenue[ , revenue := mean(na.omit(revenue)), by = .(EntityID,year)]
revenue <- unique(revenue, by = c("EntityID","year"))

# First transform to real terms
setkey(revenue,year)
revenue <- gdpDeflator[revenue]

revenue[ , revenue := revenue / gdpDeflator]

# Now merge in
setkey(revenue,EntityID,year)
setkey(entityPaths,EntityID,year)

entityPaths <- revenue[ , .(EntityID,year,revenue)][entityPaths]

#--------------#
## Calculate some statistics
#--------------#

fracRevAll <- entityPaths[ , sum(!is.na(revenue)) / .N]
fracEmpAll <- entityPaths[ , sum(!is.na(EmployeeCount)) / .N]
fracValAll <- entityPaths[ , sum(!is.na(PostValUSD)) / .N]

fracRev <- entityPaths[ , .(fracRev = sum(!is.na(revenue)) / .N, Nobs = .N), by = EntityID]
fracEmp <- entityPaths[ , .(fracEmp = sum(!is.na(EmployeeCount)) / .N, Nobs = .N), by = EntityID]
fracVal <- entityPaths[ , .(fracVal = sum(!is.na(PostValUSD)) / .N, Nobs = .N), by = EntityID]

# frac of entities that have at least one obs

fracRev[ fracRev > 0, hasRev := 1]
fracRev[ is.na(hasRev), hasRev := 0]
fracHasRev <- fracRev[ , sum(hasRev) / .N]

fracEmp[ fracEmp > 0, hasEmp := 1]
fracEmp[ is.na(hasEmp), hasEmp := 0]
fracHasEmp <- fracEmp[ , sum(hasEmp) / .N]

fracVal[ fracVal > 0, hasVal := 1]
fracVal[ is.na(hasVal), hasVal := 0]
fracHasVal <- fracVal[ , sum(hasVal) / .N]

# fraction of all conditional on at least one data point

fracRevAllCond <- fracRev[ fracRev > 0][ , sum(fracRev * Nobs) / sum(Nobs)]
fracEmpAllCond <- fracEmp[fracEmp >0][ , sum(fracEmp * Nobs) / sum(Nobs)]
fracValAllCond <- fracVal[fracVal > 0][ , sum(fracVal * Nobs) / sum(Nobs)]

    

# histograms

hist(fracRev$fracRev, breaks = 50)
hist(fracEmp$fracEmp, breaks = 50)
hist(fracVal$fracVal, breaks = 50)



#---------------------#
# Incorporate debt raised to construct asset value
#---------------------#

entityPaths[ RoundClass == "Debt/Non-Equity", debtRaised := RaisedUSD]
entityPaths[is.na(debtRaised), debtRaised := 0]

setkey(entityPaths,EntityID,year)

entityPaths[ , cumDebtRaised := cumsum(debtRaised), by = EntityID]

entityPaths[ , assetVal := PostValUSD + cumDebtRaised]

#---------------------#
# Interpolation -- decided not to do this after discussion with Ulrich Muller
#---------------------#

# Transform variables and interpolate

entityPaths[ , lEmployeeCount := log(EmployeeCount)]
entityPaths[ lEmployeeCount == -Inf, lEmployeeCount := NA]
entityPaths[ , lPostValUSD := log(PostValUSD)]
entityPaths[ , lrevenue := log(revenue)]
entityPaths[ lrevenue == -Inf, lrevenue := NA]

# Set initial revenue and valuation equal to one dollar, for extrapolative purposes...

entityPaths[ , hasEmploymentInfo := any(!is.na(EmployeeCount)), by = EntityID]
entityPaths[ , hasValuationInfo := any(!is.na(PostValUSD)), by = EntityID]
entityPaths[ , hasRevenueInfo := any(!is.na(revenue)), by = EntityID]

#entityPaths[ EntityAge == 0 & hasEmploymentInfo, lEmployeeCount := 0]
#entityPaths[ EntityAge == 0 & hasValuationInfo, lPostValUSD := log(0.000001)]
#entityPaths[ EntityAge == 0 & hasRevenueInfo, lrevenue := log(0.000001)]


setkey(entityPaths,EntityID,EntityAge)

#entityPaths[ hasEmploymentInfo == 1, lEmployeeCount := na.approx(lEmployeeCount, na.rm = FALSE), by = "EntityID"]
#entityPaths[ hasValuationInfo == 1, lPostValUSD := na.approx(lPostValUSD, na.rm = FALSE), by = "EntityID"]
#entityPaths[ hasRevenueInfo == 1, lrevenue := na.approx(lrevenue,na.rm = FALSE), by = "EntityID"]
entityPaths[ , lPostValUSDdivEmployeeCount := lPostValUSD - lEmployeeCount]
entityPaths[ , lrevenuedivEmployeeCount := lrevenue - lEmployeeCount]

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
rm(list = ls.str(mode = "list"))

