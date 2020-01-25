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

# Clear workspace
rm(list = ls())

#-----------------------#
# Preparing workspace
#-----------------------#

# Load data manipulation libraries
library(data.table)
library(lubridate)
library(stringr)
library(zoo)
library(stringdist)
library(readstata13)

# Load and set up plotting libraries
library(ggplot2)
library(ggthemr)
ggthemr("flat") # Set theme -- controls all plots

# Load specific functions
complete <- tidyr::complete
coalesce <- dplyr::coalesce

# Set working directory
setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

# Set some parameters
founderThreshold <- 2
minimumSpinoutsThreshold <- 10
excludeAltDG <- FALSE
fundingDiscountFactor <- 1.1

founderTitles <- c("CEO","CTO","CCEO","PCEO","PRE","PCOO","PCHM","PCOO","FDR")
executiveTitles <- c(founderTitles,"CSO","COO","CIO","CFO","CHF","CHMN","EVP","MDIR","MGR")

#--------------------------------
## Preparing Venture Source data  
#--------------------------------
  
# Construct VentureSource - NAICS cross-walk
source("code/VentureSource/prepare-VentureSource-NAICS-Crosswalk.R")

#----------------------------------
## Preparing compustat + nber uspto patent data
#----------------------------------

# Extract Compustat firms and link to their subsidiaries
#source("code/compustat/clean.R")
source("code/compustat/extractCompustatFirms.R") 
source("code/compustat/matchCompustatFirmsToSubsidiaries.R")

# Next, create a database of parent-patent relationships
source("code/nber uspto/matchPatentsToCompustat.R")

# Construct instrumental variable for R&D based on 
# R&D tax credits
source("code/compustat/constructInstruments.R")

#--------------------------------
# Constructing data on startups and previous employers
#--------------------------------

# Construct database of startups and their attributes, to be used later in the analysis:
# e.g. (1) whether they achieve revenue, (2) how much funding they receive, (3) whether they IPO, (4) IPO market capitalization
# Also, industry information (which will later be matched with NAICS codes using crosswalk) 
source("code/VentureSource/constructStartupAttributes.R")

# Next, construct database of parent-spinout relationships    
source("code/findSpinouts.R")

# Construct parentFirm-year spinout counts and spinout indicator 
# (for now, not considering industry)             
source("code/constructSpinoutCounts.R") 

# Combine with data on R&D from compustat_annual      
source("code/mergeRDwithSpinoutCounts.R")

# Merge with compustat-patent data
source("code/mergePatents_RD-Spinouts.R")

####
# BRING IN DATA ON NON-COMPETE ENFORCEMENT CHANGES FROM JEFFERS 2019
###

# Add variable encoding whether state has been trated by non-compete enforcement 
# using Jeffers' court rulings dates 
source("code/addNoncompeteEnforcementChanges.R") 

# Add variable encoding state-level strength of non-compete enforcement from Bishara 2011 / Starr 2018
source("code/addNoncompeteEnforcementIndices.R")

# Construct firm-specific NC enforcement changes (for shift-share regression)

# Only run the first time, because it takes a while
source("code/constructFirmSpecificNCchanges.R")

source("code/mergeFirmNCchangesToMasterData.R")

#-------------------------
# EXPORT TO STATA
# Prepare the data for analysis in Stata
# (because it has better implementations of fixed effect regressions)
#-------------------------
  
# Next, prepare the data for panel regressions in Stata   
source("code/prepareDataForStata.R")

# Prepare dataset for event study to see how    
# much spinout funding affects parent f irm stock price
source("code/prepareEventStudyDataset.R")
        
#----------------------------
# ANALYSIS (other than Stata regressions)
#----------------------------
          
# Make some scatter plots
source("code/analysis/makeScatterPlots.R")

# Make some calculations / plots to compare spinouts to regular startups
# e.g., how many of each kind in each year? 
source("code/analysis/compareSpinoutsToEntrants.R")

# Make some parent-child heatmaps: by industry, by state

source("code/analysis/parentChildStateMatrix.R")
source("code/analysis/parentChildIndustryMatrix.R")


## Compute statistics from patent data
# This includeswe have to be stewards of our cultural we have to be stewards of our cultural we have to be stewards of our cultural 
#
# (1) Fraction of innovations that are internal (cite mostly internal patents)
#
# (2) Fraction of patents coming from "new" firms (firms which first appeared in the patent data)

source("code/patents/statsFromPatentData.R")
    
        


                
