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
data[is.na(xrd) == TRUE, xrd := 0]

# Decide whether to use normalized variable or not -- 
# if not, COMMENT OUT these lines

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


## Compute moving averages
data[, xrd_ma3 := (1/3) * Reduce(`+`, shift(xrd, 0L:2L, type = "lag")), by = gvkey]
data[, xrd_ma5 := (1/5) * Reduce(`+`, shift(xrd, 0L:4L, type = "lag")), by = gvkey]

data[, patentApplicationCount_ma3 := (1/3) * Reduce(`+`, shift(patentApplicationCount, 0L:2L, type = "lag")), by = gvkey]
data[, patentApplicationCount_ma5 := (1/5) * Reduce(`+`, shift(patentApplicationCount, 0L:4L, type = "lag")), by = gvkey]

data[, patentApplicationCount_CW_ma3 := (1/3) * Reduce(`+`, shift(patentApplicationCount_CW, 0L:2L, type = "lag")), by = gvkey]
data[, patentApplicationCount_CW_ma5 := (1/5) * Reduce(`+`, shift(patentApplicationCount_CW, 0L:4L, type = "lag")), by = gvkey]

data[, patentCount_ma3 := (1/3) * Reduce(`+`, shift(patentCount, 0L:2L, type = "lag")), by = gvkey]
data[, patentCount_ma5 := (1/5) * Reduce(`+`, shift(patentCount, 0L:4L, type = "lag")), by = gvkey]

data[, patentCount_CW_ma3 := (1/3) * Reduce(`+`, shift(patentCount_CW, 0L:2L, type = "lag")), by = gvkey]
data[, patentCount_CW_ma5 := (1/5) * Reduce(`+`, shift(patentCount_CW, 0L:4L, type = "lag")), by = gvkey]

data[, spinoutCountUnweighted_ma2 := (1/2) * Reduce(`+`, shift(spinoutCountUnweighted, 0L:1L, type = "lead")), by = gvkey]
data[, spinoutCountUnweighted_ma3 := (1/3) * Reduce(`+`, shift(spinoutCountUnweighted, 0L:2L, type = "lead")), by = gvkey]

data[, spinoutCount_ma2 := (1/2) * Reduce(`+`, shift(spinoutCount, 0L:1L, type = "lead")), by = gvkey]
data[, spinoutCount_ma3 := (1/3) * Reduce(`+`, shift(spinoutCount, 0L:2L, type = "lead")), by = gvkey]

data[, spinoutCount_ma2 := (1/2) * Reduce(`+`, shift(spinoutCount, 0L:1L, type = "lead")), by = gvkey]
data[, spinoutCount_ma3 := (1/3) * Reduce(`+`, shift(spinoutCount, 0L:2L, type = "lead")), by = gvkey]




#data[is.na(xrd_ma3) == TRUE, xrd_ma3 := 0]
#data[is.na(xrd_ma5) == TRUE, xrd_ma5 := 0]

# Ignore compustat firms that never record R&D
data <- data[, if(max(na.omit(xrd)) > 0) .SD, by = gvkey]

# Ignore compustat firms that never have spinouts?
data <- data[, if(max(na.omit(spinoutCount)) >0) .SD, by = gvkey]

data <- data[year >= 1986]
data <- data[year <= 2015]

# Construct 4-digit NAICS codes
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

## Construct naics4-year and state-year variables
data[, stateYear := as.factor(paste(State,year))]

data[, naics4Year := as.factor(paste(naics4,year))]

data[, naics4Year_count := .N, by = naics4Year]
data[naics4Year_count <= 10, naics4Year_drop := 1]
  
  

fwrite(data,"data/compustat-spinouts_Stata.csv")
