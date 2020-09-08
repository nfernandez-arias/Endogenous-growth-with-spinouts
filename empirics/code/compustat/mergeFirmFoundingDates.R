#------------------------------------------------#
#
# File name: mergeFirmFoundingDates.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script merges compustat with founding dates
# from Jay Ritter at University of Florida
#------------------------------------------------#

foundingDates <- setDT(read.xlsx("raw/compustat/age19752019.xlsx"))

foundingDates[ str_length(CUSIP) == 8, CUSIP := paste0(CUSIP,"0")]

compustat <- fread("data/compustat/compustatFirms.csv")

setkey(foundingDates,CUSIP)
setkey(compustat,cusip)

compustat <- foundingDates[ , .(CUSIP,Founding)][compustat]

fwrite(compustat,"data/compustat/compustatFirms.csv")

# Clean up
rm(list = ls.str(mode = "list"))
