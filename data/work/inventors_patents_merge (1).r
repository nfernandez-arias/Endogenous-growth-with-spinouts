# File name: inventors_patents_merge.r
#
# Function: Reads in Raw\pat76_06_assg.dta, joins it with 
# the file Raw\inventor.dta. Result 
#
# Outputs: Data\patents_inventor.rda
#
#

library(readstata13)

patents <- read.dta13('Raw/pat76_06_assg.dta')

inventors <- read.csv('Raw/inventor.csv')
names(inventors)[names(inventors) == 'Patent'] <- 'patent'

inventors_patents <- merge(patents,inventors,by = "patent")





