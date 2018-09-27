cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear
insheet using "Raw\bds_e_ageisz_st_release.csv"
merge m:1 state using Data\statecodesabbrevs.dta
rename state stateNum
rename stateAbbrev state
save Data\bds_e_ageisz_st.dta, replace

clear
insheet using "Raw\bds_e_agesz_st_release.csv"
merge m:1 state using Data\statecodesabbrevs.dta
rename state stateNum
rename stateAbbrev state
drop _merge
save Data\bds_e_agesz_st.dta, replace

clear
insheet using "Raw\bds_f_ageisz_st_release.csv"
merge m:1 state using Data\statecodesabbrevs.dta
rename state stateNum
rename stateAbbrev state
drop _merge
save Data\bds_f_ageisz_st.dta, replace

clear 
insheet using "Raw\bds_f_agesz_st_release.csv"
merge m:1 state using Data\statecodesabbrevs.dta
rename state stateNum
rename stateAbbrev state
drop _merge
save Data\bds_f_agesz_st.dta, replace

clear 
insheet using "Raw\bds_f_agest_release.csv"
merge m:1 state using Data\statecodesabbrevs.dta
rename state stateNum
rename stateAbbrev state
drop _merge
save Data\bds_f_agest.dta, replace

clear 
insheet using "Raw\bds_e_ageisz_sic_release.csv"
save Data\bds_e_ageisz_sic.dta, replace

clear 
insheet using "Raw\bds_e_agesz_sic_release.csv"
save Data\bds_e_agesz_sic.dta, replace

clear 
insheet using "Raw\bds_f_ageisz_sic_release.csv"
save Data\bds_f_ageisz_sic.dta, replace

clear 
insheet using "Raw\bds_f_agesz_sic_release.csv"
save Data\bds_f_agesz_sic.dta, replace


