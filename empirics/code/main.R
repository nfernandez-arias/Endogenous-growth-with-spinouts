#------------------------------------------------#
#
# File name: main.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:d
#
# This is the main script for the empirical component
#------------------------------------------------#

library(data.table)

rm(list = ls())
setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

# First, create database of parent-spinout relationships    
source("code/findSpinouts.R")

# Next, create a database of parent-patent relationships
source("code/matchPatentsToCompustat.R")

# Construct database of spinouts and their attributes:
# e.g. (1) whether they achieve revenue, (2) how much funding they receive, (3) whether they IPO, (4) IPO market capitalization
source("code/constructSpinoutAttributes.R")

# Prepare dataset for event study to see how 
# much spinout funding affects parent firm stock price
source("code/prepareEventStudyDataset")

# Construct VentureSource - NAICS cross-walk
source("code/VentureSource/prepare-VentureSource-NAICS-Crosswalk.R")

# Construct parentFirm-year spinout counts and spinout indicator 
# (for now, not considering industry) 
source("code/constructSpinoutCounts.R") 

# Next, do some basic analyses    
source("code/basicSpinoutAnalysis.R")

# Combine with data on R&D from c ompustat_annual
source("code/mergeRDwithSpinoutCounts.R")

# Match patents with compustat
source("code/matchPatentsToCompustat.R")
source("code/mergePatents_RD-Spinouts.R")

#### Non-competes stuff

# Add variable encoding whether state has been trated by non-compete enforcement 
# using Jeffers' court rulings dates
source("code/addNoncompeteEnforcementChanges.R")

# Add variable encoding state-level strength of non-compete enforcement from Bishara 2011 / Starr 2018
source("code/addNoncompeteEnforcementIndices.R")

# Next, prepare the data for panel regressions in Stata
source("code/prepareDataForStata.R")
                            
      



