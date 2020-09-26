clear all

set more off, permanently

cd "Z:\home\nico\Insync\nfernand@princeton.edu\Google Drive\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

use "data/compustat-spinouts_Stata_newProdDeflator.dta", clear

encode State, gen(Statecode)
label variable Statecode "State"
label variable gvkey "Firm"

xtset gvkey year

keep if year <= 2006

label variable founders_founder2 "Founders"
label variable founders_founder2_at "$\frac{\textrm{Founders}}{\textrm{Assets}}$"
label variable founders_founder2_f3 "Founders"
label variable founders_founder2_at_f3 "$\frac{\textrm{Founders}}{\textrm{Assets}}$"
label variable founders_founder2_emp_f3 "$\frac{\textrm{Founders}}{\textrm{Emp}}$"

label variable founders_founder2_wso4 "WSO4"
label variable founders_founder2_wso4_at "$\frac{\textrm{WSO4}}{\textrm{Assets}}$"
label variable founders_founder2_wso4_f3 "WSO4"
label variable founders_founder2_wso4_at_f3 "$\frac{\textrm{WSO4}}{\textrm{Assets}}$"
label variable founders_founder2_wso4_emp_f3 "$\frac{\textrm{WSO4}}{\textrm{Emp}}$"



label variable xrd "R\&D"

label variable xrd_at "$\frac{\textrm{R\&D}}{\textrm{Assets}}$"


label variable xrd_l3 "R\&D"
label variable xrd_at_l3 "$\frac{\textrm{R\&D}}{\textrm{Assets}}$"
label variable emp "Employment"
label variable emp_at "$\frac{\textrm{Employment}}{\textrm{Assets}}$"
label variable emp_l3 "Employment"
label variable emp_at_l3 "$\frac{\textrm{Employment}}{\textrm{Assets}}$"

label variable capxv "Investment"
label variable capxv_at "$\frac{\textrm{Investment}}{\textrm{Assets}}$"
label variable capxv_l3 "Investment"
label variable capxv_at_l3 "$\frac{\textrm{Investment}}{\textrm{Assets}}$"

label variable intan "Intangible assets"
label variable intan_at "$\frac{\textrm{Intangible assets}}{\textrm{Assets}}$"
label variable intan_l3 "Intangible assets"
label variable intan_at_l3 "$\frac{\textrm{Intangible assets}}{\textrm{Assets}}$"

label variable ni "Net income"
label variable ni_at "$\frac{\textrm{Net income}}{\textrm{Assets}}$"
label variable ni_l3 "Net income"
label variable ni_at_l3 "$\frac{\textrm{Net income}}{\textrm{Assets}}$"

label variable at "Assets"
label variable at_l3 "Assets"

label variable Tobin_Q "Tobin's Q"
label variable tobinqat "$\textrm{Tobin's Q} \times \textrm{Assets}$"
label variable Tobin_Q_l3 "Tobin's Q"
*label variable tobinqat_l3 "$\textrm{Tobin's Q} \times \textrm{Assets}$"


replace xrd = xrd / 1000
replace xrd_l3 = xrd_l3 / 1000
replace xrd_at_l3 = xrd_at_l3 / 1000


* Define control variables
global controlsLevels patentCount_CW_cumulative emp_l3 at_l3 intan_l3 capxv_l3 ni_l3 tobinqat_l3
global controlsAssetNormalized patentCount_CW_cumulative_at emp_at_l3 intan_at_l3 capxv_at_l3 ni_at_l3 Tobin_Q2_l3
global controlsLogs lpatentCount_CW_cumulative lemp_l3 lat_l3 lintan_l3 lcapxv_l3 lni_l3 Tobin_Q2_l3


/*

global controlsAll "$controlsLevels $controlsAt "

global controlsLevels_ind_1dig ""
global controlsLevels_ind_2dig ""

foreach var of varlist $controlsLevels {

	foreach var2 of varlist ind_1dig* {

		gen `var'_`var2' = `var' * `var2'

		global controlsLevels_ind_1dig "$controlsLevels_ind_1dig `var'_`var2'"

	}

	foreach var2 of varlist ind_2dig* {

		gen `var'_`var2' = `var' * `var2'

		global controlsLevels_ind_2dig "$controlsLevels_ind_2dig `var'_`var2'"

	} 

	gen `var'_notIn3or5 = `var' * industry_notIn3or5

	global controlsLevels_ind_2dig = "$controlsLevels_ind_2dig `var'_notIn3or5"

}


*/


foreach var of varlist xrd_l3 patentCount_CW_cumulative patentCount_CW_cumulative_at emp_l3 at_l3 ch_l3 sale_l3 intan_l3 capxv_l3 ni_l3 emp_at_l3 intan_at_l3 capxv_at_l3 ni_at_l3 Tobin_Q_l3 Tobin_Q tobinqat {
egen z`var' = std(`var')
gen l`var' = log(`var')

egen zl`var' = std(l`var')
}


label variable lfounders_founder2_f3 "Founders"
label variable lxrd_l3 "log(R\&D)"
label variable lfounders_founder2_wso4_f3 "WSO4"
*** Levels

gen NCC = (NCC_1991 + NCC_2009) / 2

gen hNCA = 1 if NCC > 0
replace hNCA = 0 if hNCA == .

gen industry_notIn3or5 = 1 if naics1 != 3 & naics1 != 5
replace industry_notIn3or5 = 0 if industry_notIn3or5 == .

gen industry_3digResid = 1 if naics3 != 325 & naics3 != 333 & naics3 != 334 & naics3 != 346 & naics3 != 511 & naics3 != 519
replace industry_3digResid = 0 if industry_3digResid == .

foreach var of varlist xrd_l3 xrd_at_l3 lxrd_l3 {

	gen `var'_notIn3or5 = `var' * industry_notIn3or5
	gen hNCA_`var' = hNCA * `var'
	gen hNCA_`var'_notIn3or5 = hNCA * `var'_notIn3or5


	gen `var'_3digResid = `var' * industry_3digResid
	gen hNCA_`var'_3digResid = hNCA * `var'_3digResid

}

gen ind_1dig1 = 1 if naics1 == 1
replace ind_1dig1 = 0 if ind_1dig1 == .

gen ind_1dig2 = 1 if naics1 == 2
replace ind_1dig2 = 0 if ind_1dig2 == .

gen ind_1dig3 = 1 if naics1 == 3
replace ind_1dig3 = 0 if ind_1dig3 == .

gen ind_1dig4 = 1 if naics1 == 4
replace ind_1dig4 = 0 if ind_1dig4 == .

gen ind_1dig5 = 1 if naics1 == 5
replace ind_1dig5 = 0 if ind_1dig5 == .

gen ind_1dig6 = 1 if naics1 == 6
replace ind_1dig6 = 0 if ind_1dig6 == .

gen ind_1dig7 = 1 if naics1 == 7
replace ind_1dig7 = 0 if ind_1dig7 == .

gen ind_1dig8 = 1 if naics1 == 8
replace ind_1dig8 = 0 if ind_1dig8 == .

gen ind_1dig9 = 1 if naics1 == 9
replace ind_1dig9 = 0 if ind_1dig9 == .

*drop if ind_1dig9 == 1
*drop ind_1dig9

*drop if ind_1dig1 == 1
*drop ind_1dig1


foreach var of varlist ind_1dig* {

	foreach var2 of varlist xrd_l3 xrd_at_l3 lxrd_l3 {

		gen `var2'_`var' = `var2' * `var'
		gen hNCA_`var2'_`var' = hNCA * `var2' * `var'
	}

}


**** 2 digits closeup

gen ind_2dig31 = 1 if naics2 == 31
replace ind_2dig31 = 0 if ind_2dig31 == .

gen ind_2dig32 = 1 if naics2 == 32
replace ind_2dig32 = 0 if ind_2dig32 == .

gen ind_2dig33 = 1 if naics2 == 33
replace ind_2dig33 = 0 if ind_2dig33 == .

gen ind_2dig51 = 1 if naics2 == 51
replace ind_2dig51 = 0 if ind_2dig51 == .

gen ind_2dig52 = 1 if naics2 == 52
replace ind_2dig52 = 0 if ind_2dig52 == .

gen ind_2dig53 = 1 if naics2 == 53
replace ind_2dig53 = 0 if ind_2dig53 == .

gen ind_2dig54 = 1 if naics2 == 54
replace ind_2dig54 = 0 if ind_2dig54 == .

gen ind_2dig55 = 1 if naics2 == 55
replace ind_2dig55 = 0 if ind_2dig55 == .

gen ind_2dig56 = 1 if naics2 == 56
replace ind_2dig56 = 0 if ind_2dig56 == .


foreach var of varlist ind_2dig* {

	foreach var2 of varlist xrd_l3 xrd_at_l3 lxrd_l3 {

		gen `var2'_`var' = `var2' * `var'
		gen hNCA_`var2'_`var' = hNCA * `var2'_`var'
	}

}

* Generate naics2 variable that focuses on 3x and 5x vs not in 3 or 5reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized [aweight = at_ma5], absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
gen naics2_selected = naics2 
replace naics2_selected = 0 if industry_notIn3or5 == 1



**** 3 digits closeup


gen ind_3dig325 = 1 if naics3 == 325
replace ind_3dig325 = 0 if ind_3dig325 == .

gen ind_3dig333 = 1 if naics3 == 333
replace ind_3dig333 = 0 if ind_3dig333 == .

gen ind_3dig334 = 1 if naics3 == 334
replace ind_3dig334 = 0 if ind_3dig334 == .

gen ind_3dig336 = 1 if naics3 == 336
replace ind_3dig336 = 0 if ind_3dig336 == .

gen ind_3dig511 = 1 if naics3 == 511
replace ind_3dig511 = 0 if ind_3dig511 == .

gen ind_3dig519 = 1 if naics3 == 519
replace ind_3dig519 = 0 if ind_3dig519 == .



foreach var of varlist ind_3dig* {

	foreach var2 of varlist xrd_l3 xrd_at_l3 lxrd_l3 {

		gen `var2'_`var' = `var2' * `var'
		gen hNCA_`var2'_`var' = hNCA * `var2'_`var'
	}

}

* Generate naics3 variable that focuses on high R&D industries: 325,334,336,511,519 (and a residual) 
gen naics3_selected = naics3 
replace naics3_selected = 0 if industry_3digResid == 1


***********************************************************************************************************************
* Regressions *********************************************************************************************************
***********************************************************************************************************************
***********************************************************************************************************************

*** One table with headline regressions for paper and presentations

eststo clear
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized [aweight = at_ma5], absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year) cluster(gvkey)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_headlineRegs.tex", replace se star(+ 0.2 ++ 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3* *xrd_at_l3* *lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


*** OLS in Levels

eststo clear
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 $controlsLevels, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  $controlsLevels, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode) 
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


* For presentation - only WSOs

eststo clear

eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_onlyWSOs_absolute_founder2_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.hNCA $controlsLevels, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.hNCA $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.hNCA $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.hNCA $controlsLevels, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.hNCA $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.hNCA $controlsLevels, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_f3 i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics1#firmAge "NAICS1-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics1#Statecode#year "NAICS1-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_naics1_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_1dig* i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_1dig* i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_1dig* i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_1dig* i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_1dig* i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_1dig* i.naics1#c.(xrd_l3 $controlsLevels), absorb(gvkey naics1#firmAge naics4#year naics1#Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics1#firmAge "NAICS1-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics1#Statecode#year "NAICS1-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_naics1_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_2dig3* hNCA_xrd_l3_ind_2dig5* hNCA_xrd_l3_notIn3or5 i.naics2_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_2dig3* hNCA_xrd_l3_ind_2dig5* hNCA_xrd_l3_notIn3or5 i.naics2_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics2_selected#firmAge naics4#year naics2_selected#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_2dig3* hNCA_xrd_l3_ind_2dig5* hNCA_xrd_l3_notIn3or5 i.naics2_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics2_selected#firmAge naics4#year naics2_selected#Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_2dig3* hNCA_xrd_l3_ind_2dig5* hNCA_xrd_l3_notIn3or5 i.naics2_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_2dig3* hNCA_xrd_l3_ind_2dig5* hNCA_xrd_l3_notIn3or5 i.naics2_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics2_selected#firmAge naics4#year naics2_selected#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_2dig3* hNCA_xrd_l3_ind_2dig5* hNCA_xrd_l3_notIn3or5 i.naics2_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics2_selected#firmAge naics4#year naics2_selected#Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics2_selected#firmAge "NAICS2*-Age FE" naics4#year "Industry-Year FE" naics2_selected#Statecode#year "NAICS2*-State-Year FE" naics2#Statecode#year "NAICS2*-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_naics2_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_3dig* i.naics3_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_3dig* i.naics3_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_l3_ind_3dig* i.naics3_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_3dig* i.naics3_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_3dig* i.naics3_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_l3_ind_3dig* i.naics3_selected#c.(xrd_l3 $controlsLevels), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics3_selected#firmAge "NAICS3*-Age FE" naics4#year "Industry-Year FE" naics3_selected#Statecode#year "NAICS3*-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_naics3_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


* Speccheck2

*speccheck2 founders_founder2_f3 xrd_l3 zemp_l3 zpatentCount_CW_cumulative zat_l3, method(reghdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(naics4#year) vce(Statecode) always(2)

speccheck2 founders_founder2_f3 xrd_l3 zemp_l3 zpatentCount_CW_cumulative zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, method(reghdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(firmAge naics4#year) vce(Statecode naics4) always(2)
graph export "figures/plots/RDandSpinoutFormation_speccheck2_levels_reghdfe.pdf", replace

speccheck2 founders_founder2_wso4_f3 xrd_l3 zemp_l3 zpatentCount_CW_cumulative zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, method(reghdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(firmAge naics4#year) vce(Statecode naics4) always(2)
graph export "figures/plots/RDandSpinoutFormation_speccheck2_levels_wso4_reghdfe.pdf", replace



*** OLS normalized by assets

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 $controlsAssetNormalized, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode) 
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_l3f3.tex", replace se star(+ 0.2 ++ 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

* only WSOs

eststo clear
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_onlyWSOs_at_founder2_l3f3.tex", replace se star(+ 0.2 ++ 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.hNCA $controlsAssetNormalized, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.hNCA $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.hNCA $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.hNCA $controlsAssetNormalized, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.hNCA $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.hNCA $controlsAssetNormalized, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_hNCA_l3f3.tex", replace se star(+ 0.2 ++ 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_naics1_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 hNCA_xrd_at_l3_ind_1dig* i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 hNCA_xrd_at_l3_ind_1dig* i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 hNCA_xrd_at_l3_ind_1dig* i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 hNCA_xrd_at_l3_ind_1dig* i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 hNCA_xrd_at_l3_ind_1dig* i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 hNCA_xrd_at_l3_ind_1dig* i.naics1#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_naics1_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 hNCA_xrd_at_l3_ind_2dig3* hNCA_xrd_at_l3_ind_2dig5* hNCA_xrd_at_l3_notIn3or5 i.naics2_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 hNCA_xrd_at_l3_ind_2dig3* hNCA_xrd_at_l3_ind_2dig5* hNCA_xrd_at_l3_notIn3or5 i.naics2_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 hNCA_xrd_at_l3_ind_2dig3* hNCA_xrd_at_l3_ind_2dig5* hNCA_xrd_at_l3_notIn3or5 i.naics2_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 hNCA_xrd_at_l3_ind_2dig3* hNCA_xrd_at_l3_ind_2dig5* hNCA_xrd_at_l3_notIn3or5 i.naics2_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 hNCA_xrd_at_l3_ind_2dig3* hNCA_xrd_at_l3_ind_2dig5* hNCA_xrd_at_l3_notIn3or5 i.naics2_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 hNCA_xrd_at_l3_ind_2dig3* hNCA_xrd_at_l3_ind_2dig5* hNCA_xrd_at_l3_notIn3or5 i.naics2_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_naics2_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_at_l3_ind_3dig* i.naics3_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_at_l3_ind_3dig* i.naics3_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 hNCA_xrd_at_l3_ind_3dig* i.naics3_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(naics4 Statecode)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_at_l3_ind_3dig* i.naics3_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_at_l3_ind_3dig* i.naics3_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 hNCA_xrd_at_l3_ind_3dig* i.naics3_selected#c.(xrd_at_l3 $controlsAssetNormalized), absorb(gvkey naics3_selected#firmAge naics4#year naics3_selected#Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics3_selected#firmAge "NAICS3*-Age FE" naics4#year "Industry-Year FE" naics3_selected#Statecode#year "NAICS3*-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_naics3_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


* Speccheck2

speccheck2 founders_founder2_at_f3 xrd_at_l3 zemp_at_l3 zpatentCount_CW_cumulative_at zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q, method(reghdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(firmAge naics4#year) vce(Statecode naics4) always(2)
graph export "figures/plots/RDandSpinoutFormation_speccheck2_at_reghdfe.pdf", replace

speccheck2 founders_founder2_wso4_at_f3 xrd_at_l3 zemp_at_l3 zpatentCount_CW_cumulative_at zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q, method(reghdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(firmAge naics4#year) vce(Statecode naics4) always(2)
graph export "figures/plots/RDandSpinoutFormation_speccheck2_at_wso4_reghdfe.pdf", replace


*** Poisson pseuo-likelihood with fixed effects and clustering

eststo clear
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3 $controlsLogs, noabsorb cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3  $controlsLogs, absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode) 
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, noabsorb cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_ppml_absolute_founder2_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_p N, labels(Clustering "pseudo R-squared" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


* only WSOs

eststo clear
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, noabsorb cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3  $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_onlyWSOs_ppml_absolute_founder2_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_p N, labels(Clustering "pseudo R-squared" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


eststo clear
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3 c.lxrd_l3#i.hNCA $controlsLogs, absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3 c.lxrd_l3#i.hNCA $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 lxrd_l3 c.lxrd_l3#i.hNCA $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3 c.lxrd_l3#i.hNCA $controlsLogs, absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3 c.lxrd_l3#i.hNCA $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 lxrd_l3 c.lxrd_l3#i.hNCA $controlsLogs, absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_ppml_absolute_founder2_hNCA_1991_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_p N, labels(Clustering "pseudo R-squared" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore


eststo clear
eststo: quietly ppmlhdfe founders_founder2_f3 i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_ppml_absolute_founder2_naics1_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly ppmlhdfe founders_founder2_f3 hNCA_lxrd_l3_ind_1dig* i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 hNCA_lxrd_l3_ind_1dig* i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 hNCA_lxrd_l3_ind_1dig* i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 hNCA_lxrd_l3_ind_1dig* i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 hNCA_lxrd_l3_ind_1dig* i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 hNCA_lxrd_l3_ind_1dig* i.naics1#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_ppml_absolute_founder2_naics1_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly ppmlhdfe founders_founder2_f3 hNCA_lxrd_l3_ind_2dig3* hNCA_lxrd_l3_ind_2dig5* hNCA_lxrd_l3_notIn3or5 i.naics2_selected#c.(lxrd_l3 $controlsLogs), absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 hNCA_lxrd_l3_ind_2dig3* hNCA_lxrd_l3_ind_2dig5* hNCA_lxrd_l3_notIn3or5 i.naics2_selected#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_f3 hNCA_lxrd_l3_ind_2dig3* hNCA_lxrd_l3_ind_2dig5* hNCA_lxrd_l3_notIn3or5 i.naics2_selected#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 hNCA_lxrd_l3_ind_2dig3* hNCA_lxrd_l3_ind_2dig5* hNCA_lxrd_l3_notIn3or5 i.naics2_selected#c.(lxrd_l3 $controlsLogs), absorb(gvkey year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 hNCA_lxrd_l3_ind_2dig3* hNCA_lxrd_l3_ind_2dig5* hNCA_lxrd_l3_notIn3or5 i.naics2_selected#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly ppmlhdfe founders_founder2_wso4_f3 hNCA_lxrd_l3_ind_2dig3* hNCA_lxrd_l3_ind_2dig5* hNCA_lxrd_l3_notIn3or5 i.naics2_selected#c.(lxrd_l3 $controlsLogs), absorb(gvkey firmAge naics4#year Statecode#year) cluster(naics4 Statecode)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_ppml_absolute_founder2_naics2_hNCA_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

* Speccheck2

speccheck2 founders_founder2_f3 lxrd_l3 zlemp_l3 zlpatentCount_CW_cumulative zlat_l3 zlintan_l3 zlcapxv_l3 zlni_l3 zTobin_Q, method(ppmlhdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(firmAge naics4#year) vce(Statecode naics4) always(2)
graph export "figures/plots/RDandSpinoutFormation_speccheck2_levels_ppmlhdfe.pdf", replace

speccheck2 founders_founder2_wso4_f3 lxrd_l3 zlemp_l3 zlpatentCount_CW_cumulative zlat_l3 zlintan_l3 zlcapxv_l3 zlni_l3 zTobin_Q, method(ppmlhdfe) alwaysAbsorb(gvkey year) alwaysVce(gvkey) absorb(firmAge naics4#year) vce(Statecode naics4) always(2)
graph export "figures/plots/RDandSpinoutFormation_speccheck2_levels_wso4_ppmlhdfe.pdf", replace




*** Instrumental variables (why is my instrument / first stage so different from Babina & Howell's????)

preserve

keep if lpatentCount_CW_cumulative != .
keep if zTobin_Q != .
keep if zlat_l3 != .
keep if zlintan_l3 != .
keep if zlemp_l3 != .
keep if zlch_l3 != .
keep if zlsale_l3 != .
keep if lstate_l3 != .
keep if lfirm_l3 != .

eststo clear
eststo model1: reghdfe founders_founder2_f3 lxrd_l3, absorb(gvkey) cluster(gvkey)
eststo model2: ivreghdfe founders_founder2_f3 (lxrd_l3 = lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model3: ivreghdfe founders_founder2_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lfirm_l3), absorb(gvkey year) cluster(gvkey)
eststo model4: ivreghdfe founders_founder2_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lfirm_l3), absorb(gvkey naics4#year) cluster(gvkey)
eststo model5: reghdfe founders_founder2_wso4_f3 lxrd_l3 , absorb(gvkey) cluster(gvkey)
eststo model6: ivreghdfe founders_founder2_wso4_f3 (lxrd_l3 = lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model7: ivreghdfe founders_founder2_wso4_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lfirm_l3), absorb(gvkey year) cluster(gvkey)
eststo model8: ivreghdfe founders_founder2_wso4_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lfirm_l3), absorb(gvkey naics4#year) cluster(gvkey)

estfe . *, labels(naics3#year "NAICS3-Year FE" naics4#year "NAICS4-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Firm Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_iv_founder2_l3f3.tex", replace se star(+ 0.2 ++ 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

restore

preserve

keep if lpatentCount_CW_cumulative != .
keep if zTobin_Q != .
keep if zlat_l3 != .
keep if zlintan_l3 != .
keep if zlemp_l3 != .
keep if zlch_l3 != .
keep if zlsale_l3 != .
keep if lstate_l3 != .
keep if lfirm_l3 != .

eststo clear
eststo model1: reghdfe founders_founder2_at_f3 lxrd_l3 c.lxrd_l3#i.hNCA, absorb(gvkey) cluster(gvkey)
eststo model2: ivreghdfe founders_founder2_at_f3 (lxrd_l3 c.lxrd_l3#i.hNCA = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model3: ivreghdfe founders_founder2_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.hNCA = lstate_l3 lfirm_l3), absorb(gvkey firmAge year) cluster(gvkey)
eststo model4: ivreghdfe founders_founder2_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.hNCA = lstate_l3 lfirm_l3), absorb(gvkey firmAge naics4#year) cluster(gvkey)
eststo model5: reghdfe founders_founder2_wso4_at_f3 lxrd_l3 c.lxrd_l3#i.hNCA , absorb(gvkey) cluster(gvkey)
eststo model6: ivreghdfe founders_founder2_wso4_at_f3 (lxrd_l3 c.lxrd_l3#i.hNCA = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model7: ivreghdfe founders_founder2_wso4_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.hNCA = lstate_l3 lfirm_l3), absorb(gvkey firmAge year) cluster(gvkey)
eststo model8: ivreghdfe founders_founder2_wso4_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.hNCA = lstate_l3 lfirm_l3), absorb(gvkey firmAge naics4#year) cluster(gvkey)

estfe . *, labels(naics3#year "NAICS3-Year FE" naics4#year "NAICS4-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Firm Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_iv_founder2_hNCA_l3f3.tex", replace se star(+ 0.2 ++ 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

restore


**** WSO4

eststo clear
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge#naics4#Statecode#year) cluster(gvkey)

estfe . *, labels(firmAge#naics4#Statecode#year "NAICS4-State-Age-Year FE" naics4#year "NAICS4-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_wso4_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(xrd_l3) nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)

estfe . *, labels(naics4#year "NAICS4-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_wso4_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo model1: reghdfe lfounders_founder2_wso4_f3 lxrd_l3, absorb(gvkey) cluster(gvkey)
eststo model3: ivreghdfe lfounders_founder2_wso4_f3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model4: ivreghdfe lfounders_founder2_wso4_f3 zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model6: ivreghdfe lfounders_founder2_wso4_f3 zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey firmAge naics3#year Statecode#year) cluster(gvkey)

estfe . model*, labels(naics3#year "NAICS3-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Firm Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_iv_founder2_wso4_l3f3.tex", replace se star(++ 0.3 + 0.2 * 0.1 ** 0.05 *** 0.01) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

preserve

keep if State == "CA"

eststo clear
eststo model1: reghdfe lfounders_founder2_wso4_f3 lxrd_l3, absorb(gvkey) cluster(gvkey)
eststo model2: reghdfe lfounders_founder2_wso4_f3 lxrd_l3 zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3, absorb(gvkey firmAge naics3#year Statecode#year) cluster(gvkey)
eststo model3: ivreghdfe lfounders_founder2_wso4_f3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model4: ivreghdfe lfounders_founder2_wso4_f3 zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model5: ivreghdfe lfounders_founder2_wso4_f3 zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey firmAge year) cluster(gvkey)
eststo model6: ivreghdfe lfounders_founder2_wso4_f3 zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 = lstate_l3 lfirm_l3), absorb(gvkey firmAge naics3#year Statecode#year) cluster(gvkey)

restore


*gen lfounders_founder2_f3 = log(founders_founder2_f3)




reghdfe lfounders_founder2_f3 lxrd_l3 Tobin_Q lat_l3 lintan_l3 lemp_l3 lch_l3 lsale_l3, absorb(gvkey firmAge Statecode#year naics3#year) cluster(gvkey)




*gen lxrd = log(xrd)

*reghdfe lxrd fw*, absorb(year) cluster(gvkey)

*reghdfe xrd_at treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost0-treatedPost4, absorb(naics4 Statecode year) cluster(gvkey)
*coefplot, keep(treatedPre4 treatedPre3 treatedPre2 treatedPre1 treatedPost0 treatedPost1 treatedPost2 treatedPost3 treatedPost4)
*reghdfe xrd_at
