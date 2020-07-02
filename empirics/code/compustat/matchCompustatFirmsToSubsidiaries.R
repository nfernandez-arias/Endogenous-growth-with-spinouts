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

segments <- fread("raw/compustat/compustat_segments_annual.csv")
segments <- segments[ , .(gvkey,srcdate,datadate,snms,stype,NAICSS1,NAICSS2,soptp1,soptp2)]
segments <- segments[ stype == "BUSSEG"]

#segments <- segments[ soptp1 == "DIV"]
segments <- segments[ , stype := NULL]
segments <- segments[order(snms,datadate)]
segments <- unique(segments, by = c("gvkey","snms","datadate"))

# Remove segments that are generic - trying to remove observations that are not names of subsidiaries but rather generic names of divisions
# Do this by removing segments which appear under more than one gvkey.
segmentsUnique <- unique(segments, by = c("snms", "gvkey"))
segmentsUnique[ , count := .N , by = snms]
setkey(segmentsUnique,gvkey,snms)
setkey(segments,gvkey,snms)

segmentsUnique <- segmentsUnique[ , .(gvkey,snms,count)]

segments <- segmentsUnique[segments]
segments <- segments[count == 1]

segments[ , dataYear := as.numeric(substr(datadate,1,4))]

firms <- fread("data/compustat/compustatFirms.csv")

setkey(segments,gvkey,dataYear)
setkey(firms,gvkey,fyear)

output <- segments[firms]
output <- output[order(gvkey,dataYear)]

fwrite(output,"data/compustat/firmsSegments.csv")

# Clean up
rm(list = ls.str(mode = "list"))

