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
rm(list = ls())
setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

# First, create database of parent-spinout relationships
source("code/VentureSource/findSpinouts.R")

# Next, do some basic analyses
source("code/basicSpinoutAnalysis.R")



