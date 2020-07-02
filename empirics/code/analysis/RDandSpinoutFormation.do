clear all

set more off, permanently

cd "Z:\home\nico\Insync\nfernand@princeton.edu\Google Drive\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

use "data/compustat-spinouts_Stata.dta", clear

encode State, gen(Statecode)

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

gen highNCC = 1 if NCC > 0
replace highNCC = 0 if highNCC == .

gen industry5 = 1 if naics1 == 5
replace industry5 = 0 if industry5 == .

gen industry3 = 1 if naics1 == 3
replace industry3 = 0 if industry3 == .

eststo clear
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey naics4#firmAge naics4#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3  zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey naics4#firmAge naics4#Statecode#year) cluster(gvkey)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge#naics4#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_f3 xrd_l3 c.xrd_l3#i.highNCC zpatentCount_CW_cumulative zemp_l3 zat_l3 zintan_l3 zcapxv_l3 zni_l3 ztobinqat, absorb(gvkey firmAge#naics4#Statecode#year) cluster(gvkey)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_absolute_founder2_highNCC_l3f3.tex", replace se star(* 0.1 ** 0.05 *** 0.01) label keep(*xrd_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

*** Normalized by assets

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey naics4#firmAge naics4#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3  zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey naics4#firmAge naics4#Statecode#year) cluster(gvkey)

estfe . *, labels(_cons "No FE" gvkey "Firm FE" year "Year FE" firmAge "Age FE" naics4#firmAge "Industry-Age FE" naics4#year "Industry-Year FE" Statecode#year "State-Year FE" naics4#Statecode#year "Industry-State-Year FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_l3f3.tex", replace se star(++ 0.2 + 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

eststo clear
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge#naics4#Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, noabsorb cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge naics4#year Statecode#year) cluster(gvkey)
eststo: quietly reghdfe founders_founder2_wso4_at_f3 xrd_at_l3 c.xrd_at_l3#i.highNCC zpatentCount_CW_cumulative_at zemp_at_l3 zintan_at_l3 zcapxv_at_l3 zni_at_l3 zTobin_Q_l3, absorb(gvkey firmAge#naics4#Statecode#year) cluster(gvkey)

estfe . *, labels(firmAge#naics4#Statecode#year "NAICS4-State-Age-Year FE" naics4#year "NAICS4-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_at_founder2_highNCC_l3f3.tex", replace se star(++ 0.2 + 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*xrd_at_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
estfe . *, restore

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
esttab using "figures/tables/RDandSpinoutFormation_iv_founder2_l3f3.tex", replace se star(++ 0.2 + 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
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
eststo model1: reghdfe founders_founder2_at_f3 lxrd_l3 c.lxrd_l3#i.highNCC, absorb(gvkey) cluster(gvkey)
eststo model2: ivreghdfe founders_founder2_at_f3 (lxrd_l3 c.lxrd_l3#i.highNCC = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model3: ivreghdfe founders_founder2_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.highNCC = lstate_l3 lfirm_l3), absorb(gvkey firmAge year) cluster(gvkey)
eststo model4: ivreghdfe founders_founder2_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.highNCC = lstate_l3 lfirm_l3), absorb(gvkey firmAge naics4#year) cluster(gvkey)
eststo model5: reghdfe founders_founder2_wso4_at_f3 lxrd_l3 c.lxrd_l3#i.highNCC , absorb(gvkey) cluster(gvkey)
eststo model6: ivreghdfe founders_founder2_wso4_at_f3 (lxrd_l3 c.lxrd_l3#i.highNCC = lstate_l3 lfirm_l3), absorb(gvkey) cluster(gvkey)
eststo model7: ivreghdfe founders_founder2_wso4_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.highNCC = lstate_l3 lfirm_l3), absorb(gvkey firmAge year) cluster(gvkey)
eststo model8: ivreghdfe founders_founder2_wso4_at_f3 lpatentCount_CW_cumulative zTobin_Q zlat_l3 zlintan_l3 zlemp_l3 zlch_l3 zlsale_l3 (lxrd_l3 c.lxrd_l3#i.highNCC = lstate_l3 lfirm_l3), absorb(gvkey firmAge naics4#year) cluster(gvkey)

estfe . *, labels(naics3#year "NAICS3-Year FE" naics4#year "NAICS4-Year FE" Statecode#year "State-Year FE" gvkey "Firm FE" firmAge "Firm Age FE" Statecode "State FE" naics4 "NAICS 4 FE" year "Year FE" _cons "No FE")
return list
esttab using "figures/tables/RDandSpinoutFormation_iv_founder2_highNCC_l3f3.tex", replace se star(++ 0.2 + 0.15 * 0.1 ** 0.05 *** 0.01) label keep(*lxrd_l3*) indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) booktabs b(a2)
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
