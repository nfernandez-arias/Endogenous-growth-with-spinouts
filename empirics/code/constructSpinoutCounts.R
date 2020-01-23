#------------------------------------------------#
#
# File name: constructSpinoutCounts.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This constructs the spinout counts dataset.
# This dataset consists of an observation for each parent firm - year. 
# and stores three types of "counts"
#
# (1) A count "weighted" by the number of founders of each startup. This count has the property 
# that summing over all parent firms yields the total number of spinouts.
#
# (2) A count that is unweighted. This is essentially a "founder" count, and summed up equals 
# the total number of founders.
#
# (3) A "count" which consists of the "value" of spinouts generated in that year. Each 
# founder who most recently worked at the parent and starts a firm in a given year adds an amount
# Weight * discountedFirstFundingValuation. The discounted first funding valuation is the post money
# valuation at first funding, discounted to the date of founding of the startup. 
#
# In addition, all counts will be done for "within-industry spinouts" (WSOs) and others, 
# using various definitions of industry. 
#------------------------------------------------#



parentsSpinouts <- fread("data/parentsSpinouts.csv") 

#------------------------------------#
# Construct weight of each founder:  1 / N, where N is number of founders of that startup
# (this ensures that total number of spinouts equals sum of spinout counts across parent firms)
# I will also conduct an unweighted analysis
#------------------------------------#

parentsSpinouts[ , Weight := 1 / .N, by = "EntityID"]

#------------------------------------#
# Load in data on startups relating to successful IPO or acquisition,
# first funding events, and outcomes, constructed in 
# constructStartupAttributes.R
#------------------------------------#

exits <- fread("data/VentureSource/exits.csv")[ , .(EntityID,maxExit,exitYear,valAtExit,raisedAtExit_USD,RoundType,timeToExit,discountedExitValue)]
firstFundings <- fread("data/VentureSource/firstFundingEvents.csv")[ , .(EntityID,maxFunding,firstFundingYear,valAtFirstFunding,raisedAtFirstFunding_USD,RoundType,timeToFirstFunding,discountedFFValue)]
startupOutcomes <- fread("data/VentureSource/startupOutcomes.csv")

#------------------------------------#
# Slight detour -- I think this is deprecated, but not sure yet.
#------------------------------------#

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


#------------------------------------#
# Now proceed with the rest of the script
# 
# Bring in information on exits, first fundings and startup outcomes.
#------------------------------------#


parentsSpinouts <- exits[parentsSpinouts]
parentsSpinouts <- firstFundings[parentsSpinouts]
parentsSpinouts <- startupOutcomes[ , .(EntityID,noRevenue,genRevenue,profitable)][parentsSpinouts]

fwrite(parentsSpinouts,"data/parentsSpinoutsFirstFundingsExitsOutcomes.csv")

# Next, add NAICS industry information using my homemade crosswalk
crosswalk <- fread("raw/VentureSource-NAICS-Crosswalk.csv")
crosswalk[ , IndustrySegment := NULL]

setkey(crosswalk,IndustryCode,IndustrySubCode)
setkey(parentsSpinouts,IndustryCodeDesc,SubcodeDesc)

parentsSpinouts <- crosswalk[parentsSpinouts]

#------------------------------------#
# Only count as "founders" those employees who 
# moved to the firm within 2 years of its foundingYear.
#------------------------------------#

parentsSpinouts[ , yearError := joinYear - foundingYear]
parentsSpinouts <- parentsSpinouts[yearError <= founderThreshold]

# The "year" of the parent-spinout linkage is the joinYear, not the foundingYear, 
# in cases where they are distinct.
parentsSpinouts[,  year := joinYear]

# Drop unnecessary variables
parentsSpinouts[, joinYear := NULL]
parentsSpinouts[, yearError := NULL]

#------------------------------------#
# Compute the spinout counts
#------------------------------------#

## First, look at industry information. My cross-walk is far from perfect, but it's something...

for (i in 1:6)
{
  wsoFlag <- paste("wso",i,sep = "")
  parentsSpinouts[(substr(NAICS1,1,i) == substr(naics,1,i)) | (substr(NAICS2,1,i) == substr(naics,1,i)) | (substr(NAICS3,1,i) == substr(naics,1,i)) | (substr(NAICS4,1,i) == substr(naics,1,i)), (wsoFlag) := 1]
  parentsSpinouts[ is.na(get(wsoFlag)) , (wsoFlag) := 0]
}

## Save main dataset, so it can be used later (not sure where it is used later...)

fwrite(parentsSpinouts,"data/parentsSpinoutsWSO.csv")
  
#--------------------------#
# (1) Compute spinout counts regardless of WSO or not
#--------------------------#

out <- parentsSpinouts[ , .(spinoutCount = sum(Weight), spinoutCountUnweighted = .N , spinoutsDiscountedFFValue = sum(na.omit(Weight * discountedFFValue))), by = .(gvkey,year)][order(gvkey,year)]

# In preparation for merging with WSO counts below
setkey(out,gvkey,year)

#--------------------------#
# (2) Compute spinout counts for wso1,wso2,wso3,wso4,wso5,wso6
#--------------------------#

for (i in 1:6)
{
  # Construct strings for referring to column names
  wsoFlag <- paste("wso",i,sep = "")
  spinoutCountVar <- paste("spinoutCount_",wsoFlag,sep = "")
  spinoutCountUnweightedVar <- paste("spinoutCountUnweighted_",wsoFlag,sep = "")
  spinoutsDiscountedFFValueVar <- paste("spinoutsDiscountedFFValue_",wsoFlag,sep = "")
  
  # Construct count
  temp <- parentsSpinouts[ , .(sum(Weight * get(wsoFlag)), sum(get(wsoFlag)) , 
                               sum(na.omit(Weight * discountedFFValue * get(wsoFlag)))), by = .(gvkey,year)][order(gvkey,year)]
  
  setnames(temp,"V1",spinoutCountVar)
  setnames(temp,"V2",spinoutCountUnweightedVar)
  setnames(temp,"V3",spinoutsDiscountedFFValueVar)

  # Merge with main dataset with spinout counts
  setkey(temp,gvkey,year)
  out <- temp[out]
}

fwrite(out,"data/parentsSpinoutCounts.csv")

# Clean up
rm(crosswalk,exits,firstFundings,out,
   parentsSpinouts,startupOutcomes,temp)

rm(spinoutCountUnweightedVar,spinoutCountVar,spinoutsDiscountedFFValueVar,wsoFlag,i)




