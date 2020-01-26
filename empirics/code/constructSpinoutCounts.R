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
# Load in data on startups, computed in 
# VentureSource/constructStartupAttributes.R
#------------------------------------#

startupsData <- fread("data/VentureSource/startupsData.csv")[ , .(EntityID, EntityState = State, IndustryCodeDesc, SubcodeDesc,
                                                                  discountedExitValue,discountedFFValue)]

setkey(startupsData,EntityID)
setkey(parentsSpinouts,EntityID)

parentsSpinouts <- startupsData[parentsSpinouts]

#------------------------------------#
# Construct weight of each founder:  1 / N, where N is number of founders of that startup
# (this ensures that total number of spinouts equals sum of spinout counts across parent firms)
# I will also conduct an unweighted analysis
#------------------------------------#

parentsSpinouts[ , `:=` (allWeight = 1 / .N, founder2Weight = 1 / sum(founder2), executiveWeight = 1 / sum(executive), technicalWeight = 1 / sum(technical)), by = "EntityID"]

parentsSpinouts[ founder2Weight == Inf, founder2Weight := NA]
parentsSpinouts[ executiveWeight == Inf, executiveWeight := NA]
parentsSpinouts[ technicalWeight == Inf, technicalWeight := NA]

fwrite(parentsSpinouts,"data/parentsSpinoutsFirstFundingsExitsOutcomes.csv")

# Next, add NAICS industry information using my homemade crosswalk
crosswalk <- fread("raw/VentureSource-NAICS-Crosswalk.csv")
crosswalk[ , IndustrySegment := NULL]

setkey(crosswalk,IndustryCode,IndustrySubCode)
setkey(parentsSpinouts,IndustryCodeDesc,SubcodeDesc)

parentsSpinouts <- crosswalk[parentsSpinouts]

# The "year" of the parent-spinout linkage is the joinYear, not the foundingYear, 
# in cases where they are distinct.
parentsSpinouts[,  year := joinYear]

# Drop unnecessary variables
parentsSpinouts[, joinYear := NULL]

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

## Save main dataset, so it can be used later (in /analysis/compareSpinoutsToEntrants.R)

fwrite(parentsSpinouts,"data/parentsSpinoutsWSO.csv")
  
#--------------------------#
# (1) Compute spinout counts regardless of WSO or not
#--------------------------#

out <- unique( parentsSpinouts[ , .(gvkey,year)])
setkey(out,gvkey,year)

parentsSpinouts[ executive == 0 , all := 1]
parentsSpinouts[ is.na(all), all := 0]

for (founderType in c("all","founder2","executive"))
{
  weightString <- paste(founderType,"Weight",sep = "")
  spinoutsString <- paste("spinouts",founderType,".")
  foundersString <- paste("founders",founderType,".")
  dffvString <- paste("dffv",founderType,".")
  temp1 <- parentsSpinouts[ , .( sum(na.omit(get(weightString))), sum(get(founderType)), 
                                sum(na.omit(get(weightString) * discountedFFValue))), 
                            by = .(gvkey,year)]
  
  setnames(temp1,"V1",spinoutsString)
  setnames(temp1,"V2",foundersString)
  setnames(temp1,"V3",dffvString)
  
  setkey(temp1,gvkey,year)
  
  for (i in 1:6)
  {
    # Construct strings for referring to column names
    wsoFlag <- paste("wso",i,sep = "")
    spinoutsString_inner <- paste(spinoutsString,wsoFlag,sep = ".")
    foundersString_inner <- paste(foundersString,wsoFlag,sep = ".")
    dffvString_inner <- paste(dffvString,wsoFlag,sep = ".")
    
    # Construct count
    temp2 <- parentsSpinouts[ , .( sum(na.omit(get(weightString) * get(wsoFlag))), sum(get(wsoFlag) * get(founderType)) , 
                                 sum(na.omit(get(weightString) * discountedFFValue * get(wsoFlag)))), 
                              by = .(gvkey,year)]
    
    setnames(temp2,"V1",spinoutsString_inner)
    setnames(temp2,"V2",foundersString_inner)
    setnames(temp2,"V3",dffvString_inner)
    
    # Merge with main dataset with spinout counts
    setkey(temp2,gvkey,year)
    temp1 <- temp2[temp1]
  }
  
  out <- temp1[out]
  
}

fwrite(out,"data/parentsSpinoutCounts.csv")

# Clean up
rm(startupsData,crosswalk,out,temp1,temp2,parentsSpinouts)



