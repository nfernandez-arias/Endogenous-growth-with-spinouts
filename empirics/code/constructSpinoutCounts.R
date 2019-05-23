#------------------------------------------------#
#
# File name: constructSpinoutCounts.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This constructs the spinout counts dataset
#------------------------------------------------#

rm(list = ls())

library(lubridate)
library(tidyr)

data <- fread("data/parentsSpinouts.csv")

data[ , year := pmin(na.omit(year(ymd(JoinDate))),na.omit(year(ymd(StartDate)))), by = .(gvkey,EntityID)]

temp <- data[ , sum(Weight), by = .(gvkey,year)]

setnames(temp,"V1","spinoutCount")

temp[is.na(spinoutCount) == TRUE, spinoutCount := 0]

temp[ , spinoutCountUnweighted := data[ , .N, by = .(gvkey,year)]$N ]

fwrite(temp,"data/parentsSpinoutCounts.csv")




