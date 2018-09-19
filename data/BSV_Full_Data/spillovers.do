*PROGRAM INITIALLY BEGUN IN JULY 2003 BY NICK BLOOM

set more 1
version 8.0
clear all
cap log close
set memory 1500m
set matsize 500
*Use these variabels for geographic distance
macro define metrics "sic covsic malsic malcovsic tec covtec maltec malcovtec tloc sloc tectloc tecsloc sicsloc sictloc"
macro define varlist "$metrics tecIV sicIV tecIV_mal sicIV_mal"
*Use these variabels for non-geographic distance
*macro define varlist "tec sic tecIV sicIV tecIV_mal sicIV_mal"


/*************************************************************************************
THIS IS THE FINAL FILE WHICH COMBINES THE SIC AND TEC STUFF WITH R&D NUMBERS TO
GENERATE SPILLTEC AND SPILLTEC AND THEN COMBINES WITH COMPUSTAT AND LOAD OF OTHER THINGS
TO GENERATE OUR REGRESSION DATA SET. FINALLY RUNS SOME OF PAPER REGRESSIONS AND SAVES
AS A LOG FILE

Note that this program is fed by:
	"patents1.do" (generates the tec and sic correlation measures)
	"merge1.do" (generates some inputs into "patents1.do" and cleans data
************************************************************************************/

/*******************************************************************
*THE FILE IS SEPERATED INTO THREE MAIN SECTIONS

*DATA CONSTRUCTION
	*Combines the tec and sic correlation measures
	*Generates spillover measures by matching this up to accounting data (slow)
	*Generating the estimation data set by cleaning data, generating logs, lags etc.. (long but quick)

*ESTIMATION
	*Data descriptives
	*Production functions
	*R&D equations
	*Patenting equations
	*Value functions

*AUXILARY
	*Creates sales per industry
	*Cleans and generates estimating Compustat data
********************************************************************/

*THIS SECTION MERGES THE CORRELATION OUTPUT FILES TOGETHER
clear
u sicoutput_short7 
merge cusip cusip_ using output_short70_new 
keep if _==3
drop _merge
so cusip cusip_
merge cusip cusip_ using sicoutput_short7_mal
keep if _==3
drop _merge
so cusip cusip_
merge cusip cusip_ using output_short70_mal_new
keep if _==3
drop _merge
*GEOGRAPHIC: This is all the section on geographic distance - comment out to drop
so cusip cusip_
merge cusip cusip_ using tlocation_distance
keep if _==3
drop _
so cusip cusip_
merge cusip cusip_ using slocation_distance
keep if _==3
*Generate geographic interactions with closeness measures, using geometric mean
gen tectloc=tec^(1/2)*tloc^(1/2)
gen sicsloc=sic^(1/2)*sloc^(1/2)
gen tecsloc=tec^(1/2)*sloc^(1/2)
gen sictloc=sic^(1/2)*tloc^(1/2)
drop _
so cusip
order $metrics cusip cusip_
keep $metrics cusip cusip_
cap lab var sic "JAFFE Closeness in Product Market Space (SIC)"
cap lab var tec "JAFFE Closeness in Technology Space (TECH)"
cap lab var covsic "Covariance Closeness in Product Market Space (SIC)"
cap lab var covtec "Covariance Closeness in Technology Space (TECH)"
cap lab var malsic "Mahalanobis Closeness in Product Market Space (SIC)"
cap lab var maltec "Mahalanobis Closeness in Technology Space (TECH)"
cap lab var malcovsic "Covariance Mahalonobis Closeness in Product Market Space (SIC)"
cap lab var malcovtec "Covariance Mahalonobis Closeness in Technology Space (TECH)"
cap lab var tloc "Location closeness in Geographic Technology Space (LOC)"
cap lab var sloc "Location closeness in Geographic Sales Space (LOC)"
cap lab var tectloc "Location closeness in Geographic Technology Space (LOC) times technology closeness"
cap lab var sicsloc "Location closeness in Geographic Sales Space (LOC) times market closeness"
cap lab var tecsloc "Location closeness in Geographic Technology Space (LOC) times market closeness"
cap lab var sictloc "Location closeness in Geographic Sales Space (LOC) times technology closeness"

/*Referee 3 suggestion: only use R&D of firms that have either high SIC and low TECH or reverse. Do this by dropping any firms that are high-high
replace tec=0 if sic>0.1&tec>0.1
replace sic=0 if sic>0.1&tec>0.1 
*/

*drop if cusip==cusip_
so cusip
merge cusip using names
keep if _==3
drop _
so cusip_
merge cusip_ using names_
keep if _==3
drop _m
***********Gets rid of ADRS IN THE DATA
so cusip
merge cusip using ADR_cusip
keep if _==1
drop _
so cusip_
merge cusip_ using ADR_cusip_
keep if _==1
drop _ 


*THIS SECTION GENERATES THE BASIC TECHNOLOGY AND MARKET R&D AND PATENT SPILLOVER MEASURES
drop comn comn_ 
drop if cusip==""
drop if cusip_==""
so cusip_
*convert to integers to reduce memory size - renormalize later
foreach var in $metrics {
replace `var'=100*round(`var',0.01)
}
compress

joinby cusip_ using compustat,unm(n)
*Fix data typos
replace xrd=200 if cusip=="101137"&year==1998
cap drop _ 

********************************GENERATING THE KEY SPILLOVER MEASURES (INCLUDING ALL THE GEOGRAPHIC INTERACTIONS)
foreach var in $metrics {
egen spill`var'=sum(`var'*(1/100)*xrd*(cusip~=cusip_)), by(cusip year)
drop `var'
}
keep if cusip==cusip_
drop cusip_
so cusip year
compress
sa spill_output,replace
***************GOOD POINT TO RE-RUN THE PROGRAM IF FIXING UP DATA AS MUCH QUICKER FROM HERE ONWARDS



u spill_output,clear
***Combine with the JAFFE AND MAHALANOBIS IV data (to do this re-run ivspilloverjuly2011.do the file below)
so cusip year
merge cusip year using spill_hxrd
drop _merge
so cusip year
merge cusip year using spill_hxrd_mal
drop _merge

*Actually censoring top and bottom 1% of these values - just reset values of 0.01 and 0.99 below
gen n=_N
gen p005=round(n*0.005,1)
gen p995=round(n*0.995,1)
foreach var in $varlist {
so spill`var'
gen spill`var'_p005=spill`var'[p005]
gen spill`var'_p995=spill`var'[p995]
replace spill`var'=spill`var'_p005 if spill`var'<spill`var'_p005
replace spill`var'=spill`var'_p995 if spill`var'>spill`var'_p995
drop spill`var'_p*
}
drop p995 n
so cusip year

**********Adding in sales trend terms
merge cusip year using sales_ind
drop if _~=3&year<=1999
egen mm=max(_merge),by(cusip)
drop if mm<3
drop _merge mm
so cusip year
********THIS CAN BE CHANGED ACROSS SPECIFICATIONS - THE CONTROL ON SALES
merge cusip year using sales_ind_ns
drop if _==2
drop _merge
so cusip year
************Adding in patent trend terms
merge cusip year using patents_ind
drop if _~=3&year<=1999
egen mm=max(_merge),by(cusip)
drop if mm<3
drop _merge mm
so cusip year
***************Adding in firm level patents counts
merge cusip year using patent_counts
drop if _==2&pat_count==0&year<=1999
egen mm=max(_merge),by(cusip)
drop if mm<3
drop _merge mm
egen smax=max(sales_ind),by(cusip)
drop if smax==.
drop smax
so cusip year
*Adding in all other accounting data
merge cusip year using compustat_long_file
replace xrd=200 if cusip=="101137"&year==1998
ren mkvf mkvaf
tab _m
drop if _==2
drop _
so cusip year

*********SIMPLY GENERATING LOOGED VALUES OF A FEW KEY MEASURES
foreach var in $varlist {
gen l`var'=log(spill`var')
}
gen lxrd=log(xrd)
gen lsales_ind=log(sales_ind)
gen lsales_ind_ns=log(sales_ind_ns)
replace lsales_ind_ns=lsales_ind if lsales_ind_ns==.
gen lsales_ind_ns_dum=lsales_ind==lsales_ind_ns
*to remove values for zeros add a very small number to this which is 0.025, half the minimum non-zero value 
gen lpatents_ind=log(0.025+patents_ind)
egen lpatents_indt=mean(lpatents_ind),by(year)
replace lpatents_ind=lpatents_ind/lpatents_indt
*dropping as after 1997 very little info in nclass patenting (mostly zeros) hence numbers look very eratic. Replace with average values from 1996 to 1997 as otherwise lose lots of obs due to misssings
replace lpatents_ind=. if year>1997
egen lpatents_indm=sum(lpatents_ind*(year>1995)),by(cusip)
egen ttt=sum((year>1995)*(lpatents_ind~=.)),by(cusip)
gen lpatpat=lpatents_indm/ttt
replace lpatents_ind=lpatpat if year>1995&lpatents_ind==.
gen lpat_count=log(pat_count)
gen lpat_cite_norm=log(pat_cite_norm)
gen lsales=log(sales)
gen lppent=log(ppent)
gen lemp=log(emp)
so cusip year


*******INFILING DATA TO START GENREATING PRESAMPLE PATENT MEASURES
drop pat_cite pat_cite_norm
so cusip year
merge cusip year using patent_counts
drop _
egen sss=max(sales),by(cusip)
drop if sss==.
drop if sales==.&(pat_cite==.|pat_cite==0)
cap prog drop sorting
prog define sorting
local i=1
while `i'<20 {
so cusip year
qui by cusip:drop if sales==.&sales[_n-1]~=.
local i=`i'+1
}
end
sorting
so cusip year


****************CLEANING UP THE DATA
by cusip:gen dsales=(sales-sales[_n-1])/sales[_n-1]
by cusip: gen demp=(emp-emp[_n-1])/emp[_n-1]
gen sales_emp=sales/emp
gen ppent_emp=ppent/emp
*Want to drop all firms falling by more than 66% or expanding by more than 200% - about top 99.5% and bottom 0.5%
drop if (dsales<-0.66|dsales>2)&dsales~=.
drop if (demp<-0.66|demp>2)&demp~=.
*Also drop extreme capital/employees, sales/employee outliers - about top 99.75% and bottom 0.25%
drop if (ppent_emp<0.1|ppent_emp>1000)&ppent_emp~=.
drop if (sales_emp>2000|sales_emp<2)&(sales_emp~=.)


*NICK BASIC CLEANING ON THE JUMPS
cap drop dy
qui by cusip:gen dy=year-year[_n-1]
replace dy=1 if sales==.|sales[_n-1]==.
egen dym=sum(dy>1),by(cusip)
drop if dym>1
egen jumpyear=max(year*(dy>1&dy~=.)),by(cusip)
replace sales=. if year<=jumpyear&jumpyear<1995
replace sales=. if year>=jumpyear&jumpyear>=1995
replace dy=1 if sales==.|sales[_n-1]==.
replace lsales=. if sales==.
replace emp=. if sales==.
replace lemp=. if lsales==.
replace xrd=. if sales==.
replace lxrd=. if sales==.
*drop dy jumpyear demp dsales sales_emp dym
so cusip year
drop sss
so cusip year
egen maxy=max(year*(sales~=.)),by(cusip)
drop if year>maxy+1
drop maxy

*DEALING WITH JUMPING YEAR  - Johns code (very good obviously....)
encode cusip,gen(num)
cap prog drop jumpsclean
cap prog def jumpsclean
cap drop dyear 
cap drop zz
egen zz=group(`1')
ge old`1'=`1'
cap drop num
ge num=zz
so num year
qui by num:ge dyear=year-year[_n-1]
ge prob=1 if dyear>1&dyear~=.
replace prob=0 if prob==.
egen mprob=max(prob),by(num)
ge prob_yr=year if dyear>1&dyear~=.
replace prob_yr=0 if prob_yr==.
egen maxprob_yr=max(prob_yr),by(num)
egen nojumps=sum(prob),by(num)
egen maxnojumps=max(nojumps)
local i = 1
while `i' <= maxnojumps  {
di `i'
replace num=num + 100000 if mprob==1&(year<maxprob_yr)
replace prob_yr = 0 if year==maxprob_yr
cap drop maxprob_yr
egen maxprob_yr=max(prob_yr),by(num)
local i = `i' + 1 
}

local j=num
egen temp=group(num)
replace num=temp
cap drop nojumps maxnojumps mprob prob_yr maxprob_yr temp zz
so num year
cap drop dyear
qui by num:ge dyear=year-year[_n-1]
noi di "***** This should always be unity ******"
tab dyear
end
jumpsclean num
cap drop noj
egen noj=count(num),by(num)
so num year

**************GENERATING SOME CORE FLOW VARIABLES
qui by num:gen lxrd1=lxrd[_n-1]
qui by num:gen lsales1=lsales[_n-1]
qui by num:gen sales1=sales[_n-1]
qui by num:gen lppent1=lppent[_n-1]
qui by num:gen lemp1=lemp[_n-1]
qui by num:gen lsales_ind1=lsales_ind[_n-1]
qui by num:gen lsales_ind_ns1=lsales_ind_ns[_n-1]
qui by num:gen lsales_ind_ns_dum1=lsales_ind_ns_dum[_n-1]
replace lsales_ind=lsales_ind1 if cusip=="816119"&year==2001
qui by num:gen lsales_ind2=lsales_ind[_n-2]
qui by num:gen lpatents_ind1=lpatents_ind[_n-1]
qui by num:gen lpatents_ind2=lpatents_ind[_n-2]
qui by num:gen lpat_cite_norm1=lpat_cite_norm[_n-1]
qui by num:gen lpat_count1=lpat_count[_n-1]
qui by num:gen pat_count1=pat_count[_n-1]


**********Generating patent stock - 0% growth per year plus 15% depreciation
replace pat_cite_norm=0 if pat_cite_norm==.
gen gpatent=pat_cite_norm/0.1
qui by num:replace gpatent=0.85*gpatent[_n-1] + pat_cite_norm if gpatent[_n-1]~=.
replace pat_count=0 if pat_count==.
gen gpatent_count=pat_count/0.1
qui by num:replace gpatent_count=0.85*gpatent_count[_n-1] + pat_count if gpatent_count[_n-1]~=.
************Generating patent count - 0% growth per year plus 15% depreciation
gen kpat_cite=pat_cite/0.1
qui by num:replace kpat_cite=kpat_cite[_n-1]*0.85 + kpat_cite if kpat_cite[_n-1]~=.
************Generating R&D stocks - 5% real growth per year plus 15% depreciation
replace xrd=0 if xrd==.
gen rxrd=xrd/pindex
gen grd=rxrd/0.1
qui by num:replace grd=0.85*grd[_n-1] + rxrd if grd[_n-1]~=.
replace hxrd=0 if hxrd==.
gen rhxrd=hxrd/pindex
gen ghxrd=rhxrd/0.1
qui by num:replace ghxrd=0.85*ghxrd[_n-1] + rhxrd if ghxrd[_n-1]~=.

***************GENERATING SPILLSIC, SPILLTEC and SPILLLOC STOCK
foreach var in $varlist {
gen rspill`var'=spill`var'/pindex
gen gspill`var'=spill`var'/0.1
qui by num:replace gspill`var'=gspill`var'[_n-1]*0.85 + rspill`var' if gspill`var'[_n-1]~=.
gen lgspill`var'=log(gspill`var')
so num year
qui by num: gen lgspill`var'1=lgspill`var'[_n-1]
}

***************GENERATING A SET OF CORE PATENT AND R&D MEASURES
gen lkpat_cite=log(kpat_cite)
replace capx=0 if capx==.
gen rppent=ppent/pindex
gen rcapx=capx/pindex
gen kstock=rppent
qui by num:replace kstock=kstock[_n-1]*0.92 + rcapx if kstock[_n-1]~=.
gen lgrd=log(grd)
gen lghxrd=log(ghxrd)
gen lgpatent=log(gpatent)
gen lgpatent_count=log(gpatent_count)
gen lkstock=log(kstock)
qui by num:gen lcogs1=log(cogs[_n-1])
qui by num:gen lgrd1=lgrd[_n-1]
qui by num:gen lghxrd1=lghxrd[_n-1]
qui by num:gen grd1=grd[_n-1]
qui by num:gen lgpatent1=lgpatent[_n-1]
qui by num:gen lgpatent_count1=lgpatent_count[_n-1]
qui by num:gen gpatent_count1=gpatent_count[_n-1]
qui by num:gen lkstock1=lkstock[_n-1]
qui by num:gen dlsales=lsales-lsales[_n-1]
qui by num:gen dlemp=lemp-lemp[_n-1]
qui by num:gen dlppent=lppent-lppent[_n-1]
gen profit=sales-cogs
gen lprofit=log(sales-cogs)

*******************Generating Tobin Q type measures
gen rmkvaf=mkvaf/pindex
gen rpstk=pstk/pindex
gen rdt=dt/pindex
gen rinvt=invt/pindex
gen rivaeq=ivaeq/pindex
gen rivao=ivao/pindex
gen rintan=intan/pindex
gen ract=act/pindex
replace ract=rdt if ract>rdt
replace rpstk=0 if rpstk<0
replace rivaeq=0 if rivaeq<0
replace rmkvaf=. if rmkvaf<=0.25
gen value=rmkvaf + rpstk + rdt - ract
gen value_e=rmkvaf + rpstk 
gen value_d=rdt - ract
*Dummy variable for any of these missing
gen qkstock=rppent + rinvt + rivaeq + rivao + rintan 
gen dum_qkstock=(qkstock==.)
replace rinvt=0 if rinvt==.
replace rivaeq=0 if rivaeq==.
replace rivao=0 if rivao==.
replace rintan=0 if rintan==.
replace qkstock=rppent + rinvt + rivaeq + rivao + rintan 
gen tobinq=value/qkstock
gen tobinq_e=value_e/qkstock
gen tobinq_d=value_d/qkstock
gen rawtobinq=tobinq
replace tobinq=0.1 if tobinq<0.1
replace tobinq=20 if tobinq>20&tobinq~=.
replace tobinq_e=0.1 if tobinq_e<0.1
replace tobinq_e=20 if tobinq_e>20&tobinq_e~=.
replace tobinq_d=0.05 if tobinq_d<0.05
replace tobinq_d=5 if tobinq_d>5&tobinq_d~=.
gen lq=log(tobinq)
gen lq_e=log(tobinq_e)
gen lq_d=log(tobinq_d)
so num year
qui by num:gen lq1=lq[_n-1]

*******************GENERATING RELATED TOBINS Q MEASURES WHICH REQUIRE Q DEMONIATOR
gen grd_k=grd/qkstock
replace grd_k=10 if grd_k>10&grd_k~=.
gen gpat_k=gpatent/qkstock
replace gpat_k=10 if gpat_k>10&gpat_k~=.
gen gpatcount_k=gpatent_count/qkstock
replace gpatcount_k=10 if gpatcount_k>10&gpatcount_k~=.
gen gtec_k=gspilltec/qkstock
gen gsic_k=gspillsic/qkstock
gen pat_k=gpatent/qkstock
gen grd_k_dum=(grd==0)
qui by num:gen grd_k1=grd_k[_n-1]
qui by num:gen gtec_k1=gtec_k[_n-1]
qui by num:gen gsic_k1=gsic_k[_n-1]
qui by num:gen pat_k1=pat_k[_n-1]
qui by num:gen grd_k1_dum=grd_k_dum[_n-1]
qui by num:gen gpat_k1=gpat_k[_n-1]
qui by num:gen gpatcount_k1=gpatcount_k[_n-1]
qui by num:gen gpat_k1_dum=(gpat_k1==0)
qui by num:gen gpatcount_k1_dum=(gpatcount_k1==0)
gen gtecxrd_k=lgspilltec*grd/qkstock
so num year
qui by num:gen lkpat_cite1=lkpat_cite[_n-1]
qui by num:gen pat_cite_norm1=pat_cite_norm[_n-1]
tab year,gen(yy)
egen pat_all=sum(pat_count),by(num)

***************GENERATING A MATERIALS MEASURE
*Generating a COGS number
gen ccog=sales-oibdp
gen sic3=int(sic/10)
gen sic2=int(sic/100)
gen cty="us"
so cty sic3 year
merge cty sic3 year using uswage
drop cty
drop if _==2
drop _merge
egen mindwage=mean(indwage),by(year)
replace indwage=mindwage if indwage==.
drop mindwage
replace indwage=indwage/1000
*Scaling up by 54% to include full social security and overhead costs
gen nwage=emp*indwage*1.54
gen materials=ccog-nwage
replace materials=. if materials>sales|materials<=0
egen rati=mean(materials/sales), by (sic3)
replace materials=rati*sales if materials==.
so num year
by num:gen lmat1=log(materials[_n-1])

*******CREATING TERMS FOR A Taylor expansion of the log of grd_k1
gen grd_kt2=grd_k1^2
gen grd_kt3=grd_k1^3
gen grd_kt4=grd_k1^4
gen grd_kt5=grd_k1^5
gen grd_kt6=grd_k1^6
gen gpat_kt2=gpat_k1^2
gen gpat_kt3=gpat_k1^3
gen gpat_kt4=gpat_k1^4
gen gpat_kt5=gpat_k1^5


****************************CREATING ALL THE INITIAL CONDITIONS DATA
egen f_year=max(year*(sales==.)),by(cusip)
egen fyear=max(year*(year[_n-1]==f_year)),by(cusip)
egen myear=min(year),by(cusip)
replace fyear=myear if fyear==0
*******HERE prior_years determines the number of initial years used to calculate initial conditions
gen prior_years=4
egen riorpat      =mean(pat_count) if (year<fyear+prior_years),by(cusip)
egen riorpat_cite =mean(pat_cite) if (year<fyear+prior_years),by(cusip)
egen riorlgpat    =mean(lgpatent_count) if (year<fyear+prior_years),by(cusip)
egen riorgrd      =mean(grd)      if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorppent    =mean(ppent)    if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorsales    =mean(sales)    if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorgspilltec=mean(gspilltec) if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorgspillsic=mean(gspillsic) if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorlq       =mean(lq)       if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorgtec_k   =mean(gtec_k)   if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorgsic_k   =mean(gsic_k)   if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorgrd_k    =mean(grd_k)    if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen riorlsales_ind    =mean(lsales_ind)    if (year>=fyear)&(year<fyear+prior_years),by(cusip)
egen priorpat     =max(riorpat),by(cusip)
egen priorpat_cite=max(riorpat_cite),by(cusip)
egen priorlgpat     =max(riorlgpat),by(cusip)
egen priorgrd     =max(riorgrd),by(cusip)
egen priorppent   =mean(riorppent),by(cusip)
egen priorsales   =mean(riorsales),by(cusip)
egen priorgspilltec=mean(riorgspilltec),by(cusip)
egen priorgspillsic=mean(riorgspillsic),by(cusip)
egen priorlq      =mean(riorlq),by(cusip)
egen priorgtec_k  =mean(riorgtec_k),by(cusip)
egen priorgsic_k  =mean(riorgsic_k),by(cusip)
egen priorgrd_k   =mean(riorgrd_k),by(cusip)
egen priorlsales_ind   =mean(riorlsales_ind),by(cusip)
drop lsales_ind*
so cusip year
merge cusip year using lsales_ind
drop _
so num year
gen priordum_grd_zero=(priorgrd_k==0)
gen lpriorgrd=log(priorgrd)
gen lpriorppent=log(priorppent)
gen lpriorsales=log(priorsales)
gen lpriorgspilltec=log(priorgspilltec)
gen lpriorgspillsic=log(priorgspillsic)
gen lpriorpat=log(priorpat)
gen lpriorpat_cite=log(priorpat_cite)

replace lpriorgrd=-1 if priorgrd==0
gen lpriorgrd_dum=(priorgrd==0)
by num:gen lpriorgrd1=lpriorgrd[_n-1]
by num:gen lpriorgrd1_dum=lpriorgrd_dum[_n-1]
replace lpriorpat=-1 if priorpat==0
gen lpriorpat_dum=(priorpat==0)
replace lpriorpat_cite=0 if priorpat_cite==0
ge lpriorpat_cite_dum= priorpat_cite==0
by num:gen lpriorpat1=lpriorpat[_n-1]
qui by num:gen lpriorpat1_dum=lpriorpat_dum[_n-1]
gen lpind_ind=log(pind_ind)
by num:ge pat_cite1=pat_cite[_n-1]
ge lpat_cite1=log(pat_cite1)
replace lpat_cite1=0  if pat_cite1==0
ge lpat_cite1_dum=pat_cite1==0
ge lpat_cite=log(pat_cite)



*****************************GENERATING SOME PATENT AND R&D STOCK DATA
replace lgrd=-1 if grd==0
gen lgrd_dum=(grd==0)
by num:replace lgrd1=lgrd[_n-1]
by num:gen lgrd1_dum=lgrd_dum[_n-1]
replace lpat_count=-1 if pat_count==0
gen lpat_count_dum=(pat_count==0)
by num:replace lpat_count1=lpat_count[_n-1]
by num:gen lpat_count1_dum=lpat_count_dum[_n-1]
replace lgpatent=-1 if gpatent==0
gen lgpatent_dum=(gpatent==0)
by num:replace lgpatent1=lgpatent[_n-1]
by num:gen lgpatent1_dum=(lgpatent_dum[_n-1])
replace lgpatent_count=-1 if gpatent_count==0
gen lgpatent_count_dum=(gpatent_count==0)
by num:replace lgpatent_count1=lgpatent_count[_n-1]
by num:gen lgpatent_count1_dum=lgpatent_count_dum[_n-1]
encode cusip,gen(code)

**************IMPORTING SIC3 YEAR DEFLATORS*****************************************
cap drop _
compress
cap gen sic3=int(sic/10)
so sic3 year
drop pind_ind
merge sic3 year using deflators
drop if _==2
egen pind_indm=mean(pind_ind),by(year)
replace pind_ind=pind_indm if pind_ind==.
gen rsales=sales/pind_ind
gen lrsales=log(sales/pind_ind)
so num year
qui by num:gen lrsales1=lrsales[_n-1]
cap gen lpind_ind=log(pind_ind)

*For IV regressions: Take log R&D stock over to LHS by imposing a coefficient of unity as endogeneous
gen lqq=lq-log(1+grd_k)
gen lxrd_sales=lxrd-lsales
so num year
gen lxrd_sales1=lxrd_sales[_n-1]
gen lfirm_dum=firm_dum
gen gfirm=firm/0.05
qui by num:replace gfirm=0.85*gfirm[_n-1] + firm if gfirm[_n-1]~=.
gen lgfirm=log(gfirm)
gen lgfirm_dum=(lgfirm==.)
replace lgfirm=0 if lgfirm_dum==1
cap gen state=exp(lstate)
gen gstate=state/0.05
qui by num:replace gstate=0.85*gstate[_n-1] + state if gstate[_n-1]~=.
gen lgstate=log(gstate)
by num:gen lgfirm1=lgfirm[_n-1]
by num:gen lgfirm_dum1=lgfirm_dum[_n-1]
by num:gen lgstate1=lgstate[_n-1]
by num:gen lfirm1=lfirm[_n-1]
by num:gen lfirm_dum1=lfirm_dum[_n-1]
by num:gen lstate1=lstate[_n-1]



*GENERATING A NOJ COUNT
drop noj
egen noj=count(year),by(num)
*drop if noj==1
compress
drop if year==.
so num year
drop yy1 - yy11
**************LABELLING UP ALL THE VARIABLES*****************************************
lab var noj "Count observations per firm (includes pre-sample patent observations)"
lab var rsales "Sales in 1996 values"
lab var lrsales "Log Sales in 1996 values"
lab var lrsales1 "Lag Log Sales in 1996 values"
lab var rppent "Net book value of property, plant and equipment in 1996 values"
lab var ppent "Net book value of property, plant and equipment"
lab var tobinq "Tobin's Q calculated following Hall, Jaffe and Trajtenberg, 2000"
lab var tobinq_e "Equity component of Tobin's Q calculated following Hall, Jaffe and Trajtenberg, 2000"
lab var tobinq_d "Debt component of Tobin's Q calculated following Hall, Jaffe and Trajtenberg, 2000"
lab var lq "Log Tobin's Q"
lab var lq1 "Lag Log Tobin's Q"
lab var lq_e "Log Tobin's Equity Q - tobinq_e"
lab var lq_d "Log Tobin's Debt Q - tobinq_d"
lab var dum_qkstock "Some minor numbers missing for kstock in Tobin's q - set to zero when missing"
lab var rxrd   "Expenditure on R&D, 1996 values"
lab var xrd   "Expenditure on R&D"
lab var grd   "Stock value of R&D assuming 15% depreciation, 1996 values"
lab var pindex "CPI price index used to deflate all variables"
lab var spillsic "SIC correlation weighted R&D of other firms, 1996 values"
lab var spilltec "Patent NClass correlation weighted R&D of other firms, 1996 values"
lab var lgspillsic "Stock of SIC correlation weighted R&D of other firms, 1996 values"
lab var lgspilltec "Stock of Patent NClass correlation weighted R&D of other firms, 1996 values"
cap lab var lgspilltloc "Stock of Location weighted R&D of other firms, 1996 values"
lab var grd_k "R&D stock divided by capital stock"
lab var gpat_k "Patent stock divided by capital stock"
lab var gpat_k1 "Lagged Patent stock divided by capital stock"
lab var gpat_k1_dum "Missing value indicator for lagged Patent stock divided by capital stock"
lab var pat_all "Total granted patents per firm applied for over 1970-1999"
lab var gpatent "Cite weighted and year normalized stock of firm patents"
lab var lgpatent "Log of Cite weighted and year normalized stock of firm patents"
lab var lgpatent_dum "Missing indicator for Log of Cite weighted and year normalized stock of firm patents"
lab var lgpatent1 "Lag Log of Cite weighted and year normalized stock of firm patents"
lab var lgpatent1_dum "Missing indicator for lagged Log of Cite weighted and year normalized stock of firm patents"
lab var gpatent_count "Stock of firm patent count"
lab var lgpatent_count "Log Stock of firm patent count"
lab var lgpatent_count_dum "Missing indicator for Log Stock of firm patent count"
lab var lgpatent_count1 "Lag Log Stock of firm patent count"
lab var lgpatent_count1_dum "Missing indicator for lagged Log Stock of firm patent count"
lab var kpat_cite
lab var lgpatent "Log of Cite weighted and year normalized stock of firm patents"
lab var invt "Total inventories"
lab var intan "Total intangibles"
lab var ivaeq "Investments and advances - equity method"
lab var ivao "Investments and advances - other"
lab var act "Current assets - total"
lab var ao "Assets other"
lab var oiadp "Operating profits before amortization and depreciation"
lab var mkvaf "Market value"
lab var dt "Total debt"
lab var pstk "Preferred Equity Total (par/stated value)"
lab var xad "Advertising expense"
lab var pi "Pre-tax income"
lab var ppegt "Plant, property and equipment, gross book value"
lab var capx "Capital expenditures"
lab var capxv "Capital expenditure through acquisition as well"
lab var xlr "Labour expenses"
lab var lxrd "Log R&D expenditure"
lab var lxrd1 "Lag Log R&D expenditure"
lab var grd "Stock of R&D expenditures"
lab var lgrd "Log of stock of R&D expenditures"
lab var ghxrd "Stock of instrument predicted R&D expenditures"
lab var lghxrd "Log of stock of  instrument predicted R&D expenditures"
lab var lgrd1 "Lag Log of stock of R&D expenditures"
lab var lgrd_dum "Missing indicator for Log of stock of R&D expenditures"
lab var lgrd1_dum "Missing indicator for Lag Log of stock of R&D expenditures"
lab var grd_k_dum "R&D stock over capital missing dummy"
lab var grd_kt2 "R&D stock over capital^2"
lab var grd_kt3 "R&D stock over capital^3"
lab var grd_kt4 "R&D stock over capital^4"
lab var grd_kt5 "R&D stock over capital^5"
lab var gpat_kt2 "Patent stock over capital^2"
lab var gpat_kt3 "Patent stock over capital^3"
lab var gpat_kt4 "Patent stock over capital^4"
lab var gpat_kt5 "Patent stock over capital^5"
lab var grd_k1_dum "Lagged R&D stock over capital missing dummy"
lab var grd_k1 "lagged R&D stock over capital"
lab var lsales "Log sales"
lab var lsales1 "Lag Log sales"
lab var lppent "Log of ppent - i.e. net tangible fixed assets"
lab var lppent1 "Lag Log of ppent - i.e. net tangible fixed assets"
lab var lemp "Log count of employees"
lab var lemp1 "Lag Log count of employees"
lab var lgspilltec "Log stock of tec weighted R&D (spillovers)"
lab var lgspilltec1 "Lag Log stock of tec weighted R&D (spillovers)"
lab var lgspillsic "Log stock of sic weighted R&D (spillovers)"
lab var lgspillsic1 "Lagged Log stock of sic weighted R&D (spillovers)"
cap lab var lgspilltloc "Log stock of location weighted R&D (spillovers)"
cap lab var lgspilltloc1 "Lagged Log stock of location weighted R&D (spillovers)"
cap lab var lgspillsloc "Log stock of sales location weighted R&D (spillovers)"
cap lab var lgspillsloc1 "Lagged Log stock of location weighted R&D (spillovers)"

lab var lpatents_ind "Log Total patents in n-class weighted industries (by firm year) - tech shock control"
lab var lpatents_ind1 "Lag Log Total patents in n-class weighted industries (by firm year) - tech shock control"
lab var lpatents_ind2 "Twice Lagged Log Total patents in n-class weighted industries (by firm year) - tech shock control"
lab var lpat_count "Log of patent count by year - missing values -1 and missing indicator lpat_count_dum"
lab var lpat_count1 "Lag of Log of patent count by year - missing values -1 and missing indicator lpat_count_dum"
lab var lpat_count_dum "Dummy for missing value of log of patent count by year"
lab var lpat_count1_dum "Dummy for missing value of lag of log of patent count by year"
lab var lpat_cite_norm "Log of cite weighted patent count by year"
lab var lpat_cite_norm1 "Lag of Log of cite weighted patent count by year"
lab var kstock "Capital stock calculated by the perpetual inventory method from ppent initial value and then capex"
lab var lkstock "Log of Capital stock calculated by the perpetual inventory method from ppent initial value and then capex"
lab var lkstock1 "Lag Log of Capital stock calculated by the perpetual inventory method from ppent initial value and then capex"
lab var pind_ind "Price index, yearly at 3-digit SIC level"
lab var lpind_ind "Price index, yearly at 3-digit SIC level"
lab var lsales_ind "Logged total sales weighted by SIC matrix"
lab var lsales_ind1 "Lagged Logged total sales weighted by SIC matrix"
lab var lsales_ind2 "Twice Lagged Logged total sales weighted by SIC matrix"
lab var lpriorgrd "Logged initial conditions stock of R&D (pre-sample values)"
lab var lpriorgrd1 "Lagged Logged initial conditions stock of R&D (pre-sample values)"
lab var lpriorgrd_dum "Missing indicator for Logged initial conditions stock of R&D (pre-sample values)"
lab var lpriorgrd1_dum "Missing indicator for lagged Logged initial conditions stock of R&D (pre-sample values)"
lab var lpriorppent "Logged initial conditions ppent (pre-sample values)"
lab var lpriorsales "Logged initial conditions sales (pre-sample values)"
lab var lpriorgspilltec "Logged initial conditions lgspilltec (pre-sample values)"
lab var lpriorgspillsic "Logged initial conditions lgspillsic (pre-sample values)"
lab var lpriorpat "Logged initial conditions patent count (pre-sample values)"
lab var lpriorpat_dum "Missing indicator for Logged initial conditions patent count (pre-sample values)"
lab var lpriorpat1 "Lagged Logged initial conditions patent count (pre-sample values)"
lab var lpriorpat1_dum "Missing indicator for Lagged Logged initial conditions patent count (pre-sample values)"
lab var sic3 "Three digit SIC code"
lab var fyear "First year using actual data in patents stuff"
lab var prior_years "Number of years used to make initial conditions"
lab var i "Unique firm level indentifier, like cusip but in numeric values"
cap drop _merge
so cusip year

***SAVE THIS FOR THE NEW OLD RESULTS (I.E. CHANGED CLEANING PROCESS ABOVE)
saveold spillovers,replace




