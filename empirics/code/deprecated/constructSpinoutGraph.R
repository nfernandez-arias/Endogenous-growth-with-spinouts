library(data.table)
library(readstata13)

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/code")

#patents <- fread("../raw/patentsview/patent.tsv",quote = "")

applications <- fread("../raw/patentsview/application.tsv")

inventors <- fread("../raw/patentsview/inventor.tsv",quote = "")

inventorsPatents <- fread("../raw/patentsview/patent_inventor.tsv")

# Merge inventorsPatents with inventors
setkey(inventors,id)
setkey(inventorsPatents,inventor_id)
data <- inventors[inventorsPatents]

# Merge with applications data
setkey(applications,patent_id)
setkey(data,patent_id)
data <- data[applications]
data[, c("id","patent_id","i.id"):= NULL]
data[, number := as.numeric(number)]

rm(list = c("inventors","inventorsPatents","applications"))
gc()

## Load in data from NBER USPTO data

patentsAssignees <- fread("../data/nber uspto/patassg.csv")
patentsAssignees <- patentsAssignees[ptype == 0]
#patentsAssignees <- patentsAssignees[,c("appyear","patent","pdpass","uspto_assignee")]

# Merge
setkey(patentsAssignees,patnum)
setkey(data,number)

temp <- merge(data,patentsAssignees,by.x = "number", by.y = "patnum", all = TRUE)



