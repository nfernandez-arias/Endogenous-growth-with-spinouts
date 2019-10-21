#------------------------------------------------#
#
# File name: constructInstruments.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This file constructs the instrumental variables
# used in BSV 2013. It follows their Stata code.
#------------------------------------------------#


library(readstata13)
library(zoo)

rm(list = ls())

##########################
#
# Federal tax credit
# 
#
##########################################

compustat <- fread("raw/compustat/compustat_annual.csv")
compustat <- compustat[indfmt=="INDL" & datafmt=="STD" & popsrc=="D" & consol=="C" & loc == "USA"]

compustat <- compustat[ , .(gvkey,fyear,sale,xrd,ebit)]

fwrite(compustat,"data/compustat/compustat_annual_light.csv")

compustat <- compustat[ !is.na(gvkey)]
compustat <- compustat[ !is.na(sale)]

setkey(compustat,gvkey,fyear)

# Flag for base period
compustat[ inrange(fyear,1984,1988), basePeriod := 1]
compustat[ is.na(basePeriod) , basePeriod := 0]
# Indicator for R&D conducted
compustat[ !is.na(xrd) & xrd > 0 , Ixrd := 1]
compustat[is.na(Ixrd) , Ixrd := 0]

# Sales and R&D in the base period
compustat[ , sxrd := sum(na.omit(xrd)), by = .(gvkey,basePeriod)]
compustat[ , ssale := sum(na.omit(sale)), by = .(gvkey,basePeriod)]
compustat[ , posRE := sum(na.omit(Ixrd)), by = .(gvkey,basePeriod)]

# Fixed base % is avg(xrd/sales) from 84-88, for firms with positive R&D in at least 3 years

## Note: this is not avg(xrd / sales) but rather avg(xrd) / avg(sales). It's what Bloom does...
#compustat[ basePeriod == 1 & posRE > 3 & sale > 0, fbp := mean(na.omit(xrd / sale)) , by = .(gvkey,basePeriod)]
compustat[ basePeriod == 1 & posRE > 3 & sale > 0, fbp := sxrd / ssale, by = .(gvkey,basePeriod)]

compustat[ , fbp_count := length(fbp[!is.na(fbp)]), by = .(gvkey)]

compustat[ fbp_count > 0 , fbp_min := min(na.omit(fbp)), by = gvkey]

compustat[ , fbp := fbp_min]
compustat[ , fbp_min := NULL]
compustat[ , fbp_count := NULL]

# Start-up tax rate

# Generate lags of sales and R&D

compustat[, L1_sale := shift(sale, 1L, type = "lag"), by = gvkey]
compustat[, L2_sale := shift(sale, 2L, type = "lag"), by = gvkey]
compustat[, L3_sale := shift(sale, 3L, type = "lag"), by = gvkey]
compustat[, L4_sale := shift(sale, 4L, type = "lag"), by = gvkey]
compustat[, L5_sale := shift(sale, 5L, type = "lag"), by = gvkey]

compustat[, L1_xrd := shift(xrd, 1L, type = "lag"), by = gvkey]
compustat[, L2_xrd := shift(xrd, 2L, type = "lag"), by = gvkey]
compustat[, L3_xrd := shift(xrd, 3L, type = "lag"), by = gvkey]
compustat[, L4_xrd := shift(xrd, 4L, type = "lag"), by = gvkey]
compustat[, L5_xrd := shift(xrd, 5L, type = "lag"), by = gvkey]

# Count from year of first R&D expenditure or 1994, whichever is later

compustat[ , credityear := Ixrd  * (fyear > 1993)]
compustat[ , credityear := cumsum(credityear), by = gvkey]

# 0.03 through first 5 years after 1993, then converges to actual %
compustat[ is.na(fbp) & fyear <= 1993, fbp := 0.03 ]
compustat[ is.na(fbp) & credityear <= 5, fbp := 0.03]
compustat[ is.na(fbp) & credityear == 6, fbp := (1/6)*(L2_xrd+L1_xrd)/(L2_sale+L1_sale)]
compustat[ is.na(fbp) & credityear == 7, fbp := (1/3)*(L2_xrd+L1_xrd)/(L2_sale+L1_sale)]
compustat[ is.na(fbp) & credityear == 8, fbp := (1/2)*(L3_xrd+L2_xrd+L1_xrd)/(L3_sale+L2_sale+L1_sale)]
compustat[ is.na(fbp) & credityear == 9, fbp := (2/3)*(L4_xrd+L3_xrd+L2_xrd+L1_xrd)/(L4_sale+L3_sale+L2_sale+L1_sale)]
compustat[ is.na(fbp) & credityear == 10, fbp := (5/6)*(L5_xrd+L4_xrd+L3_xrd+L2_xrd+L1_xrd)/(L5_sale+L4_sale+L3_sale+L2_sale+L1_sale)]
compustat[ is.na(fbp) & credityear >= 10, fbp := shift(fbp, 1L, type = "lag")]

# FBP may not exceed 0.16
compustat[ fbp > 0.16 , fbp := 0.16]

# Generate base amount : max( fbp * 4 years avg receipts) , 0.5 * r&D)
compustat[ , base := pmax(0.5 * xrd , fbp * (1/4) * (sale + L1_sale + L2_sale + L3_sale))]

rdUserCost <- unique(fread("data/bsv/RDusercost_2017.csv")[ , .(year, k_f, t_f)])

setkey(rdUserCost,year)
setkey(compustat,fyear)
compustat <- rdUserCost[compustat]

## Tax price of R&D following Hall 1992

# Indicator for taxable income
compustat[ , capT := (ebit >0 & year > 1980)]
# Indicator for above / below base amount
compustat[xrd < base , Z := 1]
compustat[is.na(Z) , Z := 0]
compustat[ xrd >= 2 * base , Z := 0.5 ]

compustat[ , Zlead1 := shift(Z,1L,type = "lead"), by = gvkey]
compustat[ , Zlead2 := shift(Z,2L,type = "lead"), by = gvkey]
compustat[ , Zlead3 := shift(Z,3L,type = "lead"), by = gvkey]


# Share of R&D qualifying for credit
compustat[ , eta := (xrd - base) / xrd]
compustat[ eta < 0 , eta := 0]
compustat[ xrd <= 0, eta := 0]

# Effective credit rate

R = 1.1

compustat[ , ERC := k_f * (Z - (1/3) * (R^(-1)*(Zlead1 > 0.5) + R^(-2) * (Zlead2 > 0.5) + R^(-3) * (Zlead3 > 0.5)))]
compustat[ year == 1981, ERC := k_f * (Z - (1/2) * (R^(-1)*(Zlead1 > 0.5) + R^(-2) * (Zlead2 > 0.5) + R^(-3) * (Zlead3 > 0.5)))]
compustat[ is.na(Zlead3), ERC := k_f * (Z - (1/3) * (R^(-1)*(Zlead1 > 0.5) + R^(-2) * (Zlead2 > 0.5)))]
compustat[ year == 1981 & is.na(Zlead3), ERC := k_f * (Z - (1/2) * (R^(-1)*(Zlead1 > 0.5) + R^(-2) * (Zlead2 > 0.5)))]
compustat[ is.na(Zlead2), ERC := k_f * (Z - (1/3) * R^(-1) * (Zlead1 > 0.5))]
compustat[ year == 1981 & is.na(Zlead2), ERC := k_f * (Z - (1/2) * R^(-1) * (Zlead1 > 0.5))]
compustat[ is.na(Zlead1), ERC := k_f * Z]

# 1989
compustat[ year == 1989 , ERC := ERC * (1 - 0.5 * t_f)]

# 1990+ (there'sa typo in Bloom...does for year >= 1989, negating previous line!)
compustat[ year >= 1990 , ERC := k_f * (1 - t_f) * Z]
compustat[ year < 1981, ERC := 0]

# Tax price
compustat[ , theta := (1 - capT * t_f - eta * ERC)]
compustat[ , firm := theta / (1 - capT * t_f)]
compustat[ , lfirm := log(firm)]


fwrite(compustat[ , .(gvkey,year,lfirm)],"data/compustat/lfirm.csv")

##########################
#
# State tax credit
# 
#
##########################################

## Construt state R&D user cost

rm(list = ls())

patentAppsGvkeys <- fread("data/patentsAppyearGvkeys.csv")[!is.na(gvkey) &  country == "US"]

## Merge with inventor data
#inventorsPatents <- fread("data/patentsview/inventorsPatents.csv")[!is.na(state) & state != ""][ , .(name_first,name_last,patent_id,state,country)]

#inventorsPatents[ , patent_id := as.integer(patent_id)]
#inventorsPatents <- inventorsPatents[ !is.na(patent_id)]

#setnames(inventorsPatents,"state","inventorState")
#setnames(inventorsPatents,"country","inventorCountry")

#setkey(inventorsPatents,patent_id)
#setkey(patentAppsGvkeys,patent)

#patentAppsGvkeys <- inventorsPatents[patentAppsGvkeys]


firmStateYearPatentCounts <- patentAppsGvkeys[ , .N, by = .(gvkey,year,state)] 
firmStateYearPatentCounts[, patentCount9 := rollapply(N, width = 10, FUN = sum, align = "right", partial = TRUE), by = .(gvkey,state)]
firmStateYearPatentCounts[, isum := sum(patentCount9), by = .(gvkey,year)]
firmStateYearPatentCounts[, ishare := patentCount9 / isum]

fwrite(firmStateYearPatentCounts,"data/compustatStatePatentCounts.csv")

# Now combine data into one dataset, merging by gvkey-year

rm(list = ls())

# Load complete function from tidyr, equivalent to fill function in Stata
complete <- tidyr::complete

firmYearStateShares <- fread("data/compustatStatePatentCounts.csv")[, .(gvkey,year,state,ishare)]

firmYearStateShares <- data.table(complete(firmYearStateShares,gvkey,state,year = 1986:2006))

# if ishare is NA and year is <= 2006, then ishare should be zero 
firmYearStateShares[is.na(ishare) , ishare := 0]

# Now complete to 2015
firmYearStateShares <- data.table(complete(firmYearStateShares,gvkey,state,year = 1986:2015))

# When missing, extrapolate previous non-missing value
firmYearStateShares[ , ishare := na.locf(ishare), by = .(gvkey,state)]

# Exclude observtions with no state...

firmYearStateShares <- firmYearStateShares[state != "" & !is.na(state)]

# Export dataset for use elsewhere
fwrite(firmYearStateShares,"data/compustat/firmYearStateShares.csv")

# Bring in state abbreviations, for merging with RDusercost_2017 dataset
stateAbbrevs <- fread("bloom/spillovers_rep/1_data/Raw/stmap.csv")
rdUserCost <- unique(fread("data/bsv/RDusercost_2017.csv")[ , .(rho_h,r,fips,year)])

setkey(stateAbbrevs,fips)
setkey(rdUserCost,fips)

rdUserCost <- stateAbbrevs[rdUserCost]

## Finally, merge database on where R&D occurs with data on effective tax rate in 
# each state, and compute Bloom's weighted average, and save.

setnames(rdUserCost,"state","stateName")
setkey(rdUserCost,abbr,year)
setkey(firmYearStateShares,state,year)

firmYearStateShares <- rdUserCost[firmYearStateShares]

firmYearStateShares[ , lstate := log(sum(na.omit((ishare * rho_h / 0.3)))), by = .(gvkey,year)]

lstate <- unique(firmYearStateShares[ , .(gvkey,year,lstate)])

lstate[ lstate == -Inf, lstate := NA]

lstate <- lstate[!is.na(lstate)]

fwrite(lstate,"data/compustat/lstate.csv")



### Finally, merge with Compustat

rm(list = ls())

lstate <- fread("data/compustat/lstate.csv")
lfirm <- fread("data/compustat/lfirm.csv")
compustat <- fread("data/compustat/compustat_for_bloom_instruments.csv")


setkey(compustat,gvkey,fyear)
setkey(lstate,gvkey,year)

compustat <- lstate[compustat]

setkey(lfirm,gvkey,year)

compustat <- lfirm[compustat]


## Upload datasets constructed using Bloom Stat code, for comparison...
lfirm_bloom <- data.table(read.dta13("data/compustat/lfirm.dta"))
lstate_bloom <- data.table(read.dta13("data/compustat/lstate.dta"))

setnames(lfirm_bloom,"lfirm","lfirm_bloom")
setnames(lstate_bloom,"lstate","lstate_bloom")

setkey(lfirm_bloom,gvkey,year)
setkey(lstate_bloom,gvkey,year)

compustat <- lfirm_bloom[compustat]
compustat <- lstate_bloom[compustat]

fwrite(compustat,"data/compustat/compustat_withBloomInstruments.csv") 

































  














































