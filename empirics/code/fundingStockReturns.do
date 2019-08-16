clear all

set more off

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

insheet using "data/funding_stockReturns.csv"


sort cusip year month

by cusip: gen totalFundingLag = totalfunding[_n-1]
by cusip: gen totalFundingLag2 = totalfunding[_n-2]
by cusip: gen totalFundingLag3 = totalfunding[_n-3]

**** Run regression with firm fixed effects

reghdfe abnormalretdollars_z totalfunding_z, absorb(cusip) cluster(cusip)

reg abnormalretdollars totalfunding totalFundingLag

reg abnormalretdollars_z totalfunding_z




