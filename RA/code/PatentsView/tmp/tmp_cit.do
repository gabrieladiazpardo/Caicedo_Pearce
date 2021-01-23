*----------------------------------------------------
*Distribution and Tail of Number of Patents per Assignee by Year
*----------------------------------------------------



graph set window fontface "Garamond"
global size_font med // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots
global fyear_pl 2015


//////////////////////////////////////////////////
//////		Distributuion of Forward Citations
///////////////////////////////////////////////////

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




///////////////////////////////////
//////		Org. Assg.
/////////////////////////////////

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



///////////////////////////////////////////////////
//////		Distributuion of Backward Citations
///////////////////////////////////////////////////
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
