#------------------------------------------------#
#
# File name: constructPatentCounts.R
#
# Author: Nicolas Fernandez-Arias 
#
# Purpose:
#
# This script construct patent counts using the patentsGvkeys dataset
#------------------------------------------------#

rm(list = ls())

patentsAppyearGvkeys <- fread("data/patentsAppyearGvkeys.csv")
patentsGrantedyearGvkeys <- fread("data/patentsGrantedyearGvkeys.csv")

appCounts <- patentsAppyearGvkeys[!is.na(gvkey)][ , .N, by = c("gvkey","year")]
grantedCounts <- patentsGrantedyearGvkeys[!is.na(gvkey)][ , .N, by = c("gvkey","year")]

appCitationCounts <- patentsAppyearGvkeys[!is.na(gvkey)][ , sum(allcites), by = c("gvkey","year")]
grantedCitationCounts <- patentsGrantedyearGvkeys[!is.na(gvkey)][ , sum(allcites), by = c("gvkey","year")]

fwrite(appCounts,"data/patentApplicationCounts.csv")
fwrite(grantedCounts,"data/patentGrantCounts.csv")
fwrite(appCitationCounts,"data/patentApplicationCitationCounts.csv")
fwrite(grantedCitationCounts,"data/patentGrantCitationCounts.csv")

