#------------------------------------------------#
#
# File name: findLastEmployer.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This program analyzes EntitiesBios.csv 
# to determine the last employer of each employee.
# 
# 
#------------------------------------------------#

rm(list = ls())

data <- fread("data/VentureSource/EntitiesBiosIndustries.csv")

data <- melt(data, id.vars = c("EntityID","EntityName","JoinDate","StartDate","foundingYear","Founder","Title","TitleCode","FirstName","LastName","IndustryCodeDesc","SubcodeDesc"), 
             measure.vars = c("Company1","Company2","Company3","Company4","Company5"))

data[ , valueCLEAN := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",value), by = value]
data[ , valueCLEAN := gsub("[.]$","",valueCLEAN), by = valueCLEAN]
data[ , valueCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",valueCLEAN), by = valueCLEAN]
data[ , valueCLEAN := gsub("[ ]?[(].*[)]$","",valueCLEAN), by = valueCLEAN]

data[ , EntityNameCLEAN := gsub("[.]$","",EntityName), by = EntityName]
data[ , EntityNameCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",EntityNameCLEAN), by = EntityNameCLEAN]
data[ , EntityNameCLEAN := gsub("[ ]?[(].*[)]$","",EntityNameCLEAN), by = EntityNameCLEAN]

data <- data[order(EntityID,FirstName,LastName)]

temp1 <- data[EntityName != value]
data <- data[EntityNameCLEAN != valueCLEAN]

setnames(data,"value","PreviousEmployer")

data <- data[TitleCode == "CEO" | TitleCode == "CTO" | TitleCode == "CCEO" | TitleCode == "PCEO" | Founder == 1]

temp <- data[data[ , .I[1], by = c("EntityID","Title","FirstName","LastName")]$V1]

temp[ , variable := NULL]

fwrite(temp,"data/VentureSource/EntitiesPrevEmployers.csv")





