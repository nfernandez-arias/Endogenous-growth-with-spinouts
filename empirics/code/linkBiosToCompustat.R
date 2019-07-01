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

compustatFirmsSegments <- fread("data/compustat/firmsSegments.csv")
compustatFirmsSegments[tic == "IBM", conml := "IBM"]
compustatFirmsSegments[tic == "GS", conml := "Goldman )Sachs"]
compustatFirmsSegments[tic == "HPQ", conml := "Hewlett-Packard"]

EntitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")

## Select only founders
####
# Count CEO-Chairman and CTOs as founders when no founder listed 
#EntitiesPrevEmployers[, Founder2 := 1 - max(Founder), by = EntityID]
#EntitiesPrevEmployers[Founder2 == 1 & (TitleCode == "CTO" | TitleCode == "CCEO"), Founder := 1]

# Select founders

#EntitiesPrevEmployers <- EntitiesPrevEmployers[Founder == 1]
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

EntitiesPrevEmployers <- EntitiesPrevEmployers[, .(Weight,EntityID,EntityName,FirstName,LastName,JoinDate,StartDate,Title,TitleCode,PreviousEmployer)]
EntitiesPrevEmployers[ PreviousEmployer == "Cisco", PreviousEmployer := "Cisco Systems"]
EntitiesPrevEmployers[ PreviousEmployer == "Amazon", PreviousEmployer := "Amazon.com"]
EntitiesPrevEmployers[ PreviousEmployer == "Yahoo" | PreviousEmployer == "Yahoo!", PreviousEmployer := "Verizon"]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("[.]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("[ ]?[(].*[)]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("^Google.*$","Google",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]

# Set everything to upper case for easier matching

compustatFirmsSegments[, snms := toupper(snms)]
compustatFirmsSegments[, conml := toupper(conml)]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := toupper(PreviousEmployerCLEAN)]

#PrevEmployers <- unique(PrevEmployers, by = "PreviousEmployerCLEAN")

# Match first to parent firms via business divisions, using segments data from Compustat

# select segments
segments <- compustatFirmsSegments[snms != ""]
segments <- segments[ gvkey != 17997 | snms != "AT&T"]

setkey(segments,snms)
setkey(EntitiesPrevEmployers,PreviousEmployerCLEAN)
output <- segments[EntitiesPrevEmployers]
#output <- EntitiesPrevEmployers[segments]
#outputFuzzy <- PrevEmployers[1:5000] %>% stringdist_inner_join(segments, by = c(PreviousEmployer = "snms"), method = c("lv"), max_dist = 1, distance_col = "distance")

output <- output[ , .(gvkey,conml,snms,tic,PreviousEmployer,EntityID,EntityName,Weight,FirstName,LastName,JoinDate,StartDate)]

# Analyze output
#output[, PrevEmployerSpinoutCount := sum(Weight), by = .(snms)]

# Next, match to parent firms directly
firms <- unique(compustatFirmsSegments, by = "gvkey")
firms[, snms := NA]
setkey(firms,conml)
output2 <- firms[EntitiesPrevEmployers]
output2 <- output2[ , .(gvkey,conml,snms,tic,PreviousEmployer,EntityID,EntityName,Weight,FirstName,LastName,JoinDate,StartDate)]

output_noNA <- output[!is.na(gvkey)]
output2_noNA <- output2[!is.na(gvkey)]

#output2[, PrevEmployerSpinoutCount := sum(Weight), by = .(conml)]  

# output3 computes unique at this point, for testing, but not used later
output3 <- unique(rbind(output,output2),by = c("gvkey","EntityID","FirstName","LastName","JoinDate","StartDate")) 

# output4 contains the Entity-Manager observations successfully matched. May contain repeats if a firm name is also a segment. Repeats are useful for testing.
output4 <- rbind(output_noNA,output2_noNA)
setkey(output4,EntityID,FirstName,LastName,JoinDate,StartDate)
dups <- duplicated(output4, by = key(output4))
output4[ , fD := dups | c(tail(dups,-1), FALSE)]
output4_repeats <- output4[fD == TRUE]
output4[ , fD := NULL]

# output2 contains the Entity-Manager observations that are not matched to firms in compustat. This is the list of firms that I will feed into Serp API / AltDG  
# to try and improve the match. Useful for testing.
output2 <- rbind(output[is.na(gvkey)],output2[is.na(gvkey)])


#temp <- output2[, .N, by = conml]
#temp2 <- output[, .N, by = conml]

#fwrite(temp[order(-N)],"code/company_list.csv")

####################################
## Merge in additional previous employers using
# ticker symbols, obtained through scraping Google search results
####################################

# Use firmsTickers to match firms that are not matched by name
firmsTickers <- fread("data/firmsTickersClean.csv")

# merge with firms database using ticker symbol
setkey(firmsTickers,tic)
setkey(firms,tic)
firmsTickersGvkeys <- firms[firmsTickers]

# merge with EntitiesPrevEmployers and append to output
setkey(firmsTickersGvkeys,firmName)

temp <- firmsTickersGvkeys[EntitiesPrevEmployers][!is.na(gvkey)]

temp <- temp[ , .(gvkey,conml,snms,tic,PreviousEmployer,EntityID,EntityName,Weight,FirstName,LastName,JoinDate,StartDate)]

output5 <- unique(rbind(output4,temp), by = c("gvkey","EntityID","FirstName","LastName","JoinDate","StartDate"))

# Just for testing - remove later

test_output <- output
test_output_noNA <- output_noNA
test_output2 <- output2
test_output2_noNA <- output2_noNA
test_output3 <- output3
test_output4 <- output4
test_output4_repeats <- output4_repeats
test_output5 <- output5
test_temp <- temp
  
rm(list = c("compustatFirmsSegments","EntitiesPrevEmployers","firms","firmsTickers","firmsTickersGvkeys","output","output_noNA","output2","output2_noNA","output3","output4","output4_repeats","output5","segments","temp"))

rm(list = c("compustatFirmsSegments","EntitiesPrevEmployers","firms","firmsTickers","firmsTickersGvkeys","segments","dups"))

##################################
# Write output
##################################

fwrite(output5,"data/parentsSpinouts.csv")


