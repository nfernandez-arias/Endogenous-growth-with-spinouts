#------------------------------------------------#
#
# File name: matchCompustatFirmsToSubsidiaries.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script links Compustat firms to subsidiaries
# given by business segments.
#------------------------------------------------#

rm(list = ls())

library(data.table)

segments <- fread("raw/compustat/compustat_segments_annual.csv")
segments <- segments[ , .(gvkey,srcdate,datadate,conm,snms,stype,soptp1,soptp2)]
segments <- segments[ stype == "BUSSEG"]

#segments <- segments[ soptp1 == "DIV"]
segments <- segments[ , stype := NULL]
segments <- segments[order(conm,snms,datadate)]
segments <- unique(segments, by = c("gvkey","snms"))

# Remove segments that are generic - trying to remove observations that are not subsidiaries
segments[ , count := .N, by = "snms"]
segments <- segments[count == 1]

firms <- fread("data/compustat/compustatFirms.csv")

setkey(segments,gvkey)
setkey(firms,gvkey)

output <- segments[firms]
output <- output[order(conml)]

fwrite(output,"data/compustat/firmsSegments.csv")


