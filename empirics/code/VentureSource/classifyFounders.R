#--------------------------------------------------#
# File name: classifyFounders.R
#
# Purpose: this code classifies founders into three classes
#
# (1) All
# (2) founders with titles in founderTitles (defined in main.R)
# (3) founders with titels in executiveTitles (defined in main.R)
#
# The most restrictive class is (2), followed by (3) and then (1). 
#
#--------------------------------------------------#

data <- fread("data/parentsSpinouts.csv")


#------------------------------#
# Which early employees of startup are to be counted as "Founders" for my analysis?
#
# Those with certain titles (see main.R) and those who joined the startup within the founderThreshold (also see main.R)
# 
# For those observations without information on founder's join date, just include all founders. Better than dropping...
# Gompers et al. say that they go one by one to get data on this, but this infeasible at this point, given the size of the dataset.
#------------------------------#

data[ TitleCode %in% technicalTitles & (joinYear - foundingYear <= founderThreshold), technical := 1]
data[ is.na(technical), technical := 0]

data[ TitleCode %in% founderTitles & (joinYear - foundingYear <= founderThreshold), founder2 := 1]
data[ is.na(founder2), founder2 := 0]

data[ TitleCode %in% executiveTitles & (joinYear - foundingYear <= founderThreshold), executive := 1]
data[ is.na(executive), executive := 0]

data[ joinYear - foundingYear <= founderThreshold , all := as.integer(1)]
data[ is.na(all), all := 0]

# Save data

fwrite(data,"data/parentsSpinouts.csv")

# Clean up

rm(data)