preserve

keep if entity_founder2 == 1

label variable entity_founder2_frompublic "Spinout"
label variable entity_founder2_wso4 "WSO4"

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness successfullyexiting lpostvalusddivemployeecount lrevenuedivemployeecount {

	eststo clear

	eststo: quietly reghdfe `var' ib0.entity_founder2_frompublic ib0.entity_founder2_wso4, noabsorb cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_founder2_frompublic ib0.entity_founder2_wso4, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_founder2_frompublic ib0.entity_founder2_wso4, absorb(statecode##naics1_4##year statecode##naics1_4##foundingyear) cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_founder2_frompublic ib0.entity_founder2_wso4, absorb(statecode##naics1_4##foundingyear statecode##naics1_4##entityage) cluster(statecode naics1_4 year)

	estfe . *, labels(statecode#naics1_4#year "State-NAICS4-Year FE" statecode#naics1_4#entityage "State-NAICS4-Age FE" statecode#naics1_4#foundingyear "State-NAICS4-Cohort FE" _cons "No FE")
	esttab using "figures/tables/startupLifeCycle_founder2founders_regs_`var'_overall.tex", replace se star(* 0.1 ** 0.05 *** 0.01) keep(_cons *1.entity_founder2*) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) b(a2)
	esttab using "figures/tables/startupLifeCycle_founder2founders_regs_`var'_overall.csv", replace se star(* 0.1 ** 0.05 *** 0.01) keep(_cons *1.entity_founder2*) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ")

	estfe . *, restore

	eststo clear

}

foreach var of varlist goingoutofbusiness successfullyexiting {

	eststo clear

}


restore
