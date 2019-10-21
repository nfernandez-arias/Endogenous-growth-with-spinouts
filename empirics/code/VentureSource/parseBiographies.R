#------------------------------------------------#
#
# File name: parseBiographies.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script parses the information in the employee
# biographies into job titles and previous company positions.
#
# Output:
#
# names.csv (database linking EntityID and EntityName from VentureSource)
# EntitiesBios.csv (database linking entities to parsed biographies)
#
# 
#------------------------------------------------#

rm(list = ls())

library(data.table)
library(stringr)

BDVI <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/raw/VentureSource/PrincetonBDVI.csv")

# First, filter out entities that are venture capital firms.


# For now I haven't done this because I'm not sure I need to - VC firms have spinouts too no?

# Next, parse biographies of resulting dataset
BDVI[ , c("Job1","Job2","Job3","Job4","Job5","Job6","Job7","Job8","Job9","Job10","Job11","Job12","Job13","Job14","Job15") := tstrsplit(Bio,";")]
#BDVI[ , c("Job1","Job2","Job3","Job4","Job5") := tstrsplit(Bio,";")]
BDVI[ , Bio := NULL]

BDVI[ , c("Position1","Company1") := tstrsplit(Job1,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position2","Company2") := tstrsplit(Job2,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position3","Company3") := tstrsplit(Job3,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position4","Company4") := tstrsplit(Job4,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position5","Company5") := tstrsplit(Job5,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position6","Company6") := tstrsplit(Job6,",\\s*(?=[^,]+$)", perl=TRUE)]             
BDVI[ , c("Position7","Company7") := tstrsplit(Job7,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position8","Company8") := tstrsplit(Job8,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position9","Company9") := tstrsplit(Job9,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position10","Company10") := tstrsplit(Job10,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position11","Company11") := tstrsplit(Job11,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position12","Company12") := tstrsplit(Job12,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position13","Company13") := tstrsplit(Job13,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position14","Company14") := tstrsplit(Job14,",\\s*(?=[^,]+$)", perl=TRUE)]
BDVI[ , c("Position15","Company15") := tstrsplit(Job15,",\\s*(?=[^,]+$)", perl=TRUE)]

BDVI[ , c("Job1","Job2","Job3","Job4","Job5","Job6","Job7","Job8","Job9","Job10","Job11","Job12","Job13","Job14","Job15") := NULL]

#BDVI[ , c("Job1","Job2","Job3","Job4","Job5") := NULL]

fwrite(BDVI,"~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/data/VentureSource/EntitiesBios.csv")

