cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Raw\rd-performance-to-state-gdp.dta

reshape long RD GDP RD_by_GDP, i(State) j(year)
rename State state

merge m:1 state using Data\stateabbreviations.dta
keep if _merge == 3 // Only US doesn't match, fine bc I only care about state-level
drop _merge

rename state statename
rename StateAbbrev state

order state statename *

save Data\rd-by-state.dta, replace


