*******************************************
*			Survival Figures
*
********************************************

set more off

**Saving options
global save_fig   1 //0 // 


graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots

*in surv folder in reports
global figfolder="$main/RA/reports/Fall of Generalists/Second Version/Survival/figures"
global tabfolder="$main/RA/reports/Fall of Generalists/Second Version/Survival/tables"

*Options of sample

*---------------------------------*
*		Turn on options
*---------------------------------*

global utility 0
global rare_any 0
global rare_all 0
global rare_mean 0

*assignee only organizations type 2 and 3
global org_asg 0


*---------------------------------*
*		Open Data
*----------------------------------*

*Open PatentsView
use "$datasets/Patentsview_Main.dta", clear

*Reduced Version
keep patent date appyear type_pat inventor_id invseq categ1 ipc3 asgnum type_asg assignee tsize d_asg_org identified_ipc rare_ipc3_any rare_ipc3_mean appdate


sort patent appyear
bys patent (invseq): gen invord=_n


gen ipc1=substr(ipc3,1,1)
drop ipc3

*count running patent by inventors (total patents foreach inventor)
bys categ1 (appdate): gen rpat2=_n

compress


*keep comparable samplw
keep if tsize>1

*------------------------------------*
*	Merge Dummies
*------------------------------------*

merge m:1 patent categ1 using "$datasets/survival_dummies_probability.dta", gen(m_dummy)

drop m_dummy

if $utility==1 {
local l_utility keep if type_pat==7
local ut_save_str _only_utility
`l_utility'
}

if $rare_any==1 {
local l_rare_any drop if rare_ipc3_any==1
local any_save_str _rare_any
`l_rare_any'
}

if $rare_all==1 {
local l_rare_all drop if rare_ipc3_all==1
local all_save_str _rare_all
`l_rare_all'

}

if $rare_mean==1 {
local l_rare_mean drop if rare_ipc3_mean==1
local mean_save_str _rare_mean
`l_rare_mean'
}

*all in one string
global gsave_str `lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'


*Compute initial year

////////////////////////////////////////
///	Compute JP Decile and Quintile
//////////////////////////////////////
bys categ1 (appyear) : egen iyear=min(appyear)

sort appyear pr_alo_coinv
gen dyear=1 if appyear[_n]~=appyear[_n-1]

preserve
keep assignee appyear date patent
keep if assignee~=0 & assignee~=.
duplicates drop patent, force
bys assignee (date): gen firmseq=_n
bys assignee appyear: egen minf=min(firmseq)
keep if minf==firmseq
duplicates drop assignee appyear, force
egen f10f= xtile(firmseq), by(appyear) nq(10)
keep assignee appyear f10f firmseq
save "$datasets/firmdecile_measure_by_firm.dta"
restore


preserve
keep assignee appyear date patent
duplicates drop patent, force
keep if assignee~=0 & assignee~=.
bys assignee (date): gen firmseq=_n
egen fsize= xtile(firmseq), by(appyear) nq(5)
save "$datasets/firmquintile_measure_by_firm.dta"
restore



compress
merge m:1 assignee appyear using "$datasets/firmdecile_measure_by_firm.dta", keepusing(f10f firmseq) gen(m1)
replace f10f=0 if assignee==0

merge m:1 assignee patent using "$datasets/firmquintile_measure_by_firm.dta", keepusing(fsize) gen(m2)

drop m1 m2 
*********************************************************************************
*					Probabilities												*
*																				*
********************************************************************************

*Probabilities

////////////////////////
///	ALO - Application Year
/////////////////////////

*1a) ALO Coinventor - By App Year
*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear: egen Ndrpat_inv2=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear : egen Ndrep_alo_coinv2=total(drep_alo_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv2=Ndrep_alo_coinv2/Ndrpat_inv2

////////////////////////
///	ALO - Initital Year
/////////////////////////


*1b) ALO Coinventor - by Initial Year
*count the number of inventors that have a next patent by appyear (pat-1)
bys iyear: egen iNdrpat_inv=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys iyear : egen iNdrep_alo_coinv=total(drep_alo_coinv)

*probability of at least one repeated coinventor
gen ipr_alo_coinv=iNdrep_alo_coinv/iNdrpat_inv


////////////////////////
///	ALL - Aggregate Measure
/////////////////////////

*2a) All Coinventors -by Appyear

*count the number of inventors that repeated coinventors in next patent
bys appyear : egen Ndrep_all_coinv2=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_all_coinv2=Ndrep_all_coinv2/Ndrpat_inv2 

////////////////////////
///	ALL - Initital Year
/////////////////////////


*2b) All Coinventors -by Initial Year

*count the number of inventors that repeated coinventors in next patent
bys iyear : egen iNdrep_all_coinv=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen ipr_all_coinv=iNdrep_all_coinv/iNdrpat_inv


*discrepancy since 2005?
bys categ1: egen max_rpat=max(rpat)
tab drep_alo_coinv if rpat==max_rpat
*If figures are ok, drep_alo_coinv in the last rpat should be zero.
drop max_rpat




////////////////////////////////////////////////
//	Figures by Agg Measure - Comparing Measures
/////////////////////////////////////////////////


*1) Alo Coinventor
{
preserve

collapse (mean) pr_alo_coinv pr_alo_coinv2, by(appyear)

*Probability repeat at least one coinventor
twoway (connected  pr_alo_coinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  pr_alo_coinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Probability (Aggregate)") label( 2 "Probability (Dummies)") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/pr_alo_coinv.pdf", replace as(pdf)
}

restore
}


*2) All Coinventors
{
preserve

collapse (mean) pr_all_coinv pr_all_coinv2, by(appyear)

*Probability repeat at least one coinventor
twoway (connected  pr_all_coinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  pr_all_coinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Probability (Aggregate)") label( 2 "Probability (Dummies)") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/pr_all_coinv.pdf", replace as(pdf)
}

restore
}

//////////////////////////
//	Figures by Initial Year
//////////////////////////


*1) Alo Coinventor

{
preserve

collapse (mean) ipr_alo_coinv, by(iyear)
tempfile alo_iyear
rename iyear year
save "`alo_iyear'", replace

restore

preserve

collapse (mean) pr_alo_coinv2, by(appyear)
rename appyear year
merge m:1 year using  "`alo_iyear'", gen(m1)

*Probability repeat at least one coinventor
twoway (connected  pr_alo_coinv2 year, lcolor(navy) lwidth(medthick)) ///
(connected  ipr_alo_coinv year, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "By Application Year") label( 2 "By Initial Year") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/pr_alo_coinv_by_appyear_iyear.pdf", replace as(pdf)
}

restore
}

*2) All Coinventors

{
preserve

collapse (mean) ipr_all_coinv, by(iyear)
tempfile all_iyear
rename iyear year
save "`all_iyear'", replace
restore

preserve

collapse (mean) pr_all_coinv2, by(appyear)
rename appyear year
merge m:1 year using  "`all_iyear'", gen(m1)

*Probability repeat at least one coinventor
twoway (connected  pr_all_coinv2 year, lcolor(navy) lwidth(medthick)) ///
(connected  ipr_all_coinv year, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "By Application Year") label( 2 "By Initial Year") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/pr_all_coinv_by_appyear_iyear.pdf", replace as(pdf)
}

restore
}


drop Ndrpat_inv2 Ndrep_alo_coinv2 pr_alo_coinv2 max_rpat iNdrpat_inv iNdrep_alo_coinv ipr_alo_coinv iNdrep_all_coinv ipr_all_coinv Ndrep_all_coinv2 pr_all_coinv2


//////////////////////////
////	By IPC
/////////////////////////

*1) ALO and All Coinventor IPC- By App Year

{
*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear ipc1: egen Ndrpat_inv_ipc=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear ipc1: egen Ndrep_alo_coinv_ipc=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys appyear ipc1: egen Ndrep_all_coinv_ipc=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv_ipc=Ndrep_alo_coinv_ipc/Ndrpat_inv_ipc

*probability of at least one repeated coinventor
gen pr_all_coinv_ipc=Ndrep_all_coinv_ipc/Ndrpat_inv_ipc

//////////////
/// graphs 
////////////

local t=0
global g pr_alo_coinv_ipc pr_all_coinv_ipc

foreach k of global g{
local ++t
preserve

collapse (mean) `k', by(appyear ipc1)

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected `k' appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

restore
}


}

*2) ALO and ALL Coinventor IPC - by Initial Year

{
*count the number of inventors that have a next patent by appyear (pat-1)
bys iyear ipc1: egen iNdrpat_inv_ipc=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys iyear ipc1 : egen iNdrep_alo_coinv_ipc=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys iyear ipc1 : egen iNdrep_all_coinv_ipc=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen ipr_alo_coinv_ipc=iNdrep_alo_coinv_ipc/iNdrpat_inv_ipc

*probability of at least one repeated coinventor
gen ipr_all_coinv_ipc=iNdrep_all_coinv_ipc/iNdrpat_inv_ipc


//////////////
/// graphs 
////////////

local t=0
global g ipr_alo_coinv_ipc ipr_all_coinv_ipc

foreach k of global g{

local ++t
preserve

collapse (mean) `k', by(iyear ipc1)

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected `k' iyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

restore
}

}

drop pr_alo_coinv_ipc pr_all_coinv_ipc ipr_alo_coinv_ipc ipr_all_coinv_ipc Ndrep_all_coinv_ipc Ndrep_alo_coinv_ipc Ndrpat_inv_ipc iNdrep_all_coinv_ipc iNdrep_alo_coinv_ipc iNdrpat_inv_ipc

//////////////////////////
////	by Team Size
/////////////////////////


*1) ALO and All Coinventor IPC- By App Year
{
*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear tsize2: egen Ndrpat_inv_tsize=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear tsize2: egen Ndrep_alo_coinv_tsize=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys appyear tsize2: egen Ndrep_all_coinv_tsize=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv_tsize=Ndrep_alo_coinv_tsize/Ndrpat_inv_tsize

*probability of all  coinventors
gen pr_all_coinv_tsize=Ndrep_all_coinv_tsize/Ndrpat_inv_tsize


preserve

collapse (mean) pr_alo_coinv_tsize pr_all_coinv_tsize, by(appyear tsize2)

local t=0
global g pr_alo_coinv_tsize pr_all_coinv_tsize

foreach k of global g{

local ++t

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}


twoway (connected  `k' appyear if tsize2==2, lwidth(medthick)) (connected  `k' appyear if tsize2==3, lwidth(medthick)) ///
(connected  `k' appyear if tsize2==4, lwidth(medthick)) (connected  `k' appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore

}

drop pr_alo_coinv_tsize pr_all_coinv_tsize Ndrpat_inv_tsize Ndrep_alo_coinv_tsize Ndrep_all_coinv_tsize

*2) ALO and ALL Coinventor IPC - by Initial Year

{
*count the number of inventors that have a next patent by appyear (pat-1)
bys iyear tsize2: egen iNdrpat_inv_tsize=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys iyear tsize2 : egen iNdrep_alo_coinv_tsize=total(drep_alo_coinv)

*count the number of inventors that repeated all coinventors in next patent
bys iyear tsize2 : egen iNdrep_all_coinv_tsize=total(drep_all_coinv)


*probability of at least one repeated coinventor
gen ipr_alo_coinv_tsize=iNdrep_alo_coinv_tsize/iNdrpat_inv_tsize

*probability of at least one repeated coinventor
gen ipr_all_coinv_tsize=iNdrep_all_coinv_tsize/iNdrpat_inv_tsize



preserve

collapse (mean) ipr_alo_coinv_tsize ipr_all_coinv_tsize, by(iyear tsize2)

local t=0
global g ipr_alo_coinv_tsize ipr_all_coinv_tsize

foreach k of global g{

local ++t

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}


twoway (connected  `k' iyear if tsize2==2, lwidth(medthick)) (connected  `k' iyear if tsize2==3, lwidth(medthick)) ///
(connected  `k' iyear if tsize2==4, lwidth(medthick)) (connected  `k' iyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initital Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore
}


drop ipr_alo_coinv_tsize ipr_all_coinv_tsize iNdrpat_inv_tsize iNdrep_alo_coinv_tsize iNdrep_all_coinv_tsize

//////////////////////////
////	by Asg. Groups
/////////////////////////

*Defining Groups
{
bys appyear asgnum: gen Npat_asg=_N
bys appyear asgnum: gen dasg_year=1 if asgnum[_n]!=asgnum[_n-1]


*Patenting by year
bys appyear: egen p90_pat=pctile(dasg_year*Npat_asg), p(90)
bys appyear: egen p99_pat=pctile(dasg_year*Npat_asg), p(99)

gen group=1 if Npat_asg<p90_pat
	replace group=2 if Npat_asg>=p90_pat & Npat_asg<p99_pat
	replace group=3 if Npat_asg>=p99_pat & Npat_asg!=.
	
label define lbl_g 1 "Below p90" 2 "[p90,p99]"  3 "Top 1%"

label values group lbl_g

}

*1) ALO and All Coinventor Group- By App Year
{
*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear group: egen Ndrpat_inv_group=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear group: egen Ndrep_alo_coinv_group=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys appyear group: egen Ndrep_all_coinv_group=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv_group=Ndrep_alo_coinv_group/Ndrpat_inv_group

*probability of all  coinventors
gen pr_all_coinv_group=Ndrep_all_coinv_group/Ndrpat_inv_group


preserve

collapse (mean) pr_alo_coinv_group pr_all_coinv_group, by(appyear group)

local t=0
global g pr_alo_coinv_group pr_all_coinv_group

foreach k of global g{

local ++t

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}


twoway (connected  `k' appyear if group==1, lwidth(medthick)) (connected  `k' appyear if group==2, lwidth(medthick)) ///
(connected  `k' appyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore

}

drop Ndrep_all_coinv_group Ndrep_alo_coinv_group Ndrpat_inv_group pr_all_coinv_group pr_alo_coinv_group

*2) ALO and ALL Coinventor Group - by Initial Year

{
*count the number of inventors that have a next patent by appyear (pat-1)
bys iyear group: egen iNdrpat_inv_group=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys iyear group: egen iNdrep_alo_coinv_group=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys iyear group: egen iNdrep_all_coinv_group=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen ipr_alo_coinv_group=iNdrep_alo_coinv_group/iNdrpat_inv_group

*probability of all  coinventors
gen ipr_all_coinv_group=iNdrep_all_coinv_group/iNdrpat_inv_group


preserve

collapse (mean) ipr_alo_coinv_group ipr_all_coinv_group, by(iyear group)

local t=0
global g ipr_alo_coinv_group ipr_all_coinv_grou

foreach k of global g{

local ++t

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}


twoway (connected  `k' iyear if group==1, lwidth(medthick)) (connected  `k' iyear if group==2, lwidth(medthick)) ///
(connected  `k' iyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}
}

drop iNdrep_all_coinv_group iNdrep_alo_coinv_group iNdrpat_inv_group ipr_all_coinv_group ipr_alo_coinv_group
cap drop Ndrep_all_coinv Ndrep_alo_coinv Ndrpat_inv Npat_asg Nrep_coinv


//////////////////////////
////	by Quintiles
/////////////////////////


*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear fsize: egen Ndrpat_inv_fsize=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear fsize: egen Ndrep_alo_coinv_fsize=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys appyear fsize: egen Ndrep_all_coinv_fsize=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv_fsize=Ndrep_alo_coinv_fsize/Ndrpat_inv_fsize

*probability of all  coinventors
gen pr_all_coinv_fsize=Ndrep_all_coinv_fsize/Ndrpat_inv_fsize

{
preserve

collapse (mean) pr_all_coinv_fsize pr_alo_coinv_fsize, by(appyear fsize)

local t=0
global g pr_all_coinv_fsize pr_alo_coinv_fsize

foreach k of global g{

local ++t

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}



twoway (connected  `k' appyear if fsize==1, lwidth(medthick)) ///
(connected   `k' appyear if fsize==2, lwidth(medthick)) ///
(connected   `k' appyear if fsize==3, lwidth(medthick)) ///
(connected   `k' appyear if fsize==4, lwidth(medthick)) ///
(connected   `k' appyear if fsize==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label( 1 "1st Quintile Firm Size" ) label( 2 "2nd Quintile") label( 3 "3rd Quintile") label( 4 "4th Quintile") label( 5 "5th Quintile") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore

}

drop Ndrpat_inv_fsize Ndrep_alo_coinv_fsize Ndrep_all_coinv_fsize Ndrep_alo_coinv_fsize Ndrep_all_coinv_fsize pr_all_coinv_fsize pr_alo_coinv_fsize



//////////////////////////
////	by Deciles
/////////////////////////


*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear f10f: egen Ndrpat_inv_f10f=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear f10f: egen Ndrep_alo_coinv_f10f=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys appyear f10f: egen Ndrep_all_coinv_f10f=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv_f10f=Ndrep_alo_coinv_f10f/Ndrpat_inv_f10f

*probability of all  coinventors
gen pr_all_coinv_f10f=Ndrep_all_coinv_f10f/Ndrpat_inv_f10f

//////////////
/// graphs 
////////////

local t=0
global g pr_alo_coinv_f10f pr_all_coinv_f10f

foreach k of global g{
local ++t

preserve

drop if f10f==0

collapse (mean) `k', by(appyear f10f)

tostring f10f, replace

*Number and share of patents by IPC1
levelsof f10f, local(levels) 
local i=1
local pl_f10f


foreach l of local levels{
local pl_f10f  `pl_f10f' (connected `k' appyear if f10f=="`l'")
local lab_str  `lab_str' label( `i' "D `l'") 
local i=`i'+1
}

if `t'==1{
local lb "Pr Repeat at Least One Coinventor"
}

if `t'==2{
local lb "Pr Repeat All Coinventors"
}

twoway  `pl_f10f' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) ///
xlabel($iyear(5)$fyear , labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(5) size(small)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

restore
}


drop Ndrpat_inv_f10f Ndrep_alo_coinv_f10f Ndrep_all_coinv_f10f pr_alo_coinv_f10f pr_all_coinv_f10f




*********************************************************************************
*					Fraction of Dist. Co-Inventors								*
*																				*
*********************************************************************************

*------------------------------------*
*	Merge Agg. Measures
*------------------------------------*

merge m:1 patent categ1 using "$datasets/survival_agg_measures.dta", gen(m_ag)

drop m_ag

*Generate important measures
gen frac_dcoinv=Nd_coinv/Ncoinv

*dummy of change of inventor
sort categ1
gen dinv=1 if categ1[_n]!=categ1[_n-1]


///////////////////////////////
//	Comparing Aggregate Measures
/////////////////////////////////

*1) Large vs PV - App date

bys appyear: egen mNcoinv2=mean(Ncoinv*dinv)
bys appyear: egen mNd_coinv2=mean(Nd_coinv*dinv)
bys appyear: egen mfrac_dcoinv2=mean(frac_dcoinv*dinv)


{
preserve

collapse (mean) mNcoinv2 mNd_coinv2 mNcoinv mNd_coinv frac_dcoinv mfrac_dcoinv2, by(appyear)

*Total Inventors
twoway (connected  mNcoinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  mNcoinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number Total Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main Dataset") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/mNcoinv.pdf", replace as(pdf)
}


*No. distinct Coinventor
twoway (connected  mNd_coinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  mNd_coinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number Distinct Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main Dataset") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/mNd_coinv.pdf", replace as(pdf)
}


*Frac Rep Coinventor
twoway (connected  mfrac_dcoinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  mfrac_dcoinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/mfrac_dcoinv.pdf", replace as(pdf)
}


*Total And Distinct Coinv
twoway (connected  mNcoinv2 appyear, lcolor(navy) lwidth(medthick)) (connected  mNd_coinv2 appyear, lcolor(maroon) lwidth(medthick) lp(dash)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Co-inventors  ",height(8) size($size_font)) legend(region(lcolor(white)) label(1 "Total") label(2 "Distinct") )  xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/num_distinc_tot_agr.pdf", replace as(pdf)
}

restore
}

*2) Issue Date

bys iyear: egen imNcoinv=mean(Ncoinv*dinv)
bys iyear: egen imNd_coinv=mean(Nd_coinv*dinv)
bys iyear: egen imfrac_dcoinv=mean(frac_dcoinv*dinv)

{

preserve

collapse (mean) imNcoinv imNd_coinv imfrac_dcoinv , by(iyear)

*Total Inventors
twoway (connected  imfrac_dcoinv iyear, lcolor(navy) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main Dataset") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/imfrac_dcoinv.pdf", replace as(pdf)
}


*Total And Distinct Coinv
twoway (connected  imNcoinv iyear, lcolor(navy) lwidth(medthick)) (connected  imNd_coinv iyear, lcolor(maroon) lwidth(medthick) lp(dash)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initital Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Co-inventors",height(8) size($size_font)) legend(region(lcolor(white)) label(1 "Total") label(2 "Distinct") )  xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/inum_distinc_tot_agr.pdf", replace as(pdf)
}


restore
}

//////////////////////////
////	By IPC
/////////////////////////

*1) By App Date and IPC

bys appyear ipc1: egen mNcoinv_ipc=mean(Ncoinv*dinv)
bys appyear ipc1 : egen mNd_coinv_ipc=mean(Nd_coinv*dinv)
bys appyear ipc1: egen mfrac_dcoinv_ipc=mean(frac_dcoinv*dinv)

{

preserve

collapse (mean) mNcoinv_ipc mNd_coinv_ipc mfrac_dcoinv_ipc, by(appyear ipc1)

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected mfrac_dcoinv_ipc appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/mfrac_dcoinv_ipc.pdf", replace as(pdf)
}

restore

}

drop mNcoinv_ipc mNd_coinv_ipc mfrac_dcoinv_ipc

*2) By App Date and Initial Year

*--Media del numero de coinventores por ipc1
bys iyear ipc1: egen imNcoinv_ipc=mean(Ncoinv*dinv)
bys iyear ipc1 : egen imNd_coinv_ipc=mean(Nd_coinv*dinv)
bys iyear ipc1: egen imfrac_dcoinv_ipc=mean(frac_dcoinv*dinv)

{

preserve

collapse (mean) imNcoinv_ipc imNd_coinv_ipc imfrac_dcoinv_ipc, by(iyear ipc1)

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected imfrac_dcoinv_ipc iyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/imfrac_dcoinv_ipc.pdf", replace as(pdf)
}

restore

}

drop imNcoinv_ipc imNd_coinv_ipc imfrac_dcoinv_ipc

//////////////////////////
////	by Team Size
/////////////////////////


*1) By App Date and tsize

bys appyear tsize2: egen mNcoinv_tsize=mean(Ncoinv*dinv)
bys appyear tsize2 : egen mNd_coinv_tsize=mean(Nd_coinv*dinv)
bys appyear tsize2: egen mfrac_dcoinv_tsize=mean(frac_dcoinv*dinv)

{

preserve

collapse (mean) mNcoinv_tsize mNd_coinv_tsize mfrac_dcoinv_tsize, by(appyear tsize2)


twoway (connected mfrac_dcoinv_tsize appyear if tsize2==2, lwidth(medthick)) (connected mfrac_dcoinv_tsize appyear if tsize2==3, lwidth(medthick)) ///
(connected mfrac_dcoinv_tsize appyear if tsize2==4, lwidth(medthick)) (connected mfrac_dcoinv_tsize appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 


if $save_fig==1 {
graph export "$figfolder/mfrac_dcoinv_tsize.pdf", replace as(pdf)
}

restore

}

drop mNcoinv_tsize mNd_coinv_tsize mfrac_dcoinv_tsize

*2) By Initial Year and tsize

bys iyear tsize2: egen imNcoinv_tsize=mean(Ncoinv*dinv)
bys iyear tsize2 : egen imNd_coinv_tsize=mean(Nd_coinv*dinv)
bys iyear tsize2: egen imfrac_dcoinv_tsize=mean(frac_dcoinv*dinv)

{

preserve


collapse (mean) imNcoinv_tsize imNd_coinv_tsize imfrac_dcoinv_tsize, by(iyear tsize2)

twoway (connected imfrac_dcoinv_tsize iyear if tsize2==2, lwidth(medthick)) (connected imfrac_dcoinv_tsize iyear if tsize2==3, lwidth(medthick)) ///
(connected imfrac_dcoinv_tsize iyear if tsize2==4, lwidth(medthick)) (connected  imfrac_dcoinv_tsize iyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/imfrac_dcoinv_tsize.pdf", replace as(pdf)
}


restore

}

drop imNcoinv_tsize imNd_coinv_tsize imfrac_dcoinv_tsize


//////////////////////////
////	by Asg. Groups
/////////////////////////


*1) By App Date and Assignee

bys appyear group: egen mNcoinv_group=mean(Ncoinv*dinv)
bys appyear group : egen mNd_coinv_group=mean(Nd_coinv*dinv)
bys appyear group: egen mfrac_dcoinv_group=mean(frac_dcoinv*dinv)
{

preserve

collapse (mean) mNcoinv_group mNd_coinv_group mfrac_dcoinv_group, by(appyear group)

twoway (connected  mfrac_dcoinv_group appyear if group==1, lwidth(medthick)) (connected mfrac_dcoinv_group appyear if group==2, lwidth(medthick)) ///
(connected  mfrac_dcoinv_group appyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/mfrac_dcoinv_group.pdf", replace as(pdf)
}

restore
}

drop mNcoinv_group mNd_coinv_group mfrac_dcoinv_group

*2) By Issue Date and Assignee 

bys iyear group: egen imNcoinv_group=mean(Ncoinv*dinv)
bys iyear group : egen imNd_coinv_group=mean(Nd_coinv*dinv)
bys iyear group: egen imfrac_dcoinv_group=mean(frac_dcoinv*dinv)

{

preserve

collapse (mean) imNcoinv_group imNd_coinv_group imfrac_dcoinv_group, by(iyear group)

twoway (connected  imfrac_dcoinv_group iyear if group==1, lwidth(medthick)) (connected imfrac_dcoinv_group iyear if group==2, lwidth(medthick)) ///
(connected  imfrac_dcoinv_group iyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/imfrac_dcoinv_group.pdf", replace as(pdf)
}

restore
}

drop imNcoinv_group imNd_coinv_group imfrac_dcoinv_group imfrac_dcoinv_tsize


//////////////////////////////
//		By quintiles
//////////////////////////////

*1) By App Date and IPC

bys appyear fsize: egen mNcoinv_fsize=mean(Ncoinv*dinv)
bys appyear fsize : egen mNd_coinv_fsize=mean(Nd_coinv*dinv)
bys appyear fsize: egen mfrac_dcoinv_fsize=mean(frac_dcoinv*dinv)

{

preserve

collapse (mean) mNcoinv_fsize mNd_coinv_fsize mfrac_dcoinv_fsize, by(appyear fsize)

global g mfrac_dcoinv_fsize

foreach k of global g {
twoway (connected  `k' appyear if fsize==1, lwidth(medthick)) ///
(connected   `k' appyear if fsize==2, lwidth(medthick)) ///
(connected   `k' appyear if fsize==3, lwidth(medthick)) ///
(connected   `k' appyear if fsize==4, lwidth(medthick)) ///
(connected   `k' appyear if fsize==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label( 1 "1st Quintile Firm Size" ) label( 2 "2nd Quintile") label( 3 "3rd Quintile") label( 4 "4th Quintile") label( 5 "5th Quintile") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore
}

drop mNcoinv_fsize mNd_coinv_fsize mfrac_dcoinv_fsize


//////////////////////////////
//		By Deciles
//////////////////////////////

*1) By App Date and IPC

bys appyear f10f: egen mNcoinv_f10f=mean(Ncoinv*dinv)
bys appyear f10f : egen mNd_coinv_f10f=mean(Nd_coinv*dinv)
bys appyear f10f: egen mfrac_dcoinv_f10f=mean(frac_dcoinv*dinv)


{
global g mfrac_dcoinv_f10f
foreach k of global g{


preserve

drop if f10f==0

collapse (mean) `k', by(appyear f10f)

tostring f10f, replace

*Number and share of patents by IPC1
levelsof f10f, local(levels) 
local i=1
local pl_f10f


foreach l of local levels{
local pl_f10f  `pl_f10f' (connected `k' appyear if f10f=="`l'")
local lab_str  `lab_str' label( `i' "D `l'") 
local i=`i'+1
}


twoway  `pl_f10f' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) ///
xlabel($iyear(5)$fyear , labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Distinct Coinventors" ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(5) size(small)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

restore
}
}
drop mNcoinv_f10f mNd_coinv_f10f mfrac_dcoinv_f10f

*********************************************************************************
*					Fraction of Rep. Inventors									*
*																				*
*********************************************************************************

gen frac_rep_coinv2=Nrep_coinv/tsize

///////////////////////////////
//	Comparing Aggregate Measures
/////////////////////////////////

*1) Large vs PV - App date

bys appyear : egen mpat_frac_rep_coinv2=mean(frac_rep_coinv2)
bys appyear : egen mrpat_frac_rep_coinv2=mean(frac_rep_coinv*dpat_rpat_inv)

{


preserve

collapse mpat_frac_rep_coinv2 mrpat_frac_rep_coinv2 mpat_frac_rep_coinv mrpat_frac_rep_coinv, by(appyear)


twoway (connected  mpat_frac_rep_coinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  mpat_frac_rep_coinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Rep Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main Dataset") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/mpat_frac_rep_coinv.pdf", replace as(pdf)
}


twoway (connected  mrpat_frac_rep_coinv appyear, lcolor(navy) lwidth(medthick)) ///
(connected  mrpat_frac_rep_coinv2 appyear, lcolor(maroon) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Rep Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main Dataset") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/mrpat_frac_rep_coinv.pdf", replace as(pdf)
}

restore

}


*2) by Initial Year

bys iyear : egen impat_frac_rep_coinv2=mean(frac_rep_coinv2)
bys iyear : egen imrpat_frac_rep_coinv2=mean(frac_rep_coinv*dpat_rpat_inv)

{
preserve

collapse (mean) impat_frac_rep_coinv2 imrpat_frac_rep_coinv2, by(iyear)

twoway (connected impat_frac_rep_coinv2 iyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Rep Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main Dataset") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/impat_frac_rep_coinv.pdf", replace as(pdf)
}


twoway (connected  imrpat_frac_rep_coinv2 iyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Rep Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Paired Dataset") label( 2 "PV Main") size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/imrpat_frac_rep_coinv.pdf", replace as(pdf)
}

restore

}

drop impat_frac_rep_coinv2 imrpat_frac_rep_coinv2

//////////////////////////
////	By IPC
/////////////////////////

*1) by App Year and IPC

bys appyear ipc1 : egen mpat_frac_rep_coinv_ipc=mean(frac_rep_coinv2)
bys appyear ipc1 : egen mrpat_frac_rep_coinv_ipc=mean(frac_rep_coinv*dpat_rpat_inv)

{

preserve

collapse (mean) mpat_frac_rep_coinv_ipc mrpat_frac_rep_coinv_ipc , by(appyear ipc1)

local t=0

global g mpat_frac_rep_coinv_ipc mrpat_frac_rep_coinv_ipc

foreach k of global g{
local ++t

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected `k' appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

if `t'==1{
local lb "Fraction of Repeated Co-inventors (All Patents)"
}

if `t'==2{
local lb "Pr Repeat All Coinventors (Next-Patent Inventors)"
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore

}
drop mpat_frac_rep_coinv_ipc mrpat_frac_rep_coinv_ip

*2) by Initial Year and IPC


bys iyear ipc1 : egen impat_frac_rep_coinv_ipc=mean(frac_rep_coinv2)
bys iyear ipc1 : egen imrpat_frac_rep_coinv_ipc=mean(frac_rep_coinv*dpat_rpat_inv)

{


preserve

collapse (mean) impat_frac_rep_coinv_ipc imrpat_frac_rep_coinv_ipc , by(iyear ipc1)

local t=0

global g impat_frac_rep_coinv_ipc imrpat_frac_rep_coinv_ipc

foreach k of global g{
local ++t

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected `k' iyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

if `t'==1{
local lb "Fraction of Repeated Co-inventors (All Patents)"
}

if `t'==2{
local lb "Pr Repeat All Coinventors (Next-Patent Inventors)"
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore
}

drop impat_frac_rep_coinv_ipc imrpat_frac_rep_coinv_ip


//////////////////////////
////	by Team Size
/////////////////////////


*1) By App Year and Tsize

bys appyear tsize2: egen mpat_frac_rep_coinv_tsize=mean(frac_rep_coinv2)
bys appyear tsize2 : egen mrpat_frac_rep_coinv_tsize=mean(frac_rep_coinv*dpat_rpat_inv)

{
preserve

collapse (mean) mpat_frac_rep_coinv_tsize mrpat_frac_rep_coinv_tsize, by(appyear tsize2)

twoway (connected mpat_frac_rep_coinv_tsize appyear if tsize2==2, lwidth(medthick)) (connected mpat_frac_rep_coinv_tsize appyear if tsize2==3, lwidth(medthick)) ///
(connected mpat_frac_rep_coinv_tsize appyear if tsize2==4, lwidth(medthick)) (connected mpat_frac_rep_coinv_tsize appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 


if $save_fig==1 {
graph export "$figfolder/mpat_frac_rep_coinv_tsize.pdf", replace as(pdf)
}

twoway (connected mrpat_frac_rep_coinv_tsize appyear if tsize2==2, lwidth(medthick)) (connected mrpat_frac_rep_coinv_tsize appyear if tsize2==3, lwidth(medthick)) ///
(connected mrpat_frac_rep_coinv_tsize appyear if tsize2==4, lwidth(medthick)) (connected mrpat_frac_rep_coinv_tsize appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 


if $save_fig==1 {
graph export "$figfolder/mrpat_frac_rep_coinv_tsize.pdf", replace as(pdf)
}

restore
}
drop mpat_frac_rep_coinv_tsize mrpat_frac_rep_coinv_tsize


*2) By Initial Year and Tsize

bys iyear tsize2: egen impat_frac_rep_coinv_tsize=mean(frac_rep_coinv2)
bys iyear tsize2 : egen imrpat_frac_rep_coinv_tsize=mean(frac_rep_coinv*dpat_rpat_inv)

{
preserve

collapse (mean) impat_frac_rep_coinv_tsize imrpat_frac_rep_coinv_tsize, by(iyear tsize2)

twoway (connected impat_frac_rep_coinv_tsize iyear if tsize2==2, lwidth(medthick)) (connected impat_frac_rep_coinv_tsize iyear if tsize2==3, lwidth(medthick)) ///
(connected impat_frac_rep_coinv_tsize iyear if tsize2==4, lwidth(medthick)) (connected impat_frac_rep_coinv_tsize iyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 


if $save_fig==1 {
graph export "$figfolder/impat_frac_rep_coinv_tsize.pdf", replace as(pdf)
}

twoway (connected imrpat_frac_rep_coinv_tsize iyear if tsize2==2, lwidth(medthick)) (connected imrpat_frac_rep_coinv_tsize iyear if tsize2==3, lwidth(medthick)) ///
(connected imrpat_frac_rep_coinv_tsize iyear if tsize2==4, lwidth(medthick)) (connected imrpat_frac_rep_coinv_tsize iyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 


if $save_fig==1 {
graph export "$figfolder/imrpat_frac_rep_coinv_tsize.pdf", replace as(pdf)
}

restore
}
drop impat_frac_rep_coinv_tsize imrpat_frac_rep_coinv_tsize



//////////////////////////
////	by Asg. Groups
/////////////////////////

*1) By App Year + Group

bys appyear group: egen mpat_frac_rep_coinv_group=mean(frac_rep_coinv2)
bys appyear group : egen mrpat_frac_rep_coinv_group=mean(frac_rep_coinv*dpat_rpat_inv)

{
preserve

collapse (mean) mpat_frac_rep_coinv_group mrpat_frac_rep_coinv_group, by(appyear group)

twoway (connected  mpat_frac_rep_coinv_group appyear if group==1, lwidth(medthick)) (connected mpat_frac_rep_coinv_group appyear if group==2, lwidth(medthick)) ///
(connected  mpat_frac_rep_coinv_group appyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/mpat_frac_rep_coinv_group.pdf", replace as(pdf)
}

twoway (connected  mrpat_frac_rep_coinv_group appyear if group==1, lwidth(medthick)) (connected mrpat_frac_rep_coinv_group appyear if group==2, lwidth(medthick)) ///
(connected  mrpat_frac_rep_coinv_group appyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/mrpat_frac_rep_coinv_group.pdf", replace as(pdf)
}

restore
}

drop mpat_frac_rep_coinv_group mrpat_frac_rep_coinv_group


*2) By Initial Year + Group
bys iyear group: egen impat_frac_rep_coinv_group=mean(frac_rep_coinv2)
bys iyear group : egen imrpat_frac_rep_coinv_group=mean(frac_rep_coinv*dpat_rpat_inv)

{
preserve

collapse (mean) impat_frac_rep_coinv_group imrpat_frac_rep_coinv_group, by(iyear group)

twoway (connected  impat_frac_rep_coinv_group iyear if group==1, lwidth(medthick)) (connected impat_frac_rep_coinv_group iyear if group==2, lwidth(medthick)) ///
(connected  impat_frac_rep_coinv_group iyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/impat_frac_rep_coinv_group.pdf", replace as(pdf)
}

twoway (connected  imrpat_frac_rep_coinv_group iyear if group==1, lwidth(medthick)) (connected imrpat_frac_rep_coinv_group iyear if group==2, lwidth(medthick)) ///
(connected  imrpat_frac_rep_coinv_group iyear if group==3, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below p90") label( 2 "[p90,p99]") label( 3 "Top 1%") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/imrpat_frac_rep_coinv_group.pdf", replace as(pdf)
}

restore
}

drop impat_frac_rep_coinv_group imrpat_frac_rep_coinv_group


//////////////////////////
////	by Quintiles
/////////////////////////

*1) By App Year + Group

bys appyear fsize: egen mpat_frac_rep_coinv_fsize=mean(frac_rep_coinv2)
bys appyear fsize : egen mrpat_frac_rep_coinv_fsize=mean(frac_rep_coinv*dpat_rpat_inv)

{

preserve

collapse (mean) mpat_frac_rep_coinv_fsize mrpat_frac_rep_coinv_fsize, by(appyear fsize)

global g mpat_frac_rep_coinv_fsize mrpat_frac_rep_coinv_fsize

foreach k of global g {
twoway (connected  `k' appyear if fsize==1, lwidth(medthick)) ///
(connected   `k' appyear if fsize==2, lwidth(medthick)) ///
(connected   `k' appyear if fsize==3, lwidth(medthick)) ///
(connected   `k' appyear if fsize==4, lwidth(medthick)) ///
(connected   `k' appyear if fsize==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label( 1 "1st Quintile Firm Size" ) label( 2 "2nd Quintile") label( 3 "3rd Quintile") label( 4 "4th Quintile") label( 5 "5th Quintile") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore
}

drop mpat_frac_rep_coinv_fsize mrpat_frac_rep_coinv_fsize


//////////////////////////
////	by Deciles
/////////////////////////

*1) By App Year + Group

bys appyear f10f: egen mpat_frac_rep_coinv_f10f=mean(frac_rep_coinv2)
bys appyear f10f : egen mrpat_frac_rep_coinv_f10f=mean(frac_rep_coinv*dpat_rpat_inv)

{
global g mpat_frac_rep_coinv_f10f mrpat_frac_rep_coinv_f10f

foreach k of global g{


preserve

drop if f10f==0

collapse (mean) `k', by(appyear f10f)

tostring f10f, replace

*Number and share of patents by IPC1
levelsof f10f, local(levels) 
local i=1
local pl_f10f


foreach l of local levels{
local pl_f10f  `pl_f10f' (connected `k' appyear if f10f=="`l'")
local lab_str  `lab_str' label( `i' "D `l'") 
local i=`i'+1
}


twoway  `pl_f10f' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) ///
xlabel($iyear(5)$fyear , labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction Repeated Coinventors" ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(5) size(small)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

restore
}

}
drop mpat_frac_rep_coinv_f10f mrpat_frac_rep_coinv_f10f