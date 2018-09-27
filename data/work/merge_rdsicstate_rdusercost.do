cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

* First do some cleaning 
u Raw\RDusercost_2017_13.dta

replace state = "Massachusetts" if state == "Massachussetts"
merge m:1 state using Data\stateabbreviations.dta
drop _merge

rename state statename
rename StateAbbrev state


save Data\RDusercost_2017_13.dta, replace

u Data\rd_state_sic.dta

merge m:1 year state using Data\RDusercost_2017_13.dta
keep if _merge == 3 // observations that were not merged have missing variables
drop _merge

save Data\rdstatesic_RDusercost_merged.dta, replace

u Data\rd-by-state.dta, clear

merge m:1 year state using Data\RDusercost_2017_13.dta
keep if _merge == 3
drop _merge

save Data\rd-by-state_RDusercost_merged.dta, replace

