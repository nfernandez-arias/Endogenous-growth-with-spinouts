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


#firmsTickers <- fread("code/firmsTickers.csv")

firmsAltDG_1 <- fread("raw/AltDG/company_list_5000-2019-07-15.csv")
firmsAltDG_2 <- fread("raw/AltDG/company_list_10000-2019-07-21.csv")
firmsAltDG_3 <- fread("raw/AltDG/company_list_15000-2019-07-26.csv")
firmsAltDG_4 <- fread("raw/AltDG/company_list_20000-2019-08-10.csv")
firmsAltDG_5 <- fread("raw/AltDG/company_list_25000-2019-08-28.csv")
firmsAltDG_6 <- fread("raw/AltDG/company_list_30000-2019-08-29.csv")

#firmsAltDG <- rbind(firmsAltDG_1,firmsAltDG_2)
firmsAltDG <- rbind(firmsAltDG_1,firmsAltDG_2,firmsAltDG_3,firmsAltDG_4,firmsAltDG_5,firmsAltDG_6)

setnames(firmsAltDG,"Original Input","query")
setnames(firmsAltDG,"Company Name","companyName")

# Only keep results which have ticker symbol, since this is how I match back to Compustat
results <- firmsAltDG[Ticker != ""]

## Keep results (1) trading on US exchanges and (2) that are matched with > 90% confidence.
fwrite(results[(Exchange == "NYSE" | Exchange == "NASDAQ") & Confidence >= 0.9][ , .(query,companyName,Ticker)],"data/firmsTickersAltDG.csv")

# Clean up
rm(firmsAltDG,firmsAltDG_1,firmsAltDG_2,firmsAltDG_3,firmsAltDG_4,firmsAltDG_5,firmsAltDG_6,results)
