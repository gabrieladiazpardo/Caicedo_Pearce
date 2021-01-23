*************************************************
*		Fall of Generalists?
*		PatentsView Data
*
************************************************

*Fall 2020
set more off

**Saving options
global save_fig   1 // 0 //


graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots


global figfolder="$main/RA/output/figfolder/fall of generalists"
global tabfolder="$main/RA/output/tabfolder/fall of generalists"


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


/*
use "$datasets/Patentsview_Main.dta", clear
use "$datasets/Patentsview_lev_dataset.dta", clear
*/



****************************************
*		Explorations:  USPC VS IPC3
*****************************************
{

/*


use "$datasets/Patentsview_lev_dataset.dta", clear


count if mainclass_uspc==""
count if ipc3==""

tab type_pat if ipc3==""

gen same_code=1 if mainclass_uspc==ipc3 & mainclass_uspc!="" & ipc3!=""

gen uspc_not_ipc=1 if mainclass_uspc!="" & ipc3==""

gen ipc_not_uspc=1 if mainclass_uspc=="" & ipc3!=""

tab mainclass_uspc if ipc3=="" //99.60 D //

tab type_pat if ipc3=="" // 99.63% are design.

gen miss=1 if mainclass_uspc=="" & ipc3==""

tab type_pat if miss==1  //99.38 D //


gen d_lett=substr(patent,1,1)
gen d_patent=(d_lett=="D")
drop d_lett

tab mainclass_uspc if d_patent==1 //all 


tab d_patent type_pat //all patents starting with D letter are design patents

*/
}

*****************************************
* Facts 0: From Pearce (2020) Appendix
*****************************************
{

*-------------
* Team size 
*-------------

{
***Team size over time

use "$datasets/Patentsview_lev_dataset.dta", clear

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

drop if appyear<=$iyear

collapse (mean) tsize , by(appyear)

twoway (connected  tsize appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/team_size`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

***Team size over time by ipc1

use "$datasets/Patentsview_lev_dataset.dta", clear

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


gen ipc1=substr(ipc3,1,1)

collapse (mean) tsize , by(appyear ipc1)

levelsof ipc1, local(levels) 

local i=1

foreach l of local levels{
local pl_str  `pl_str' (connected  tsize appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Team Size",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/team_size_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

***Team size distribution

use "$datasets/Patentsview_lev_dataset.dta", clear


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

local maxtsize 10
local dtsize=round(`maxtsize'/10)

gen tsize_mod=tsize
	replace tsize_mod=`maxtsize' if tsize>`maxtsize' & tsize!=.

keep appyear tsize_mod

twoway histogram tsize_mod , bcolor(navy) width(1) gap(20) start(1) discrete ///
graphregion(color(white)) bgcolor(white) xtitle("Team Size",height(8) size($size_font)) xlabel(0(`dtsize')`maxtsize', labsize($size_font)) ///
ylabel(, nogrid labsize($size_font)) ytitle("Density",height(8) size($size_font)) 

if $save_fig==1 {
graph export "$figfolder/team_size_hist`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

***Team size distribution by decade

gen decade=10*floor(appyear/10)

levelsof decade, local(ldecade) 

local i=1

foreach l of local ldecade{

twoway histogram tsize if tsize<=10 & decade==`l' , bcolor(navy) width(1) gap(20) start(1) discrete ///
graphregion(color(white)) bgcolor(white) xtitle("Team Size",height(8) size($size_font)) xlabel(1(1)10, labsize($size_font)) ///
ylabel(, nogrid labsize($size_font)) ytitle("Density",height(8) size($size_font)) 

*name(g`l', replace) 

if $save_fig==1 {
graph export "$figfolder/team_size_hist`l'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}

}

*--------------------
* Depth and breadth 
*--------------------
{
/*
***Depth and breadth by year

use "$data/main_pat_lev_CP$save_str.dta", clear

collapse (mean) breadthteam_e depthteam_e , by(appyear)

twoway (connected  depthteam_e appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Depth",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/depth_team.pdf", replace as(pdf)
}

twoway (connected  breadthteam_e appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Breadth",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/breadth_team.pdf", replace as(pdf)
}


***Depth and breadth by year and ipc1

use "$data/main_pat_lev_CP$save_str.dta", clear

gen ipc1=substr(ipc3,1,1)

collapse (mean) breadthteam_e depthteam_e , by(appyear ipc1)

levelsof ipc1, local(levels) 

*initialize locals
local i=1
local pl_strd
local pl_strb
local lab_str 

foreach l of local levels{
local pl_strd  `pl_strd' (connected  depthteam_e appyear if ipc1=="`l'")
local pl_strb  `pl_strb' (connected  breadthteam_e appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_strd' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Depth",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/depth_ipc1.pdf", replace as(pdf)
}

twoway  `pl_strb' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Breadth",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/breadth_ipc1.pdf", replace as(pdf)
}

*/
}


}

*****************************************
* Facts 1: Explorations
*****************************************
{
*-----------------------
* Time to build patents 
*-----------------------
{

*** Time to build patent for each year

use "$datasets/Patentsview_lev_dataset.dta", clear

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


collapse (mean) m_ttb  , by(appyear)

twoway (connected  m_ttb appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build (Average of Team)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ttb_team`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*** Time to build patent for each year by team size


use "$datasets/Patentsview_lev_dataset.dta", clear


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

gen tsize2=tsize if tsize<=5
	replace tsize2=5 if tsize>5

collapse (mean) m_ttb  , by(appyear tsize2)

twoway (connected  m_ttb appyear if tsize2==1, lwidth(medthick)) (connected  m_ttb appyear if tsize2==2, lwidth(medthick)) ///
(connected  m_ttb appyear if tsize2==3, lwidth(medthick)) (connected  m_ttb appyear if tsize2==4, lwidth(medthick)) ///
(connected  m_ttb appyear if tsize2==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build (Average of Team)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label( 1 "1-person" ) label( 2 "2-person") label( 3 "3-person") label( 4 "4-person") label( 5 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/ttb_team_ts`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


*** Time to build patent for each year by sector 


use "$datasets/Patentsview_lev_dataset.dta", clear

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

gen ipc1=substr(ipc3,1,1)

collapse (mean) m_ttb , by(appyear ipc1)

levelsof ipc1, local(levels) 

*initialize locals
local i=1
local pl_str
local lab_str 

foreach l of local levels{
local pl_str  `pl_str' (connected  m_ttb appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build (Average of Team)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ttb_team_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}


*-----------------------
* Surviving Teams
*-----------------------

{
*** Surviving teams for each year


use "$datasets/Patentsview_lev_dataset.dta", clear

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


collapse (mean) survive , by(appyear)

twoway (connected  survive appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Surviving Team",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/survive`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*** Time to build patent for each year by team size

use "$datasets/Patentsview_lev_dataset.dta", clear


gen tsize2=tsize if tsize<=5
	replace tsize2=5 if tsize>5

collapse (mean) survive  , by(appyear tsize2)

twoway (connected  survive appyear if tsize2==2, lwidth(medthick)) (connected  survive appyear if tsize2==3, lwidth(medthick)) ///
(connected  survive appyear if tsize2==4, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Surviving Team",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/survive_ts`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}



*** Time to build patent for each year by sector 

use "$datasets/Patentsview_lev_dataset.dta", clear

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


gen ipc1=substr(ipc3,1,1)

collapse (mean) survive , by(appyear ipc1)

levelsof ipc1, local(levels) 

*initialize locals
local i=1
local pl_str
local lab_str 

foreach l of local levels{
local pl_str  `pl_str' (connected  survive appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Surviving Team",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/survive_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


}

*--------------------------------------
* Patent quality and team productivity
*--------------------------------------
{

***Patent quality and team productivity per year

use "$datasets/Patentsview_lev_dataset.dta", clear

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

gen tprod_f_cit3=f_cit3/tsize
gen tprod_f_cit5=f_cit5/tsize
gen tprod_f_cit8=f_cit8/tsize


gen tprod_cit3=cit3/tsize
gen tprod_cit5=cit5/tsize
gen tprod_cit8=cit8/tsize

summ cit3 if appyear==2000, d

collapse (mean) f_cit3 f_cit5 f_cit8 cit3 cit5 cit8 tprod_f_cit3 tprod_cit3 tprod_f_cit5 tprod_cit5 tprod_f_cit8 tprod_cit8, by(appyear)

**Patent quality: citations
twoway (connected  f_cit3  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected  f_cit5  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("5-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit5`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected  f_cit8  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("8-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit8`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}



twoway (connected  cit3  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected  cit5  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("5-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit5`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected  cit8  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("8-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit8`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}




**Team productivity
twoway (connected  tprod_f_cit3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_f_cit3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway (connected  tprod_f_cit5 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_f_cit5`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway (connected  tprod_f_cit8 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_f_cit8`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}




twoway (connected  tprod_cit3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_cit3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway (connected  tprod_cit5 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_cit5`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway (connected  tprod_cit8 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_cit8`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


}
}

*****************************************
* Fall of Generalists?
*****************************************
{
*---------------------------
*---------------------------
* Basics
*---------------------------
*---------------------------

*---------------------------
* Number of Classes by Year
*---------------------------
{
**USPTO

/*
use "$data/main_pat_lev_CP$save_str.dta", clear

keep appyear uspto_class

duplicates drop appyear uspto_class, force

collapse (count) uspto_class, by(appyear)


twoway (connected  uspto_class appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Distinct USPTO Classes",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/uspto_class.pdf", replace as(pdf)
}

*/

**IPC3
use "$datasets/Patentsview_lev_dataset.dta", clear

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


keep appyear ipc3 

duplicates drop appyear ipc3, force

encode ipc3, gen(ipc3n)

collapse (count) ipc3n, by(appyear)

twoway (connected  ipc3n appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(80(10)150, nogrid labsize($size_font)) ////
ytitle("Number of Distinct IPC (3 Characters)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


}

*----------------------------------------
* Number and share of Patents by IPC3
*----------------------------------------
{
**Number of patents

use "$datasets/Patentsview_lev_dataset.dta", clear

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


gen ipc1=substr(ipc3,1,1)

sort appyear patent

bys appyear: gen tot_pat=_N
bys appyear ipc1: gen n_ipc1=_N
bys appyear ipc3: gen n_ipc3=_N

gen s_ipc1=n_ipc1/tot_pat
gen s_ipc3=n_ipc3/tot_pat

bys appyear ipc1: gen sqs_ipc1=s_ipc1^2
bys appyear ipc3: gen sqs_ipc3=s_ipc3^2

sort appyear ipc1
gen temp=1 if ipc1[_n]!=ipc1[_n-1]
gen sqs_ipc1_temp=temp*sqs_ipc1

duplicates drop appyear ipc3, force

egen  HHI_ipc1=sum(sqs_ipc1_temp), by(appyear)
egen  HHI_ipc3=sum(sqs_ipc3), by(appyear)

keep appyear ipc1 ipc3 tot_pat n_ipc1 s_ipc1 n_ipc3 s_ipc3 HHI_ipc1 HHI_ipc3

encode ipc3, gen(ipc3n)

**Number of patents

replace tot_pat=tot_pat/1000


*Total number of patents
twoway (connected  tot_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents in Thousands",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tot_pat`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*Total number of patents not classified
twoway (connected  n_ipc3 appyear if ipc3n==. , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Not Classified",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/no_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

local i=1
local pl_n_str 
local pl_s_str 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  n_ipc1 appyear if ipc1=="`l'")
local pl_s_str  `pl_s_str' (connected  s_ipc1 appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_n_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/n_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway  `pl_s_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

**Herfindahl-Hirschman Index

global pl_fyear 2015

*IPC1
twoway (connected  HHI_ipc1 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC1",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*IPC3
twoway (connected  HHI_ipc3 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}

*---------------------------
* Number of inventors by Year
*---------------------------
{

use "$datasets/Patentsview_Main.dta", clear

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

drop if categ1==.

keep categ1 appyear

collapse (count) categ1, by(appyear)


twoway (connected  categ1 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Inventors",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/inventors`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}
*--------------------------------
* Number of patents by inventors (M)
*--------------------------------
{
***Options: choose lsolo=1 if want to run for solo patents only
local lsolo 1

if `lsolo'==1{
local lkeep keep if tsize==1
global save_str_solo _solo
}

use "$datasets/Patentsview_Main.dta", clear

`lkeep'

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


keep categ1 appyear ipc3

drop if categ1==.
drop if appyear==.

gen ipc1=substr(ipc3,1,1)

bys categ1 : gen npat=_N
bys categ1 ipc1 : gen npat_ipc1=_N
bys categ1 ipc3 :  gen npat_ipc3=_N

*Running number of patents
sort categ1 appyear ipc3

bys categ1 ipc3 (appyear ipc3):  gen rpat_ipc3=_n
bys categ1 (appyear ipc3 rpat_ipc3): gen rpat=_n
bys categ1 ipc1 (appyear ipc3 rpat_ipc3): gen rpat_ipc1=_n


sort categ1 appyear ipc3 rpat_ipc3

*count number of different classes by inventor
bys categ1 (ipc3 appyear rpat_ipc3) : gen dipc3=1 if ipc3[_n]!=ipc3[_n-1]
bys categ1 : egen nipc3=total(dipc3)
bys categ1 (appyear ipc3 rpat_ipc3)  : gen ripc3=sum(dipc3)

bys categ1 (ipc3 appyear rpat_ipc3) : gen dipc1=1 if ipc1[_n]!=ipc1[_n-1]
bys categ1 : egen nipc1=total(dipc1)
bys categ1 (appyear ipc3 rpat_ipc3)  : gen ripc1=sum(dipc1)

*ratios: number of classes per patents
gen nipc3_pat=nipc3/npat
gen ripc3_pat=ripc3/rpat 

gen nipc1_pat=nipc1/npat
gen ripc1_pat=ripc1/rpat

*Initial year and final year
bys categ1 (appyear) : egen iyear=min(appyear)
bys categ1 (appyear) : egen fyear=max(appyear)

**Cohorts: 
*Group every 10 years
gen gr_10yr=1 if iyear>=1975 & iyear<=1984
	replace gr_10yr=2 if iyear>=1985 & iyear<=1994
	replace gr_10yr=3 if iyear>=1995 & iyear<=2004
	replace gr_10yr=4 if iyear>=2005 & iyear<=2014
	
*Group every 5 years
gen gr_5yr=1 if iyear>=1975 & iyear<=1979
	replace gr_5yr=2 if iyear>=1980 & iyear<=1984
	replace gr_5yr=3 if iyear>=1985 & iyear<=1989
	replace gr_5yr=4 if iyear>=1990 & iyear<=1994
	replace gr_5yr=5 if iyear>=1995 & iyear<=1999
	replace gr_5yr=6 if iyear>=2000 & iyear<=2004
	replace gr_5yr=7 if iyear>=2005 & iyear<=2009
	replace gr_5yr=8 if iyear>=2010 & iyear<=2014

**Distribution of number of patents by inventor
local nmaxpat 10
local dpat=round(`nmaxpat'/10)
local lw=max(round(`nmaxpat'/50),1)


preserve

duplicates drop categ1, force

gen npat_mod=npat
	replace npat_mod=`nmaxpat' if npat>`nmaxpat' & npat!=.
	
twoway histogram npat_mod, bcolor(navy) width(`lw') gap(20) start(1) discrete ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents by Inventor",height(8) size($size_font)) xlabel(0(`dpat')`nmaxpat', labsize($size_font)) ///
ylabel(, nogrid labsize($size_font)) ytitle("Density",height(8) size($size_font)) 

if $save_fig==1 {
graph export "$figfolder/npat_hist$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

restore


**IPC per inventor
preserve

collapse (mean) ripc1 ripc3 ripc1_pat ripc3_pat , by(appyear)


*Running IPC count

twoway (connected  ripc1 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC1 per Inventor",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc1$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway (connected  ripc3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Inventor",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


*Running IPC count per patent count

twoway (connected  ripc1_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc1_pat$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected  ripc3_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


restore

**Compare cohorts

*Every 10 years
preserve

local maxrpat 100
local dpat=round(`maxrpat'/10)

keep if rpat<=`maxrpat'

collapse (mean) ripc1 ripc3, by(rpat gr_10yr)

twoway (line ripc3 rpat if gr_10yr==1, lcolor(navy) lwidth(medthick))  (line  ripc3 rpat if gr_10yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  ripc3 rpat if gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  ripc3 rpat if gr_10yr==4, lcolor(gray) lwidth(medthick) lpattern("---")) if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_10yr$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (line ripc1 rpat if gr_10yr==1, lcolor(navy) lwidth(medthick))  (line  ripc1 rpat if gr_10yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  ripc1 rpat if gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  ripc3 rpat if gr_10yr==4, lcolor(gray) lwidth(medthick) lpattern("---")) if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC1",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014")  )

if $save_fig==1 {
graph export "$figfolder/ripc1_rpat_10yr$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

restore


*Every 5 years
preserve

local maxrpat 100
local dpat=round(`maxrpat'/10)

keep if rpat<=`maxrpat'

collapse (mean) ripc1 ripc3, by(rpat gr_5yr)

local maxrpat 100
local dpat=round(`maxrpat'/10)

twoway (line ripc3 rpat if gr_5yr==1, lcolor(navy) lwidth(medthick))  (line  ripc3 rpat if gr_5yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
( line ripc3 rpat if gr_5yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-.") )  (line  ripc3 rpat if gr_5yr==4, lwidth(medthick) lpattern("--..")) ///
(line ripc3 rpat if gr_5yr==5,  lwidth(medthick) lpattern(longdash_dot))  (line  ripc3 rpat if gr_5yr==6,  lwidth(medthick) lpattern("--."))  ///
(line  ripc3 rpat if gr_5yr==7, lwidth(medthick) lpattern("--.."))  ///
(line  ripc3 rpat if gr_5yr==8, lwidth(medthick) lpattern("---"))  ///
if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1979") label(2 "1980-1984" ) label(3 "1985-1989") label(4 "1990-1994") label(5 "1995-1999" ) label(6 "2000-2004") label(7 "2005-2009") label(8 "2010-2014"))

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_5yr$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

twoway (line ripc1 rpat if gr_5yr==1, lcolor(navy) lwidth(medthick))  (line  ripc1 rpat if gr_5yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
( line ripc1 rpat if gr_5yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-.") )  (line  ripc1 rpat if gr_5yr==4, lwidth(medthick) lpattern("--..")) ///
(line ripc1 rpat if gr_5yr==5,  lwidth(medthick) lpattern(longdash_dot))  (line  ripc1 rpat if gr_5yr==6,  lwidth(medthick) lpattern("--."))   ///
(line  ripc3 rpat if gr_5yr==7, lwidth(medthick) lpattern("--.."))  ///
(line  ripc3 rpat if gr_5yr==8, lwidth(medthick) lpattern("---"))  ///
if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC1",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1979") label(2 "1980-1984" ) label(3 "1985-1989") label(4 "1990-1994") label(5 "1995-1999" ) label(6 "2000-2004") label(7 "2005-2009") label(8 "2010-2014"))

if $save_fig==1 {
graph export "$figfolder/ripc1_rpat_5yr$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


restore
}

*-----------------
* Solo patents (M)
*-----------------
{
**Number of patents

use "$datasets/Patentsview_lev_dataset.dta", clear

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

gen ipc1=substr(ipc3,1,1)

gen solo=1 if tsize==1
	replace solo=0 if tsize>1 & tsize!=.
	
drop if solo==.

sort appyear patent

bys appyear : gen tot_pat=_N
bys appyear ipc1: gen n_ipc1=_N
bys appyear solo: gen tot_pat_solo=_N
bys appyear solo ipc1: gen n_ipc1_solo=_N

gen s_solo_tot=tot_pat_solo/tot_pat
gen s_ipc1_solo_tot=n_ipc1_solo/n_ipc1

gen s_ipc1_solo=n_ipc1_solo/tot_pat_solo

keep appyear ipc1 solo tot_pat tot_pat_solo n_ipc1_solo s_solo_tot s_ipc1_solo_tot s_ipc1_solo

duplicates drop appyear solo ipc1, force


**Number of patents by ipc1

levelsof ipc1, local(levels) 

*initialize locals
local i=1
local pl_str_solo
local pl_s_str_solo
local pl_s_str 
local lab_str 

foreach l of local levels{
local pl_str_solo  `pl_str_solo' (connected  n_ipc1_solo appyear if ipc1=="`l'" & solo==1)
local pl_s_str_solo  `pl_s_str_solo' (connected  s_ipc1_solo appyear if ipc1=="`l'" & solo==1)
local pl_s_str  `pl_s_str' (connected  s_ipc1_solo_tot appyear if ipc1=="`l'" & solo==1)

local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


local pl_s_str `pl_s_str'  (line  s_solo_tot appyear if ipc1=="A" & solo==1, lcolor(black) lwidth(thick) lpattern(dash) )
local lab_str_s `lab_str' label( `i' "All")

*level
twoway  `pl_str_solo' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/n_ipc1_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*share in solo
twoway  `pl_s_str_solo' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_ipc1_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*share of solo
twoway  `pl_s_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str_s' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_solo_tot_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


duplicates drop appyear solo, force

*Total number of patents
twoway (connected  tot_pat_solo appyear if solo==0, lcolor(navy) lwidth(medthick)) (connected  tot_pat_solo appyear if solo==1, lcolor(maroon) lwidth(medthick) ms(D)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "Team Patents (>1)") label(2 "Solo Patents"))

if $save_fig==1 {
graph export "$figfolder/tot_pat_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}

*---------------------------------------
* HHI by Inventor and only solo patents
*---------------------------------------
{
**Herfindahl-Hirschman Index
*Options: choose lsolo=1 if want to run for solo patents only
local lsolo 1

global save_str_solo

if `lsolo'==1{
local lkeep keep if tsize==1
global save_str_solo _solo
}

use "$datasets/Patentsview_Main.dta", clear

`lkeep'

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


gen ipc1=substr(ipc3,1,1)

sort appyear patent

bys appyear: gen tot_pat=_N
bys appyear ipc1: gen n_ipc1=_N
bys appyear ipc3: gen n_ipc3=_N

gen s_ipc1=n_ipc1/tot_pat
gen s_ipc3=n_ipc3/tot_pat

bys appyear ipc1: gen sqs_ipc1=s_ipc1^2
bys appyear ipc3: gen sqs_ipc3=s_ipc3^2

sort appyear ipc1
gen temp=1 if ipc1[_n]!=ipc1[_n-1]
gen sqs_ipc1_temp=temp*sqs_ipc1

duplicates drop appyear ipc3, force

egen  HHI_ipc1=sum(sqs_ipc1_temp), by(appyear)
egen  HHI_ipc3=sum(sqs_ipc3), by(appyear)

keep appyear ipc1 ipc3 tot_pat n_ipc1 s_ipc1 n_ipc3 s_ipc3 HHI_ipc1 HHI_ipc3

encode ipc3, gen(ipc3n)


global pl_fyear 2015

*IPC1
twoway (connected  HHI_ipc1 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC1",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc1_ind$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*IPC3
twoway (connected  HHI_ipc3 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3_ind$save_str_solo`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}

*----------------------------------------------------
*Basics: Assignees (Organizational Assignees)
*----------------------------------------------------
{

**Number of assignees by year
use "$datasets/Patentsview_lev_dataset.dta", clear

drop if asgnum==""
drop if appyear==.

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

keep appyear asgnum

duplicates drop appyear asgnum, force

egen asg_num=group(asgnum)

collapse (count) asg_num, by(appyear)

rename asg_num nasg

twoway (connected  nasg appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/nasg`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


**Share of identified assignees
use "$datasets/Patentsview_lev_dataset.dta", clear

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


global fyear_pl 2015

gen dasg=1 if asgnum!=""
	replace dasg=0 if asgnum==""
	
collapse (mean) dasg , by(appyear)

twoway (connected  dasg appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dasg`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


keep if appyear<=$fyear_pl

twoway (connected  dasg appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dasg_$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

*Share of identified assignees by sector 


use "$datasets/Patentsview_lev_dataset.dta", clear

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


gen dasg=1 if asgnum!=""
	replace dasg=0 if asgnum==""
	
gen ipc1=substr(ipc3,1,1)

collapse (mean) dasg , by(appyear ipc1)


levelsof ipc1, local(levels) 

*initialize locals
local i=1
local pl_str
local lab_str 

foreach l of local levels{
local pl_str  `pl_str' (connected  dasg appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

keep if appyear<=$fyear_pl

twoway  `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Assignees",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dasg_ipc1_$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


global fyear_pl 2015

**Flow of patents by assignee each year

use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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


egen pat=group(patent)

rename patent patst
rename pat patent


collapse (count) patent, by(asgnum appyear d_asg_org)

drop if appyear==.

drop if asgnum==""

collapse (mean) patent, by (appyear)


twoway (connected  patent appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents by Assignee",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asgn_pat`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

keep if appyear<= $fyear_pl

twoway (connected  patent appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents by Assignee",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asgn_pat_$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

*--------------------------------
* Number of Patents by Assignee
*--------------------------------
{

use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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


keep asgnum appyear ipc3

drop if asgnum==""
drop if appyear==.

gen ipc1=substr(ipc3,1,1)

bys asgnum : gen npat=_N

duplicates drop asgnum , force 


**Distribution of number of patents by inventor
local nmaxpat 10
local dpat=round(`nmaxpat'/10)
local lw=max(round(`nmaxpat'/50),1)

gen npat_mod=npat
	replace npat_mod=`nmaxpat' if npat>`nmaxpat' & npat!=.
	
twoway histogram npat_mod, bcolor(navy) width(`lw') gap(20) start(1) discrete ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents by Assignee",height(8) size($size_font)) xlabel(0(`dpat')`nmaxpat', labsize($size_font)) ///
ylabel(, nogrid labsize($size_font)) ytitle("Density",height(8) size($size_font)) 

if $save_fig==1 {
graph export "$figfolder/npat_asg_hist`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

*----------------------------------------------------
*Distribution and Tail of Number of Patents per Assignee by Year
*----------------------------------------------------
{
global fyear_pl 2015

use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

egen pat=group(patent)

rename patent patst
rename pat patent

bys appyear : gen tot_pat=_N

collapse (count) patent (mean) tot_pat, by(appyear asgnum d_asg_org)
drop if appyear==.
drop if asgnum==""

rename patent N_pat

bys appyear: egen tot_pat_only_asg=total(N_pat)

sort appyear asgnum

*choose number of percentiles
local dprc 10

*initialize locals
local j 1
local pl_str

 forvalues i = 60(`dprc')90 {

 bys appyear: egen p`i'_pat=pctile(N_pat), p(`i')
 
local pl_str  `pl_str' (connected  p`i'_pat appyear)
local lab_str  `lab_str' label( `j' "Percentile `i'") 
local j=`j'+1
 
 }

 
*Tail of the distribution
bys appyear: egen p99_pat=pctile(N_pat), p(99)
bys appyear: egen p995_pat=pctile(N_pat), p(99.5)
bys appyear: egen p999_pat=pctile(N_pat), p(99.9)
bys appyear: egen p9999_pat=pctile(N_pat), p(99.99)

duplicates drop appyear, force

keep if appyear<= $fyear_pl

*percentiles
twoway `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  legend(region(lcolor(white)) `lab_str' cols(2) )

if $save_fig==1 {
graph export "$figfolder/dist`dprc'_N_pat$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


*p90 and p99
twoway (connected  p90_pat appyear, lcolor(navy) lwidth(medthick)) (connected  p99_pat appyear, lcolor(maroon) lwidth(medthick) msymbol(D)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "90th Percentile") label(2 "99th Percentile")  )

if $save_fig==1 {
graph export "$figfolder/p90_99_N_pat$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*tail

twoway (connected p99_pat appyear ) (connected p995_pat appyear ) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Percentile 99") label(2 "Percentile 99.5"))

if $save_fig==1 {
graph export "$figfolder/tail_p99_p995_N_pat$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected p99_pat appyear ) (connected p995_pat appyear )  (connected p999_pat appyear )  (connected p9999_pat appyear )  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Percentile 99") label(2 "Percentile 99.5") label(3 "Percentile 99.9") label(4 "Percentile 99.99") )

if $save_fig==1 {
graph export "$figfolder/tail_N_pat$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

*----------------------------------------------------
*Number and Share by Percentile of Patents for Assignees by Year
*----------------------------------------------------
{
global fyear_pl 2015

use "$datasets/Patentsview_lev_dataset.dta", clear


if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

egen pat=group(patent)

rename patent patst
rename pat patent

bys appyear : gen tot_pat=_N

collapse (count) patent (mean) tot_pat, by(appyear asgnum)

drop if appyear==.
drop if asgnum==""

bys appyear: egen tot_pat_only_asg=total(patent)

sort appyear asgnum

bys appyear: egen p50_pat=pctile(patent), p(50)
bys appyear: egen p90_pat=pctile(patent), p(90)
bys appyear: egen p99_pat=pctile(patent), p(99)

*percentiles
gen one_pat=1 if patent==1
gen p50=1 if patent>=p50_pat
	replace p50=0 if p50==.
gen p90=1 if patent>=p90_pat
	replace p90=0 if p90==.
gen p99=1 if patent>=p99_pat
	replace p99=0 if p99==.
	
*groups
gen gr_asg=1 if patent==1
	replace gr_asg=2 if patent>1 & patent<p90_pat
	replace gr_asg=3 if patent>=p90_pat & patent<p99_pat
	replace gr_asg=4 if patent>=p99_pat & patent!=.
	
gen gr2_asg=1 if patent<p90_pat
	replace gr2_asg=2 if patent>=p90_pat & patent<p99_pat
	replace gr2_asg=3 if patent>=p99_pat & patent!=.


bys appyear one_pat: egen tot_one_pat=total(patent) 
bys appyear p50: egen tot_p50_pat=total(patent) 
bys appyear p90: egen tot_p90_pat=total(patent) 
bys appyear p99: egen tot_p99_pat=total(patent)

bys appyear gr_asg: egen tot_gr_asg_pat=total(patent)
bys appyear gr2_asg: egen tot_gr2_asg_pat=total(patent)

*Compute shares
local lonly_asg  1

local ltot_pat tot_pat

if `lonly_asg'==1 {
	local ltot_pat tot_pat_only_asg
	local lsave_str _only_asg

}

gen s_one_tot=tot_one_pat/`ltot_pat'
gen s_p50_tot=tot_p50_pat/`ltot_pat'
gen s_p90_tot=tot_p90_pat/`ltot_pat'
gen s_p99_tot=tot_p99_pat/`ltot_pat'

gen s_gr_asg_tot=tot_gr_asg_pat/`ltot_pat'
gen s_gr2_asg_tot=tot_gr2_asg_pat/`ltot_pat'


duplicates drop appyear one_pat p50 p90 p99 gr_asg, force


**Top 10, and top 1 percent

*share of patents
twoway (connected  s_p90_tot appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  s_p99_tot appyear if p99==1, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 10%") label(2 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_p90_99`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

keep if appyear<= $fyear_pl

twoway (connected  s_p90_tot appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  s_p99_tot appyear if p99==1, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 10%") label(2 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_p90_99_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*in levels
twoway (connected  tot_p90_pat appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  tot_p99_pat appyear if p99==1, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "90th Percentile") label(2 "99th Percentile")  )

if $save_fig==1 {
graph export "$figfolder/tot_pat_p90_99_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Above and Below p90
twoway (connected  s_p90_tot appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  s_p90_tot appyear if p90==0, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 10%") label(2 "Bottom 90%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_t10_b90_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Above and Below p99
twoway (connected  s_p99_tot appyear if p99==1, lcolor(navy) lwidth(medthick)) (connected  s_p99_tot appyear if p99==0, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 1%") label(2 "Bottom 99%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_t1_b99_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Above the median
twoway (connected  s_p50_tot appyear if p50==1, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/s_pat_p50_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*in levels
twoway (connected  tot_p50_pat appyear, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/tot_pat_p50_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


*Only one patent

twoway (connected  s_one_tot appyear if one_pat==1, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/s_one_pat_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  tot_one_pat appyear if one_pat==1, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/tot_one_pat_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Groups
twoway (connected  s_gr_asg_tot appyear if gr_asg==1,  lwidth(medthick)) (connected  s_gr_asg_tot appyear if gr_asg==2, lwidth(medthick)) ///
(connected  s_gr_asg_tot appyear if gr_asg==3, lwidth(medthick)) (connected  s_gr_asg_tot appyear if gr_asg==4, lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Bottom 70% (Only One Patent)") label(2 "Between 70 and 90th Percentile") label(3 "Between 90 and 99th Percentile") label(4 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_gr_asg_tot_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Groups 2
twoway (connected  s_gr2_asg_tot appyear if gr2_asg==1,  lwidth(medthick)) (connected  s_gr2_asg_tot appyear if gr2_asg==2, lwidth(medthick) ms(D)) ///
(connected  s_gr2_asg_tot appyear if gr2_asg==3, lwidth(medthick) ms(S))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Below 90th Percentile") label(2 "Between 90 and 99th Percentile") label(3 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_gr2_asg_tot_$fyear_pl`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

*----------------------------------------------------
*Assignees and Classes
*----------------------------------------------------
{
global fyear_pl 2015

use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

*Only keep patents with assignee
drop if appyear==.
drop if asgnum==""


bys asgnum : gen npat=_N
bys asgnum ipc3 :  gen npat_ipc3=_N

*Running number of patents
sort asgnum appyear ipc3

bys asgnum ipc3 (appyear ipc3):  gen rpat_ipc3=_n
bys asgnum (appyear ipc3 rpat_ipc3): gen rpat=_n

sort asgnum appyear ipc3 rpat_ipc3

*count number of different classes by assignee
bys asgnum (ipc3 appyear rpat_ipc3) : gen dipc3=1 if ipc3[_n]!=ipc3[_n-1]
bys asgnum : egen nipc3=total(dipc3)
bys asgnum (appyear ipc3 rpat_ipc3)  : gen ripc3=sum(dipc3)

*ratios: number of classes per assignee
gen nipc3_pat=nipc3/npat
gen ripc3_pat=ripc3/rpat 


*Initial year and final year
bys asgnum (appyear) : egen iyear=min(appyear)
bys asgnum (appyear) : egen fyear=max(appyear)

**Cohorts: 
*Group every 10 years
gen gr_10yr=1 if iyear>=1975 & iyear<=1984
	replace gr_10yr=2 if iyear>=1985 & iyear<=1994
	replace gr_10yr=3 if iyear>=1995 & iyear<=2004
	replace gr_10yr=4 if iyear>=2005 & iyear<=2014
	
*Group every 5 years
gen gr_5yr=1 if iyear>=1975 & iyear<=1979
	replace gr_5yr=2 if iyear>=1980 & iyear<=1984
	replace gr_5yr=3 if iyear>=1985 & iyear<=1989
	replace gr_5yr=4 if iyear>=1990 & iyear<=1994
	replace gr_5yr=5 if iyear>=1995 & iyear<=1999
	replace gr_5yr=6 if iyear>=2000 & iyear<=2004
	replace gr_5yr=7 if iyear>=2005 & iyear<=2009
	replace gr_5yr=8 if iyear>=2010 & iyear<=2014
	
	
**IPC per assignee
preserve

collapse (mean) ripc3 ripc3_pat , by(appyear)

*Running IPC count
twoway (connected  ripc3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Assignee",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_asg`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


*Running IPC count per patent count

twoway (connected  ripc3_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat_asg`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

restore

**Distribution

*Only keep patents with assignee


bys appyear asgnum: gen tot_pat_asg=_N

bys appyear: egen p90_pat=pctile(tot_pat_asg), p(90)
bys appyear: egen p99_pat=pctile(tot_pat_asg), p(99)

gen p90=(tot_pat_asg>=p90_pat)

gen p99=(tot_pat_asg>=p99_pat)


preserve

collapse (mean) ripc3 ripc3_pat , by(appyear p90)

*Running IPC count per patent count

twoway (connected  ripc3_pat appyear if p90==1, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat_asg_p90`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

restore

preserve

collapse (mean) ripc3 ripc3_pat , by(appyear p99)

*Running IPC count per patent count

twoway (connected  ripc3_pat appyear if p99==1, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat_asg_p99`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

restore



**Compare cohorts of Assignees

*Every 10 years
preserve

local maxrpat 500
local dpat=round(`maxrpat'/10)

keep if rpat<=`maxrpat'

collapse (mean) ripc3, by(rpat gr_10yr)

twoway (line ripc3 rpat if gr_10yr==1, lcolor(navy) lwidth(medthick))  (line  ripc3 rpat if gr_10yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  ripc3 rpat if gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  ripc3 rpat if gr_10yr==4, lcolor(gray) lwidth(medthick) lpattern("---")) ///
if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_10yr_asg`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

restore

*Every 5 years
preserve

local maxrpat 500
local dpat=round(`maxrpat'/10)

keep if rpat<=`maxrpat'

collapse (mean) ripc3, by(rpat gr_5yr)

twoway (line ripc3 rpat if gr_5yr==1, lcolor(navy) lwidth(medthick))  (line  ripc3 rpat if gr_5yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
( line ripc3 rpat if gr_5yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-.") )  (line  ripc3 rpat if gr_5yr==4, lwidth(medthick) lpattern("--..")) ///
(line ripc3 rpat if gr_5yr==5,  lwidth(medthick) lpattern(longdash_dot))  (line  ripc3 rpat if gr_5yr==6,  lwidth(medthick) lpattern("--.")) ///
(line  ripc3 rpat if gr_5yr==7, lwidth(medthick) lpattern("--.."))  ///
(line  ripc3 rpat if gr_5yr==8, lwidth(medthick) lpattern("---"))  ///
 if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1979") label(2 "1980-1984" ) label(3 "1985-1989") label(4 "1990-1994") label(5 "1995-1999" ) label(6 "2000-2004") label(7 "2005-2009") label(8 "2010-2014"))

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_5yr_asg`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

restore

}

*----------------------------------------------------
*New entrants
*----------------------------------------------------
{
global iyear_pl 1980
global fyear_pl 2015

use "$datasets/Patentsview_lev_dataset.dta", clear


if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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


egen pat=group(patent)

rename patent patst
rename pat patent

bys asgnum appyear : gen asg_year=_n

bys appyear : gen tot_pat=_N

drop if appyear==.
drop if asgnum==""


keep if asg_year==1

collapse (count) patent (mean) tot_pat, by(appyear)

gen s_agn_entry=patent/tot_pat


twoway (connected  s_agn_entry appyear, lcolor(navy) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) name(test,replace)

if $save_fig==1 {
graph export "$figfolder/s_agn_entry`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

keep if  appyear<= $fyear_pl

twoway (connected  s_agn_entry appyear, lcolor(navy) lwidth(medthick)),  ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) 

if $save_fig==1 {
graph export "$figfolder/s_agn_entry_$fyear_pl`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
}

*----------------------------------------------------
*HHI at the Assignee level
*----------------------------------------------------
{

global iyear_pl 1980
global fyear_pl 2015

use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

drop if appyear==.
drop if asgnum==""


gen ipc1=substr(ipc3,1,1)

sort appyear patent

bys appyear asgnum: gen tot_pat=_N
bys appyear asgnum ipc3: gen n_ipc3=_N

preserve

duplicates drop appyear asgnum, force

sum tot_pat, d

restore

gen p50=1 if tot_pat>`r(p50)'
	replace p50=0 if p50==.

gen s_ipc3=n_ipc3/tot_pat

bys appyear asgnum ipc3: gen sqs_ipc3=s_ipc3^2

duplicates drop appyear asgnum, force

egen  HHI_ipc3=sum(sqs_ipc3), by(appyear asgnum)


collapse (mean)  HHI_ipc3, by(appyear p50) 


global pl_fyear 2015


*IPC3
*below p50
twoway (connected  HHI_ipc3 appyear if p50==0 , yaxis(1) lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3_asg_bp50_$pl_fyear`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*above p50
twoway (connected  HHI_ipc3 appyear if p50==1 , lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3_asg_ap50_$pl_fyear`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
}

*----------------------------------------------------
*Self-citations (macro-level)
*----------------------------------------------------
{
use "$datasets/Patentsview_lev_dataset.dta", clear

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

drop if appyear==.

egen pat=group(patent)

rename patent patst
rename pat patent

*asg_self_cite ipc3_self_cite cit_same_asg cit_ident_asg b_cit_asg_sc b_cit_ipc3_sc b_cit

/*
*micro shares
gen s_asg_self_cite=b_cit_asg_sc/b_cit
gen s_ipc3_self_cite=b_cit_ipc3_sc/b_cit
*/

collapse (count) patent (sum) b_cit b_cit_asg_sc b_cit_ipc3_sc cit_same_asg cit_ident_asg , by(appyear)

*Shares SC
gen b_cit_pat=b_cit/patent
gen asg_b_cit=b_cit_asg_sc/b_cit
gen ipc3_b_cit=b_cit_ipc3_sc/b_cit

*Shares SC
gen id_cit_asg_pat=cit_ident_asg/patent 
gen asg_cit_id_cit=cit_same_asg/cit_ident_asg
gen id_cit_b_cit=cit_ident_asg/b_cit

*Backward citations

twoway (connected  b_cit_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Backward Citations per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/b_cit`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


*Identified Assg. citations

twoway (connected id_cit_asg_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Identified Assignee Citations per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/id_cit_asg_pat`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


*Self-Citation Assignees/Backward cit

twoway (connected  asg_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Self-Citations of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asg_b_cit`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


*Self-Citation Assignees/Backward cit

twoway (connected id_cit_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Citations of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/id_cit_bcit`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}



*Self-Citation Assignees/Identified

twoway (connected  asg_cit_id_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Self-Citations of Assignees to""Citations to Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asg_cit_id_cit`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}




*----IPC3 
*Self-Citation IPC3

twoway (connected  ipc3_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Self-Citations of IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ipc3_b_cit`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}



}

*----------------------------------------------------
*Self-citations (micro-level)
*----------------------------------------------------
{
use "$datasets/Patentsview_lev_dataset.dta", clear

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

drop if appyear==.

egen pat=group(patent)

rename patent patst
rename pat patent

gen prop_asg_id_cit=cit_same_asg/cit_ident_asg
gen prop_asg_cit_b_cit=cit_same_asg/b_cit
gen prop_id_cit_b_cit=cit_ident_asg/b_cit 

collapse (count) patent (mean) prop_asg_id_cit prop_asg_cit_b_cit prop_id_cit_b_cit b_cit, by(appyear)

twoway (connected b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Average Backward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/b_cit_ml`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected prop_asg_id_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Average Ratio of Self-Citations of Assignees to""Citations to Identified Assignees",height(8) size(med)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/prop_asg_id_cit_ml`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected prop_id_cit_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Average Fraction of Identified Citations of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/prop_id_cit_b_cit_ml`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}


twoway (connected  prop_asg_cit_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Average Fraction of Self-Citations of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/prop_asg_cit_b_cit_ml`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}




}

*----------------------------------------------------
*Self-Citations (Firm Level)
*----------------------------------------------------
{
*Compute the fraction of firms that cited themselves.

use "$datasets/Patentsview_lev_dataset.dta", clear


if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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


*not identified assignee=0
*if not identified, asignee_self_cite=0

collapse (count) assignee asg_self_cite, by(appyear)

*missing value for unidentified assignees
gen  prop_asg_self_cit=asg_self_cite/assignee

twoway (connected prop_asg_self_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Self-Citing Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/prop_asg_self_cit`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}



}

*---------------------------------------
* Theil Index for IPC
*---------------------------------------
{
**Theil Index

use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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


drop if ipc3==""
drop if appyear==.
*only include patents with assignees
drop if asgnum==""

keep appyear patent ipc3 asgnum

*only firms with more than X patents
bys appyear asgnum: gen tot_asg=_N

*keep if tot_asg>50

gen ipc1=substr(ipc3,1,1)

sort appyear patent

*aggregate shares 
bys appyear: gen N_pat=_N
bys appyear ipc1: gen n_ipc1=_N
bys appyear ipc3: gen n_ipc3=_N

gen s_ipc1=n_ipc1/N_pat
gen s_ipc3=n_ipc3/N_pat

bys appyear ipc1: gen ent_ipc1=s_ipc1*log(1/s_ipc1)
bys appyear ipc3: gen ent_ipc3=s_ipc3*log(1/s_ipc3)

bys appyear: gen dyear=1 if appyear[_n]!=appyear[_n-1]
bys appyear ipc1: gen dipc1_year=1 if ipc1[_n]!=ipc1[_n-1]
bys appyear ipc3: gen dipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

bys appyear: egen E_ipc1=sum(dipc1_year*ent_ipc1)
bys appyear: egen E_ipc3=sum(dipc3_year*ent_ipc3)

*assignee shares
bys appyear asgnum: gen Npat_asg=_N
bys appyear asgnum ipc1: gen n_asg_ipc1=_N
bys appyear asgnum ipc3: gen n_asg_ipc3=_N

gen s_asg_ipc1=n_asg_ipc1/Npat_asg
gen s_asg_ipc3=n_asg_ipc3/Npat_asg

/*
bys appyear asgnum ipc1: gen ent_asg_ipc1=s_asg_ipc1*log(s_asg_ipc1/s_ipc1)
bys appyear asgnum ipc3: gen ent_asg_ipc3=s_asg_ipc3*log(s_asg_ipc3/s_ipc3)
*/

bys appyear asgnum ipc1: gen ent_asg_ipc1=s_asg_ipc1*log(1/s_asg_ipc1)
bys appyear asgnum ipc3: gen ent_asg_ipc3=s_asg_ipc3*log(1/s_asg_ipc3)

bys appyear asgnum: gen dasg_year=1 if asgnum[_n]!=asgnum[_n-1]
bys appyear asgnum ipc1: gen dasg_ipc1_year=1 if ipc1[_n]!=ipc1[_n-1]
bys appyear asgnum ipc3: gen dasg_ipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

bys appyear asgnum: egen E_asg_ipc1=sum(dasg_ipc1_year*ent_asg_ipc1)
bys appyear asgnum: egen E_asg_ipc3=sum(dasg_ipc3_year*ent_asg_ipc3)

	
bys appyear : egen T_asg=sum(dasg_year)

bys appyear : egen H_ipc1=sum((Npat_asg/N_pat)*dasg_year*(E_ipc1-E_asg_ipc1)/E_ipc1)
bys appyear : egen H_ipc3=sum((Npat_asg/N_pat)*dasg_year*(E_ipc3-E_asg_ipc3)/E_ipc3)

gen invE_ipc1=1/E_ipc1
gen invE_ipc3=1/E_ipc3


global pl_fyear 2015
	
**Entropy

*IPC1
twoway (connected  E_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC1 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  invE_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC1 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  E_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC3 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  invE_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC3 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

**Theil index for Assignees

*IPC1
twoway (connected  H_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  H_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


}

*---------------------------------------
* Decomposition: Theil Index for IPC
*---------------------------------------
{
**Theil Index

use "$datasets/Patentsview_lev_dataset.dta", clear



if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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



drop if ipc3==""
drop if appyear==.
*only include patents with assignees
drop if asgnum==""

keep appyear patent ipc3 asgnum

gen ipc1=substr(ipc3,1,1)

**1. Compute E, na, N, Ea as before

*aggregate shares 
bys appyear: gen N_pat=_N
bys appyear ipc1: gen n_ipc1=_N
bys appyear ipc3: gen n_ipc3=_N

gen s_ipc1=n_ipc1/N_pat
gen s_ipc3=n_ipc3/N_pat

bys appyear ipc1: gen ent_ipc1=s_ipc1*log(1/s_ipc1)
bys appyear ipc3: gen ent_ipc3=s_ipc3*log(1/s_ipc3)

bys appyear: gen dyear=1 if appyear[_n]!=appyear[_n-1]
bys appyear ipc1: gen dipc1_year=1 if ipc1[_n]!=ipc1[_n-1]
bys appyear ipc3: gen dipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

bys appyear: egen E_ipc1=sum(dipc1_year*ent_ipc1)
bys appyear: egen E_ipc3=sum(dipc3_year*ent_ipc3)

*assignee shares
bys appyear asgnum: gen Npat_asg=_N
bys appyear asgnum ipc1: gen n_asg_ipc1=_N
bys appyear asgnum ipc3: gen n_asg_ipc3=_N

gen s_asg_ipc1=n_asg_ipc1/Npat_asg
gen s_asg_ipc3=n_asg_ipc3/Npat_asg

bys appyear asgnum ipc1: gen ent_asg_ipc1=s_asg_ipc1*log(1/s_asg_ipc1)
bys appyear asgnum ipc3: gen ent_asg_ipc3=s_asg_ipc3*log(1/s_asg_ipc3)

bys appyear asgnum: gen dasg_year=1 if asgnum[_n]!=asgnum[_n-1]
bys appyear asgnum ipc1: gen dasg_ipc1_year=1 if ipc1[_n]!=ipc1[_n-1]
bys appyear asgnum ipc3: gen dasg_ipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

*compute Ea
bys appyear asgnum: egen E_asg_ipc1=sum(dasg_ipc1_year*ent_asg_ipc1)
bys appyear asgnum: egen E_asg_ipc3=sum(dasg_ipc3_year*ent_asg_ipc3)

**2. Define Groups 

*Patenting by year
bys appyear: egen p90_pat=pctile(dasg_year*Npat_asg), p(90)
bys appyear: egen p99_pat=pctile(dasg_year*Npat_asg), p(99)

gen group=1 if Npat_asg<p90_pat
	replace group=2 if Npat_asg>=p90_pat & Npat_asg<p99_pat
	replace group=3 if Npat_asg>=p99_pat & Npat_asg!=.
	
label define lbl_g 1 "Below p90" 2 "[p90,p99]"  3 "Top 1%"

label values group lbl_g

/*

local ng 1000

**Firm size

*temporary dataset to define groups 
preserve
	duplicates drop appyear asgnum, force
	*create ranking
	bys appyear (Npat_asg): gen group = int(`ng'*(_n-1)/_N)+1
	keep appyear asgnum group
	save "$wrkdata/temp_rank", replace
restore

*merge group info and erase file
merge m:1 appyear asgnum using "$wrkdata/temp_rank.dta"
drop _merge
erase "$wrkdata/temp_rank.dta"
*/

**3. By groups compute: 


*group shares
bys appyear group: gen N_g=_N
bys appyear group ipc1: gen n_g_ipc1=_N
bys appyear group ipc3: gen n_g_ipc3=_N

gen s_g_ipc1=n_g_ipc1/N_g
gen s_g_ipc3=n_g_ipc3/N_g

bys appyear group ipc1: gen ent_g_ipc1=s_g_ipc1*log(1/s_g_ipc1)
bys appyear group ipc3: gen ent_g_ipc3=s_g_ipc3*log(1/s_g_ipc3)

bys appyear group: gen dg_year=1 if group[_n]!=group[_n-1]
bys appyear group ipc1: gen dg_ipc1_year=1 if ipc1[_n]!=ipc1[_n-1]
bys appyear group ipc3: gen dg_ipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

bys appyear group: egen E_g_ipc1=sum(dg_ipc1_year*ent_g_ipc1)
bys appyear group: egen E_g_ipc3=sum(dg_ipc3_year*ent_g_ipc3)



** 4. Compute decomposition: Within and Between groups

*Between groups
bys appyear: egen H_B_ipc1=sum((N_g/N_pat)*dg_year*(E_ipc1-E_g_ipc1)/E_ipc1)
bys appyear: egen H_B_ipc3=sum((N_g/N_pat)*dg_year*(E_ipc3-E_g_ipc3)/E_ipc3)

*Within groups
bys appyear group: egen H_g_ipc1=sum((Npat_asg/N_g)*dasg_year*(E_g_ipc1-E_asg_ipc1)/E_g_ipc1)
bys appyear group: egen H_g_ipc3=sum((Npat_asg/N_g)*dasg_year*(E_g_ipc3-E_asg_ipc3)/E_g_ipc3)

bys appyear: egen H_W_ipc1=sum((N_g/N_pat)*(E_g_ipc1/E_ipc1)*dg_year*H_g_ipc1)
bys appyear: egen H_W_ipc3=sum((N_g/N_pat)*(E_g_ipc3/E_ipc3)*dg_year*H_g_ipc3)


** 5. Total Theil Index and comparison

bys appyear : egen H_ipc1=sum((Npat_asg/N_pat)*dasg_year*(E_ipc1-E_asg_ipc1)/E_ipc1)
bys appyear : egen H_ipc3=sum((Npat_asg/N_pat)*dasg_year*(E_ipc3-E_asg_ipc3)/E_ipc3)

bys appyear : gen H2_ipc1=H_B_ipc1+H_W_ipc1
bys appyear : gen H2_ipc3=H_B_ipc3+H_W_ipc3


gen invE_ipc1=1/E_ipc1
gen invE_ipc3=1/E_ipc3

gen invE_g_ipc1=1/E_g_ipc1
gen invE_g_ipc3=1/E_g_ipc3


global pl_fyear 2015

***Plots
	
**Entropy

*IPC1
twoway (connected  E_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC1 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  invE_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC1 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  E_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC3 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  invE_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC3 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

**Aggregate Theil index for Assignees

*IPC1
twoway (connected  H_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc1`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  H_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}



**Decomposition: Theil index for Assignees

*local lsave_str _ng`ng'

local lsave_str _gr2_asg

*IPC1
/*
twoway (line  H_ipc1 appyear , yaxis(1) lcolor(black) lwidth(medthick) ytitle("Theil Index IPC1 ",height(8) size($size_font)) yscale(range(0.5 0.58) axis(1)) ylabel(#10,axis(1)) ) ///
(connected  H_W_ipc1 appyear, yaxis(1) lcolor(maroon) lwidth(medthick) ms(D) mcolor(maroon)) ///
(connected  H_B_ipc1 appyear , yaxis(2) lcolor(navy) lwidth(medthick) mcolor(navy) ytitle(" Theil Index IPC1 ", axis(2) height(8) size($size_font)) yscale(range(0 0.03) axis(2)) ylabel(#10,axis(2)))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ////
xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Total") label(2 "Within") label(3 "Between (Right Axis)" ) )
*/

twoway (line  H_ipc1 appyear , lcolor(black) lwidth(medthick)) ///
(connected  H_B_ipc1 appyear , lcolor(navy) lwidth(medthick) mcolor(navy)) (connected  H_W_ipc1 appyear, lcolor(maroon) lwidth(medthick) ms(D) mcolor(maroon)) if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Decompostion Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Total") label(2 "Between") label(3 "Within" ) )

if $save_fig==1 {
graph export "$figfolder/deco_H_ipc1`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  H_W_ipc1 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Within Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_W_ipc1`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway (connected  H_B_ipc1 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Between Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_B_ipc1`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*IPC3
twoway (line  H_ipc3 appyear , lcolor(black) lwidth(medthick)) ///
(connected  H_B_ipc3 appyear , lcolor(navy) lwidth(medthick) mcolor(navy)) (connected  H_W_ipc3 appyear, lcolor(maroon) lwidth(medthick) ms(D) mcolor(maroon)) if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Decompostion Theil Index IPC3 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Total") label(2 "Between") label(3 "Within" ) )

if $save_fig==1 {
graph export "$figfolder/deco_H_ipc3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


twoway (connected  H_W_ipc3 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Within Theil Index IPC3 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_W_ipc3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
twoway (connected  H_B_ipc3 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Decompostion Theil Index IPC3 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_B_ipc3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


** Entropy and Theil index by groups

levelsof group , local(lgroup)

local pl_str 
local lab_str
local i=1

local lab : value label group

foreach ig of local lgroup{
local lbl_str `: label `lab' `ig''

local pl_str_E_g_ipc1  `pl_str_E_g_ipc1' (connected  E_g_ipc1 appyear if group==`ig')
local pl_str_E_g_ipc3  `pl_str_E_g_ipc3' (connected  E_g_ipc3 appyear if group==`ig')

local pl_str_invE_g_ipc1  `pl_str_invE_g_ipc1' (connected  invE_g_ipc1 appyear if group==`ig')
local pl_str_invE_g_ipc3  `pl_str_invE_g_ipc3' (connected  invE_g_ipc3 appyear if group==`ig')

local pl_str_H_g_ipc1  `pl_str_H_g_ipc1' (connected  H_g_ipc1 appyear if group==`ig')
local pl_str_H_g_ipc3  `pl_str_H_g_ipc3' (connected  H_g_ipc3 appyear if group==`ig')

local lab_str  `lab_str' label( `i' "`lbl_str'") 
local i=`i'+1

}

*Entropy

twoway  `pl_str_E_g_ipc1' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC1 (Diversity)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_g_ipc1`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway  `pl_str_E_g_ipc3' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC3 (Diversity)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_g_ipc3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Inverse Entropy
twoway  `pl_str_invE_g_ipc1' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC1 (Specialization)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_g_ipc1`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway  `pl_str_invE_g_ipc3' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC3 (Specialization)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_g_ipc3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Theil
twoway  `pl_str_H_g_ipc1' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_g_ipc1`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway  `pl_str_H_g_ipc3' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC3",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_g_ipc3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

*-----------------------
* Variables by groups
*-----------------------
{

use "$datasets/Patentsview_lev_dataset.dta", clear


if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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



drop if appyear<=$iyear | appyear==.

drop if asgnum==""

bys appyear asgnum: gen Npat_asg=_N
bys appyear asgnum: gen dasg_year=1 if asgnum[_n]!=asgnum[_n-1]


*Defining groups
local lsave_str _gr2_asg

*Patenting by year
bys appyear: egen p90_pat=pctile(dasg_year*Npat_asg), p(90)
bys appyear: egen p99_pat=pctile(dasg_year*Npat_asg), p(99)

gen group=1 if Npat_asg<p90_pat
	replace group=2 if Npat_asg>=p90_pat & Npat_asg<p99_pat
	replace group=3 if Npat_asg>=p99_pat & Npat_asg!=.
	
label define lbl_g 1 "Below p90" 2 "[p90,p99]"  3 "Top 1%"

label values group lbl_g



collapse (mean) tsize m_ttb cit3 f_cit3 survive, by(appyear group)


levelsof group , local(lgroup)

local lab_str
local i=1

local lab : value label group

foreach ig of local lgroup{
local lbl_str `: label `lab' `ig''


local pl_str_tsize  `pl_str_tsize' (connected  tsize appyear if group==`ig')
local pl_str_m_ttb  `pl_str_m_ttb' (connected  m_ttb appyear if group==`ig')
local pl_str_survive  `pl_str_survive' (connected  survive appyear if group==`ig')

local pl_str_cit3  `pl_str_cit3' (connected  cit3 appyear if group==`ig')
local pl_str_f_cit3  `pl_str_f_cit3' (connected  f_cit3 appyear if group==`ig')

local lab_str  `lab_str' label( `i' "`lbl_str'") 
local i=`i'+1

}


*Team size
twoway `pl_str_tsize' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/tsize`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Time to build

twoway `pl_str_m_ttb' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/m_ttb`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

*Survival


twoway `pl_str_survive' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Survival",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/survive`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}


*Citations

twoway `pl_str_cit3' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations (Adjusted)",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/cit3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

twoway `pl_str_f_cit3' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/f_cit3`lsave_str'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

*------------------------------------------------------------
* Mobility of Assignees: Transition Probabilities
*------------------------------------------------------------
{
 global pl_fyear 2014

*load assignee level strongly balanced panel

use "$datasets/main_asg_lev_bp_Patentsview.dta", clear

bys appyear: gen dyear=1 if appyear[_n]!=appyear[_n-1]

gen dpatented=1 if Npat_asg>0


*Defining groups
global save_str_gr _gr2_asg

*Patenting by year
bys appyear: egen p90_pat=pctile(dpatented*Npat_asg), p(90)
bys appyear: egen p99_pat=pctile(dpatented*Npat_asg), p(99)

gen group=1 if Npat_asg<p90_pat
	replace group=2 if Npat_asg>=p90_pat & Npat_asg<p99_pat
	replace group=3 if Npat_asg>=p99_pat & Npat_asg!=.
	replace group=0 if Npat_asg==0
	

bys appyear group: gen dg_year=1 if group[_n]!=group[_n-1]
bys appyear group: egen Nasg_g=count(asgnum)
	
label define lbl_g 1 "Below p90" 2 "Between p90 and p99"  3 "Top 1%" 0 "No Patents", replace

label values group lbl_g



*Number of assignee in top group

twoway connected Nasg_g appyear if group==3 & dg_year==1  & appyear<=$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Assignees ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/Nasg_g$save_str_gr.pdf", replace as(pdf)
}


*Future group and lagged group

bys asgnum (appyear) :  gen group_f=group[_n+1]
bys asgnum (appyear) :  gen group_l=group[_n-1]

label values group_f lbl_g
label values group_l lbl_g

**By year

levelsof appyear, local(lyear)

foreach iyear of local lyear {

local fyear=`iyear'+1
 

label var group "Groups `iyear'"
label var group_f "Groups `fyear'"

if `iyear'<2015 {
*percentage
tabout  group group_f  if (group>0 | group_f>0 )& appyear==`iyear' ///
using "$tabfolder/tab_tmat_asg_`iyear'$save_str_gr.tex", replace style(tex)  ptotal(none) cells(row) f(1p)  h3(nil)

*frequency
tabout  group group_f  if (group>0 | group_f>0 )& appyear==`iyear' ///
using "$tabfolder/tab_freq_tmat_asg_`iyear'$save_str_gr.tex", replace style(tex)  ptotal(none) cells(freq) f(0)  h3(nil)
}

}

label var group "Groups t"
label var group_f "Groups t+1"
label var group_l "Groups t-1"



**Define transtion groups

gen trans_g=1 if group==0 & group_f==1
	replace trans_g=2 if group==0 & group_f==2
	replace trans_g=3 if group==0 & group_f==3
	
	replace trans_g=10 if group==1 & group_f==0
	replace trans_g=11 if group==1 & group_f==1
	replace trans_g=12 if group==1 & group_f==2
	replace trans_g=13 if group==1 & group_f==3
	
	replace trans_g=20 if group==2 & group_f==0
	replace trans_g=21 if group==2 & group_f==1
	replace trans_g=22 if group==2 & group_f==2
	replace trans_g=23 if group==2 & group_f==3
	
	replace trans_g=30 if group==3 & group_f==0
	replace trans_g=31 if group==3 & group_f==1
	replace trans_g=32 if group==3 & group_f==2
	replace trans_g=33 if group==3 & group_f==3
	
replace trans_g=0 if trans_g==.
	
label define lbl_trans_g 1 "No Patents → Below p90" 2 "No Patents → [p90,p99]"  3 " No Patents → Top 1%" ///
10 "Below p90 → No Patents" 11 "Below p90 → Below p90"  12 " Below p90 → [p90,p99]" 13 " Below p90 → Top 1%" ///
20 "[p90,p99] → No Patents" 21 "[p90,p99] → Below p90"  22 " [p90,p99] → [p90,p99]" 23 " [p90,p99] → Top 1%" ///
30 "Top 1% → No Patents" 31 "Top 1% → Below p90"  32 " Top 1% → [p90,p99]" 33 " Top 1% → Top 1%" , replace

label values trans_g lbl_trans_g

bys appyear trans_g: gen dtrans_g_year=1 if trans_g[_n]!=trans_g[_n-1]


gen group2=group 
	replace group2=. if group==0 & group_f==0
	
	

**Transition Probabilities

bys appyear trans_g : egen Nasg_trans_g=count(asgnum)
bys appyear group2 : egen Nasg_g2=count(asgnum)

gen trans_pr_g2=Nasg_trans_g/Nasg_g2


keep if dtrans_g_year==1

*declare the panel and fill the missing observations
tsset trans_g appyear
tsfill, full

replace trans_pr_g2=0 if trans_pr_g2==.


**Shorrocks index

*Not including in and out
gen temp=trans_pr_g2 if trans_g==11
	bys appyear: egen trans_pr_11=max(temp)
	drop temp
gen temp=trans_pr_g2 if trans_g==22
	bys appyear: egen trans_pr_22=max(temp)
	drop temp
gen temp=trans_pr_g2 if trans_g==33
	bys appyear: egen trans_pr_33=max(temp)
	drop temp
	
quietly: distinct group

local ng=`r(ndistinct)'-1

*bys appyear: egen trace=
bys appyear: gen M=(`ng'-(trans_pr_11+ trans_pr_22+ trans_pr_33))/(`ng'-1)

local var M "Shorrock's Mobility Index"


*Diagonal
twoway (connected trans_pr_g2 appyear if trans_g==11) (connected trans_pr_g2 appyear if trans_g==22) (connected trans_pr_g2 appyear if trans_g==33) if appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Transition Probability (t → t+1) ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "Stay Below p90") label(2 "Stay [p90,p99]") label(3 "Stay Top 1%") )

if $save_fig ==1 {
graph export "$figfolder/tr_stay$save_str_gr.pdf", replace as(pdf)
}


*-> Out
twoway (connected trans_pr_g2 appyear if trans_g==10) (connected trans_pr_g2 appyear if trans_g==20) (connected trans_pr_g2 appyear if trans_g==30 )  if appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Transition Probability (t → t+1) ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "Below p90 → No Patents") label(2 "[p90, p99] → No Patents") label(3 "Top 1% → No Patents") )

if $save_fig ==1 {
graph export "$figfolder/tr_out$save_str_gr.pdf", replace as(pdf)
}

*-> In
twoway (connected trans_pr_g2 appyear if trans_g==1) (connected trans_pr_g2 appyear if trans_g==2) (connected trans_pr_g2 appyear if trans_g==3)  if appyear<=$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Transition Probability (t → t+1) ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "No Patents → Below p90  ") label(2 "No Patents → [p90, p99]") label(3 "No Patents → Top 1%") )

if $save_fig ==1 {
graph export "$figfolder/tr_in$save_str_gr.pdf", replace as(pdf)
}

*Upward Mobility
twoway (connected trans_pr_g2 appyear if trans_g==12) (connected trans_pr_g2 appyear if trans_g==13) (connected trans_pr_g2 appyear if trans_g==23) if appyear<=$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Transition Probability (t → t+1) ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "Below p90 → [p90, p99] ") label(2 "Below p90 →Top 1%") label(3 "[p90, p99] → Top 1%") )

if $save_fig ==1 {
graph export "$figfolder/tr_up$save_str_gr.pdf", replace as(pdf)
}

*Downward Mobility
twoway (connected trans_pr_g2 appyear if trans_g==21) (connected trans_pr_g2 appyear if trans_g==32) (connected trans_pr_g2 appyear if trans_g==31)  if appyear<=$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Transition Probability (t → t+1) ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "[p90, p99]→ Below p90  ") label(2 "Top 1% →[p90, p99] ") label(3 "Top 1% → Below p90 ") )

if $save_fig ==1 {
graph export "$figfolder/tr_down$save_str_gr.pdf", replace as(pdf)
}

*Shorrock's Mobility Index

twoway connected M appyear   if appyear<=$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Shorrock's Mobility Index ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) 

if $save_fig ==1 {
graph export "$figfolder/M$save_str_gr.pdf", replace as(pdf)
}


}



*----------------------------------------------------
*Entry and Exit of Assignees
*----------------------------------------------------
{
global piyear 1980
global pfyear 2005

use "$data/main_pat_lev_CP$save_str.dta", clear

drop if appyear==.
drop if asgnum==""

sort asgnum appyear

*Indicators
bys appyear: gen dyear=1 if appyear[_n-1]!=appyear[_n]
bys appyear asgnum: gen dasg_yr=1 if asgnum[_n-1]!=asgnum[_n] 

bys appyear: egen Nasg_yr=total(dasg_yr)

*Survival of assignee to next period
bys asgnum (appyear): gen ds_asg=1 if appyear[_n+1]==appyear[_n]+1

bys appyear: egen Ns_asg_yr=total(ds_asg)

*Probability of survival and exit
gen pr_s_asg=Ns_asg_yr/Nasg_yr
gen pr_exit_asg=1-pr_s_asg

*Assignee age
bys asgnum  : egen iyear_asg=min(appyear)
gen asg_age=appyear-iyear_asg

bys appyear asgnum: gen dentry=1 if asgnum[_n-1]!=asgnum[_n] & asg_age==0 

bys appyear: egen Nentry_asg_yr=total(dentry)

*Fraction of entry assignees
gen frac_entry=Nentry_asg_yr/Nasg_yr



*Probability of survival
twoway (connected  pr_s_asg appyear, lcolor(navy) lwidth(medthick)) if dyear==1  & appyear>=$iyear & appyear<=$pfyear, ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pfyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Probability of Survival to Next Period",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) 

if $save_fig==1 {
graph export "$figfolder/pr_s_asg.pdf", replace as(pdf)
}

*Probability of exit
twoway (connected  pr_exit_asg appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear>=$iyear & appyear<=$pfyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pfyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Probability of Exit Next Period",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) 

if $save_fig==1 {
graph export "$figfolder/pr_exit_asg.pdf", replace as(pdf)
}

* Fraction of new entrants
twoway (connected  frac_entry appyear, lcolor(navy) lwidth(medthick)) if dyear==1  & appyear>=$piyear & appyear<=$pfyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($piyear (5)$pfyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of First Time Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) 

if $save_fig==1 {
graph export "$figfolder/frac_entry.pdf", replace as(pdf)
}


}

}


*******************************************
*Comparison on distribution of Cites
*******************************************

{

global fyear_pl 2015

*--------------------------------------
* Distributuion of Forward Citations
*------------------------------------------
{
use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

egen pat=group(patent)

rename patent patst
rename pat patent

gen ipc1=substr(ipc3,1,1)

drop if ipc1==""

local num 3 5

foreach i of local num {

*Unadjusted
bys appyear ipc1: egen f_cit`i'_p99=pctile(f_cit`i'), p(99)
bys appyear ipc1: egen f_cit`i'_p995=pctile(f_cit`i'), p(99.5)
bys appyear ipc1: egen f_cit`i'_p999=pctile(f_cit`i'), p(99.9)
bys appyear ipc1: egen f_cit`i'_p9999=pctile(f_cit`i'), p(99.99)

bys appyear ipc1: egen f_cit`i'_p25=pctile(f_cit`i'), p(25)
bys appyear ipc1: egen f_cit`i'_p50=pctile(f_cit`i'), p(50)
bys appyear ipc1: egen f_cit`i'_p75=pctile(f_cit`i'), p(75)
bys appyear ipc1: egen f_cit`i'_p90=pctile(f_cit`i'), p(90)

}


*Figures by IPC and Appyear
collapse (mean) f_cit3* f_cit5* , by(appyear ipc1)

	
forvalues g=3(2)5{ 
	local y 25 50 75 90 99 995 999 9999
foreach k of local y{

local i=1
local pl_n_str 

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  f_cit`g'_p`k' appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_n_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`g' - Year Forward Citations P `k'",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dist_fcit`g'_p`k'_ipc`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
}
}


forvalues g=3(2)5{ 

local i=1
local pl_n_str 
*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  f_cit`g' appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_n_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`g' - Year Forward Citations ",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/dist_fcit`g'_ipc`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
}



*Figures by Appyear 
collapse (mean) f_cit3* f_cit5* , by(appyear)

local tail 0

if `tail'==0 {
local y 25 50 75 90
local start 25
local final 90
}

if `tail'==1 {
local y 99 995 999 9999
local start 99
local final 9999
}


forvalues g=3(2)5{ 

*initialize locals
local j 1
local pl_str


foreach i of local y {
 
local pl_str  `pl_str' (connected  f_cit`g'_p`i' appyear)
local lab_str  `lab_str' label( `j' "Percentile `i'") 
local j=`j'+1
 
 }
 
 
*percentiles
twoway `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font))  ///
ytitle("`g' - Year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  legend(region(lcolor(white)) `lab_str' cols(2))

if $save_fig==1 {
graph export "$figfolder/dist_fcit`g'_p`start'_p`final'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

}

*-----------------------------------------------------
* Share of Assignees with Zero 3 and 5 Forward Cites
*----------------------------------------------------

{
use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

gen d_cit3_zero=(f_cit3==0)
gen d_cit5_zero=(f_cit5==0)


*Figures by Appyear
collapse (mean) d_cit3_zero d_cit5_zero , by(appyear)

forvalues g=3(2)5{ 
replace d_cit`g'_zero=d_cit`g'_zero*100
}



forvalues g=3(2)5{ 
twoway (connected  d_cit`g'_zero appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font))  ///
ytitle("% Assignees with zero `g' - Year Forward Citations",height(6) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  legend(region(lcolor(white)) `lab_str' cols(2))

if $save_fig==1 {
graph export "$figfolder/s_asg_cit`g'_zero.pdf", replace as(pdf)
}
}
}


*---------------------------------------
* Distributuion of Backward Citations
*---------------------------------------
{


use "$datasets/Patentsview_lev_dataset.dta", clear

if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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

egen pat=group(patent)

rename patent patst
rename pat patent

gen ipc1=substr(ipc3,1,1)

drop if ipc1==""

*Unadjusted
bys appyear ipc1: egen b_cit_p99=pctile(b_cit), p(99)
bys appyear ipc1: egen b_cit_p995=pctile(b_cit), p(99.5)
bys appyear ipc1: egen b_cit_p999=pctile(b_cit), p(99.9)
bys appyear ipc1: egen b_cit_p9999=pctile(b_cit), p(99.99)

bys appyear ipc1: egen b_cit_p25=pctile(b_cit), p(25)
bys appyear ipc1: egen b_cit_p50=pctile(b_cit), p(50)
bys appyear ipc1: egen b_cit_p75=pctile(b_cit), p(75)
bys appyear ipc1: egen b_cit_p90=pctile(b_cit), p(90)



*Figures by IPC and Appyear
collapse (mean) b_cit*, by(appyear ipc1)

	drop b_cit_asg_sc b_cit_ipc3_sc
	
local y 25 50 75 90 99 995 999 9999
foreach k of local y{

local i=1
local pl_n_str 

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  b_cit_p`k' appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


twoway  `pl_n_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Backward Citations P `k'",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dist_bcit_p`k'_ipc`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}
}



local i=1
local pl_n_str 
*Number and share of patents by IPC1
levelsof ipc1, local(levels) 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  b_cit appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_n_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Backward Citations ",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/dist_bcit_ipc`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}




*Figures by Appyear 
collapse (mean) b_cit* , by(appyear)

local tail 0

if `tail'==0 {
local y 25 50 75 90
local start 25
local final 90
}

if `tail'==1 {
local y 99 995 999 9999
local start 99
local final 9999
}

*initialize locals
local j 1
local pl_str


foreach i of local y {
 
local pl_str  `pl_str' (connected  b_cit_p`i' appyear)
local lab_str  `lab_str' label( `j' "Percentile `i'") 
local j=`j'+1
 
 }
 
 
*percentiles
twoway `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font))  ///
ytitle("Backward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  legend(region(lcolor(white)) `lab_str' cols(2))

if $save_fig==1 {
graph export "$figfolder/dist_bcit_p`start'_p`final'`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'`org_save_str'.pdf", replace as(pdf)
}

}

}