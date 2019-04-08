/***************************************************************************************************
THIS FILE CREATES SUBSAMPLES OF THE RAW DATA BASED ON DESIRED TIME PERIOD AND PATENT MATCH SOURCE
***************************************************************************************************/
* BSV firm ids
use "$data/BSV_spillovers_matched", clear
	egen tag=tag(gvkey)
	keep if tag==1
	rename gvkey bsvids
	keep bsvids
	tempfile tmp
	save `tmp'
* TIME AND PATENT MATCH SOURCE RESTRICTION
u "$raw_data/pat76_06_assg", clear
keep if inrange(appyear,$patent_start,$patent_end)
sa "$data/pat76_06_assg", replace
u "$raw_data/dynass", clear
sa "$data/dynass", replace
u "$raw_data/segments", clear
keep if stype=="BUSSEG"
keep if sales>0 & sales~=.
keep if  (substr(sics1,1,1)=="2" | substr(sics1,1,1)=="3" | substr(sics2,1,1)=="2" | substr(sics2,1,1)=="3")
keep if yofd(datadate)>=$segments_start & yofd(datadate)<=$segments_end
destring gvkey, force generate(bsvids)
merge m:1 bsvids using `tmp'
	keep if _m==3
	drop _m bsvids
sa "$data/segments", replace
use "$raw_data/compustat_annual"
keep if inrange(fyear,$compustat_start,$compustat_end)
destring gvkey, force generate(bsvids)
merge m:1 bsvids using `tmp'
	keep if _m==3
	drop _m bsvids
sa "$data/compustat_annual", replace
