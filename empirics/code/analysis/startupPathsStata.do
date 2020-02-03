clear all

set more off
set matsize 10000

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

insheet using "data/VentureSource/startupsPathsStata.csv"

encode(state), gen(statecode)

keep if entityage <= 20

xtset(entityid year)

* Spinouts vs non-Spinouts

do code/analysis/startupPathsStata_all.do

do code/analysis/startupPathsStata_founder2.do

do code/analysis/startupPathsStata_executive.do

do code/analysis/startupPathsStata_technical.do

