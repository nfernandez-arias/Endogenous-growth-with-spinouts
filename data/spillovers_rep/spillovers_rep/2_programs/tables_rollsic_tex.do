*MAIN RESULTS PROGRAM: Replicates the results from Lucking, Bloom and Van Reenen (2018)
*Note 1: this was run in stata version 14.1
*Note 2: if running for the first time you might want to change the name of the log file so you can compare 

set more off
clear all
cap clear mata
cap clear matrix
cap ssc install newey2

cap log close
log using ../replication.smcl,smcl replace

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
sa "$data/rsampleXXX", replace
* REPLICATION
*************************************
di "Descriptive statistics"
di "Table 2" 
*************************************
u "$data/rsampleXXX", clear
matrix dstats=J(36,5,.)
local i=1
replace emp=emp*1000
foreach var in tobinq rmkvaf grd grd_k1 rxrd gspilltec gspillsic pat_count pat_cite rsales rppent emp {
*	qui su `var' if year>=1981&year<2001,det
*	matrix dstats[`i',1]=r(p50)
*	matrix dstats[`i',2]=r(mean)
*	matrix dstats[`i',3]=r(sd)
*	matrix dstats[`i',4]=r(N)
*	egen tag=tag(gvkey) if `var'~=. &year>=1981&year<2001
*	qui count if tag==1
*	drop tag
*	matrix dstats[`i',5]=r(N)
*	local j=`i'+12
	local end=2015
	if "`var'"=="pat_count" | "`var'"=="pat_cite" {
		local end=2006
	}
*	qui su `var' if year>=2001&year<=`end',det
*	matrix dstats[`j',1]=r(p50)
*	matrix dstats[`j',2]=r(mean)
*	matrix dstats[`j',3]=r(sd)
*	matrix dstats[`j',4]=r(N)
*	egen tag=tag(gvkey) if `var'~=. &year>=2001&year<=`end'
*	qui count if tag==1
*	drop tag
*	matrix dstats[`j',5]=r(N)
	local k=`i'+24
	qui su `var' if year>=1981&year<=`end',det
	matrix dstats[`k',1]=r(p50)
	matrix dstats[`k',2]=r(mean)
	matrix dstats[`k',3]=r(sd)
	matrix dstats[`k',4]=r(N)
	egen tag=tag(gvkey) if `var'~=. &year>=1981&year<=`end'
	qui count if tag==1
	drop tag
	matrix dstats[`k',5]=r(N)
	local i=`i'+1
}
esttab matrix(dstats) using "$tables/dstats.tex", replace
*estout matrix(dstats) using "$tables/dstats.tex", replace
*************************************
di "Market value equations"
di "Table 3" 
*************************************
** BSV
use "$raw_data/BSV_spillovers", clear
* MKVAL
qui replace lgspilltec1=. if lgspillsic1==.
cap tsset num year
qui reghdfe lq grd_k1 grd_k1_dum lgspilltec1 lgspillsic1 grd_kt* lsales_ind lsales_ind1 if year>1984&year<2001, ab(year) vce(robust, bw(2)) old
qui keep if e(sample)
cap drop yy*
cap qui tab year,gen(yy)
cap drop nnn*
cap qui tab num,gen(nnn)
qui reghdfe lq grd_k1 grd_k1_dum lgspilltec1 lgspillsic1 grd_kt* lsales_ind lsales_ind1 if year>1984&year<2001, ab(year num) vce(robust, bw(2)) old
qui egen tag=tag(cusip)
count if tag==1
estadd local firms=r(N)
eststo BSV1
*** FULL SAMPLE ***
u "$data/rsampleXXX" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
*cap tsset gvkey year
tsset num year
di "Column 2"
reghdfe lq lgspilltec1 lgspillsic1 grd_k1 grd_k1_dum grd_kt? lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
keep if e(sample)
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c2
di "Column 3"
reghdfe lq lgspilltec1 			   grd_k1 grd_k1_dum grd_kt? lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c3
di "Column 4"
reghdfe lq 			   lgspillsic1 grd_k1 grd_k1_dum grd_kt? lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c4
di "Column 5"
rename lgspill???1 zzz???1
rename lgspillmal???1 lgspill???1
reghdfe lq lgspilltec1 lgspillsic1 grd_k1 grd_k1_dum grd_kt? lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c5
rename lgspill???1 lgspillmal???1
rename zzz???1 lgspill???1
di "Column 6"
* F-TESTS
reghdfe lgspilltec1 lgspilltecIV1 lgspillsicIV1 grd_k1 grd_k1_dum grd_kt? lfirm firm_dum lstate lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
test lgspilltecIV1 lgspillsicIV1
local Ftec=floor(r(F)*10)/10
reghdfe lgspillsic1 lgspilltecIV1 lgspillsicIV1 grd_k1 grd_k1_dum grd_kt? lfirm firm_dum lstate lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
test lgspilltecIV1 lgspillsicIV1
local Fsic=floor(r(F)*10)/10
*
xtivreg2 lq (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) grd_k1 grd_k1_dum grd_kt? lfirm firm_dum lstate lsales_ind lsales_ind1 yy*, fe robust bw(2)
cap drop tag
keep if e(sample)==1
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
estadd local Ftec=`Ftec'
estadd local Fsic=`Fsic'
eststo c6
*************************************
* OUTPUT RESULTS *
#delimit ;
estout BSV1 c2 c3 c4 c5 c6 using "$tables/MarketValue.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
/*	keep(lgspilltec1 lgspillsic1 grd_k1)
	varlabels(lgspilltec1 "ln(SPILLTECH)"
			  lgspillsic1 "ln(SPILLSIC)"
			  grd_k1	"ln(R\&D/Capital)")*/
	keep(lgspilltec1 lgspillsic1)
	varlabels(lgspilltec1 "ln(SPILLTECH)"
			  lgspillsic1 "ln(SPILLSIC)")
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms Ftec Fsic, fmt(0 0 1 1) labels("N" "Firms" "ln(SPILLTEC)" "ln(SPILLSIC)"))
	numbers
	prehead(\\ \hline \hline)
	posthead(& OLS  & OLS & OLS & OLS & IV \\
			& Jaffe& Jaffe& Jaffe& Mahalanobis& Jaffe \\ \hline)
	prefoot( &  &  &  &  & 1st stage F-stat \\ \hline)
	style(tex)
	replace;
#delimit cr;
************************************* 
di "Patent equations"
di "Table 4" 
*************************************
* BSV
use "$raw_data/BSV_spillovers" if year<1999&year>(fyear+prior_years)&lgspillsic1~=., clear
*keep the arbitrary base industry common across regressions (brokerage). Merge software together as otherwise does not produce standard errors as too many industry codes
replace sic=999 if sic==6211
replace sic=7373 if sic==7370 
qui tab sic,gen(jjj)
drop jjj1
qui nbreg pat_cite lgrd1 lgrd1_dum  lgspilltec1 lgspillsic1 lsales1 jjj*    yy*, cluster(i) 
nbreg
qui keep if e(sample)
di "Column 3"
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(i)  
nbreg
qui egen tag=tag(cusip)
count if tag==1
estadd local firms=r(N)
eststo BSV2
u "$data/rsampleXXX" if year<2006 &year>(fyear+prior_years)&lgspillsic1~=., clear
*keep the arbitrary base industry common across regressions (brokerage). Merge software together as otherwise does not produce standard errors as too many industry codes
replace sic=999 if sic==6211
replace sic=7373 if sic==7370 
qui tab sic,gen(jjj)
drop jjj1
di "Column 3"
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(num)  
nbreg
keep if e(sample)
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c3
di "Column 4"
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspilltec1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(num)  
nbreg
count if tag==1
estadd local firms=r(N)
eststo c4
di "Column 5"
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum 			 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(num)  
nbreg
count if tag==1
estadd local firms=r(N)
eststo c5
di "Column 6"
rename lgspill???1 zzz???1
rename lgspillmal???1 lgspill???1
*(note this differs slighlty from the text due to different industry  baseline dummy, but qualitatively the same)
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(num)  
nbreg
count if tag==1
estadd local firms=r(N)
eststo c6
rename lgspill???1 lgspillmal???1
rename zzz???1 lgspill???1
*JAFFE IV
di "Columns 7, control function for IV"
*First get residuals for lgspilltec1
qui reghdfe lgspilltec1  lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum if pat_cite~=., ab(FE_YEAR=year FE_SIC=sic FE_NUM=num) cluster(num)
qui predict _tec,res
qui reghdfe lgspilltec1  lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum if pat_cite~=.,ab(year sic num) cluster(num)
test lgspilltecIV1 lgspillsicIV1
local Ftec=floor(r(F)*10)/10
*Then get residuals for lgspillsic1
cap drop FE_*
qui reghdfe lgspillsic1 lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum if pat_cite~=.,cluster(num) ab(FE_YEAR=year FE_SIC=sic FE_NUM=num)
qui predict _sic,res
qui reghdfe lgspillsic1  lpat_cite1 lpat_cite1_dum lghxrd1 lgspilltecIV1 lgspillsicIV1 lsales1 lpriorpat_cite lpriorpat_cite_dum if pat_cite~=.,cluster(num) ab(year sic num)
test lgspilltecIV1 lgspillsicIV1
local Fsic=floor(r(F)*10)/10

qui forv i=2(1)5 {
qui gen _tec`i'=(_tec^`i')
qui gen _sic`i'=(_sic^`i')
}
*Then add residuals in, use up for fifth power, although results very similar even with first power
qui nbreg pat_cite lpat_cite1 lpat_cite1_dum lgrd1 lgspilltec1 lgspillsic1 _tec* _sic* lsales1 lpriorpat_cite lpriorpat_cite_dum jjj*  yy*, cluster(num)  
test _tec _tec2 _tec3 _tec4 _tec5 _sic _sic2 _sic3 _sic4 _sic5
nbreg
cap drop tag
keep if e(sample)==1
egen tag=tag(gvkey) 
count if tag==1
estadd local firms=r(N)
estadd local Ftec=`Ftec'
estadd local Fsic=`Fsic'
eststo c7
*************************************
* OUTPUT RESULTS *
#delimit ;
estout BSV2 c3 c4 c5 c6 c7 using "$tables/Patents.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1 lgspillsic1 lgrd1 lpat_cite1 lpriorpat_cite)
	varlabels(lgspilltec1 "ln(SPILLTECH)"
			  lgspillsic1 "ln(SPILLSIC)"
			  lgrd1	"R\&D Stock"
			  lpat_cite1	"Lagged dependent variable" 
			  lpriorpat_cite "Pre-sample FE")
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms Ftec Fsic, fmt(0 0 1 1) labels("N" "Firms" "ln(SPILLTEC)" "ln(SPILLSIC)"))
	numbers
	prehead(\\ \hline \hline)
	posthead(& OLS & OLS & OLS & OLS & OLS & IV \\
			& Jaffe& Jaffe& Jaffe& Jaffe&  Mahalanobis& Jaffe \\ \hline)
	prefoot(&  &  &  &  &   & 1st stage F-stat \\ \hline)
	style(tex)
	replace;
#delimit cr;
********************************************
di "Productivity equations"
di "TABLE 5"
********************************************
* BSV
use "$raw_data/BSV_spillovers" if year>1984&year<2001&lgspillsic1~=., clear
cap tsset num year
qui reghdfe lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales_ind lsales_ind1  lpind_ind, ab(year) vce(robust, bw(2)) old
qui keep if e(sample)
cap qui tab num,gen(nnn)
qui reghdfe lsales lemp1  lppent1 lgrd1 lgrd1_dum lgspilltec1 lgspillsic1 lsales_ind lsales_ind1  lpind_ind, ab(year num) vce(robust, bw(2)) old
qui egen tag=tag(cusip)
count if tag==1
estadd local firms=r(N)
eststo BSV3
u "$data/rsampleXXX" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
tsset num year
di "Column2"
reghdfe lsales lgspilltec1 lgspillsic1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind, ab(year num)  vce(robust, bw(2)) old
keep if e(sample)
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c2
di "Column3"
reghdfe lsales lgspilltec1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind, ab(year num)  vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c3
di "Column4"
reghdfe lsales lgspillsic1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind, ab(year num)  vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c4
di "Column 4, Mahalanobis"
rename lgspill???1 zzz???1
rename lgspillmal???1 lgspill???1
reghdfe lsales lgspilltec1 lgspillsic1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind, ab(year num)  vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c5
rename lgspill???1 lgspillmal???1
rename zzz???1 lgspill???1
di "Column 5"
* F-TESTS
reghdfe lgspilltec1 lgspilltecIV1 lgspillsicIV1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind, ab(year num) vce(robust, bw(2)) old
test lgspilltecIV1 lgspillsicIV1
local Ftec=floor(r(F)*10)/10

reghdfe lgspillsic1 lgspilltecIV1 lgspillsicIV1 lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind, ab(year num) vce(robust, bw(2)) old
test lgspilltecIV1 lgspillsicIV1
local Fsic=floor(r(F)*10)/10

*
xtivreg2 lsales (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lemp1 lppent1 lgrd1 lgrd1_dum lsales_ind lsales_ind1 lpind_ind yy*, fe robust bw(2)
cap drop tag
keep if e(sample)==1
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
estadd local Ftec=`Ftec'
estadd local Fsic=`Fsic'
eststo c6
*************************************
* OUTPUT RESULTS *
#delimit ;
estout BSV3 c2 c3 c4 c5 c6 using "$tables/TFP.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1 lgspillsic1 lemp1 lppent1 lgrd1)
	varlabels(lgspilltec1 "ln(SPILLTECH)"
			  lgspillsic1 "ln(SPILLSIC)"
			  lemp1			"Labor"
			  lppent1		"Capital"
			  lgrd1			"R\&D Stock")
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms Ftec Fsic, fmt(0 0 1 1) labels("N" "Firms" "ln(SPILLTEC)" "ln(SPILLSIC)"))
	numbers
	prehead(\\ \hline \hline)
	posthead(& OLS & OLS & OLS & OLS & OLS & IV \\
			& Jaffe& Jaffe& Jaffe& Jaffe&  Mahalanobis& Jaffe \\ \hline )
	prefoot(&  &  &  &  &  & 1st stage F-stat \\ \hline)
	style(tex)
	replace;
#delimit cr;
********************************************
di "R&D equation"
di "TABLE 5"
********************************************
* R&D
use "$raw_data/BSV_spillovers", clear
tsset num year
qui reghdfe lxrd_sales             lgspilltec1  lgspillsic1 lsales_ind lsales_ind1, ab(year) vce(robust, bw(2)) old
qui keep if e(sample)
cap qui tab num,gen(nnn)
qui reghdfe lxrd_sales             lgspilltec1  lgspillsic1 lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
qui egen tag=tag(cusip)
count if tag==1
estadd local firms=r(N)
eststo BSV4
u "$data/rsampleXXX" if year>1984, clear
replace lgspilltec1=. if lgspillsic1==.
tsset num year
di "Column2"
reghdfe lxrd_sales lgspilltec1  lgspillsic1 lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
keep if e(sample)
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
eststo c2
di "Column3"
reghdfe lxrd_sales lgspilltec1  lgspillsic1 lxrd_sales1 lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c3
test lgspilltec1 lgspillsic1
di "Column4"
rename lgspill???1 zzz???1
rename lgspillmal???1 lgspill???1
reghdfe lxrd_sales lgspilltec1  lgspillsic1 lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
count if tag==1
estadd local firms=r(N)
eststo c4
rename lgspill???1 lgspillmal???1
rename zzz???1 lgspill???1
di "Column5, IV"
* F-TESTS
reghdfe lgspilltec1 lgspilltecIV1 lgspillsicIV1 lfirm firm_dum lstate lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
test lgspilltecIV1 lgspillsicIV1
local Ftec=floor(r(F)*10)/10

reghdfe lgspillsic1 lgspilltecIV1 lgspillsicIV1 lfirm firm_dum lstate lsales_ind lsales_ind1, ab(year num) vce(robust, bw(2)) old
test lgspilltecIV1 lgspillsicIV1
local Fsic=floor(r(F)*10)/10

*
xtivreg2 lxrd_sales (lgspilltec1 lgspillsic1=lgspilltecIV1 lgspillsicIV1) lfirm firm_dum lstate lsales_ind lsales_ind1 yy*, fe robust bw(2)
cap drop tag
keep if e(sample)==1
egen tag=tag(gvkey)
count if tag==1
estadd local firms=r(N)
estadd local Ftec=`Ftec'
estadd local Fsic=`Fsic'
eststo c5
cap log close
*************************************
* OUTPUT RESULTS *
#delimit ;
estout BSV4 c2 c3 c4 c5 using "$tables/RD.tex",
	cells(b(fmt(3) star) se(fmt(3) nopar))
	keep(lgspilltec1 lgspillsic1 lxrd_sales1)
	varlabels(lgspilltec1 "ln(SPILLTECH)"
			  lgspillsic1 "ln(SPILLSIC)"
			  lxrd_sales1			"ln(R\&D/sales)")
	starlevels("*" 0.1 "**" 0.05 "***" 0.01)
	mlabels(none)
	collabels(none)
	stats(N firms Ftec Fsic, fmt(0 0 1 1) labels("N" "Firms" "ln(SPILLTEC)" "ln(SPILLSIC)"))
	numbers
	prehead(\\ \hline \hline)
	posthead(& OLS & OLS & OLS & OLS & IV \\
			& Jaffe& Jaffe& Jaffe&  Mahalanobis& Jaffe \\ \hline )
	prefoot(&  &  &  &  & 1st stage F-stat \\   \hline)
	style(tex)
	replace;
#delimit cr;
*





