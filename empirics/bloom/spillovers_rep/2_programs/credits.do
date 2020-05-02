clear all

set more off

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"


***************************
* FEDERAL R&D TAX CREDITS
***************************
* READ IN COMPUSTAT
insheet using "data/compustat/compustat_annual_light.csv", clear
destring gvkey, replace force
drop if gvkey==.
drop if sale==.
rename fyear year
tsset gvkey year
***** CALCULATE FIRM-SPECIFIC BASE
* historical base period for fbp calculation
gen base_period = inrange(year,1984,1988)
* indicator for positive Research Expenditure
gen Ixrd = xrd>0 & xrd<.
* sales and RD in the base period
bysort gvkey base_period : egen sxrd=sum(xrd)
by gvkey base_period : egen ssale=sum(sale)
by gvkey base_period : egen posRE=sum(Ixrd)
* fixed base % is avg(xrd/sales) from 84-88, for firms with positive R&D in at least 3 of those years
gen fbp = sxrd/ssale if base_period==1 & posRE>=3
by gvkey : egen fbp_min=min(fbp)
replace fbp=fbp_min
drop fbp_min
* "START-UP" rate
so gvkey year
*generate lags of sales and R&D
forv i=1/5 {
	gen L`i'_sale = L`i'.sale
	gen L`i'_xrd = L`i'.xrd
}
* count from year of first R&D expenditure or 1994, whichever is later
gen credityear = Ixrd*(year>1993)
bysort gvkey year : replace credityear = credityear[_n-1]+credityear if credityear[_n-1]~=.
* 0.03 through 1st 5 years after 1993, then converges to actual %
replace fbp=0.03 if fbp==. & year<=1993
replace fbp=0.03 if fbp==. & credityear<=5
replace fbp=(1/6)*(L2_xrd+L1_xrd)/(L2_sale+L1_sale) if fbp==. & credityear==6
replace fbp=(1/3)*(L2_xrd+L1_xrd)/(L2_sale+L1_sale) if fbp==. & credityear==7
replace fbp=(1/2)*(L3_xrd+L2_xrd+L1_xrd)/(L3_sale+L2_sale+L1_sale) if fbp==. & credityear==8
replace fbp=(2/3)*(L4_xrd+L3_xrd+L2_xrd+L1_xrd)/(L4_sale+L3_sale+L2_sale+L1_sale) if fbp==. & credityear==9
replace fbp=(5/6)*(L5_xrd+L4_xrd+L3_xrd+L2_xrd+L1_xrd)/(L5_sale+L4_sale+L3_sale+L2_sale+L1_sale) if fbp==. & credityear==10
replace fbp=fbp[_n-1] if fbp==. & credityear>10 & credityear~=.
* FBP may not exceed 0.16
replace fbp = 0.16 if fbp>0.16 & fbp~=.
* generate base amount=max[fbp*(4 years avg. of gross receipts),0.5*xrd]
egen base = rmean(sale L1_sale L2_sale L3_sale)
replace base=base*fbp
replace base=0.5*xrd if base<0.5*xrd
* credit amount = 0.5*(xrd-base)
* MERGE IN federal_credit_rate, fed_tax_rate, r
preserve
	insheet using "raw/bsv/RDusercost_2017.csv", clear
	keep year k_f_e t_f t_f_e t_s_e
	egen tag=tag(year)
	keep if tag==1
	drop tag
	rename k_f federal_credit_rate
	rename t_f fed_tax_rate
	rename t_f_e effective_federal_tax_rate
	rename t_s_e effective_state_tax_rate
	tempfile fedrates
	save "data/bsv/fedrates", replace
restore
merge m:1 year using "data/bsv/fedrates"
	keep if _m==3
	drop _m
***** TAX PRICE OF R&D following Hall (1992)
* indicator for taxable income
gen T=(ebit>0 & year>1980)
* indicator for above/below base amount-sorta2
gen  Z=(xrd<base)
replace Z=0.5 if xrd>=2*base
* share of R&D which qualifies for credit
gen eta=(xrd-base)/xrd
replace eta=0 if eta<0
* effective credit rate
local r=0.1
gen ERC=federal_credit_rate*(Z-(1/3)*((1+`r')^(-1)*(Z[_n+1]>0.5) + (1+`r')^(-2)*(Z[_n+2]>0.5) + (1+`r')^(-3)*(Z[_n+3]>0.5)))
replace ERC=federal_credit_rate*(Z-(1/2)*((1+`r')^(-1)*(Z[_n+1]>0.5) + (1+`r')^(-2)*(Z[_n+2]>0.5) + (1+`r')^(-3)*(Z[_n+3]>0.5))) if year==1981
replace ERC=federal_credit_rate*(Z-(1/3)*((1+`r')^(-1)*(Z[_n+1]>0.5) + (1+`r')^(-2)*(Z[_n+2]>0.5))) if Z[_n+3]==.
replace ERC=federal_credit_rate*(Z-(1/2)*((1+`r')^(-1)*(Z[_n+1]>0.5) + (1+`r')^(-2)*(Z[_n+2]>0.5))) if Z[_n+3]==. & year==1981
replace ERC=federal_credit_rate*(Z-(1/3)*((1+`r')^(-1)*(Z[_n+1]>0.5))) if Z[_n+2]==.
replace ERC=federal_credit_rate*(Z-(1/2)*((1+`r')^(-1)*(Z[_n+1]>0.5))) if Z[_n+2]==. & year==1981
replace ERC=federal_credit_rate*Z if Z[_n+1]==.
* 1989
replace ERC=ERC*(1-0.5*fed_tax_rate) if year==1989
* 1990+
replace ERC=federal_credit_rate*1*(1-fed_tax_rate)*Z if year>1989
replace ERC=0 if year<1981
* TAX PRICE
gen theta=1*(1-T*fed_tax_rate-eta*ERC)
gen firm=theta/(1-T*fed_tax_rate)
tab year, su(firm)
gen lfirm=log(firm)
keep gvkey year lfirm
sa "data/compustat/lfirm", replace
***************************
* STATE R&D TAX CREDITS
***************************
* Read in the patents data from the NBER
use "raw/nber uspto/pat76_06_assg.dta", clear
* rename key variables
gen pat_count=1
* merge to dynamic assignee match file
merge m:1 pdpass using "data/nber uspto/dynass", keepusing(pdpass gvkey1 source)
	keep if _m==3
	drop _m
rename gvkey1 gvkey
destring gvkey, replace
* collapse count/cites to firm-state-year
collapse (sum) pat_count, by(gvkey appyear state)
* take 10-year moving average of inventors and patent count (aka "inventors")
forv y=1980/2006 {
	preserve
	local x=`y'-9
	keep if inrange(appyear,`x',`y')
	collapse (sum) pat_count, by(gvkey state)
	bysort gvkey : egen isum=sum(pat_count)
	gen ishare=pat_count/isum
	fillin gvkey state
	replace ishare=0 if ishare==.
	gen year=`y'
	tempfile `y'
	save `y'.dta, replace
	* fix shares for 2006 through 2015
	if `y'==2006 {
		forv z=2007/2015 {
			replace year=`z'
			tempfile `z'
			save `z'.dta, replace
		}
	}
	restore
}
clear
forv y=1980/2015 {
	append using `y'.dta
}
drop _fillin
*  THIS PART MAPS PATENT SHARES FORWARD
fillin gvkey state year
sort gvkey state year
by gvkey state : replace ishare=ishare[_n-1] if ishare==. & _fillin==1
*

export delimited "data/compustat/firmYearStateShares_bloom.csv"

rename state abbr
merge m:1 abbr using "bloom/spillovers_rep/1_data/Raw/stmap"
keep if _m==3
drop _m
drop state abbr
merge m:1 fips year using "data/bsv/RDusercost_2017", keepusing(rho_h r)
	keep if _m==3
	drop _m
gen state=ishare*rho_h/(0.3)
collapse (sum) state, by(gvkey year)
tab year, su(state)
gen lstate=log(state)
keep gvkey year lstate
sa "data/compustat/lstate", replace
