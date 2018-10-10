# File name: clean_GDP_stateLevel.R
#
# Description:
# 
# (1)
# Reads in 
# (a) Raw/gdpstate_naics_all_C.csv (data since 1997)
# (b) Raw/gdpstate_sic_all_C.csv (data until 1997)
# (c) Raw/stateAbbreviations.csv (for making it easier to clean)
# 
# (both datasets from BEA Regional Economic Accounts)
# located at https://apps.bea.gov/regional/downloadzip.cfm
#
# (2)
# Extract relevant columns and rows... basically, filter out "United States", "Great Lakes" etc. type of regions
# Also keep only IndustryID == 1 or 2 (total GDP and private sector GDP, respectively)
# and keep only GDP variables and statename.
# 
# (3)
# Merge datasets (not append) because they are in WIDE format
#
# (4)
# Reshape to long and 
# Writes resulting datasets to Data/yearStateGDP_TOTAL.csv and Data/yearStateGDP_PRIVATE.csv, respectively
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


## (1) Read in data
yearStateGDP_NAICS <- data.table(read.csv("Raw/gdpstate_naics_all_C.csv"))
yearStateGDP_SIC <- data.table(read.csv("Raw/gdpstate_sic_all_C.csv"))
stateAbbreviations <- fread("Raw/stateAbbreviations.csv")

## (2) Extract relevant columns (TOTAL GDP and PRIVATE SECTOR GDP) and rows (50 states, not regional aggregates / whole US)
# First, get extract only rows corresponding to total GDP or private sector GDP (i.e., not industry breakdown - YET)
yearStateGDP_NAICS <- yearStateGDP_NAICS[(IndustryId == 1) | (IndustryId == 2)]
yearStateGDP_SIC <- yearStateGDP_SIC[(IndustryId == 1) | (IndustryId == 2)]

# Second, get rid of non state-level observations
# Need to rename state variable in stateAbbreviations for easier cleaning
yearStateGDP_NAICS <- yearStateGDP_NAICS %>% dplyr::rename(state = GeoName)
yearStateGDP_SIC <- yearStateGDP_SIC %>% dplyr::rename(state = GeoName)
stateAbbreviations <- stateAbbreviations %>% dplyr::rename(state = State, stateAbbrev = StateAbbrev)

# Merge them in
setkey(stateAbbreviations,state)
setkey(yearStateGDP_NAICS,state)
setkey(yearStateGDP_SIC,state)

# Finally merge in and keep only observations where merge was successful - this effectively drops observations not at the state level
yearStateGDP_NAICS <- stata.merge(yearStateGDP_NAICS,stateAbbreviations,"state")[merge == 3]
yearStateGDP_SIC <- stata.merge(yearStateGDP_SIC,stateAbbreviations,"state")[merge == 3]

## Finally, merge the two resulting datasets by state name:
# First, get rid of unnecessary variables
yearStateGDP_NAICS <- yearStateGDP_NAICS %>% select(-merge,-GeoFIPS,-Region,-ComponentId,-ComponentName,-IndustryClassification)
yearStateGDP_SIC <- yearStateGDP_SIC %>% select(-merge,-GeoFIPS,-Region,-ComponentId,-ComponentName,-IndustryClassification,-stateAbbrev,-Description)

yearStateGDP_NAICS <- yearStateGDP_NAICS %>% select(state,stateAbbrev,IndustryId,Description,everything())
yearStateGDP_SIC <- yearStateGDP_SIC %>% select(state,IndustryId,everything())

# Next merge:
yearStateGDP <- stata.merge(yearStateGDP_NAICS,yearStateGDP_SIC,c("state","IndustryId"))

## Finally, make consistent:
# First, need to turn RD spending variables into numerics (why are they factors? weird)

yearStateGDP[,5:61 := lapply(.SD,function(x) {as.numeric(as.character(x))}), .SDcols = 5:61]
# Make consistent: new variable X1997 is average of 1997 from two datasets!
yearStateGDP[,X1997 := (X1997.x + X1997.y)/2]

# Drop X1997.x and X1997.y
yearStateGDP <- yearStateGDP %>% select(-X1997.x,-X1997.y,-merge)

## Reshape to long format
yearStateGDP_long <- yearStateGDP %>% gather(year,GDP,X1998:X1997) %>% data.table()

yearStateGDP_long[, year := as.numeric(substring(year,2))]

## Finally, reshape to wide to drop observations where total GDP is less than state GDP because that 
# doesn't make sense:
#yearStateGDP_long[, ID := .I]
#yearStateGDP_long <- yearStateGDP_long %>% select(-Description)
#temp <- yearStateGDP_long %>% tidyr::spread(IndustryId,GDP)

## Finally, output data

fwrite(yearStateGDP_long,"Data/yearStateGDP.csv")

#fwrite(yearStateGDP_long[IndustryId == 1] %>% select(-IndustryId,-Description), "Data/yearStateGDP_TOTAL.csv")
#fwrite(yearStateGDP_long[IndustryId == 2] %>% select(-IndustryId,-Description), "Data/yearStateGDP_PRIVATE.csv")
