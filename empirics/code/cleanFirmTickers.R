#------------------------------------------------#
#
# File name: cleanFirmTickers.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script clean firmsTickers.csv, the output
# of the Google Scrape
#------------------------------------------------

rm(list = ls())

#firmsTickers <- fread("code/firmsTickers.csv")

firmsAltDG_1 <- fread("code/company_list_5000-2019-07-15.csv")
firmsAltDG_2 <- fread("code/company_list_10000-2019-07-21.csv")

firmsAltDG <- rbind(firmsAltDG_1,firmsAltDG_2)

setnames(firmsAltDG,"Original Input","query")
setnames(firmsAltDG,"Company Name","companyName")

#results <- firmsAltDG[ , .(query,companyName,Confidence,Ticker,Exchange)][Ticker != ""]
results <- firmsAltDG[Ticker != ""]

fwrite(results[(Exchange == "NYSE" | Exchange == "NASDAQ") & Confidence >= 0.8][ , .(query,companyName,Ticker)],"data/firmsTickersAltDG.csv")

#temp <- results[Confidence >= 0.5][order(Confidence)]

fwrite(firmsTickers,"data/firmsTickersClean.csv")

firmsTickers[, c("Exchange","Symbol") := tstrsplit(tickerSymbol,": ")]

firmsTickers <- firmsTickers[Symbol != "" & (Exchange == "NYSE" | Exchange == "NASDAQ" | Exchange == "NYSEARCA")]
#firmsTickers <- firmsTickers[Symbol != ""]

firmsTickers[, tickerSymbol := NULL]

setnames(firmsTickers,"Symbol","tic")
setnames(firmsTickers,"Firm Name","firmName")



fwrite(firmsTickers,"data/firmsTickersClean.csv")
          



