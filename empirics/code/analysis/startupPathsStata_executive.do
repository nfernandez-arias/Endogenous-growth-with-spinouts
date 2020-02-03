preserve

keep if entity_executive == 1

eststo clear

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

	eststo: quietly reghdfe `var' ib0.entityage##ib0.entity_executive_frompublic, noabsorb cluster(statecode naics1_4 year)
	coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
	graph export "figures/plots/startupLifeCycle_executivefounders_regs_`var'.pdf", replace

	*esttab model`var' using "figures/tables/startupLifeCycle_regs_`var'.csv", replace se drop(*0.entity_executive_frompublic *.entityage 0*)

}

esttab using "figures/tables/startupLifeCycle_executivefounders_regs_all.csv", replace se drop(*0.entity_executive_frompublic *.entityage 0*)
esttab using "figures/tables/startupLifeCycle_executivefounders_regs_all.tex", replace se drop(_cons *0.entity_executive_frompublic *.entityage 0*)

eststo clear

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

	eststo: quietly reghdfe `var' ib0.entityage##ib0.entity_executive_frompublic, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(entityid)
	coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
	graph export "figures/plots/startupLifeCycle_executivefounders_regs_`var'_FE_smallClusters.pdf", replace

	*esttab model`var' using "figures/tables/startupLifeCycle_regs_`var'_FE.csv", replace se drop(*0.entity_executive_frompublic *.entityage 0*)

}

esttab using "figures/tables/startupLifeCycle_executivefounders_regs_all_FE_smallClusters.csv", replace se drop(*0.entity_executive_frompublic *.entityage 0*)
esttab using "figures/tables/startupLifeCycle_executivefounders_regs_all_FE_smallClusters.tex", replace se drop(_cons *0.entity_executive_frompublic *.entityage 0*)

eststo clear

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

	eststo: quietly reghdfe `var' ib0.entityage##ib0.entity_executive_frompublic, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
	graph export "figures/plots/startupLifeCycle_executivefounders_regs_`var'_FE.pdf", replace

	*esttab model`var' using "figures/tables/startupLifeCycle_regs_`var'_FE.csv", replace se drop(*0.entity_executive_frompublic *.entityage 0*)

}

esttab using "figures/tables/startupLifeCycle_executivefounders_regs_all_FE.csv", replace se drop(*0.entity_executive_frompublic *.entityage 0*)
esttab using "figures/tables/startupLifeCycle_executivefounders_regs_all_FE.tex", replace se drop(_cons *0.entity_executive_frompublic *.entityage 0*)

keep if entity_executive_frompublic == 1

foreach wso of varlist entity_executive_wso1-entity_executive_wso4 {

	eststo clear

		foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

		eststo: quietly reghdfe `var' ib0.entityage##ib0.`wso', noabsorb cluster(entityid)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "figures/plots/startupLifeCycle_executivefounders_regs_`wso'_`var'_smallClusters.pdf", replace

		*esttab model`var' using "figures/tables/startupLifeCycle_regs_`wso'_noclustering_`var'.csv", replace se drop(*0.`wso' *.entityage 0*)

	}

	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all_smallClusters.csv", replace se drop(*0.`wso' *.entityage 0*)
	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all_smallClusters.tex", replace se drop(_cons *0.`wso' *.entityage 0*)

	eststo clear

	foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

		eststo: quietly reghdfe `var' ib0.entityage##ib0.`wso', noabsorb cluster(statecode naics1_4 year)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "figures/plots/startupLifeCycle_executivefounders_regs_`wso'_`var'.pdf", replace

		*esttab model`var' using "figures/tables/startupLifeCycle_regs_`wso'_`var'.csv", replace se drop(*0.`wso' *.entityage 0*)

	}

	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all.csv", replace se drop(*0.`wso' *.entityage 0*)
	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all.tex", replace se drop(_cons *0.`wso' *.entityage 0*)

	eststo clear

	foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

		eststo: quietly reghdfe `var' ib0.entityage##ib0.`wso', absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(entityid)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "figures/plots/startupLifeCycle_executivefounders_regs_`wso'_`var'_FE_smallClusters.pdf", replace

		*esttab `modelvar' using "figures/tables/startupLifeCycle_regs_`wso'_`var'_FE.csv", replace se drop(*0.`wso'  *.entityage 0*)

	}

	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all_FE_smallClusters.csv", replace se drop(*0.`wso'  *.entityage 0*)
	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all_FE_smallClusters.tex", replace se drop(_cons *0.`wso'  *.entityage 0*)

	eststo clear

	foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {

		eststo: quietly reghdfe `var' ib0.entityage##ib0.`wso', absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "figures/plots/startupLifeCycle_executivefounders_regs_`wso'_`var'_FE.pdf", replace

		*esttab `modelvar' using "figures/tables/startupLifeCycle_regs_`wso'_`var'_FE.csv", replace se drop(*0.`wso'  *.entityage 0*)

	}

	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all_FE.csv", replace se drop(*0.`wso'  *.entityage 0*)
	esttab using "figures/tables/startupLifeCycle_executivefounders_regs_`wso'_all_FE.tex", replace se drop(_cons *0.`wso'  *.entityage 0*)

}

restore
