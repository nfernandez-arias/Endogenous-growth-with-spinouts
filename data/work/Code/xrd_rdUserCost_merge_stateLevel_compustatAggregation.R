# File name: xrd_rdUserCost_merge_stateLevel_compustatAggregation.R
#
# Description:
# 
# (1)
# Reads in 
# Data\yearStateXrd.csv and 
# Data\RDusercost_2017_13.dta
# 
# (2)
# Cleans, make sure both use same state conventions
# 
# (3)
# Merges by state-year
#
# (4)
# Finally, writes dataset to 
# Data/xrd_rdUserCost_stateLevel_compustatAggregation.csv
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


## Merge
yearStateXrdRDUserCost <- stata.merge(yearStateXrd,yearStateRDUserCost,c("state","year"))
# Diagnostics
setkey(yearStateXrdRDUserCost,state,year)
## Output










