cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Raw\business-performed-rd-to-private-industry-output.dta

reshape long RD OUTPUT RD_OUTPUT, i(State) j(year)
rename State state

merge m:1 state using Data\stateabbreviations.dta
keep if _merge == 3 // Only US doesn't match, fine bc I only care about state-level
drop _merge

rename state statename
rename StateAbbrev state

order state statename *

save Data\business-performed-rd-by-state.dta, replace
