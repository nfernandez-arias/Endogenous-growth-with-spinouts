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
#
# It loads in the firmsSegments.csv file constructed in compustat/matchCompustatFirmsToSubsidiaries.R
#
# It proceeds as follows:
#
# (1) Manually standardize the names of some important companies in Compustat (e.g. IBM, Hewlett-Packard)
# (2) Use RegEx to standardize names of all companies: removing , Inc. , Corp. , spaces, artefacts from the encoding (probably exists a better way)
# and finally, moving to lower case.
#
# (3) Perform analogous steps on the EntitiesPrevEmployers.csv file constructed in VentureSource/findLastEmployer.R file
#     (this file )
# (4) Merge datasets: 
#     (a) First, find matches of company names in Compustat to previous employers in Venture Source
#     (b) Next, find matches of subsidiary names in Compustat to previos employers in Venture Source
#     (c) Finally, find matches previous employers in Venture Source using AltDG, and match these entities to Compustat
#         using their ticker symbol. This last step then requires manual verification, since it usually is matching
#         subsidiaries, which change company ownership. E.g., it often will match a startup to the firm that acquries it,
#         but the relevant employee worked at the startup before it was acquired by the firm. 
#------------------------------------------------#


compustatFirmsSegments <- fread("data/compustat/firmsSegments.csv")
compustatFirmsSegments[tic == "IBM", conml := "IBM"]
compustatFirmsSegments[tic == "GS", conml := "Goldman Sachs"] 
compustatFirmsSegments[tic == "HPQ", conml := "Hewlett-Packard"]
compustatFirmsSegments[snms == "HP", snms := ""] 
compustatFirmsSegments <- compustatFirmsSegments[ , .(gvkey,state,city,cusip,naics,NAICSS1,NAICSS2,dataYear,conml,snms,tic)]
compustatFirmsSegments[ , conml := gsub("[.]$","",conml)]
compustatFirmsSegments[ , conml := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",conml)]
compustatFirmsSegments[ , conml := tolower(conml)]

EntitiesPrevEmployers <- fread("data/VentureSource/EntitiesPrevEmployers.csv")[!is.na(FoundingDate)][year(ymd(FoundingDate)) >= 1986]
EntitiesPrevEmployers[ , foundingYear := as.integer(year(ymd(FoundingDate)))]
EntitiesPrevEmployers[ , joinYear := as.integer(year(ymd(JoinDate)))]

# As before, if missing info on joinYear, treat joinYear as foundingYear 
EntitiesPrevEmployers[ is.na(joinYear) , `:=` (joinYear = foundingYear, joinYearImputed = 1)]
EntitiesPrevEmployers[ is.na(joinYearImputed), joinYearImputed := 0]  


## Prepare data
EntitiesPrevEmployers <- EntitiesPrevEmployers[, .(EntityID,EntityName,foundingYear,FirstName,LastName,joinYear,joinYearImputed,Title,TitleCode,Employer,Position,hasBio)]
EntitiesPrevEmployers[ TitleCode %in% founderTitles, founder2 := 1]
EntitiesPrevEmployers[ is.na(founder2), founder2 := 0]
EntitiesPrevEmployers[ Employer == "Cisco", Employer := "Cisco Systems"]
EntitiesPrevEmployers[ Employer == "Amazon", Employer := "Amazon.com"]
EntitiesPrevEmployers[ Employer == "Yahoo" | Employer == "Yahoo!", Employer :=  "Verizon"]
EntitiesPrevEmployers[ , Employer := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",Employer)]
EntitiesPrevEmployers[ , Employer := gsub("[.]$","",Employer)]
EntitiesPrevEmployers[ , Employer := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",Employer)]
EntitiesPrevEmployers[ , Employer := gsub("[ ]?[(].*[)]$","",Employer)]
EntitiesPrevEmployers[ , Employer := gsub("^Google.*$","Google",Employer)]
EntitiesPrevEmployers[ , EmployerCase := Employer]
EntitiesPrevEmployers[ , Employer := tolower(Employer)]

#------------------------------#
# Initial merge, using standardized firm names
#------------------------------#

firms <- unique(compustatFirmsSegments,by = "gvkey")[ , .(gvkey,conml,tic,cusip,state,city,naics) ]
EntitiesPrevEmployers[ , count := .N, by = c("Employer","joinYear")]
EntitiesPrevEmployers[ , globCount := .N, by = Employer]
EntitiesPrevEmployers[ , founder2Count := sum(founder2), by = Employer]
prevEmployers <- unique(EntitiesPrevEmployers, by = c("Employer","joinYear"))[ , .(Employer,joinYear,count,globCount,founder2Count)]

setkey(prevEmployers,Employer)
setkey(firms,conml)

firmsPrevEmployers <- firms[,.(gvkey,conml)][prevEmployers]

# Construct subsample of matched and unmatched startup-founder observations
matched <- firmsPrevEmployers[ !is.na(gvkey)][ , .(gvkey,conml,joinYear,count,globCount,founder2Count)]
unmatched <- firmsPrevEmployers[ is.na(gvkey)][ , .(conml,joinYear,count,globCount,founder2Count)]

matched[ , source := "regex"]

#------------------------------#
## Secondary merge using compustat segments data
#------------------------------#

segments <- unique(compustatFirmsSegments[snms != ""], by = c("snms"))[ , .(gvkey,snms)]

segments[ , snms := tolower(snms)]

setkey(segments,snms)
#setkey(unmatched,conml)

unmatched <- segments[unmatched]

# Construct dataset of startup-founder pairs *not* matched to firms, which are matched / not matched to segments of parent firms, 
# as per the Compustat business segment database

matchedSegments <- unmatched[!is.na(gvkey)]
unmatched <- unmatched[is.na(gvkey)][ , .(snms,joinYear,count,globCount,founder2Count)]

matchedSegments[ , source := "compustat segments"]

#------------------------------#
# Final merge using results of AltDG
#------------------------------#

firmsTickers <- fread("data/firmsTickersAltDG.csv")
firmsTickers[, query := tolower(query)]
firmsTickers <- unique(firmsTickers, by = "query")

setkey(firmsTickers,query)

unmatched <- firmsTickers[unmatched]

matchedQueries <- unmatched[!is.na(Ticker)]
unmatched <- unmatched[is.na(Ticker)][ , .(query,joinYear,count,globCount,founder2Count)]

matchedQueries[ , source := "altdg"]

# Merge matched queries to firms via ticker symbol
setkey(matchedQueries,Ticker)
setkey(firms,tic)

matchedQueries <- firms[matchedQueries][, .(gvkey,tic,query,count,globCount,founder2Count,joinYear,source)]

unmatchedQueries <- matchedQueries[is.na(gvkey)]
matchedQueries <- matchedQueries[ !is.na(gvkey)]

## Change names to query

setnames(matched,"conml","name")
setnames(matchedSegments,"snms","name")
setnames(matchedQueries,"query","name")
setnames(unmatchedQueries,"query","name")

matched <- rbind(matched,matchedSegments,matchedQueries,unmatchedQueries[tic == "NOK"], fill = TRUE)
#matched <- rbind(matched,matchedSegments)
### Now match back to EntitiesPrevEmployers

setkey(matched,gvkey)
setkey(firms,gvkey)

matched <- firms[matched]

### Check matches for accuracy


# First build matches that are not due to regex
matchedDist <- matched[ source != "regex"]

# Remove matches where one string is a subset of the other
matchedDist <- matchedDist[is.na(gvkey) | (mapply(grepl,conml,name) == FALSE & mapply(grepl,name,conml) == FALSE)]

# Next order by largest count
matchedDist <- matchedDist[order(-founder2Count,name,joinYear)]

# Finally, get rid of copies
matchedDistUnique <- unique(matchedDist, by = c("conml","name"))[ , .(conml,name,globCount,founder2Count,source)]

### Make some ad-hoc corrections for major M&A
## Basically AltDG tells me if something is currently a subsidiary,
# which is helpful for understanding entire history of ownership, but 
# really I need to go back and manually ensure that the data is correct.
# Still, this is MUCH easier than just going with the initial list of names.


# Still need to figure out what is going on with AOL / Time Warner/ Verizon / Netscape


matched[ name == "merrill lynch" & joinYear <= 2008 + mergerThreshold, `:=` (gvkey = 7267, tic = "BAC2", conml = "Merrill Lynch & Co Inc", naics = 523110, state = "NY", city = "New York", cusip = "59098Z002")]

matched[ name == "ca technologies" & joinYear <= 2018 + mergerThreshold, `:=` (gvkey = 3310, tic = "CA", conml = "CA Inc", naics = 511210, state = "NY", city = "New York", cusip = "12673P105")]

matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear <= 1996 + mergerThreshold, `:=` (gvkey = 9899, tic = "T", conml = "AT&T Inc", naics = 517210, state = "TX", city = "Dallas", cusip = "00206R102")]
matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear > 1996  + mergerThreshold & joinYear <= 2006 + mergerThreshold, `:=` (gvkey = 62599, tic = "LU", conml = "Lucent Technologies", naics = 541512, state = "NJ", city = "New Providence", cusip = "549463107")]
#matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear > 2006 & joinYear <= 2015, `:=` (gvkey = 101352, tic = "ALU", conml = "Alcatel-Lucent", naics = 334210, state = "", city = "Boulogne-Billancourt", cusip = "013904305")]
#matched[ name == "bell labs" | name == "bell laboratories" | name == "at&t bell laboratories" & joinYear > 2015, `:=` (gvkey = 23671, tic = "NOK", conml = "Nokia Corp", naics = 334220, state = "", city = "Espoo", cusip = "654902204")]

matched[ name == "myspace" & joinYear > 2008 + mergerThreshold & joinYear <= 2016 + mergerThreshold, gvkey := 18043]  # Owned by Newscorp during this time

#matched[ name == "alcatel" , gvkey := 101352] 

matched[ name == "compaq" & joinYear <= 2002 + mergerThreshold, `:=` (gvkey = 3282, tic = "CPQ.2", conml = "Compaq Computer Corp", naics = 334111, state = "TX", city = "Houston", cusip = "204493100")] # acquired by HP

matched[ name == "appnexus" & joinYear <= 2018 + mergerThreshold, gvkey := NA] # acquired by AT&T

matched[ name == "netscape" & joinYear <= 1999 + mergerThreshold, gvkey := 61143] # acquired by AOL

# For some reason, amd was getting matched to something totally wrong...
matched[ name == "amd", gvkey := 1161]

#matched[ name == "covidien" & joinYear <= 2015 + mergerThreshold , gvkey := 177264] #Medtronic acquires

matched[ name == "lsi logic" & joinYear <= 2014 + mergerThreshold, gvkey := 60914] # Prior to acquisition, was publicly traded.

matched[ name == "network associates", gvkey := 25783] # is Mcafee

matched[ name == "hughes network systems" & joinYear <= 2004 + mergerThreshold, gvkey := NA]            
matched[ name == "hughes network systems" & joinYear > 2004 + mergerThreshold & joinYear <= 2007 + mergerThreshold, gvkey := 18043] # Owned by NewsCorp
matched[ name == "hughes network systems" & joinYear > 2007 + mergerThreshold & joinYear <= 2011 + mergerThreshold, gvkey := 166208] # Separate private company

matched[ name == "soasta", gvkey := NA]

matched[ name == "storagetek" & joinYear <= 2005 + mergerThreshold, gvkey := NA ]
matched[ name == "storagetek" & joinYear > 2005 + mergerThreshold & joinYear <= 2009 + mergerThreshold, gvkey := 12136] # acquisition by Sun
matched[ name == "storagetek" & joinYear > 2009 + mergerThreshold, gvkey := 12142] # acquisition by Oracle

matched[ name == "tumblr" & joinYear <= 2013 + mergerThreshold, gvkey := NA]
matched[ name == "tumblr" & joinYear >  2013 + mergerThreshold, gvkey := 62634]  # Acquisition by Yahoo
matched[ name == "tumblr" & joinYear >  2017 + mergerThreshold, gvkey := 2136]  # Acquisition by Verizon

matched[ name == "dow jones" & joinYear <= 2007 + mergerThreshold, gvkey := 4062] # Pre acquisition by News Corp

matched[ name == "endeca" & joinYear <= 2011 + mergerThreshold, gvkey := NA]  # Private before acquisition by Oracle

matched[ name == "homeaway.com" & joinYear <= 2015 + mergerThreshold, gvkey := 186714] # HomeAway.com was public before being acquired by Expedia

matched[ name == "huffington post" & joinYear <= 2011 + mergerThreshold, gvkey := NA] # Huffington post was private before being acquired by AOL

matched[ name == "the active network" & joinYear > 2011 + mergerThreshold & joinYear <= 2013 + mergerThreshold, gvkey := 160281] # Before being acquired, it was public

matched[ name == "websidestory" & joinYear <= 2008, gvkey := 140050] # Publicly listed 
matched[ name == "websidestory" & joinYear > 2008 + mergerThreshold & joinYear <= 2010 + mergerThreshold, gvkey := 174871] # Bought by Omniture
matched[ name == "websidestory" & joinYear > 2010 + mergerThreshold, gvkey := 12540] # Bought by Adobe

matched[ name == "yousendit", gvkey := NA]   # Not acquired until 2018, so null for me

matched[ name == "accelops" & joinYear <= 2016 + mergerThreshold, gvkey := NA]  # Private 

matched[ name == "airclic" & joinYear <= 2014 + mergerThreshold, gvkey := NA] # Private

matched[ name == "apollo group" & joinYear <= 2017 + mergerThreshold, gvkey := 31122]  # Apollo Education Group before being acuqired by Apollo Group

matched[ name == "arbor networks" & joinYear <= 2011, gvkey := NA] # Private
matched[ name == "arbor networks" & joinYear > 2011 & joinYear <= 2016, gvkey := 3735]  # Owned by Danaher Corporation

matched[ name == "aster data systems" & joinYear <= 2012, gvkey := NA]  #Private before acquisition

matched[ name == "bleacher report" & joinYear <= 2013, gvkey := NA]  #Private before acquisition

matched[ name == "business objects" & joinYear <= 2008, gvkey := NA]  #Private before acquisition

matched[ name == "emptoris" & joinYear <= 2013, gvkey := NA]  #Private before acquisition

matched[ name == "goldengate software" & joinYear <= 2010, gvkey := NA]  #Private before acquisition

matched[ name == "hulu" & joinYear <= 2018, gvkey := NA] # private before disney
matched[ name == "hulu" & joinYear > 2018, gvkey := 3980]  # Then disney

matched[ name == "ims health" & joinYear <= 2016 , gvkey := 63800]   # IMS health before IQVIA merger

matched[ name == "janrain" & joinYear <= 2019, gvkey := NA]  # Private before acquisition by Akamai

matched[ name == "livingsocial" & joinYear <= 2017, gvkey := NA]  # Private before acquisition by Groupon

matched[ name == "redbeacon" & joinYear <= 2012, gvkey := NA]  # Private before acquisition by Home Depot

matched[ name == "skype" & joinYear <= 2011, gvkey := NA]  # Private before acquisition by Microsoft

matched[ name == "upromise" & joinYear <= 2006, gvkey := NA]  # Private before acquisition by Sallie Mae

matched[ name == "veritas" & joinYear <= 2008, gvkey := NA]  # Private before acquisition by Pepperball

matched[ name == "zulily" & joinYear <= 2008, gvkey := NA]  # Private before acquisition by Pepperball














matched[ , count := NULL]
matched[ , globCount := NULL]
matched[ , founder2Count := NULL]
# Merge with founder information using joinYear, because 
# matches of names to gvkey, in particular using AltDG, 
# can depend on the joinYear. See above.

setkey(EntitiesPrevEmployers,Employer,joinYear)
setkey(matched,name,joinYear)

parentsSpinouts <- matched[EntitiesPrevEmployers]

#------------------------------#
## Flag biographies as coming from public companies
# based on successful matchesa above
#------------------------------#

parentsSpinouts[ is.na(source), source := "unmatched"]
if (excludeAltDG == TRUE)
{
  parentsSpinouts[ source %in% c("altdg","unmatched") | hasBio == 0, fromPublic := as.integer(0)]
} else
{
  parentsSpinouts[ source %in% c("unmatched") | hasBio == 0 | source == "altdg" & founder2Count < minimumSpinoutsThreshold, fromPublic := as.integer(0)] 
}
parentsSpinouts[ is.na(fromPublic), fromPublic := as.integer(1)]

fwrite(parentsSpinouts,"data/parentsSpinouts.csv")
  
# Clean up
rm(matched,matchedDist,matchedQueries,matchedSegments,parentsSpinouts,
   prevEmployers,segments,unmatched,compustatFirmsSegments,
   EntitiesPrevEmployers,firms,firmsPrevEmployers,firmsTickers)









