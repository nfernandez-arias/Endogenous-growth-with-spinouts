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


setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

rm(list = ls())
library(data.table)
#library(dplyr)
#library(fuzzyjoin) 

compustatFirmsSegments <- fread("data/compustat/firmsSegments.csv")
EntitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")

compustatFirmsSegments <- compustatFirmsSegments[ , .(gvkey,conml,snms)]
compustatFirmsSegments <- compustatFirmsSegments[ , conml := gsub("[.]$","",conml), by = gvkey]
compustatFirmsSegments <- compustatFirmsSegments[ , conml := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",conml), by = gvkey]
PrevEmployers <- unique(EntitiesPrevEmployers[, .(EntityID,EntityName,Founder,Title,TitleCode,PreviousEmployer)], by = "PreviousEmployer")
rm(EntitiesPrevEmployers)

PrevEmployers[ , PreviousEmployerCLEAN := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",PreviousEmployer), by = PreviousEmployer]
PrevEmployers[ , PreviousEmployerCLEAN := gsub("[.]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
PrevEmployers[ , PreviousEmployerCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]

PrevEmployers <- unique(PrevEmployers, by = "PreviousEmployerCLEAN")
  
setkey(compustatFirms,conml)
setkey(PrevEmployers,PreviousEmployerCLEAN)
output <- compustatFirms[PrevEmployers]
#output <- PrevEmployers[compustatFirms]
length(na.omit(output$PreviousEmployer))
  
#outputFuzzy <- PrevEmployers[1:5000] %>% stringdist_inner_join(compustatFirms, by = c(PreviousEmployer = "conml"), method = c("lv"), max_dist = 0, distance_col = "distance")

#for (i in 2:16) {

#outputFuzzy <- rbind(outputFuzzy,na.omit(PrevEmployers[5000*(i-1)+1:5000*i]) %>% stringdist_inner_join(compustatFirms, by = c(PreviousEmployer = "conml"), method = c("lv"), max_dist = 0, distance_col = "distance"))

#}

#i <- 17

#outputFuzzy <- rbind(outputFuzzy,na.omit(tail(PrevEmployers,5000-1)) %>% stringdist_inner_join(compustatFirms, by = c(PreviousEmployer = "conml"), method = c("lv"), max_dist = 0, distance_col = "distance"))

setkey(compustatFirmsSegments,snms)
setkey(PrevEmployers,PreviousEmployerCLEAN)

output <- compustatFirmsSegments[PrevEmployers]



