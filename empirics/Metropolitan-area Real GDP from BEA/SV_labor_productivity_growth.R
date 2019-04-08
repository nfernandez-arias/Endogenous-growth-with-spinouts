

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/data/Metropolitan-area Real GDP from County Business Patterns (CBP)")


library(data.table)


# Load in dataset

data <- fread("MAGDP9_CA_San-Jose-Sunnyvale-Santa-Clara_2001_2017.csv")

# Reshape to long format

data <- melt(data, measure = patterns("^20"), value.name = c("Real GDP"), variable.name = c("Year"))

# 
