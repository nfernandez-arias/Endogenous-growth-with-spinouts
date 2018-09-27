cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Data\bds_f_agest.dta

rename year2 year

bysort stateNum year: egen estabs_total = total(estabs)
bysort stateNum year: egen emp_total = total(emp)

drop if fage4 != "a) 0"
drop fage4

order year state estabs_entry estabs_entry_rate job_creation job_creation_births net_job_creation net_job_creation_rate *
sort state year

save Data\entry_rates_by_state.dta, replace 

*xtline estabs_entry_rate, i(state) t(year2)

*merge 

*by year2 state fage4, egen entry = total

