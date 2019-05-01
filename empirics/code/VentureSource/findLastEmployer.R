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

data <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/data/VentureSource/EntitiesBios.csv")

data <- melt(data, id.vars = c("EntityID","EntityName","Founder","Title","TitleCode","FirstName","LastName"), 
             measure.vars = c("Company1","Company2","Company3","Company4","Company5"))

data <- data[order(EntityID,FirstName,LastName)]

data <- data[EntityName != value]

temp <- data[data[ , .I[1], by = c("EntityID","Title","FirstName","LastName")]$V1]

setnames(temp,"value","PreviousEmployer")

temp[ , variable := NULL]

temp <- temp[ TitleCode != "BD"]
temp <- temp[ TitleCode != "BDII"]
temp <- temp[ TitleCode != "BDVI"]
temp <- temp[ TitleCode != "CBD"]

fwrite(temp,"~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/data/VentureSource/EntitiesPrevEmployers.csv")





