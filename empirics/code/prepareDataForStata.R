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

data <- fread("data/compustat-spinouts.csv")

setkey(data,gvkey,year)

# Set NA xrd values to zero 
data[is.na(xrd), xrd := 0]
data[is.na(capxv), capxv := 0]
data[is.na(sppe), sppe := 0]

# Change units
#data[ , xrd := xrd / 1000]

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
xrdDeflator <- fread("data/deflators/xrdDeflator.csv")
setkey(xrdDeflator,year)
setkey(data,year)
data <- xrdDeflator[data]
data[ , xrd := xrd / xrdDeflator]

# Need to deflate R&D further by productivity growth
productivityDeflator <- fread("data/deflators/productivityDeflator.csv")
setkey(productivityDeflator,year)
data <- productivityDeflator[data]
data[ , xrd := xrd / productivityDeflator]

## Apply other price indices  

gdpDeflator <- fread("data/deflators/gdpDeflator.csv")
setkey(gdpDeflator,year)
data <- gdpDeflator[data]

investmentDeflator <- fread("data/deflators/investmentDeflator.csv")
setkey(investmentDeflator,year)
data <- investmentDeflator[data]

parentFirmControls <- c("capx","capxv","at","sppe","intan","ni","ch","ebitda","sale","ppent")

for (var in parentFirmControls) 
{
  data[ , (var) := get(var) / (investmentDeflator * productivityDeflator)]
}

# Ignore compustat firms that never record R&D
# data <- data[, if(max(na.omit(xrd)) > 0) .SD, by = gvkey]
      
# Ignore compustat firms that never have spinouts?
# data <- data[, if(max(na.omit(spinoutCount)) >0) .SD, by = gvkey]


# Force the right time frame

data <- data[year >= 1986]
data <- data[year <= 2018]

# Construct 1,2,3,4,5,6-digit NAICS codes
data[, naics6 := as.integer(substr(naics,1,6))]
data[, naics5 := as.integer(substr(naics,1,5))]
data[, naics4 := as.integer(substr(naics,1,4))]
data[, naics3 := as.integer(substr(naics,1,3))]
data[, naics2 := as.integer(substr(naics,1,2))]
data[, naics1 := as.integer(substr(naics,1,1))]

# Sort data 
data <- data[order(gvkey,year)]
    
# Compute firm age  
data[, firmAge := rowidv(gvkey)]

data[, naics4Year_count := .N, by = .(naics4,year)]

#-------------#
# Drop naics4-year categories which have fewer than 10 firms in them
# (not sure if deprecated)
#-------------#

#data[naics4Year_count <= 10, naics4Year_drop := 1]
  
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

# Construct indicator variables
countCols <- grep("spinouts|founders|dev|dffv", names(data), value = T)
  
        for (col in countCols) 
{
  indicatorString <- paste0("i",col)
  data[ get(col) >0, (indicatorString) := 1]
  data[ is.na(get(indicatorString)), (indicatorString) := 0]
}


# Construct log variables
#countCols <- grep("spinouts|founders|dev|dffv", names(data), value = T)
        
#for (col in countCols)
#{
#  logcol <- paste("log_",col,sep = "")
  #print(logcol)
#  data[ , (logcol) := log(get(col))]
#}
    
#data[ , log_xrd := log(xrd)]
    

# Construct variable normalized by asset holdings

parentFirmVars <- c("xrd","patentApplicationCount","patentApplicationCount_CW","patentCount_CW","patentCount_CW_cumulative","emp","Tobin_Q","lfirm","lstate","lfirm_bloom","lstate_bloom")


#data[ , at_ma5 := (1/5) * Reduce(`+`, shift(at,0L:4L,type="lag")), by = gvkey]
data[ , at_ma5 := rollapplyr(at, FUN = mean, width = 5, align = "right", partial = TRUE), by = gvkey]
data[ , emp_ma5 := rollapplyr(emp, FUN = mean, width = 5, align = "right", partial = TRUE), by = gvkey]
#data[ , at_ma5_rollapplyr_false := rollapplyr(at, FUN = mean, width = 5, align = "right", partial = FALSE, fill = c(NA,NA,NA)), by = gvkey]

#setcolorder(data,c("gvkey","year","at","at_ma5","at_ma5_rollapplyr","at_ma5_rollapplyr_false"))

for (col in c(countCols,parentFirmControls,parentFirmVars))
{
  colString <- paste(col,"at",sep = ".")
  
  data[ , (colString) := get(col) / at_ma5]
}


# Construct forward looking counts

spinoutCols <- grep("spinouts(.+)at$",names(data),value = T)
founderCols <- grep("founders",names(data),value = T)

#for (col in spinoutCols)
#{
 # colString <- paste0("l",col)
#  data[ , (colString) := log(get(col))]
  
 # spinoutCols <- c(spinoutCols,colString)
  
#}

ptm <- proc.time()

founderCols.f3 <- c()

for (col in founderCols) {
  colString <- paste(col,".f3",sep = "")
  founderCols.f3 <- c(founderCols.f3,colString)
  data[ , (colString) := (1/3) * Reduce(`+`,shift(get(col), 1L:3L, type = "lead")), by = gvkey]
}
proc.time() - ptm



for (col in founderCols.f3)
{
  colString <- paste0("l",col)
  data[ , (colString) := log(get(col))]
  
}



# Construct backward looking independent variables

parentCols <- grep("at$", paste(c(parentFirmControls,parentFirmVars),"at",sep = "."), value = T)

# Consruct backward looking moving averages   
ptm <- proc.time()

for (col in c(parentCols,parentFirmControls,parentFirmVars))
{
  colString <- paste(col,"l3",sep = ".")
  
  data[ , (colString) := rollapplyr(get(col), FUN = mean, width = 3, align = "right", partial = TRUE), by = gvkey]
}
proc.time() - ptm

#--------------------------#
# Generate log variables
#--------------------------#


# deprecated - paralllel, slower for some reason
#data[ , paste0(c(parentFirmControls,parentFirmVars), ".l3") := mclapply(.SD, function(x) rollapplyr(x, FUN = mean, width = 3, align = "right", partial = TRUE), mc.cores = detectCores()), by = gvkey,
#      .SDcols = c(parentFirmControls,parentFirmVars)]                                                                   

  
## Construct variables to attempt to 
# do OLS regressions from Babina & Howell 2019          

#data[ , spin_emp := spinoutCountUnweighted / emp_lag1]
#data[ , lat := log(at)]
#data[ lat == -Inf, lat := NA]
#data[ , assetTang := ppent / at_lag1 ]
#data[ , invest_at := capx / at_lag1 ]    
#data[ , lch := log(ch)]
#data[ lch == -Inf, lch := NA]
#data[ , salesGrowth := sale / sale1]
#data[ salesGrowth == Inf, salesGrowth := NA]
#data[ at > 0 , roa := ni / at]


#-------------------------# 
# Variable normalization
# Important to do this at the end of the script
#-------------------------#

data[ , tobinqat := Tobin_Q * at]
      
if (normalizeVariablesStata == TRUE)
{
  for (col in c("Tobin_Q", "tobinqat", parentFirmVars, parentFirmControls, parentCols, paste0(parentCols,".l3")))
  {
    set(data, , col , (data[[col]] - mean(data[[col]], na.rm = TRUE)) / sd(data[[col]], na.rm = TRUE))
  }
}
            

# For use in making scatter plots  
fwrite(data,"data/compustat-spinouts_Stata.csv")
# Much faster for loading in Stata
write.dta(data,"data/compustat-spinouts_Stata.dta")

# Clean up
rm(data,gdpDeflator,investmentDeflator,productivityDeflator,xrdDeflator)
        
