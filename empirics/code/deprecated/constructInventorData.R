library(data.table)
library(readstata13)

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/code")

# Load data

inventors <- fread("../raw/patentsview/inventor.tsv", quote = "")
setnames(inventors,c("name_first","name_last"),c("name_first_inventor","name_last_inventor"))
inventorsPatents <- fread("../raw/patentsview/patent_inventor.tsv")
patentsAssignees <- fread("../raw/patentsview/patent_assignee.tsv")
assignees <- fread("../raw/patentsview/assignee.tsv", quote = "")
setnames(assignees,c("name_first","name_last"),c("name_first_assignee","name_last_assignee"))
inventorLocations <- fread("../raw/patentsview/location_inventor.tsv")
locations <- fread("../raw/patentsview/location.tsv", quote = "")
assigneeLocations <- fread("../raw/patentsview/location_assignee.tsv")

# Merge

setkey(patentsAssignees,assignee_id)
setkey(assignees,id)
data <- patentsAssignees[assignees]

setkey(data,patent_id)
setkey(inventorsPatents,patent_id)
data <- data[inventorsPatents]

setkey(data,inventor_id)
setkey(inventors,id)
data <- data[inventors]

# Clean up
rm(list = c("inventors","inventorsPatents","assignees","patentsAssignees"))
   
# Merge some more
setkey(inventorLocations,inventor_id)
data <- data[inventorLocations]
rm(inventorLocations)
setnames(data,"location_id","location_id_inventor")

# Merge some more
setkey(data,assignee_id)
setkey(assigneeLocations,assignee_id)

patents <- fread("../raw/patentsview/patent.tsv",quote = "")


#data <- data[assigneeLocations,allow.cartesian=TRUE]

data <- merge(data,assigneeLocations,by.x = "assignee_id",by.y = "assignee_id")
data <- merge(data,locations,by.x = "location_id",by.y = "id")
data[ , c("location_id","assignee_id") := NULL]


fwrite(data,"../data/patentsview/patentsInventorsAssignees_patentsview.csv")


