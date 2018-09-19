cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Data\patents_inventors.dta

merge m:1 pdpass year using Data\dynass_reshaped.dta 

rename _merge _merge1

save Data\patents-inventors-gvkey.dta, replace
