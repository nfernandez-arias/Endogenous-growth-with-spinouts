# File name: clean_FirmEntryMeasures_state.R
#
# Description:
# 
# (1) Reads in: 




rm(list = setdiff(ls(), lsf.str()))
setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

library(plyr)
library(dplyr)
library(data.table)

data <- fread("Raw/bds_f_agest_release.csv")

data[, empTotal := sum(Emp), by = c("state","year2")]
data[, estabsTotal := sum(Estabs), by = c("state","year2")] 
data[, firmsTotal := sum(Firms), by = c("state","year2")]

data <- data[fage4 == "a) 0"]
data[,fage4 := NULL]


stateNames <- fread("Raw/statecodesabbrevs.csv")

setkey(data,state)
setkey(stateNames,state)

data2 <- merge(data,stateNames,by = "state")

fwrite(data2,"Data/firmEntryByState.csv")
