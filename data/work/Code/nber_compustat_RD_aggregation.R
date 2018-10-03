# File name: inventorsAndPatents_compustat_merge.R
#
# Function: Reads in and cleans
# Raw/pat76_06_assg.dta,
# Raw/inventor.csv,
# Data/dynass_reshaped.dta
# Raw/compustat_annual_13.dta

# Merges pat76_06_assg.dta and inventor.csv by patent #
# merges with dynass_reshaped by pdpass, identification in NBER / Compustat bridge. this brings in gvkey.
# merges with compustat by year using gvkey
#
# Output: Dataset with observations at the inventor level, with information 
#

rm(list = setdiff(ls(), lsf.str()))



setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

## Start timer
ptm <- proc.time()

## Load libraries
library(readstata13)
library(dplyr)
library(tidyr)
library(data.table)
source('Code/Functions/stata_merge.R')

#### Merge Patents and Inventors Datasets by Patent #
install.packages("data.table")
## Load in and clean Patents dataset
patents <- read.dta13('Raw/pat76_06_assg.dta')
patents$year <- patents$appyear
patents <- patents %>% rename(assigneeState = state, assigneeCountry = country)
patents <- patents %>% select(patent,pdpass,year)


## Load in and clean Inventors datasets
inventors <- read.csv('Raw/inventor.csv')
inventors <- inventors %>% rename(patent = Patent, inventorCountry = Country, inventorZipCode = Zipcode, inventorState = State, inventorCity = City)
# Convert patent # to numeric. Non-utility patents have non-numeric characters, so these become NAs
# and can then be dropped. 
inventors$patent <- as.numeric(as.character(inventors$patent))
inventors <- inventors[!is.na(inventors$patent),]
inventors <- inventors %>% select(patent,inventorState)
## Merge datasets
inventorsPatents <- merge(patents,inventors,by = "patent")

# Check time
proc.time() - ptm

# Remove unnecessary data: inventors, patents, and unnecessary variables in inventorsAndPatents
rm(list = c("inventors","patents"))

#############
###########
## Construction of patent-level geographic distribution
# 
## Algorithm:
#
# Create new variable, inventorCount, that counts number of inventors 
# for each patent (i.e. count # of observations per patent)
# Then invert - this is now the weight 
# assigned to each patent-city observation.
#
###########
############

weights <- count(inventorsPatents,patent)
weights$weight <- 1/weights$n
weights <- weights %>% select(patent,weight)
inventorsPatentsWeights <- merge(inventorsPatents,weights,by = "patent")

rm(list=c("inventorsPatents","weights"))
inventorsPatentsWeights$inventorState <- as.character(inventorsPatentsWeights$inventorState)
proc.time() - ptm

## Have to now load in dynass and merge with compustat. The reason is that 
## this allows me to modify the variable inventorState = assigneeState for 
## <gvkey>-<year> pairs that do not have a patent. 

#### Construct dataset with patent number, year, and gvkey
## Load dynass_reshaped
dynass <- read.dta13('Data/dynass_reshaped.dta')
# Clean and diagnose
dynass$gvkey <- as.integer(dynass$gvkey)
dynass <- dynass %>% select(pdpass,gvkey,year)

## Merge and clean
# Merge
inventorsPatentsWeightsDynass <- merge(inventorsPatentsWeights,dynass,by = c("pdpass","year"))
# Remove unnecessary data: inventorsAndPatents and dynass
rm(list = c("inventorsPatentsWeights","dynass"))

#### Merge patentsAssigneesDynass with compustat's XRD data
## Load compustat dataset and clean
compustat <- read.dta13('Raw/compustat_annual.dta')
compustat <- compustat %>% select(gvkey,fyear,xrd,state)

compustat$year <- compustat$fyear
compustat$gvkey <- as.integer(compustat$gvkey)

## Merge and clean
inventorsPatentsWeightsCompustat <- merge(inventorsPatentsWeightsDynass,compustat,by = c("gvkey","year"),all.y = TRUE)
rm(list = c("inventorsPatentsWeightsDynass","compustat"))

inventorsPatentsWeightsCompustat <- tibble::rowid_to_column(inventorsPatentsWeightsCompustat,"ID")
inventorsPatentsWeightsCompustat <- inventorsPatentsWeightsCompustat %>% mutate(weight = replace(weight, is.na(inventorState), 1))
inventorsPatentsWeightsCompustat <- inventorsPatentsWeightsCompustat %>% mutate(inventorState = replace(inventorState, is.na(inventorState), state[is.na(inventorState)]))
# Spread to make column for each state's weight

inventorsPatentsWeightsCompustat <- inventorsPatentsWeightsCompustat %>% select(ID,gvkey,patent,xrd,year,inventorState,weight)
inventorsPatentsWeightsCompustatWide <- inventorsPatentsWeightsCompustat %>% spread(inventorState,weight)

# Extract just weights
gvkeyXrdYearWeights <- inventorsPatentsWeightsCompustatWide %>% select(-V1)
# Sum by gvkey-year
gvkeyXrdYearWeights <- gvkeyXrdYearWeights %>% group_by(gvkey,year) %>% summarize_all(funs(sum))


#### Multiply xrd by all weight columns

## First turn NAs into 0s

gvkeyXrdYearWeights <- gvkeyXrdYearWeights %>% mutate_all(funs(replace(.,is.na(.),0)))
# Do i even need to do this? not sure...
gvkeyXrdYearWeights <- ungroup(gvkeyXrdYearWeights)
# Not working
for (i in 4:68) {
  gvkeyXrdYearWeights[,i] <- gvkeyXrdYearWeights[,3] * gvkeyXrdYearWeights[,i]
}

# Clean up
rm(inventorsAndPatentsWeights)

### Aggregate weights for each state by patent
# Extract just weights
patentsWeights <- inventorsAndPatentsWeightsWide %>% select(-pdpass,-year,-assigneeState,-assigneeCountry,-inventorCountry,-inventorCity,-inventorZipCode) 
# Sum by patent group
patentsWeights <- patentsWeights %>% group_by(patent) %>% summarize_all(funs(sum))
## Construct dataset with patent number, year and pdpass for merging with dynass
patentsAssignees <- inventorsAndPatentsWeightsWide %>% select(patent,pdpass,year) %>% distinct(patent,pdpass,year,.keep_all = TRUE)
# Clean up
patentsWeights <- patentsWeights %>% select(-US)
rm(inventorsAndPatentsWeightsWide)


#### Merge with weights
patentsAssigneesDynassCompustatWeights <- merge(patentsAssigneesDynassCompustat,patentsWeights,by = c("patent"),all.x = TRUE)

# Remove unnecessary variables: inventorsAndPatents and compustat
rm(list = c("patentsAssigneesDynassCompustat","patentsWeights"))

#### Summarize data
summary(patentsAssigneesDynassCompustatWeights)

write.csv(inventorsAndPatentsAndDynassAndCompustat, file = "Data/inventors_patents_compustat.csv")

proc.time() - ptm
