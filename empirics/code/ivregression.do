clear all
set more off

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"


insheet using "data/compustat-spinouts_Stata.csv"
encode state, gen(stateCode)

gen firm_dum = lfirm == 0

gen lxrd = log(xrd)

gen lemp_lag1 = log(emp_lag1)
gen lrevt = log(revt)
gen lact = log(act)


winsor2 lxrd, replace cuts(1 99)
winsor2 lfirm, replace cuts(1 99)
winsor2 lstate, replace cuts(5 95)

winsor2 xrdintensity, replace cuts(1 99)
winsor2 xrdintensity1, replace cuts(1 99)

*reg lxrd lfirm lstate, robust
*areg lxrd lfirm lstate, ab(gvkey) robust

reghdfe xrdintensity1 lfirm firm_dum, absorb(gvkey stateCode#year naics4#year, savefe) cluster(gvkey) resid
predict hxrdIntensity, xbd

reghdfe lxrd lfirm firm_dum, absorb(gvkey stateCode#year naics4#year, savefe) cluster(gvkey) resid
predict hxrd, xbd

reghdfe xrd tobin_q lfirm firm_dum, absorb(gvkey stateCode#year naics4#year, savefe) cluster(gvkey) resid
predict zxrd, xbd

*keep gvkey year hxrd 

*save "data/hxrd", replace

** Run second stage regression using hxrd as independent variable

gen hxrdIntensity_treated = treatedpost * hxrdIntensity

gen californiaIndicator = 1 if state == "CA"
replace californiaIndicator = 0 if californiaIndicator == .
gen hxrdCalif = hxrdIntensity * californiaIndicator

gen massachusettsIndicator = 1 if state == "MA"
replace massachusettsIndicator = 0 if massachusettsIndicator == .
gen hxrdMass = hxrdIntensity * massachusettsIndicator

gen spinoutcountunweighted_emplag1 = spinoutcountunweighted / emp_lag1
gen spinoutcount_emplag1 = spinoutcount / emp_lag1
gen spinoutdffv_emplag1 = spinoutsdiscountedffvalue / emp_lag1

reghdfe spinoutcount zxrd tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
reghdfe spinoutcountunweighted zxrd tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
reghdfe spinoutsdiscountedffvalue zxrd tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)

reghdfe spinoutcountunweighted_emplag1 hxrd tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)

reghdfe spinoutcount_emplag1 hxrd firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
reghdfe spinoutsweightedintensity hxrdIntensity tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(stateCode naics4)
reghdfe spinoutsdffvintensity hxrdIntensity tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)

reghdfe spinoutsdffvintensity xrdintensity firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)

reghdfe spinoutsdiscountedffvalue hxrd tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey) 

reghdfe spinoutsdiscountedffvalue lxrd tobin_q firm_dum, absorb(gvkey stateCode#year naics4#year) cluster(gvkey) 




