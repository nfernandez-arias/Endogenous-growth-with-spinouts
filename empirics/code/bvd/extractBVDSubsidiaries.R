#------------------------------------------------#
#
# File name: extractBVDSubsidiaries.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script extracts the BVD subsidiary data
#------------------------------------------------#

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

library(data.table)

rm(list = ls())

data <- fread("raw/BvD Osiris/subsidiaries.csv")

data <- data[ SUBCTRY == "US"]
