cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Data\rdstatesic_RDusercost_merged.dta
drop sic xrd_sic xrd_intensity_sic
duplicates drop



merge 1:1 state year using Data\entry_rates_by_state.dta

/*

drop if _merge != 3

* Declare panel data (need to use number to encode state)
xtset stateNum year

** Using RD intensity

* Run with establishment entry rate
xtreg estabs_entry_rate xrd_intensity_state  i.year, fe

* Run with job creation rate
xtreg net_job_creation_rate xrd_intensity_state i.year, fe

** Using RD spending

** estab entry rate
xtreg estabs_entry_rate xrd_state i.year, fe

** job creation rate
xtreg estabs_entry_rate xrd_state i.year, fe
