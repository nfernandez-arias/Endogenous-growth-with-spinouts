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

#rm(list = setdiff(ls(), lsf.str()))



setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

## Start timer
ptm <- proc.time()

## Load libraries
library(readstata13)
source('stata_merge.R')
source('arrange_vars.R')

#### Merge Patents and Inventors Datasets by Patent #

## Load in and clean Patents dataset
patents <- read.dta13('Raw/pat76_06_assg.dta')
patents$year <- patents$appyear

## Load in and clean Inventors datasets
inventors <- read.csv('Raw/inventor.csv')
names(inventors)[names(inventors) == 'Patent'] <- 'patent'
names(inventors)[names(inventors) == 'Country'] <- 'inventorCountry'
names(inventors)[names(inventors) == 'Zipcode'] <- 'inventorZipCode'
inventors$patent = as.numeric(as.character(inventors$patent))

## Merge datasets
inventorsAndPatents <- merge(patents,inventors,by = "patent")

# Diagnostics
#inventorsAndPatents <- stata.merge(patents,inventors,"patent")
#inventorsAndPatents <- arrange.vars(inventorsAndPatents,c("merege" = 1))
#inventorsAndPatents$merge <- factor(inventorsAndPatents$merge)
#summary(inventorsAndPatents$merge)

# Check time
proc.time() - ptm

# Remove unnecessary data: inventors, patents, and unnecessary variables in inventorsAndPatents
rm(list = c("inventors","patents"))
inventorsAndPatents <- inventorsAndPatents[,c("patent","pdpass","year","cclass","country","City","State","Firstname","Lastname","inventorCountry","inventorZipCode")]

#### Merge inventorsAndPatents and dynass, the dynamic match between pdpass and gvkey / pdpco

## Load dynass_reshaped
dynass = read.dta13('Data/dynass_reshaped.dta')

# Clean and diagnose
dynass$gvkey <- as.integer(dynass$gvkey)
head(dynass)

## Merge and Clean

# Merge
inventorsAndPatentsAndDynass <- merge(inventorsAndPatents,dynass,by = c("pdpass","year"))
# Clean: remove observations not in the US
#inventorsAndPatentsAndDynass <- inventorsAndPatentsAndDynass[(inventorsAndPatentsAndDynass$country == "US"),]

# Diagnostics
#inventorsAndPatentsAndDynass <- stata.merge(inventorsAndPatents,dynass,c("pdpass","year"))
#inventorsAndPatentsAndDynass <- inventorsAndPatentsAndDynass[(inventorsAndPatentsAndDynass$merge == 3),]
#inventorsAndPatentsAndDynass$merge <- factor(inventorsAndPatentsAndDynass$merge)

# Remove unnecessary data: inventorsAndPatents and dynass
rm(list = c("inventorsAndPatents","dynass"))

#### Merge inventorsAndPatents and compustat

## Load compustat dataset and clean
compustat <- read.dta13('Raw/compustat_annual.dta')
compustat$year <- compustat$fyear
# remove unnecessary columns to conserve memory
compustat <- compustat[,c("gvkey","year","xrd","loc","state","sic","naics","conm")]
#compustat <- compustat[with(compustat, order(gvkey, year)),]
compustat$gvkey <- as.integer(compustat$gvkey)

## Merge and clean
inventorsAndPatentsAndDynassAndCompustat <- merge(inventorsAndPatentsAndDynass,compustat,by = c("gvkey","year"))

# Diagnostics
#inventorsAndPatentsAndDynassAndCompustat <- stata.merge(inventorsAndPatentsAndDynass,compustat,c("gvkey","year"))
#inventorsAndPatentsAndDynassAndCompustat <- arrange.vars(inventorsAndPatentsAndDynassAndCompustat,c("merge" = 3))
#inventorsAndPatentsAndDynassAndCompustat$merge <- factor(inventorsAndPatentsAndDynassAndCompustat$merge)

# Remove unnecessary variables: inventorsAndPatents and compustat
rm(list = c("inventorsAndPatentsAndDynass","compustat"))

#### Summarize data
summary(inventorsAndPatentsAndDynassAndCompustat)

write.csv(inventorsAndPatentsAndDynassAndCompustat, file = "Data/inventors_patents_compustat.csv")

proc.time() - ptm
