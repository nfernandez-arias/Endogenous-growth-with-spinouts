#-----------------------------------#
# 
# filename: compareSpinoutsToEntrants.R
#
# This file does calcluations / constructs some plots
# to get a picture of the data
#
#-----------------------------------#

rm(list = ls())

parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")

#-------------------------#
# Preliminaries
#-------------------------#

# Compute number of founders who are from parent firms in data set
parentsSpinouts[ , numSpinoutFounders := .N, by = "EntityID"]

# Valuation at first funding event
# (from code/constructSpinoutAttributes.R)
firstFundings <- fread("data/VentureSource/firstFundingEvents.csv")[ , .(EntityID,discountedFFValue,foundingYear)]

# Number of founders for each startup
# (from code/constructSpinoutAttributes.R)
EntitiesNumFounders <- fread("data/VentureSource/EntitiesNumFounders.csv")

#-------------------------#
# Construct a flag for a spinout being within-industry if 
# at least one founder came from parent in same industry
#-------------------------#

for (i in 1:6)
{
  wsoFlag <- paste("wso",i,sep = "")
  parentsSpinouts[ , (wsoFlag) := max(get(wsoFlag)), by = EntityID]
}

# Only take one record per EntityID - 
# just need to be able to flag that
# it is a spinout in the later calculations
parentsSpinouts <- unique(parentsSpinouts, by = "EntityID")[, .(gvkey,EntityID,numSpinoutFounders,wso1,wso2,wso3,wso4)][ foundingYear >= 1986 & foundingYear <= 2018]

# Merge funding information with parent firm - spinout link
setkey(firstFundings,EntityID)
setkey(parentsSpinouts,EntityID)
parentsSpinoutsFF <- parentsSpinouts[firstFundings]

parentsSpinoutsFF <- parentsSpinoutsFF[!is.na(foundingYear)]

# Label spinouts and non-spinouts
parentsSpinoutsFF[!is.na(gvkey) , isSpinout := 1]
parentsSpinoutsFF[is.na(isSpinout), isSpinout := 0]

# Replace NA values with zero
parentsSpinoutsFF[ is.na(discountedFFValue), discountedFFValue := 0]

#--------------------------------#
#
# Compute first funding value of spinouts vs regular entrants
#
#--------------------------------#

# First, construct indicators wso4 spinouts and wso spinout

# spinout vs non-spinout
parentsSpinoutsFF[ isSpinout == 0, nonSpinout := 1]
parentsSpinoutsFF[ is.na(nonSpinout) , nonSpinout := 0] 

# any WSO vs. non-WSO
parentsSpinoutsFF[ wso1 + wso2 + wso3 + wso4 == 0 & isSpinout == 1, nonwsoSpinout := 1]
parentsSpinoutsFF[ is.na(nonwsoSpinout), nonwsoSpinout := 0]

# wso4 vs non-wso4
parentsSpinoutsFF[ wso4 == 0 & isSpinout == 1, nonwso4Spinout := 1]
parentsSpinoutsFF[ is.na(nonwso4Spinout) , nonwso4Spinout := 0]

## Merge with information on number of founders at each startup (founder meaning CTO,CEO,President,Chairman,or "Founder")

setkey(parentsSpinoutsFF,EntityID)
setkey(EntitiesNumFounders,EntityID)

parentsSpinoutsFF <- EntitiesNumFounders[parentsSpinoutsFF]
parentsSpinoutsFF[ , fracSpinoutFounders := numSpinoutFounders / numFounders]

#parentsSpinoutsFF[ nonSpinout == 1, `:=` (wso1 = 0, wso2 = 0, wso3 = 0, wso4 = 0, nonwso4Spinout = 0, nonwsoSpinout = 0)]

## Construct counts

# First do founder weighted measures 

spinoutCounts <- parentsSpinoutsFF[ , .(wso1 = sum(na.omit(fracSpinoutFounders * wso1)) , wso2 = sum(na.omit(fracSpinoutFounders * wso2)) ,
                                        wso3 = sum(na.omit(fracSpinoutFounders * wso3)) , wso4 = sum(na.omit(fracSpinoutFounders * wso4)) , 
                                        nonwso = sum(na.omit(fracSpinoutFounders * nonwsoSpinout)), nonwso4 = sum(na.omit(fracSpinoutFounders *nonwso4Spinout)), 
                                        nonspinout = .N - sum(na.omit(fracSpinoutFounders * wso1)) - sum(na.omit(fracSpinoutFounders * nonwsoSpinout))) , by = "foundingYear" ]


founderCounts <- parentsSpinoutsFF[ , .(wso1 = sum(na.omit(numSpinoutFounders * wso1)) , wso2 = sum(na.omit(numSpinoutFounders * wso2)) ,
                                        wso3 = sum(na.omit(numSpinoutFounders * wso3)) , wso4 = sum(na.omit(numSpinoutFounders * wso4)) , 
                                        nonwso = sum(na.omit(numSpinoutFounders * nonwsoSpinout)), nonwso4 = sum(na.omit(numSpinoutFounders * nonwso4Spinout)), 
                                        allspinout = sum(na.omit(numSpinoutFounders * wso1)) + sum(na.omit(numSpinoutFounders * nonwsoSpinout)),
                                        nonspinout = sum(na.omit(numFounders)) - sum(na.omit(numSpinoutFounders * wso1)) - sum(na.omit(numSpinoutFounders * nonwsoSpinout)) ) , by = "foundingYear" ]


dffv <- parentsSpinoutsFF[ , .(wso1 = sum(na.omit(fracSpinoutFounders * discountedFFValue * wso1)) , wso2 = sum(na.omit(fracSpinoutFounders * discountedFFValue * wso2)) ,
                               wso3 = sum(na.omit(fracSpinoutFounders * discountedFFValue * wso3)) , wso4 = sum(na.omit(fracSpinoutFounders * discountedFFValue * wso4)) , 
                               nonwso = sum(na.omit(fracSpinoutFounders * discountedFFValue * nonwsoSpinout)),  nonwso4 = sum(na.omit(fracSpinoutFounders * discountedFFValue * nonwso4Spinout)),
                               allspinout = sum(na.omit(fracSpinoutFounders * discountedFFValue * wso1)) + sum(na.omit(fracSpinoutFounders * discountedFFValue * nonwsoSpinout)),
                               nonspinout = sum(na.omit(discountedFFValue)) - sum(na.omit(fracSpinoutFounders * discountedFFValue * wso1)) - sum(na.omit(fracSpinoutFounders * discountedFFValue * nonwsoSpinout))) , by = "foundingYear" ]


# Now do measures that are not founder-weighted

spinoutCounts_unweighted <- parentsSpinoutsFF[ , .(wso1 = sum(na.omit(wso1)) , wso2 = sum(na.omit(wso2)) ,
                       wso3 = sum(na.omit(wso3)) , wso4 = sum(na.omit(wso4)) , 
                       nonwso = sum(na.omit(nonwsoSpinout)), nonwso4 = sum(na.omit(nonwso4Spinout)), 
                       allspinout = sum(na.omit(wso1)) + sum(na.omit(nonwsoSpinout)),
                       nonspinout = .N - sum(na.omit(wso1)) - sum(na.omit(nonwsoSpinout))) , by = "foundingYear" ]

dffv_unweighted <- parentsSpinoutsFF[ , .(wso1 = sum(na.omit(discountedFFValue * wso1)) , wso2 = sum(na.omit(discountedFFValue * wso2)) ,
                               wso3 = sum(na.omit(discountedFFValue * wso3)) , wso4 = sum(na.omit(discountedFFValue * wso4)) , 
                               nonwso = sum(na.omit(discountedFFValue * nonwsoSpinout)), nonwso4 = sum(na.omit(discountedFFValue * nonwso4Spinout)), 
                               allspinout = sum(na.omit(discountedFFValue * wso1)) + sum(na.omit(discountedFFValue * nonwsoSpinout)),
                               nonspinout = sum(na.omit(discountedFFValue * nonSpinout))), by = "foundingYear" ]



### First compute some statistics (easier in wide format)

avg_countRatio_weighted <- spinoutCounts[ , mean(na.omit((wso1 + nonwso) / nonspinout)) ]
avg_countRatio_unweighted <- spinoutCounts_unweighted[ , mean((wso1 + nonwso) / nonspinout) ]
avg_countRatio_wso4_weighted <- spinoutCounts[ , mean((wso4) / nonspinout) ]
avg_countRatio_wso4_unweighted <- spinoutCounts_unweighted[ , mean((wso4) / nonspinout) ]
    
avg_founderRatio <- founderCounts[ , mean( (wso1 + nonwso) / nonspinout)]

avg_dffvRatio_weighted <- dffv[ , mean((wso1 + nonwso) / nonspinout)]
avg_dffvRatio_unweighted <- dffv_unweighted[ , mean((wso1 + nonwso) / nonspinout)]

# Also compute ratio of sums

allCounts_ratio_weighted <- spinoutCounts[ , sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]
allCounts_ratio_unweighted <- spinoutCounts_unweighted[ , sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso4_weighted <- spinoutCounts[ , sum(na.omit(wso4)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso4_unweighted <- spinoutCounts_unweighted[ , sum(na.omit(wso4)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso3_weighted <- spinoutCounts[ , sum(na.omit(wso3)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso3_unweighted <- spinoutCounts_unweighted[ , sum(na.omit(wso3)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso2_weighted <- spinoutCounts[ , sum(na.omit(wso2)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso2_unweighted <- spinoutCounts_unweighted[ , sum(na.omit(wso2)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso1_weighted <- spinoutCounts[ , sum(na.omit(wso1)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso1_unweighted <- spinoutCounts_unweighted[ , sum(na.omit(wso1)) / sum(na.omit(nonspinout))]

allCounts_ratio_weighted <- spinoutCounts[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]
allCounts_ratio_unweighted <- spinoutCounts_unweighted[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso4_weighted <- spinoutCounts[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso4)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso4_unweighted <- spinoutCounts_unweighted[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso4)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso3_weighted <- spinoutCounts[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso3)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso3_unweighted <- spinoutCounts_unweighted[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso3)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso2_weighted <- spinoutCounts[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso2)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso2_unweighted <- spinoutCounts_unweighted[foundingYear >= 1986 & foundingYear <= 2008 , sum(na.omit(wso2)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso1_weighted <- spinoutCounts[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso1)) / sum(na.omit(nonspinout))]
allCounts_ratio_wso1_unweighted <- spinoutCounts_unweighted[ foundingYear >= 1986 & foundingYear <= 2008, sum(na.omit(wso1)) / sum(na.omit(nonspinout))]

allFounders_ratio <- founderCounts[ , sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]
  
allDFFV_ratio <- dffv[ , sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]
allDFFV_ratio_unweighted <- dffv_unweighted[ , sum(na.omit(wso1 + nonwso)) / sum(na.omit(nonspinout))]

###  Melt datasets to long form for plotting with ggplot

spinoutCounts <- melt(spinoutCounts, id.vars = "foundingYear", measure.vars = c("wso1","wso2","wso3","wso4","nonwso","nonwso4","nonspinout"))
founderCounts <- melt(founderCounts, id.vars = "foundingYear", measure.vars = c("wso1","wso2","wso3","wso4","nonwso","nonwso4","allspinout","nonspinout"))
dffv <- melt(dffv, id.vars = "foundingYear", measure.vars = c("wso1","wso2","wso3","wso4","nonwso","nonwso4","nonspinout"))
spinoutCounts_unweighted <- melt(spinoutCounts_unweighted, id.vars = "foundingYear", measure.vars = c("wso1","wso2","wso3","wso4","nonwso","nonwso4","allspinout","nonspinout"))
dffv_unweighted <- melt(dffv_unweighted, id.vars = "foundingYear", measure.vars = c("wso1","wso2","wso3","wso4","nonwso","nonwso4","nonspinout"))
## Make plots

library(ggplot2)
library(RColorBrewer)

my_palette <- brewer.pal(name="Blues",n=8)[4:9]

# First make plot of counts of spinouts, unweighted, wso1, nonwso, and nonspinouts, stacked up

ggplot(data = spinoutCounts_unweighted[ variable == "nonspinout" | variable == "wso4" | variable == "nonwso4"], aes(x = foundingYear, y = value, fill = variable)) + 
  geom_area(position = "stack") +
  #scale_fill_manual(values = my_palette) + 
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("Firm counts") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2015) + 
  ylab("Number of firms") +
  xlab("Founding Year")

ggsave("../figures/spinouts_entrants_counts.png", plot = last_plot())

# Next make plot of founders

ggplot(data = founderCounts[ variable == "nonspinout" | variable == "wso4" | variable == "nonwso4"], aes(x = foundingYear, y = value, fill = variable)) + 
  geom_area(position = "stack") +
  scale_fill_manual(values = my_palette) + 
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("Founder counts") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2015) + 
  ylab("Number of founders") +
  xlab("Founding Year")

ggsave("../figures/spinout_entrant_founderCounts.png", plot = last_plot())

# Next make plot of founder-weighted spinouts

ggplot(data = spinoutCounts[ variable == "nonspinout" | variable == "wso4" | variable == "nonwso4"], aes(x = foundingYear, y = value, fill = variable)) + 
  geom_area(position = "stack") +
  scale_fill_manual(values = my_palette) + 
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("Firm counts (weighted)") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2008) + 
  ylab("Number of firms") +
  xlab("Founding Year")

ggsave("../figures/spinouts_entrants_weightedcounts.png", plot = last_plot())


ggplot(data = dffv[variable == "nonspinout" | variable == "wso4" | variable == "nonwso4"], aes(x = foundingYear, y = value, fill = variable)) + 
  geom_area(position = "stack") +
  scale_fill_manual(values = my_palette) + 
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("DFFV (weighted)") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2015) + 
  ylab("DFFV") +
  xlab("Founding Year")

ggsave("../figures/spinouts_entrants_DFFV.png", plot = last_plot())


# Compute ratio of spinouts to non-spinouts in sample

spinoutsNonSpinoutsRatio <- year_spinoutsEntrantsCounts[foundingYear >= 1986 & foundingYear <= 2008][ , sum(Spinout) / sum(nonSpinout)]
spinoutsNonSpinoutDFFVsRatio <- year_spinoutsEntrantsFFValue[foundingYear >= 1986 & foundingYear <= 2008][ , sum(Spinout) / sum(nonSpinout)]

setkey(year_spinoutsEntrantsCounts,foundingYear)
setkey(year_spinoutsEntrantsFFValue,foundingYear)

out <- year_spinoutsEntrantsCounts[ , .(foundingYear,countRatio)][year_spinoutsEntrantsFFValue[, .(foundingYear,FFValueRatio)]]

## Compute avearage ratios of spinouts to non-spinouts

averageCountRatio <- out[ foundingYear >= 1986 & foundingYear <= 2008, mean(na.omit(countRatio))]
averageFFValueRatio <- out[ foundingYear >= 1986 & foundingYear <= 2008, mean(na.omit(FFValueRatio))]

out <- melt(out, id.vars = c("foundingYear"), measure.vars = c("countRatio","FFValueRatio"))

ggplot(data = out, aes(x = foundingYear, y = value, group = variable, color = as.factor(variable))) + 
  geom_line() +
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("Ratio of spinouts to non-spinouts") +
  #ggtitle("Unadjusted") +
  xlim(1986,2008) + 
  ylim(0,2) + 
  ylab("Ratio (FFValue or Counts)") +
  xlab("Year")

ggsave("../figures/spinouts_entrants_ratio.png")

# Compute spinouts generated by R&D according to fixed effect regression results

compustat <- fread("raw/compustat/compustat_annual.csv")
compustat <- compustat[indfmt=="INDL" & datafmt=="STD" & popsrc=="D" & consol=="C"]
compustat <- compustat[ , .(gvkey,fyear,datadate,state,xrd,emp,revt,intan,act,sic,naics)]
compustat <- compustat[!is.na(fyear)]

compustat[ is.na(xrd), xrd := 0]
xrdGeneratedSpinouts <- compustat[ , .(xrd = sum(xrd)), by = "fyear"]

xrdPriceIndex <- fread("raw/rdPriceIndex.csv")
xrdPriceIndex[ , year := year(ymd(DATE))]
xrdPriceAnnual <- xrdPriceIndex[ , .(priceIndex = mean(priceIndex)), by = year]
xrdPriceAnnual[ , xrdInflation := priceIndex / priceIndex[year == 2012]]
xrdPriceAnnual[ , priceIndex := NULL]
setkey(xrdPriceAnnual,year)
setkey(xrdGeneratedSpinouts,fyear)
xrdGeneratedSpinouts <- xrdPriceAnnual[xrdGeneratedSpinouts]
xrdGeneratedSpinouts[ , xrd := xrd / xrdInflation]

productivityGrowth <- fread("raw/productivityGrowth.csv")
productivityGrowth[ , Growth := 1 + Annual/100]
productivityGrowth[ , Annual := NULL]
productivityGrowth[ , cumGrowth := cumprod(Growth)]
productivityGrowth[ , growthFactor := cumGrowth / cumGrowth[Year == 2012]]
setkey(productivityGrowth,Year)
xrdGeneratedSpinouts <- productivityGrowth[xrdGeneratedSpinouts]
xrdGeneratedSpinouts[ , xrd := xrd / growthFactor ]


cpi <- fread("raw/cpi.csv")
setnames(cpi,"Year","year")
cpi[ , cpiInflation := Annual / Annual[year == 2012]]
cpi[ , Annual := NULL]

setkey(cpi,year)
dffv <- cpi[dffv]
dffv_unweighted <- cpi[dffv_unweighted]

dffv[ , value := value / cpiInflation]
dffv_unweighted[ , value := value / cpiInflation]


# For now hard coded from OLS regression results

xrdGeneratedSpinouts[ , spinoutsGenerated := 0.000302 * xrd]
xrdGeneratedSpinouts[ , spinoutsGenerated_low := (0.000302 + 0.000099) * xrd]
xrdGeneratedSpinouts[ , spinoutsGenerated_high := (0.000302 - 0.000099) * xrd] 
xrdGeneratedSpinouts[ , spinoutwsosGenerated := 0.000123 * xrd]
xrdGeneratedSpinouts[ , spinoutwsosGenerated_low := (0.000123 + 0.000029) * xrd]
xrdGeneratedSpinouts[ , spinoutwsosGenerated_high := (0.000123 - 0.000029) * xrd] 
#xrdGeneratedSpinouts[ , foundersGenerated := 0.001061 * xrd]
#xrdGeneratedSpinouts[ , foundersGenerated_low := (0.001061 + 0.000384) * xrd]
#xrdGeneratedSpinouts[ , foundersGenerated_high := (0.001061 - 0.000384) * xrd]

setkey(xrdGeneratedSpinouts,Year)



###  Construct graph showing fraction of spnouts due to R&D suggested by the micro estimates

# First need to reshape to wide
spinoutCounts_unweighted <- dcast(spinoutCounts_unweighted, foundingYear ~ variable, value.var = "value")
founderCounts <- dcast(founderCounts, foundingYear ~ variable, value.var = "value")

setkey(spinoutCounts_unweighted,foundingYear)
setkey(founderCounts,foundingYear)

countsComparison <- xrdGeneratedSpinouts[spinoutCounts_unweighted][ , .(Year,spinoutsGenerated,spinoutsGenerated_low,spinoutsGenerated_high,allspinout)]
countsWSOComparison <- xrdGeneratedSpinouts[spinoutCounts_unweighted][ , .(Year,spinoutwsosGenerated,spinoutwsosGenerated_low,spinoutwsosGenerated_high,wso4)]
#foundersComparison <- xrdGeneratedSpinouts[founderCounts][ , .(Year,foundersGenerated,foundersGenerated_low,foundersGenerated_high,allspinout)]

## Compute statistics for calibration

rd_ratioAverageCounts <- countsComparison[ Year >= 1986 & Year <= 2008 , sum(spinoutsGenerated) / sum(allspinout)]

rd_ratioAverageFounders <- foundersComparison[ Year >= 1986 & Year <= 2008, sum(foundersGenerated) / sum(allspinout)]

# Reshape wide to long for plotting with ggplot

countsComparison <- melt(countsComparison, id.vars = "Year", measure.vars = c("spinoutsGenerated","spinoutsGenerated_low","spinoutsGenerated_high","allspinout"))
countsWSOComparison <- melt(countsWSOComparison, id.vars = "Year", measure.vars = c("spinoutwsosGenerated","spinoutwsosGenerated_low","spinoutwsosGenerated_high","wso4"))
foundersComparison <- melt(foundersComparison, id.vars = "Year", measure.vars = c("foundersGenerated","foundersGenerated_low","foundersGenerated_high","allspinout"))


## Make plotss

my_palette2 <- brewer.pal(name="Blues",n=8)[4:9]

ggplot(data = foundersComparison, aes(x = Year, y = value, group = variable, color = variable)) + 
  geom_line(size = 2) +
  scale_color_manual(values = my_palette2) +
  theme(text = element_text(size=14)) +
  #theme(legend.position = "none") +
  ggtitle("Founders (actual vs. regression prediction)") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2009) + 
  ylab("Number of founders") +
  xlab("Year")

ggsave("../figures/foundersComparison.png", plot = last_plot())
  
ggplot(data = countsComparison, aes(x = Year, y = value, group = variable, color = variable)) + 
  geom_line(size = 2) +
  scale_color_manual(values = my_palette2) +
  theme(text = element_text(size=14)) +
  #theme(legend.position = "none") +
  ggtitle("Number of spinouts (actual vs. regression prediction)") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2009) + 
  ylab("# of Spinouts") +
  xlab("Year")

ggsave("../figures/countsComparison.png", plot = last_plot())

ggplot(data = countsWSOComparison, aes(x = Year, y = value, group = variable, color = variable)) + 
  geom_line(size = 2) +
  scale_color_manual(values = my_palette2) +
  theme(text = element_text(size=14)) +
  #theme(legend.position = "none") +
  ggtitle("Number of WSOs (actual vs. regression prediction)") +
  #ggtitle("Unadjusted") + 
  xlim(1986,2009) + 
  ylab("# of Spinouts") +
  xlab("Year")

ggsave("../figures/countsWSOComparison.png", plot = last_plot())
  
  
  
    ### Compute relative outcomes of spinouts and entrants

# Load weighted histogram function from Weights package
  
rm(list = ls())  

wtd.hist <- weights::wtd.hist

    
StartupStats <- fread("data/VentureSource/startupOutcomes.csv")
setnames(StartupStats,"State","startupState")

parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")[,.(gvkey,state,EntityID,wso4)]

parentsSpinouts[ , wso4 := max(wso4), by = EntityID]

# Construct flag for spinouts
parentsSpinouts[ , isSpinout := 1]

# Merge with Startup stats
setkey(parentsSpinouts,EntityID)
setkey(StartupStats,EntityID)

StartupStats <- parentsSpinouts[StartupStats]

StartupStats[ is.na(isSpinout), isSpinout := 0]

# Compute counts by industry, for weighting histograms
startupCounts <- StartupStats[ , .N , by = IndustryCodeDesc]
setkey(startupCounts,IndustryCodeDesc)

## Compute fraction of spinouts and non-spinouts that go from non-revenue generating to revenue generating

startupToRevenue_all <- StartupStats[ , sum(genRevenue) / .N , by = .(isSpinout,wso4,noRevenue)][ noRevenue == 1]
startupToProfitable_all <- StartupStats[ , sum(profitable) / .N , by = .(isSpinout,wso4,noRevenue)][ noRevenue == 1]
startupToExit_all <- StartupStats[ , sum(maxExit) / .N , by = .(isSpinout,wso4,noRevenue)][ noRevenue == 1]
revenueToProfitable_all <- StartupStats[ , sum(profitable) / .N , by = .(isSpinout,wso4,genRevenue)][ genRevenue == 1]

startupToRevenue <- StartupStats[ , sum(genRevenue) / .N , by = .(IndustryCodeDesc,isSpinout,noRevenue)][ noRevenue == 1][order(IndustryCodeDesc,isSpinout)]
#startupToRevenue <- StartupStats[ , sum(genRevenue) / .N , by = .(isSpinout,noRevenue)][ noRevenue == 1][order(isSpinout)]
startupToRevenue[ isSpinout == 1, type := "spinout"]
startupToRevenue[ isSpinout == 0, type := "nonSpinout"]
startupToRevenueRatios <- dcast(startupToRevenue, IndustryCodeDesc ~ type, value.var = "V1")
startupToRevenueRatios[ , ratio := spinout / nonSpinout] 
setkey(startupToRevenueRatios,IndustryCodeDesc)
startupToRevenueRatios <- startupCounts[startupToRevenueRatios]
wtd.hist(startupToRevenueRatios$ratio , breaks = 100,weight = startupToRevenueRatios$N, xlim = c(0,3))


  
startupToProfitable <- StartupStats[ , sum(profitable) / .N , by = .(IndustryCodeDesc,isSpinout,noRevenue)][ noRevenue == 1][order(IndustryCodeDesc,isSpinout)]
startupToProfitable[ isSpinout == 1, type := "spinout"]
startupToProfitable[ isSpinout == 0, type := "nonSpinout"]
startupToProfitableRatios <- dcast(startupToProfitable, IndustryCodeDesc ~ type, value.var = "V1")
startupToProfitableRatios[ , ratio := spinout / nonSpinout]
setkey(startupToProfitableRatios,IndustryCodeDesc)
startupToProfitableRatios <- startupCounts[startupToProfitableRatios]
wtd.hist(startupToProfitableRatios$ratio , breaks = 100, weight = startupToProfitableRatios$N , xlim = c(0,5))





revenueToProfitable <- StartupStats[ , sum(profitable) / .N, by = .(IndustryCodeDesc,isSpinout,genRevenue)][ genRevenue == 1][order(IndustryCodeDesc,isSpinout)]
revenueToProfitable[ isSpinout == 1, type := "spinout"]
revenueToProfitable[ isSpinout == 0, type := "nonSpinout"]
revenueToProfitableRatios <- dcast(revenueToProfitable, IndustryCodeDesc ~ type, value.var = "V1")
revenueToProfitableRatios[ , ratio := spinout / nonSpinout]
setkey(revenueToProfitableRatios,IndustryCodeDesc)
revenueToProfitableRatios <- startupCounts[revenueToProfitableRatios]
wtd.hist(revenueToProfitableRatios$ratio , breaks = 100, weight = revenueToProfitableRatios$N, xlim = c(0,5))



allToProfitable <- StartupStats[ , sum(profitable) / .N, by = .(IndustryCodeDesc,isSpinout)]
allToProfitable[ isSpinout == 1, type := "spinout"]
allToProfitable[ isSpinout == 0, type := "nonSpinout"]
allToProfitableRatios <- dcast(allToProfitable, IndustryCodeDesc ~ type, value.var = "V1")
allToProfitableRatios[ , ratio := spinout / nonSpinout]
setkey(allToProfitableRatios,IndustryCodeDesc)
allToProfitableRatios <- startupCounts[allToProfitableRatios]
wtd.hist(allToProfitableRatios$ratio , breaks = 100, weight = allToProfitableRatios$N, xlim = c(0,5))






















bdsData <- fread("raw/bds/bds_f_age_release.csv")
yearStartupsFirms <- bdsData[ , .( allFirms = sum(Firms), startups = Firms[fage4 == ") 0"]), by = year2]

yearStartupsFirms[ , entryRate := startups / allFirms]

averageEntryRate <- yearStartupsFirms[ year2 >= 1986 & year2 <= 2008, mean(entryRate)]




  

  






