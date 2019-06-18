#------------------------------------------------#
#
# File name: main.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This is the main script for the empirical component
#------------------------------------------------#

library(data.table)

rm(list = ls())
setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

# First, create database of parent-spinout relationships
source("code/findSpinouts.R")

# Construct database of spinouts and their attributes:
# e.g. (1) whether they achieve revenue, (2) how much funding they receive, (3) whether they IPO, (4) IPO market capitalization
source("code/constructSpinoutAttributes")

# Next, do some basic analyses  
source("code/basicSpinoutAnalysis.R")

# Construct NAICS - VentureSource industry cross-walk?

# Construct parentFirm-year spinout counts and spinout indicator 
# (for now, not considering industry) 
source("code/constructSpinoutCounts.R") 

# Combine with data on R&D from compustat_annual
source("code/mergeRDwithSpinoutCounts.R")

# Next, do regressions
source("code/RD_spinouts_OLS.R")





