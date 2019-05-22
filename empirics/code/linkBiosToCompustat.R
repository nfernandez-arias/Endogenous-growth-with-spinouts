#------------------------------------------------#
#
# File name: linkBiosToCompustat.R
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
library(dplyr)
library(fuzzyjoin) 

compustatFirmsSegments <- fread("data/compustat/firmsSegments.csv")
compustatFirmsSegments[tic == "IBM", conml := "IBM"]
compustatFirmsSegments[tic == "GS", conml := "Goldman Sachs"]
# select segments
segments <- compustatFirmsSegments[snms != ""]
segments <- segments[ gvkey != 17997 | snms != "AT&T"]

EntitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")

## Select only founders
####
# Count CEO-Chairman and CTOs as founders when no founder listed 
EntitiesPrevEmployers[, Founder2 := 1 - max(Founder), by = EntityID]
EntitiesPrevEmployers[Founder2 == 1 & (TitleCode == "CTO" | TitleCode == "CCEO"), Founder := 1]

# Select founders

EntitiesPrevEmployers <- EntitiesPrevEmployers[Founder == 1]
EntitiesPrevEmployers <- EntitiesPrevEmployers[!is.na(PreviousEmployer) & PreviousEmployer != ""]

# Set weights to take into account multiple founders at same firm - to not overcount spinouts
# i.e. this way if we aggregate spinout measure across firms, we get the total number of spinouts
EntitiesPrevEmployers[, Weight := 1 / .N, by = EntityID]


## Prepare data

compustatFirmsSegments <- compustatFirmsSegments[ , .(gvkey,conml,snms,tic)]
compustatFirmsSegments <- compustatFirmsSegments[ , conml := gsub("[.]$","",conml), by = gvkey]
compustatFirmsSegments <- compustatFirmsSegments[ , conml := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",conml), by = gvkey]
#PrevEmployers <- unique(EntitiesPrevEmployers[, .(Weight,EntityID,EntityName,JoinDate,StartDate,Title,TitleCode,PreviousEmployer)], by = "PreviousEmployer")

#rm(EntitiesPrevEmployers)

EntitiesPrevEmployers <- EntitiesPrevEmployers[, .(Weight,EntityID,EntityName,JoinDate,StartDate,Title,TitleCode,PreviousEmployer)]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("[.]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("[ ]?[(].*[)]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("^Google.*$","Google",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]


#PrevEmployers <- unique(PrevEmployers, by = "PreviousEmployerCLEAN")

# Match first to parent firms via business divisions, using segments data from Compustat

setkey(segments,snms)
setkey(EntitiesPrevEmployers,PreviousEmployerCLEAN)
output <- segments[EntitiesPrevEmployers]
#output <- EntitiesPrevEmployers[segments]
#outputFuzzy <- PrevEmployers[1:5000] %>% stringdist_inner_join(segments, by = c(PreviousEmployer = "snms"), method = c("lv"), max_dist = 1, distance_col = "distance")

output <- output[ , .(gvkey,conml,snms,tic,PreviousEmployer,EntityID,EntityName,Weight,JoinDate,StartDate)]

# Analyze output
#output[, PrevEmployerSpinoutCount := sum(Weight), by = .(snms)]

# Next, match to parent firms directly
firms <- unique(compustatFirmsSegments, by = "gvkey")
firms[, snms := NA]
setkey(firms,conml)
output2 <- firms[EntitiesPrevEmployers]
output2 <- output2[ , .(gvkey,conml,snms,tic,PreviousEmployer,EntityID,EntityName,Weight,JoinDate,StartDate)]

#output2[, PrevEmployerSpinoutCount := sum(Weight), by = .(conml)]
output <- rbind(output[!is.na(gvkey)],output2[!is.na(gvkey)])
output2 <- rbind(output[is.na(gvkey)],output2[is.na(gvkey)])
temp <- output2[, .N, by = conml]

temp2 <- output[, .N, by = conml]

fwrite(output,"data/parentsSpinouts.csv")
  
#outputFuzzy <- PrevEmployers[1:5000] %>% stringdist_inner_join(compustatFirms, by = c(PreviousEmployer = "conml"), method = c("lv"), max_dist = 0, distance_col = "distance")

#for (i in 2:16) {

#outputFuzzy <- rbind(outputFuzzy,na.omit(PrevEmployers[5000*(i-1)+1:5000*i]) %>% stringdist_inner_join(compustatFirms, by = c(PreviousEmployer = "conml"), method = c("lv"), max_dist = 0, distance_col = "distance"))

#} 

#i <- 17

#outputFuzzy <- rbind(outputFuzzy,na.omit(tail(PrevEmployers,5000-1)) %>% stringdist_inner_join(compustatFirms, by = c(PreviousEmployer = "conml"), method = c("lv"), max_dist = 0, distance_col = "distance"))




