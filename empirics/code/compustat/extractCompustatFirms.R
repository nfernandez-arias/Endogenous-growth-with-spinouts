#------------------------------------------------#
#
# File name: extractCompustatFirms.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# Extracts relevant compustat variables
#------------------------------------------------#

compustat <- fread("raw/compustat/compustat_annual.csv")[indfmt=="INDL" & datafmt=="STD" & popsrc=="D" & consol=="C" & loc == "USA"]
#compustat <- fread("raw/compustat/compustat_annual.csv")[indfmt=="INDL" & datafmt=="STD" & popsrc=="D" & consol=="C"]

compustat <- compustat[ , .(fyear,gvkey,naics,dldte,dlrsn,tic,exchg,cusip,cik,conm,conml,state,city,xrd)]
compustatFirms <- unique(compustat[ , .(gvkey,cusip,fyear,naics,tic,conm,conml,state,city)])
setkey(compustatFirms,conml)
rm(compustat)
fwrite(compustatFirms,"data/compustat/compustatFirms.csv")

# Clean up
rm(list = ls.str(mode = "list"))
