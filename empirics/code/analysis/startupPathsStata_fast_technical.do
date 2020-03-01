preserve

keep if entity_technical == 1

label variable entity_technical_frompublic "Spinout"
label variable entity_technical_wso4 "WSO4"

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness successfullyexiting lpostvalusddivemployeecount lrevenuedivemployeecount {

	eststo clear

	eststo: quietly reghdfe `var' ib0.entity_technical_frompublic, noabsorb cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_technical_frompublic, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_technical_frompublic, absorb(statecode##naics1_4##year statecode##naics1_4##foundingyear) cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_technical_frompublic, absorb(statecode##naics1_4##foundingyear statecode##naics1_4##entityage) cluster(statecode naics1_4 year)

	estfe . *, labels(statecode#naics1_4#year "State-NAICS4-Year FE" statecode#naics1_4#entityage "State-NAICS4-Age FE" statecode#naics1_4#foundingyear "State-NAICS4-Cohort FE")
	esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_`var'_overall.tex", replace se star(* 0.1 ** 0.05 *** 0.01) keep(_cons *1.entity_technical*) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) b(a2)
	esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_`var'_overall.csv", replace se star(* 0.1 ** 0.05 *** 0.01) keep(_cons *1.entity_technical*) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ")

	estfe . *, restore

	eststo clear

	*eststo: quietly reghdfe `var' ib0.entityage##ib0.entity_technical_frompublic, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	*coefplot, drop(_cons *.entityage *naics* *state*) title("`var': Spinouts vs. non-spinouts")
	*graph export "figures/plots/startupLifeCycle_technicalfounders_regs_`var'_FE.pdf", replace

	*estfe . *, labels(statecode#naics1_4#year "State-NAICS4-Year FE" statecode#naics1_4#entityage "State-NAICS4-Age FE")
	*esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_`var'.tex", replace se keep(_cons *1.entity_technical*) nomtitles label nobaselevels indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex)
	*esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_`var'.csv", replace se keep(_cons *1.entity_technical*) nomtitles label nobaselevels indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ")

	*estfe . *, restore

}

keep if entity_technical_frompublic == 1

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness successfullyexiting lpostvalusddivemployeecount lrevenuedivemployeecount {

	eststo clear

	eststo: quietly reghdfe `var' ib0.entity_technical_wso4, noabsorb cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_technical_wso4, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_technical_wso4, absorb(statecode##naics1_4##year statecode##naics1_4##foundingyear) cluster(statecode naics1_4 year)
	eststo: quietly reghdfe `var' ib0.entity_technical_wso4, absorb(statecode##naics1_4##foundingyear statecode##naics1_4##entityage) cluster(statecode naics1_4 year)


	estfe . *, labels(statecode#naics1_4#year "State-NAICS4-Year FE" statecode#naics1_4#entityage "State-NAICS4-Age FE" statecode#naics1_4#foundingyear "State-NAICS4-Cohort FE")
	esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_wso4_`var'_overall.tex", replace se star(* 0.1 ** 0.05 *** 0.01) keep(_cons *1.entity_technical*) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex) b(a2)
	esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_wso4_`var'_overall.csv", replace se star(* 0.1 ** 0.05 *** 0.01) keep(_cons *1.entity_technical*) label nomtitles indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ")

	estfe . *, restore

	*eststo clear

	*eststo: quietly reghdfe `var' ib0.entityage##ib0.entity_technical_wso4, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	*coefplot, drop(_cons *.entityage *naics* *state*) title("`var': WSO4 vs non-WSO4 spinouts")
	*graph export "figures/plots/startupLifeCycle_technicalfounders_regs_`var'_wso4_FE.pdf", replace

	*estfe . *, labels(statecode#naics1_4#year "State-NAICS4-Year FE" statecode#naics1_4#entityage "State-NAICS4-Age FE")
	*esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_wso4_`var'.tex", replace se keep(_cons *1.entity_technical*) label nobaselevels indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ") style(tex)
	*esttab using "figures/tables/startupLifeCycle_technicalfounders_regs_wso4_`var'.csv", replace se keep(_cons *1.entity_technical*) label nobaselevels indicate(`r(indicate_fe)') stats(r2_a r2_a_within N) interaction(" $\times$ ")

	*estfe . *, restore

}

restore
