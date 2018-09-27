# File name: inventors_patents_merge.r
#
# Function: Reads in and cleans Raw/pat76_06_assg.dta,
# Reads in Raw/inventor.csv, and merges using 
# custom function stata.merge (which announces errors)
#
# Outputs: Data\patents_inventor.rda
#

ptm <- proc.time()
library(readstata13)
source('stata_merge.R')
patents <- read.dta13('Raw/pat76_06_assg.dta')

# Read in datasets
inventors <- read.csv('Raw/inventor.csv')
names(inventors)[names(inventors) == 'Patent'] <- 'patent'

# Destring patent variable
inventors$patent = as.numeric(as.character(inventors$patent))

# Merge
#inventors_patents <- stata.merge(patents,inventors,"patent")
inventors_patents <- merge(patents,inventors,by = "patent")
proc.time() - ptm


