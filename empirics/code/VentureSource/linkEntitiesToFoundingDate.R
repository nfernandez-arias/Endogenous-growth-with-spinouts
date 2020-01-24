



Deals <- fread("raw/VentureSource/01Deals.csv")[ , .(EntityID,EntityName,StartDate,IndustryCodeDesc,SubcodeDesc)]

setnames(Deals,"StartDate","FoundingDate")

EntitiesBios <- fread("data/VentureSource/EntitiesBios.csv")

Deals <- unique(Deals, by = "EntityID")

setkey(EntitiesBios,EntityID)
setkey(Deals,EntityID)

merged <- Deals[EntitiesBios]
#merged <- EntitiesBios[Deals]

# Do some final cleaning: when there is no Subcode, put the Higher level code as the subcode
merged[SubcodeDesc == "", SubcodeDesc := IndustryCodeDesc]

## Need to clean - this does not have to do with industries but with founding years...

#merged[ , foundingYear1 := pmin(na.omit(year(ymd(JoinDate))),na.omit(year(ymd(StartDate)))), by = EntityID]

merged[, JoinYear := year(ymd(JoinDate))]
merged[, StartYear := year(ymd(StartDate))]
merged[!is.na(JoinYear) | !is.na(StartYear), startDateInfoFlag := 1] 
merged[is.na(startDateInfoFlag), startDateInfoFlag := 0 ]
merged[ , startDateInfoCount := sum(startDateInfoFlag), by = EntityID]

# For Entities with no founder start / join date info, use founding year
merged[startDateInfoCount == 0, foundingYear := year(ymd(FoundingDate))]

# For other Entities, use first start / join date of a founder as founding year of the company
merged[startDateInfoCount > 0, foundingYear := pmin(min(na.omit(JoinYear),na.omit(StartYear))), by = EntityID]

merged[ , startDateInfoFlag := NULL]
merged[ , startDateInfoCount := NULL]

fwrite(merged,"data/VentureSource/EntitiesBiosIndustries.csv")

# Clean up

rm(Deals,EntitiesBios,merged)
