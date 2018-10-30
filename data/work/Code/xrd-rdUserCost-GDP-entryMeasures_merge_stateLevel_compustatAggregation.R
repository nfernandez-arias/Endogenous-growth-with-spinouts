# File name: xrd-rdUserCost-GDP-entryMeasures_merge_stateLevel_compustatAggregation.R
#
# Description:
# 
# (1) Reads in:
# 
#     (a) yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.csv
#     (b) entry_rates_by_state.dta
#
# (2) Cleans (b) - rename, convert to csv, etc.
# 
# (3) Merges the datasets by state-year
# 
# (4) Outputs combind dataset in csv format to 
#     Data/yearStateXrd-RDUserCost-GDP-entryMeasures_stateLevel_compustatAggregation.csv
#

## (i) Preamble

rm(list = setdiff(ls(), lsf.str()))
setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

library(readstata13)
library(plyr)
library(dplyr)
library(data.table)
source('Code/Functions/stata_merge.R')

## (1) Read in Data

yearStateXrdRDUserCostGDP <- fread("Data/yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.csv")
yearStateEntry <- data.table(read.dta13("Data/entry_rates_by_state.dta"))

## (2) Clean yearStateEntry

yearStateEntry <- yearStateEntry %>% select(state,stateNum,year,estabs_entry,estabs_total,net_job_creation,emp_total)

## (3) Merge datasets

setkey(yearStateXrdRDUserCostGDP,state,year)
setkey(yearStateEntry,state,year)
yearStateXrdRDUserCostGDP_yearStateEntry_merge <- merge(yearStateXrdRDUserCostGDP,yearStateEntry)

## (4) Write file

fwrite(yearStateXrdRDUserCostGDP_yearStateEntry_merge,"Data/yearStateXrd-RDUserCost-GDP-entryMeasures_stateLevel_compustatAggregation.csv")
