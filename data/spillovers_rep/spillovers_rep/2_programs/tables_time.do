* TIME-VARYING COEFFICIENTS
set more off
clear all
cap clear mata
cap clear matrix
cap log close
log using ../replication.smcl,smcl append
* MERGE IN ROLLSIC
u "$data/rsample", clear
foreach var in spillsic spillcovsic spillsicIV spillmalsic spillcovmalsic spillmalsicIV sales_ind {
	cap drop `var'
	cap drop l`var'
	cap drop lg`var'
	cap drop `var'1
	cap drop l`var'1
	cap drop lg`var'1
}
merge 1:1 gvkey year using "$data/sicroll_ma5"
keep if _m==1 | _m==3
drop _m
foreach var in lgspilltec1 lgspillsic1 grd_k1 lgrd1 {
foreach y of numlist 1985(5)2010 {
	gen `var'`y'=`var'*inrange(year,`y',`y'+4)
}
}
sa "$data/rsampleXXX", replace
* REPLICATION
*************************************
di "Market value equations"
di "Table 3" 
*************************************
*** FULL SAMPLE ***
u "$data/rsampleXXX" if year>1984, clear
cap drop *1985
replace lgspilltec1=. if lgspillsic1==.
*cap tsset gvkey year
tsset num year
reghdfe lq lgspilltec1 lgspillsic1 grd_k1 lgspilltec1???? lgspillsic1???? grd_k1???? lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
cap drop tag
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c1
********************************************
di "Productivity equations"
di "TABLE 5"
********************************************
u "$data/rsampleXXX" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
tsset num year
cap drop *1985
* merge in deflators
merge m:1 sic3 year using "$data/deflators_1215", update
keep if _merge==1 | _merge==3 | _merge==4
drop _merge
replace lpind_ind=log(pind_ind) if year>2011 & year~=.
reghdfe lsales lgspilltec1???? lgspillsic1???? lgrd1???? lgspilltec1 lgspillsic1 lgrd1 lemp1 lppent1 lsales_ind lsales_ind1 lpind_ind, ab(year num)  vce(robust, bw(2)) old
cap drop tag
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c2
********************************************
di "R&D equation"
di "TABLE 5"
********************************************
* R&D
u "$data/rsampleXXX" if year>1984, clear
cap drop *1985
replace lgspilltec1=. if lgspillsic1==.
tsset num year
reghdfe lxrd_sales lgspilltec1 lgspillsic1 lgspilltec1???? lgspillsic1???? lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
cap drop tag
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c3
************************************* 
di "Patent equations"
di "Table 4" 
*************************************
u "$data/rsampleXXX" if year<2006 & year>(fyear+prior_years)&lgspillsic1~=., clear
cap drop *1985 *2005 *2010
cap replace lgspilltec12000=lgspilltec1 if year==2005
cap replace lgspillsic12000=lgspillsic1 if year==2005
cap replace lgrd12000=lgrd1 if year==2005
*keep the arbitrary base industry common across regressions (brokerage). Merge software together as otherwise does not produce standard errors as too many industry codes
replace sic=999 if sic==6211
replace sic=7373 if sic==7370 
qui tab sic,gen(jjj)
drop jjj1
qui nbreg pat_cite lgspilltec1 lgspillsic1 lgrd1 lgspilltec1???? lgspillsic1???? lgrd1???? lpat_cite1 lpat_cite1_dum lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(num)
nbreg
cap drop tag
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c4
*************************************
* OUTPUT RESULTS *
#delimit ;
estout c1 using "$tables/spillovers_q_t.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1* lgspillsic1* grd_k1 grd_k11990 grd_k11995 grd_k12000 grd_k12005 grd_k12010)
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms, fmt(0 0 1 1) labels("N" "Firms"))
	numbers
	prehead(\\ \hline \hline)
	posthead(& OLS \\
			& Jaffe\\ \hline)
	prefoot(  & \\ \hline)
	style(tex)
	replace;
estout c2 using "$tables/spillovers_tfp_t.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1* lgspillsic1* lgrd1 lgrd11990 lgrd11995 lgrd12000 lgrd12005)
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms, fmt(0 0 1 1) labels("N" "Firms"))
	numbers
	prehead(\\ \hline \hline)
	posthead(& OLS & OLS & OLS & OLS \\
			& Jaffe& Jaffe& Jaffe & Jaffe\\ \hline)
	prefoot(&  &  &  & \\ \hline)
	style(tex)
	replace;
estout c3 using "$tables/spillovers_rd_t.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1* lgspillsic1*)
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms, fmt(0 0 1 1) labels("N" "Firms"))
	numbers
	prehead(\\ \hline \hline)
	posthead( & OLS \\
			 & Jaffe\\ \hline)
	prefoot(  & \\ \hline)
	style(tex)
	replace;
estout c4 using "$tables/spillovers_p_t.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1* lgspillsic1* lgrd1 lgrd11990 lgrd11995 lgrd12000)
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms, fmt(0 0 1 1) labels("N" "Firms"))
	numbers
	prehead(\\ \hline \hline)
	posthead( & OLS \\
			 & Jaffe\\ \hline)
	prefoot( & \\ \hline)
	style(tex)
	replace;
#delimit cr;

*
*
