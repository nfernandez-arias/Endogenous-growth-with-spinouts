rm( list = ls())

Deals <- fread("raw/VentureSource/01Deals.csv")[ , .(EntityID,StartDate,IndustryCodeDesc,SubcodeDesc)]

EntitiesBios <- fread("data/VentureSource/EntitiesBios.csv")

Deals <- unique(Deals, by = "EntityID")

setkey(EntitiesBios,EntityID)
setkey(Deals,EntityID)

merged <- EntitiesBios[Deals]

# Do some final cleaning: when there is no Subcode, put the Higher level code as the subcode
merged[SubcodeDesc == "", SubcodeDesc := IndustryCodeDesc]

## Need to clean - this does not have to do with industries but with founding years...

#merged[ , foundingYear1 := pmin(na.omit(year(ymd(JoinDate))),na.omit(year(ymd(StartDate)))), by = EntityID]
merged[JoinDate == "", JoinDate := NA]
merged[StartDate == "", StartDate := NA]
merged[!is.na(JoinDate) | !is.na(StartDate), startDateInfoFlag := 1] 
merged[is.na(startDateInfoFlag), startDateInfoFlag := 0 ]
merged[ , startDateInfoCount := sum(startDateInfoFlag), by = EntityID]

# For Entities with no founder start / join date info, use founding year
merged[startDateInfoCount == 0, foundingYear := year(ymd(i.StartDate))]

# For other Entities, use first start / join date of a founder as founding year of the company
merged[startDateInfoCount > 0, foundingYear := min(pmin(na.omit(year(ymd(StartDate))), na.omit(year(ymd(JoinDate))))), by = EntityID]

merged[ , startDateInfoFlag := NULL]
merged[ , startDateInfoCount := NULL]

fwrite(merged,"data/VentureSource/EntitiesBiosIndustries.csv")
