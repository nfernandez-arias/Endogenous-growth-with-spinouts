# This file clean the raw compustat data

library(data.table)

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")
  
# Load raw data
raw <- fread("raw/compustat/compustat_annual.csv")
head(raw)

      