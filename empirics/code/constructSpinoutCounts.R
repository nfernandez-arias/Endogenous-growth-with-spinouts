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

fwrite(temp,"data/parentsSpinoutCounts.csv")





