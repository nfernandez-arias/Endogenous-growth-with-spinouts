cd "Z:\home\nico\nfernand@princeton.edu\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

*****************************************************************************
*****************************************************************************
** First analysis normalizing by total GDP **********************************
*****************************************************************************
*****************************************************************************

*** Set up data ********************************************
************************************************************

* Load data
u Data\yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.dta

* Select total gdp 
keep if IndustryId == 1

* Merge with entry rates
merge 1:1 state year using Data\entry_rates_by_state.dta
drop if _merge != 3

* Declare panel data (need to use number to encode state)
xtset stateNum year


*** Prepare variables for analysis ************************* 
************************************************************

label variable net_job_creation `net_j_cr'
rename net_job_creation net_j_cr

*** Define varlists
** Not normalized (deprecated)
*local depvarlist estabs_entry net_j_cr
*local indepvarlist RD

** NORMALIZE
** Normalizing R&D spending by state GDP 
** Normalizing establishment entry by total number of establishments
** Normalizing net job creation by total employment

generate e_entry_n = estabs_entry / estabs_total
generate n_j_cr_n = net_j_cr / emp_total
local depvarlist e_entry_n n_j_cr_n
local indepvarlist xrd_percentGDP

local indepvarlist_with_lags `indepvarlist'
* Generate lags of instrument 
gen rho_high_lag1 = l1.rho_high
*gen rho_h_lag2 = l2.rho_h
*gen rho_h_lag3 = l3.rho_h
local rhovarlist rho_high rho_high_lag*


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

display "Normalizing R&D by total state GDP"

foreach depvar of varlist `depvarlist' {

	display "`depvar'"
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
		
		display "OLS regression of `depvar' on `indepvar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `indepvar' i.year, fe vce(cluster stateNum)
		display "`indepvar'"
	}
	
	display "OLS regression of `depvar' on RD and lags, with state- and time-fixed effects"
	eststo: quietly xtreg `depvar' `indepvarlist_with_lags' i.year, fe vce(cluster stateNum)
	*eststo clear
	esttab using Tables\totalGDP_`depvar'_OLS_compustatAggregation.tex, ar2 drop(*.year) replace booktabs compress 
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
	
	gen temp = xrd_percentGDP * xrd_percentGDP_coef
	replace total_`depvar'_resid2 = total_`depvar'_resid2 + temp
	
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
	
		*gen temp = `indepvar' * `indepvar'_coef
		*replace total_`depvar'_resid2 = total_`depvar'_resid2 + temp
		*display "Made residual `indepvar'"
		*drop temp
		drop `indepvar'_coef
	}
	
	
	display "Attempting to make graph"
	graph twoway scatter total_`depvar'_resid2 temp xrd_percentGDP, title(total `depvar' (norm) vs total R&D (norm)) msize(vsmall)
	graph export Graphs\totalGDP_`depvar'_compustatAggregation.pdf, replace
	drop temp
	
	display "Made plot!"
	
	foreach rhovar of varlist `rhovarlist' {
		display "Reduced form regression: OLS regression of `depvar' on `rhovar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `rhovar' i.year, fe vce(cluster stateNum)	
	}
	
	esttab using Tables\totalGDP_`depvar'_reduced_compustatAggregation.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
	
	foreach indepvar of varlist `indepvarlist' {
	
		display "IV regression of `depvar' on `indepvar' with rho_h as instrument"
		eststo: quietly xtivreg `depvar' i.year (`indepvar' = rho_high), fe
	}
	
	esttab using Tables\totalGDP_`depvar'_IV_compustatAggregation.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
}

** First stage for IV
foreach indepvar of varlist `indepvarlist' {

	display "First stage regression of `depvar' on rho_h" 
	eststo: quietly xtreg `indepvar' rho_high i.year, fe vce(cluster stateNum)

}

esttab using Tables\totalGDP_firststage_compustatAggregation.tex, ar2 drop(*.year) replace booktabs 
eststo clear

*****************************************************************************
*****************************************************************************
** Second analysis using just private GDP *************************
*****************************************************************************
*****************************************************************************

*** Set up data ********************************************
************************************************************

* Load data
u Data\yearStateXrd-RDUserCost-GDP_stateLevel_compustatAggregation.dta, clear

keep if IndustryId == 2

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

*** Define varlists
** Not normalized (deprecated)
*local depvarlist estabs_entry net_j_cr
*local indepvarlist RD

** NORMALIZE
** Normalizing R&D spending by state GDP 
** Normalizing establishment entry by total number of establishments
** Normalizing net job creation by total employment

generate e_entry_n = estabs_entry / estabs_total
generate n_j_cr_n= net_j_cr / emp_total
local depvarlist e_entry_n n_j_cr_n
local indepvarlist xrd_percentGDP

local indepvarlist_with_lags `indepvarlist'

foreach depvar of varlist `depvarlist'  {

	replace `depvar' = log(`depvar')

}

foreach indepvar of varlist `indepvarlist_with_lags' {

	replace `indepvar' = log(`indepvar')
	
}

* Generate lags of instrument 
gen rho_high_lag1 = l1.rho_high
*gen rho_h_lag2 = l2.rho_h
*gen rho_h_lag3 = l3.rho_h

local rhovarlist rho_high rho_high_lag*

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
	
	* Have to hardcode - otherwise, we cannot use suffixes bc of macros
	* ...Stata sucks.
	
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag1
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag2
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag3
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag4
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag5
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag6
}



keep `depvarlist' `indepvarlist_with_lags' `rhovarlist' stateNum year state

** OLS regressions
display "Using private R&D data"
foreach depvar of varlist `depvarlist' {
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
		
		display "OLS regression of `depvar' on `indepvar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `indepvar' i.year, fe vce(cluster stateNum) 
	}
	
	display "OLS regression of `depvar' on RD and lags, with state- and time-fixed effects"
	eststo: quietly xtreg `depvar' `indepvarlist_with_lags' i.year, fe vce(cluster stateNum)
	esttab using Tables\privateGDP_`depvar'_OLS_compustatAggregation.tex, ar2 drop(*.year) replace booktabs compress
	eststo clear
	
		foreach indepvar of varlist `indepvarlist_with_lags' {
	
		gen `indepvar'_coef = _b[`indepvar']
		
	}
	
	
	* Plot residuals
	predict double private_`depvar'_resid, e 
	display "Constructed residuals"
	gen private_`depvar'_resid2 = private_`depvar'_resid
	display "Initialized second residuals"
	
	
	
	* Add back in effect from RD coeffs
	
	gen temp = xrd_percentGDP * xrd_percentGDP_coef
	replace private_`depvar'_resid2 = private_`depvar'_resid2 + temp
	
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
	
		*gen temp = `indepvar' * `indepvar'_coef
		*replace private_`depvar'_resid2 = private_`depvar'_resid2 + temp
		*display "Made residual `indepvar'"
		*drop temp
		drop `indepvar'_coef
	}
	
	
	
	graph twoway scatter private_`depvar'_resid2 temp xrd_percentGDP, title(private `depvar' (norm) vs private R&D (norm)) msize(vsmall)
	graph export Graphs\privateGDP_`depvar'.pdf, replace
	drop temp
	
	

	
	foreach rhovar of varlist `rhovarlist' {
		display "Reduced form regression: OLS regression of `depvar' on `rhovar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `rhovar' i.year, fe vce(cluster stateNum)	
	}
	
	esttab using Tables\privateGDP_`depvar'_reduced_compustatAggregation.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
	
	foreach indepvar of varlist `indepvarlist' {
	
		display "IV regression of `depvar' on `indepvar' with rho_h as instrument"
		eststo: quietly xtivreg `depvar' i.year (`indepvar' = rho_high), fe
	}
	
	esttab using Tables\privateGDP_`depvar'_IV_compustatAggregation.tex, ar2 drop(*.year) replace booktabs 
	eststo clear
}

** First stage for IV
foreach indepvar of varlist `indepvarlist' {

	display "First stage regression of `depvar' on rho_h" 
	eststo: quietly xtreg `indepvar' rho_high i.year, fe vce(cluster stateNum)

}

esttab using Tables\privateGDP_firststage_compustatAggregation.tex, ar2 drop(*.year) replace booktabs 
eststo clear





