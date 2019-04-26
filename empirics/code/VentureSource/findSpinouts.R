#------------------------------------------------#
#
# File name: findSpinouts.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This is the main script for identifying spinouts
# of Compustat firms by name matching to employee bios 
# in Venture Source.
#------------------------------------------------#

rm(list = ls())

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/code/VentureSource")

# Parse employee biographies
source("parseBiographies.R")

# Determine which is the previous firm the employee worked at


# Link employee bios dataset to Compustat firms using fuzzy name matching
source("linkBiosToCompustat.R")

# Extra: link employee bios to other firms in Venture Source

