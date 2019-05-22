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



encode state, gen(stateCode)

xtset gvkey year

* Generate state-year, naics4-year, gvkey-year catgories for clustering purposes
foreach var in year gvkey naics1 naics2 naics3 naics4 {
	tostring `var', g(p`var') 
}

foreach var in pnaics1 pnaics2 pnaics3 pnaics4 {
	local varname = substr("`var'",2,.)
	gen `var'_state = `var'+"-"+state
	encode `var'_state, gen(`var'_state_encode)
	drop `var'_state
	rename `var'_state_encode `varname'_state
	
	gen `var'_year = `var'+"-"+pyear
	encode `var'_year, gen(`var'_year_encode)
	drop `var'_year
	drop `var'
	rename `var'_year_encode `varname'_year
}

*Run regressions

reghdfe spinoutCountUnweighted xrd_ma5 emp, absorb(naics4#year state) vce(cluster naics4 state)


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

