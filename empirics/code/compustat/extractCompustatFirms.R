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

rm(list = ls())
library(data.table)

compustat <- fread("raw/compustat/compustat_annual.csv")
compustat <- compustat[ , .(fyear,gvkey,dldte,dlrsn,tic,exchg,cusip,cik,conm,conml,state,city,xrd)]
compustatFirms <- unique(compustat[ , .(gvkey,tic,conm,conml,state,city)])
setkey(compustatFirms,conml)
rm(compustat)
fwrite(compustatFirms,"data/compustat/compustatFirms.csv")
