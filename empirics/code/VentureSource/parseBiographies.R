#------------------------------------------------#
#
# File name: parseBiographies.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script parses the information in the employee
# biographies into job titles and previous company positions.
#
# Output:
#
# names.csv (database linking EntityID and EntityName from VentureSource)
# EntitiesBios.csv (database linking entities to parsed biographies)
#
# 
#------------------------------------------------#

BDVI <- fread("raw/VentureSource/PrincetonBDVI.csv")
#BDVI <- read.xlsx("raw/VentureSource/PrincetonBDVI.xlsx")

#------------------------------#
# Divide biographies into jobs: separated by ";" character
#
# This will return a warning, since there are some employees with more than 15 jobs
# I will only be using the first few jobs in any case, so it's fine.
#------------------------------#

# First, flag observations re: whether they have Biographical information
BDVI[ Bio != "", hasBio := 1]
BDVI[ is.na(hasBio), hasBio := 0]

## Split bio into jobs -- to ensure getting the previous employer, include last 15 jobs (this covers all jobs for almost all individuals)
n <- max(lengths(strsplit(BDVI$Bio,";")))
BDVI[ , paste0("Job",1:n) := tstrsplit(Bio,";", fixed = T)]
# Keep first 15 jobs for good measure. 
for (i in 16:n)
{
  jobString <- paste0("Job",i)
  BDVI[ , (jobString) := NULL]
}

#------------------------------#
# Next, divide each job into (position,company) pair.
# 
# The challenge here is that some jobs are in the format
# <position>, <division>, <company>
# 
# While some are in the format
# <position> , <company>
#
# And finally some company strings are in the format
# <companyName>, <LLC | Inc | Inc.> 
# and so on.
#
# Originally I was dividing based on the last comma; this works
# in the first two cases. However, it leads to company names of "Inc.", "Inc" and "LLC" 
# in the third case. Therefore, do a second pass for those cases (hard-coding the major error cases)
# where I break based on the second-to-last comma. 
# A simple way to do this without having to construct a new RegEx expression is to simply 
# break off the area after the last comma in the relevant Company variable.
#
#------------------------------#

for (i in 1:15)
{
  position <- paste("Position",i, sep = "" )
  company <- paste("Company",i, sep = "")
  job <- paste("Job",i,sep = "")

  # First pass
  BDVI[ , c(position,company) := tstrsplit(get(job),",\\s*(?=[^,]+$)", perl=TRUE)]
  
  # Second pass
  BDVI[ get(company) == "Inc." | get(company) == "Inc" | get(company) == "LLC", c(position,company) := tstrsplit(get(position),",\\s*(?=[^,]+$)", perl=TRUE)]
  
  # Clear job variable when done
  BDVI[ , (job) := NULL]
  
}

fwrite(BDVI,"data/VentureSource/EntitiesBios.csv")

# Clean up
rm(list = ls.str(mode = "list"))
