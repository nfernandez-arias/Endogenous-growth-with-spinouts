#------------------------------------------------#
#
# File name: prepare-VentureSource-NAICS-Crosswalk.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script prepares the crosswalk for use in the analysis
# Mostly this entails constructing variables for the different it codes
#------------------------------------------------#

rm(list = ls())

library(stringr)
  
data <- fread("raw/VentureSource-NAICS-Crosswalk.csv")

data[str_count(NAICS1) == 6, NAICS1_6 := NAICS1]
data[str_count(NAICS1) >= 5, NAICS1_5 := substr(NAICS1,1,5)]
data[str_count(NAICS1) >= 4, NAICS1_4 := substr(NAICS1,1,4)]
data[str_count(NAICS1) >= 3, NAICS1_3 := substr(NAICS1,1,3)]
data[str_count(NAICS1) >= 2, NAICS1_2 := substr(NAICS1,1,2)]
data[str_count(NAICS1) >= 1, NAICS1_1 := substr(NAICS1,1,1)]

data[str_count(NAICS2) == 6, NAICS2_6 := NAICS2]
data[str_count(NAICS2) >= 5, NAICS2_5 := substr(NAICS2,1,5)]
data[str_count(NAICS2) >= 4, NAICS2_4 := substr(NAICS2,1,4)]
data[str_count(NAICS2) >= 3, NAICS2_3 := substr(NAICS2,1,3)]
data[str_count(NAICS2) >= 2, NAICS2_2 := substr(NAICS2,1,2)]
data[str_count(NAICS2) >= 1, NAICS2_1 := substr(NAICS2,1,1)]

data[str_count(NAICS3) == 6, NAICS3_6 := NAICS3]
data[str_count(NAICS3) >= 5, NAICS3_5 := substr(NAICS3,1,5)]
data[str_count(NAICS3) >= 4, NAICS3_4 := substr(NAICS3,1,4)]
data[str_count(NAICS3) >= 3, NAICS3_3 := substr(NAICS3,1,3)]
data[str_count(NAICS3) >= 2, NAICS3_2 := substr(NAICS3,1,2)]
data[str_count(NAICS3) >= 1, NAICS3_1 := substr(NAICS3,1,1)]
  
data[str_count(NAICS4) == 6, NAICS4_6 := NAICS4]
data[str_count(NAICS4) >= 5, NAICS4_5 := substr(NAICS4,1,5)]
data[str_count(NAICS4) >= 4, NAICS4_4 := substr(NAICS4,1,4)]
data[str_count(NAICS4) >= 3, NAICS4_3 := substr(NAICS4,1,3)]
data[str_count(NAICS4) >= 2, NAICS4_2 := substr(NAICS4,1,2)]
data[str_count(NAICS4) >= 1, NAICS4_1 := substr(NAICS4,1,1)]

fwrite(data,"data/VentureSource-NAICS-Crosswalk-final.csv")

