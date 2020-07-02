#------------------------------------------------#
#
# File name: mergePatents_RD-Spinouts.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script merges patent counts with the RD-Spinouts dataset
#------------------------------------------------#

appCounts <- fread("data/patentApplicationCounts.csv")
patentCounts <- fread("data/patentGrantCounts.csv")
appCitationCounts <- fread("data/patentApplicationCitationCounts.csv")
patentCitationCounts <- fread("data/patentGrantCitationCounts.csv")

compustatSpinouts <- fread("data/compustat-spinouts.csv")

setkey(appCounts,gvkey,year)
setkey(patentCounts,gvkey,year)
setkey(appCitationCounts,gvkey,year)
setkey(patentCitationCounts,gvkey,year)
setkey(compustatSpinouts,gvkey,year)

compustatSpinouts[ , patentApplicationCount := appCounts[compustatSpinouts]$N]
compustatSpinouts[ , patentCount := patentCounts[compustatSpinouts]$N]
compustatSpinouts[ , patentApplicationCount_CW := appCitationCounts[compustatSpinouts]$V1]
compustatSpinouts[ , patentCount_CW := patentCitationCounts[compustatSpinouts]$V1]

compustatSpinouts[is.na(patentApplicationCount) & year <= 2006, patentApplicationCount := 0]
compustatSpinouts[is.na(patentApplicationCount_CW) & year <= 2006, patentApplicationCount_CW := 0]
compustatSpinouts[is.na(patentCount) & year <= 2006, patentCount := 0]
compustatSpinouts[is.na(patentCount_CW) & year <= 2006, patentCount_CW := 0]

compustatSpinouts[, patentCount_cumulative := cumsum(patentCount), by = "gvkey"]
compustatSpinouts[, patentCount_CW_cumulative := cumsum(patentCount_CW), by = "gvkey"]

fwrite(compustatSpinouts,"data/compustat-spinouts.csv")

# Clean up
rm(list = ls.str(mode = "list"))
