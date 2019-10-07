#------------------------------------------------#
#
# File name: statsFromPatentData.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This file extracts statistics from the patent data
# for calibrating the model
#
# This includes:
#
# (1) Fraction of patents coming from new firms
#
#        This will be used to calibrate the spinout entry rate
#        in the model, along with the fraction of new firms 
#        which are spinouts.
#
# (2) Fraction of patents citing mostly patents from same firm
#
#------------------------------------------------#


rm(list = ls())


# Construct match from patent data to Venture Source,
# by name. Using regex techniques, go from 6 matches to 5000 matches.
# This means that 1/10 of Venture Source firms are matched to the patent data in this way.
source("code/patents/matchToVentureSource.R")

# Compute entry rates based on patent data
source("code/patents/computeEntryRate.R")

# Compute fraction of innovations that are internal










