# This file clean the raw compustat data

rm(list =ls())

library(data.table)

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics")
  
# Load raw data
compustat <- fread("raw/compustat/compustat_annual.csv")[indfmt=="INDL" & datafmt=="STD" & popsrc=="D" & consol=="C" & loc == "USA"][ , .(gvkey,fyear,datadate,loc,state,xrd,sale,capx,capxv,sppe,ppent,ebit,ebitda,ni,ch,emp,revt,intan,at,sic,naics,seq,pstkrv,pstkl,pstk,txdb,itcb,prcc_c,csho,re,act)]

fwrite(compustat,"data/compustat/compustat_for_bloom_instruments.csv")
fwrite(compustat,"data/compustat/compustat_Cleaned.csv")

      