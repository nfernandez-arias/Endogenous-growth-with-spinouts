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
library(data.table)
library(ggplot2)

data <- fread("data/compustat-spinouts.csv")

# Set NA xrd values to zero 
data[is.na(xrd) == TRUE, xrd := 0]

# Construct indicator for whether any spinouts are formed
data[, spinoutIndicator := factor(spinoutCount >= 1)]

# Ignore compustat firms that never record R&D
data <- data[, if(max(na.omit(xrd)) > 0) .SD, by = gvkey]

# Ignore compustat firms that never have spinouts?
data <- data[, if(max(na.omit(spinoutCount)) >0) .SD, by = gvkey]

# Construct 4-digit NAICS codes
data[, naics4 := substr(naics,1,4)]
data[, naics3 := substr(naics,1,3)]
data[, naics2 := substr(naics,1,2)]
data[, naics1 := substr(naics,1,1)]

# Sort data
data <- data[order(gvkey,year)]


#### Analyses with spinout counts

# Construct scatter plot of R&D spending and spinout formation
ggplot(data, aes(x = xrd, y = spinoutCount, color = naics1)) +
  geom_point() + 
  geom_smooth(method = "lm", formula = y ~ poly(x,1), se = TRUE, fullrange =TRUE)

# Run OLS - no fixed effects lags of R&D spending
basicOLS <- lm(spinoutCount ~ xrd, data = data)
summary(basicOLS)

# Run OLS with industry fixed effects

industryFixedEffects <- plm(formula = spinoutCount ~ xrd, data = data, effect = "twoways", model = "within", index = "naics1")

summary(industryFixedEffects)

#### Analyses with spinout indicator

# Run logit regression to pre
logitModel <- glm(spinoutIndicator ~ xrd, data = data, family = "binomial")
summary(logitModel)








