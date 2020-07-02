clear all
set more off
* THIS PROGRAM "credits.do" CREATES THE TAX CREDIT DATASETS lfirm.dta AND lstate.dta
do "$programs/credits.do"
use fyear gvkey xrd using "$raw_data/compustat_annual" if fyear>=$compustat_start, clear
drop if xrd==.
rename fyear year
destring gvkey, replace force
* MERGE TO TAX CREDIT DATA
merge 1:1 gvkey year using "$data/lfirm"
	keep if _m==1 | _m==3
	drop _m
merge 1:1 gvkey year using "$data/lstate"
	keep if _m==1 | _m==3
	drop _m
* MERGE TO SAMPLE
preserve
	use "$data/spill_tmp", clear
	egen tag=tag(gvkey)
	keep if tag==1
	keep gvkey
	tempfile sample
	save `sample'
restore
*
merge m:1 gvkey using `sample'
	keep if _m==3
	drop _m
* GENERATE PREDICTED R&D SPENDING
gen lxrd=log(xrd)
gen firm_dum=lfirm==0
winsor2 lxrd, replace cuts(1 99)
winsor2 lfirm, replace cuts(1 99)
winsor2 lstate, replace cuts(5 95)
reg lxrd lfirm lstate, robust
areg lxrd lfirm lstate, ab(gvkey) robust
reghdfe lxrd lfirm lstate firm_dum, ab(year gvkey, savefe) vce(robust, bw(2)) old
predict hxrd, xbd
keep gvkey year hxrd
save "$data/hxrd", replace
