  #------------------------------------------------#
#
# File name: prepareDataForStata.R
#         
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This prepares the data / exports the data for 
# use in Stata (which is way better for panel data      
# regressions than R...)
#------------------------------------------------#  


rm(list = ls())

library(data.table)

data <- fread("data/compustat-spinouts.csv")

# Set NA xrd values to zero 
data[is.na(xrd), xrd := 0]
data[is.na(capxv), capxv := 0]
data[is.na(sppe), sppe := 0]


# Change units
data[ , xrd := xrd / 1000]


#-------------------------------#
#
# APPLY PRICE DEFLATORS TO GET REAL UNITS
#
# (1) First, convert R&D into real units of R&D, taking into account change in relative price of R&D
# (2) Second, convert R&D into units of R&D deflated by productivity growth: model hypothesizes that more real units of R&D are required to generate 
# innovations as productivity increases
# (3) Third, deflate the funding valuations of spinouts by the CPI, to arrive at real funding valuations
#
#-------------------------------#

# Apply R&D price index

xrdPriceIndex <- fread("raw/rdPriceIndex.csv")
xrdPriceIndex[ , year := year(ymd(DATE))]
xrdPriceAnnual <- xrdPriceIndex[ , .(priceIndex = mean(priceIndex)), by = year]
xrdPriceAnnual[ , xrdInflation := priceIndex / priceIndex[year == 2012]]
xrdPriceAnnual[ , priceIndex := NULL]
setkey(xrdPriceAnnual,year)
setkey(data,year)
data <- xrdPriceAnnual[data]
data[ , xrd := xrd / xrdInflation]


# Need to deflate R&D further by productivity growth
productivityGrowth <- fread("raw/productivityGrowth.csv")
productivityGrowth[ , Growth := 1 + Annual/100]
productivityGrowth[ , Annual := NULL]
productivityGrowth[ , cumGrowth := cumprod(Growth)]
productivityGrowth[ , growthFactor := cumGrowth / cumGrowth[Year == 2012]]
setkey(productivityGrowth,Year)
data <- productivityGrowth[data]
data[ , xrd := xrd / growthFactor ]

## Apply other price indices

cpi <- fread("raw/cpi.csv")
setnames(cpi,"Year","year")
cpi[ , cpiInflation := Annual / Annual[year == 2012]]
cpi[ , Annual := NULL]

setkey(cpi,year)

data <- cpi[data]
      
data[ , `:=` (capx = capx / (cpiInflation * growthFactor), at = at / (cpiInflation * growthFactor), sppe = sppe / (cpiInflation * growthFactor), capxv = capxv / (cpiInflation * growthFactor), intan = intan / (cpiInflation * growthFactor), ni = ni / (cpiInflation * growthFactor), ch = ch / (cpiInflation * growthFactor), ebitda = ebitda / (cpiInflation * growthFactor), sale = sale / (cpiInflation * growthFactor), ppent = ppent / (cpiInflation * growthFactor))]

data[ , spinoutsDiscountedFFValue := spinoutsDiscountedFFValue / (cpiInflation * growthFactor)]

# Code for normalizing variables
# if not normalizing, COMMENT OUT these lines

#data[, xrd := (xrd - mean(xrd)) / sd(xrd)]
#data[, patentApplicationCount := (patentApplicationCount - mean(patentApplicationCount)) / sd(patentApplicationCount)]
#data[, patentApplicationCount_CW := (patentApplicationCount_CW - mean(patentApplicationCount_CW)) / sd(patentApplicationCount_CW)]
#data[, patentCount := (patentCount - mean(patentCount)) / sd(patentCount)]
#data[, patentCount_CW := (patentCount_CW - mean(patentCount_CW)) / sd(patentCount_CW)]
#data[, patentCount_CW_cumulative := (patentCount_CW_cumulative - mean(patentCount_CW_cumulative)) / sd(patentCount_CW_cumulative)]
#data[, emp := (emp - mean(emp,na.rm = TRUE)) / sd(emp, na.rm = TRUE)]

#data[, spinoutCount := (spinoutCount - mean(spinoutCount,na.rm = TRUE)) / sd(spinoutCount, na.rm = TRUE)]
#data[, spinoutCountUnweighted := (spinoutCountUnweighted - mean(spinoutCountUnweighted,na.rm = TRUE)) / sd(spinoutCountUnweighted, na.rm = TRUE)]
#data[, spinoutCountUnweighted_onlyExits := (spinoutCountUnweighted_onlyExits - mean(spinoutCountUnweighted_onlyExits,na.rm = TRUE)) / sd(spinoutCountUnweighted_onlyExits, na.rm = TRUE)]
#data[, emp := (emp - mean(emp,na.rm = TRUE)) / sd(emp, na.rm = TRUE)]


#----------------------#
#
# Some messy code computing some data transformations
# Some of this is deprecated...
#
#----------------------#


## Compute moving averages
data[, xrd_3 := Reduce(`+`, shift(xrd, 0L:2L, type = "lag")), by = gvkey]
data[, xrd_5 := Reduce(`+`, shift(xrd, 0L:4L, type = "lag")), by = gvkey]

data[, xrd_ma3 := (1/3) * Reduce(`+`, shift(xrd, 0L:2L, type = "lag")), by = gvkey]

data[, patentCount_CW_cumulative_ma5 := (1/5) *  Reduce(`+`, shift(patentCount_CW_cumulative, 0L:4L, type = "lag")), by = gvkey]

data[, patentCount_cumulative_ma5 :=  (1/5) * Reduce(`+`, shift(patentCount_cumulative, 0L:4L, type = "lag")), by = gvkey]

data[, emp_ma5 := (1/5) * Reduce(`+`, shift(emp, 0L:4L, type = "lag")), by = gvkey]
data[, emp_lag1 := shift(emp, 1L, type = "lag"), by = gvkey]
data[, at_lag1 := shift(at, 1L, type = "lag"), by = gvkey]
    
data[ , ppent_lag1 := shift(ppent, 1L, type = "lag") , by = gvkey]
data[, investmentRate := (capxv - sppe) / ppent_lag1]
data[, xrdRate := xrd / ppent_lag1]


# Construct R&D intensity measures
data[ , xrdIntensity := xrd / at]
data[ xrdIntensity == Inf, xrdIntensity := NA]
data[ , sale1 := shift(sale, 1L, type = "lag"), by = gvkey]
data[ , xrdIntensity1 := xrd / sale1, by = gvkey]
data[ , sale_ma3 := Reduce(`+` , shift(sale,0L:2L, type = "lag")), by = gvkey]
data[ , xrdIntensity_3 := xrd / sale_ma3]
data[ xrdIntensity_3 == Inf, xrdIntensity_3 := NA]

data[ , salesFD := sale - sale1]
  
#data[is.na(xrd_ma3) == TRUE, xrd_ma3 := 0]
#data[is.na(xrd_ma5) == TRUE, xrd_ma5 := 0]   

# Ignore compustat firms that never record R&D
data <- data[, if(max(na.omit(xrd)) > 0) .SD, by = gvkey]
      
# Ignore compustat firms that never have spinouts?
#data <- data[, if(max(na.omit(spinoutCount)) >0) .SD, by = gvkey]

data <- data[year >= 1986]
data <- data[year <= 2018]

# Construct 1,2,3,4,5,6-digit NAICS codes
data[, naics6 := substr(naics,1,6)]
data[, naics5 := substr(naics,1,5)]
data[, naics4 := substr(naics,1,4)]
data[, naics3 := substr(naics,1,3)]
data[, naics2 := substr(naics,1,2)]
data[, naics1 := substr(naics,1,1)]

# Sort data 
data <- data[order(gvkey,year)]
    
# Compute firm age  
data[, firmAge := rowidv(gvkey)]

data[, naics4Year_count := .N, by = .(naics4,year)]

#-------------#
# Drop naics4-year categories which have fewer than 10 firms in them
# (not sure if deprecated)
#-------------#

data[naics4Year_count <= 10, naics4Year_drop := 1]
  
#data <- data[ sale > 0 ]
#data <- data[ emp > 0 ]
#data <- data[ sale1 > 0]

data <- data[State != ""]



### Define xrd treatment interaction variables

for (str in c("Pre3","Pre2","Pre1","Post0","Post1","Post2","Post3"))
{
  xrdTreatedString <- paste("xrd_tre",str,sep = "_")
  xrdPlaceboString <- paste("xrd_plac",str,sep = "_")
  treatedString <- paste("treated",str,sep = "")
  placeboString <- paste("placebo",str, sep = "")
  data[ , (xrdTreatedString) := xrd * get(treatedString)]
  data[ , (xrdPlaceboString) := xrd * get(placeboString)]
}

## Construct variables to attempt to 
# do OLS regressions from Babina & Howell 2019          

data[ , spin_emp := spinoutCountUnweighted / emp_lag1]
data[ , lat := log(at)]
data[ lat == -Inf, lat := NA]
data[ , assetTang := ppent / at_lag1 ]
data[ , invest_at := capx / at_lag1 ]
data[ , lch := log(ch)]
data[ lch == -Inf, lch := NA]
data[ , salesGrowth := sale / sale1]
data[ salesGrowth == Inf, salesGrowth := NA]
data[ at > 0 , roa := ni / at]

data[ , Spinouts_fut4 := Reduce(`+`,shift(spinoutCount,1L:4L,type = "lead")), by = gvkey]
data[ , Founders_fut4 := Reduce(`+`,shift(spinoutCountUnweighted,1L:4L,type = "lead")), by = gvkey]
data[ , SpinoutsDFFV_fut4 := Reduce(`+`,shift(spinoutsDiscountedFFValue,1L:4L,type = "lead")), by = gvkey]

data[ , Spinouts_fut5 := Reduce(`+`,shift(spinoutCount,1L:5L,type = "lead")), by = gvkey]
data[ , Founders_fut5 := Reduce(`+`,shift(spinoutCountUnweighted,1L:5L,type = "lead")), by = gvkey]
data[ , SpinoutsDFFV_fut5 := Reduce(`+`,shift(spinoutsDiscountedFFValue,1L:5L,type = "lead")), by = gvkey]

data[ , xrd_pas5 := Reduce(`+`, shift(xrd,0L:4L,type = "lag")), by = gvkey]

### 2 -year 
data[ , spinouts_fut2 := Reduce(`+`,shift(spinoutCount,1L:2L,type = "lead")), by = gvkey]
data[ , founders_fut2 := Reduce(`+`,shift(spinoutCountUnweighted,1L:2L,type = "lead")), by = gvkey]
data[ , spinoutsDFFV_fut2 := Reduce(`+`,shift(spinoutsDiscountedFFValue,1L:2L,type = "lead")), by = gvkey]


data[ , xrd_lag := shift(xrd,1L,type="lag"), by = gvkey]
data[ , xrd_lag2 := shift(xrd,2L,type="lag"), by = gvkey]
data[ , xrd_lag3 := shift(xrd,3L,type="lag"), by = gvkey]
data[ , xrd_lag4 := shift(xrd,4L,type="lag"), by = gvkey]
data[ , xrd_lead := shift(xrd,1L,type = "lead"), by = gvkey]
data[ , xrd_lead2 := shift(xrd,2L,type = "lead"), by = gvkey]



# Construct variables normalized by asset holdings, so that fixed effects are effectively
# multiplied by asset holdings. Should be a better specification, more able to control for the effects of 
# NAICS4-Year and State-Year shocks. Although there may be issues stemming from the fact that movements in at
# will affect both now. So, a useful robustness exercise, but not a panacea.

data[ , at_ma5 := (1/5) * Reduce(`+`, shift(at,0L:4L,type="lag")), by = gvkey]

#data[ , Spinouts_fut4_at := Spinouts_fut4 / at_ma5]
#data[ , Founders_fut4_at := Founders_fut4 / at_ma5]
#data[ , SpinoutsDFFV_fut4_at := SpinoutsDFFV_fut4 / at_ma5]
#data[ , xrd_at := xrd / at_ma5]
#data[ , ch_at := ch / at_ma5]
#data[ , patentCount_CW_cumulative_at := patentCount_CW_cumulative / at_ma5]
#data[ , emp_at := emp / at_ma5]

data[ , Tobin_Q_assets := Tobin_Q * at]
          
fwrite(data,"data/compustat-spinouts_Stata.csv")
                                                        



