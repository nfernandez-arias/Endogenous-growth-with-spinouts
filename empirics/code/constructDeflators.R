#------------------------------------------------#
#
# File name: constructDeflators.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This file constructs CPI deflators, productivity growth 
# deflators, and R&D price index deflators (could do more here)
#
#------------------------------------------------#

# GDP deflator
gdpDeflator <- fread("raw/deflators/gdpDeflator.csv")
names(gdpDeflator) <- c("year","gdpDeflator")
gdpDeflator[ , year := year(ymd(year))]
gdpDeflator[ , gdpDeflator := gdpDeflator / 100]
fwrite(gdpDeflator,"data/deflators/gdpDeflator.csv")

# CPI deflator
cpi <- fread("raw/deflators/cpi.csv")
setnames(cpi,"Year","year")
cpi[ , cpiInflation := Annual / Annual[year == 2012]]
cpi[ , Annual := NULL]
setnames(cpi,"cpiInflation","cpiDeflator")
setkey(cpi,year)
fwrite(cpi[ , .(year,cpiDeflator)],"data/deflators/cpiDeflator.csv")

# Private non-residential fixed investment deflator
investmentDeflator <- fread("raw/deflators/fixedinvestmentDeflator.csv")
names(investmentDeflator) <- c("year","investmentDeflator")
investmentDeflator[ , year := year(ymd(year))]
investmentDeflator[ , investmentDeflator := investmentDeflator / 100]
fwrite(investmentDeflator,"data/deflators/investmentDeflator.csv")

# R&D deflator
xrdPriceIndex <- fread("raw/deflators/rdPriceIndex.csv")
xrdPriceIndex[ , year := year(ymd(DATE))]
xrdPriceAnnual <- xrdPriceIndex[ , .(priceIndex = mean(priceIndex)), by = year]
xrdPriceAnnual[ , xrdInflation := priceIndex / priceIndex[year == 2012]]
xrdPriceAnnual[ , priceIndex := NULL]
setkey(xrdPriceAnnual,year)
setnames(xrdPriceAnnual,"xrdInflation","xrdDeflator")
fwrite(xrdPriceAnnual[ , .(year,xrdDeflator)], "data/deflators/xrdDeflator.csv")

# Cumulative productivity growth -- for deflating R&D
# relative to spinout and founder counts
# i.e. as productivity grows, need more REAL UNITS of R&D 
# to achieve same proportional innovation (requirement of balanced growth)

productivityGrowth <- fread("raw/deflators/productivityGrowth.csv")
productivityGrowth[ , Growth := 1 + Annual/100]
productivityGrowth[ , Annual := NULL]
productivityGrowth[ , cumGrowth := cumprod(Growth)]
productivityGrowth[ , growthFactor := cumGrowth / cumGrowth[Year == 2012]]
setnames(productivityGrowth,"Year","year")
setnames(productivityGrowth,"growthFactor","productivityDeflator")
setkey(productivityGrowth,year)

fwrite(productivityGrowth[ , .(year,productivityDeflator)],"data/deflators/productivityDeflator.csv")

# Clear data
rm(list = ls.str(mode = "list"))


