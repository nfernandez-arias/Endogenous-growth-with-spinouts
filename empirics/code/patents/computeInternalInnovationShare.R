

##
#
# THis script computes the internal innovation share
# defined as the fraction of patents that are to the 
# firm's own patents
#
#

rm(list = ls())

patentsPdpass <- fread("raw/nber uspto/pat76_06_assg.csv")[country == "US"][ , .(patent,pdpass,appyear,gyear)]

citations <- fread("raw/nber uspto/cite76_06.csv")

# First, merge in information on citing patents
setkey(patentsPdpass,patent)

setkey(citations,citing)
citations <- patentsPdpass[citations]
setnames(citations,"patent","citing")
setnames(citations,"pdpass","citingPdpass")
setnames(citations,"appyear","citingAppyear")
setnames(citations,"gyear","citingGyear")

setkey(citations,cited)
citations <- patentsPdpass[citations]
setnames(citations,"patent","cited")
setnames(citations,"pdpass","citedPdpass")
setnames(citations,"appyear","citedAppyear")
setnames(citations,"gyear","citedGyear")

patent_internalCiteRatios <- citations[ , .(ratio = nrow(.SD[citedPdpass == citingPdpass]) / .N) , by = citing]

fwrite(patent_internalCiteRatios,"data/nber uspto/patentInternalCitationRatios.csv")

rm(citations)

#patent_internalCiteRatios <- fread("data/nber uspto/patentInternalCitationRatios.csv")

wtd.hist <- weights::wtd.hist

patentsPdpass <- fread("data/nber uspto/pat76_06_assg.csv")[country == "US"][ , .(patent,allcites,appyear,gyear)]

setkey(patentsPdpass,patent)
setkey(patent_internalCiteRatios,citing)

patentsPdpass <- patent_internalCiteRatios[patentsPdpass]

patentsPdpass <- patentsPdpass[appyear >= 1986]

wtd.hist(patentsPdpass$ratio, weight = patentsPdpass$allcites,  breaks= 100)
