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

firmsTickers <- fread("code/firmsTickers.csv")

firmsTickers[, c("Exchange","Symbol") := tstrsplit(tickerSymbol,": ")]

firmsTickers <- firmsTickers[Symbol != "" & (Exchange == "NYSE" | Exchange == "NASDAQ" | Exchange == "NYSEARCA")]
#firmsTickers <- firmsTickers[Symbol != ""]

firmsTickers[, tickerSymbol := NULL]

setnames(firmsTickers,"Symbol","tic")
setnames(firmsTickers,"Firm Name","firmName")



fwrite(firmsTickers,"data/firmsTickersClean.csv")
          



