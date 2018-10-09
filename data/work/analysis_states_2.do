cd "Z:\home\nico\nfernand@princeton.edu\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

*****************************************************************************
*****************************************************************************
** First analysis using total R&D in state **********************************
*****************************************************************************
*****************************************************************************

*** Set up data ********************************************
************************************************************

* Load data
u Data\rd-by-state_RDusercost_merged.dta


* Merge with entry rates
merge 1:1 state year using Data\entry_rates_by_state.dta
drop if _merge != 3

* Declare panel data (need to use number to encode state)
xtset stateNum year

*** Prepare variables for analysis ************************* 
************************************************************

label variable net_job_creation `net_j_cr'
rename net_job_creation net_j_cr
drop net_job_creation

* Define varlists
*local depvarlist estabs_entry_rate net_job_creation_rate estabs_entry net_job_creation
local depvarlist estabs_entry net_j_cr
local indepvarlist RD
local indepvarlist_with_lags `indepvarlist'
* Generate lags of instrument 
gen rho_h_lag1 = l1.rho_h
*gen rho_h_lag2 = l2.rho_h
*gen rho_h_lag3 = l3.rho_h
local rhovarlist rho_h rho_h_lag*


*display "`indepvarlist_with_lags'"
*display "Hello!"

*Try specification in logs


foreach depvar of varlist `depvarlist'  {

	replace `depvar' = log(`depvar')

}

foreach indepvar of varlist `indepvarlist_with_lags' {

	replace `indepvar' = log(`indepvar')
	
}


foreach rhovar of varlist `rhovarlist' {

	replace `rhovar' = log(`rhovar')
	
}


* Generate lags of independent variables
foreach var of varlist `indepvarlist' {

	gen `var'_lag1 = l1.`var'
	gen `var'_lag2 = l2.`var'
	gen `var'_lag3 = l3.`var'
	gen `var'_lag4 = l4.`var'
	gen `var'_lag5 = l5.`var'
	gen `var'_lag6 = l6.`var'
	
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag1
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag2
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag3
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag4
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag5
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag6
	
}

display "`indepvarlist_with_lags'"


keep `depvarlist' `indepvarlist_with_lags' `rhovarlist' stateNum year state

** OLS regressions

display "Using total R&D data"

foreach depvar of varlist `depvarlist' {

	display "`depvar'"
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
		
		display "OLS regression of `depvar' on `indepvar' with state- and time-fixed effects"
		pause
		eststo: quietly xtreg `depvar' `indepvar' i.year, fe vce(cluster stateNum)
		pause
		display "`indepvar'"
	}
	
	display "OLS regression of `depvar' on RD and lags, with state- and time-fixed effects"
	eststo: quietly xtreg `depvar' `indepvarlist_with_lags' i.year, fe vce(cluster stateNum)
	*eststo clear
	esttab using Tables\total_`depvar'_OLS.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
	*drop _est*
	
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
	
		gen `indepvar'_coef = _b[`indepvar']
		
	}
	
	
	* Plot residuals
	predict double total_`depvar'_resid, e 
	display "Constructed residuals"
	gen total_`depvar'_resid2 = total_`depvar'_resid
	display "Initialized second residuals"
	
	* Add back in effect from RD coeffs
	foreach indepvar of varlist `indepvarlist_with_lags' {
	
		gen temp = `indepvar' * `indepvar'_coef
		replace total_`depvar'_resid2 = total_`depvar'_resid2 + temp
		display "Made residual `indepvar'"
		drop temp
		drop `indepvar'_coef
	}
	
	
	display "Attempting to make graph"
	graph twoway scatter total_`depvar'_resid2 RD, title(total `depvar' vs R&D) msize(vsmall)
	graph export Graphs\total_`depvar'.pdf, replace
	
	display "Made plot!"
	
	foreach rhovar of varlist `rhovarlist' {
		display "Reduced form regression: OLS regression of `depvar' on `rhovar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `rhovar' i.year, fe vce(cluster stateNum)	
	}
	
	esttab using Tables\total_`depvar'_reduced.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
	
	foreach indepvar of varlist `indepvarlist' {
	
		display "IV regression of `depvar' on `indepvar' with rho_h as instrument"
		eststo: quietly xtivreg `depvar' i.year (`indepvar' = rho_h), fe
	}
	
	esttab using Tables\total_`depvar'_IV.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
}

** First stage for IV
foreach indepvar of varlist `indepvarlist' {

	display "First stage regression of `depvar' on rho_h" 
	eststo: quietly xtreg `indepvar' rho_h i.year, fe vce(cluster stateNum)

}

esttab using Tables\total_firststage.tex, ar2 drop(*.year) replace booktabs 
eststo clear

*****************************************************************************
*****************************************************************************
** Second analysis using just private-performed R&D *************************
*****************************************************************************
*****************************************************************************

*** Set up data ********************************************
************************************************************

* Load data
u Data\private-performed-rd-by-state_RDusercost_merged.dta, clear

* Merge with entry rates
merge 1:1 state year using Data\entry_rates_by_state.dta
drop if _merge != 3

* Set panel data dimensions
xtset stateNum year

*** Prepare variables for analysis ************************* 
************************************************************

drop net_job_creation_rate
label variable net_job_creation `net_j_cr'
rename net_job_creation net_j_cr

* Define varlists
local depvarlist estabs_entry net_j_cr
local indepvarlist RD
local indepvarlist_with_lags `indepvarlist'



* Generate lags of independent variables
foreach var of varlist `indepvarlist' {

	gen `var'_lag1 = l1.`var'
	gen `var'_lag2 = l2.`var'
	gen `var'_lag3 = l3.`var'
	gen `var'_lag4 = l4.`var'
	gen `var'_lag5 = l5.`var'
	gen `var'_lag6 = l6.`var'
	
	* Have to hardcode - otherwise, we cannot use suffixes bc of macros
	* ...Stata sucks.
	
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag1
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag2
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag3
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag4
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag5
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag6
}

* Generate lags of instrument 
gen rho_h_lag1 = l1.rho_h
*gen rho_h_lag2 = l2.rho_h
*gen rho_h_lag3 = l3.rho_h

local rhovarlist rho_h rho_h_lag*

keep `depvarlist' `indepvarlist_with_lags' `rhovarlist' stateNum year state


foreach depvar of varlist `depvarlist'  {

	gen `depvar'_log = log(`depvar')

}

foreach indepvar of varlist `indepvarlist_with_lags' {

	gen `indepvar'_log = log(`indepvar')
	
}

foreach rhovar of varlist `rhovarlist' {

	gen `rhovar'_log = log(`rhovar')
	
}



** OLS regressions
display "Using private R&D data"
foreach depvar of varlist `depvarlist' {
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
		
		display "OLS regression of `depvar' on `indepvar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `indepvar' i.year, fe vce(cluster stateNum) 
	}
	
	display "OLS regression of `depvar' on RD and lags, with state- and time-fixed effects"
	eststo: quietly xtreg `depvar' `indepvarlist_with_lags' i.year, fe vce(cluster stateNum)
	
	* Plot residuals
	predict private_`depvar'_resid, e
	graph twoway scatter private_`depvar'_resid RD, title(private_`depvar' vs R&D) msize(vsmall)
	graph export Graphs\private_`depvar'.pdf, replace
	
	
	esttab using Tables\private_`depvar'_OLS.tex, ar2 drop(*.year) replace booktabs
	eststo clear
	
	foreach rhovar of varlist `rhovarlist' {
		display "Reduced form regression: OLS regression of `depvar' on `rhovar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `rhovar' i.year, fe vce(cluster stateNum)	
	}
	
	esttab using Tables\private_`depvar'_reduced.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
	
	foreach indepvar of varlist `indepvarlist' {
	
		display "IV regression of `depvar' on `indepvar' with rho_h as instrument"
		eststo: quietly xtivreg `depvar' i.year (`indepvar' = rho_h), fe
	}
	
	esttab using Tables\private_`depvar'_IV.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
}

** First stage for IV
foreach indepvar of varlist `indepvarlist' {

	display "First stage regression of `depvar' on rho_h" 
	eststo: quietly xtreg `indepvar' rho_h i.year, fe vce(cluster stateNum)

}

esttab using Tables\private_firststage.tex, ar2 drop(*.year) replace booktabs 
eststo clear





