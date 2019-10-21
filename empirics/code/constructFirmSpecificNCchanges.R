
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


rm(list =ls()) 

firmYearStateShares <- fread("data/compustat/firmYearStateShares_bloom.csv")[ ,.(gvkey,state,year,ishare)]


## Set equal to zero to initilaize 


firmYearStateShares[ , treatedPreAll := 0]
firmYearStateShares[ , treatedPostAll := 0]
firmYearStateShares[ , treatedPost0 := 0]
firmYearStateShares[ , treatedPost1 := 0]
firmYearStateShares[ , treatedPost2 := 0]
firmYearStateShares[ , treatedPost3 := 0]
firmYearStateShares[ , treatedPost4 := 0]
firmYearStateShares[ , treatedPre1 := 0]
firmYearStateShares[ , treatedPre2 := 0]
firmYearStateShares[ , treatedPre3 := 0]
firmYearStateShares[ , treatedPre4 := 0]

firmYearStateShares[ state == "WI" & year < 2009, treatedPreAll := 1]
firmYearStateShares[ state == "SC" & year < 2010, treatedPreAll := -1]
firmYearStateShares[ state == "CO" & year < 2011, treatedPreAll := 1]
firmYearStateShares[ state == "TX" & year < 2011, treatedPreAll := 1]
firmYearStateShares[ state == "MT" & year < 2011, treatedPreAll := -1]
firmYearStateShares[ state == "IL" & year < 2011, treatedPreAll := 1]
firmYearStateShares[ state == "IL" & year < 2013, treatedPreAll := 0]
firmYearStateShares[ state == "VA" & year < 2013, treatedPreAll := 1]
firmYearStateShares[ state == "GA" & year < 2011, treatedPreAll := 1]


firmYearStateShares[ state == "WI" & year >= 2009, treatedPostAll := 1]
firmYearStateShares[ state == "SC" & year >= 2010, treatedPostAll := -1]
firmYearStateShares[ state == "CO" & year >= 2011, treatedPostAll := 1]
firmYearStateShares[ state == "TX" & year >= 2011, treatedPostAll := 1]
firmYearStateShares[ state == "MT" & year >= 2011, treatedPostAll := -1]
firmYearStateShares[ state == "IL" & year >= 2011, treatedPostAll := 1]
firmYearStateShares[ state == "IL" & year >= 2013, treatedPostAll := 0]
firmYearStateShares[ state == "VA" & year >= 2013, treatedPostAll := 1]
firmYearStateShares[ state == "GA" & year >= 2011, treatedPostAll := 1]


firmYearStateShares[ state == "WI" & year == 2009, treatedPost0 := 1]
firmYearStateShares[ state == "SC" & year == 2010, treatedPost0 := -1]
firmYearStateShares[ state == "CO" & year == 2011, treatedPost0 := 1]
firmYearStateShares[ state == "TX" & year == 2011, treatedPost0 := 1]
firmYearStateShares[ state == "MT" & year == 2011, treatedPost0 := -1]
firmYearStateShares[ state == "IL" & year == 2011, treatedPost0 := 1]
firmYearStateShares[ state == "IL" & year == 2013, treatedPost0 := 0]
firmYearStateShares[ state == "VA" & year == 2013, treatedPost0 := 1]
firmYearStateShares[ state == "GA" & year == 2011, treatedPost0 := 1]

firmYearStateShares[ state == "WI" & year == 2009+1, treatedPost1 := 1]
firmYearStateShares[ state == "SC" & year == 2010+1, treatedPost1 := -1]
firmYearStateShares[ state == "CO" & year == 2011+1, treatedPost1 := 1]
firmYearStateShares[ state == "TX" & year == 2011+1, treatedPost1 := 1]
firmYearStateShares[ state == "MT" & year == 2011+1, treatedPost1 := -1]
firmYearStateShares[ state == "IL" & year == 2011+1, treatedPost1 := 1]
firmYearStateShares[ state == "IL" & year == 2013+1, treatedPost1 := 0]
firmYearStateShares[ state == "VA" & year == 2013+1, treatedPost1 := 1]
firmYearStateShares[ state == "GA" & year == 2011+1, treatedPost1 := 1]

firmYearStateShares[ state == "WI" & year == 2009+2, treatedPost2 := 1]
firmYearStateShares[ state == "SC" & year == 2010+2, treatedPost2 := -1]
firmYearStateShares[ state == "CO" & year == 2011+2, treatedPost2 := 1]
firmYearStateShares[ state == "TX" & year == 2011+2, treatedPost2 := 1]
firmYearStateShares[ state == "MT" & year == 2011+2, treatedPost2 := -1]
firmYearStateShares[ state == "IL" & year == 2011+2, treatedPost2 := 1]
firmYearStateShares[ state == "IL" & year == 2013+2, treatedPost2 := 0]
firmYearStateShares[ state == "VA" & year == 2013+2, treatedPost2 := 1]
firmYearStateShares[ state == "GA" & year == 2011+2, treatedPost2 := 1]

firmYearStateShares[ state == "WI" & year == 2009+3, treatedPost3 := 1]
firmYearStateShares[ state == "SC" & year == 2010+3, treatedPost3 := -1]
firmYearStateShares[ state == "CO" & year == 2011+3, treatedPost3 := 1]
firmYearStateShares[ state == "TX" & year == 2011+3, treatedPost3 := 1]
firmYearStateShares[ state == "MT" & year == 2011+3, treatedPost3 := -1]
firmYearStateShares[ state == "IL" & year == 2011+3, treatedPost3 := 1]
firmYearStateShares[ state == "IL" & year == 2013+3, treatedPost3 := 0]
firmYearStateShares[ state == "VA" & year == 2013+3, treatedPost3 := 1]
firmYearStateShares[ state == "GA" & year == 2011+3, treatedPost3 := 1]

firmYearStateShares[ state == "WI" & year == 2009+4, treatedPost4 := 1]
firmYearStateShares[ state == "SC" & year == 2010+4, treatedPost4 := -1]
firmYearStateShares[ state == "CO" & year == 2011+4, treatedPost4 := 1]
firmYearStateShares[ state == "TX" & year == 2011+4, treatedPost4 := 1]
firmYearStateShares[ state == "MT" & year == 2011+4, treatedPost4 := -1]
firmYearStateShares[ state == "IL" & year == 2011+4, treatedPost4 := 1]
firmYearStateShares[ state == "IL" & year == 2013+4, treatedPost4 := 0]
firmYearStateShares[ state == "VA" & year == 2013+4, treatedPost4 := 1]
firmYearStateShares[ state == "GA" & year == 2011+4, treatedPost4 := 1]

# Add pre-treatement, to ensure that results are not driven by a 
# relative weakness in the relationship in these states overall. 
# But want to use a small enough window to not pick up instead 
# a general trend in the relationship over time.  Could also test for this trend directly. 

firmYearStateShares[ state == "WI" & year == 2009-1, treatedPre1 := 1]
firmYearStateShares[ state == "SC" & year == 2010-1, treatedPre1 := -1]
firmYearStateShares[ state == "CO" & year == 2011-1, treatedPre1 := 1]
firmYearStateShares[ state == "TX" & year == 2011-1, treatedPre1 := 1]
firmYearStateShares[ state == "MT" & year == 2011-1, treatedPre1 := -1]
firmYearStateShares[ state == "IL" & year == 2011-1, treatedPre1 := 1]
firmYearStateShares[ state == "IL" & year == 2013-1, treatedPre1 := 0]
firmYearStateShares[ state == "VA" & year == 2013-1, treatedPre1 := 1]
firmYearStateShares[ state == "GA" & year == 2011-1, treatedPre1 := 1]

firmYearStateShares[ state == "WI" & year == 2009-2, treatedPre2 := 1]
firmYearStateShares[ state == "SC" & year == 2010-2, treatedPre2 := -1]
firmYearStateShares[ state == "CO" & year == 2011-2, treatedPre2 := 1]
firmYearStateShares[ state == "TX" & year == 2011-2, treatedPre2 := 1]
firmYearStateShares[ state == "MT" & year == 2011-2, treatedPre2 := -1]
firmYearStateShares[ state == "IL" & year == 2011-2, treatedPre2 := 1]
firmYearStateShares[ state == "IL" & year == 2013-2, treatedPre2 := 0]
firmYearStateShares[ state == "VA" & year == 2013-2, treatedPre2 := 1]
firmYearStateShares[ state == "GA" & year == 2011-2, treatedPre2 := 1]

firmYearStateShares[ state == "WI" & year == 2009-3, treatedPre3 := 1]
firmYearStateShares[ state == "SC" & year == 2010-3, treatedPre3 := -1]
firmYearStateShares[ state == "CO" & year == 2011-3, treatedPre3 := 1]
firmYearStateShares[ state == "TX" & year == 2011-3, treatedPre3 := 1]
firmYearStateShares[ state == "MT" & year == 2011-3, treatedPre3 := -1]
firmYearStateShares[ state == "IL" & year == 2011-3, treatedPre3 := 1]
firmYearStateShares[ state == "IL" & year == 2013-3, treatedPre3 := 0]
firmYearStateShares[ state == "VA" & year == 2013-3, treatedPre3 := 1]
firmYearStateShares[ state == "GA" & year == 2011-3, treatedPre3 := 1]

firmYearStateShares[ state == "WI" & year == 2009-4, treatedPre4 := 1]
firmYearStateShares[ state == "SC" & year == 2010-4, treatedPre4 := -1]
firmYearStateShares[ state == "CO" & year == 2011-4, treatedPre4 := 1]
firmYearStateShares[ state == "TX" & year == 2011-4, treatedPre4 := 1]
firmYearStateShares[ state == "MT" & year == 2011-4, treatedPre4 := -1]
firmYearStateShares[ state == "IL" & year == 2011-4, treatedPre4 := 1]
firmYearStateShares[ state == "IL" & year == 2013-4, treatedPre4 := 0]
firmYearStateShares[ state == "VA" & year == 2013-4, treatedPre4 := 1]
firmYearStateShares[ state == "GA" & year == 2011-4, treatedPre4 := 1]



## Construct interactions with shares and treated

firmYearStateShares <- firmYearStateShares[order(gvkey,state,year)][!is.na(gvkey)]

## For firms with no patenting information, use headquarters. Or not. Maybe this is pointless.
#firmHQs <- unique(fread("raw/compustat/compustat_annual.csv")[ , .(gvkey,state)][!is.na(gvkey) & !is.na(state) & state != ""], by = c("gvkey"))
#setnames(firmHQs,"state","HQstate")

#setkey(firmHQs,gvkey)
#setkey(firmYearStateShares,gvkey)

#firmYearStateShares <- firmHQs[firmYearStateShares]

firmYearStateShares <- firmYearStateShares[state != "" & !is.na(state)]

firmYearStateShares[ , ishare_la4 := shift(ishare,4L,type="lag"), by = .(gvkey,state)]
firmYearStateShares[ , ishare_la3 := shift(ishare,3L,type="lag"), by = .(gvkey,state)]
firmYearStateShares[ , ishare_la2 := shift(ishare,2L,type="lag"), by = .(gvkey,state)]
firmYearStateShares[ , ishare_la1 := shift(ishare,1L,type="lag"), by = .(gvkey,state)]

firmYearStateShares[ , ishare_le1 := shift(ishare,1L,type="lead"), by = .(gvkey,state)]
firmYearStateShares[ , ishare_le2 := shift(ishare,2L,type="lead"), by = .(gvkey,state)]
firmYearStateShares[ , ishare_le3 := shift(ishare,3L,type="lead"), by = .(gvkey,state)]
firmYearStateShares[ , ishare_le4 := shift(ishare,4L,type="lead"), by = .(gvkey,state)]





#firmYearStateShares[ , ishare_treatedPre4 := ishare_le4 * treatedPre4 ]
#firmYearStateShares[ , ishare_treatedPre3 := ishare_le3 * treatedPre3 ]
#firmYearStateShares[ , ishare_treatedPre2 := ishare_le2 * treatedPre2 ]
#firmYearStateShares[ , ishare_treatedPre1 := ishare_le1 * treatedPre1 ]
#firmYearStateShares[ , ishare_treatedPost0 := ishare * treatedPost0 ]
#firmYearStateShares[ , ishare_treatedPost1 := ishare_la1 * treatedPost1 ]
#firmYearStateShares[ , ishare_treatedPost2 := ishare_la2 * treatedPost2 ]
#firmYearStateShares[ , ishare_treatedPost3 := ishare_la3 * treatedPost3 ]
#firmYearStateShares[ , ishare_treatedPost4 := ishare_la4 * treatedPost4 ]

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

#firmYearNCchanges <- firmYearStateShares[ , .( fw_pre4 = sum(na.omit(ishare_treatedPre4)), fw_pre3 = sum(na.omit(ishare_treatedPre3)) , fw_pre2 = sum(na.omit(ishare_treatedPre2)) , 
#                                              fw_pre1 = sum(na.omit(ishare_treatedPre1)) , fw_post0 = sum(na.omit(ishare_treatedPost0)) , 
#                                              fw_post1 = sum(na.omit(ishare_treatedPost1)) , fw_post2 = sum(na.omit(ishare_treatedPost2)) , 
#                                              fw_post3 = sum(na.omit(ishare_treatedPost3)) , fw_post4 = sum(na.omit(ishare_treatedPost4)) ) , by = .(gvkey,year)]

firmYearNCchanges <- firmYearStateShares[ , .( fw_pre4 = sum(ishare_treatedPre4), fw_pre3 = sum(ishare_treatedPre3) , fw_pre2 = sum(ishare_treatedPre2) , 
                                               fw_pre1 = sum(ishare_treatedPre1) , fw_post0 = sum(ishare_treatedPost0) , 
                                               fw_post1 = sum(ishare_treatedPost1) , fw_post2 = sum(ishare_treatedPost2) , 
                                               fw_post3 = sum(ishare_treatedPost3) , fw_post4 = sum(ishare_treatedPost4) ) , by = .(gvkey,year)]
  

# Diagnostic -- some weird stuff happening with ishare values exceeding 1 in magnitude...but not too many, so I'm hoping my measures are right...idk...
hist(na.omit(firmYearNCchanges$fw_post0))
hist(na.omit(firmYearNCchanges[fw_post0 != 0 & fw_post0 != 1 & fw_post0 != -1]$fw_post0),breaks = 100)

hist(na.omit(firmYearStateShares$ishare), breaks = 100)

    
fwrite(firmYearNCchanges,"data/firmYearNCchanges.csv")









