* MATCH ON CUSIP
use "$raw_data/compustat_annual", clear
replace cusip=substr(cusip,1,6)
egen tag=tag(cusip)
keep if tag==1 & cusip~=""
keep cusip gvkey
merge 1:m cusip using "$raw_data/BSV_spillovers"
preserve
keep if _m==3
drop _m
gen source="cusip"
sa "$data/bsv_ids_1", replace
restore
keep if _m==2
drop gvkey _m
tempfile tmp
save `tmp'
* MATCH ON TICKER SYMBOL
use "$raw_data/compustat_annual", clear
egen tag=tag(tic)
keep if tag==1 & tic~=""
keep tic gvkey
merge 1:m tic using `tmp'
preserve
keep if _m==3
drop _m
gen source="tic"
sa "$data/bsv_ids_2", replace
restore
keep if _m==2
drop gvkey _m
tempfile tmp
save `tmp'
* MATCH ON LEGAL COMPANY NAME
use "$raw_data/compustat_annual", clear
egen tag=tag(conm)
keep if tag==1 & conm~=""
keep conm gvkey
rename conm comn
merge 1:m comn using `tmp'
preserve
keep if _m==3
drop _m
gen source="conm"
sa "$data/bsv_ids_3", replace
restore
keep if _m==2
codebook cusip
drop gvkey _m
**********
tempfile tmp
save `tmp'
* MATCH ON SALES AND EMPLOYEES from 1980 to 2000
forv y=1980/2000 {
cap drop x y z
gen x=round(sales) if year==`y'
gen y=round(emp) if year==`y'
gen z=round(ppent) if year==`y'
so cusip year
foreach v in x y z {
cap drop tmp
by cusip : egen tmp=min(`v')
replace `v'=tmp if year~=`y'
}
tempfile tmp
save `tmp'
use "$raw_data/compustat_annual", clear
keep if fyear==`y'
egen tag=tag(cusip)
gen x=round(sale)
gen y=round(emp)
gen z=round(ppent)
foreach v in x y z {
drop if `v'==0 | `v'==.
}
duplicates drop x y z, force
keep x y z gvkey
merge 1:m x y z using `tmp'
preserve
keep if _m==3
drop _m
gen source="conm"
sa "$data/bsv_ids_`y'", replace
restore
keep if _m==2
codebook cusip
drop gvkey _m
}
**********
sa "$data/bsv_unmatched", replace
/*
u "$data/bsv_unmatched", clear
sort cusip year
by cusip:replace comn=comn[_n-1] if comn==""
by cusip:replace tic=tic[_n-1] if tic==""
gen negyear=year*-1
sort cusip negyear
by cusip:replace comn=comn[_n-1] if comn==""
by cusip:replace tic=tic[_n-1] if tic==""
egen tag=tag(cusip)
keep if tag==1
drop tag negyear
so comn
order comn tic cusip
outsheet using "$data/unmatched_firms.csv", comma replace
*/
**********
u "$data/bsv_ids_1", clear
append using "$data/bsv_ids_2"
append using "$data/bsv_ids_3"
forv y=1980/2000 {
append using "$data/bsv_ids_`y'"
}
foreach var in  tobinq tobinq_e tobinq_d rawtobinq q mkvaf ppent xrd sale pstk dt act invt ivaeq ivao intan revt cstk emp /*
*/				rmkvaf rppent rxrd rsale rpstk rdt ract rinvt rivaeq rivao rintan rrevt rcstk /*
*/				gspilltec gspilltec1 gspillsic gspillsic1 sales_ind sales_ind1 /*
*/				pat_count pat_cite rsale /*
*/ 				 lgspilltec lgspilltec1 lgspillsic lgspillsic1 lsales_ind lsales_ind1 /*
*/				grd grd1 grd_k grd_k_dum grd_k1 grd_k1_dum grd_kt2 grd_kt3 grd_kt3 grd_kt4 grd_kt5 grd_kt6 num cusip fyear prior_years lsales1 /*
*/				lpriorpat_cite lpriorpat_cite_dum lgspillmaltec1 lgspillmalsic1 lgrd1 lgrd1_dum lpat_cite1 lpat_cite1_dum /*
*/				lsales lemp1  lppent1  lpind_ind {
	cap rename `var' `var'_nb
	cap rename l`var' l`var'_nb
}
keep gvkey year *_nb
destring gvkey, replace
sa "$data/BSV_spillovers_matched", replace
**** OUTSHEET UNMATCHED FIRMS
u "$data/BSV_spillovers_matched", clear
egen tag=tag(cusip_nb)
keep if tag==1
rename cusip_nb cusip
keep cusip
merge 1:m cusip using "$data/bsv_unmatched"
keep if _m==2
egen tag=tag(cusip)
drop tag x y z
so cusip year
order year cusip tic
sa  "$data/bsv_unmatched", replace
outsheet using "$data/unmatched_firms.csv", comma replace
* CLEAN UP
forv y=1980/2000 {
erase "$data/bsv_ids_`y'.dta"
}
