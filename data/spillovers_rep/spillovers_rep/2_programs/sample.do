/***************************************************************************************************
THIS FILE CREATES SUBSAMPLES OF THE RAW DATA BASED ON DESIRED TIME PERIOD AND PATENT MATCH SOURCE
-- Patent data downloaded from NBER Patent Data Project:
		https://sites.google.com/site/patentdataproject/Home/downloads
-- Compustat Segmenta and Fundamentals Annual data downloaded from WDRS:
		https://wrds-web.wharton.upenn.edu/wrds/
***************************************************************************************************/
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
sa "$data/segments", replace
use "$raw_data/compustat_annual"
keep if inrange(fyear,$compustat_start,$compustat_end)
sa "$data/compustat_annual", replace



