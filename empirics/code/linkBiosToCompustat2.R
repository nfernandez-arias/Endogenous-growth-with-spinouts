#------------------------------------------------#
#
# File name: linkBiosToCompustat2.R
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
compustatFirmsSegments <- compustatFirmsSegments[ , .(gvkey,state,city,cusip,naics,NAICSS1,NAICSS2,dataYear,conml,snms,tic)]
compustatFirmsSegments[ , conml := gsub("[.]$","",conml), by = gvkey]
compustatFirmsSegments[ , conml := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",conml), by = gvkey]
compustatFirmsSegments[ , conml := tolower(conml)]

EntitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")[foundingYear >= 1986]
#EntitiesPrevEmployers[ , foundingYear := pmin(na.omit(year(ymd(JoinDate))),na.omit(year(ymd(StartDate)))), by = .(EntityID)]
EntitiesPrevEmployers[ , joinYear := as.integer(year(ymd(JoinDate)))]
EntitiesPrevEmployers[ is.na(joinYear) , joinYear := foundingYear]
EntitiesPrevEmployers <- EntitiesPrevEmployers[!is.na(PreviousEmployer) & PreviousEmployer != ""]

## Prepare data
EntitiesPrevEmployers <- EntitiesPrevEmployers[, .(EntityID,founder2,EntityName,IndustryCodeDesc,SubcodeDesc,foundingYear,FirstName,LastName,joinYear,Title,TitleCode,PreviousEmployer)]
EntitiesPrevEmployers[ PreviousEmployer == "Cisco", PreviousEmployer := "Cisco Systems"]
EntitiesPrevEmployers[ PreviousEmployer == "Amazon", PreviousEmployer := "Amazon.com"]
EntitiesPrevEmployers[ PreviousEmployer == "Yahoo" | PreviousEmployer == "Yahoo!", PreviousEmployer :=  "Verizon"]
EntitiesPrevEmployers[ , PreviousEmployer := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployer := gsub("[.]$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployer := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployer := gsub("[ ]?[(].*[)]$","",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployer := gsub("^Google.*$","Google",PreviousEmployer), by = PreviousEmployer]
EntitiesPrevEmployers[ , PreviousEmployer := tolower(PreviousEmployer)]

# Initial merge

firms <- unique(compustatFirmsSegments,by = "gvkey")[ , .(gvkey,conml,tic,cusip,state,city,naics) ]
EntitiesPrevEmployers[ , count := .N, by = c("PreviousEmployer","joinYear")]
EntitiesPrevEmployers[ , globCount := .N, by = PreviousEmployer]
prevEmployers <- unique(EntitiesPrevEmployers, by = c("PreviousEmployer","joinYear"))[ , .(PreviousEmployer,joinYear,count,globCount)]

#setkey(prevEmployers,PreviousEmployer)
setkey(firms,conml)

firmsPrevEmployers <- firms[,.(gvkey,conml)][prevEmployers]

matched <- firmsPrevEmployers[ !is.na(gvkey)][ , .(gvkey,conml,joinYear,count,globCount)]
unmatched <- firmsPrevEmployers[ is.na(gvkey)][ , .(conml,joinYear,count,globCount)]

matched[ , source := "regex"]

## Merge using compustat segments data
segments <- unique(compustatFirmsSegments, by = "snms")[ , .(gvkey,snms)]

segments[ , snms := tolower(snms)]

setkey(segments,snms)
#setkey(unmatched,conml)

unmatched <- segments[unmatched]

matchedSegments <- unmatched[!is.na(gvkey)]
unmatched <- unmatched[is.na(gvkey)][ , .(snms,joinYear,count,globCount)]

matchedSegments[ , source := "compustat segments"]

firmsTickers <- fread("data/firmsTickersAltDG.csv")
firmsTickers[, query := tolower(query)]
firmsTickers <- unique(firmsTickers, by = "query")

setkey(firmsTickers,query)

unmatched <- firmsTickers[unmatched]

matchedQueries <- unmatched[!is.na(Ticker)]
unmatched <- unmatched[is.na(Ticker)][ , .(query,joinYear,count,globCount)]

matchedQueries[ , source := "altdg"]

# Merge matched queries to firms via ticker symbol
setkey(matchedQueries,Ticker)
setkey(firms,tic)

matchedQueries <- firms[matchedQueries][, .(gvkey,query,count,globCount,joinYear,source)][ !is.na(gvkey)]

## Change names to query

setnames(matched,"conml","name")
setnames(matchedSegments,"snms","name")
setnames(matchedQueries,"query","name")

matched <- rbind(matched,matchedSegments,matchedQueries)
#matched <- rbind(matched,matchedSegments)
### Now match back to EntitiesPrevEmployers

setkey(matched,gvkey)
setkey(firms,gvkey)

matched <- firms[matched]

### Check matches for accuracy

library(stringdist)

# First build matches that are not due to regex
matchedDist <- matched[stringdist(conml,name) > 0]

# Remove matches where one string is a subset of the other
matchedDist <- matchedDist[mapply(grepl,conml,name) == FALSE & mapply(grepl,name,conml) == FALSE]

# Next order by largest count
matchedDist <- matchedDist[order(-globCount,name,joinYear)]



### Make some ad-hoc corrections for major M&A
## Basically AltDG tells me if something is currently a subsidiary,
# which is helpful for understanding entire history of ownership, but 
# really I need to go back and manually ensure that the data is correct.
# Still, this is MUCH easier than just going with the initial list of names.


# Still need to figure out wtf is going on with AOL / Time Warner/ Verizon / Netscape


matched[ name == "merrill lynch" & joinYear <= 2012, `:=` (gvkey = 7267, tic = "BAC2", conml = "Merrill Lynch & Co Inc", naics = 523110, state = "NY", city = "New York", cusip = "59098Z002")]

matched[ name == "ca technologies" & joinYear <= 2018, `:=` (gvkey = 3310, tic = "CA", conml = "CA Inc", naics = 511210, state = "NY", city = "New York", cusip = "12673P105")]

matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear <= 1996, `:=` (gvkey = 9899, tic = "T", conml = "AT&T Inc", naics = 517210, state = "TX", city = "Dallas", cusip = "00206R102")]
matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear > 1996 & joinYear <= 2006, `:=` (gvkey = 62599, tic = "LU", conml = "Lucent Technologies", naics = 541512, state = "NJ", city = "New Providence", cusip = "549463107")]
matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear > 2006 & joinYear <= 2015, `:=` (gvkey = 101352, tic = "ALU", conml = "Alcatel-Lucent", naics = 334210, state = "", city = "Boulogne-Billancourt", cusip = "013904305")]
matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear > 2015, `:=` (gvkey = 23671, tic = "NOK", conml = "Nokia Corp", naics = 334220, state = "", city = "Espoo", cusip = "654902204")]

matched[ name == "alcatel" , gvkey := 101352]

matched[ name == "compaq" & joinYear <= 2001, `:=` (gvkey = 3282, tic = "CPQ.2", conml = "Compaq Computer Corp", naics = 334111, state = "TX", city = "Houston", cusip = "204493100")]

matched[ name == "appnexus" & joinYear <= 2018, gvkey := NA]

matched[ name == "netscape" & joinYear <= 1997, gvkey := 61143]

# For some reason, amd was getting matched to something totally wrong...
matched[ name == "amd", gvkey := 1161]

matched[ name == "covidien" & joinYear < 2015 , gvkey := 177264]

matched[ name == "lsi logic" & joinYear < 2014, gvkey := 60914]

matched[ name == "network associates", gvkey := 25783]

matched[ name == "hughes network systems", gvkey := 11206]

matched[ name == "soasta", gvkey := NA]

matched[ name == "storagetek" & joinYear <= 2004, gvkey := NA ]
matched[ name == "storagetek" & joinYear > 2005 & joinYear <= 2009, gvkey := 12136] # acquisition by Sun
matched[ name == "storagetek" & joinYear > 2009, gvkey := 12142] # acquisition by Oracle

matched[ name == "tumblr" & joinYear < 2014, gvkey := NA]
matched[ name == "tumblr" & joinYear >=  2014, gvkey := 62634]  # Acquisition by Yahoo
matched[ name == "tumblr" & joinYear >=  2018, gvkey := 2136]  # Acquisition by Verizon

matched[ name == "dow jones" & joinYear <= 2007, gvkey := 4062] # Pre acquisition by News Corp

matched[ name == "endeca" & joinYear <= 2011, gvkey := NA]  # Private before acquisition by Oracle

matched[ name == "homeaway.com" & joinYear >= 2006 & joinYear <= 2015, gvkey := 186714] # HomeAway.com was public before being acquired by Expedia

matched[ name == "huffington post" & joinYear <= 2011, gvkey := NA] # Huffington post was private before being acquired by AOL

matched[ name == "the active network" & joinYear <= 2013, gvkey := 160281] # Before being acquired, it was public

matched[ name == "websidestory" & joinYear <= 2008, gvkey := 140050] # Publicly listed 
matched[ name == "websidestory" & joinYear > 2008 & joinYear <= 2010, gvkey := 174871] # Bought by Omniture
matched[ name == "websidestory" & joinYear > 2010, gvkey := 12540] # Bought by Adobe

matched[ name == "yousendit", gvkey := NA]   # Not acquired until 2018, so null for me

matched[ name == "accelops" & joinYear <= 2018, gvkey := NA]  # Private 

matched[ name == "airclic" & joinYear <= 2016, gvkey := NA] # Private

matched[ name == "apollo group" & joinYear <= 2017, gvkey := 31122]  # Apollo Education Group before being acuqired by Apollo Group

matched[ name == "arbor networks" & joinYear <= 2011, gvkey := NA] # Private
matched[ name == "arbor networks" & joinYear > 2011 & joinYear <= 2016, gvkey := 3735]  # Owned by Danaher Corporation

matched[ name == "aster data systems" & joinYear <= 2012, gvkey := NA]  #Private before acquisition

matched[ name == "bleacher report" & joinYear <= 2013, gvkey := NA]  #Private before acquisition

matched[ name == "business objects" & joinYear <= 2008, gvkey := NA]  #Private before acquisition

matched[ name == "emptoris" & joinYear <= 2013, gvkey := NA]  #Private before acquisition

matched[ name == "goldengate software" & joinYear <= 2010, gvkey := NA]  #Private before acquisition

matched[ name == "hulu" & joinYear <= 2018, gvkey := NA] #private before disney
matched[ name == "hulu" & joinYear > 2018, gvkey := 3980]  # Then disney

matched[ name == "ims health" & joinYear <= 2016 , gvkey := 63800]   # IMS health before IQVIA merger

matched[ name == "janrain" & joinYear <= 2019, gvkey := NA]  # Private before acquisition by Akamai

matched[ name == "livingsocial" & joinYear <= 2017, gkvey := NA]  # Private before acquisition by Groupon

matched[ name == "redbeacon" & joinYear <= 2012, gkvey := NA]  # Private before acquisition by Home Depot

matched[ name == "skype" & joinYear <= 2011, gkvey := NA]  # Private before acquisition by Microsoft

matched[ name == "upromise" & joinYear <= 2006, gkvey := NA]  # Private before acquisition by Sallie Mae

matched[ name == "veritas" & joinYear <= 2008, gkvey := NA]  # Private before acquisition by Pepperball

matched[ name == "zulily" & joinYear <= 2008, gkvey := NA]  # Private before acquisition by Pepperball








matched[ , count := NULL]
matched[ , globCount := NULL]

setkey(EntitiesPrevEmployers,PreviousEmployer,joinYear)
setkey(matched,name,joinYear)


parentsSpinouts <- matched[EntitiesPrevEmployers]

parentsSpinouts <- parentsSpinouts[!is.na(gvkey)]

temp <- parentsSpinouts[globCount >= 10]

#temp <- parentsSpinouts

fwrite(temp,"data/parentsSpinouts.csv")









