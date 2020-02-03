

EntitiesBios <- fread("data/VentureSource/EntitiesBios.csv")
Deals <- unique(fread("raw/VentureSource/01Deals.csv")[ , .(EntityID,EntityName, FoundingDate = StartDate)])

setkey(Deals,EntityID)
setkey(EntitiesBios,EntityID)

EntitiesBios <- Deals[EntitiesBios]

# Save data

fwrite(EntitiesBios,"data/VentureSource/EntitiesBiosNamesFoundingDates.csv")

# Clean up

rm(Deals,EntitiesBios)
