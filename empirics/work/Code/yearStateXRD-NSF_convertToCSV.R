# File name: yearStateXRD-NSF_convertToCSV.R
#
# Description: Converts NSF data to csv (see Docs/README.txt)
#


rm(list = ls())
setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

library(data.table)
library(readstata13)
library(dplyr)

data1 <- data.table(read.dta13('Data/business-performed-rd-by-state.dta'))
data1 <- data1 %>% rename(xrdBusinessNSF = RD, gdpBusinessNSF = OUTPUT)
data1 <- data1 %>% select(state,year,xrdBusinessNSF,gdpBusinessNSF)

data2 <- data.table(read.dta13('Data/rd-by-state.dta'))
data2 <- data2 %>% rename(xrdTotalNSF = RD, gdpTotalNSF = GDP)
data2 <- data2 %>% select(state,year,xrdTotalNSF,gdpTotalNSF)

setkey(data1,state,year)
setkey(data2,state,year)

data <- merge(data1,data2,all.y = TRUE)

#data <- data %>% select(state,year,xrd_NSF,GDP_NSF)
fwrite(data,"Data/yearStateXRD_NSFaggregate.csv")


