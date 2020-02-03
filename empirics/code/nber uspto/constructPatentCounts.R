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

patentsAppyearGvkeys <- fread("data/patentsAppyearGvkeys.csv")
patentsGrantedyearGvkeys <- fread("data/patentsGrantedyearGvkeys.csv")

appCounts <- patentsAppyearGvkeys[!is.na(gvkey)][ , .N, by = c("gvkey","year")]
grantedCounts <- patentsGrantedyearGvkeys[!is.na(gvkey)][ , .N, by = c("gvkey","year")]

patentsCitations <- fread("raw/nber uspto/pat76_06_assg.csv")[ , .(patent,allcites)]

setkey(patentsCitations,patent)
setkey(patentsAppyearGvkeys,patent)
setkey(patentsGrantedyearGvkeys,patent)

patentsCitationsAppyearGvkeys <- patentsAppyearGvkeys[patentsCitations]
patentsCitationsGrantedyearGvkeys <- patentsGrantedyearGvkeys[patentsCitations]

appCitationCounts <- patentsCitationsAppyearGvkeys[!is.na(gvkey)][ , sum(allcites), by = c("gvkey","year")]
grantedCitationCounts <- patentsCitationsGrantedyearGvkeys[!is.na(gvkey)][ , sum(allcites), by = c("gvkey","year")]

# Save data
fwrite(appCounts,"data/patentApplicationCounts.csv")
fwrite(grantedCounts,"data/patentGrantCounts.csv")
fwrite(appCitationCounts,"data/patentApplicationCitationCounts.csv")
fwrite(grantedCitationCounts,"data/patentGrantCitationCounts.csv")

# Clean up
rm(appCitationCounts,appCounts,grantedCitationCounts,grantedCounts,
   patentsAppyearGvkeys,patentsCitations,patentsCitationsAppyearGvkeys,
   patentsCitationsGrantedyearGvkeys,patentsGrantedyearGvkeys)



  
