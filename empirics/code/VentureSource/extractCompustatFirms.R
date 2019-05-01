#------------------------------------------------#
#
# File name: extractCompustatFirms.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script links EntityNames to the Compustat database
# to find parent firms. 
#------------------------------------------------#

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

rm(list = ls())
library(data.table)

compustat <- fread("raw/compustat/compustat_annual.csv")
compustatFirms <- unique(compustat[ , .(gvkey,conm,conml,state,city)])
setkey(compustatFirms,conml)
rm(compustat)
fwrite(compustatFirms,"data/compustat/compustatFirms.csv")

compustat_segments <- fread("raw/compustat/compustat_segments_annual.csv")
compustat_segments <- compustat_segments[ , .(gvkey,srcdate,datadate,conm,snms,stype,sic,naics,rds,emps,nis,ops,revts,sales,capxs)]
compustat_segments <- compustat_segments[ stype == "BUSSEG"]
compustat_segments <- compustat_segments[ , stype := NULL]
compustat_segments <- compustat_segments[order(conm,snms,datadate)]
