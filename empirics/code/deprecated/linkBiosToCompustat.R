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
library(lubridate)

compustatFirmsSegments <- fread("data/compustat/firmsSegments.csv")
compustatFirmsSegments[tic == "IBM", conml := "IBM"]
compustatFirmsSegments[tic == "GS", conml := "Goldman Sachs"] 
compustatFirmsSegments[tic == "HPQ", conml := "Hewlett-Packard"]
compustatFirmsSegments[snms == "HP", snms := ""] 

EntitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")
#EntitiesPrevEmployers[ , foundingYear := pmin(na.omit(year(ymd(JoinDate))),na.omit(year(ymd(StartDate)))), by = .(EntityID)]
EntitiesPrevEmployers[ , joinYear := as.integer(year(ymd(JoinDate)))]
EntitiesPrevEmployers[ is.na(joinYear) , joinYear := foundingYear]
#EntitiesPrevEmployers <- EntitiesPrevEmployers[foundingYear <= 1999]

# Select founders

#EntitiesPrevEmployers <- EntitiesPrevEmployers[Founder == 1]
EntitiesPrevEmployers <- EntitiesPrevEmployers[!is.na(PreviousEmployer) & PreviousEmployer != ""]

## Prepare data

compustatFirmsSegments <- compustatFirmsSegments[ , .(gvkey,state,city,cusip,naics,NAICSS1,NAICSS2,dataYear,conml,snms,tic)]
compustatFirmsSegments <- compustatFirmsSegments[ , conml := gsub("[.]$","",conml), by = gvkey]
compustatFirmsSegments <- compustatFirmsSegments[ , conml := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",conml), by = gvkey]
#PrevEmployers <- unique(EntitiesPrevEmployers[, .(Weight,EntityID,EntityName,JoinDate,StartDate,Title,TitleCode,PreviousEmployer)], by = "PreviousEmployer")

#rm(EntitiesPrevEmployers)


EntitiesPrevEmployers <- EntitiesPrevEmployers[, .(EntityID,founder2,EntityName,IndustryCodeDesc,SubcodeDesc,foundingYear,FirstName,LastName,joinYear,Title,TitleCode,PreviousEmployer)]
EntitiesPrevEmployers[ PreviousEmployer == "Cisco", PreviousEmployer := "Cisco Systems"]
EntitiesPrevEmployers[ PreviousEmployer == "Amazon", PreviousEmployer := "Amazon.com"]
EntitiesPrevEmployers[ PreviousEmployer == "Yahoo" | PreviousEmployer == "Yahoo!", PreviousEmployer :=  "Verizon"]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("[.]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("[ ]?[(].*[)]$","",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]
EntitiesPrevEmployers[ , PreviousEmployerCLEAN := gsub("^Google.*$","Google",PreviousEmployerCLEAN), by = PreviousEmployerCLEAN]

# Set everything to upper case for easier matching

#compustatFirmsSegments[, snms := toupper(snms)]
#compustatFirmsSegments[, conml := toupper(conml)]
#EntitiesPrevEmployers[ , PreviousEmployerCLEAN := toupper(PreviousEmployerCLEAN)]

#PrevEmployers <- unique(PrevEmployers, by = "PreviousEmployerCLEAN")

# Match first to parent firms via business divisions, using segments data from Compustat

# select segments
segments <- compustatFirmsSegments[snms != ""]
segments <- segments[ gvkey != 17997 | snms != "AT&T"]
segments[ , dataYear := as.numeric(dataYear)]
  
#setkey(segments,snms,dataYear)
#setkey(EntitiesPrevEmployers,PreviousEmployerCLEAN,joinYear)
#output <- segments[EntitiesPrevEmployers][!is.na(gvkey)]

tempSegments <- unique(segments, by = "snms")
setkey(tempSegments,snms)
setkey(EntitiesPrevEmployers,PreviousEmployerCLEAN)
output <- tempSegments[EntitiesPrevEmployers]



#output <- EntitiesPrevEmployers[segments]
#outputFuzzy <- PrevEmployers[1:5000] %>% stringdist_inner_join(segments, by = c(PreviousEmployer = "snms"), method = c("lv"), max_dist = 1, distance_col = "distance")

output <- output[ , .(gvkey,cusip,state,city,naics,NAICSS1,NAICSS2,conml,snms,tic,PreviousEmployer,founder2,EntityID,EntityName,IndustryCodeDesc,SubcodeDesc,foundingYear,FirstName,LastName,joinYear)]

# Analyze output
#output[, PrevEmployerSpinoutCount := sum(Weight), by = .(snms)]

# Next, match to parent firms directly
firms <- unique(compustatFirmsSegments, by = "gvkey")
firms[, snms := NA]
setkey(firms,conml)
output2 <- firms[EntitiesPrevEmployers]
output2 <- output2[ , .(gvkey,cusip,state,city,naics,NAICSS1,NAICSS2,conml,snms,tic,PreviousEmployer,founder2,EntityID,EntityName,IndustryCodeDesc,SubcodeDesc,foundingYear,FirstName,LastName,joinYear)]

output_noNA <- output[!is.na(gvkey)]
output2_noNA <- output2[!is.na(gvkey)]

#output2[, PrevEmployerSpinoutCount := sum(Weight), by = .(conml)]  

# output3 computes unique at this point, for testing, but not used later
output3 <- unique(rbind(output,output2),by = c("gvkey","EntityID","FirstName","LastName","joinYear")) 

# output4 contains the Entity-Manager observations successfully matched. May contain repeats if a firm name is also a segment. Repeats are useful for testing.
output4 <- rbind(output_noNA,output2_noNA)
setkey(output4,EntityID,FirstName,LastName,joinYear)
dups <- duplicated(output4, by = key(output4))
output4[ , fD := dups | c(tail(dups,-1), FALSE)]
output4_repeats <- output4[fD == TRUE]
output4[ , fD := NULL]

# output2 contains the Entity-Manager observations that are not matched to firms in compustat. This is the list of firms that I will feed into Serp API / AltDG  
# to try and improve the match. Useful for testing.

#output_NA <- unique(output[is.na(gvkey)], by = c("snms","EntityID","FirstName","LastName"))
#output2_NA <- unique(output2[is.na(gvkey)], by = c("conml","EntityID","FirstName","LastName"))

output_NA <- output[is.na(gvkey)]
output2_NA <- output2[is.na(gvkey)]

output2 <- rbind(output_NA,output2_NA)
 
output2[is.na(conml)&!is.na(snms), conml := snms]

output2 <- output2[conml != ""]
setkey(output2,conml)

dups2 <- duplicated(output2, by = c("conml","EntityID","FirstName","LastName"))
output2_dups <- output2[dups2]

temp <- output2_dups[, .N, by = conml][order(-N)] 
#temp2 <- output[, .N, by = conml]

#fwrite(data.table(temp[order(-N)]$conml),"code/company_list_2.txt")
#fwrite(data.table(temp[order(-N)]$conml)[1:5000],"code/company_list_5000_2.txt")
#fwrite(data.table(temp[order(-N)]$conml)[5001:10000],"code/company_list_10000_2.txt")
#fwrite(data.table(temp[order(-N)]$conml)[10001:15000],"code/company_list_15000_2.txt")
  

####################################
## Merge in additional previous employers using
# ticker symbols, obtained through scraping Google search results
####################################

# Use firmsTickers to match firms that are not matched by name
firmsTickers2 <- fread("data/firmsTickersClean.csv")
firmsTickers <- fread("data/firmsTickersAltDG.csv")

# merge with firms database using ticker symbol
setkey(firmsTickers,Ticker)
#setkey(firmsTickers2,tic)
setkey(firms,tic)
#firmsTickersGvkeys <- firms[firmsTickers]
firmsTickersGvkeys <- firms[firmsTickers]

# merge with EntitiesPrevEmployers and append to output 
setkey(firmsTickersGvkeys,query)

temp <- EntitiesPrevEmployers[firmsTickersGvkeys, nomatch = 0]

temp <- temp[ , .(gvkey,cusip,state,city,naics,NAICSS1,NAICSS2,conml,snms,tic,PreviousEmployer,founder2,EntityID,EntityName,IndustryCodeDesc,SubcodeDesc,foundingYear,FirstName,LastName,joinYear)]

temp <- temp[!is.na(gvkey)]

output5 <- unique(rbind(output4,temp), by = c("gvkey","EntityID","foundingYear","FirstName","LastName","joinYear")) 

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
  
#rm(list = c("compustatFirmsSegments","EntitiesPrevEmployers","firms","firmsTickers","firmsTickersGvkeys","output","output_noNA","output2","output2_noNA","output3","output4","output4_repeats","output5","segments","temp"))

#rm(list = c("compustatFirmsSegments","EntitiesPrevEmployers","firms","firmsTickers","firmsTickersGvkeys","segments","dups"))

##################################
# Write output
##################################
        
fwrite(output5,"data/parentsSpinouts.csv")


