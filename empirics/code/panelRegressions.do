clear all

set more off

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

insheet using "data/compustat-spinouts_Stata.csv"

rename spinoutcountunweighted spinoutCountUnweighted
rename spinoutcount spinoutCount
rename spinoutcountunweighted_ma2 spinoutCountUnweighted_ma2
rename spinoutcount_ma2 spinoutCount_ma2
rename spinoutcountunweighted_ma3 spinoutCountUnweighted_ma3
rename spinoutcount_ma3 spinoutCount_ma3
rename firmage age

rename spinoutindicator spinoutIndicator
rename exitspinoutindicator exitSpinoutIndicator
rename valuablespinoutindicator valuableSpinoutIndicator

encode state, gen(stateCode)

rename spinoutCount spinoutCountWeighted
label variable spinoutCountUnweighted "Spinouts (unweighted)"

rename spinoutCountUnweighted Spinouts
label variable Spinouts "Spinouts (weighted)"

rename spinoutcountunweighted_onlyexits Exits
label variable Exits "Exits"

rename spinoutsdiscountedexitvalue SpinoutsDEV
label variable SpinoutsDEV "Spinouts DEV"

rename spinoutcountunweighted_discounted SpinoutsDTE
label variable SpinoutsDTE "Spinout Count DTE"

label variable xrd "R\&D (millions US\$)"
label variable stateCode "State"
label variable SpinoutsDEV "Spinouts Discounted Exit Value (millions US\$)"
label variable emp Employment
label variable patentcount_cw_ma3 "Patents (CW, ma3)"
label variable patentapplicationcount_cw "Patent Applications (CW)"


*Run regressions

xtset gvkey year

encode naics4year, gen(naics4yearCode)

set emptycells drop


*** Spinout counts: all types

eststo model1: quietly reghdfe Spinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey) cluster(naics4 stateCode)
eststo model2: quietly xtnbreg Spinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe  
eststo model3: quietly poisson Spinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4, robust
eststo model4: quietly xtpoisson Spinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/all_spinoutCount_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
estfe model*, restore
eststo clear

*** Effect of CNC enforcement on R&D - spinout relationship

gen xrdTimesTreatedPost = xrd * treatedpost

eststo model1: quietly reghdfe Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey) cluster(naics4 stateCode)
*eststo model2: quietly xtnbreg Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe  
eststo model3: quietly poisson Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4, robust
eststo model4: quietly xtpoisson Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/all_spinoutCount_regressions_JeffersCourtRulings.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
estfe model*, restore
eststo clear

gen xrdTimesNCC_1991 = xrd * ncc_1991

eststo model1: quietly reghdfe Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(stateCode)
*eststo model2: quietly xtnbreg Spinouts treatedpost i.naics4yearCode, fe  
*eststo model3: quietly poisson Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.naics4, robust
eststo model4: quietly xtpoisson Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe model*, labels(naics4#year "NAICS4-Year FE")
esttab model* using tables/all_spinoutCount_regressions_NCC1991-Starr2018.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
estfe model*, restore
eststo clear


*** Effect of CNC enforcement on spinout generation

eststo model1: quietly reghdfe Spinouts treatedpost, absorb(gvkey naics4#year) cluster(stateCode)
*eststo model2: quietly xtnbreg Spinouts treatedpost i.naics4yearCode, fe  
*eststo model3: quietly poisson Spinouts treatedpost i.naics4yearCode, robust
*eststo model4: quietly xtpoisson Spinouts treatedpost i.naics4yearCode, fe robust
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/noPredictors_spinoutCount_regressions_JeffersCourtRulings.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(treatedpost)
estfe model*, restore
eststo clear

 **** Headlines
 
eststo model1: quietly reghdfe Spinouts xrd emp, absorb(gvkey) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, absorb(gvkey) cluster(naics4 stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey) cluster(naics4 stateCode)
eststo model4: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey) cluster(naics4 stateCode) 
eststo model5: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_cumulative emp, absorb(gvkey) cluster(naics4 stateCode)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE" year "Year FE" gvkey "Parent Firm FE")
esttab model* using tables/rawSpinoutCount_firmFE.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') 
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, absorb(naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, absorb(naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(naics4#year stateCode#year) cluster(naics4 stateCode) 
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative emp, absorb(naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE" year "Year FE" gvkey "Parent Firm FE")
esttab model* using tables/SpinoutDEV_allFixedEffects.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo: quietly xtnbreg Spinouts xrd emp, fe
eststo: quietly xtnbreg Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, fe
eststo: quietly xtnbreg Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp, fe
eststo: quietly xtnbreg Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, fe
esttab using tables/xtnbreg_rawSpinoutCount_firmFE.tex, replace se stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
*estfe model*, restore
eststo clear

eststo: quietly nbreg Spinouts xrd emp
eststo: quietly nbreg Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp
eststo: quietly nbreg Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp
eststo: quietly nbreg Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp
esttab using tables/nbreg_rawSpinoutCount_stateFE.tex, replace se stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none) keep(xrd emp patentcount_cw_cumulative patentcount_cw_ma3 patentapplicationcount_cw_ma3 patentapplicationcount_cw_ma5)
*estfe model*, restore
eststo clear

eststo: quietly xtpoisson Spinouts xrd emp, fe robust
eststo: quietly xtpoisson Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, fe robust
eststo: quietly xtpoisson Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp, fe robust
eststo: quietly xtpoisson Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, fe robust
esttab using tables/xtpoisson_rawSpinoutCount_firmFE.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
*estfe model*, restore
eststo clear

eststo: quietly poisson Spinouts xrd emp i.stateCode, robust
eststo: quietly poisson Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp i.stateCode, robust
eststo: quietly poisson Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp i.stateCode, robust
eststo: quietly poisson Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp i.stateCode, robust
esttab using tables/poisson_rawSpinoutCount_stateFE.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none) keep(xrd emp patentcount_cw_cumulative patentcount_cw_ma3 patentapplicationcount_cw_ma3 patentapplicationcount_cw_ma5)
*estfe model*, restore
eststo clear




 
 
 
 
 ** others
 
 
 
 

eststo: quietly reg Spinouts xrd
eststo: quietly reg Spinouts xrd emp
eststo: quietly reg Spinouts xrd_ma3 emp
eststo: quietly reg Spinouts xrd_ma5 emp
esttab using tables/OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly reg Spinouts patentapplicationcount emp
eststo: quietly reg Spinouts patentapplicationcount_cw emp
eststo: quietly reg Spinouts patentcount emp
eststo: quietly reg Spinouts patentcount_cw emp
esttab using tables/patents_OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly reg Spinouts xrd patentapplicationcount emp
eststo: quietly reg Spinouts xrd patentapplicationcount_cw emp
eststo: quietly reg Spinouts xrd patentcount emp
eststo: quietly reg Spinouts xrd patentcount_cw emp
esttab using tables/patents-xrd_OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear


eststo: quietly reg SpinoutsDEV xrd
eststo: quietly reg SpinoutsDEV xrd emp
eststo: quietly reg SpinoutsDEV xrd_ma3 emp
eststo: quietly reg SpinoutsDEV xrd_ma5 emp
esttab using tables/OLS_discountedExitValue.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly logit spinoutIndicator xrd
eststo: quietly logit spinoutIndicator xrd emp
eststo: quietly logit spinoutIndicator xrd_ma3 emp
eststo: quietly logit spinoutIndicator xrd_ma5 emp
esttab using tables/logit.tex, replace stats(N) mlabels(none)
eststo clear

eststo: quietly logit exitSpinoutIndicator xrd
eststo: quietly logit exitSpinoutIndicator xrd emp
eststo: quietly logit exitSpinoutIndicator xrd_ma3 emp
eststo: quietly logit exitSpinoutIndicator xrd_ma5 emp
esttab using tables/logit_exitsOnly.tex, replace stats(N) mlabels(none)
eststo clear

eststo: quietly logit valuableSpinoutIndicator xrd
eststo: quietly logit valuableSpinoutIndicator xrd emp
eststo: quietly logit valuableSpinoutIndicator xrd_ma3 emp
eststo: quietly logit valuableSpinoutIndicator xrd_ma5 emp
esttab using tables/logit_valuableOnly.tex, replace stats(N) mlabels(none)
eststo clear

* Fixed effects

** Regular spinout count

eststo model1: quietly reghdfe Spinouts xrd emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
return list
esttab model* using tables/OLS_FE_industry2_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
return list
esttab model* using tables/OLS_FE_industry3_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_FE_industry4_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

** Discounted exit value of spinouts spawned in a given year

eststo model1: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
esttab model* using tables/OLS_DEV_FE_industry2_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/OLS_DEV_FE_industry3_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_DEV_FE_industry4_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Fixed effects with xrd_ma3

eststo model1: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
return list
esttab model* using tables/OLS_XRDMA3_FE_industry2_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
return list
esttab model* using tables/OLS_XRDMA3_FE_industry3_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_XRDMA3_FE_industry4_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry2_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry3_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry4_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Patent data

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/patents-xrd_OLS_FE_industry3.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patents-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd_ma3 patentapplicationcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd_ma3 patentapplicationcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model3: quietly reghdfe Spinouts xrd_ma3 patentcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model4: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patentsma3-xrdma3_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentapplicationcount_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model2: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentapplicationcount_cw_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentcount_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentcount_cw_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patentsma3-xrdma3_OLS_DEV_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
*esttab model*, stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear


eststo model1: quietly reghdfe SpinoutsDEV xrd patentapplicationcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patents-xrd_OLS_DEV_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patents-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patentsma3-xrd_OLS_DEV_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patentsma3-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patentsma3-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Regressions for Wharton Innovation Conference Research Proposal

eststo model1: reghdfe Spinouts xrd patentapplicationcount_cw patentcount_cw_ma3 emp, absorb(naics4#year stateCode#year) cluster(gvkey naics4#year stateCode#year)
eststo model2: reghdfe SpinoutsDEV xrd patentapplicationcount_cw patentcount_cw_ma3 emp, absorb(naics4#year stateCode#year) cluster(gvkey naics4#year stateCode#year)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
*esttab model* using "../writings/wharton innovation conference/preliminary_results.tex", replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)')
esttab model*, stats(clustvar r2_a_within N)  indicate(`r(indicate_fe)')
estfe model*, restore
eststo clear









