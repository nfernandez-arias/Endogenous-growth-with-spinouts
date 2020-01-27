#-------------------------------------------#
#
# File name: combineParentsSpinoutsWithStartupsData.R
#
# Purpose: This file brings in information on 
# industry (coded by Venture Source) and funding (from
# constructStartupAttributes.R) to the 
# parentsSpinouts.csv dataset, merges with my 
# VentureSource - NAICS industrial classification
# crosswalk, and construcst a flag for spinout-founder
# observations which are in / not in the same 
# NAICS - i digit industrial classification as their parent firm.
#
#
#-------------------------------------------#


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

# Next, add NAICS industry information using my homemade crosswalk
crosswalk <- fread("raw/VentureSource-NAICS-Crosswalk.csv")
crosswalk[ , IndustrySegment := NULL]

setkey(crosswalk,IndustryCode,IndustrySubCode)
setkey(parentsSpinouts,IndustryCodeDesc,SubcodeDesc)

parentsSpinouts <- crosswalk[parentsSpinouts]

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


# Clean up
rm(crosswalk,parentsSpinouts,startupsData)

