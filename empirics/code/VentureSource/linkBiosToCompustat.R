#------------------------------------------------#
#
# File name: linkBiosToCompustat.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script links EntityNames to the Compustat database
# to find parent firms. 
#------------------------------------------------#


setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/code/VentureSource")

rm(list = ls())

library(data.table)
library(stringr)


compustat <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/raw/compustat/compustat_annual.csv")
compustatFirms <- unique(compustat[ , .(gvkey,conm,conml,state,city)])
rm(compustat)

setkey(compustatFirms,conml)
setkey(data,Company1)

temp <- data[compustatFirms]


setkey(names,EntityName)

setkey(temp,Company1)

temp <- temp[names]
