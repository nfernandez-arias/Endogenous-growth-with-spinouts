
rm(list = ls())

library(data.table)
library(lubridate)

overview <- fread("raw/VentureSource/PU_Overview.csv")

deals <- fread("raw/VentureSource/01Deals.csv")

startups <- unique(overview, by = "EntityID")

startups[, StartYear := year(mdy(StartDate))]




