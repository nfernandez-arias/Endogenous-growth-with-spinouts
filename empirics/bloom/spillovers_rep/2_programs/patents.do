clear all
set more off
set matsize 7500
set maxvar 7500
set memory 1500m
/***************************************************************************
 THIS FILE IS IN THREE PARTS. 
 PART 1) DATA READING IN
 PART 2) TECHNOLOGY MEASURES
 PART 3) PRODUCT MARKET MEASURES
 PART 4) GEOGRAPHIC MEASURES
 
 THIS WAS INITIALLLY PROGRAMMED ON A 2002 PC AND EVOLVED OVER TIME, 
 SO NOT ALL CODING IS OPTIMAL FOR CURRENT MACHINES. 
 FOR EXAMPLE ALL SHARES OUT OF 100 (SO PERCENT) AS INTEGERS VALUES
 NBLOOM@STANFORD.EDU, OCTOBER 2011
***************************************************************************/

***************************************************************************
***************************************************************************
*    PART 1: INPUTTING MASSIVE PATENTS AND COMPUSTAT DATABASE: INITIAL DATA READING IN PHASE, 
* SKIP ONCE FILES ARE CREATED ON THE FIRST RUN
***************************************************************************
***************************************************************************
*INPUTTING THE PATENTS DATA
* Read in the patents data from the NBER
u "$data/pat76_06_assg", clear
* count number of assignees for each patent
by patent: egen nass = count(pdpass)
* calculate fractional patent ownership
gen npat = 1/nass
* create localtion variable
gen location=state
replace location="X"+country if location==""
lab var location "State, unless overseas in which case country"
rename nclaims claims
rename allcites creceive
gen gdate=date(strofreal(gmonth)+"/"+strofreal(gday)+"/"+strofreal(gyear),"MDY")
keep pdpass patent gyear gdate appyear claims nclass cat subcat location hjtwt creceive npat
so pdpass
* merge to dynamic assignee match file
preserve
u "$data/dynass", clear
keep gvkey* pdpass 
reshape long gvkey, i(pdpass) j(n)
drop n
drop if pdpass==. | gvkey==.
tempfile p_ids
save `p_ids'
restore
joinby pdpass using `p_ids', unm(n)
sa "$data/patsmall70",replace 
*INPUTTING THE MATCHING DATA - SLOW!
u "$data/segments",clear
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
destring gvkey, replace
merge 1:m gvkey using "$data/patsmall70"
keep if _m==3
drop _merge
so gvkey
sa "$data/patsmall_70",replace

*************************************
***************************************************************************
*	PART 2: CALCULATING CORRELATIONS FOR PATENT TECH SHARES
***************************************************************************
*************************************
*USING THE PATENTS TO CREATE A SHARE OF EACH SUBCATEGORY WITHIN EACH FIRM
u "$data/patsmall_70",clear
keep gvkey nclass patent
so nclass
gen tclass=1
replace tclass=tclass[_n-1]+1*(nclass~=nclass[_n-1]) if nclass[_n-1]~=.
egen TECH=max(tclass)
global define tech=TECH
egen total=count(patent),by(gvkey)
egen total_tech=count(patent),by(gvkey tclass)
fillin gvkey tclass
drop _f
so gvkey tclass
drop if gvkey==gvkey[_n-1]&tclass==tclass[_n-1]
gen double subsh=100*(total_tech/total)
keep gvkey tclass subsh
qui su tclass
global tech=r(max)
replace subsh=0 if subsh==.
reshape wide subsh, i(gvkey) j(tclass)
compress
sa "$data/patshare70_norounding",replace


*CREATING A N BY NY LIST WITH SHARES IN EACH SECTOR ACROSS (N*N DOWN AND J ACROSS)
u "$data/patshare70_norounding",clear
*u patshare70,clear
cap drop nclass subcat tclass TECH total
so gvkey
gen num=1
replace num=num[_n-1]+1*(gvkey~=gvkey[_n-1]) if gvkey[_n-1]~=.
so num
preserve
egen tag=tag(num)
keep num gvkey
save "$data/num_gvkey", replace
rename num num_
rename gvkey gvkey_
save "$data/num_gvkey_", replace
restore
egen NUM=max(num)
qui su num
global num=r(max)

*Generates a matrix of all the shares in dimensions (num, tech) 
mkmat subsh*,mat(subsh)
matrix normsubsh=subsh

*Var is a (tech,tech) matrix of the correlations between tech classes. Used for Mahalanobis distance measures
matrix var=subsh'*subsh
matrix basevar=var
forv i=1(1)$tech {
forv j=1(1)$tech {
matrix var[`i',`j']=var[`i',`j']/(basevar[`i',`i']^(1/2)*basevar[`j',`j']^(1/2))
}
}

*Standard is a (num,num) matrix of the correlations between firms over tech classes
matrix basestandard=subsh*subsh'
forv j=1(1)$tech {
forv i=1(1)$num {
matrix normsubsh[`i',`j']=subsh[`i',`j']/(basestandard[`i',`i']^(1/2))
}
}
matrix standard=normsubsh*normsubsh'
matrix covstandard=subsh*subsh'
save "$data/temp",replace



* BL: TOO LONG, NEED TO SPLIT UP MATRICES
global X=ceil($num/500)*500 - 500

forv mal=0(1)1{
u "$data/temp",clear

*Generate the Malhabois measure
if `mal'==1 {
matrix mal_corr=normsubsh*var*normsubsh'
matrix standard=mal_corr
matrix covmal_corr=subsh*var*subsh'
matrix covstandard=covmal_corr
}
*Convert back into scalar data
keep gvkey
sort gvkey
local J=$X+1
forv j=1(500)`J' {
preserve
local j2=`j'+499
if `j'==`J' {
	local j2 .
}
matrix covstandardj`j'=covstandard[1...,`j'..`j2']
matrix standardj`j'=standard[1...,`j'..`j2']
svmat standardj`j',n(standard)
svmat covstandardj`j',n(covstandard)
compress
reshape long standard covstandard,i(gvkey) j(num_)
cap drop subsh*
ren *standard *tec
replace num_ = `j'+num_-1
so gvkey num_
*convert to integers to reduce memory size - renormalize later
foreach var in tec covtec {
cap replace `var'=100*round(`var',0.01)
}
compress
if `mal'==1 {
ren *tec mal*tec
sa "$data/output_short70_mal_newj`j'",replace
}
else {
sa "$data/output_short70_newj`j'",replace
}
restore
}
}
foreach f in output_short70_new output_short70_mal_new {
clear
forv j=1(500)`J' {
	append using "$data/`f'j`j'"
}
sort gvkey num_
merge m:1 num_ using "$data/num_gvkey_"
assert _m==3
drop _m
sa "$data/`f'", replace
* clean up
forv j=1(500)`J' {
	erase "$data/`f'j`j'.dta"
}
}
***************************************************************************
***************************************************************************
*PART 3:	CALCULATING CORRELATIONS FOR SIC SHARES
***************************************************************************
***************************************************************************
set more off
*slow to run - only update when the SIC info. is updated in merge1.do
u "$data/patsmall_70", clear
egen tag=tag(gvkey)
keep if tag==1
keep gvkey
tempfile tmp
save `tmp'
u "$data/segments", clear
destring gvkey, replace
merge m:1 gvkey using `tmp'
keep if _m==3
drop _m
* ALLOCATE SALES 75% TO PRIMARY SIC, 25% TO SECONDARY SIC
gen f_nosics2 = sics2==""
gen s1sale=sales if f_nosics2==1
gen s2sale=0 if f_nosics2==1
replace s1sale=sales*$primary_share if f_nosics2==0
replace s2sale=sales*(1-$primary_share) if f_nosics2==0
preserve
collapse (sum) s1sale, by(gvkey datadate sics1)
rename sics1 sics
rename s1sale sales
tempfile segments
save `segments'
restore
drop if sics2==""
collapse (sum) s2sale, by(gvkey datadate sics2)
rename sics2 sics
rename s2sale sales
append using `segments'
collapse (sum) sales, by(gvkey datadate sics)
bysort gvkey datadate : egen ssales=sum(sales)
gen share=sales/ssales
collapse (mean) share, by(gvkey sics)
egen tag=tag(sics)
egen SIC=sum(tag)
qui su SIC
global SIC=r(max)
keep gvkey share sics
reshape wide share, i(gvkey) j(sics) string
sa "$data/sicstage1", replace
*
u "$data/sicstage1",clear
so gvkey
compress
gen num=_n
sa "$data/tempn",replace
keep num gvkey
so num
sa "$data/sicnum",replace
rename num num_
rename gvkey gvkey_
so num_
sa "$data/sicnum_",replace
*
u "$data/tempn",clear
*drop gvkey
order num
egen NUM=max(num)
so num
gen x=NUM - num + 1
replace x=x+1 if num==1
*compress
label drop _all
global num=NUM
global sic=$SIC

*Generates a matrix of all the shares in dimensions (num, sic) 
mvencode share*,mv(0) over
mkmat share*,mat(share)
matrix normshare=share


*Var is a (tech,tech) matrix of the correlations between sales classes. Used for Mahalanobis distance measures
matrix var=share'*share
matrix basevar=var
forv i=1(1)$sic {
forv j=1(1)$sic {
matrix var[`i',`j']=var[`i',`j']/(basevar[`i',`i']^(1/2)*basevar[`j',`j']^(1/2))
if var[`i',`j']==. {
matrix var[`i',`j']=0
}
}
}

*Standard is a (num,num) matrix of the correlations between firms over tech classes
matrix basestandard=share*share'
forv j=1(1)$sic {
forv i=1(1)$num {
matrix normshare[`i',`j']=share[`i',`j']/(basestandard[`i',`i']^(1/2))
}
}
matrix standard=normshare*normshare'
matrix covstandard=share*share'
save "$data/temp",replace

forv mal=0(1)1{
u "$data/temp",clear

*Generate the Malhabois measure
if `mal'==1 {
matrix mal_corr=normshare*var*normshare'
matrix standard=mal_corr
matrix covmal_corr=share*var*share'
matrix covstandard=covmal_corr
}
*Convert back into scalar data
keep gvkey
sort gvkey
local J=$X+1
forv j=1(500)`J' {
preserve
local j2=`j'+499
if `j'==`J' {
	local j2 .
}
matrix covstandardj`j'=covstandard[1...,`j'..`j2']
matrix standardj`j'=standard[1...,`j'..`j2']
svmat standardj`j',n(standard)
svmat covstandardj`j',n(covstandard)
compress
reshape long standard covstandard,i(gvkey) j(num_)
cap drop subsh*
ren *standard *sic
replace num_ = `j'+num_-1
so gvkey num_
*convert to integers to reduce memory size - renormalize later
foreach var in sic covsic {
cap replace `var'=100*round(`var',0.01)
}
compress
if `mal'==1 {
ren *sic mal*sic
sa "$data/sicoutput_short7_malj`j'",replace
}
else {
sa "$data/sicoutput_short7j`j'",replace
}
restore
}
}
foreach f in sicoutput_short7 sicoutput_short7_mal {
clear
forv j=1(500)`J' {
	append using "$data/`f'j`j'"
}
sort gvkey num_
merge m:1 num_ using "$data/sicnum_"
assert _m==3
drop _m
sa "$data/`f'", replace
* clean up
forv j=1(500)`J' {
	erase "$data/`f'j`j'.dta"
}
}
***************************************************************************
*	PART 4: CALCULATING GEOGRAPHIC MEASURES 
***************************************************************************
*************************************


*************************************
*PART 4A: CORRELATIONS FOR PATENTING GEOGRAPHIC SHARES
*************************************
/*
*USING THE PATENTS TO CREATE A SHARE OF EACH SUBCATEGORY WITHIN EACH FIRM
u patsmall_70,clear
keep if appyear>=1970
drop gyear appyear claims creceive gdate cat
*cap ssc install egenmore
egen location_count=nvals(location)
global location_count=location_count
egen total=count(patent),by(gvkey)
egen total_location=count(patent),by(gvkey location)
fillin gvkey location
drop _f
so gvkey location
drop if gvkey==gvkey[_n-1]&location==location[_n-1]
gen double subsh=100*(total_location/total)
keep gvkey location subsh
encode location, gen(loc)
drop location
replace subsh=0 if subsh==.
reshape wide subsh, i(gvkey) j(loc) 
compress
sa locationshare,replace

*CREATING A N BY NY LIST WITH SHARES IN EACH SECTOR ACROSS (N*N DOWN AND J ACROSS)
u locationshare,clear
so gvkey
*merge gvkey using gvkey_num
merge 1:1 gvkey using num_gvkey
drop _m
so num
egen NUM=max(num)
global num=NUM

*Generates a matrix of all the shares in dimensions (num, location_count) 
mkmat subsh*,mat(subsh)

*Var is a (loc,loc) matrix of the correlations between locations classes
matrix var=subsh'*subsh
matrix basevar=var
forv i=1(1)$location_count {
forv j=1(1)$location_count {
matrix var[`i',`j']=var[`i',`j']/(basevar[`i',`i']^(1/2)*basevar[`j',`j']^(1/2))
}
}

*Standard is a (num,num) matrix of the correlations between firms over locations classes
matrix basestandard=subsh*subsh'
forv j=1(1)$location_count {
forv i=1(1)$num {
matrix subsh[`i',`j']=subsh[`i',`j']/(basestandard[`i',`i']^(1/2))
}
}
matrix standard=subsh*subsh'

*Convert back into scalar data
keep num 
drop num
svmat standard,n(standard)
gen num=1
replace num=num[_n-1]+1 if num[_n-1]~=.
compress
reshape long standard,i(num) j(num_)
so num
merge num using num_gvkey
drop _m
so num_
merge num_ using num_gvkey_
drop _m
cap drop subsh*
so gvkey gvkey_
drop num*
ren standard tloc
so gvkey gvkey_
sa tlocation_distance,replace
*/

/*
*************************************
*PART 4B: CORRELATIONS FOR SALES GEOGRAPHIC SHARES
*************************************
clear all
u geog_sales,clear
global region_count=9
encode region, gen(loc)
fillin cusip loc
drop _
drop region
ren reg subsh
replace subsh=0 if subsh==.
reshape wide subsh, i(cusip) j(loc) 
compress
sa regionshare,replace


u regionshare,clear
so cusip
merge cusip using cusip_num
*Assume those with no geographic info are purely domestic
replace subsh9=1 if _m==2
mvencode subsh*,mv(0) over
*Scaling up
egen tot=rsum(subsh*)
replace subsh9=1 if tot==0
drop tot

drop _m
so num
egen NUM=max(num)
global num=NUM

*Generates a matrix of all the shares in dimensions (num, location_count) 
mkmat subsh*,mat(subsh)

*Var is a (loc,loc) matrix of the correlations between locations classes
matrix var=subsh'*subsh
matrix basevar=var
forv i=1(1)$region_count {
forv j=1(1)$region_count {
matrix var[`i',`j']=var[`i',`j']/(basevar[`i',`i']^(1/2)*basevar[`j',`j']^(1/2))
}
}

*Standard is a (num,num) matrix of the correlations between firms over locations classes
matrix basestandard=subsh*subsh'
forv j=1(1)$region_count {
forv i=1(1)$num {
matrix subsh[`i',`j']=subsh[`i',`j']/(basestandard[`i',`i']^(1/2))
}
}
matrix standard=subsh*subsh'

*Convert back into scalar data
keep num 
drop num
svmat standard,n(standard)
gen num=1
replace num=num[_n-1]+1 if num[_n-1]~=.
compress
reshape long standard,i(num) j(num_)
so num
merge num using num_cusip
drop _m
so num_
merge num_ using num_cusip_
drop _m
cap drop subsh*
so cusip cusip_
drop num*
ren standard sloc
so cusip cusip_
sa slocation_distance,replace
*/


