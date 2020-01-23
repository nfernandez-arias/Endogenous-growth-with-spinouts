#------------------------------------------------#
#
# File name: addNoncompeteEnforcementIndices.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This adds NCC enforcement index from Starr 2018 
# to the data
#------------------------------------------------#

enforcementIndex <- fread("raw/NCCEnforcementIndices.csv")

compustatSpinouts <- fread("data/compustat-spinouts.csv")

setkey(enforcementIndex,State)
setkey(compustatSpinouts,state)

compustatSpinouts <- enforcementIndex[compustatSpinouts]

fwrite(compustatSpinouts,"data/compustat-spinouts.csv")

# Clean up
rm(compustatSpinouts,enforcementIndex)
