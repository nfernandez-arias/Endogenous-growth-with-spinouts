#
## This script attempts to match to Venture Source
#
#
#
#




rm(list = ls())

entities <- unique(fread("raw/VentureSource/01Deals.csv"), by = "EntityID")[ , .(EntityID,EntityName)]
#assignees <- fread("raw/patentsview/assignee.tsv")
assignees <- fread("data/nber uspto/assignee.csv")


# Do some regex cleaning of names -- remove Corp, etc. like in other algorithm
assignees[ , standard_name := tolower(standard_name)]
assignees[ , standard_name := gsub("[.]$","",standard_name)]
assignees[ , standard_name := gsub("( inc| corp| llc| | l.l.c| ltd| co| lp)$","",standard_name)]
assignees[ , standard_name := gsub("[,]$","",standard_name)]
assignees[ , standard_name := gsub("[.]$","",standard_name)]
assignees[ , standard_name := gsub("( inc| corp| llc| l.l.c| ltd| co| lp)$","",standard_name)]

entities[ , EntityName := tolower(EntityName)]
entities[ , EntityName := gsub("[.]$","",EntityName)]
entities[ , EntityName := gsub("( inc| corp| llc| | l.l.c| ltd| co| lp)$","",EntityName)]
entities[ , EntityName := gsub("[,]$","",EntityName)]
entities[ , EntityName := gsub("[.]$","",EntityName)]
entities[ , EntityName := gsub("( inc| corp| llc| l.l.c| ltd| co| lp)$","",EntityName)]

setkey(assignees,standard_name)
setkey(entities,EntityName)

assignees <- entities[assignees]

# Construct map from VentureSource entities to Pdpass
entitiesPdpass <- assignees[!is.na(EntityID)][ , .(EntityID,pdpass)]

fwrite(entitiesPdpass,"data/entitiesPdpass.csv")




### Attempt to match using inventor data
rm(list = ls())
patentsInventors <- fread("data/patentsview/inventorsPatents.csv")[ , .(patent_id,name_first,name_last,city,state,country)]


entitiesBios <- fread("data/VentureSource/EntitiesBios.csv")[ , .(EntityID,FirstName,LastName)]






