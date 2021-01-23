
set more off

**Saving options
global save_fig   1 //0 // 


graph set window fontface "Garamond"
global size_font large // medlarge //

*******************************************
*		New Figures Survival
*
********************************************

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots

global figfolder="$main/RA/output/reports/Fall of Generalists/Second Version/Survival/figures"
global tabfolder="$main/RA/output/reports/Fall of Generalists/Second Version/Survival/tables"

*Options of sample

*---------------------------------*
*		Turn on options
*---------------------------------*

global utility 1
global rare_any 0
global rare_all 0
global rare_mean 1

*assignee only organizations type 2 and 3
global org_asg 1


*---------------------------------*
*		Open Data
*----------------------------------*

*Open PatentsView
use "$datasets/Patentsview_Main.dta", clear

*Reduced Version
keep patent date appyear type_pat inventor_id invseq categ1 ipc3 asgnum type_asg assignee tsize d_asg_org identified_ipc rare_ipc3_any rare_ipc3_mean

* Merge Survival SC

merge m:1 patent categ1 using "$main/RA/from server/output/datasets/survival_PV.dta", gen(m_surv_sc)
drop if m_surv_sc==2
drop m_surv_sc

compress

save "$datasets/PatentsView_Survival_Main.dta", replace


* Merge dummies data 
use "$datasets/PatentsView_Survival_Main.dta", clear

merge m:1 patent categ1 using "$datasets/survival_dummies_probability.dta", gen(m_dummy)

drop m_dummy


*Merge agg measures 

merge m:1 patent categ1 using "$datasets/survival_agg_measures.dta", gen(m_ag)

drop m_ag


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

bys categ1 (appyear) : egen iyear=min(appyear)

sort appyear pr_alo_coinv
gen dyear=1 if appyear[_n]~=appyear[_n-1] 


*Create alternative measure for team size
keep if tsize>1

*Define Top


**************************************************************
*		Number of Coinventors (Repeated and Distinct)
*
***************************************************************
{

	
*Verify Aggregate Measures


*--Media del numero de coinventores por año
bys appyear: egen mNcoinv2=mean(Ncoinv)

*--Media del numero de diferentes coinventores por año
bys appyear: egen mNd_coinv2=mean(Nd_coinv)

preserve
collapse (mean) mNcoinv2 mNd_coinv2, by(appyear)

twoway (connected  mNcoinv2 appyear, lcolor(navy) lwidth(medthick)) (connected  mNd_coinv2 appyear, lcolor(maroon) lwidth(medthick) lp(dash)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Co-inventors  ",height(8) size($size_font)) legend(region(lcolor(white)) label(1 "Total") label(2 "Distinct") )  xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/num_distinc_tot_agr$gsave_str.pdf", replace as(pdf)
}

restore

*--Media del numero de coinventores por año
bys appyear ipc1: egen mNcoinv_ipc1=mean(Ncoinv)

*--Media del numero de diferentes coinventores por año
bys appyear ipc1: egen mNd_coinv_ipc1=mean(Nd_coinv)

*--Media del numero de diferentes coinventores por año
bys appyear ipc1: egen mNrep_coinv_ipc1=mean(Nrep_coinv)


preserve


collapse (mean) mNcoinv_ipc1 mNd_coinv_ipc1 mNrep_coinv_ipc1, by(appyear ipc1)



*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected  mNd_coinv_ipc appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Distinct Coinventors ",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/num_distinc_coinv_ipc$gsave_str.pdf", replace as(pdf)
}




*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected  mNrep_coinv_ipc appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Repeated Coinventors ",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/num_rep_coinv_ipc$gsave_str.pdf", replace as(pdf)
}



*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected mNcoinv_ipc appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}




twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Coinventors ",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/num_coinv_ipc$gsave_str.pdf", replace as(pdf)
}


restore




*--Media del numero de coinventores por año
bys appyear tsize2: egen mNcoinv_tsize2=mean(Ncoinv)

*--Media del numero de diferentes coinventores por año
bys appyear tsize2: egen mNd_coinv_tsize2=mean(Nd_coinv)

*--Media del numero de diferentes coinventores por año
bys appyear tsize2: egen mNrep_coinv_tsize2=mean(Nrep_coinv)

preserve

collapse (mean) mNcoinv_tsize2 mNd_coinv_tsize2 mNrep_coinv_tsize2, by(appyear tsize2)

twoway (connected  mNcoinv_tsize2 appyear if tsize2==2, lwidth(medthick)) (connected  mNcoinv_tsize2 appyear if tsize2==3, lwidth(medthick)) ///
(connected  mNcoinv_tsize2 appyear if tsize2==4, lwidth(medthick)) (connected  mNcoinv_tsize2 appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Coinventors ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/num_coinv_tsize2$gsave_str.pdf", replace as(pdf)
}



twoway (connected   mNrep_coinv_tsize2 appyear if tsize2==2, lwidth(medthick)) (connected  mNrep_coinv_tsize2 appyear if tsize2==3, lwidth(medthick)) ///
(connected  mNrep_coinv_tsize2 appyear if tsize2==4, lwidth(medthick)) (connected  mNrep_coinv_tsize2 appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Repeated Coinventors ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/num_rep_coinv_tsize2$gsave_str.pdf", replace as(pdf)
}



twoway (connected   mNd_coinv_tsize2 appyear if tsize2==2, lwidth(medthick)) (connected  mNd_coinv_tsize2 appyear if tsize2==3, lwidth(medthick)) ///
(connected  mNd_coinv_tsize2 appyear if tsize2==4, lwidth(medthick)) (connected  mNd_coinv_tsize2 appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Distinct Coinventors ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/num_distinc_coinv_tsize2$gsave_str.pdf", replace as(pdf)
}

restore
}


*************************************************************
*		Probability (All and Alo)
*
************************************************************
*identify year (with information)

{

*---Aggregate
preserve

collapse (mean) pr_alo_coinv pr_all_coinv, by(appyear)

*Probability repeat at least one coinventor
twoway (connected  pr_alo_coinv appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/pr_alo_coinv$gsave_str.pdf", replace as(pdf)
}

*Probability repeat all coinventors
twoway (connected  pr_all_coinv appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/pr_all_coinv$gsave_str.pdf", replace as(pdf)
}

restore

*Probability - At least one coinventor
preserve


collapse (mean) pr_alo_coinv_ipc1 pr_all_coinv_ipc1, by(appyear ipc1)

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected  pr_alo_coinv_ipc1 appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/pr_alo_coinv_ipc1$gsave_str.pdf", replace as(pdf)
}


*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected  pr_all_coinv_ipc1 appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventors",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/pr_all_coinv_ipc1$gsave_str.pdf", replace as(pdf)
}

restore



preserve


collapse (mean) pr_alo_coinv_tsize2 pr_all_coinv_tsize2, by(appyear tsize2)

twoway (connected pr_alo_coinv_tsize2 appyear if tsize2==2, lwidth(medthick)) (connected pr_alo_coinv_tsize2 appyear if tsize2==3, lwidth(medthick)) ///
(connected  pr_alo_coinv_tsize2 appyear if tsize2==4, lwidth(medthick)) (connected  pr_alo_coinv_tsize2 appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/pr_alo_coinv_tsize2$gsave_str.pdf", replace as(pdf)
}

twoway (connected pr_all_coinv_tsize2 appyear if tsize2==2, lwidth(medthick)) (connected pr_all_coinv_tsize2 appyear if tsize2==3, lwidth(medthick)) ///
(connected  pr_all_coinv_tsize2 appyear if tsize2==4, lwidth(medthick)) (connected  pr_all_coinv_tsize2 appyear if tsize2==5, lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventors",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/pr_all_coinv_tsize2$gsave_str.pdf", replace as(pdf)
}


restore



}

****************************************************
*		Probability - Exercise computing the dummies
*
**************************************************
{

*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear: egen Ndrpat_inv_ipc1=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear : egen Ndrep_alo_coinv_ipc1=total(drep_alo_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv2=Ndrep_alo_coinv/Ndrpat_inv


twoway (connected  pr_alo_coinv appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

twoway (connected  pr_alo_coinv2 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))


}


