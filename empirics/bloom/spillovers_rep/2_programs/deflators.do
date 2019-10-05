clear all
set more off
* INPUT NBER-CES DATA (http://www.nber.org/nberces/)
u "$raw_data/sic5811", clear
gen sic3=floor(sic/10)
collapse (mean) piship [aw=vship], by(sic3 year)
rename piship pind_ind
compress
sa "$data/deflators", replace


