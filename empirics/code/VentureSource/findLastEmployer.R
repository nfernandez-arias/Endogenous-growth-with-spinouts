#------------------------------------------------#
#
# File name: findLastEmployer.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This program analyzes EntitiesBiosIndustries.csv 
# to determine the last employer of each employee.
# 
# 
#------------------------------------------------#

data <- fread("data/VentureSource/EntitiesBiosNamesFoundingDates.csv")

positions <- c("Position1","Position2","Position3","Position4","Position5")
companies <- c("Company1","Company2","Company3","Company4","Company5")

data <- melt(data, id.vars = c("EntityID","EntityName","JoinDate","FoundingDate","Founder","Title","TitleCode","FirstName","LastName","hasBio",positions), 
             measure.vars = companies) 

for (i in 1:5)
{
  companyTemp <- paste("Company",i,sep = "")
  positionTemp <- paste("Position",i,sep = "")
  
  data[ variable == companyTemp , Position := get(positionTemp)]
  data[ , (positionTemp) := NULL]
}


#------------------------------#
# Clean up names of Previous Employers and Entities, 
# so that we can get rid of obs where they are equal 
# and look further back into employment history for those founders
#------------------------------#

setnames(data,"value","Employer")

data[ , Employer := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",Employer)]
data[ , Employer := gsub("[.]$","",Employer)]
data[ , Employer := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",Employer)]
data[ , Employer := gsub("[ ]?[(].*[)]$","",Employer)]

data[ , EntityName := gsub("[.]$","",EntityName)]
data[ , EntityName := gsub("( Inc| Corp| LLC| Ltd| Co| LP)$","",EntityName)]
data[ , EntityName := gsub("[ ]?[(].*[)]$","",EntityName)]

data[ Position == "Chief Technical Officer", Position := "CTO"]

data <- data[order(EntityID,FirstName,LastName)]

# Get rid of previous employers equal to the startup. To do this,
# get rid of observations where either string is a subset of the other (to account for different naming conventions)

data <- data[ hasBio == 0 | (mapply(grepl,tolower(Employer),tolower(EntityName), MoreArgs = list(fixed = TRUE)) == FALSE & 
                mapply(grepl,tolower(EntityName),tolower(Employer), MoreArgs = list(fixed = TRUE)) == FALSE)]


data[ Employer == "Individual Investors", Employer := "Individual Investor"]

# Get the first record for each person-EntityID pair. Given the previous line of code, this should 
# have info on the most recent job. 
mostRecentEmployers <- data[data[ , .I[1], by = c("EntityID","Title","FirstName","LastName")]$V1]

mostRecentEmployers[ , variable := NULL]

#------------------------------#
# Save data
#------------------------------#

fwrite(mostRecentEmployers,"data/VentureSource/EntitiesPrevEmployers.csv")

# Clean up
rm(data,mostRecentEmployers)





