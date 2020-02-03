#------------------------------------------------#
#
# File name: computeDataInputLagDistribution.R
#
# Author: Nicolas Fernandez-Arias
#
# Purpose:
#
# This script uses BDVI to compute the funding lag distribution
#------------------------------------------------#

rm(list = ls())

library(data.table)

BDVI <- fread("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/raw/VentureSource/PrincetonBDVI.csv")
deals <- fread("raw/VentureSource/01Deals.csv")

output <- BDVI[ BDVI[ , .I[which.min(ymd(InputDate))], by = EntityID]$V1]



output[ , fundingLag := ymd(InputDate) - ymd(JoinDate)]

fwrite(output[ , .(EntityID,fundingLag)],
       "~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/data/VentureSource/fundingLags.csv")

hist(as.numeric(output[fundingLag>0]$fundingLag), n = 100, main = "Funding lag histogram")

d <- density(as.numeric(na.omit(output[fundingLag > 0])$fundingLag/365))

plot(d,main = "Data input lag (years) density")

cdf <- ecdf(as.numeric(na.omit(output[fundingLag > 0])$fundingLag/365))

mean(BDVI[fundingLag > 0]$fundingLag) / 365
