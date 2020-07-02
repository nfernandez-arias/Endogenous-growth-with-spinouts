************************************************************************
* This file just creates 1 sample of firms for all of the regressions
************************************************************************
* patents
u "$data/spillovers" if year<($patent_end-5) &year>(fyear+prior_years)&lgspillsic1~=., clear
winsor2 pat_cite, cuts(0 99.5) replace
qui tab sic,gen(jjj)
qui nbreg pat_cite lgrd1 lgrd1_dum  lgspilltec1 lgspillsic1 lsales1 jjj*    yy* , cluster(num)
keep if e(sample)==1
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
tempfile Spat
save `Spat'
* market value
u "$data/spillovers" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
tsset num year
qui reghdfe lq lgspilltec1 lgspillsic1 grd_k1 grd_k1_dum grd_kt? lsales_ind lsales_ind1, ab(year) vce(robust, bw(2)) old
keep if e(sample)==1
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
tempfile Sq
save `Sq'
* TFP
u "$data/spillovers" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
tsset num year
qui reghdfe lsales lgspilltec1 lgspillsic1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind,ab(year)  vce(robust, bw(2)) old
keep if e(sample)==1
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
tempfile Stfp
save `Stfp'
* R&D
u "$data/spillovers" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
tsset num year
qui reghdfe lxrd_sales lgspilltec1  lgspillsic1 lsales_ind lsales_ind1,ab(year)  vce(robust, bw(2)) old
keep if e(sample)==1
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
merge 1:1 gvkey using `Stfp'
	keep if _m==3
	drop _m
merge 1:1 gvkey using `Spat'
	keep if _m==3
	drop _m
merge 1:1 gvkey using `Sq'
	keep if _m==3
	drop _m
save "$data/sample", replace
u "$data/spillovers", clear
winsor2 pat_cite, cuts(0 99.5) replace
merge m:1 gvkey using "$data/sample"
	keep if _m==3
	drop _m
keep if inrange(year,$compustat_start,$compustat_end)
sa "$data/rsample", replace








