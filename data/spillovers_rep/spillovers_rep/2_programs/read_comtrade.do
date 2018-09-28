clear all
set more off
forv y=1989/2008 {
	local i=`y'-1900
	use "$raw_data/trade/imp_detl_yearly_`i'n.dta", clear
	gen china = cty_code=5700
	collapse (sum) *qy* *val* *cha* *cif* *wgt* *dut* (firstnm) scommodity comm_desc, by(year sic china)
	compress
	tempfile im`y'
	save `im`y''
}
clear all
forv y=1989/2008 {
	append using `im`y''
}
compress
save "$data/imports", replace


