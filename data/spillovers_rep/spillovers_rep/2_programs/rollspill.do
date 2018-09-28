clear all
set more off
set matsize 7500
set maxvar 7500
set memory 1500m
/***************************************************************************
 THIS FILE CREATES A TIME-VARYING SIC MEASURE BASED ON THE LAST 5 YEARS OF
 SALES.
***************************************************************************/
* COMBINE COMPUSTAT SALES/R&D WITH PREDICT R&D STOCKS
u "$data/compustat", clear
rename gvkey_ gvkey
merge 1:1 gvkey year using "$data/hxrd"
keep if _m==1 | _m==3
drop _m
rename gvkey gvkey_
tempfile compustat_hxrd
save `compustat_hxrd'
***************************************************************************
*	CALCULATING CORRELATIONS FOR SIC SHARES
***************************************************************************
*slow to run - only update when the SIC info. is updated in merge1.do
u "$data/rsample", clear
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
tempfile tmp
save `tmp'
foreach ma in 10 20 {
forv yX=1984(1)2015 {
local d=`ma'-1
local yN=`yX'
local y0=`yX'-`d'
u "$raw_data/segments", clear
keep if yofd(datadate)>=`y0' & yofd(datadate)<=`yN'
destring gvkey, replace
merge m:1 gvkey using `tmp'
keep if _m==3
drop _m
* ALLOCATE SALES 75% TO PRIMARY SIC, 25% TO SECONDARY SIC
gen f_nosics2 = sics2==""
gen s1sale=sales if f_nosics2==1
gen s2sale=0 if f_nosics2==1
replace s1sale=sales*$primary_share if f_nosics2==0
replace s2sale=sales*(1-$primary_share) if f_nosics2==0
preserve
collapse (sum) s1sale, by(gvkey datadate sics1)
rename sics1 sics
rename s1sale sales
tempfile segments
save `segments'
restore
drop if sics2==""
collapse (sum) s2sale, by(gvkey datadate sics2)
rename sics2 sics
rename s2sale sales
append using `segments'
collapse (sum) sales, by(gvkey datadate sics)
keep if (substr(sics,1,1)=="2" | substr(sics,1,1)=="3")
bysort gvkey datadate : egen ssales=sum(sales)
gen share=sales/ssales
collapse (mean) share, by(gvkey sics)
egen tag=tag(sics)
egen SIC=sum(tag)
qui su SIC
global SIC=r(max)
keep gvkey share sics
reshape wide share, i(gvkey) j(sics) string
sa "$data/sicstage1`yN'", replace
*
u "$data/sicstage1`yN'",clear
so gvkey
compress
gen num=_n
sa "$data/tempn`yN'",replace
keep num gvkey
so num
sa "$data/sicnum`yN'",replace
rename num num_
rename gvkey gvkey_
so num_
sa "$data/sicnum_`yN'",replace
*
u "$data/tempn`yN'",clear
*drop gvkey
order num
egen NUM=max(num)
so num
gen x=NUM - num + 1
replace x=x+1 if num==1
*compress
label drop _all
global num=NUM
global sic=$SIC

*Generates a matrix of all the shares in dimensions (num, sic) 
mvencode share*,mv(0) over
mkmat share*,mat(share)
matrix normshare=share


*Var is a (tech,tech) matrix of the correlations between sales classes. Used for Mahalanobis distance measures
matrix var=share'*share
matrix basevar=var
forv i=1(1)$sic {
forv j=1(1)$sic {
matrix var[`i',`j']=var[`i',`j']/(basevar[`i',`i']^(1/2)*basevar[`j',`j']^(1/2))
if var[`i',`j']==. {
matrix var[`i',`j']=0
}
}
}

*Standard is a (num,num) matrix of the correlations between firms over tech classes
matrix basestandard=share*share'
forv j=1(1)$sic {
forv i=1(1)$num {
matrix normshare[`i',`j']=share[`i',`j']/(basestandard[`i',`i']^(1/2))
}
}
matrix standard=normshare*normshare'
matrix covstandard=share*share'
save "$data/temp`yN'",replace

forv mal=0(1)1{
u "$data/temp`yN'",clear

*Generate the Malhabois measure
if `mal'==1 {
matrix mal_corr=normshare*var*normshare'
matrix standard=mal_corr
matrix covmal_corr=share*var*share'
matrix covstandard=covmal_corr
}
*Convert back into scalar data
keep gvkey
sort gvkey
local J=$X+1
svmat standard,n(standard)
svmat covstandard,n(covstandard)
compress
reshape long standard covstandard,i(gvkey) j(num_)
cap drop subsh*
ren *standard *sic
so gvkey num_
merge m:1 num_ using "$data/sicnum_`yN'"
assert _m==3
drop _m
* merge to xrd and sale
joinby gvkey_ using `compustat_hxrd'
cap drop _m
* create spillovers variables
egen spillind=sum(sic*(1/100)*sale*(gvkey~=gvkey_)), by(gvkey year)
egen spillsicIV=sum(sic*(1/100)*hxrd*(gvkey~=gvkey_)), by(gvkey year)
foreach var in sic covsic {
	egen spill`var'=sum(`var'*(1/100)*xrd*(gvkey~=gvkey_)), by(gvkey year)
	drop `var'
}
keep if gvkey==gvkey_
drop gvkey_
so gvkey year
compress
*Actually censoring top and bottom 1% of these values - just reset values of 0.01 and 0.99 below
gen n=_N
gen p005=round(n*0.005,1)
gen p995=round(n*0.995,1)
foreach var in sic covsic ind sicIV {
cap so spill`var'
cap gen spill`var'_p005=spill`var'[p005]
cap gen spill`var'_p995=spill`var'[p995]
cap replace spill`var'=spill`var'_p005 if spill`var'<spill`var'_p005
cap replace spill`var'=spill`var'_p995 if spill`var'>spill`var'_p995
cap drop spill`var'_p*
}
drop p995 n
so gvkey year
gen sales_ind=spillind

if `mal'==1 {
ren *sic* *malsic*
sa "$data/sicoutput`yN'_short7_mal",replace
}
else {
sa "$data/sicoutput`yN'_short7",replace
}
}
}
* Merge together the few different measures of spillovers, rename with year suffix, make 1 continuous rolling measure
use gvkey year spillsicIV spillsic spillcovsic sales_ind using "$data/sicoutput1984_short7", clear
merge 1:1 gvkey year using "$data/sicoutput1984_short7_mal", keepusing(spillmalsicIV spillmalsic spillcovmalsic)
	drop _m
rename *sic *sic1984
rename *sicIV *sicIV1984
rename sales_ind sales_ind1984
forv yN=1985(1)2015 {
	merge 1:1 gvkey year using "$data/sicoutput`yN'_short7", keepusing(spillsicIV spillsic spillcovsic sales_ind)
		drop _m
	merge 1:1 gvkey year using "$data/sicoutput`yN'_short7_mal", keepusing(spillmalsicIV spillmalsic spillcovmalsic)
		drop _m
	rename *sic *sic`yN'
	rename *sicIV *sicIV`yN'
	rename sales_ind sales_ind`yN'
}
sort gvkey year
foreach var in spillsic spillcovsic spillsicIV spillmalsic spillcovmalsic spillmalsicIV sales_ind {
	cap drop `var'
	gen `var'=.
/*	* First, fill in the missings by taking closest neighbor
	forv yN=1984(1)2015 {
		gen x`var'`yN'=`var'`yN'
		foreach x of numlist 1(1)5 {
			local yM`x'=`yN'-`x'
			cap replace x`var'`yN' = `var'`yM`x'' if x`var'`yN'==.
		}
		foreach x of numlist 1(1)5 {
			local yP`x'=`yN'+`x'
			cap replace x`var'`yN' = `var'`yP`x'' if x`var'`yN'==.
		}
	}
	drop `var'????
	rename x`var'???? `var'????
	* use correlations calculated over previous 5 years or closest neighbor*/
	forv yN=1984(1)2015 {
		replace `var'=`var'`yN' if year==`yN'
	}
	drop `var'????
}
foreach var in sic covsic sicIV malsic covmalsic malsicIV {
gen lspill`var'=log(spill`var')
}
* MERGE TO PINDEX
merge m:1 year using "$raw_data/pindex"
	keep if _m==3
	drop _m
foreach var in sic covsic sicIV malsic covmalsic malsicIV {
	gen rspill`var'=spill`var'*pindex
	gen gspill`var'=spill`var'/0.1
	so gvkey year
	qui by gvkey:replace gspill`var'=gspill`var'[_n-1]*0.85 + rspill`var' if gspill`var'[_n-1]~=.
	gen lgspill`var'=log(gspill`var')
	so gvkey year
	qui by gvkey: gen lgspill`var'1=lgspill`var'[_n-1]
}
gen lsales_ind=log(sales_ind)
so gvkey year
qui by gvkey: gen lsales_ind1=lsales_ind[_n-1]
compress
save "$data/sicroll_ma`ma'", replace
*** CLEAN UP
forv yN=1984(1)2015 {
	cap erase "$data/sicoutput`yN'_short7.dta"
	cap erase "$data/sicoutput`yN'_short7_mal.dta"
	cap erase "$data/sicstage1`yN'.dta"
	cap erase "$data/sicnum_`yN'.dta"
	cap erase "$data/sicnum`yN'.dta"
	cap erase "$data/temp`yN'.dta"
	cap erase "$data/tempn`yN'.dta"

}
}














