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

data <- data[order(EntityID,FirstName,LastName)]

data <- data[EntityName != value]

setnames(data,"value","PreviousEmployer")

data <- data[TitleCode == "CEO" | TitleCode == "CTO" | TitleCode == "CCEO" | TitleCode == "PCEO" | Founder == 1]

temp <- data[data[ , .I[1], by = c("EntityID","Title","FirstName","LastName")]$V1]

temp[ , variable := NULL]

fwrite(temp,"data/VentureSource/EntitiesPrevEmployers.csv")





