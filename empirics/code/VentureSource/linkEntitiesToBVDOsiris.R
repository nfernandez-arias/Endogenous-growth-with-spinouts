#------------------------------------------------#
#
# File name: linkEntitiesToBVDOsiris.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script links EntityNames to the BVDOsiris database
# of private firms 
#------------------------------------------------#


setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

rm(list = ls())
library(data.table)

Osiris <- fread("data/BVD/bvdOsirisUnlisted.csv")
Osiris <- Osiris[ , NAME := gsub("[.]$","",NAME), by = OS_ID_NUMBER]
Osiris <- Osiris[ , NAME := gsub("( Inc| Corp| LLC| Ltd| Co| LP| L.P| CORPORATION| LIMITED PARTNERSHIP| COMPANY| OPERATING PARTNERSHIP)$","",NAME,ignore.case = TRUE), by = OS_ID_NUMBER]
Osiris <- Osiris[ , NAME := gsub("[,]$","",NAME), by = OS_ID_NUMBER]

Entities <- fread("data/VentureSource/EntityNames.csv")
Entities <- Entities[ , EntityName := gsub("[.]$","",EntityName), by = EntityID]
Entities <- Entities[ , EntityName := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",EntityName), by = EntityID]
Entities[ , EntityName := toupper(EntityName)]

setkey(Osiris,NAME)
setkey(Entities,EntityName)

temp <- Entities[Osiris]
