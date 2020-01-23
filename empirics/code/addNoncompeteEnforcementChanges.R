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


compustatSpinouts <- fread("data/compustat-spinouts.csv")


## Set equal to zero to initilaize 


compustatSpinouts[ , treatedPost0 := 0]
compustatSpinouts[ , treatedPost1 := 0]
compustatSpinouts[ , treatedPost2 := 0]
compustatSpinouts[ , treatedPost3 := 0]
compustatSpinouts[ , treatedPost4 := 0]
compustatSpinouts[ , treatedPre1 := 0]
compustatSpinouts[ , treatedPre2 := 0]
compustatSpinouts[ , treatedPre3 := 0]
compustatSpinouts[ , treatedPre4 := 0]

compustatSpinouts[ , placeboPost0 := 0]
compustatSpinouts[ , placeboPost1 := 0]
compustatSpinouts[ , placeboPost2 := 0]
compustatSpinouts[ , placeboPost3 := 0]
compustatSpinouts[ , placeboPre1 := 0]
compustatSpinouts[ , placeboPre2 := 0]
compustatSpinouts[ , placeboPre3 := 0]

compustatSpinouts[ state == "WI" & year == 2009, treatedPost0 := 1]
compustatSpinouts[ state == "SC" & year == 2010, treatedPost0 := -1]
compustatSpinouts[ state == "CO" & year == 2011, treatedPost0 := 1]
compustatSpinouts[ state == "TX" & year == 2011, treatedPost0 := 1]
compustatSpinouts[ state == "MT" & year == 2011, treatedPost0 := -1]
compustatSpinouts[ state == "IL" & year == 2011, treatedPost0 := 1]
compustatSpinouts[ state == "IL" & year == 2013, treatedPost0 := 0]
compustatSpinouts[ state == "VA" & year == 2013, treatedPost0 := 1]
compustatSpinouts[ state == "GA" & year == 2011, treatedPost0 := 1]

compustatSpinouts[ state == "WI" & year == 2009+1, treatedPost1 := 1]
compustatSpinouts[ state == "SC" & year == 2010+1, treatedPost1 := -1]
compustatSpinouts[ state == "CO" & year == 2011+1, treatedPost1 := 1]
compustatSpinouts[ state == "TX" & year == 2011+1, treatedPost1 := 1]
compustatSpinouts[ state == "MT" & year == 2011+1, treatedPost1 := -1]
compustatSpinouts[ state == "IL" & year == 2011+1, treatedPost1 := 1]
compustatSpinouts[ state == "IL" & year == 2013+1, treatedPost1 := 0]
compustatSpinouts[ state == "VA" & year == 2013+1, treatedPost1 := 1]
compustatSpinouts[ state == "GA" & year == 2011+1, treatedPost1 := 1]

compustatSpinouts[ state == "WI" & year == 2009+2, treatedPost2 := 1]
compustatSpinouts[ state == "SC" & year == 2010+2, treatedPost2 := -1]
compustatSpinouts[ state == "CO" & year == 2011+2, treatedPost2 := 1]
compustatSpinouts[ state == "TX" & year == 2011+2, treatedPost2 := 1]
compustatSpinouts[ state == "MT" & year == 2011+2, treatedPost2 := -1]
compustatSpinouts[ state == "IL" & year == 2011+2, treatedPost2 := 1]
compustatSpinouts[ state == "IL" & year == 2013+2, treatedPost2 := 0]
compustatSpinouts[ state == "VA" & year == 2013+2, treatedPost2 := 1]
compustatSpinouts[ state == "GA" & year == 2011+2, treatedPost2 := 1]

compustatSpinouts[ state == "WI" & year == 2009+3, treatedPost3 := 1]
compustatSpinouts[ state == "SC" & year == 2010+3, treatedPost3 := -1]
compustatSpinouts[ state == "CO" & year == 2011+3, treatedPost3 := 1]
compustatSpinouts[ state == "TX" & year == 2011+3, treatedPost3 := 1]
compustatSpinouts[ state == "MT" & year == 2011+3, treatedPost3 := -1]
compustatSpinouts[ state == "IL" & year == 2011+3, treatedPost3 := 1]
compustatSpinouts[ state == "IL" & year == 2013+3, treatedPost3 := 0]
compustatSpinouts[ state == "VA" & year == 2013+3, treatedPost3 := 1]
compustatSpinouts[ state == "GA" & year == 2011+3, treatedPost3 := 1]

compustatSpinouts[ state == "WI" & year == 2009+4, treatedPost4 := 1]
compustatSpinouts[ state == "SC" & year == 2010+4, treatedPost4 := -1]
compustatSpinouts[ state == "CO" & year == 2011+4, treatedPost4 := 1]
compustatSpinouts[ state == "TX" & year == 2011+4, treatedPost4 := 1]
compustatSpinouts[ state == "MT" & year == 2011+4, treatedPost4 := -1]
compustatSpinouts[ state == "IL" & year == 2011+4, treatedPost4 := 1]
compustatSpinouts[ state == "IL" & year == 2013+4, treatedPost4 := 0]
compustatSpinouts[ state == "VA" & year == 2013+4, treatedPost4 := 1]
compustatSpinouts[ state == "GA" & year == 2011+4, treatedPost4 := 1]

# Add pre-treatement, to ensure that results are not driven by a 
# relative weakness in the relationship in these states overall. 
# But want to use a small enough window to not pick up instead 
# a general trend in the relationship over time.  Could also test for this trend directly. 

compustatSpinouts[ state == "WI" & year == 2009-1, treatedPre1 := 1]
compustatSpinouts[ state == "SC" & year == 2010-1, treatedPre1 := -1]
compustatSpinouts[ state == "CO" & year == 2011-1, treatedPre1 := 1]
compustatSpinouts[ state == "TX" & year == 2011-1, treatedPre1 := 1]
compustatSpinouts[ state == "MT" & year == 2011-1, treatedPre1 := -1]
compustatSpinouts[ state == "IL" & year == 2011-1, treatedPre1 := 1]
compustatSpinouts[ state == "IL" & year == 2013-1, treatedPre1 := 0]
compustatSpinouts[ state == "VA" & year == 2013-1, treatedPre1 := 1]
compustatSpinouts[ state == "GA" & year == 2011-1, treatedPre1 := 1]

compustatSpinouts[ state == "WI" & year == 2009-2, treatedPre2 := 1]
compustatSpinouts[ state == "SC" & year == 2010-2, treatedPre2 := -1]
compustatSpinouts[ state == "CO" & year == 2011-2, treatedPre2 := 1]
compustatSpinouts[ state == "TX" & year == 2011-2, treatedPre2 := 1]
compustatSpinouts[ state == "MT" & year == 2011-2, treatedPre2 := -1]
compustatSpinouts[ state == "IL" & year == 2011-2, treatedPre2 := 1]
compustatSpinouts[ state == "IL" & year == 2013-2, treatedPre2 := 0]
compustatSpinouts[ state == "VA" & year == 2013-2, treatedPre2 := 1]
compustatSpinouts[ state == "GA" & year == 2011-2, treatedPre2 := 1]

compustatSpinouts[ state == "WI" & year == 2009-3, treatedPre3 := 1]
compustatSpinouts[ state == "SC" & year == 2010-3, treatedPre3 := -1]
compustatSpinouts[ state == "CO" & year == 2011-3, treatedPre3 := 1]
compustatSpinouts[ state == "TX" & year == 2011-3, treatedPre3 := 1]
compustatSpinouts[ state == "MT" & year == 2011-3, treatedPre3 := -1]
compustatSpinouts[ state == "IL" & year == 2011-3, treatedPre3 := 1]
compustatSpinouts[ state == "IL" & year == 2013-3, treatedPre3 := 0]
compustatSpinouts[ state == "VA" & year == 2013-3, treatedPre3 := 1]
compustatSpinouts[ state == "GA" & year == 2011-3, treatedPre3 := 1]

compustatSpinouts[ state == "WI" & year == 2009-4, treatedPre4 := 1]
compustatSpinouts[ state == "SC" & year == 2010-4, treatedPre4 := -1]
compustatSpinouts[ state == "CO" & year == 2011-4, treatedPre4 := 1]
compustatSpinouts[ state == "TX" & year == 2011-4, treatedPre4 := 1]
compustatSpinouts[ state == "MT" & year == 2011-4, treatedPre4 := -1]
compustatSpinouts[ state == "IL" & year == 2011-4, treatedPre4 := 1]
compustatSpinouts[ state == "IL" & year == 2013-4, treatedPre4 := 0]
compustatSpinouts[ state == "VA" & year == 2013-4, treatedPre4 := 1]
compustatSpinouts[ state == "GA" & year == 2011-4, treatedPre4 := 1]

compustatSpinouts[ year == 2008, placeboPre3 := 1]
compustatSpinouts[ year == 2009, placeboPre2 := 1]
compustatSpinouts[ year == 2010, placeboPre1 := 1]
compustatSpinouts[ year == 2011, placeboPost0 := 1]
compustatSpinouts[ year == 2012, placeboPost1 := 1]
compustatSpinouts[ year == 2013, placeboPost2 := 1]
compustatSpinouts[ year == 2014, placeboPost3 := 1]

fwrite(compustatSpinouts,"data/compustat-spinouts.csv")

#-------------------------#
# Store these for later use (in constructFirmSpecificNCchanges.R)
#-------------------------#

temp <- compustatSpinouts[ , .(state,year,treatedPre4,treatedPre3,treatedPre2,treatedPre1,treatedPost0,treatedPost1,treatedPost2,treatedPost3,treatedPost4,
                               placeboPre3,placeboPre2,placeboPre1,placeboPost0,placeboPost1,placeboPost2,placeboPost3)]

temp <- unique(temp, by = c("state","year"))
temp <- temp[ !is.na(state) & state != ""]

fwrite(temp,"data/NCCenforcementChanges.csv")

# Clean up

rm(compustatSpinouts,temp)
