set more off

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

clear

insheet using "data/compustat-spinouts_Stata.csv"

rename spinoutcountunweighted spinoutCountUnweighted
rename spinoutcount spinoutCount
rename spinoutcountunweighted_ma2 spinoutCountUnweighted_ma2
rename spinoutcount_ma2 spinoutCount_ma2
rename spinoutcountunweighted_ma3 spinoutCountUnweighted_ma3
rename spinoutcount_ma3 spinoutCount_ma3
rename firmage age

encode state, gen(stateCode)

xtset gvkey year

*Run regressions

rename spinoutCountUnweighted Spinouts
label variable Spinouts "Spinouts"

eststo: quietly reg Spinouts xrd
eststo: quietly reg Spinouts xrd emp
eststo: quietly reg Spinouts xrd_ma3 emp
eststo: quietly reg Spinouts xrd_ma5 emp
esttab using tables/OLS.tex, replace stats(r2 r2_a N)
eststo clear

eststo: quietly reg Spinouts xrd_ma3 emp revt
eststo: quietly reg Spinouts xrd_ma3 emp revt act
eststo: quietly reg Spinouts xrd_ma3 emp revt act intan
eststo: quietly reg Spinouts xrd emp revt act intan
esttab using tables/OLS_more-controls.tex, replace stats(r2 r2_a N)
eststo clear

eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(naics4 age year) cluster(gvkey) 
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(naics4 age year) cluster(gvkey year)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(naics4 age year) cluster(naics4 year)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(naics4 age year) cluster(naics4 stateCode)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(naics4 age year) cluster(naics4 stateCode year)
esttab using tables/OLS_FE_industry_age_time.tex, replace stats(vce r2 r2_a N)
eststo clear

eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(gvkey age year) cluster(gvkey)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(gvkey age year) cluster(gvkey year)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(gvkey age year) cluster(naics4 year)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(gvkey age year) cluster(naics4 stateCode)
eststo: quietly reghdfe Spinouts xrd emp revt act intan, absorb(gvkey age year) cluster(naics4 stateCode year)
esttab using tables/OLS_FE_firm_age_time.tex, replace stats(vce r2 r2_a N)
eststo clear


* Basic OLS regression

foreach var in xrd xrd_ma3 xrd_ma5 {

	display "Regression using `var'"
	reg spinoutCountUnweighted `var', vce(robust)

}


* Basic OLS regression with clustered standard errors

display "Clustered standard errors"

foreach var in xrd xrd_ma3 xrd_ma5 {

	display "Regressions using `var'"
	display "Cluster by gvkey"
	reghdfe spinoutCountUnweighted `var', noabsorb vce(cluster gvkey)
	
	display "Cluster by state"
	reghdfe spinoutCountUnweighted `var', noabsorb vce(cluster stateCode)
	
	display "Cluster by naics4"
	reghdfe spinoutCountUnweighted `var', noabsorb vce(cluster naics4)
	
	display "Cluster by naics1"
	reghdfe spinoutCountUnweighted `var', noabsorb vce(cluster naics1) 

	display "Cluster by naics4-state and naics4-year"
	reghdfe spinoutCountUnweighted `var', noabsorb vce(cluster naics4#stateCode naics4#year)

}


* Fixed effects regression with clustered standard errors

display "Fixed effects with clustered standard errors"

foreach var in xrd xrd_ma3 xrd_ma5 {

	display "Naics4, year and naics4-year fixed effects."
	reghdfe spinoutCountUnweighted `var', absorb(naics4 stateCode year naics4#year stateCode#year) vce(cluster naics4#stateCode naics4#year stateCode#year)

}

