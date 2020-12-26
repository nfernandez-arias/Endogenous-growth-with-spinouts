preserve

keep if entity_founder2 == 1

label variable entity_founder2_wso4 "$\frac{\text{Spinout founders}}{\text{Total founders}}$"
label variable entity_founder2_wso4 "$\frac{\text{WSO4 founders}}{\text{Total founders}}$"


foreach var of varlist lemployeecount lpostvalusd lrevenue {

	gen `var'_founder2 = `var' - log(entity_founder2_count)

}


foreach var of varlist lemployeecount_founder2 lpostvalusd_founder2 lrevenue_founder2 goingoutofbusiness successfullyexiting {

	eststo clear

	eststo: quietly reghdfe `var' entity_founder2_wso4, noabsorb cluster(statecode naics1_4)
	eststo: quietly reghdfe `var' entity_founder2_wso4, absorb(statecode#year statecode#entityage naics1_4##year naics1_4##entityage) cluster(statecode naics1_4)
	eststo: quietly reghdfe `var' entity_founder2_wso4, absorb(statecode#year statecode#foundingyear naics1_4##year naics1_4##foundingyear) cluster(statecode naics1_4)
	eststo: quietly reghdfe `var' entity_founder2_wso4, absorb(statecode#foundingyear statecode#entityage naics1_4##foundingyear naics1_4##entityage) cluster(statecode naics1_4)

	estfe . *, labels(statecode#year "State-Year FE" statecode#entityage "State-Age FE" statecode#foundingyear "State-Cohort FE" naics1_4#year "NAICS4-Year FE" naics1_4#entityage "NAICS4-Age FE" naics1_4#foundingyear "NAICS4-Cohort FE" _cons "No FE")
	esttab using "figures/tables/startupLifeCycle_founder2founders_regs_`var'_overall.tex", replace se star(* 0.1 ** 0.05 *** 0.01) keep(*entity_founder2*) label nomtitles indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ") style(tex) booktabs b(a2)
	esttab using "figures/tables/startupLifeCycle_founder2founders_regs_`var'_overall.csv", replace se star(* 0.1 ** 0.05 *** 0.01) keep(*entity_founder2*) label nomtitles indicate(`r(indicate_fe)') stats(clustvar r2_a r2_a_within N, labels(Clustering "R-squared (adj.)" "R-squared (within, adj)" Observations)) interaction(" $\times$ ")

	estfe . *, restore

	eststo clear

}



restore
