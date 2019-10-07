# mergeFirmNCchangesToMasterData.R
#
#
#


rm(list = ls())

firmYearNCchanges <- fread("data/firmYearNCchanges.csv")
firmYearNCchanges[ , flag := 1]

compustatSpinouts <- fread("data/compustat-spinouts.csv")

setkey(firmYearNCchanges,gvkey,year)
setkey(compustatSpinouts,gvkey,year)

compustatSpinouts <- firmYearNCchanges[compustatSpinouts]


compustatSpinouts[ is.na(flag), fw_pre3 := as.double(treatedPre3)]
compustatSpinouts[ is.na(flag), fw_pre2 := as.double(treatedPre2)]
compustatSpinouts[ is.na(flag), fw_pre1 := as.double(treatedPre1)] 
compustatSpinouts[ is.na(flag), fw_post0 := as.double(treatedPost0)]
compustatSpinouts[ is.na(flag), fw_post1 := as.double(treatedPost1)]
compustatSpinouts[ is.na(flag), fw_post2 := as.double(treatedPost2)]
compustatSpinouts[ is.na(flag), fw_post3 := as.double(treatedPost3)]



fwrite(compustatSpinouts,"data/compustat-spinouts.csv")
