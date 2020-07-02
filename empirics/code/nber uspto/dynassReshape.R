#------------------------------------------------#
#
# File name: dynassReshape.R
#
# Author: Nicolas Fernandez-Arias 
#
# Purpose:
#
# This code rehsapes dynass into a form more amenable
# to matching with compustat.
#------------------------------------------------#

dynass <- fread("raw/nber uspto/dynass.csv")

dynass_long <- melt(dynass, id.vars = c("pdpass","source","gvkey1","gvkey2","gvkey3","gvkey4","gvkey5"), 
                    measure.vars = c("begyr1","begyr2","begyr3","begyr4","begyr5"))[order(pdpass,variable)]

dynass_long[variable == "begyr1" | variable == "endyr1", gvkey := gvkey1]
dynass_long[variable == "begyr2" | variable == "endyr2", gvkey := gvkey2]
dynass_long[variable == "begyr3" | variable == "endyr3", gvkey := gvkey3]
dynass_long[variable == "begyr4" | variable == "endyr4", gvkey := gvkey4]
dynass_long[variable == "begyr5" | variable == "endyr5", gvkey := gvkey5]

temp <- dynass_long[ , .(pdpass,gvkey,variable,value)]

setnames(temp,"value","year")

temp <- data.table(complete(temp,pdpass,year))

temp[ , gvkey := na.locf0(gvkey), by = pdpass]

temp <- temp[!is.na(gvkey) & !is.na(year)]

temp <- temp[ , .(pdpass,gvkey,year)]

# Save data
fwrite(temp,"data/nber uspto/dynass_reshaped.csv")

# Clean up
rm(list = ls.str(mode = "list"))
