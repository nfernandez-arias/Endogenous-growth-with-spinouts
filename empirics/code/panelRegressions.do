clear all

set more off

cd "Z:\home\nico\nfernand@princeton.edu\PhD - Thesis\Research\Endogenous-growth-with-spinouts\empirics"

insheet using "data/compustat-spinouts_Stata.csv"

rename spinoutcountunweighted spinoutCountUnweighted
*rename spinoutcountunweighted_onlyexits spinoutCountUnweighted_onlyExits
rename spinoutcount spinoutCount
rename firmage age

rename spinoutindicator spinoutIndicator
rename exitspinoutindicator exitSpinoutIndicator
rename valuablespinoutindicator valuableSpinoutIndicator

encode state, gen(stateCode)

rename spinoutCount spinoutCountWeighted
label variable spinoutCountUnweighted "Spinouts (unweighted)"

rename spinoutCountUnweighted Spinouts
label variable Spinouts "Spinouts (weighted)"

rename spinoutcountunweighted_onlyexits ExitingSpinouts
label variable ExitingSpinouts "Exiting Spinouts"

rename spinoutsdiscountedexitvalue SpinoutsDEV
label variable SpinoutsDEV "Spinouts DEV"

rename spinoutsdiscountedffvalue SpinoutsDFFV
label variable SpinoutsDFFV "Spinouts DFFV"

rename spinoutcountunweighted_discounted SpinoutsDTE
label variable SpinoutsDTE "Spinout Count DTE"

label variable xrd "R\&D (millions US\$)"
label variable stateCode "State"
label variable SpinoutsDEV "Spinouts Discounted Exit Value (millions US\$)"
label variable emp Employment
label variable patentapplicationcount_cw "Patent Applications (CW)"

gen lxrd = log(xrd)
gen lsalesfd = log(salesfd)
gen ltobin_q = log(tobin_q)
gen lebitda = log(ebitda)
gen lemp = log(emp)
gen lpatentcount_cw_cumulative = log(patentcount_cw_cumulative)

*Run regressions

xtset gvkey year
sort gvkey year

set emptycells drop

* California and Massachusetts indicators
gen californiaIndicator = 1 if state == "CA"
replace californiaIndicator = 0 if californiaIndicator == .
gen xrdCalif = xrd * californiaIndicator

gen massachusettsIndicator = 1 if state == "MA"
replace massachusettsIndicator = 0 if massachusettsIndicator == .
gen xrdMass = xrd * massachusettsIndicator

* Winsorize xrd
*winsor2 xrd, replace cuts(1,99)

* change units

egen std_at = std(at)
egen std_tobin_q_assets = std(tobin_q_assets)
egen std_patentcount_cw_cumulative = std(patentcount_cw_cumulative)
egen std_emp = std(emp)

gen xrd_fw_pre_4 = xrd * fw_pre4
gen xrd_fw_pre_3 = xrd * fw_pre3
gen xrd_fw_pre_2 = xrd * fw_pre2
gen xrd_fw_pre_1 = xrd * fw_pre1
gen xrd_fw_post_0 = xrd * fw_post0
gen xrd_fw_post_1 = xrd * fw_post1
gen xrd_fw_post_2 = xrd * fw_post2
gen xrd_fw_post_3 = xrd * fw_post3
gen xrd_fw_post_4 = xrd * fw_post4

gen xrd_fd = xrd[_n] - xrd[_n-1]
gen std_tobin_q_assets_fd = std_tobin_q_assets[_n] - std_tobin_q_assets[_n-1]
gen tobin_q_fd = tobin_q[_n] - tobin_q[_n-1]
gen std_at_fd = std_at[_n] - std_at[_n-1]
gen ch_fd = ch[_n] - ch[_n-1]
gen assettang_fd = assettang[_n] - assettang[_n-1]
gen roa_fd = roa[_n] - roa[_n-1]
gen std_emp_fd = std_emp[_n] - std_emp[_n-1]
gen std_patentcount_cw_cumulative_fd = std_patentcount_cw_cumulative[_n] - std_patentcount_cw_cumulative[_n-1]

gen spinouts_fut4_fd = spinouts_fut4[_n] - spinouts_fut4[_n-1]
gen founders_fut4_fd = founders_fut4[_n] - founders_fut4[_n-1]
gen spinoutsdffv_fut4_fd = spinoutsdffv_fut4[_n] - spinoutsdffv_fut4[_n-1]


** Effect of R&D on spinout formation, and effect of non-compete enforcement changes on this relationship

* OLS

gen xrd2 = xrd^2

eststo model1: reg spinouts_fut4 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, robust
eststo model2: reg founders_fut4 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, robust
eststo model3: reg spinoutsdffv_fut4 xrd_fd std_tobin_q_assets std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, robust
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_noFE.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(xrd std_tobin_q_assets std_at std_emp std_patentcount_cw_cumulative)
estfe model*, restore
eststo clear

eststo model1: reg spinouts_fut4_fd xrd_fd std_tobin_q_assets_fd tobin_q_fd std_at_fd salesfd ch_fd assettang_fd roa_fd std_emp_fd std_patentcount_cw_cumulative_fd, robust
eststo model1: reg founders_fut4_fd xrd_fd std_tobin_q_assets_fd tobin_q_fd std_at_fd salesfd ch_fd assettang_fd roa_fd std_emp_fd std_patentcount_cw_cumulative_fd, robust
eststo model1: reg spinoutsdffv_fut4_fd xrd_fd std_tobin_q_assets_fd tobin_q_fd std_at_fd salesfd ch_fd assettang_fd roa_fd std_emp_fd std_patentcount_cw_cumulative_fd, robust
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_fd_noFE.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(xrd_fd std_tobin_q_assets_fd std_at_fd std_emp_fd std_patentcount_cw_cumulative_fd)
estfe model*, restore
eststo clear

eststo model1: reghdfe spinouts_fut5 xrd std_tobin_q_assets tobin_q std_at salesfd ch ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe founders_fut5 xrd std_tobin_q_assets tobin_q std_at salesfd ch ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinoutsdffv_fut5 xrd std_tobin_q_assets std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_FE.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(xrd std_tobin_q_assets std_at std_emp std_patentcount_cw_cumulative)
estfe model*, restore
eststo clear

eststo model1: reghdfe spinouts_fut5 xrd_fd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe founders_fut5 xrd_fd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinoutsdffv_fut5 xrd_fd std_tobin_q_assets std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_fd_FE.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(xrd_fd std_tobin_q_assets std_at std_emp std_patentcount_cw_cumulative)
estfe model*, restore
eststo clear


eststo model1: reg spinoutCountWeighted l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd, robust
eststo model2: reg spinoutCountWeighted l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, robust
eststo model3: reghdfe spinoutCountWeighted l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/regs_spinouts_accounting_lags.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets std_at std_emp std_patentcount_cw_cumulative)
estfe model*, restore
eststo clear

eststo model1: reg spinouts_wso4 l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd, robust
eststo model2: reg spinouts_wso4 l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, robust
eststo model3: reghdfe spinouts_wso4 l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/regs_spinouts_wso4_accounting_lags.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets std_at std_emp std_patentcount_cw_cumulative)
estfe model*, restore
eststo clear



reghdfe spinouts_wso4 f1.xrd xrd l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
reghdfe spinouts_wso4 f1.xrd xrd l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
reghdfe spinouts_wso4 f1.xrd xrd l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
reg spinouts_wso4 f1.xrd xrd l1.xrd l2.xrd l3.xrd l4.xrd l5.xrd, robust



reghdfe spinoutCountWeighted f1.xrd xrd l1.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)

* Estimates for accounting for spinouts
eststo model1: reghdfe f1.spinoutCountWeighted xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe f2.spinoutCountWeighted xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe f3.spinoutCountWeighted xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model4: reghdfe f4.spinoutCountWeighted xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model5: reghdfe f5.spinoutCountWeighted xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model6: reghdfe f6.spinoutCountWeighted xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model7: reghdfe f7.spinoutCountWeighted xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
*estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/regs_spinouts_accounting.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("t+1" "t+2" "t+3" "t+4" "t+5" "t+6" "t+7") keep(xrd)
estfe model*, restore
eststo clear

eststo model1: reghdfe f1.spinouts_wso4 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe f2.spinouts_wso4 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe f3.spinouts_wso4 xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model4: reghdfe f4.spinouts_wso4 xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model5: reghdfe f5.spinouts_wso4 xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model6: reghdfe f6.spinouts_wso4 xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model7: reghdfe f7.spinouts_wso4 xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
*estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/regs_spinouts_wso4_accounting.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("t+1" "t+2" "t+3" "t+4" "t+5" "t+6" "t+7") keep(xrd)
estfe model*, restore
eststo clear


eststo model1: reghdfe f1.spinoutCountWeighted xrd l1.xrd l2.xrd l3.xrd l4.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe f1.Spinouts xrd l1.xrd l2.xrd l3.xrd l4.xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe f1.SpinoutsDFFV xrd l1.xrd l2.xrd l3.xrd l4.xrd std_tobin_q_assets std_at salesfd ch assettang roa ppent ni std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/regs_accounting.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(xrd xrd_lag xrd_lag2)
estfe model*, restore
eststo clear

* Normalized by assets (for better fixed effects control)

eststo model1: reghdfe spinouts_fut4_at xrd_at tobin_q salesgrowth ch_at assettang roa patentcount_cw_cumulative_at, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
eststo model2: reghdfe founders_fut4_at xrd_at tobin_q salesgrowth ch_at assettang roa patentcount_cw_cumulative_at, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
eststo model3: reghdfe spinoutsdffv_fut4_at xrd_at tobin_q salesgrowth ch_at assettang roa patentcount_cw_cumulative_at, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_assetNormalized.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(xrd_at patentcount_cw_cumulative_at)
estfe model*, restore
eststo clear

* Poisson 

gen lxrd_lag1 = log(xrd_lag1)

gen lemp = log(emp)

xtpoisson spinoutCountWeighted lxrd_lag1 tobin_q lsalesfd lat lemp i.age, fe vce(robust)
eststo model2: reghdfe Spinouts xrd_lag1 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
eststo model3: reghdfe SpinoutsDFFV xrd_lag1 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear

* Log regressions (like in Babina and Howell)



reghdfe founders_fut4 lxrd, absorb(gvkey naics4#year stateCode#year) cluster(gvkey)

eststo model1: reghdfe spinouts_fut4 lxrd ltobin_q salesgrowth lat lch assettang lebitda roa lemp lpatentcount_cw_cumulative, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
eststo model2: reghdfe founders_fut4 lxrd ltobin_q salesgrowth lat lch assettang lebitda roa lemp lpatentcount_cw_cumulative, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
eststo model3: reghdfe spinoutsdffv_fut4 lxrd ltobin_q salesgrowth lat lch assettang lebitda roa lemp lpatentcount_cw_cumulative, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_logs.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(lxrd lat lemp lpatentcount_cw_cumulative)
estfe model*, restore
eststo clear

eststo model1: reghdfe spinouts_fut4 lxrd ltobin_q salesgrowth lat ch assettang ebitda roa emp patentcount_cw_cumulative, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
eststo model2: reghdfe founders_fut4 lxrd ltobin_q salesgrowth lat ch assettang ebitda roa emp patentcount_cw_cumulative, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
eststo model3: reghdfe spinoutsdffv_fut4 lxrd ltobin_q salesgrowth lat ch assettang ebitda roa lemp lpatentcount_cw_cumulative, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_logs_babinaHowell.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(lxrd lat emp patentcount_cw_cumulative)
estfe model*, restore
eststo clear



* IV regressions (like in Babina and Howell)
gen firm_dum = lfirm == 0
reghdfe lxrd lfirm firm_dum lstate roa salesgrowth ltobin_q lat ch assettang age, absorb(gvkey stateCode#year naics4#year, savefe) cluster(gvkey) resid
predict hxrd, xbd

reg lxrd lfirm lstate, robust
reg lxrd lfirm_bloom lstate_bloom, robust
reghdfe lxrd lfirm_bloom lstate_bloom, absorb(gvkey) cluster(gvkey)

gen founders_fut4_emp = founders_fut4 / emp

eststo model1: ivreghdfe spinouts_fut4 ltobin_q salesgrowth lat lch assettang ebitda roa emp (lxrd = lfirm_bloom lstate_bloom), absorb(gvkey naics3#year stateCode#year) cluster(gvkey)
eststo model2: ivreghdfe founders_fut4 ltobin_q salesgrowth lat lch assettang ebitda roa emp (lxrd = lfirm_bloom lstate_bloom), absorb(gvkey age naics3#year stateCode#year) cluster(stateCode)
eststo model3: ivreghdfe spinoutsdffv_fut4 ltobin_q salesgrowth lat lch assettang ebitda roa emp (lxrd = lfirm_bloom lstate_bloom), absorb(gvkey age naics3#year stateCode#year) cluster(stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics3#year "NAICS3-Year FE"  naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_logs_IV.tex, replace se stats(r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation") keep(lxrd lat emp patentcount_cw_cumulative)
estfe model*, restore
eststo clear

* Placebo regressions

eststo model0: reg spinoutcount_l1 xrd emp patentcount_cw_cumulative, robust
eststo model1: reghdfe spinoutcount_l1 xrd emp patentcount_cw_cumulative, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe spinoutcountunweighted_l1 xrd emp patentcount_cw_cumulative, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinoutdffv_l1 xrd emp patentcount_cw_cumulative, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_placebo1.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("Counts" "Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear


eststo model0: reg spinoutcount_l2 xrd emp_lag1 revt act, robust
eststo model1: reghdfe spinoutcount_l2 xrd emp_lag1 revt act, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe spinoutcountunweighted_l2 xrd emp_lag1 revt act, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinoutdffv_l2 xrd emp_lag1 revt act, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_placebo2.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("Counts" "Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear

eststo model0: reg spinoutcount_l3 xrd emp_lag1 revt act, robust
eststo model1: reghdfe spinoutcount_l3 xrd emp_lag1 revt act, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe spinoutcountunweighted_l3 xrd emp_lag1 revt act, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinoutdffv_l3 xrd emp_lag1 revt act, absorb(gvkey stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/presentationRegressions_placebo3.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("Counts" "Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear

**********************
**** Evaluating the efect of Non-compete Agreemtn enforcement policy changes due to court rulings
**********************

* Regression of R&D on firm-specific non-compete enforcement changes

reg lxrd ltobin_q lat fw_pre3 fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3, robust
coefplot, keep(fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3) vertical

* Fixed effects and clustering

label variable fw_pre4 "-4"
label variable fw_pre3 "-3"
label variable fw_pre2 "-2"
label variable fw_pre1 "-1"
label variable fw_post0 "0"
label variable fw_post1 "1"
label variable fw_post2 "2"
label variable fw_post3 "3"
label variable fw_post4 "4"

reghdfe lxrd fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode)
matrix list e(V)
test (1/2) * (fw_pre1 + fw_pre2) = (1/4) * (fw_post1 + fw_post2 + fw_post3)
coefplot, keep(fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3) vertical
graph export "../writings/figures/shiftShareDiffInDiff.png", replace

reghdfe lxrd lat roa assettang lch salesgrowth fw_pre1 fw_post0 fw_post1 fw_post2, absorb(gvkey age naics4#year) cluster(stateCode)
coefplot, keep(fw_pre1 fw_post0 fw_post1 fw_post2) vertical
test (1/1) * (fw_pre1 ) = (1/2) * (fw_post1 + fw_post2)
graph export "../writings/figures/shiftShareDiffInDiff.png", replace


reghdfe lxrd tobin_q lat lch assettang roa lemp fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3, absorb(gvkey year) cluster(stateCode)
coefplot, keep(fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2 fw_post3) vertical

gen lcapxv = log(capxv)
gen lcapx = log(capx)

reghdfe lcapxv fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2, absorb(gvkey naics4#year stateCode#year) cluster(gvkey)
reghdfe lcapx fw_pre2 fw_pre1 fw_post0 fw_post1 fw_post2, absorb(gvkey naics4#year stateCode#year) cluster(gvkey)

* My specification

gen xrd_tre_pre = xrd * (treatedpre3 + treatedpre2 + treatedpre1)
gen xrd_tre_post = xrd * (treatedpost0 + treatedpost1 + treatedpost2 + treatedpost3)

gen xrd_ncc = xrd * ncc_avg

eststo model1: reghdfe spinouts_fut2 xrd xrd_tre_pre_3 xrd_tre_pre_2 xrd_tre_pre_1 xrd_tre_post_0 xrd_tre_post_1 xrd_tre_post_2 xrd_tre_post_3 tobin_q_assets at salesfd ch assettang roa emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode)
coefplot, keep(xrd_tre_pre_3 xrd_tre_pre_2 xrd_tre_pre_1 xrd_tre_post_0 xrd_tre_post_1 xrd_tre_post_2 xrd_tre_post_3) vertical
eststo model2: reghdfe founders_fut2 xrd xrd_tre_pre_3 xrd_tre_pre_2 xrd_tre_pre_1 xrd_tre_post_0 xrd_tre_post_1 xrd_tre_post_2 xrd_tre_post_3 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
eststo model3: reghdfe spinoutsdffv_fut2 xrd xrd_tre_pre_3 xrd_tre_pre_2 xrd_tre_pre_1 xrd_tre_post_0 xrd_tre_post_1 xrd_tre_post_2 xrd_tre_post_3 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/noncompeteRegressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear

label variable xrd_fw_pre_3 "-3"
label variable xrd_fw_pre_2 "-2"
label variable xrd_fw_pre_1 "-1"
label variable xrd_fw_post_0 "0"
label variable xrd_fw_post_1 "1"
label variable xrd_fw_post_2 "2"
label variable xrd_fw_post_3 "3"

gen year2007_2008_2009 = 1 if year == 2007 | year == 2008 | year == 2009
gen year2010_2011_2012 = 1 if year == 2010 | year == 2011 | year == 2012
gen year2013_2014_2015 = 1 if year == 2013 | year == 2014 | year == 2015


gen xrd2007_2008_2009 = xrd * year2007_2008_2009
gen xrd2010_2011_2012 = xrd * year2010_2011_2012
gen xrd2013_2014_2015 = xrd * year2013_2014_2015


eststo model1: reghdfe spinouts_fut2 xrd xrd_fw_pre_2 xrd_fw_pre_1 xrd_fw_post_0 xrd_fw_post_1 xrd_fw_post_2 xrd_fw_post_3 tobin_q_assets at salesfd ch assettang roa emp, absorb(gvkey age naics4#year) cluster(stateCode)
test (1/2) * (xrd_fw_pre_1 + xrd_fw_pre_2) = (1/3) * (xrd_fw_post_1 + xrd_fw_post_2 + xrd_fw_post_3)
coefplot, keep(xrd_fw_pre_2 xrd_fw_pre_1 xrd_fw_post_0 xrd_fw_post_1 xrd_fw_post_2 xrd_fw_post_3) vertical
graph export "../writings/figures/shiftShareDiffInDiff_xrdEffect.png", replace

eststo model2: reghdfe founders_fut2 xrd xrd_fw_pre_2 xrd_fw_pre_1 xrd_fw_post_0 xrd_fw_post_1 xrd_fw_post_2 xrd_fw_post_3 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
coefplot, keep(xrd_fw_pre_2 xrd_fw_pre_1 xrd_fw_post_0 xrd_fw_post_1 xrd_fw_post_2 xrd_fw_post_3) vertical
test (1/2) * (xrd_fw_pre_1 + xrd_fw_pre_2) = (1/3) * (xrd_fw_post_1 + xrd_fw_post_2 + xrd_fw_post_3)

eststo model3: reghdfe spinoutsdffv_fut2 xrd xrd_fw_pre_3 xrd_fw_pre_2 xrd_fw_pre_1 xrd_fw_post_0 xrd_fw_post_1 xrd_fw_post_2 xrd_fw_post_3 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/noncompeteRegressions_fw.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear


* With Babina and Howell controls...

reghdfe spinouts_fut4 xrd xrd_ncc ltobin_q salesgrowth at ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe founders_fut4 xrd xrd_ncc ltobin_q salesgrowth at ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe spinoutsdffv_fut4 xrd xrd_ncc ltobin_q salesgrowth at ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)

reghdfe spinouts_fut4 xrd xrd_tre_pre xrd_tre_post ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe founders_fut4 xrd xrd_tre_pre xrd_tre_post ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe spinoutsdffv_fut4 xrd xrd_tre_pre xrd_tre_post ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)

* Babina and howell specification

gen lxrd_tre_pre_3 = lxrd * treatedpre3
gen lxrd_tre_pre_2 = lxrd * treatedpre2
gen lxrd_tre_pre_1 = lxrd * treatedpre1
gen lxrd_tre_post_0 = lxrd * treatedpost0
gen lxrd_tre_post_1 = lxrd * treatedpost1
gen lxrd_tre_post_2 = lxrd * treatedpost2
gen lxrd_tre_post_3 = lxrd * treatedpost3

gen lxrd_tre_pre = lxrd * (treatedpre3 + treatedpre2 + treatedpre1)
gen lxrd_tre_post = lxrd * (treatedpost0 + treatedpost1 + treatedpost2 + treatedpost3)

gen xrd_ncc = xrd * ncc_avg

reghdfe founders_fut4 lxrd lxrd_ncc ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)

reghdfe spinouts_fut4 lxrd lxrd_tre_pre_3 lxrd_tre_pre_2 lxrd_tre_pre_1 lxrd_tre_post_0 lxrd_tre_post_1 lxrd_tre_post_2 lxrd_tre_post_3 ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe founders_fut4 lxrd lxrd_tre_pre_3 lxrd_tre_pre_2 lxrd_tre_pre_1 lxrd_tre_post_0 lxrd_tre_post_1 lxrd_tre_post_2 lxrd_tre_post_3 ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe spinoutsdffv_lead4 lxrd lxrd_tre_pre_3 lxrd_tre_pre_2 lxrd_tre_pre_1 lxrd_tre_post_0 lxrd_tre_post_1 lxrd_tre_post_2 lxrd_tre_post_3 ltobin_q salesgrowth lat lch assettang, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)

reghdfe spinouts_fut4 lxrd lxrd_tre_pre lxrd_tre_post ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe founders_fut4 lxrd lxrd_tre_pre lxrd_tre_post ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)
reghdfe spinoutsdffv_fut4 lxrd lxrd_tre_pre lxrd_tre_post ltobin_q salesgrowth lat ch assettang ebitda roa, absorb(gvkey age naics4#year stateCode#year) cluster(gvkey)

* placebo


eststo model1: reghdfe spinoutCountWeighted xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
eststo model2: reghdfe Spinouts xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
eststo model3: reghdfe SpinoutsDFFV xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age stateCode#year naics4#year) cluster(stateCode naics4)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-Year FE")
esttab model* using tables/noncompeteRegressions_placebo.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("Counts" "Founder counts" "Valuation")
estfe model*, restore
eststo clear




*************
* WSO vs non WSO regressions

eststo model0: reghdfe spinouts_fut2 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model1: reghdfe spinouts_wso1_fut2 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe spinouts_wso2_fut2 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinouts_wso3_fut2 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model4: reghdfe spinouts_wso4_fut2 xrd std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/spinoutCounts_regressions.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4") keep(xrd std_tobin_q_assets std_at std_emp std_patentcount_cw_cumulative)
estfe model*, restore
eststo clear




** lags for accounting

eststo model0: reghdfe spinouts_fut4 xrd xrd_lag xrd_lag2 xrd_lag3 xrd_lag4 std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model1: reghdfe spinouts_wso1_fut4 xrd xrd_lag xrd_lag2 xrd_lag3 xrd_lag4 std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model2: reghdfe spinouts_wso2_fut4 xrd xrd_lag xrd_lag2 xrd_lag3 xrd_lag4 std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model3: reghdfe spinouts_wso3_fut4 xrd xrd_lag xrd_lag2 xrd_lag3 xrd_lag4 std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
eststo model4: reghdfe spinouts_wso4_fut4 xrd xrd_lag xrd_lag2 xrd_lag3 xrd_lag4 std_tobin_q_assets tobin_q std_at salesfd ch assettang roa std_emp std_patentcount_cw_cumulative, absorb(gvkey age stateCode#year naics4#year) cluster(gvkey)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/spinoutCounts_regressions_accounting.tex, replace se stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4") keep(xrd xrd_lag xrd_lag2 xrd_lag3 xrd_lag4 )
estfe model*, restore
eststo clear




eststo model0: reghdfe Spinouts tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model1: reghdfe spinoutsunweighted_wso1 xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: reghdfe spinoutsunweighted_wso2 xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: reghdfe spinoutsunweighted_wso3 xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: reghdfe spinoutsunweighted_wso4 xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model5: reghdfe spinoutsunweighted_wso5 xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model6: reghdfe spinoutsunweighted_wso6 xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/founderCounts_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4" "naics5" "naics6")
estfe model*, restore
eststo clear

eststo model0: reghdfe SpinoutsDFFV tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model1: reghdfe spinoutsdffv_wso1 tobin_q xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: reghdfe spinoutsdffv_wso2 tobin_q xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: reghdfe spinoutsdffv_wso3 tobin_q xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: reghdfe spinoutsdffv_wso4 tobin_q xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model5: reghdfe spinoutsdffv_wso5 tobin_q xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model6: reghdfe spinoutsdffv_wso6 tobin_q xrd_lag1 xrd_tre_pre_3_l1 xrd_tre_pre_2_l1 xrd_tre_pre_1_l1 xrd_tre_post_0_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/spinoutDFFV_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4" "naics5" "naics6")
estfe model*, restore
eststo clear

 ** zoom in: wso4 vs nonwso4

eststo model0: reghdfe spinouts_wso4 xrd_lag1 xrd_tre_pre_1_l1 xrd_tre_pre_2_l1 xrd_tre_pre_3_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model1: reghdfe spinouts_nonwso4 xrd_lag1 xrd_tre_pre_1_l1 xrd_tre_pre_2_l1 xrd_tre_pre_3_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: reghdfe spinoutsunweighted_wso4 xrd_lag1 xrd_tre_pre_1_l1 xrd_tre_pre_2_l1 xrd_tre_pre_3_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: reghdfe spinoutsunweighted_nonwso4 xrd_lag1 xrd_tre_pre_1_l1 xrd_tre_pre_2_l1 xrd_tre_pre_3_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: reghdfe spinoutsdffv_wso4 xrd_lag1 xrd_tre_pre_1_l1 xrd_tre_pre_2_l1 xrd_tre_pre_3_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model5: reghdfe spinoutsdffv_nonwso4 xrd_lag1 xrd_tre_pre_1_l1 xrd_tre_pre_2_l1 xrd_tre_pre_3_l1 xrd_tre_post_1_l1 xrd_tre_post_2_l1 xrd_tre_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/naics4_nonnaics4_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("naics4 counts" "non-naics4 counts" "naics4 founders" "non-naics4 founders" "naics4 valuation" "non-naics4 valuation")
estfe model*, restore
eststo clear

*Placebo WSO vs non-WSO regressions

eststo model0: reghdfe spinoutCountWeighted xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model1: reghdfe spinouts_wso1 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: reghdfe spinouts_wso2 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: reghdfe spinouts_wso3 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: reghdfe spinouts_wso4 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model5: reghdfe spinouts_wso5 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model6: reghdfe spinouts_wso6 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/spinoutCounts_regressions_placebo.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4" "naics5" "naics6")
estfe model*, restore
eststo clear


eststo model0: reghdfe Spinouts tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model1: reghdfe spinoutsunweighted_wso1 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: reghdfe spinoutsunweighted_wso2 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: reghdfe spinoutsunweighted_wso3 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: reghdfe spinoutsunweighted_wso4 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model5: reghdfe spinoutsunweighted_wso5 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model6: reghdfe spinoutsunweighted_wso6 xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/founderCounts_regressions_placebo.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4" "naics5" "naics6")
estfe model*, restore
eststo clear

eststo model0: reghdfe SpinoutsDFFV tobin_q salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model1: reghdfe spinoutsdffv_wso1 tobin_q xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model2: reghdfe spinoutsdffv_wso2 tobin_q xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model3: reghdfe spinoutsdffv_wso3 tobin_q xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model4: reghdfe spinoutsdffv_wso4 tobin_q xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model5: reghdfe spinoutsdffv_wso5 tobin_q xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
eststo model6: reghdfe spinoutsdffv_wso6 tobin_q xrd_lag1 xrd_plac_pre_3_l1 xrd_plac_pre_2_l1 xrd_plac_pre_1_l1 xrd_plac_post_0_l1 xrd_plac_post_1_l1 xrd_plac_post_2_l1 xrd_plac_post_3_l1 salesfd at emp, absorb(gvkey age naics4#year stateCode#year) cluster(naics4 stateCode)
estfe model*, labels(gvkey "Parent Firm FE" age "Parent Firm Age FE" naics4#year "NAICS4-Year FE" stateCode#year "State-year FE")
esttab model* using tables/spinoutDFFV_regressions_placebo.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mtitles("all" "naics1" "naics2" "naics3" "naics4" "naics5" "naics6")
estfe model*, restore
eststo clear

*** Effect of non-compete policy on investment and R&D



** First, I replicate Jeffers' regressions

eststo model1: reghdfe investmentrate treatedpost, absorb(gvkey naics4#year) cluster(stateCode)
eststo model2: reghdfe xrdrate treatedpost, absorb(gvkey naics4#year) cluster(stateCode)
estfe model*, labels(gvkey "Parent Firm FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/investment_noncompetepolicy_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("Capex rate (I/K)" "R&D rate (xrd / K)")
estfe model*, restore
eststo clear








*** Spinout counts: all types

eststo model1: quietly reghdfe Spinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd xrdCalif xrdMass emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(naics4 stateCode)
*eststo model3: quietly xtnbreg Spinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe  
eststo model3: quietly poisson Spinouts xrd xrdCalif xrdMass emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.naics4 i.year, robust
eststo model4: quietly xtpoisson Spinouts xrd xrdCalif xrdMass emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe model*, labels(gvkey "Parent Firm FE" year "Year FE")
esttab model* using tables/all_spinoutCount_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "OLS (FE) with indicators" "negative binomial FE" "Poisson FE") keep(xrd xrdCalif xrdMass emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
*estfe model*, restore
eststo clear

*** Eventually exiting spinouts only

eststo model1: quietly reghdfe ExitingSpinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model2: quietly xtnbreg ExitingSpinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe  
*eststo model3: quietly poisson ExitingSpinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4, robust
eststo model4: quietly xtpoisson ExitingSpinouts xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe . model*, labels(gvkey "Parent Firm FE" year "Year FE")
esttab model* using tables/all_exitingSpinoutCount_regressions.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(xrd emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
*estfe . model*, restore
eststo clear


*** Spinouts DEV

eststo model1: quietly reg SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, robust
eststo model2: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(stateCode#year naics4#year) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE" year "Year FE" gvkey "Parent Firm FE")
esttab model* using tables/spinoutsDEV_firm-naicsyear.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear



*** Effect of CNC enforcement on R&D - spinout relationship



eststo model1: quietly reghdfe Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(stateCode)
eststo model2: quietly nbreg Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4
eststo model3: quietly poisson Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4, robust
eststo model4: quietly xtpoisson Spinouts xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/all_spinoutCount_regressions_JeffersCourtRulings.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
*estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(stateCode)
*eststo model2: quietly nbreg SpinoutsDEV xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4
*eststo model3: quietly poisson SpinoutsDEV xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4, robust
*eststo model4: quietly xtpoisson SpinoutsDEV xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, fe robust
*estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/all_spinoutDEV_regressions_JeffersCourtRulings.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS Spinouts DEV") keep(xrd xrdTimesTreatedPost emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
*estfe model*, restore
eststo clear

gen xrdTimesNCC_1991 = xrd * ncc_1991

eststo model1: quietly reghdfe Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3, absorb(gvkey naics4#year) cluster(stateCode)
*eststo model2: quietly nbreg Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4 i.year
*eststo model3: quietly poisson Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.stateCode i.naics4 i.year, robust
eststo model4: quietly xtpoisson Spinouts xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3 i.year, fe robust
*estfe model*, labels(naics4#year "NAICS4-Year FE")
esttab model* using tables/all_spinoutCount_regressions_NCC1991-Starr2018.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(xrd xrdTimesNCC_1991 emp patentcount_cw_cumulative patentapplicationcount_cw_ma3)
*estfe model*, restore
eststo clear


*** Effect of CNC enforcement on spinout generation

eststo model1: quietly reghdfe Spinouts treatedpost, absorb(gvkey naics4#year) cluster(stateCode)
*eststo model2: quietly xtnbreg Spinouts treatedpost i.naics4yearCode, fe  
*eststo model3: quietly poisson Spinouts treatedpost i.naics4yearCode, robust
*eststo model4: quietly xtpoisson Spinouts treatedpost i.naics4yearCode, fe robust
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/noPredictors_spinoutCount_regressions_JeffersCourtRulings.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') nonumbers mtitles("OLS (FE)" "Negative binomial FE" "Poisson" "Poisson FE") keep(treatedpost)
estfe model*, restore
eststo clear

 **** Headlines
 
eststo model1: quietly reghdfe Spinouts xrd emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model4: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode) 
eststo model5: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_cumulative emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE" year "Year FE" gvkey "Parent Firm FE")
esttab model* using tables/rawSpinoutCount_firmFE.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') 
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, absorb(gvkey naics4#year) cluster(naics4 stateCode) 
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 patentcount_cw_cumulative emp, absorb(gvkey naics4#year) cluster(naics4 stateCode)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE" year "Year FE" gvkey "Parent Firm FE")
esttab model* using tables/SpinoutDEV_allFixedEffects.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo: quietly xtnbreg Spinouts xrd emp, fe
eststo: quietly xtnbreg Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, fe 
eststo: quietly xtnbreg Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp i.naics4 i.stateCode i.year, fe
*eststo: quietly xtnbreg Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp, fe
*eststo: quietly xtnbreg Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, fe
esttab using tables/xtnbreg_rawSpinoutCount_firmFE.tex, replace se stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
*estfe model*, restore
eststo clear

eststo: quietly nbreg Spinouts xrd emp
eststo: quietly nbreg Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp
eststo: quietly nbreg Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp
eststo: quietly nbreg Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp
esttab using tables/nbreg_rawSpinoutCount_stateFE.tex, replace se stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none) keep(xrd emp patentcount_cw_cumulative patentcount_cw_ma3 patentapplicationcount_cw_ma3 patentapplicationcount_cw_ma5)
*estfe model*, restore
eststo clear

eststo: quietly xtpoisson Spinouts xrd emp, fe robust
eststo: quietly xtpoisson Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp, fe robust
eststo: quietly xtpoisson Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp, fe robust
eststo: quietly xtpoisson Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp, fe robust
esttab using tables/xtpoisson_rawSpinoutCount_firmFE.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
*estfe model*, restore
eststo clear

eststo: quietly poisson Spinouts xrd emp i.stateCode, robust
eststo: quietly poisson Spinouts xrd patentcount_cw_cumulative patentapplicationcount_cw_ma5 emp i.stateCode, robust
eststo: quietly poisson Spinouts xrd patentcount_cw_ma3 patentapplicationcount_cw_ma3 emp i.stateCode, robust
eststo: quietly poisson Spinouts xrd_ma3 patentcount_cw_cumulative patentapplicationcount_cw_ma3 emp i.stateCode, robust
esttab using tables/poisson_rawSpinoutCount_stateFE.tex, replace se stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none) keep(xrd emp patentcount_cw_cumulative patentcount_cw_ma3 patentapplicationcount_cw_ma3 patentapplicationcount_cw_ma5)
*estfe model*, restore
eststo clear




 
 
 
 
 ** others
 
 
 
 

eststo: quietly reg Spinouts xrd
eststo: quietly reg Spinouts xrd emp
eststo: quietly reg Spinouts xrd_ma3 emp
eststo: quietly reg Spinouts xrd_ma5 emp
esttab using tables/OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly reg Spinouts patentapplicationcount emp
eststo: quietly reg Spinouts patentapplicationcount_cw emp
eststo: quietly reg Spinouts patentcount emp
eststo: quietly reg Spinouts patentcount_cw emp
esttab using tables/patents_OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly reg Spinouts xrd patentapplicationcount emp
eststo: quietly reg Spinouts xrd patentapplicationcount_cw emp
eststo: quietly reg Spinouts xrd patentcount emp
eststo: quietly reg Spinouts xrd patentcount_cw emp
esttab using tables/patents-xrd_OLS.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear


eststo: quietly reg SpinoutsDEV xrd
eststo: quietly reg SpinoutsDEV xrd emp
eststo: quietly reg SpinoutsDEV xrd_ma3 emp
eststo: quietly reg SpinoutsDEV xrd_ma5 emp
esttab using tables/OLS_discountedExitValue.tex, replace stats(r2 r2_a N) mlabels(none)
eststo clear

eststo: quietly logit spinoutIndicator xrd
eststo: quietly logit spinoutIndicator xrd emp
eststo: quietly logit spinoutIndicator xrd_ma3 emp
eststo: quietly logit spinoutIndicator xrd_ma5 emp
esttab using tables/logit.tex, replace stats(N) mlabels(none)
eststo clear

eststo: quietly logit exitSpinoutIndicator xrd
eststo: quietly logit exitSpinoutIndicator xrd emp
eststo: quietly logit exitSpinoutIndicator xrd_ma3 emp
eststo: quietly logit exitSpinoutIndicator xrd_ma5 emp
esttab using tables/logit_exitsOnly.tex, replace stats(N) mlabels(none)
eststo clear

eststo: quietly logit valuableSpinoutIndicator xrd
eststo: quietly logit valuableSpinoutIndicator xrd emp
eststo: quietly logit valuableSpinoutIndicator xrd_ma3 emp
eststo: quietly logit valuableSpinoutIndicator xrd_ma5 emp
esttab using tables/logit_valuableOnly.tex, replace stats(N) mlabels(none)
eststo clear

* Fixed effects

** Regular spinout count

eststo model1: quietly reghdfe Spinouts xrd emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
return list
esttab model* using tables/OLS_FE_industry2_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
return list
esttab model* using tables/OLS_FE_industry3_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_FE_industry4_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

** Discounted exit value of spinouts spawned in a given year

eststo model1: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
esttab model* using tables/OLS_DEV_FE_industry2_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/OLS_DEV_FE_industry3_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_DEV_FE_industry4_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Fixed effects with xrd_ma3

eststo model1: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
return list
esttab model* using tables/OLS_XRDMA3_FE_industry2_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
return list
esttab model* using tables/OLS_XRDMA3_FE_industry3_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe Spinouts xrd_ma3 emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_XRDMA3_FE_industry4_age_time.tex, replace stats(clustvar r2_a r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics2#year) cluster(naics3)
estfe model*, labels(naics2 "NAICS2 FE" year "Year FE" naics2#year "NAICS2-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry2_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics3#year) cluster(naics3)
estfe model*, labels(naics3 "NAICS3 FE" year "Year FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry3_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4 year) cluster(gvkey)
eststo model2: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4 year) cluster(naics4)
eststo model3: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4 year) cluster(naics3)
eststo model4: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4#year) cluster(gvkey)
eststo model5: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4#year) cluster(naics4)
eststo model6: quietly reghdfe SpinoutsDEV xrd_ma3 emp, absorb(naics4#year) cluster(naics3)
estfe model*, labels(naics4 "NAICS4 FE" year "Year FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/OLS_XRDMA3_DEV_FE_industry4_age_time.tex, replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Patent data

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw emp, absorb(naics3#year stateCode) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics3#year "NAICS3-Year FE")
esttab model* using tables/patents-xrd_OLS_FE_industry3.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw emp, absorb(naics4#year stateCode) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patents-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd_ma3 patentapplicationcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd_ma3 patentapplicationcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model3: quietly reghdfe Spinouts xrd_ma3 patentcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model4: quietly reghdfe Spinouts xrd_ma3 patentcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patentsma3-xrdma3_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentapplicationcount_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model2: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentapplicationcount_cw_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentcount_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV  emp xrd_ma3 patentcount_cw_ma3, absorb(naics4#year stateCode) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patentsma3-xrdma3_OLS_DEV_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
*esttab model*, stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear


eststo model1: quietly reghdfe SpinoutsDEV xrd patentapplicationcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patents-xrd_OLS_DEV_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patents-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(gvkey stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patentsma3-xrd_OLS_DEV_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe Spinouts xrd patentapplicationcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model2: quietly reghdfe Spinouts xrd patentapplicationcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model3: quietly reghdfe Spinouts xrd patentcount_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
eststo model4: quietly reghdfe Spinouts xrd patentcount_cw_ma3 emp, absorb(naics4#year stateCode) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4#year "NAICS4-Year FE")
esttab model* using tables/patentsma3-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

eststo model1: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
eststo model2: quietly reghdfe SpinoutsDEV xrd patentapplicationcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
eststo model3: quietly reghdfe SpinoutsDEV xrd patentcount_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
eststo model4: quietly reghdfe SpinoutsDEV xrd patentcount_cw_ma3 emp, absorb(naics4 stateCode year) cluster(naics4 stateCode)
estfe model*, labels(stateCode "State FE" naics4 "NAICS4 FE" year "Year FE")
esttab model* using tables/patentsma3-xrd_OLS_FE_industry4.tex, replace stats(r2 r2_a_within N)  indicate(`r(indicate_fe)') mlabels(none)
estfe model*, restore
eststo clear

* Regressions for Wharton Innovation Conference Research Proposal

eststo model1: reghdfe Spinouts xrd patentapplicationcount_cw patentcount_cw_ma3 emp, absorb(naics4#year stateCode#year) cluster(gvkey naics4#year stateCode#year)
eststo model2: reghdfe SpinoutsDEV xrd patentapplicationcount_cw patentcount_cw_ma3 emp, absorb(naics4#year stateCode#year) cluster(gvkey naics4#year stateCode#year)
estfe model*, labels(stateCode#year "State-Year FE" naics4#year "NAICS4-Year FE")
*esttab model* using "../writings/wharton innovation conference/preliminary_results.tex", replace stats(clustvar r2 r2_a_within N)  indicate(`r(indicate_fe)')
esttab model*, stats(clustvar r2_a_within N)  indicate(`r(indicate_fe)')
estfe model*, restore
eststo clear









