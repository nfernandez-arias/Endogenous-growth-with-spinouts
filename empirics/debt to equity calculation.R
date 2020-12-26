
dat <- fread("raw/fred/NCBCMDPMVCE.csv")

setnames(dat,"NCBCMDPMVCE","debtToEquity")

dat[ , year := year(ymd(DATE))]

dat <- dat[ year >= 1984 & year <= 2006]

dat[ , debtToEquity := mean(as.numeric(debtToEquity)), by = year]

dat <- unique(dat, by = c("year"))[ , .(year,debtToEquity)]



averageDebtToEquity = dat[ , mean(as.numeric(debtToEquity))]

debtToValue = averageDebtToEquity / (100 + averageDebtToEquity)


debtToValue * 7.58 + (1-debtToValue) * 9.15


