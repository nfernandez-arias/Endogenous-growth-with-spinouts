#------------------------------------------------#
#
# File name: matchPatentsGvkeys.R
#
# Author: Nicolas Fernandez-Arias 
#
# Purpose:
#
# This script matches patents to gkveys using the 
# rehsaped dynass dataset
#------------------------------------------------#

dynass_reshaped <- fread("data/nber uspto/dynass_reshaped.csv")

patents <- fread("raw/nber uspto/pat76_06_assg.csv")[ , .(pdpass,patent,appyear,gyear)]

setkey(dynass_reshaped,pdpass,year)

setkey(patents,pdpass,appyear)

patentsApplied <- dynass_reshaped[patents][order(pdpass,year)]

setkey(patents,pdpass,gyear)
patentsGranted <- dynass_reshaped[patents][order(pdpass,year)]

fwrite(patentsApplied,"data/patentsAppyearGvkeys.csv")
fwrite(patentsGranted,"data/patentsGrantedyearGvkeys.csv")

# Clean up
rm(list = ls.str(mode = "list"))





