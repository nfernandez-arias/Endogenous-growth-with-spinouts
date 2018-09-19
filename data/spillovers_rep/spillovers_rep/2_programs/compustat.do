**** SEGMENTS
u "$raw_data/segments" if sales~=., clear
drop if sics1=="" & sics2==""
destring gvkey, replace force
* ALLOCATE SALES $primary_share TO PRIMARY SIC, (1-$primary_share) TO SECONDARY SIC
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
keep if  (substr(sics,1,1)=="2" | substr(sics,1,1)=="3")
bysort gvkey datadate : egen ssales=sum(sales)
gen share=sales/ssales
collapse (mean) share, by(gvkey sics)
bysort gvkey : egen segnum=count(share)
save "$data/segments_processed", replace
egen tag=tag(gvkey)
keep if tag==1
keep gvkey segnum
save "$data/segnum", replace
*** XRD AND SALES FROM FUNDAMENTALS ANNUAL DATA
use "$raw_data/compustat_annual" if sale~=., clear
*Fix data typos
replace xrd=200 if substr(cusip,1,6)=="101137"&fyear==1998
rename fyear year
rename gvkey gvkey_
keep if xrd~=. | sale~=.
replace xrd = 0 if xrd<0
replace sale = 0 if sale<0
destring gvkey, replace force
drop if year<$compustat_start | year>$compustat_end
keep xrd sale gvkey* year
compress
save "$data/compustat", replace
*** SALES
/*
use "$raw_data/compustat_annual" if sale~=., clear
rename fyear year
rename gvkey gvkey_
replace sale = 0 if sale<0
destring gvkey, replace force
drop if year<$compustat_start | year>$compustat_end
compress
save "$data/sales", replace
*/
*** SALES_IND
use "$raw_data/compustat_annual" if sale~=., clear
destring gvkey, replace force
collapse (sum) sale, by(fyear sic)
rename fyear year
rename sale sales
merge m:1 year using "$raw_data/pindex"
	keep if _m==3
	drop _m
replace sales = sales*pindex
keep year sales sic
rename sic sics
joinby sics using "$data/segments_processed", unm(n)
replace sales=sales*share
gen lsales=log(sales)*share
collapse (sum) sales, by(gvkey year)
rename sales sales_ind
drop if year<$compustat_start | year>$compustat_end
compress
save "$data/sales_ind", replace
* COMPUSTAT LONG FILE
use "$raw_data/compustat_annual" if sale~=., clear
replace xrd=200 if cusip=="101137"&fyear==1998
destring gvkey, replace force
replace cusip = substr(cusip,1,6)
rename sale sales
rename fyear year
gen mkvaf=csho*prcc_f
replace dt=dlc+dltt
gen la=log10(at*1000000)
drop ls
gen ls=log10(sales*1000000)
gen poa=gp/at
gen pos=gp/sales
* merge in # of segments
merge m:1 gvkey using "$data/segnum"
	keep if _m==3
	drop _m
* merge in pindex
merge m:1 year using "$raw_data/pindex"
	keep if _m==3
	drop _m
local varlist /*
*/ at sales oibdp ib emp dldte segnum invt /*
*/ intan ivaeq ivao act ao oiadp poa pos mkvalt mkvaf dt pstk xad xrd pi aqi aqs gp  /*
*/ ppegt ppent capx capxv xrent xint xintd xlr xpr xsga cogs invfg invwip invo /*
*/ invrm  lifr dp la ls pindex dlc dltt revt cstk csho prcc_f
keep gvkey cusip year tic conm dlrsn sic datadate `varlist'
drop if year<$compustat_start | year>$compustat_end
save "$data/compustat_long_file", replace







