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


parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")


# The "year" of the parent-spinout linkage is the joinYear, not the foundingYear, 
# in cases where they are distinct.
parentsSpinouts[,  year := joinYear]

# Drop unnecessary variables
parentsSpinouts[, joinYear := NULL]

#------------------------------------#
# Construct weight of each founder:  1 / N, where N is number of founders of that startup
# (this ensures that total number of spinouts equals sum of spinout counts across parent firms)
# I will also conduct an unweighted analysis
#------------------------------------#

for (founderType in c("all","founder2","executive","technical"))
{
  colString <- paste("weight",founderType, sep = "_")
  parentsSpinouts[ , (colString) := 1 / sum(get(founderType)), by = EntityID]
} 

#--------------------------#
# (1) Compute: 
# (a) Founder counts
# (b) Spinout counts (weighted)
# (c) Spinouts DFFV (weighted)
# (d) Spinouts DFFV (unweighted)
# (e) Spinouts DEV (weighted)
# (f) Spinouts DEV (unweighted)
#--------------------------#

out <- unique( parentsSpinouts[ , .(gvkey,year)])
setkey(out,gvkey,year)

for (founderType in c("all","founder2","executive","technical"))
{
  
  # Construct strings for referring to variables
  weightString <- paste("weight",founderType,sep = "_")
  spinoutsString <- paste("spinouts",founderType, sep = ".")
  foundersString <- paste("founders",founderType, sep = ".")
  dffvString <- paste("dffv",founderType, sep = ".")
  dffvUnweightedString <- paste("dffvUnw",founderType, sep = ".")
  devString <- paste("dev",founderType,sep = ".")
  devUnweightedString <- paste("devUnw",founderType, sep = ".")
  
  # Construct counts
  temp1 <- parentsSpinouts[ , .(sum(get(founderType)), 
                                sum(NaRV.omit(get(weightString) * get(founderType))), 
                                sum(NaRV.omit(get(weightString) * get(founderType) * discountedFFValue)), 
                                sum(NaRV.omit(get(founderType) * discountedFFValue)),
                                sum(NaRV.omit(get(weightString) * get(founderType) * discountedExitPostValue)),
                                sum(NaRV.omit(get(founderType) * discountedExitPostValue))),
                            by = .(gvkey,year)]
  
  # Rename columns -- couldn't get this to work in one line...not sure why
  setnames(temp1,"V1",foundersString)
  setnames(temp1,"V2",spinoutsString)
  setnames(temp1,"V3",dffvString)
  setnames(temp1,"V4",dffvUnweightedString)
  setnames(temp1,"V5",devString)
  setnames(temp1,"V6",devUnweightedString)
  
  # Set key for merging with output below
  setkey(temp1,gvkey,year)
  
  # Loop through industries
  for (i in 1:6)
  {
    # Construct strings for referring to column names
    wsoFlag <- paste("wso",i,sep = "")
    nonwsoFlag <- paste("nonwso",i,sep = "")
    spinoutsString_inner <- paste(spinoutsString,wsoFlag,sep = ".")
    foundersString_inner <- paste(foundersString,wsoFlag,sep = ".")
    dffvString_inner <- paste(dffvString,wsoFlag,sep = ".")
    dffvUnweightedString_inner <- paste(dffvUnweightedString,wsoFlag,sep = ".")
    devString_inner <- paste(devString,wsoFlag,sep = ".")
    devUnweightedString_inner <- paste(devUnweightedString,wsoFlag,sep = ".")
    
    spinoutsStringNonwso_inner <- paste(spinoutsString,nonwsoFlag,sep = ".")
    foundersStringNonwso_inner <- paste(foundersString,nonwsoFlag,sep = ".")
    dffvStringNonwso_inner <- paste(dffvString,nonwsoFlag,sep = ".")
    dffvUnweightedStringNonwso_inner <- paste(dffvUnweightedString,nonwsoFlag,sep = ".")
    devStringNonwso_inner <- paste(devString,nonwsoFlag,sep = ".")
    devUnweightedStringNonwso_inner <- paste(devUnweightedString,nonwsoFlag,sep = ".")

    # Construct counts
    temp2 <- parentsSpinouts[ , .(sum(NaRV.omit(get(wsoFlag) * get(founderType))),
                                  sum(NaRV.omit(get(wsoFlag) * get(weightString) *  get(founderType))), 
                                  sum(NaRV.omit(get(wsoFlag) * get(weightString) * get(founderType) * discountedFFValue)), 
                                  sum(NaRV.omit(get(wsoFlag) * get(founderType) * discountedFFValue)),
                                  sum(NaRV.omit(get(wsoFlag) * get(weightString) * get(founderType) * discountedExitPostValue )),
                                  sum(NaRV.omit(get(wsoFlag) * get(founderType) * discountedExitPostValue ))),
                              by = .(gvkey,year)]
    
    # Rename columns
    setnames(temp2,"V1",foundersString_inner)
    setnames(temp2,"V2",spinoutsString_inner)
    setnames(temp2,"V3",dffvString_inner)
    setnames(temp2,"V4",dffvUnweightedString_inner)
    setnames(temp2,"V5",devString_inner)
    setnames(temp2,"V6",devUnweightedString_inner)
  
    # Merge with main dataset with spinout counts
    setkey(temp2,gvkey,year)
    temp1 <- temp2[temp1]
    
    # Construct nonwso counts
    temp1[ , (spinoutsStringNonwso_inner) := get(spinoutsString) - get(spinoutsString_inner)]
    temp1[ , (foundersStringNonwso_inner) := get(foundersString) - get(foundersString_inner)]
    temp1[ , (dffvStringNonwso_inner) := get(dffvString) - get(dffvString_inner)]
    temp1[ , (dffvUnweightedStringNonwso_inner) := get(dffvUnweightedString) - get(dffvUnweightedString_inner)]
    temp1[ , (devStringNonwso_inner) := get(devString) - get(devString_inner)]
    temp1[ , (devUnweightedStringNonwso_inner) := get(devUnweightedString) - get(devUnweightedString_inner)]
    
    
  }
  
  # Merge with main dataset
  out <- temp1[out]
  
}

# Label gvkey = 0 for when it is NA -- could also 
# drop observations, but this retains info (i.e., know
# non-spinout counts in each year this way...idk)   

out[ is.na(gvkey), gvkey := 0]

# Write data
fwrite(out,"data/parentsSpinoutCounts.csv")

# Clean up
rm(list = ls.str(mode = "list"))



