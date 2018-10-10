# File name: constructDataset_stateLevelAnalylsis_compustatAggregation_main.R
#
# Description: Main script for constructing dataset for state-level analysis based on compsutat R&D data
# and inventor locations from linked NBER patent data
#
# Todo: shit, need to figure out how to have TODO flags...
# 10/9/2018: Need to think about smoothing the weights in nber_compustat_RD_aggregation.R - 
# this involves rolling means, and have been having issues with that...But maybe easier in Stata!
# 
# Detail: 
# nber_compustat_RD_aggregation.R
# clean_GDP_stateLevel.R
# xrd_rdUserCost_GDP_merge_stateLevel_compustatAggregation.R
#

rm(list = ls())
setwd("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/work")

#library(profvis)

#source("Code/nber_compustat_RD_aggregation.R")
#source("Code/clean_GDP_stateLevel.R")
#source("Code/xrd_rdUserCost_GDP_merge_stateLevel_compustatAggregation.R")



profvis({

  source("Code/nber_compustat_RD_aggregation.R")
  source("Code/clean_GDP_stateLevel.R")
  source("Code/xrd-rdUserCost-GDP_merge_stateLevel_compustatAggregation.R")

})
