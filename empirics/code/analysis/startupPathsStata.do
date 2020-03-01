clear all

set more off, permanently
set matsize 10000, permanently

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

insheet using "data/VentureSource/startupsPathsStata.csv"

encode(state), gen(statecode)

keep if entityage <= 20

xtset(entityid year)

label variable entityage "Age"
label variable foundingyear "Cohort"
label variable lemployeecount "log(Employment)"
label variable lpostvalusd "log(Valuation)"
label variable lrevenue "log(Revenue)"
label variable goingoutofbusiness "Out of business (hazard)"
label variable successfullyexiting "IPO / Acquisition (hazard)"
label variable lpostvalusddivemployeecount "log(Valuation / Employee)"
label variable lrevenuedivemployeecount "log(Revenue / Employee)"

* Spinouts vs non-Spinouts

*do code/analysis/startupPathsStata_all.do
do code/analysis/startupPathsStata_fast_all.do

*do code/analysis/startupPathsStata_founder2.do
do code/analysis/startupPathsStata_fast_founder2.do

do code/analysis/startupPathsStata_fast_executive.do

do code/analysis/startupPathsStata_fast_technical.do
