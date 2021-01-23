***************************************
*		Dataset Probability
*
*
****************************************

///////////////////////////////////////
/////		Cites
///////////////////////////////////////

use "$rawdata/uscites2020.dta", clear

*----Citing
merge m:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop if _m==2
drop _merge

merge m:1 patent using "$datasets/ipc3_for_cit.dta", gen(ay_merge2)
drop if ay_merge2==2
drop ay_merge

gen ipc1_citing=substr(ipc3,1,1)
drop ipc3 gyear appdate

rename patent citing
rename appyear citing_appyear

*----Cited
rename cited patent

merge m:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop if _m==2
drop _m

merge m:1 patent using "$datasets/ipc3_for_cit.dta", gen(ay_merge2)
drop if ay_merge2==2
drop ay_merge2

gen ipc1_cited=substr(ipc3,1,1)
drop ipc3 gyear appdate

rename appyear cited_appyear
rename patent cited

order citing cited citing_appyear cited_appyear

sort cited cited_appyear

*label variables
label var citing "Citing Patent"
label var cited  "Cited Patent"
label var citing_appyear  "Citing Patent Application Year"
label var cited_appyear  "Cited Patent Application Year"
label var ipc1_citing  "IPC Citing"
label var ipc1_cited  "IPC Cited"

*patent age
gen cit_pat_age=citing_appyear-cited_appyear

drop if citing=="" | cited==""

*Fix Patent Age
count if cit_pat_age<0
count if cit_pat_age>114 & cit_pat_age!=.
replace cit_pat_age=0 if cit_pat_age<0
replace cit_pat_age=114 if cit_pat_age>114 & cit_pat_age!=.

tab cit_pat_age, m

bys cit_pat_age ipc1_cited cited_appyear: gen num=_N

*Dejar Panel nivel de citada, cada posible lag (0,114)
duplicates drop cit_pat_age ipc1_cited cited_appyear, force

sort ipc1_cited cit_pat_age cited_appyear
drop citing cited ipc1_citing citing_appyear

drop if ipc1_cited==""

order ipc1_cited cited_appyear cit_pat_age num den pr_cite_ipc_appyear

label var num "#cites at lag s to patents applied for at t in field j"

*save data

save "$datasets/cits_lag_app_field.dta", replace

///////////////////////////////////////
/////	Number of Patents
///////////////////////////////////////

use  "$datasets/patents_uspto_for_cit.dta", clear

merge 1:1 patent using "$datasets/ipc3_for_cit.dta", gen(ay_merge2)
drop if ay_merge2==2
drop ay_merge
gen ipc1=substr(ipc3,1,1)
drop ipc3 gyear appdate

bys ipc1 appyear: gen no_pats=_N

drop if ipc1==""

duplicates drop ipc1 appyear, force

drop patent

save "$datasets/no_pats_ipc_appyear.dta", replace

///////////////////////////////////////
/////	Merge Cites and Number of Patents
///////////////////////////////////////

use "$datasets/cits_lag_app_field_all_lags.dta", clear

rename cited_appyear appyear
rename ipc1_cited ipc1
sort ipc1 appyear cit_pat_age num 

merge m:1 ipc1 appyear using "$datasets/no_pats_ipc_appyear.dta", gen(merge_yrs)

keep if merge_yrs==3
drop merge_yrs

gen prob=num/no_pats


sort ipc1 appyear 
gsort cit_pat_age


label var num "#cites at lag s to patents applied for at t in field j"
label var no_pats "# patents applied for at t in field j"



keep  if appyear>=1975 & appyear<=2015
keep if cit_pat_age<=40

sort ipc1 appyear cit_pat_age
order ipc1 appyear cit_pat_age num 

gen log_prob=ln(prob)

egen ipc=group(ipc1)

tabulate ipc, generate(dipc)
replace 

tabulate appyear, generate(dappyear)

nl (prob = {b0=0}*{b0=0}(1 - exp(-1*{b1=0}*x)))

save "$datasets/prob_lag_ipc_appyear.dta", replace

///////////////////////////////////////
/////	Probability Dataset
///////////////////////////////////////

use "$datasets/prob_lag_ipc_appyear.dta", clear

gen citing_appyear=appyear+cit_pat_age