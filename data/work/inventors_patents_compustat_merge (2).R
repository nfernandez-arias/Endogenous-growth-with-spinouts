# File name: inventors_patents_compustat_merge.R
#
# Function: Reads in and cleans
# Raw/pat76_06_assg.dta,
# Raw/inventor.csv,
# Data/dynass_reshaped.dta
# Raw/compustat_annual_13.dta

# Merges pat76_06_assg.dta and inventor.csv by patent number
# merges with dynas_reshaped by pdpass
# merges with compustat by year using gvkey
#
# Outputs: Data\patents_inventor.rda
#

setwd("/home/nico/Google Drive/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

ptm <- proc.time()
library(readstata13)
source('stata_merge.R')
patents <- read.dta13('Raw/pat76_06_assg.dta')
patents$year <- patents$appyear
# Read in datasets
inventors <- read.csv('Raw/inventor.csv')
names(inventors)[names(inventors) == 'Patent'] <- 'patent'

# Destring patent variable
inventors$patent = as.numeric(as.character(inventors$patent))

# Mergerm(list = setdiff(ls(), lsf.str()))
#inventors_patents <- stata.merge(patents,inventors,"patent")
inventors_patents <- merge(patents,inventors,by = "patent")
proc.time() - ptm
rm(list = c("inventors","patents"))

## Load dynass_reshaped
dynass = read.dta13('Data/dynass_reshaped.dta')
head(dynass)
# Merge
inventors_patents_dynass <- stata.merge(inventors_patents,dynass,c("pdpass","year"))
#head(inventors_patents_dynass)
rm(list = c("inventors_patents","dynass"))


## Load compustat dataset
compustat <- read.dta13('Raw/compustat_annual.dta')
