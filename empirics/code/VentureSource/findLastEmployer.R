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
             measure.vars = c("Company1","Position1","Company2","Position2","Company3","Position3","Company4","Position4","Company5","Position5")) 

data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5" , valueCLEAN := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",value), by = value]
data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5"  , valueCLEAN := gsub("[.]$","",valueCLEAN), by = valueCLEAN]
data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5"  , valueCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",valueCLEAN), by = valueCLEAN]
data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5"  , valueCLEAN := gsub("[ ]?[(].*[)]$","",valueCLEAN), by = valueCLEAN]

data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5"  , EntityNameCLEAN := gsub("[.]$","",EntityName), by = EntityName]
data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5"  , EntityNameCLEAN := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",EntityNameCLEAN), by = EntityNameCLEAN]
data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5"  , EntityNameCLEAN := gsub("[ ]?[(].*[)]$","",EntityNameCLEAN), by = EntityNameCLEAN]

data[variable == "Position1" | variable == "Position2" | variable == "Position3" | variable == "Position4" | variable == "Position5" & value == "Chief Technical Officer", valueCLEAN := "CTO"]

data <- data[order(EntityID,FirstName,LastName)]

positionCounts <- data[variable == "Position1" | variable == "Position2" | variable == "Position3" | variable == "Position4" | variable == "Position5", .N, by = "value"]
employerCounts <- data[variable == "Company1" | variable == "Company2" | variable == "Company3" | variable == "Company4" | variable == "Company5", .N, by = "value"]



temp1 <- data[EntityName != value]
data <- data[EntityNameCLEAN != valueCLEAN]

setnames(data,"value","PreviousEmployer")

data[TitleCode == "CEO" | TitleCode == "CTO" | TitleCode == "CCEO" | TitleCode == "PCEO" | Founder == 1, founder2 := 1]
data[ is.na(founder2), founder2 := 0]

data <- data[  founder2 == 1]

temp <- data[data[ , .I[1], by = c("EntityID","Title","FirstName","LastName")]$V1]

temp[ , variable := NULL]

fwrite(temp,"data/VentureSource/EntitiesPrevEmployers.csv")





