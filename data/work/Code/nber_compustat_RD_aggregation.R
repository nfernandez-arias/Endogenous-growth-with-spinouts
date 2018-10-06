# File name: nber_compustat_RD_aggregation.R
#
# Function: Reads in and cleans
# Raw/pat76_06_assg.dta,
# Raw/inventor.csv,
# Data/dynass_reshaped.dta
# Raw/compustat_annual_13.dta
#
# Merges pat76_06_assg.dta and inventor.csv by patent #
# merges with dynass_reshaped by pdpass, identification in NBER / Compustat bridge. this brings in gvkey.
# merges with compustat by year using gvkey
#
# Uses the resulting dataset to compute state-level measures of each gvkey-year R&D expenditures
# and then aggregates this to provide state-level measures of R&D by public firms. 
#
# Algorithm: see README.
#
#####################################################
#### Preamble #######################################
#####################################################


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

profvis({
  
  #####################################################
  #### Merge Patents and Inventors Datasets by Patent #
  #####################################################
  
  ##### Load in and clean patents dataset
  patents <- read.dta13('Raw/pat76_06_assg.dta')
  patents$year <- patents$appyear
  patents <- patents %>% dplyr::rename(assigneeState = state, assigneeCountry = country)
  patents <- patents %>% dplyr::select(patent,pdpass,year)
  
  ##### Load in and clean inventors datasets
  # Use data.table::fread -- it is an order of magntiude faster than read.csv
  inventors <- fread(file = "Raw/inventor.csv")
  # Rename variables
  inventors <- inventors %>% dplyr::rename(patent = Patent, inventorCountry = Country, inventorZipCode = Zipcode, inventorState = State, inventorCity = City)
  # Convert patent # to numeric. Non-utility patents have non-numeric characters, so these become NAs
  # and can then be dropped. 
  inventors$patent <- as.numeric(as.character(inventors$patent))
  inventors$inventorState <- as.character(inventors$inventorState)
  inventors <- inventors %>% dplyr::filter(!is.na(patent))
  # Select only relevant variables: patent number and inventor state 
  inventors <- inventors %>% dplyr::select(patent,inventorState)
  
  ##### Merge datasets using data.table - order of magnitude faster than baseR merge or plyr::join
  # To conserve memory, can define data.tables by reference! beautiful!
  inventors <- data.table(inventors)
  patents <- data.table(patents)
  #setDT(inventors, keep.rownames = FALSE)
  #setDT(patents, keep.rownames = FALSE)
  setkey(inventors,patent)
  setkey(patents,patent)
  inventorsPatents <- merge(patents,inventors)
  
  ##### Clean up: remove inventors, patents data.tables
  rm(list = c("inventors","patents"))
  
  ######################################################################
  ######################################################################
  ## Construction of geographic distribution of R&D for each gvkey-year
  # 
  ## Algorithm:
  #
  # For inventorsPatents dataset, Create new variable, inventorCount, that 
  # counts number of inventors for each patent (i.e. count # of observations per patent)
  # Then invert - this is now the weight assigned to each patent-city observation.
  #
  # This only gives me the ability to assign a state to gvkey-year observations
  # that match the patent database, i.e. where the company applied for 
  # a patent. 
  #
  # In order to use all, need to next import dynass and compustat,
  # merge with inventorsPatentsWeights, and do the following:
  # 
  # (1) Assign a weight of 1 to gvkey-year observations which do not have a patent
  # (2) Assign the gvkey-year state to inventorState for those observations 
  # (i.e. treat all R&D as occuring in the main state of the company when the company 
  # does not apply for any patents in that year - the natural approximation)
  #
  ######################################################################
  ######################################################################
  
  
  ### Compute weights - easy with data.table
  #inventorsPatentsWeights <- inventorsPatents[ , weight := .N, by]
  #inventorsPatentsWeights$weight <- 1/inventorsPatentsWeights$weight
  
  # clean up
  #rm(list=c("inventorsPatents"))
  
  ### Load in dynass, compustat and merge 
  ## Load dynass
  dynass <- read.dta13('Data/dynass_reshaped.dta')
  # Clean
  dynass$gvkey <- as.integer(dynass$gvkey)
  dynass <- dynass %>% select(gvkey,pdpass,year)
  
  ## Merge inventorsPatentsWeights and dynass
  # Prepare for merge
  dynass <- data.table(dynass)
  setkey(dynass,pdpass,year)
  setkey(inventorsPatents,pdpass,year)
  # Merge
  inventorsPatentsDynass <- merge(inventorsPatents,dynass)
  
  ## Clean up: remove inventorsAndPatents and dynass
  rm(list = c("inventorsPatents","dynass"))
  
  #### Merge patentsAssigneesDynass with compustat's XRD data
  ## Load compustat dataset and clean
  compustat <- read.dta13('Raw/compustat_annual.dta')
  compustat <- compustat %>% select(gvkey,fyear,xrd,state)
  
  compustat$year <- compustat$fyear
  compustat$gvkey <- as.integer(compustat$gvkey)
  
  ## Merge and clean
  # Convert compustat to data.table and set keys
  compustat <- data.table(compustat)
  setkey(compustat,gvkey,year)
  setkey(inventorsPatentsDynass,gvkey,year)
  inventorsPatentsCompustat <- merge(inventorsPatentsDynass,compustat,by = c("gvkey","year"),all.y = TRUE)
  
  # For diagnostics, save here so I don't have to redo above
  inventorsPatentsCompustat <- inventorsPatentsCompustat %>% select(-pdpass,-fyear)
  fwrite(inventorsPatentsCompustat, file = "Data/inventorsPatentsCompustat.csv")
  
  inventorsPatentsCompustat <- fread("Data/inventorsPatentsCompustat.csv", na.strings = c("",NA))    
  
  # Count number of patents per gvkey-year to modify weight so we can simply sum over gvkey-year entries later
  inventorsPatentsCompustat[, numInventorsInGvkeyYearPatent := .N, by = c("gvkey","year","patent")]
  inventorsPatentsCompustat[, numPatentsInGvkeyYear := uniqueN(patent), by = c("gvkey","year")]
  inventorsPatentsCompustatWeights <- inventorsPatentsCompustat[, weight := 1 / (numInventorsInGvkeyYearPatent * numPatentsInGvkeyYear)]
  rm(list = c("inventorsPatentsCompustat","compustat"))
  
  # Make tibble - necessary for spread()
  inventorsPatentsCompustatWeights[is.na(inventorState),inventorState := state]
  inventorsPatentsCompustatWeights[,state := NULL]
  inventorsPatentsCompustatWeights <- inventorsPatentsCompustatWeights %>% dplyr::rename(state = inventorState)
  
  # Compute sum of weights by gvkey-year-inventorState
  
  gvkeyYearStateWeights <- inventorsPatentsCompustatWeights[, lapply(.SD,sum), by = c("gvkey","year","state"), .SDcols = "weight"]
  setkey(gvkeyYearStateWeights,gvkey,year)
  
  gvkeyYearXrd <- unique(inventorsPatentsCompustatWeights, by=c("gvkey","year"))[,c("gvkey","year","xrd")]
  
  setkey(gvkeyYearXrd,gvkey,year)
  
  gvkeyYearStateWeightsXrd <- merge(gvkeyYearStateWeights,gvkeyYearXrd)
  
  # Clean up
  rm(list = c("inventorsPatentsCompustatWeights","gvkeyYearStateWeights","gvkeyYearXrd"))
  
  gvkeyYearStateWeightsXrd[is.na(xrd), xrd := 0]
  
  gvkeyYearStateWeightsXrd[, xrdStateLevel := xrd * weight ]
  
  #### Aggregate by state!
  
  yearStateXrd <- gvkeyYearStateWeightsXrd[ , lapply(.SD,sum), by = c("year","state"), .SDcols = "xrdStateLevel"]
  yearStateXrd <- yearStateXrd %>% dplyr::rename(xrd = xrdStateLevel)
  
  ### Save data!
  
  fwrite(yearStateXrd,"Data/yearStateXrd.csv")

})


