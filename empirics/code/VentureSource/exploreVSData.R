setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")

rm(list = ls())

library(data.table)
library(lubridate)
library(gridExtra)

BDVI <- fread("raw/VentureSource/PrincetonBDVI.csv")
temp <- fread("raw/VentureSource/PrincetonEntrepCoSiteRevised.csv")

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

#output <- BDVI[ , min(pmin(year(ymd(JoinDate)), year(ymd(InputDate)) , na.rm = TRUE)) , by = EntityID]
output <- BDVI[ , min(year(ymd(JoinDate)), na.rm = TRUE) , by = EntityID]
#output <- BDVI[ , min(year(ymd(InputDate)), na.rm = TRUE) , by = EntityID]
output[ , FoundingYear := V1]
output[ , V1 := NULL]

temp <- temp[ , c("EntityID","State")]
setkey(temp,EntityID)
setkey(output,EntityID)

output <- output[temp]

# Count VC startups founded by state-year
output <- output[ , .(.N), by = .(State,FoundingYear)]
output <- output[order(State,FoundingYear)]

output <- output[ FoundingYear != Inf]

# Make some plots

library(ggplot2)

p1 <- ggplot(data = output[State == "NY"], aes(x = FoundingYear, y = N, group = State)) + 
  geom_line(aes(color = State)) +
  theme(legend.position = "none") +
  #ggtitle("Number of firms added by year (color = state)") +
  ggtitle("Unadjusted") + 
  xlim(1975,2018) +
  ylab("# Firms") +
  xlab("Year")

fundingLags <- fread("data/VentureSource/fundingLags.csv")

fundingLags[ , fundingLagYears := fundingLag/365]

cdf <- ecdf(as.numeric(na.omit(fundingLags[fundingLag > 0])$fundingLagYears))

output[ , adjustedN := N * (1/cdf(2019.3-FoundingYear))]

p2 <- ggplot(data = output, aes(x = FoundingYear, y = adjustedN, group = State)) + 
  geom_line(aes(color = State)) +
  theme(legend.position = "none") + 
  ggtitle("Adjusted") + 
  ylab("# Firms") + 
  xlab("Year") + 
  xlim(1975,2018)

grid.arrange(p1,p2, ncol = 1, top = "# Firms founded by year (color = state)")
g <- arrangeGrob(p1,p2,ncol = 1, top = "# Firms founded by year (color = state)")

ggsave(file = "code/VenturSource/plots/firmsFoundedByYearState.png", g, width = 16, height = 9, dpi = 100)

#output <- BDVI[ , min(pmin(year(ymd(JoinDate)), year(ymd(InputDate)) , na.rm = TRUE)) , by = EntityID]
#output <- BDVI[ , min(year(ymd(JoinDate)), na.rm = TRUE) , by = EntityID]
output <- BDVI[ , min(year(ymd(InputDate)), na.rm = TRUE) , by = EntityID]
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

output <- output[ FoundingYear != Inf]

p1 <- ggplot(data = output, aes(x = FoundingYear, y = N, group = State)) + 
  geom_line(aes(color = State)) +
  theme(legend.position = "none") +
  ggtitle("Number of firms added by year (color = state)") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2018) +
  ylab("# Firms") +
  xlab("Year")

ggsave("code/VentureSource/plots/firmsAddedByYearState.png", width = 16, height = 9, dpi = 100)

fwrite(output,"data/VentureSource/firmFoundingCountsbyStateYear.csv")


rm(list = ls())
data <- fread("raw/VentureSource/PrincetonDealDollarQuarter.csv")
data <- data[CompanyBackedBy == "VC"]
#data <- data[State != "CA"]
temp <- data[ , sum(na.omit(RaisedUSD)), by = c("State","Year") ]

ggplot(data = temp, aes(x = Year, y = V1, group = State)) + 
  geom_line(aes(color = State)) +
  theme(legend.position = "none") +
  ggtitle("Amount raised in VC-led deals (color = state)") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2019) +
  ylab("# Firms") +
  xlab("Year")

temp <- data[State == "NY"][ , .(q20 = quantile(RaisedUSD, probs = 0.2, na.rm = TRUE), 
                     q40 = quantile(RaisedUSD, probs = 0.4, na.rm = TRUE),
                     q60 = quantile(RaisedUSD, probs = 0.6, na.rm = TRUE),
                     q80 = quantile(RaisedUSD, probs = 0.8, na.rm = TRUE),
                     q90 = quantile(RaisedUSD, probs = 0.9, na.rm = TRUE)), by = c("Year")]

temp <- melt(temp, id.vars = c("Year"), 
             measure.vars = c("q20","q40","q60","q80","q90"))

setnames(temp, old = "variable", new = "quantile")

ggplot(data = temp, aes(x = Year, y = value, group = quantile)) + 
  geom_line(aes(color = quantile)) +
  #theme(legend.position = "none") +
  ggtitle("Quantiles of amount raised by deals by year") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2019) +
  ylab("USD ('000s)") +
  xlab("Year")


temp <- data[State == "NY"][ , .(q90 = quantile(RaisedUSD, probs = 0.9, na.rm = TRUE), 
                  q95 = quantile(RaisedUSD, probs = 0.95, na.rm = TRUE),
                  q98 = quantile(RaisedUSD, probs = 0.98, na.rm = TRUE),
                  q99 = quantile(RaisedUSD, probs = 0.99, na.rm = TRUE),
                  q995 = quantile(RaisedUSD, probs = 0.995, na.rm = TRUE),
                  q998 = quantile(RaisedUSD, probs = 0.998, na.rm = TRUE)), by = c("Year")]

temp <- melt(temp, id.vars = c("Year"), 
             measure.vars = c("q90","q95","q98","q99","q995","q998"))

setnames(temp, old = "variable", new = "quantile")

ggplot(data = temp, aes(x = Year, y = value, group = quantile)) + 
  geom_line(aes(color = quantile)) +
  #theme(legend.position = "none") +
  ggtitle("Quantiles of amount raised by deals by year") +
  #ggtitle("Unadjusted") + 
  xlim(1975,2019) +
  ylab("USD ('000s)") +
  xlab("Year")




