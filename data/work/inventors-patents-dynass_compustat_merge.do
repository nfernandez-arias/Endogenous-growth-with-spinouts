cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Data\patents-inventors-gvkey.dta

merge m:1 gvkey year using Raw\compustat_annual_13.dta
