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

#parentsSpinouts <- fread("data/parentsSpinouts.csv")
parentsSpinouts <- fread("data/parentsSpinoutsExits.csv")

parentsSpinouts[ , `:=` (snms = NULL, PreviousEmployer = NULL)]

parentsSpinouts <- parentsSpinouts[maxExit == 1]

startupData <- fread("raw/VentureSource/PU_Overview.csv")
startupData <- startupData[HQ == 1]
temp <- startupData
startupData <- startupData[ , .(EntityID,State,StartDate)]

setkey(startupData,EntityID)
setkey(parentsSpinouts,EntityID)

output <- startupData[parentsSpinouts]
output[ , foundingYear := year(mdy(StartDate))]

### Exits

exits <- fread("data/VentureSource/exits.csv")

startupLocations <- temp[ , .(EntityID,State)]

setkey(startupLocations,EntityID)
setkey(exits,EntityID)

exits <- startupLocations[exits][State != ""]








##### 
# Make plots
####

library(ggplot2)

#### Plot total entry per year of eventually VC-funded spinouts

temp[ , year := year(mdy(StartDate))]

totalCounts_allStartups <- temp[ , .N, by = "year"][order(year)]

ggplot(data = totalCounts_allStartups, aes(x = year, y = N)) + 
  geom_line() + 
  ggtitle("Number of eventually VC-funded startups spawned per year (color = state)") +
  xlim(1975,2019) + 
  ylab("# of Startups") + 
  xlab("Year")



# Plot state spinout counts by year


# By state of spin out

stateCounts <- output[ , sum(Weight), by = .(State,year)]

ggplot(data = stateCounts[State == "CA" | State == "NY" | State == "WA" | State == "MA"], aes(x = year, y = V1, group = State)) + 
  geom_line(aes(color = State)) +
  #theme(legend.position = "none") +
  ggtitle("Number of eventually VC-funded spinouts spawned per year (color = state)") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2018) +
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Year")

ggsave("code/plots/VCspawning_noFuzzy_CCEOandCTO.png", width = 16, height = 9, dpi = 100)

# By state of parent
stateCountsParents <- output[ , sum(Weight), by = .(state,year)]

ggplot(data = stateCountsParents, aes(x = year, y = V1, group = state)) + 
  geom_line(aes(color = state)) +
  #theme(legend.position = "none") +
  ggtitle("Number of eventually VC-funded spinouts spawned per year (color = state)") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2019) +
  #ylim(0,36) + 
  ylab("# of Spinouts") +
  xlab("Year")


#ggsave("code/plots/VCspawning_noFuzzy.png", width = 16, height = 9, dpi = 100)
ggsave("code/plots/VCspawning_noFuzzy_CCEOandCTO_parentFirmState.png", width = 16, height = 9, dpi = 100)

temp2 <- unique(output, by = c("EntityID"))
totalCounts <- temp2[ , .N, by = "year"][order(year)]

ggplot(data = totalCounts, aes(x = year, y = N)) + geom_line() + ggtitle("Number of eventually VC-funded spinouts spawned per year (all U.S.)") + 
    xlim(1975,2017) + 
    ylab("# of Spinouts") + 
    xlab("Year")

ggsave("code/plots/totalSpinoutsFoundedPerYear.png", width = 16, height = 9, dpi = 200)




## Finally, plot both regular startups and spinouts on same plot:

totalCounts[ , label := "Spinouts"]
totalCounts_allStartups[ , label := "Startups"]

totalCountsAll <- rbind(totalCounts,totalCounts_allStartups)

ggplot(data = totalCountsAll, aes(x = year, y = N, group = label)) + 
  geom_line(aes(color = label)) + 
  ggtitle("Number of VC-funded startups and spinouts") +
  xlim(1975,2019) + 
  ylab("# of Firms") + 
  xlab("Year") + 
  theme(text = element_text(size=20))

ggsave("code/plots/totalSpinoutsAndStartupsPerYear.png", width = 16, height = 9, dpi = 200)








#setkey(output,EntityID)
#setkey(spinoutData,EntityID)

#output <- output[spinoutData]



