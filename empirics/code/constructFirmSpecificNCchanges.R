#---------------------------------------#
# constructFirmSpecificNCchanges.R
#
# Use history of patenting to construct
# index of where firm does its R&D,
# then interact this with changes to state-level 
# non-compete enforcement to form index for 
# firm-specific changes to non-compete enforceability.
#
# Then I will use this to see if I can find evidence that:
#
# (1) First-stage: increased noncompete enforcement leads to an increase in R&D spending.
#
# (2) Direct: increased non-compete enforcement leads to fewer spinouts by the firm (though this is kind of weird. not necessary.)
#
#


# I think my calculation is more accurate than Bloom's,
# because he only uses the first gvkey associated with each pdpass...whereas
# I use dynass to form my matches. Anyway...

firmYearStateShares <- fread("data/compustat/firmYearStateShares.csv")[ ,.(gvkey,state,year,ishare)]
#firmYearStateShares_bloom <- fread("data/compustat/firmYearStateShares_bloom.csv")[ ,.(gvkey,state,year,ishare)]

NCCenforcementChanges <- fread("data/NCCenforcementChanges.csv")

setkey(firmYearStateShares,state,year)
setkey(NCCenforcementChanges,state,year)

firmYearStateShares <- NCCenforcementChanges[firmYearStateShares]

## Construct interactions with shares and treated

firmYearStateShares <- firmYearStateShares[order(gvkey,state,year)][!is.na(gvkey)]

firmYearStateShares <- firmYearStateShares[state != "" & !is.na(state)]

firmYearStateShares[ , ishare_treatedPre4 := ishare * treatedPre4 ]
firmYearStateShares[ , ishare_treatedPre3 := ishare * treatedPre3 ]
firmYearStateShares[ , ishare_treatedPre2 := ishare * treatedPre2 ]
firmYearStateShares[ , ishare_treatedPre1 := ishare * treatedPre1 ]
firmYearStateShares[ , ishare_treatedPost0 := ishare * treatedPost0 ]
firmYearStateShares[ , ishare_treatedPost1 := ishare * treatedPost1 ]
firmYearStateShares[ , ishare_treatedPost2 := ishare * treatedPost2 ]
firmYearStateShares[ , ishare_treatedPost3 := ishare * treatedPost3 ]
firmYearStateShares[ , ishare_treatedPost4 := ishare * treatedPost4 ]
  
## Now sum across states for each (gvkey,year) to get firm-year instrument
# Note: have to use na.omit, because got the treatedPre information from a dataset
# that was built off of Compustat, hence, will have NAs for state-year obs
# where no Compustat firms were headquartered in that state in that year. 
# This is fine provided that in such state-years, no Compustat firms have
# patenting activity there. This will be 99.99% true...
# Although, I will probably eventually want to correct this, for now it is fine..

firmYearNCchanges <- firmYearStateShares[ , .( fw_pre4 = sum(na.omit(ishare_treatedPre4)), fw_pre3 = sum(na.omit(ishare_treatedPre3)) , fw_pre2 = sum(na.omit(ishare_treatedPre2)) , 
                                               fw_pre1 = sum(na.omit(ishare_treatedPre1)) , fw_post0 = sum(na.omit(ishare_treatedPost0)) , 
                                               fw_post1 = sum(na.omit(ishare_treatedPost1)) , fw_post2 = sum(na.omit(ishare_treatedPost2)) , 
                                               fw_post3 = sum(na.omit(ishare_treatedPost3)) , fw_post4 = sum(na.omit(ishare_treatedPost4)) ) , by = .(gvkey,year)]


#--------------------------#
# Some diagnostics just for sanity-checking
#--------------------------#

hist(na.omit(firmYearNCchanges[fw_post0 != 0]$fw_post0, breaks = 100))
hist(na.omit(firmYearNCchanges[fw_post0 != 0 & fw_post0 != 1 & fw_post0 != -1]$fw_post0),breaks = 100)
hist(na.omit(firmYearStateShares[ishare != 0 & ishare != 1]$ishare), breaks = 100)

    
fwrite(firmYearNCchanges,"data/firmYearNCchanges.csv")


# Clean up

rm(firmYearStateShares,firmYearNCchanges,NCCenforcementChanges)








