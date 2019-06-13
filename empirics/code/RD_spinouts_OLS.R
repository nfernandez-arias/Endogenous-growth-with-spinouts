#------------------------------------------------#
#
# File name: RD_spinouts_OLS.R
#         
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This runs some basic OLS analyses - is R&D 
# associated with spinout formation at the firm level?
#------------------------------------------------#  

rm(list = ls())

library(plm)
library(sandwich)
library(lmtest)
library(data.table)
library(ggplot2)

data <- fread("data/compustat-spinouts.csv")

# Set NA xrd values to zero 
data[is.na(xrd) == TRUE, xrd := 0]

## Compute moving averages
data[, xrd_ma3 := (1/3) * Reduce(`+`, shift(xrd, 0L:2L, type = "lag")), by = gvkey]
data[, xrd_ma5 := (1/5) * Reduce(`+`, shift(xrd, 0L:4L, type = "lag")), by = gvkey]

data[, spinoutCountUnweighted_ma2 := (1/2) * Reduce(`+`, shift(spinoutCountUnweighted, 0L:1L, type = "lead")), by = gvkey]
data[, spinoutCountUnweighted_ma3 := (1/3) * Reduce(`+`, shift(spinoutCountUnweighted, 0L:2L, type = "lead")), by = gvkey]

data[, spinoutCount_ma2 := (1/2) * Reduce(`+`, shift(spinoutCount, 0L:1L, type = "lead")), by = gvkey]
data[, spinoutCount_ma3 := (1/3) * Reduce(`+`, shift(spinoutCount, 0L:2L, type = "lead")), by = gvkey]

#data[is.na(xrd_ma3) == TRUE, xrd_ma3 := 0]
#data[is.na(xrd_ma5) == TRUE, xrd_ma5 := 0]

# Ignore compustat firms that never record R&D
data <- data[, if(max(na.omit(xrd)) > 0) .SD, by = gvkey]

# Ignore compustat firms that never have spinouts?
data <- data[, if(max(na.omit(spinoutCount)) >0) .SD, by = gvkey]

#data <- data[year >= 1986]

# Construct 4-digit NAICS codes
data[, naics4 := substr(naics,1,4)]
data[, naics3 := substr(naics,1,3)]
data[, naics2 := substr(naics,1,2)]
data[, naics1 := substr(naics,1,1)]

# Sort data
data <- data[order(gvkey,year)]

# Compute firm age  

data[, firmAge := rowidv(gvkey)]
        
fwrite(data,"data/compustat-spinouts_Stata.csv")

            #### Analyses with spinout counts

# Construct scatter plot of R&D spending and spinout formation    
ggplot(data, aes(x = xrd, y = spinoutCount)) +
  geom_point(size = 0.1) + 
  geom_smooth(method = "lm", formula = y ~ poly(x,1), se = TRUE, fullrange =TRUE)

ggplot(data, aes(x = xrd_ma3, y = spinoutCountUnweighted_ma3)) +
  geom_point(size = 0.1) + 
  geom_smooth(method = "lm", formula = y ~ poly(x,1), se = TRUE, fullrange =TRUE)

ggplot(data, aes(x = xrd_ma3, y = spinoutCountUnweighted)) +
  geom_point(size = 0.1) + 
  geom_smooth(method = "lm", formula = y ~ poly(x,1), se = TRUE, fullrange =TRUE)

# Run OLS - no fixed effects lags of R&D spending
basicOLS <- lm(spinoutCount ~ xrd, data = data)
summary(basicOLS)

basicOLS_UnweightedSpinoutCount <- lm(spinoutCountUnweighted ~ xrd, data = data)
summary(basicOLS_UnweightedSpinoutCount)

basicOLS_UnweightedSpinoutCount_RDma3 <- lm(spinoutCountUnweighted ~ xrd_ma3, data = data)
#summary(basicOLS_UnweightedSpinoutCount_RDma3)
coeftest(basicOLS_UnweightedSpinoutCount_RDma3, vcov. = vcovHAC)

basicOLS_UnweightedSpinoutCount_RDma5 <- lm(spinoutCountUnweighted ~ xrd_ma5, data = data)
summary(basicOLS_UnweightedSpinoutCount_RDma5)
coeftest(basicOLS_UnweightedSpinoutCount_RDma5, vcov. = vcovHAC)

panelData <- pdata.frame(data, index = c("gvkey","year"))

# Run OLS with lags

OLS_lags <- plm(formula = spinoutCount ~ xrd + lag(xrd,1) + lag(xrd,2) + lag(xrd,3) + lag(xrd,4), data = panelData, effect = "time", model = "pooling", index = c("gvkey","year"))
summary(OLS_lags)

OLS_UnweightedSpinoutCount_lags <- plm(formula = spinoutCountUnweighted ~ xrd + lag(xrd,1) + lag(xrd,2), data = panelData, effect = "time", model = "pooling", index = c("gvkey","year"))
summary(OLS_UnweightedSpinoutCount_lags)
coeftest(OLS_UnweightedSpinoutCount_lags, vcov. = vcovHAC)

OLS_UnweightedSpinoutCount_lags_RDma3 <- plm(formula = spinoutCountUnweighted ~ xrd_ma3 + lag(xrd_ma3,1) + lag(xrd_ma3,2), data = panelData, effect = "time", model = "pooling", index = c("gvkey","year"))
summary(OLS_UnweightedSpinoutCount_lags_RDma3)

OLS_UnweightedSpinoutCount_lags_RDma5 <- plm(formula = spinoutCountUnweighted ~ xrd_ma5 + lag(xrd_ma5,1) + lag(xrd_ma5,2), data = panelData, effect = "time", model = "pooling", index = c("gvkey","year"))
summary(OLS_UnweightedSpinoutCount_lags_RDma5)

# Run OLS with firm fixed effects

firmFixedEffects <- plm(formula = spinoutCount ~ xrd, data = panelData, effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects)

firmFixedEffects_ma3 <- plm(formula = spinoutCount ~ xrd_ma3, data = panelData, effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects_ma3)

firmFixedEffects_ma5 <- plm(formula = spinoutCount ~ xrd_ma5, data = panelData, effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects_ma5)

firmFixedEffects_lags <- plm(formula = spinoutCount ~ xrd + lag(xrd,1) + lag(xrd,2), data = panelData, effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects_lags)

firmFixedEffects_UnweightedSpinoutCount <- plm(formula = spinoutCountUnweighted ~ xrd, data = panelData, 
                                               effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects_UnweightedSpinoutCount)

firmFixedEffects_UnweightedSpinoutCount_lags <- plm(formula = spinoutCountUnweighted ~ xrd + lag(xrd,1) + lag(xrd,2), data = panelData, 
                                                    effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects_UnweightedSpinoutCount_lags)

firmFixedEffects_UnweightedSpinoutCount_lags_ma3 <- plm(formula = spinoutCountUnweighted ~ xrd_ma3 + lag(xrd_ma3,1) + lag(xrd_ma3,2), data = panelData, 
                                                    effect = "twoways", model = "within", index = c("gvkey","year"))
summary(firmFixedEffects_UnweightedSpinoutCount_lags_ma3)


out <- duplicated(data, by = c("gvkey","year"))

summary(industryFixedEffects)

# Run OLS with industry-time fixed effects


summary(industryFixedEffects)

#### Analyses with spinout indicator

# Run logit regression to pre
logitModel <- glm(spinoutIndicator ~ xrd, data = data, family = "binomial")
summary(logitModel)








