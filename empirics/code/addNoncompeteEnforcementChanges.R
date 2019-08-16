#------------------------------------------------#
#
# File name: addNoncompeteEnforcementChanges.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This adds NCC enforcement changes to the dataset 
#------------------------------------------------#

rm(list = ls())

compustatSpinouts <- fread("data/compustat-spinouts.csv")

compustatSpinouts[ , treatedPost := 0]

compustatSpinouts[ state == "WI" & year >= 2009, treatedPost := 1]
compustatSpinouts[ state == "SC" & year >= 2010, treatedPost := -1]
compustatSpinouts[ state == "CO" & year >= 2011, treatedPost := 1]
compustatSpinouts[ state == "TX" & year >= 2011, treatedPost := 1]
compustatSpinouts[ state == "MT" & year >= 2011, treatedPost := -1]
compustatSpinouts[ state == "IL" & year >= 2011, treatedPost := 1]
compustatSpinouts[ state == "IL" & year >= 2013, treatedPost := 0]
compustatSpinouts[ state == "VA" & year >= 2013, treatedPost := 1]
compustatSpinouts[ state == "GA" & year >= 2011, treatedPost := 1]

fwrite(compustatSpinouts,"data/compustat-spinouts.csv")