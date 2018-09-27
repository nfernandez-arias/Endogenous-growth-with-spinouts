cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Raw/dynass.dta, replace

reshape long pdpco begyr gvkey endyr, i(pdpass) j(spell)

gen nspell = endyr - begyr + 1

expand nspell 

bysort pdpass spell : gen year = begyr[1] + _n - 1

drop if year == .

duplicates tag pdpass year, generate(duptag)
drop if duptag != 0
drop duptag

save Data/dynass_reshaped.dta, replace
