u Data\business-performed-rd-by-state.dta, clear

merge m:1 year state using Data\RDusercost_2017_13.dta
keep if _merge == 3
drop _merge

save Data\private-performed-rd-by-state_RDusercost_merged.dta, replace
