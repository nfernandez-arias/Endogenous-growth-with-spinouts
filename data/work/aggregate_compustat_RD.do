cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Raw\compustat_annual_13.dta

* Select sample
keep year loc fic incorp state city sic sale ppent xrd
keep if loc == "USA"
drop if mi(state)

* Aggregate RD by STATE
bysort year state: egen xrd_state = total(xrd)
bysort year state: egen sale_state = total(sale)
gen xrd_intensity_state = xrd_state / sale_state

* Aggregate R&D by SIC
bysort year sic: egen xrd_sic = total(xrd)
bysort year sic: egen sale_sic = total(sale)
gen xrd_intensity_sic = xrd_sic / sale_sic

* Save resulting dataset for analysis
keep year state sic xrd_state xrd_intensity_state xrd_sic xrd_intensity_sic
save Data\rd_state_sic.dta, replace






