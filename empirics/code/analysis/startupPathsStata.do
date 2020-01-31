clear all

set more off
set matsize 10000

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

insheet using "data/VentureSource/startupsPathsStata.csv"

encode(state), gen(statecode)

keep if entityage <= 20

xtset(entityid year)

* Spinouts vs non-Spinouts

eststo clear

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {
	
	eststo `var': quietly reghdfe `var' ib0.entityage##ib0.entityfrompublic, noabsorb cluster(statecode naics1_4 year)
	coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
	graph export "../figures/startupLifeCycle_regs_`var'.pdf", replace
	
	esttab model`var' using "../figures/tables/startupLifeCycle_regs_`var'.csv", replace se drop(*0.entityfrompublic *.entityage 0*) 
		
}

esttab using "../figures/tables/startupLifeCycle_regs_all.tex", replace se drop(_cons *0.entityfrompublic *.entityage 0*) 

eststo clear

foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {
	
	eststo model`var': quietly reghdfe `var' ib0.entityage##ib0.entityfrompublic, absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
	coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
	graph export "../figures/startupLifeCycle_regs_`var'_FE.pdf", replace
	
	esttab model`var' using "../figures/tables/startupLifeCycle_regs_`var'_FE.csv", replace se drop(*0.entityfrompublic *.entityage 0*) 
		
}

esttab using "../figures/tables/startupLifeCycle_regs_all_FE.tex", replace se drop(_cons *0.entityfrompublic *.entityage 0*) 

keep if entityfrompublic == 1

foreach wso of varlist entitywso1-entitywso4 {

	eststo clear
	
		foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {
		
		eststo model`var': quietly reghdfe `var' ib0.entityage##ib0.`wso', noabsorb cluster(entityid year)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "../figures/startupLifeCycle_regs_`wso'_`var'.pdf", replace
		
		esttab model`var' using "../figures/tables/startupLifeCycle_regs_`wso'_noclustering_`var'.csv", replace se drop(*0.`wso' *.entityage 0*) 
			
	}

	esttab using "../figures/tables/startupLifeCycle_regs_`wso'_all.tex", replace se drop(_cons *0.`wso' *.entityage 0*) 

	eststo clear

	foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {
		
		eststo model`var': quietly reghdfe `var' ib0.entityage##ib0.`wso', noabsorb cluster(statecode naics1_4 year)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "../figures/startupLifeCycle_regs_`wso'_`var'.pdf", replace
		
		esttab model`var' using "../figures/tables/startupLifeCycle_regs_`wso'_`var'.csv", replace se drop(*0.`wso' *.entityage 0*) 
			
	}

	esttab using "../figures/tables/startupLifeCycle_regs_`wso'_all.tex", replace se drop(_cons *0.`wso' *.entityage 0*) 

	eststo clear

	foreach var of varlist lemployeecount lpostvalusd lrevenue goingoutofbusiness lpostvalusddivemployeecount lrevenuedivemployeecount {
		
		eststo model`var': quietly reghdfe `var' ib0.entityage##ib0.`wso', absorb(statecode##naics1_4##year statecode##naics1_4##entityage) cluster(statecode naics1_4 year)
		coefplot, drop(_cons *.entityage *naics* *state*) title("`var'")
		graph export "../figures/startupLifeCycle_`wso'_regs_`var'_FE.pdf", replace
		
		esttab `modelvar' using "../figures/tables/startupLifeCycle_regs_`wso'_`var'_FE.csv", replace se drop(*0.`wso'  *.entityage 0*) 
			
	}

	esttab using "../figures/tables/startupLifeCycle_regs_`wso'_all_FE.tex", replace se drop(_cons *0.`wso'  *.entityage 0*) 

}

