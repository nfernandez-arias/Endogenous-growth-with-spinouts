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

xtset gvkey year

rename spinoutCount spinoutCountWeighted
label variable spinoutCountUnweighted "Spinouts (unweighted)"

rename spinoutCountUnweighted Spinouts
label variable Spinouts "Spinouts (weighted)"

rename spinoutcountunweighted_onlyexits Exits
label variable Exits "Exits"

rename spinoutsdiscountedexitvalue SpinoutsDiscountedExitValue
label variable SpinoutsDiscountedExitValue "Spinouts (discounted exit value)"

rename spinoutcountunweighted_discounte Spinouts_discounted
label variable Spinouts_discounted "Spinout Count (discounted by time to exit)"


*Run regressions

eststo: quietly reg Spinouts xrd
eststo: quietly reg Spinouts xrd emp
eststo: quietly reg Spinouts xrd_ma3 emp
eststo: quietly reg Spinouts xrd_ma5 emp
esttab using tables/OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly reg SpinoutsDiscountedExitValue xrd
eststo: quietly reg SpinoutsDiscountedExitValue xrd emp
eststo: quietly reg SpinoutsDiscountedExitValue xrd_ma3 emp
eststo: quietly reg SpinoutsDiscountedExitValue xrd_ma5 emp
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

eststo model1: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/OLS_DEV_FE_industry3_age_time.tex, replace stats(clustvar r2 r2_a N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDiscountedExitValue xrd emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_DEV_FE_industry4_age_time.tex, replace stats(clustvar r2 r2_a N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Fixed effects with xrd_ma3

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

eststo model1: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry3_age_time.tex, replace stats(clustvar r2 r2_a N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDiscountedExitValue xrd_ma3 emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry4_age_time.tex, replace stats(clustvar r2 r2_a N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear





