#---------------------------------
#---------------------------------
#---------------------------------
# This code computes labor productivity growth in San-Jose / Sunnyvale 
# and in the United States as a whole, to compare. 
#---------------------------------
#---------------------------------



setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/data")


library(data.table)


# Load in dataset

realGDP <- fread("./Metropolitan-area Real GDP from BEA/MAGDP9_CA_San-Jose-Sunnyvale-Santa-Clara_2001_2017.csv")

# Reshape to long format

realGDP <- melt(realGDP, measure = patterns("^20"), value.name = c("Real GDP"), variable.name = c("Year"))

# Load in data on annual employment (well, employment during week of March 12) in San-Jose / Sunnyvale / Santa Clara from CBP

cbpData <- fread("./County Business Patterns/cbp16co.txt")




