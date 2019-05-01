#------------------------------------------------#
#
# File name: extractBVDOsirisFirms.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script extracts firms from the BVD Osiris database
# The purpose for now is to be able to check if there is
# any information on firms in the VentureSource database
#------------------------------------------------#

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

library(data.table)

rm(list = ls())

data <- fread("raw/BvD Osiris/bvd_full.csv")

temp <- data[ , .(OS_ID_NUMBER,NAME,LISTED,CLOSDATE,CITY,PROVCODE,COUNTRY,CAICS12COD,DATA13004,DATA22020)]
temp <- temp[COUNTRY == "United States of America"]
#temp <- temp[LISTED == "Unlisted"]
  
fwrite(temp,"data/BVD/bvdOsirisUnlisted.csv")

