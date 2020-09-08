

dat <- fread("data/compustat-spinouts_Stata.csv")[ , .(gvkey,naics1,naics2,naics3,naics4,year,firmAge,emp)][!is.na(naics3) & !is.na(naics2)] 

dat <- dat[ naics1 %in% c("3","5")]


dat[ firmAge <= 6, newFirm := 1]
dat[ is.na(newFirm), newFirm := 0]

industryEntryRates <- dat[ , .(entryRate = sum(newFirm) / .N, empRate = sum(na.omit(emp * newFirm)) / sum(na.omit(emp)), numFirms = .N), by = .(naics2,year)]
industryEntryRates[ , numFirms := sum(numFirms), by = naics2]

industryEntryRates_1dig <- dat[ , .(entryRate = sum(newFirm) / .N, empRate = sum(na.omit(emp * newFirm)) / sum(na.omit(emp)), numFirms = .N), by = .(naics1,year)]
industryEntryRates_1dig[ , numFirms := sum(numFirms), by = naics1]

industryEntryRates_3dig <- dat[ , .(entryRate = sum(newFirm) / .N, empRate = sum(na.omit(emp * newFirm)) / sum(na.omit(emp)), numFirms = .N), by = .(naics3,year)]
industryEntryRates_3dig[ , numFirms := sum(numFirms), by = naics3]

industryEntryRates_4dig <- dat[ , .(entryRate = sum(newFirm) / .N, empRate = sum(na.omit(emp * newFirm)) / sum(na.omit(emp)), numFirms = .N), by = .(naics4,year)]
industryEntryRates_4dig[ , numFirms := sum(numFirms), by = naics4]

ggplot(industryEntryRates_4dig[numFirms >= 1000], aes(x = year, y = empRate)) + 
  geom_line() + 
  facet_wrap( ~naics4)
  
ggplot(industryEntryRates_3dig[year >= 1986], aes(x = year, y = empRate)) + 
  geom_line() + 
  facet_wrap( ~naics3)

ggplot(industryEntryRates[year >= 1986], aes(x = year, y = empRate)) + 
  geom_line() + 
  facet_wrap( ~naics2)

ggplot(industryEntryRates_1dig[year >= 1986], aes(x = year, y = entryRate)) + 
  geom_line() + 
  facet_wrap( ~naics1)

