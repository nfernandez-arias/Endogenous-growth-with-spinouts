*MAIN RESULTS PROGRAM: Replicates the results from Bloom, Schankerman and Van Reenen (2010)
*Nick Bloom, July 2013, nbloom@stanford.edu
set more off
clear all
cap clear mata
cap clear matrix
set memory 250m
set matsize 8000
cap ssc install newey2

cap log close

*Note 1: this was run in stata version 11.2
*Note 2: if running for the first time you might want to change the name of the log file so you can compare 
*Note 3: The Newey-West SEs are slow so you can drop this (or go to clustering alonside using areg) to speed this up. But NW are appropriate. 
	*NW assumes an AR(1) error process, which because of fixed-effects and perpetual inventory method to generate all R&D stocks is what any error structure is likely to look
	*Clustering is an alternative but allows for full cross-period error dependence, which in long-panels of yearly data with FEs and moderate sized N is over conservative

log using BSV_replication,replace t

*************************************
di "Summary statistics"
di "Table 2" 
*************************************
clear all
u spillovers
su tobinq rmkvaf grd grd_k1 rxrd gspilltec gspillsic pat_count pat_cite rsales rppent emp if year>=1981&year<=2001,det
di  _newline(10)

************************************* 
di "Market value equations"
di "Table 3" 
*************************************
clear all
u spillovers
replace lgspilltec1=. if lgspillsic1==.
cap tsset num year

di "Column1"
qui newey2 lq grd_k1 grd_k1_dum lgspilltec1 lgspillsic1 grd_kt* lsales_ind lsales_ind1  yy* if year>1984&year<2001,force lag(1)
newey2
di  _newline(10)
keep if e(sample)

di "Column2"
cap drop yy*
cap qui tab year,gen(yy)
cap drop nnn*
cap qui tab num,gen(nnn)
qui newey2 lq grd_k1 grd_k1_dum lgspilltec1 lgspillsic1 grd_kt* lsales_ind lsales_ind1  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Generating numbers in the text"
su rmkvaf gspilltec gspillsic if e(sample)
di "Value of spilltec"
di (4256.093/23716.01)*_b[lgspilltec1]
di (4256.093/7023.869)*_b[lgspillsic1]
su tobinq grd_k1 if e(sample)&grd_k1_dum==0
di "elasticity evaluated at regression sample mean: defined at dlq/[dG_A/G_A]"
di 0.6658132*((_b[grd_k1]+2*.6658132*_b[grd_kt2]+3*.6658132^2*_b[grd_kt3]+4*.6658132^3*_b[grd_kt4]+5*.6658132^4*_b[grd_kt5]))
di "Value of an extra unit of R&D stock"
di 2.678941*(_b[grd_k1]+2*.6658132*_b[grd_kt2]+3*.6658132^2*_b[grd_kt3]+4*.6658132^3*_b[grd_kt4]+5*.6658132^4*_b[grd_kt5])
di "Note to test can not have powers"
test 2.678941*(_b[grd_k1]+2*.6658132*_b[grd_kt2]+3*.44330722*_b[grd_kt3]+4*.2951598*_b[grd_kt4]+5*.19652129*_b[grd_kt5])=1

di "Footnote: using linear rather than high-order expansionColumn2"
qui newey2 lq grd_k1 grd_k1_dum lgspilltec1 lgspillsic1 lsales_ind lsales_ind1  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column3"
qui newey2 lq grd_k1 grd_k1_dum lgspilltec1             grd_kt* lsales_ind lsales_ind1  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column4"
qui newey2 lq grd_k1 grd_k1_dum             lgspillsic1 grd_kt* lsales_ind lsales_ind1  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column5"
qui newey2 lq grd_k1 grd_k1_dum lgspillmaltec1 lgspillmalsic1 grd_kt* lsales_ind lsales_ind1  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column6"
qui newey2 lq grd_k1 grd_k1_dum grd_kt* (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lfirm firm_dum lstate lsales_ind lsales_ind1  yy* nnn* ,force lag(1)
newey2
*To get first stage F-tests, noting that newey2 does not produce these so need to use ivreg2 with clustering (which is conservative as allows full cross correlation of errors across time despite this being 20 years of data)
ivreg2 lq grd_k1 grd_k1_dum grd_kt* (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lfirm firm_dum lstate lsales_ind lsales_ind1  yy* nnn* ,first cluster(num) partial(yy* nnn*)
di  _newline(10)

*For Table 8 row D, Jaffe Covariance distance measure
di "For Table 8 row D"
newey2 lq grd_k1 grd_k1_dum lgspillcovtec1 lgspillcovsic1 grd_kt* lsales_ind lsales_ind1  yy* nnn*,force lag(1)
di  _newline(10)


************************************* 
di "Patent equations"
di "Table 4" 
*************************************
clear all
u spillovers
keep if year<1999&year>(fyear+prior_years)&lgspillsic1~=.
*keep the arbitrary base industry common across regressions (brokerage). Merge software together as otherwise does not produce standard errors as too many industry codes
replace sic=999 if sic==6211
replace sic=7373 if sic==7370 

qui tab sic,gen(jjj)

drop jjj1

di "Column 1"
qui nbreg pat_cite lgrd1 lgrd1_dum  lgspilltec1 lgspillsic1 lsales1 jjj*    yy*, cluster(i) 
nbreg
di  _newline(10)
keep if e(sample)

di "Column 2"
qui nbreg pat_cite lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum  jjj*    yy*, cluster(i)  
nbreg
di  _newline(10)

di "Column 3"
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(i)  
nbreg
di  _newline(10)

di "Column 4"
*(note this differs slighlty from the text due to different industry  baseline dummy, but qualitatively the same)
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspillmaltec1 lgspillmalsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(i)  
nbreg
di  _newline(10)

*JAFFE IV
di "Columns 5, control function for IV"
*First get residuals for lgspilltec1
qui reg lgspilltec1  lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy* if pat_cite~=.,cluster(i)
qui predict _tec,res
qui areg lgspilltec1  lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy* if pat_cite~=.,cluster(i) ab(num)
test lgspilltecIV1 lgspillsicIV1
*Then get residuals for lgspillsic1
qui areg lgspillsic1 lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*  if pat_cite~=.,cluster(i) ab(num)
qui predict _sic,res
qui areg lgspillsic1  lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy* if pat_cite~=.,cluster(i) ab(num)
test lgspilltecIV1 lgspillsicIV1
qui forv i=2(1)5 {
qui gen _tec`i'=(_tec^`i')
qui gen _sic`i'=(_sic^`i')
}
*Then add residuals in, use up for fifth power, although results very similar even with first power
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgspilltec1 lgspillsic1 _tec* _sic* lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(i)  
test _tec _tec2 _tec3 _tec4 _tec5 _sic _sic2 _sic3 _sic4 _sic5
nbreg

*For Table 8 row D, Jaffe Covariance distance measure
di "For Table 8 row D"
nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspillcovtec1 lgspillcovsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(i)  
di  _newline(10)


********************************************
di "Productivity equations"
di "TABLE 5"
********************************************
clear all
u spillovers,clear
keep if year>1984&year<2001&lgspillsic1~=.

di "Column1"
tsset num year
qui newey2 lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales_ind lsales_ind1  lpind_ind  yy*,force lag(1)
newey2
di  _newline(10)

keep if e(sample)
cap qui tab num,gen(nnn)

di "Column2"
qui newey2 lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales_ind lsales_ind1  lpind_ind  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column3"
qui newey2 lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspilltec1             lsales_ind lsales_ind1  lpind_ind  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column4, Mahalanobis"
qui newey2 lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspillmaltec1 lgspillmalsic1 lsales_ind lsales_ind1  lpind_ind  yy* nnn*,force lag(1)
newey2
di  _newline(10)

di "Column5, IV"
***JAFFE
newey2 lsales lemp1 lppent1 lgrd1 lgrd1_dum (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lsales_ind lsales_ind1  lpind_ind  yy* nnn*,first force lag(1)
*To get first stage F-tests, noting that newey2 does not produce these so need to use ivreg2 with clustering (which is conservative)
ivreg2 lsales lemp1 lppent1 lgrd1 lgrd1_dum (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lsales_ind lsales_ind1  lpind_ind  yy* nnn*,first cluster(num) partial(yy* nnn*)
di  _newline(10)


*For Table 8 row D, Jaffe Covariance distance measure
di "For Table 8 row d"
newey2 lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspillcovtec1 lgspillcovsic1 lsales_ind lsales_ind1  lpind_ind  yy* nnn*,force lag(1)
di  _newline(10)




*************************************
di "R&D equation"
di "TABLE 6"
*************************************
clear all
u spillovers,clear
so num year 
tsset num year

di "Column1"
qui newey2 lxrd_sales             lgspilltec1  lgspillsic1 lsales_ind lsales_ind1  yy*, force lag(1)
newey2
di  _newline(10)
keep if e(sample)
cap qui tab num,gen(nnn)

di "Column2"
qui newey2 lxrd_sales             lgspilltec1  lgspillsic1 lsales_ind lsales_ind1  yy* nnn*, force lag(1)
newey2
di  _newline(10)

di "Column3"
qui newey2 lxrd_sales lxrd_sales1 lgspilltec1  lgspillsic1 lsales_ind lsales_ind1  yy* nnn*, force lag(1)
newey2
test lgspilltec1 lgspillsic1
di  _newline(10)

di "Column4"
qui newey2 lxrd_sales             lgspillmaltec1  lgspillmalsic1 lsales_ind lsales_ind1  yy* nnn*, force lag(1)
newey2
di  _newline(10)

di "Column5, IV"
newey2 lxrd_sales lfirm firm_dum lstate  (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lsales_ind lsales_ind1  yy* nnn*,first force lag(1)
*To get first stage F-tests, noting that newey2 does not produce these so need to use ivreg2 with clustering (which is conservative)
ivreg2 lxrd_sales lfirm firm_dum lstate  (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lsales_ind lsales_ind1  yy* nnn*,first cluster(num) partial(yy* nnn*)
di  _newline(10)

*For Table 8 row D, Jaffe Covariance distance measure
di "For Table 8 row D"
newey2 lxrd_sales             lgspillcovtec1  lgspillcovsic1 lsales_ind lsales_ind1  yy* nnn*, force lag(1)
di  _newline(10)


*************************************
di "Comparison of results to theory table"
di "TABLE 7"
*************************************



*************************************
di "GEOGRAPHIC"
di "TABLE 8"
*************************************

di "Column1"
*Market value
u spillovers,clear
keep  if year>1984&year<2001
gen lgspilltectloc1_dum=(lgspilltectloc1==.)
replace lgspilltectloc1=0 if lgspilltectloc1==.
gen lgspillsictloc1_dum=(lgspillsictloc1==.)
replace lgspillsictloc1=0 if lgspillsictloc1==.
so num year
qui tab num,gen(nnn)
tsset num year
qui newey lq grd_k1 grd_k1_dum lgspilltec1 lgspilltectloc1* lgspillsic1 lgspillsicsloc1 grd_kt* lsales_ind lsales_ind1  yy* nnn* if year>1984&year<2001, force lag(1)
newey
di  _newline(10)

*Footnotes: With full tloc and sloc interactions & levels
qui newey lq grd_k1 grd_k1_dum lgspilltec1 lgspilltectloc1* lgspilltecsloc1* lgspillsic1 lgspillsictloc1* lgspillsicsloc1* lgspilltloc1 lgspillsloc1 grd_kt* lsales_ind lsales_ind1  yy* nnn* if year>1984&year<2001, force lag(1)
*Footnotes: With full tloc and sloc interactions
qui newey lq grd_k1 grd_k1_dum lgspilltec1 lgspilltectloc1* lgspilltecsloc1* lgspillsic1 lgspillsictloc1* lgspillsicsloc1* grd_kt* lsales_ind lsales_ind1  yy* nnn* if year>1984&year<2001, force lag(1)


di "Column2"
*Patents
u spillovers,clear
gen lgspilltectloc1_dum=(lgspilltectloc1==.)
replace lgspilltectloc1=0 if lgspilltectloc1==.
so num year
keep if year<1999&year>(fyear+prior_years)
replace sic=999 if sic==6211
replace sic=7373 if sic==7370 
qui tab sic,gen(jjj)
drop jjj1
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspilltec1 lgspilltectloc1* lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy* if year<1999&year>(fyear+prior_years), cluster(i)  
nbreg
*Nothing different for patent counts
*qui nbreg pat_count lpat_count1 lpat_count1_dum lgrd1 lgrd1_dum lgspilltec1 lgspilltectloc1* lsales1 lpriorpat lpriorpat_dum jjj*  yy* if year<1999&year>(fyear+prior_years), cluster(i)  
di  _newline(10)


di "Column 3"
*"Productivity equations"
u spillovers,clear
gen lgspilltectloc1_dum=(lgspilltectloc1==.)
replace lgspilltectloc1=0 if lgspilltectloc1==.
keep if year>1984&year<2001
cap qui tab num,gen(nnn)
so num year
tsset num year
qui newey lsales lemp1  lppent1 lgrd1 lgrd1_dum 							lgspilltec1 lgspilltectloc1* lsales_ind lsales_ind1  lpind_ind  yy* nnn* if year>1984&year<2001,force lag(1)
newey
di  _newline(10)

di "Column 4"
*"R&D equation"
u spillovers,clear
cap gen lxrd_sales=lxrd-lsales
cap gen lxrd_sales1=lxrd1-lsales1
keep if lxrd_sales~=.|lxrd_sales1~=.
cap qui tab num,gen(nnn)
so num year 
tsset num year
qui newey lxrd_sales             							 lgspillsic1 lgspillsicsloc1 lsales_ind lsales_ind1  yy* nnn*, force lag(1)
newey
di  _newline(10)


/*Table 8 Panel B*/
u spillovers_eg,replace
replace lgspilltec1=. if lgspillsic1==.
cap tsset num year
keep if year<1999&year>(fyear+prior_years)
*keep the arbitrary base industry common across regressions (brokerage). Merge software together
replace sic=999 if sic==6211
replace sic=7373 if sic==7370 
qui tab sic,gen(jjj)
drop jjj1
cap qui tab year,gen(yy)


*Table 8, Elison Glaeser, Column 2: Patents (cites)
qui nbreg pat_cite lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum  jjj*    yy*  if year<1999&year>(fyear+prior_years), cluster(sic)  
nbreg 

u spillovers_eg,replace
keep if year>1984&year<2001
cap qui tab num,gen(nnn)
cap qui tab year,gen(yy)

*Table 8, Elison Glaeser, Column 1: Tobin's Q
qui newey lq grd_k1 grd_k1_dum lgspilltec1 lgspillsic1 grd_kt* lsales_ind lsales_ind1  yy* nnn* if year>1984&year<2001, force lag(1)
newey
di  _newline(10)

*Table 8, Elison Glaeser, Column 3: Productivity (real sales)
qui newey lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales_ind lsales_ind1  lpind_ind  yy* nnn* if year>1984&year<2001,force lag(1)
newey
di  _newline(10)


*Table 8, Elison Glaeser, Column 4: R&D
u spillovers_eg,replace
cap qui tab num,gen(nnn)
so num year 
cap tab year,gen(yy)
tsset num year
qui newey lxrd_sales lgspilltec1  lgspillsic1 lsales_ind lsales_ind1  yy* nnn*, force lag(1)
newey
di  _newline(10)

*************************************
di "PRIVATE AND SOCIAL RETURNS"
di "TABLE 10"

*************************************
di "This is sufficiently complex the results are run in another file"
do privatesocial_rep
di  _newline(10)


*APPENDIX
*************************************
di "IV First Stage"
di "APPENDIX TABLE A.IV"
*************************************
u firststage,clear

*Column (1)
newey2 lxrd lstate  lfirm firm_dum,force lag(1) 

*Column (2)
newey2 lxrd lstate  lfirm firm_dum nnn*,force lag(1) 

*Column (3)
newey2 lxrd lstate  lfirm firm_dum yy* nnn*,force lag(1) 


*************************************
di "Industry breakdowns"
di "APPENDIX TABLE A4"
*************************************

forv i=1(1)3 {
u spillovers,clear
if `i'==1 {
di "Computer hardware"
keep if sic3==357&sic<3578
gen _dum3570=(sic==3570)
gen _dum3571=(sic==3571)
gen _dum3572=(sic==3572)
gen _dum3575=(sic==3575)
gen _dum3576=(sic==3576)
}
if `i'==2 {
di "Pharmaceuticals"
keep if sic==2834|sic==2835
gen _dum2835=(sic==2835)
}
if `i'==3 {
di "Teleco equipment"
keep if sic3==366
gen _dum3661=(sic==3661)
gen _dum3663=(sic==3663)
}
so num year
qui tab num,gen(nnn)
qui tab sic,gen(jjj)
tsset num year
qui newey  lq grd_k1 grd_k1_dum grd_kt2 grd_kt3   lgspilltec1 lgspillsic1 yy* nnn*   if year>1984&year<2001,lag(1) force
newey
qui nbreg  pat_cite lgrd1 lgrd1_dum lgspillsic1  lgspilltec1  lsales1 lpriorpat_cite lpriorpat_cite_dum yy* _dum*   if year<1999&year>(fyear+prior_years), cluster(i) 
nbreg
qui newey lsales lemp1 lppent1 lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lpind_ind lsales_ind lsales_ind1 yy* nnn*  if year>1984&year<2001, force lag(1)
newey
qui newey lxrd_sales  lgspillsic1 lgspilltec1 lsales_ind lsales_ind1 yy* nnn* , force lag(1)
newey
di  _newline(10)
}




log close




stop_at_end
