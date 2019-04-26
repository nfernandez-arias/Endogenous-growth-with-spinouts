setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/code/VentureSource")

rm(list = ls())

library(data.table)
#library(lubridate)

BDVI <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/VentureSource/PrincetonBDVI.csv")
temp <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/VentureSource/PrincetonEntrepCoSiteRevised.csv")

#revenue <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/VentureSource/PrincetonCoRevenueRevised.csv")

#deals <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/VentureSource/PrincetonDealDollarQuarter.csv")

#setkey(BDVI,EntityID)
#setkey(revenue,EntityID)

#data <- BDVI[revenue,allow.cartesian=TRUE]

#data <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/VentureSource/PrincetonEntrepAndInvestRevised.csv")

# Calculate Coverage

#data <- BDVI[Founder == 1]
#data <- unique(data, by = c("EntityID","JoinDate"))

# Calculate FoundingYear of EntityID: minimum of JoinDate and InputDate for all people associated with the firm.
# (Should be able to get an actual variable for founding date from VentureSource...it says in the Data Dictionary that there is one)

output <- BDVI[ , min(pmin(year(ymd(JoinDate)), year(ymd(InputDate)) , na.rm = TRUE)) , by = EntityID]
output[ , FoundingYear := V1]
output[ , V1 := NULL]
rm(BDVI)

temp <- temp[ , c("EntityID","State")]
setkey(temp,EntityID)
setkey(output,EntityID)

output <- output[temp]

# Count VC startups founded by state-year
output <- output[ , .(.N), by = .(State,FoundingYear)]
output <- output[order(State,FoundingYear)]

# Make some plots

library(ggplot2)

ggplot(data = output, aes(x = FoundingYear, y = N, group = State)) + 
  geom_line(aes(color = State)) +
  theme(legend.position = "none") + 
  xlim(1975,2019)





