# File name: xrd_rdUserCost_GDP_merge_stateLevel_compustatAggregation.R
#
# Description:
# 
# (1)
# Reads in 
# (a) Data\yearStateXrd.csv and 
# (b) Data\RDusercost_2017_13.dta
# (c) Data\rd-by-state.dta
# 
# (2)
# Cleans, make sure both use same state conventions
# 
# (3)
# Merges (a),(b) by state-year
#
# (4)
# Merges with (c) by state-year to obtain state-year GDP data
#
# (4)
# Finally, writes dataset to 
# Data/yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.csv
# which will be used for conducting the analysis
#

rm(list = setdiff(ls(), lsf.str()))
setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

## Load libraries and auxiliary functions
library(profvis)
library(readstata13)
library(dplyr)
library(plyr)
library(tidyr)
library(data.table)
source('Code/Functions/stata_merge.R')

## Load in data
# Load R&D spending by state-year
yearStateXrd <- fread("Data/yearStateXrd.csv")
# Load R&D user cost by state-year and clean
yearStateRDUserCost <- data.table(read.dta13("Data/RDusercost_2017_13.dta"))
yearStateRDUserCost <- yearStateRDUserCost %>% select(state,year,rho_high)
# Load Data/yearStateGDP.csv
yearStateGDP <- fread("Data/yearStateGDP.csv")
yearStateGDP <- yearStateGDP %>% dplyr::rename(stateName = state, state = stateAbbrev)




## Merge
#yearStateXrdRDUserCost <- stata.merge(yearStateXrd,yearStateRDUserCost,c("state","year"))
setkey(yearStateRDUserCost,state,year)
setkey(yearStateXrd,state,year)
setkey(yearStateGDP,state,year)
yearStateXrdRDUserCost <- merge(yearStateXrd,yearStateRDUserCost) 
yearStateXrdRDUserCostGDP <- merge(yearStateXrdRDUserCost,yearStateGDP)

# Compute RD as % of GDP as a sanity check and for later use - looks good!
yearStateXrdRDUserCostGDP[, xrd_percentGDP := 100 * xrd / GDP]


# Diagnostics



## Output (in csv and in dta13 format)
fwrite(yearStateXrdRDUserCostGDP,"Data/yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.csv")
save.dta13(yearStateXrdRDUserCostGDP,"Data/yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.dta")








