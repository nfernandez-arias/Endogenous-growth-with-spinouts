clear all
set more 1
set matsize 7500
set maxvar 7500
* PATENT COUNTS
* Read in the patents data from the NBER
u "$raw_data/pat76_06_assg" if appyear>=1970 & appyear~=., clear
* rename key variables
gen pat_count=1
rename allcites pat_cite
* merge to dynamic assignee match file
merge m:1 pdpass using "$raw_data/dynass", keepusing(pdpass gvkey1 source)	
	keep if _m==3
	drop _m
rename gvkey1 gvkey
destring gvkey, replace
* collapse count/sites to firm-year-class
collapse (sum) pat_count pat_cite, by(gvkey appyear nclass)
* normalize cites per firm to 1 per year
bysort appyear : egen cites_sum=sum(pat_cite)
bysort appyear : egen firms_sum=count(gvkey)
gen pat_cite_norm=pat_cite*firms_sum/cites_sum
rename appyear year
keep gvkey year nclass pat_count pat_cite pat_cite_norm
sa "$data/patent_counts_nclass",replace 
collapse (sum) pat_count pat_cite pat_cite_norm, by(gvkey year)
compress
so gvkey year
sa "$data/patent_counts",replace 

*** PATENTS_IND nclass

* Read in the patents data from the NBER
u "$raw_data/pat76_06_assg" if appyear>=1970 & appyear~=., clear
* merge to dynamic assignee match file
merge m:1 pdpass using "$raw_data/dynass", keepusing(pdpass gvkey1 source)
	keep if _m==3
	drop _m
rename gvkey1 gvkey
destring gvkey, replace
*
preserve
collapse (count) patent, by(nclass gvkey)
bysort gvkey : egen pat_share=sum(patent)
replace pat_share=patent/pat_share
save "$data/patent_counts_nclass", replace
restore
*
collapse (count) patent, by(nclass appyear)
rename appyear year
joinby nclass using "$data/patent_counts_nclass", unm(n)
gen patents_ind = patent*pat_share
collapse (sum) patents_ind, by(gvkey year)
compress
so gvkey year
sa "$data/patents_ind", replace



