clear all
set more 1
set matsize 5000
set maxvar 5000
set memory 1500m

/***************************************************************************
 THIS FILE IS IN THREE PARTS. 
 PART 1) DATA READING IN
 PART 2) TECHNOLOGY MEASURES
 PART 3) PRODUCT MARKET MEASURES
 PART 4) GEOGRAPHIC MEASURES
 
 THIS WAS INITIALLLY PROGRAMMED ON A 2002 PC AND EVOLVED OVER TIME, SO NOT ALL CODING IS OPTIMAL FOR CURRENT MACHINES. FOR EXAMPLE ALL SHARES OUT OF 100 (SO PERCENT) AS INTEGERS VALUES
 NBLOOM@STANFORD.EDU, OCTOBER 2011
***************************************************************************/

***************************************************************************
***************************************************************************
*    PART 1: INPUTTING MASSIVE PATENTS AND COMPUSTAT DATABASE: INITIAL DATA READING IN PHASE, SKIP ONCE FILES ARE CREATED ON THE FIRST RUN
***************************************************************************
***************************************************************************

*INPUTTING THE PATENTS DATA - VERY VERY SLOW!
*Infiles the raw patents data from the NBER
cap insheet using apat63_99.txt,clear comma
cap sa apat63_99,replace
u apat63_99,replace
gen location=postate
replace location="X"+country if location==""
lab var location "State, unless overseas in which case country"
drop country postate general original selfctub selfctlb secdupbd secdlwbd
*drop if asscode~=2
drop asscode
drop if appyear<1970
drop if appyear==.
so assignee
sa patsmall70,replace 

*INPUTTING THE MATCHING DATA - SLOW!
u basic,clear
so assignee
keep if assignee~=assignee[_n-1]
keep assignee cusip
merge assignee using patsmall70
keep if _==3
drop _merge
so assignee
sa patsmall_70,replace



*************************************
***************************************************************************
*	PART 2: CALCULATING CORRELATIONS FOR PATENT TECH SHARES
***************************************************************************
*************************************
*USING THE PATENTS TO CREATE A SHARE OF EACH SUBCATEGORY WITHIN EACH FIRM
u patsmall_70,clear
keep if appyear>=1970
drop gyear appyear claims cmade creceive ratiocit fwdaplag bckgtlag gdate cat
so nclass
gen tclass=1
replace tclass=tclass[_n-1]+1*(nclass~=nclass[_n-1]) if nclass[_n-1]~=.
egen TECH=max(tclass)
global define tech=TECH
egen total=count(patent),by(cusip)
egen total_tech=count(patent),by(cusip tclass)
fillin cusip tclass
drop _f
so cusip tclass
drop if cusip==cusip[_n-1]&tclass==tclass[_n-1]
gen double subsh=100*(total_tech/total)
keep cusip tclass subsh
replace subsh=0 if subsh==.
reshape wide subsh, i(cusip) j(tclass)
compress
sa patshare70_norounding,replace


*CREATING A N BY NY LIST WITH SHARES IN EACH SECTOR ACROSS (N*N DOWN AND J ACROSS)
u patshare70_norounding,clear
*u patshare70,clear
cap drop nclass subcat tclass TECH total
so cusip
merge cusip using cusip_num
drop _m
so num
egen NUM=max(num)
global num=NUM
global tech=407

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
save temp,replace

forv mal=0(1) 1{
u temp,clear
*Generate the Malhabois measure
if `mal'==1 {
matrix mal_corr=normsubsh*var*normsubsh'
matrix standard=mal_corr
matrix covmal_corr=subsh*var*subsh'
matrix covstandard=covmal_corr
}

*Convert back into scalar data
keep num 
drop num
svmat standard,n(standard)
svmat covstandard,n(covstandard)
gen num=1
replace num=num[_n-1]+1 if num[_n-1]~=.
compress
reshape long standard covstandard,i(num) j(num_)
so num
merge num using num_cusip
drop _m
so num_
merge num_ using num_cusip_
drop _m
cap drop subsh*
so cusip cusip_
drop num*
ren standard tec
ren covstandard covtec
so cusip cusip_
if `mal'==1 {
ren tec maltec
ren covtec malcovtec
sa output_short70_mal_new,replace
}
else {
sa output_short70_new,replace
}
}


***************************************************************************
***************************************************************************
*PART 3:	CALCULATING CORRELATIONS FOR SIC SHARES
***************************************************************************
***************************************************************************

*slow to run - only update when the SIC info. is updated in merge1.do
u basic,clear
so assignee
keep if assignee~=assignee[_n-1]
drop _merge
merge assignee using patsmall_70
keep if _==3
drop _merge
so cusip
*At this point need to change inputs for sic types (3 or 4 digit, 66% or 75% assumption) *Note the the dataset below comes from "combine.d" in the "new" subdirectory
merge cusip using sicsales
keep if _m==3
so cusip
keep if cusip~=cusip[_n-1]
keep cusip share* SIC
sa sicstage1,replace

u sicstage1,clear
so cusip
compress
encode cusip,gen(num)
sa tempn,replace
keep num cusip
so num
sa sicnum,replace
rename num num_
rename cusip cusip_
so num_
sa sicnum_,replace

u tempn,clear
drop cusip
order num
egen NUM=max(num)
so num
gen x=NUM - num + 1
replace x=x+1 if num==1
*compress
label drop _all
global num=NUM
global sic=SIC

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
save temp,replace

forv mal=0(1)1{
u temp,clear

*Generate the Malhabois measure
if `mal'==1 {
matrix mal_corr=normshare*var*normshare'
matrix standard=mal_corr
matrix covmal_corr=share*var*share'
matrix covstandard=covmal_corr
}

*Convert back into scalar data
keep num 
drop num
svmat standard,n(standard)
svmat covstandard,n(covstandard)
gen num=1
replace num=num[_n-1]+1 if num[_n-1]~=.
compress
reshape long standard covstandard,i(num) j(num_)
sa temptemp,replace
so num
merge num using sicnum
drop _m
so num_
merge num_ using sicnum_
drop _m
cap drop subsh*
so cusip cusip_
drop num*
so cusip cusip_
ren standard sic
ren covstandard covsic
if `mal'==1 {
ren sic malsic
ren covsic malcovsic
sa sicoutput_short7_mal,replace
}
else {
sa sicoutput_short7,replace
}
}


*************************************
***************************************************************************
*	PART 4: CALCULATING GEOGRAPHIC MEASURES 
***************************************************************************
*************************************


*************************************
*PART 4A: CORRELATIONS FOR PATENTING GEOGRAPHIC SHARES
*************************************

*USING THE PATENTS TO CREATE A SHARE OF EACH SUBCATEGORY WITHIN EACH FIRM
u patsmall_70,clear
keep if appyear>=1970
drop gyear appyear claims cmade creceive ratiocit fwdaplag bckgtlag gdate cat
*cap ssc install egenmore
egen location_count=nvals(location)
global location_count=location_count
egen total=count(patent),by(cusip)
egen total_location=count(patent),by(cusip location)
fillin cusip location
drop _f
so cusip location
drop if cusip==cusip[_n-1]&location==location[_n-1]
gen double subsh=100*(total_location/total)
keep cusip location subsh
encode location, gen(loc)
drop location
replace subsh=0 if subsh==.
reshape wide subsh, i(cusip) j(loc) 
compress
sa locationshare,replace

*CREATING A N BY NY LIST WITH SHARES IN EACH SECTOR ACROSS (N*N DOWN AND J ACROSS)
u locationshare,clear
so cusip
merge cusip using cusip_num
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
merge num using num_cusip
drop _m
so num_
merge num_ using num_cusip_
drop _m
cap drop subsh*
so cusip cusip_
drop num*
ren standard tloc
so cusip cusip_
sa tlocation_distance,replace



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



