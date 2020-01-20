#------------------------------------------------#
#
# File name: findSpinouts.R
#
# Author: Nicolas Fernandez-Arias 
#
# Purpose:
#
# This is the main script for identifying spinouts
# of Compustat firms by name matching to employee bios deals <- fread(
# in Venture Source.  
#------------------------------------------------#

rm(list = ls())
setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

# Parse employee biographies
source("code/VentureSource/parseBiographies.R")

# Link with industry information
source("code/VentureSource/linkEntitiesToIndustries.R")

# Determine which is the previous firm the employee worked at
source("code/VentureSource/findLastEmployer.R")

# Clean results from AltDG
source("code/AltDG/cleanAltDGResults.R")


#--------------------------#
# Match everything up: 
#
# (1) Merge  
source("code/linkBiosToCompustat2.R")




