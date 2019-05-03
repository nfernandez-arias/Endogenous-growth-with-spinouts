#------------------------------------------------#
#
# File name: basicSpinoutAnalysis.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# (1) Add some data about spinouts and parent firms 
# (2) Present some basic descriptive spinout statistics
#------------------------------------------------#

rm(list = ls())
library(lubridate)

parentsSpinouts <- fread("data/parentsSpinouts.csv")

parentsSpinouts[ , `:=` (snms = NULL, PreviousEmployer = NULL)]
parentsSpinouts[ , year := year(ymd(JoinDate))]

parentsSpinouts[ , spinoutCount := sum(Weight), by = .(gvkey,year)]

spinoutData <- fread("raw/VentureSource/PU_Overview.csv")
spinoutData <- spinoutData[HQ == 1]
spinoutData <- spinoutData[ , .(EntityID,State)]

setkey(spinoutData,EntityID)
setkey(parentsSpinouts,EntityID)

output <- spinoutData[parentsSpinouts]

stateCounts <- output[ , sum(spinoutCount), by = .(State,year)]

library(ggplot2)

ggplot(data = stateCounts[State == "CA" | State == "NY" | State == "WA" | State == "MA" | State == ""], aes(x = year, y = V1, group = State)) + 
  geom_line(aes(color = State)) +
  #theme(legend.position = "none") +
  ggtitle("Number of eventually VC-funded spinouts spawned per year (color = state)") +
  #ggtitle("Unadjusted") + 
  #xlim(1975,2018) +
  #ylim(0,36) + 
  ylab("# of Spinouts") +
  xlab("Year")

ggsave("code/plots/VCspawning_noFuzzy.png", width = 16, height = 9, dpi = 100)

compustat <- fread("raw/compustat/compustat_annual.csv")

compustatData <- compustat[, .(gvkey,state,fyear,xrd,naics,sic)]

setkey(compustatData,gvkey,fyear)
setkey(parentsSpinouts,gvkey,year)

output <- compustatData[parentsSpinouts]

stateCounts <- output[ , sum(spinoutCount), by = .(state,fyear)]



# Plot state spinout counts by year

library(ggplot2)

ggplot(data = stateCounts, aes(x = fyear, y = V1, group = state)) + 
  geom_line(aes(color = state)) +
  theme(legend.position = "none") +
  ggtitle("Number of eventually VC-funded spinouts spawned per year (color = state)") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2019) +
  #ylim(0,36) + 
  ylab("# of Spinouts") +
  xlab("Year")

#ggsave("code/plots/VCspawning_noFuzzy.png", width = 16, height = 9, dpi = 100)
ggsave("code/plots/VCspawning_noFuzzy_parentFirmState.png", width = 16, height = 9, dpi = 100)




setkey(output,EntityID)
setkey(spinoutData,EntityID)

output <- output[spinoutData]



