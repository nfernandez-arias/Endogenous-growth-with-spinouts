cd "C:\Google_Drive_Princeton\PhD - Big boy\Research\Endogenous growth with worker flows and noncompetes\data\work"

clear

u Raw\pat76_06_assg.dta, replace

joinby patent using Raw\inventor.dta

*joinby pdpass using dynass.dta


rename appyear year




save Data/patents_inventors.dta, replace







*merge m:1 patent 











* count number of assignees for each patent
*by patent: egen nass = count(pdpass)

