clear all

set more off, permanently

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

use "data/compustat-spinouts_Stata.dta", clear

xtset gvkey year

encode State, gen(Statecode)

label variable xrd "R\&D"

foreach var of varlist xrd patentCount_CW_cumulative emp at ch at_ma5 sale intan capxv ni Tobin_Q {
	egen z`var' = std(`var')
	gen l`var' = log(`var')

	egen zl`var' = std(l`var')
}

label variable lxrd "log(R\&D)"

gen highIncidence = 1 if naics2 == 51 | naics2 == 21 | naics2 == 54 | naics2 == 52
replace highIncidence = 0 if highIncidence == .

gen lowIncidence = 1 if naics2 == 11 | naics2 == 72 | naics2 == 71 | naics2 == 23 
replace lowIncidence = 0 if lowIncidence == .


by gvkey: egen firm_xrd_at = mean(xrd_at)

gen high_xrd_at = 1 if firm_xrd_at > 0.1
replace high_xrd_at = 0 if high_xrd_at == .


* Regressions

foreach var of varlist treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost* {

	gen high`var' = highIncidence * `var'
	gen low`var' = lowIncidence * `var'
	
	gen high_xrd_at_`var' = high_xrd_at * `var'

}


foreach var of varlist fw_pre4 fw_pre3 fw_pre2 fw_pre1 fw_post* {

	gen high`var' = highIncidence * `var'
	gen low`var' = lowIncidence * `var'
	
	gen high_xrd_at_`var' = high_xrd_at * `var'

}

bysort gvkey: gen lag_ppent = ppent[_n-1]
gen invRate = (capxv - sppe) / lag_ppent

label variable treatedPre4 "-4"
label variable treatedPre3 "-3"
label variable treatedPre2 "-2"
label variable treatedPre1 "-1"
label variable treatedPost0 "0"
label variable treatedPost1 "1"
label variable treatedPost2 "2"
label variable treatedPost3 "3"
label variable treatedPost4 "4"

label variable high_xrd_at_treatedPre4 "-4"
label variable high_xrd_at_treatedPre3 "-3"
label variable high_xrd_at_treatedPre2 "-2"
label variable high_xrd_at_treatedPre1 "-1"
label variable high_xrd_at_treatedPost0 "0"
label variable high_xrd_at_treatedPost1 "1"
label variable high_xrd_at_treatedPost2 "2"
label variable high_xrd_at_treatedPost3 "3"
label variable high_xrd_at_treatedPost4 "4"


reghdfe invRate high_xrd_at_treatedPre4 high_xrd_at_treatedPre3 high_xrd_at_treatedPre2 high_xrd_at_treatedPre1 high_xrd_at_treatedPost0 high_xrd_at_treatedPost1 high_xrd_at_treatedPost2 high_xrd_at_treatedPost3 high_xrd_at_treatedPost4 treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost0 treatedPost1 treatedPost2 treatedPost3 treatedPost4, absorb(gvkey naics4#year) cluster(Statecode)
test (1/4) * (high_xrd_at_treatedPre4 + high_xrd_at_treatedPre3 + high_xrd_at_treatedPre2 + high_xrd_at_treatedPre1 - treatedPre4 - treatedPre3 - treatedPre2 - treatedPre1) = (1/5) * (high_xrd_at_treatedPost0 + high_xrd_at_treatedPost1 + high_xrd_at_treatedPost2 + high_xrd_at_treatedPost3 + high_xrd_at_treatedPost4 - treatedPost0 - treatedPost1 - treatedPost2 - treatedPost3 - treatedPost4)
coefplot, keep(high*) label vertical
addplot: , yline(0) norescaling

reghdfe xrd_at high_xrd_at_treatedPre4 high_xrd_at_treatedPre3 high_xrd_at_treatedPre2 high_xrd_at_treatedPre1 high_xrd_at_treatedPost0 high_xrd_at_treatedPost1 high_xrd_at_treatedPost2 high_xrd_at_treatedPost3 high_xrd_at_treatedPost4 treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost0 treatedPost1 treatedPost2 treatedPost3 treatedPost4, absorb(gvkey high_xrd_at#Statecode naics4#year) cluster(Statecode)
test (1/4) * (high_xrd_at_treatedPre4 + high_xrd_at_treatedPre3 + high_xrd_at_treatedPre2 + high_xrd_at_treatedPre1 - treatedPre4 - treatedPre3 - treatedPre2 - treatedPre1) = (1/5) * (high_xrd_at_treatedPost0 + high_xrd_at_treatedPost1 + high_xrd_at_treatedPost2 + high_xrd_at_treatedPost3 + high_xrd_at_treatedPost4 - treatedPost0 - treatedPost1 - treatedPost2 - treatedPost3 - treatedPost4)

reghdfe xrd_at high_xrd_at_fw_pre4 high_xrd_at_fw_pre3 high_xrd_at_fw_pre2 high_xrd_at_fw_pre1 high_xrd_at_fw_post0 high_xrd_at_fw_post1 high_xrd_at_fw_post2 high_xrd_at_fw_post3 high_xrd_at_fw_post4 fw_pre4 fw_pre3 fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3 fw_post4, absorb(gvkey high_xrd_at#Statecode naics4#year) cluster(Statecode)
test (1/4) * (high_xrd_at_fw_pre4 + high_xrd_at_fw_pre3 + high_xrd_at_fw_pre2 + high_xrd_at_fw_pre1 - fw_pre4 - fw_pre3 - fw_pre2 - fw_pre1) = (1/5) * (high_xrd_at_fw_post0 + high_xrd_at_fw_post1 + high_xrd_at_fw_post2 + high_xrd_at_fw_post3 + high_xrd_at_fw_post4 - fw_post0 - fw_post1 - fw_post2 - fw_post3 - fw_post4)

reg lxrd highIncidence lowIncidence hightreatedPre4 hightreatedPre3 hightreatedPre2 hightreatedPre1 hightreatedPost* lowtreatedPre4 lowtreatedPre3 lowtreatedPre2 lowtreatedPre1 lowtreatedPost* treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost*

reghdfe lxrd highIncidence lowIncidence hightreatedPre4 hightreatedPre3 hightreatedPre2 hightreatedPre1 hightreatedPost* lowtreatedPre4 lowtreatedPre3 lowtreatedPre2 lowtreatedPre1 lowtreatedPost* treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost*, absorb(gvkey year) cluster(gvkey)

coefplot, keep(*hightreated*)


reghdfe lxrd lemp lat_ma5 lintan lch lsale lTobin_Q hightreatedPre4 hightreatedPre3 hightreatedPre2 hightreatedPre1 hightreatedPost* lowtreatedPre4 lowtreatedPre3 lowtreatedPre2 lowtreatedPre1 lowtreatedPost* treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost*, absorb(gvkey year) cluster(gvkey)

reghdfe xrd_at emp_at intan_at ch_at sale_at Tobin_Q hightreatedPre4 hightreatedPre3 hightreatedPre2 hightreatedPre1 hightreatedPost* lowtreatedPre4 lowtreatedPre3 lowtreatedPre2 lowtreatedPre1 lowtreatedPost* treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost*, absorb(gvkey year) cluster(gvkey)


reghdfe xrd_at emp_at intan_at ch_at sale_at Tobin_Q hightreatedPre4 hightreatedPre3 hightreatedPre2 hightreatedPre1 hightreatedPost* lowtreatedPre4 lowtreatedPre3 lowtreatedPre2 lowtreatedPre1 lowtreatedPost* treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost*, absorb(gvkey naics4#year highIncidence#Statecode lowIncidence#Statecode) cluster(gvkey)
coefplot, keep(hightreatedPre4 hightreatedPre3 hightreatedPre2 hightreatedPre1 hightreatedPost*) saving(high)
addplot : , xline(0) norescaling

coefplot, keep(lowtreatedPre4 lowtreatedPre3 lowtreatedPre2 lowtreatedPre1 lowtreatedPost*) saving(low)
addplot : , xline(0) norescaling

test (1/4) * (hightreatedPre4 + hightreatedPre3 + hightreatedPre2 + hightreatedPre1 -  lowtreatedPre4 - lowtreatedPre3 - lowtreatedPre2 - lowtreatedPre1) = (1/5) * (hightreatedPost0 + hightreatedPost1 + hightreatedPost2 + hightreatedPost3 + hightreatedPost4 - lowtreatedPost0 - lowtreatedPost1 - lowtreatedPost2 - lowtreatedPost3 - lowtreatedPost4)

gr combine high.gph low.gph





reghdfe xrd_at highfw_pre4 highfw_pre3 highfw_pre2 highfw_pre1 highfw_post* lowfw_pre4 lowfw_pre3 lowfw_pre2 lowfw_pre1 lowfw_post* fw_pre4 fw_pre3 fw_pre2 fw_pre1 fw_post*, absorb(gvkey naics4#year) cluster(gvkey)
coefplot, keep(highfw_pre4 highfw_pre3 highfw_pre2 highfw_pre1 highfw_post*) 
addplot : , xline(0) norescaling
graph save high, replace

coefplot, keep(lowfw_pre4 lowfw_pre3 lowfw_pre2 lowfw_pre1 lowfw_post*) 
addplot : , xline(0) norescaling
graph save low, replace

gr combine high.gph low.gph
graph export "figures/plots/jeffersRegressions/fw_NCAincidence_divAssets.pdf", replace

test (1/4) * (highfw_pre4 + highfw_pre3 + highfw_pre2 + highfw_pre1 -  lowfw_pre4 - lowfw_pre3 - lowfw_pre2 - lowfw_pre1) = (1/5) * (highfw_post0 + highfw_post1 + highfw_post2 + highfw_post3 + highfw_post4 - lowfw_post0 - lowfw_post1 - lowfw_post2 - lowfw_post3 - lowfw_post4)

test (highfw_pre4 + highfw_pre3 + highfw_pre2 + highfw_pre1) = (lowfw_pre4 + lowfw_pre3 + lowfw_pre2 + lowfw_pre1)

test (highfw_post0 + highfw_post1 + highfw_post2 + highfw_post3 + highfw_post4) = (lowfw_post0 + lowfw_post1 + lowfw_post2 + lowfw_post3 + lowfw_post4)





reghdfe lcapxv lemp lat_ma5 lintan lch lsale lTobin_Q highfw_pre4 highfw_pre3 highfw_pre2 highfw_pre1 highfw_post* lowfw_pre4 lowfw_pre3 lowfw_pre2 lowfw_pre1 lowfw_post* fw_pre4 fw_pre3 fw_pre2 fw_pre1 fw_post*, absorb(gvkey firmAge year) cluster(gvkey)

