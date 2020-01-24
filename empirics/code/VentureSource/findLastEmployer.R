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

data <- fread("data/VentureSource/EntitiesBiosIndustries.csv")

positions <- c("Position1","Position2","Position3","Position4","Position5")
companies <- c("Company1","Company2","Company3","Company4","Company5")

data <- melt(data, id.vars = c("EntityID","EntityName","JoinDate","StartDate","foundingYear","Founder","Title","TitleCode","FirstName","LastName","IndustryCodeDesc","SubcodeDesc",positions), 
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

data[ , Employer := gsub("( )?(_x000D_)?(\n)?( )?(_x000D_)?(\n)?( )?_x000D_\n$","",value)]
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

data <- data[ mapply(grepl,tolower(Employer),tolower(EntityName), MoreArgs = list(fixed = TRUE)) == FALSE & 
                mapply(grepl,tolower(EntityName),tolower(Employer), MoreArgs = list(fixed = TRUE)) == FALSE]
  
#------------------------------#
# Which early employees of startup are to be counted as "Founders" for my analysis?
#
# Those with certain titles (see main.R) and those who joined the startup within the founderThreshold (also see main.R)
# 
# For those observations without information on founder's join date, just include all founders. Better than dropping...
# Gompers et al. say that they go one by one to get data on this, but this infeasible at this point, given the size of the dataset.
#------------------------------#

data[ TitleCode %in% founderTitles & (is.na(JoinDate) | year(ymd(JoinDate)) - foundingYear <= founderThreshold), founder2 := 1]
data[ is.na(founder2), founder2 := 0]

mostRecentEmployers <- data[data[ , .I[1], by = c("EntityID","Title","FirstName","LastName")]$V1]

mostRecentEmployers[ , variable := NULL]

#------------------------------#
# Construct some counts, mostly for diagnostic purposes
#------------------------------#

positionCounts <- mostRecentEmployers[ , .N, by = Position]
employerCounts <- mostRecentEmployers[ , .N, by = Employer]
  
positionCounts_founder2 <- mostRecentEmployers[ founder2 == 1, .N, by = Position]
employerCounts_founder2 <- mostRecentEmployers[ founder2 == 1, .N, by = Employer]

titleCodeCounts <- mostRecentEmployers[  , .N, by = TitleCode]
titleCounts <- mostRecentEmployers[ , .N, by = .(Title,TitleCode)]

fwrite(mostRecentEmployers,"data/VentureSource/EntitiesPrevEmployers.csv")

# Clean up
rm(data,employerCounts,positionCounts,titleCounts,titleCodeCounts,temp,temp1)







