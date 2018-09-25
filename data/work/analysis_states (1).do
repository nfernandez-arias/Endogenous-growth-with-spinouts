cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Data\rd-by-state_RDusercost_merged.dta

merge 1:1 state year using Data\entry_rates_by_state.dta
drop if _merge != 3

* Declare panel data (need to use number to encode state)
xtset stateNum year

*local depvarlist estabs_entry_rate net_job_creation_rate estabs_entry net_job_creation
local depvarlist estabs_entry_rate net_job_creation_rate
local indepvarlist RD RD_by_GDP
local indepvarlist_with_lags `indepvarlist'

foreach var of varlist `indepvarlist' {

	gen `var'_lag1 = l1.`var'
	*gen `var'_lag2 = l2.`var'
	*gen `var'_lag3 = l3.`var'
	
	local indepvarlist_with_lags `indepvarlist_with_lags' `var'_lag*
	
}

*display "`indepvarlist_with_lags'"


* Lags of instrument 

gen rho_h_lag1 = l1.rho_h
*gen rho_h_lag2 = l2.rho_h
*gen rho_h_lag3 = l3.rho_h

local rhovarlist rho_h_lag*

** OLS regressions

timer on 1

foreach depvar of varlist `depvarlist' {
	
	foreach indepvar of varlist `indepvarlist_with_lags' {
		
		display "OLS regression of `depvar' on `indepvar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `indepvar' i.year, fe vce(cluster stateNum)
	}
	
	esttab, ar2 drop(*.year)
	eststo clear
	
	foreach rhovar of varlist `rhovarlist' {
		display "Reduced form regression: OLS regression of `depvar' on `rhovar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `rhovar' i.year, fe vce(cluster stateNum)	
	}
	
	esttab, ar2 drop(*.year)
	eststo clear
	
	foreach indepvar of varlist `indepvarlist' {
	
		display "IV regression of `depvar' on `indepvar' with rho_h as instrument"
		eststo: quietly xtivreg `depvar' i.year (`indepvar' = rho_h), fe cluster year
	}
	
	esttab, ar2 drop(*.year)
	eststo clear
}

** Reduced form regressions - instrument on depvar **

/*
foreach depvar of varlist `depvarlist' {
	foreach rhovar of varlist `rhovarlist' {
		display "Reduced form regression: OLS regression of `depvar' on `rhovar' with state- and time-fixed effects"
		eststo: quietly xtreg `depvar' `rhovar' i.year, fe vce(robust)
	}	
	
	
	esttab, ar2 drop(*.year)
	eststo clear
}

timer off 1


** IV regressions **
foreach depvar of varlist 


/*

*foreach depvar of varlist `depvarlist' {

*	foreach indepvar of varlist `indepvarlist' {	
	
*		display "OLS regression of `depvar' on `indepvar'

*	}
*}



/*
foreach var of depvarlist {
	xtreg `var' RD_by_GDP 
* Run with establishment entry rate
xtreg estabs_entry_rate RD_by_GDP i.year, fe vce(bootstrap)
* Run with job creation rate
xtreg net_job_creation_rate RD_by_GDP i.year, fe vce(bootstrap)
* Run with establishment entry
xtreg estabs_entry RD_by_GDP i.year, fe vce(bootstrap)
* Run with job creation rate
xtreg net_job_creation RD_by_GDP i.year, fe vce(bootstrap)

** Independent varible: R&D spending / GDP 
** 1-yr lag
* Run with establishment entry rate
xtreg estabs_entry_rate i.year, fe vce(bootstrap)
* Run with job creation rate
xtreg net_job_creation_rate i.year, fe vce(bootstrap)
* Run with establishment entry
xtreg estabs_entry RD_by_GDP, fe vce(bootstrap)
* Run with job creation rate
xtreg net_job_creation RD_by_GDP, fe vce(bootstrap)

** Independent varible: R&D spending
** No lagging
* Run with establishment entry rate
xtreg estabs_entry_rate RD i.year, fe vce(bootstrap)
* Run with job creation rate
xtreg net_job_creation_rate RD i.year, fe vce(bootstrap)
* Run with establishment entry
xtreg estabs_entry RD, fe vce(bootstrap)
* Run with job creation rate
xtreg net_job_creation RD, fe vce(bootstrap)






** Using RD spending
** estab entry rate
xtreg estabs_entry RD i.year, fe
xtreg estabs_entry_rate RD i.year, fe

** job creation rate
xtreg net_job_creation RD_by_GDP i.year, fe
xtreg net_job_creation RD_by_GDP_ma5 i.year, fe






tssmooth ma RD_by_GDP_ma5 = RD_by_GDP, window(4 1 0)
tssmooth ma estabs_entry_rate_ma = estabs_entry_rate, window(0,1,2)

xtreg estabs_entry_rate_ma RD_by_GDP_ma5 i.year, fe vce(bootstrap)
xtreg estabs_entry RD_by_GDP i.year, fe vce(bootstrap)
xtreg net_job_creation RD_by_GDP i.year, fe vce(bootstrap)
xtreg estabs_entry RD i.year, fe vce(bootstrap)
xtreg net_job_creation RD i.year, fe vce(bootstrap)
xtreg net_job_creation_rate RD i.year, fe vce(bootstrap)
xtreg estabs_entry_rate RD i.year, fe vce(bootstrap)

reg estabs_entry RD, vce(bootstrap)
reg estabs_entry_rate RD, vce(bootstrap)
reg estabs_entry RD_by_GDP, vce(bootstrap)
reg estabs_entry_rate RD_by_GDP, vce(bootstrap)
reg net_job_creation RD, vce(bootstrap)
reg net_job_creation_rate RD, vce(bootstrap)
reg net_job_creation RD_by_GDP, vce(bootstrap)
reg net_job_creation_rate RD_by_GDP, vce(bootstrap)

** Instrumental variables regression


*First stage
xtreg RD_by_GDP t_f_e-rho_h i.year, fe vce(bootstrap)

 
xtivreg estabs_entry_rate RD_by_GDP i.year (RD_by_GDP = rho_m), fe first vce(bootstrap)
xtline estabs_entry_rate RD_by_GDP

xtivreg net_job_creation_rate RD_by_GDP i.year (RD_by_GDP = rho_m), fe vce(bootstrap)

xtivreg estabs_entry_rate RD i.year (RD = rho_m), fe vce(bootstrap)
xtivreg estabs_entry RD i.year (RD = rho_m), fe vce(bootstrap)

xtivreg net_job_creation_rate RD i.year (RD = rho_m), fe vce(bootstrap)
xtivreg net_job_creation RD i.year (RD = rho_m), fe vce(bootstrap)

** Make plots

order state statename year RD GDP RD_by_GDP RD_by_GDP_ma5 estabs_entry_rate_ma*

regress estabs_entry_rate_ma RD_by_GDP_ma5 i.stateNum i.year
predict yhat
separate estabs_entry_rate_ma, by(stateNum)
separate yhat, by(stateNum)


local thinlist "vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin"
local tinylist "vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny"



*twoway connected yhat1-yhat20 RD_by_GDP_ma5, lwidth(`thinlist') msize(`tinylist') || lfit net_job_creation RD_by_GDP, msize(vtiny)
*twoway connected net_job_creation21-net_job_creation40 RD_by_GDP_ma5, lwidth(`thinlist') msize(`tinylist') legend(off)|| lfit net_job_creation RD_by_GDP, msize(vtiny)
twoway connected estabs_entry_rate_ma1-estabs_entry_rate_ma20 RD_by_GDP_ma5, lwidth(`thinlist') msize(`tinylist') legend(off)|| lfit estabs_entry_rate_ma RD_by_GDP_ma5, msize(vtiny)
*twoway scatter estabs_entry_rate RD_by_GDP, legend(off) msize(tiny) || lfit estabs_entry_rate RD_by_GDP, msize(vtiny) lwidth(vthin)



regress estabs_entry RD i.stateNum i.year
predict zhat
separate estabs_entry, by(year)
separate zhat, by(year)

twoway connected zhat1991 zhat1993 zhat1995 zhat1997 zhat1998 zhat1999 zhat2000 zhat2002-zhat2014 RD, lwidth(vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin vthin) msize(vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny vtiny) || lfit estabs_entry RD, msize(vtiny)



|| lfit estabs_entry RD, msize(vtiny) lwidth(vthin)
twoway connect
ed yhat1-yhat7 
x1, msymbol(none 
diamond_hollow t
riangle_hollow 
square_hollow + 
circle_hollow 
x) msize(medium) 
mcolor(black 
black black black black black 
black) || lfit y x1, 
clwidth(thick) 
clcolor(black)



*/
