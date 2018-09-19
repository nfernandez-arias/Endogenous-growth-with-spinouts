clear all
set more off
set maxvar 11000
* NO R&D AMPLIFICATION AND FULLY SYMMETRIC
qui u "$raw_data/BSV_spillovers",clear
qui keep if inrange(year,1981,2001)	// regression sample
qui gen mgrd=rxrd/0.1
qui gen Y_G=rsales/mgrd
qui collapse (median) Y_G mgrd rxrd rsales rppent
list
qui u "$data/rsample",clear
qui keep if inrange(year,1981,2015)	// regression sample
qui gen mgrd=rxrd/0.1
qui gen Y_G=rsales/mgrd
qui collapse (median) Y_G mgrd rxrd rsales rppent
list
//assume sigma=(0.5)
gen sigma=0.5
*gen phi1=0.010				// dlsales/dlgrd1
*gen phi2=0.240				// dlsales/dlgspilltech1
gen phi1=0.015				// dlsales/dlgrd1,  assuming no spillsic effect on output
gen phi2=0.231				// dlsales/dlgspilltech1,  assuming no spillsic effect on output
gen gamma3=-0.086			// dlq/dlgspillsic1
gen MSR=Y_G*(phi1+phi2)
gen MPR=Y_G*(phi1-sigma*gamma3)
gen MSR_MPR=MSR/MPR
list MSR MPR MSR_MPR Y_G
di "BSV MSR/MPR=" (0.042+0.186)/( 0.042-0.5*(-0.083))
* 
STOP

u "$data/rsample",clear
collapse (mean) xrd grd pat_count sales emp (firstnm) sic, by(gvkey)
rename * m*_
rename mgvkey_ gvkey_
rename msic_ sic_
tempfile experiment_
save `experiment_'
u "$data/spill_tmp", clear
keep gvkey gvkey_ sic tec malsic maltec
rename *tec *teccor
rename *sic *siccor
merge m:1 gvkey_ using `mgrd'
	keep if _m==3
	drop _m
merge m:1 gvkey using `x', keepusing(gvkey)
	keep if _m==3
	drop _m
sa "$data/spillovers_big", replace
*
foreach var in "baseline" "IV" "mal" {
u "$data/spillovers_big", clear
qui egen mmgrd=mean(mgrd)
qui gen omgrd=mgrd
qui replace mgrd=mmgrd
qui drop mmgrd
qui egen ccc=sum(gvkey==gvkey_),by(gvkey)
qui drop if ccc==0
qui gen code_=gvkey_
qui gen code=gvkey
qui so gvkey_
qui sa "$data/ncode_",replace
qui so gvkey
qui sa "$data/ncode",replace
qui so gvkey_
qui sa "$data/nstagea",replace

*This bit just for overview data later on - only need to run once
qui merge m:1 gvkey_ using `experiment_'
	qui keep if _m==3
	qui drop _m
if "`var'"=="mal"|"`var'"=="malIV" {
replace teccor=malteccor
replace siccor=malsiccor
}
qui egen mtec=mean(teccor),by(code_)
qui egen msic=mean(siccor),by(code_)
qui so code_
qui drop if code_==code_[_n-1]
*qui keep msic mtec code_ mxrd_ mgrd_ msales_ rd_ silo_ sihi_ ra_ mgrowth_ sic_ memp_
qui keep msic mtec code_ mxrd_ mgrd_ msales_ sic_ memp_
*lab var rd "RD tax credit firms"
*lab var silo "Smaller firms>0, larger firms==0"
qui so code_
qui sa "$data/overview_",replace
qui ren code_ code
qui ren mgrd_ mgrd
qui ren msales_ msales
qui so code
qui sa "$data/overview",replace

u "$data/nstagea",clear
drop ccc
qui gen tecrd=teccor*mgrd
qui egen atec=sum(tecrd),by(code)
gen bij=(tecrd/atec)
gen sicrd=siccor*mgrd
qui egen asic=sum(sicrd),by(code)
gen dij=(sicrd/asic)
qui drop mgrd
qui compress
qui keep gvkey* sic bij dij sic code code_


if "`var'"=="baseline" {
*************************************
*FILL IN REGRESSION COEFFICIENTS HERE AND CHANGE BELOW AS WELL
*Note that the matrix term always refers to the R&D impulse
*************************************
*BASIC R&D EQUATIONS
qui gen alpha2=(0     + 0.180)/(1-0.009)
qui gen alpha3=(0.268 + 0    )/(1-0.009)
*PRODUCTIVITY
qui gen peta1_=0.009
*matrix peta1=0
qui gen peta2=0.180
qui gen peta3=0
*VALUE FUNCTION
qui gen val3=-0.059
}

if "`var'"=="IV" {
*************************************
*FILL IN REGRESSION COEFFICIENTS HERE AND CHANGE BELOW AS WELL
*Note that the matrix term always refers to the R&D impulse
*************************************
*BASIC R&D EQUATIONS
qui gen alpha2=(0     + 0.229)/(1-0.012)
qui gen alpha3=(0     + 0    )/(1-0.012)
*PRODUCTIVITY
qui gen peta1_=0.012
qui gen peta2=0.229
qui gen peta3=0
*VALUE FUNCTION
qui gen val3=-0.215
}


if "`var'"=="mal" {
***MAHALONOBIS
*************************************
*FILL IN REGRESSION COEFFICIENTS HERE AND CHANGE BELOW AS WELL
*Note that the matrix term always refers to the R&D impulse
*************************************
*BASIC R&D EQUATIONS
qui gen alpha2=(0     + 0.299)/(1-0.010)
qui gen alpha3=(0.508 + 0    )/(1-0.010)
*PRODUCTIVITY
qui gen peta1_=0.010
qui gen peta2=0.299
qui gen peta3=0
*VALUE FUNCTION
qui gen val3 =-0.062
}


*Assume 50% of spillover business stealing goes to output
qui replace val3=val3/2

qui gen thetaij=alpha2*bij + alpha3*dij
qui gen deltaij=peta1*(gvkey==gvkey_)+peta2*bij + peta3*dij
qui gen valij=              val3*dij

*Homogeneous size - give them all the sample average of real sales to real R&D (for R&D doing firms)
qui gen msales=2.48																					// need to change this
qui gen mgrd=1
qui replace mgrd=0 if code~=code_
qui replace msales=0 if code~=code_
qui save "$data/temp",replace

qui u "$data/temp",clear

qui so code
qui merge m:1 code using "$data/overview"
qui keep code code_ theta delta valij* mgrd msales peta1_
qui egen num=max(code)
qui global NUM=num

qui reshape wide theta delta vali mgrd msales peta1_,i(code) j(code_)
qui so code
qui order theta* delta* val*  peta1_* msales* mgrd* 
qui mkmat thetaij1 - thetaij$NUM,matrix(H)
qui mkmat deltaij1 - deltaij$NUM,matrix(M)
qui mkmat valij1 - valij$NUM,matrix(GAMMA)
qui mkmat mgrd1-mgrd$NUM,matrix(BG)
qui mkmat msales1-msales$NUM,matrix(BY)
qui matrix OMEGA=I($NUM)-H
qui matrix OMEGA_INV=inv(OMEGA)
qui matrix dR=BG*OMEGA_INV
qui matrix dY=BY*M*OMEGA_INV
qui matrix dB=BY*GAMMA*OMEGA_INV
qui keep thetaij1  code
qui replace thetaij1=1
qui ren thetaij1 i
qui mkmat i
qui matrix setup_i_star=I($NUM)
qui matrix setup_i_starstar=I($NUM)-J($NUM,$NUM,1/$NUM)
qui gen social=.
qui gen private=.
qui gen private_noBS=.

forv i=1(1)$NUM {
qui matrix i_star=setup_i_star[1... ,`i']
qui matrix i_starstar=setup_i_starstar[1... ,`i']

*Social
qui matrix aggregate_Y_soc=(dY*i_star)'*i
qui matrix aggregate_R_soc=(dR*i_star)'*i
qui cap drop ratio agg_*
qui svmat aggregate_Y_soc,name(agg_Y)
qui svmat aggregate_R_soc,name(agg_R)
qui egen ratio=max(agg_Y/agg_R)
qui replace social=ratio if _n==`i'

*Private
qui cap drop ratio agg_*
qui matrix aggregate_R=(dR*i_star)'*i_star
*Note give the firm the business stealing share of it's increase in R&D over total increase in R&D
qui matrix aggregate_Y=(dY*i_star)'*i_star - (dB*i_star)'*i*(aggregate_R*inv(aggregate_R_soc))
qui cap drop agg* ratio
qui svmat aggregate_Y,name(agg_Y)
qui svmat aggregate_R,name(agg_R)
qui egen ratio=max(agg_Y/agg_R)
qui replace private=ratio if _n==`i'

*Private, no BS
qui cap drop ratio agg_*
qui matrix aggregate_R=(dR*i_star)'*i_star
*Note give the firm the business stealing share of it's increase in R&D over total increase in R&D
qui matrix aggregate_Y=(dY*i_star)'*i_star 
qui cap drop agg* ratio
qui svmat aggregate_Y,name(agg_Y)
qui svmat aggregate_R,name(agg_R)
qui egen ratio=max(agg_Y/agg_R)
qui replace private_noBS=ratio if _n==`i'

}

qui keep social private* code 
so code
qui gen gap=social-private
qui merge m:1 code using "$data/overview"
qui ren sic_ sic
qui gen sic3=floor(sic/10)
qui drop _merge

if "`var'"=="baseline" {
di  _newline(10)
di "Baseline results"
su social private* gap
*Generate size quartiles
qui xtile groups=memp,nq(4)
qui so groups
di  _newline(10)
di "Size results"
label define groups 1 "smallest quintile" 2 "second quintile" 3 "third quintile" 4 "largest quintile"
label values groups groups
by groups: su social private* gap
}

if "`var'"=="IV" {
di  _newline(10)
di "IV results"
su social private* gap
}

if "`var'"=="mal" {
di  _newline(10)
di "Mahalanobis results"
su social private* gap
}

}
