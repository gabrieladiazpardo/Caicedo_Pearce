*Exploration Facts
*Fall 2020

set more off

global main "/Users/JeremyPearce/Dropbox"
*global main "D:/Dropbox/santiago/Research"

**Folders
global data "$main/Caicedo_Pearce/data/output"
global wrkdata "$main/Caicedo_Pearce/data/wrkdata"
global outdata "$main/Caicedo_Pearce/data/output"

global figfolder "$main/Caicedo_Pearce/notes/figures"

**Saving options
global save_fig 1 //  0 //

*save string: data version
global save_str _SC

**Graph options
*cd D:\Dropbox\Santiago\Stata\ado\personal
*set scheme scheme_papers  // Larger axis labels, tick labels, 
graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2010 //final year of plots



***first, maybe use the dataset with newest IPC categories--



*1: 

use "$outdata/main_CP.dta",clear
merge m:1 patent using "$outdata/dates_CP.dta"
drop _m
drop ipc*
merge m:1 patent using "$wrkdata/patent_ipc3_100.dta"
keep if _m==3
drop _m

gen ipc1=substr(ipc3,1,1)

***OVERALL

preserve
keep if appyear>$iyear & appyear<$fyear
duplicates drop patent, force
gen dum=1
collapse (sum) dum, by(ipc1 appyear)
bys appyear: egen tot_dum=total(dum)
gen share=dum/tot_dum
levelsof ipc1, local(levels) 

*initialize locals
local i=1
local pl_str
local lab_str 

foreach l of local levels{
local pl_str  `pl_str' (connected  dum appyear if ipc1=="`l'")
local pl_str2  `pl_str2' (connected  share appyear if ipc1=="`l'")

local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Patent Count",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/pearce/patent_count_ipc.pdf",replace



twoway  `pl_str2' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Patent Share",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/pearce/patent_share_ipc.pdf",replace


restore



preserve
keep if appyear>$iyear & appyear<$fyear
duplicates drop patent, force

*only firms with more than X patents
bys appyear asgnum: gen tot_asg=_N

*keep if tot_asg>50

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
bys appyear asgnum: gen N_asg=_N
bys appyear asgnum ipc1: gen n_asg_ipc1=_N
bys appyear asgnum ipc3: gen n_asg_ipc3=_N

gen s_asg_ipc1=n_asg_ipc1/N_asg
gen s_asg_ipc3=n_asg_ipc3/N_asg

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

bys appyear : egen H_ipc1=sum((N_asg/N_pat)*dasg_year*(E_ipc1-E_asg_ipc1)/E_ipc1)
bys appyear : egen H_ipc3=sum((N_asg/N_pat)*dasg_year*(E_ipc3-E_asg_ipc3)/E_ipc3)

gen invE_ipc1=1/E_ipc1
gen invE_ipc3=1/E_ipc3


global pl_fyear 2010
	
**Entropy

*IPC1
twoway (connected  invE_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse Entropy IPC1 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/pearce/inv_entropy_ipc1_total.pdf",replace


*IPC3
twoway (connected  invE_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse Entropy IPC3 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/pearce/inv_entropy_ipc3_total.pdf",replace



*2: WITHIN CATEGORY 
levelsof ipc1, local(levels) 

foreach l of local levels{

preserve


keep if appyear>$iyear & appyear<$fyear & ipc1=="`l'"
duplicates drop patent, force

*only firms with more than X patents
bys appyear asgnum: gen tot_asg=_N

*keep if tot_asg>50

sort appyear patent

*aggregate shares 
bys appyear: gen N_pat=_N
bys appyear ipc3: gen n_ipc3=_N

gen s_ipc3=n_ipc3/N_pat

bys appyear ipc3: gen ent_ipc3=s_ipc3*log(1/s_ipc3)

bys appyear: gen dyear=1 if appyear[_n]!=appyear[_n-1]
bys appyear ipc3: gen dipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

bys appyear: egen E_ipc3=sum(dipc3_year*ent_ipc3)

*assignee shares
bys appyear asgnum: gen N_asg=_N
bys appyear asgnum ipc3: gen n_asg_ipc3=_N

gen s_asg_ipc3=n_asg_ipc3/N_asg

/*
bys appyear asgnum ipc1: gen ent_asg_ipc1=s_asg_ipc1*log(s_asg_ipc1/s_ipc1)
bys appyear asgnum ipc3: gen ent_asg_ipc3=s_asg_ipc3*log(s_asg_ipc3/s_ipc3)
*/

bys appyear asgnum ipc3: gen ent_asg_ipc3=s_asg_ipc3*log(1/s_asg_ipc3)

bys appyear asgnum: gen dasg_year=1 if asgnum[_n]!=asgnum[_n-1]
bys appyear asgnum ipc3: gen dasg_ipc3_year=1 if ipc3[_n]!=ipc3[_n-1]

bys appyear asgnum: egen E_asg_ipc3=sum(dasg_ipc3_year*ent_asg_ipc3)

	
bys appyear : egen T_asg=sum(dasg_year)

bys appyear : egen H_ipc3=sum((N_asg/N_pat)*dasg_year*(E_ipc3-E_asg_ipc3)/E_ipc3)

gen invE_ipc3=1/E_ipc3


global pl_fyear 2010
	
**Entropy

*IPC3
twoway (connected  invE_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse Entropy IPC3,  (Specialization `l')",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/pearce/inv_entropy_ipc3_total_`l'.pdf",replace
restore


}







***for individuals, what's the probability they repeat IPCs?

egen g_ipc=group(ipc3)
xtset categ1 patnumpp1
gen is_repeat=.
replace is_repeat=1 if L.g_ipc==g_ipc
replace is_repeat=0 if L.g_ipc~=g_ipc & L.g_ipc~=.

gen is_team=0
replace is_team=1 if tsize>1
drop if tsize==.


gen team_prop=1/tsize
bys is_team appyear: egen count_team=total(team_prop)
replace ttbc2=exp_cit/m_ttb
foreach local in is_repeat m_ttb ttbc2 invh_cit exp_cit count_team survive patnumpp1{
xtset categ1 patnumpp1
preserve
**keep all
collapse `local', by(appyear is_team)
global pl_fyear1 1980
global fyear 2007
twoway (connected  `local' appyear if is_team==0, lcolor(navy) lwidth(medthick)) (connected  `local' appyear if is_team==1, lcolor(maroon) lwidth(medthick)) if appyear>$iyear & appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`local', Individual",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Alone" 2 "In Team"))
graph export "$figfolder/pearce/`local'_team_noteam.pdf",replace
restore

preserve
keep if L.is_team==0
collapse `local', by(appyear is_team)
global pl_fyear1 1980
global fyear 2007
twoway (connected  `local' appyear if is_team==0, lcolor(navy) lwidth(medthick)) (connected  `local' appyear if is_team==1, lcolor(maroon) lwidth(medthick)) if appyear>$iyear & appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`local', Individual",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Alone" 2 "In Team"))
graph export "$figfolder/pearce/`local'_team_noteam_Lno.pdf",replace
restore

preserve
keep if L.is_team==1
collapse `local', by(appyear is_team)
global pl_fyear1 1980
global fyear 2007
twoway (connected  `local' appyear if is_team==0, lcolor(navy) lwidth(medthick)) (connected  `local' appyear if is_team==1, lcolor(maroon) lwidth(medthick)) if appyear>$iyear & appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`local', Individual",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Alone" 2 "In Team"))
graph export "$figfolder/pearce/`local'_team_noteam_Lyes.pdf",replace
restore

preserve
**only keep 2 of 4 quadrants
keep if is_team==L.is_team
collapse `local', by(appyear is_team)
global pl_fyear1 1980
global fyear 2007
twoway (connected  `local' appyear if is_team==0, lcolor(navy) lwidth(medthick)) (connected  `local' appyear if is_team==1, lcolor(maroon) lwidth(medthick)) if appyear>$iyear & appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`local', Individual",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Alone" 2 "In Team"))
graph export "$figfolder/pearce/`local'_team_noteam_LeqT.pdf",replace
restore
}







***NEXT WE COULD LOOK AT FIRMS (W/ PATENT APPLIED IN LAST 20 YEARS) across categories 






*****************************************
* Facts 0: From Pearce (2020) Appendix
*****************************************
{
*-------------
* Team size 
*-------------

***Team size over time

use "$data/main_pat_lev_CP$save_str.dta", clear

drop if appyear<=$iyear

collapse (mean) tsize , by(appyear)

twoway (connected  tsize appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/team_size.pdf", replace as(pdf)
}

***Team size over time by ipc1

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/team_size_ipc1.pdf", replace as(pdf)
}

***Team size distribution

use "$data/main_pat_lev_CP$save_str.dta", clear


local maxtsize 10
local dtsize=round(`maxtsize'/10)

gen tsize_mod=tsize
	replace tsize_mod=`maxtsize' if tsize>`maxtsize' & tsize!=.

keep appyear tsize_mod

twoway histogram tsize_mod , bcolor(navy) width(1) gap(20) start(1) discrete ///
graphregion(color(white)) bgcolor(white) xtitle("Team Size",height(8) size($size_font)) xlabel(0(`dtsize')`maxtsize', labsize($size_font)) ///
ylabel(, nogrid labsize($size_font)) ytitle("Density",height(8) size($size_font)) 

if $save_fig==1 {
graph export "$figfolder/team_size_hist.pdf", replace as(pdf)
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
graph export "$figfolder/team_size_hist`l'.pdf", replace as(pdf)
}

}

*--------------------
* Depth and breadth 
*--------------------

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

}
*****************************************
* Facts 1: Explorations
*****************************************
{
*-----------------------
* Time to build patents 
*-----------------------

*** Time to build patent for each year

use "$data/main_pat_lev_CP$save_str.dta", clear

collapse (mean) m_ttb  , by(appyear)

twoway (connected  m_ttb appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build (Average of Team)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ttb_team.pdf", replace as(pdf)
}

*** Time to build patent for each year by team size

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/ttb_team_ts.pdf", replace as(pdf)
}


*** Time to build patent for each year by sector 

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/ttb_team_ipc1.pdf", replace as(pdf)
}

*-----------------------
* Surviving Teams
*-----------------------

*** Surviving teams for each year

use "$data/main_pat_lev_CP$save_str.dta", clear

collapse (mean) survive , by(appyear)

twoway (connected  survive appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Surviving Team",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/survive.pdf", replace as(pdf)
}

*** Time to build patent for each year by team size

use "$data/main_pat_lev_CP$save_str.dta", clear

gen tsize2=tsize if tsize<=5
	replace tsize2=5 if tsize>5

collapse (mean) survive  , by(appyear tsize2)

twoway (connected  survive appyear if tsize2==2, lwidth(medthick)) (connected  survive appyear if tsize2==3, lwidth(medthick)) ///
(connected  survive appyear if tsize2==4, lwidth(medthick)) (connected  survive appyear if tsize2==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Surviving Team",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "2-person") label( 2 "3-person") label( 3 "4-person") label( 4 "5-person or more") size(med) ) 

if $save_fig==1 {
graph export "$figfolder/survive_ts.pdf", replace as(pdf)
}


*** Time to build patent for each year by sector 

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/survive_ipc1.pdf", replace as(pdf)
}


*--------------------------------------
* Patent quality and team productivity
*--------------------------------------


***Patent quality and team productivity per year

use "$data/main_pat_lev_CP$save_str.dta", clear


gen tprod_f_cit3=f_cit3/tsize
gen tprod_f_cit5=f_cit5/tsize

gen tprod_cit3=cit3/tsize
gen tprod_cit5=cit5/tsize

collapse (mean) f_cit3 f_cit5 cit3 cit5  tprod_f_cit3 tprod_cit3 tprod_f_cit5 tprod_cit5 , by(appyear)

**Patent quality: citations
twoway (connected  f_cit3  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit3.pdf", replace as(pdf)
}


twoway (connected  f_cit5  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("5-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit5.pdf", replace as(pdf)
}

twoway (connected  cit3  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit3.pdf", replace as(pdf)
}


twoway (connected  cit5  appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("5-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit5.pdf", replace as(pdf)
}


**Team productivity
twoway (connected  tprod_f_cit3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_f_cit3.pdf", replace as(pdf)
}

twoway (connected  tprod_f_cit5 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_f_cit5.pdf", replace as(pdf)
}

twoway (connected  tprod_cit3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_cit3.pdf", replace as(pdf)
}

twoway (connected  tprod_cit5 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Citations per Team Member",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tprod_cit5.pdf", replace as(pdf)
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


**USPTO
use "$data/main_pat_lev_CP$save_str.dta", clear

keep appyear ipc3

duplicates drop appyear ipc3, force

encode ipc3, gen(ipc3n)

collapse (count) ipc3n, by(appyear)

twoway (connected  ipc3n appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Distinct IPC (3 Characters)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ipc3.pdf", replace as(pdf)
}

}
*----------------------------------------
* Number and share of Patents by IPC3
*----------------------------------------
{
**Number of patents

use "$data/main_pat_lev_CP$save_str.dta", clear

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

*Total number of patents
twoway (connected  tot_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tot_pat.pdf", replace as(pdf)
}

*Total number of patents not classified
twoway (connected  n_ipc3 appyear if ipc3n==. , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Not Classified",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/no_ipc3.pdf", replace as(pdf)
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
graph export "$figfolder/n_ipc1.pdf", replace as(pdf)
}

twoway  `pl_s_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_ipc1.pdf", replace as(pdf)
}

**Herfindahl-Hirschman Index

global pl_fyear 2005

*IPC1
twoway (connected  HHI_ipc1 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC1",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc1.pdf", replace as(pdf)
}

*IPC3
twoway (connected  HHI_ipc3 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3.pdf", replace as(pdf)
}

}

*---------------------------
* Number of inventors by Year
*---------------------------
{
use "$data/main_CP$save_str.dta", clear

drop if categ1==.

keep categ1 appyear

collapse (count) categ1, by(appyear)


twoway (connected  categ1 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Inventors",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/inventors.pdf", replace as(pdf)
}
}
*--------------------------------
* Number of patents by inventors
*--------------------------------
{
***Options: choose lsolo=1 if want to run for solo patents only
local lsolo 1 //  0 // 

if `lsolo'==1{
local lkeep keep if tsize==1
global save_str_solo _solo
}

use "$data/main_CP$save_str.dta", clear

`lkeep'

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
	
*Group every 5 years
gen gr_5yr=1 if iyear>=1975 & iyear<=1979
	replace gr_5yr=2 if iyear>=1980 & iyear<=1984
	replace gr_5yr=3 if iyear>=1985 & iyear<=1989
	replace gr_5yr=4 if iyear>=1990 & iyear<=1994
	replace gr_5yr=5 if iyear>=1995 & iyear<=1999
	replace gr_5yr=6 if iyear>=2000 & iyear<=2004



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
graph export "$figfolder/npat_hist$save_str_solo.pdf", replace as(pdf)
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
graph export "$figfolder/ripc1$save_str_solo.pdf", replace as(pdf)
}

twoway (connected  ripc3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Inventor",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3$save_str_solo.pdf", replace as(pdf)
}


*Running IPC count per patent count

twoway (connected  ripc1_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc1_pat$save_str_solo.pdf", replace as(pdf)
}


twoway (connected  ripc3_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat$save_str_solo.pdf", replace as(pdf)
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
(line  ripc3 rpat if gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") )

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_10yr$save_str_solo.pdf", replace as(pdf)
}


twoway (line ripc1 rpat if gr_10yr==1, lcolor(navy) lwidth(medthick))  (line  ripc1 rpat if gr_10yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  ripc1 rpat if gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC1",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") )

if $save_fig==1 {
graph export "$figfolder/ripc1_rpat_10yr$save_str_solo.pdf", replace as(pdf)
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
(line ripc3 rpat if gr_5yr==5,  lwidth(medthick) lpattern(longdash_dot))  (line  ripc3 rpat if gr_5yr==6,  lwidth(medthick) lpattern("--."))  if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1979") label(2 "1980-1984" ) label(3 "1985-1989") label(4 "1990-1994") label(5 "1995-1999" ) label(6 "2000-2004") )

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_5yr$save_str_solo.pdf", replace as(pdf)
}

twoway (line ripc1 rpat if gr_5yr==1, lcolor(navy) lwidth(medthick))  (line  ripc1 rpat if gr_5yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
( line ripc1 rpat if gr_5yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-.") )  (line  ripc1 rpat if gr_5yr==4, lwidth(medthick) lpattern("--..")) ///
(line ripc1 rpat if gr_5yr==5,  lwidth(medthick) lpattern(longdash_dot))  (line  ripc1 rpat if gr_5yr==6,  lwidth(medthick) lpattern("--."))  if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC1",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1979") label(2 "1980-1984" ) label(3 "1985-1989") label(4 "1990-1994") label(5 "1995-1999" ) label(6 "2000-2004") )

if $save_fig==1 {
graph export "$figfolder/ripc1_rpat_5yr$save_str_solo.pdf", replace as(pdf)
}


restore
}
*-----------------
* Solo patents
*-----------------
{
**Number of patents

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/n_ipc1_solo.pdf", replace as(pdf)
}

*share in solo
twoway  `pl_s_str_solo' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_ipc1_solo.pdf", replace as(pdf)
}

*share of solo
twoway  `pl_s_str' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str_s' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_solo_tot_ipc1.pdf", replace as(pdf)
}



duplicates drop appyear solo, force

*Total number of patents
twoway (connected  tot_pat_solo appyear if solo==0, lcolor(navy) lwidth(medthick)) (connected  tot_pat_solo appyear if solo==1, lcolor(maroon) lwidth(medthick) ms(D)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "Team Patents (>1)") label(2 "Solo Patents"))

if $save_fig==1 {
graph export "$figfolder/tot_pat_solo.pdf", replace as(pdf)
}

}
*---------------------------------------
* HHI by Inventor and only solo patents
*---------------------------------------
{
**Herfindahl-Hirschman Index
*Options: choose lsolo=1 if want to run for solo patents only
local lsolo  1 // 0 // 

global save_str_solo

if `lsolo'==1{
local lkeep keep if tsize==1
global save_str_solo _solo
}

use "$data/main_CP$save_str.dta", clear // only change this line

`lkeep'

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


global pl_fyear 2005

*IPC1
twoway (connected  HHI_ipc1 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC1",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc1_ind$save_str_solo.pdf", replace as(pdf)
}

*IPC3
twoway (connected  HHI_ipc3 appyear, lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3_ind$save_str_solo.pdf", replace as(pdf)
}

}
*----------------------------------------------------
*Basics: Assignees
*----------------------------------------------------
{

**Number of assignees by year
use "$data/main_pat_lev_CP$save_str.dta", clear

drop if asgnum==""
drop if appyear==.

keep appyear asgnum

duplicates drop appyear asgnum, force

egen asg_num=group(asgnum)

collapse (count) asg_num, by(appyear)

rename asg_num nasg

twoway (connected  nasg appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/nasg.pdf", replace as(pdf)
}


**Share of identified assignees
use "$data/main_pat_lev_CP$save_str.dta", clear

global fyear_pl 2005

gen dasg=1 if asgnum!=""
	replace dasg=0 if asgnum==""
	
collapse (mean) dasg , by(appyear)

twoway (connected  dasg appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dasg.pdf", replace as(pdf)
}


keep if appyear<=$fyear_pl

twoway (connected  dasg appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dasg_$fyear_pl.pdf", replace as(pdf)
}

*Share of identified assignees by sector 

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/dasg_ipc1_$fyear_pl.pdf", replace as(pdf)
}

global fyear_pl 2005

**Flow of patents by assignee each year

use "$data/main_pat_lev_CP$save_str.dta", clear

collapse (count) patent, by(asgnum appyear)

drop if appyear==.

drop if asgnum==""

collapse (mean) patent, by (appyear)


twoway (connected  patent appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents by Assignee",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asgn_pat.pdf", replace as(pdf)
}

keep if appyear<= $fyear_pl

twoway (connected  patent appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents by Assignee",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asgn_pat_$fyear_pl.pdf", replace as(pdf)
}

}
*--------------------------------
* Number of Patents by Assignee
*--------------------------------
{

use "$data/main_pat_lev_CP$save_str.dta", clear

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
graph export "$figfolder/npat_asg_hist.pdf", replace as(pdf)
}

}
*----------------------------------------------------
*Distribution and Tail of Number of Patents per Assignee by Year
*----------------------------------------------------
{
global fyear_pl 2005

use "$data/main_pat_lev_CP$save_str.dta", clear

bys appyear : gen tot_pat=_N

collapse (count) patent (mean) tot_pat, by(appyear asgnum)

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
graph export "$figfolder/dist`dprc'_N_pat$fyear_pl.pdf", replace as(pdf)
}


*p90 and p99
twoway (connected  p90_pat appyear, lcolor(navy) lwidth(medthick)) (connected  p99_pat appyear, lcolor(maroon) lwidth(medthick) msymbol(D)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "90th Percentile") label(2 "99th Percentile")  )

if $save_fig==1 {
graph export "$figfolder/p90_99_N_pat$fyear_pl.pdf", replace as(pdf)
}

*tail

twoway (connected p99_pat appyear ) (connected p995_pat appyear ) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Percentile 99") label(2 "Percentile 99.5"))

if $save_fig==1 {
graph export "$figfolder/tail_p99_p995_N_pat$fyear_pl.pdf", replace as(pdf)
}

twoway (connected p99_pat appyear ) (connected p995_pat appyear )  (connected p999_pat appyear )  (connected p9999_pat appyear )  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Percentile 99") label(2 "Percentile 99.5") label(3 "Percentile 99.9") label(4 "Percentile 99.99") )

if $save_fig==1 {
graph export "$figfolder/tail_N_pat$fyear_pl.pdf", replace as(pdf)
}

}
*----------------------------------------------------
*Number and Share by Percentile of Patents for Assignees by Year
*----------------------------------------------------
{
global fyear_pl 2005

use "$data/main_pat_lev_CP$save_str.dta", clear

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
local lonly_asg  1 // 0 //

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
graph export "$figfolder/s_pat_p90_99`lsave_str'.pdf", replace as(pdf)
}

keep if appyear<= $fyear_pl

twoway (connected  s_p90_tot appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  s_p99_tot appyear if p99==1, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 10%") label(2 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_p90_99_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*in levels
twoway (connected  tot_p90_pat appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  tot_p99_pat appyear if p99==1, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "90th Percentile") label(2 "99th Percentile")  )

if $save_fig==1 {
graph export "$figfolder/tot_pat_p90_99_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*Above and Below p90
twoway (connected  s_p90_tot appyear if p90==1, lcolor(navy) lwidth(medthick)) (connected  s_p90_tot appyear if p90==0, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 10%") label(2 "Bottom 90%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_t10_b90_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*Above and Below p99
twoway (connected  s_p99_tot appyear if p99==1, lcolor(navy) lwidth(medthick)) (connected  s_p99_tot appyear if p99==0, lcolor(maroon) lwidth(medthick) msymbol(D)) if p90!=. & p99!=. , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Top 1%") label(2 "Bottom 99%")  )

if $save_fig==1 {
graph export "$figfolder/s_pat_t1_b99_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*Above the median
twoway (connected  s_p50_tot appyear if p50==1, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/s_pat_p50_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*in levels
twoway (connected  tot_p50_pat appyear, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/tot_pat_p50_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}


*Only one patent

twoway (connected  s_one_tot appyear if one_pat==1, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/s_one_pat_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

twoway (connected  tot_one_pat appyear if one_pat==1, lcolor(navy) lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  

if $save_fig==1 {
graph export "$figfolder/tot_one_pat_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*Groups
twoway (connected  s_gr_asg_tot appyear if gr_asg==1,  lwidth(medthick)) (connected  s_gr_asg_tot appyear if gr_asg==2, lwidth(medthick)) ///
(connected  s_gr_asg_tot appyear if gr_asg==3, lwidth(medthick)) (connected  s_gr_asg_tot appyear if gr_asg==4, lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Bottom 70% (Only One Patent)") label(2 "Between 70 and 90th Percentile") label(3 "Between 90 and 99th Percentile") label(4 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_gr_asg_tot_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

*Groups 2
twoway (connected  s_gr2_asg_tot appyear if gr2_asg==1,  lwidth(medthick)) (connected  s_gr2_asg_tot appyear if gr2_asg==2, lwidth(medthick) ms(D)) ///
(connected  s_gr2_asg_tot appyear if gr2_asg==3, lwidth(medthick) ms(S))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))  ///
legend(region(lcolor(white)) label(1 "Below 90th Percentile") label(2 "Between 90 and 99th Percentile") label(3 "Top 1%")  )

if $save_fig==1 {
graph export "$figfolder/s_gr2_asg_tot_$fyear_pl`lsave_str'.pdf", replace as(pdf)
}

}

*----------------------------------------------------
*Assignees and Classes
*----------------------------------------------------
{
global fyear_pl 2005

use "$data/main_pat_lev_CP$save_str.dta", clear

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
	
*Group every 5 years
gen gr_5yr=1 if iyear>=1975 & iyear<=1979
	replace gr_5yr=2 if iyear>=1980 & iyear<=1984
	replace gr_5yr=3 if iyear>=1985 & iyear<=1989
	replace gr_5yr=4 if iyear>=1990 & iyear<=1994
	replace gr_5yr=5 if iyear>=1995 & iyear<=1999
	replace gr_5yr=6 if iyear>=2000 & iyear<=2004

**IPC per assignee
preserve

collapse (mean) ripc3 ripc3_pat , by(appyear)

*Running IPC count
twoway (connected  ripc3 appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Assignee",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_asg.pdf", replace as(pdf)
}


*Running IPC count per patent count

twoway (connected  ripc3_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat_asg.pdf", replace as(pdf)
}

restore

**Distribution

use "$data/main_pat_lev_CP$save_str.dta", clear

*Only keep patents with assignee
drop if appyear==.
drop if asgnum==""


bys appyear asgnum: gen tot_pat_asg=_N

bys appyear: egen p90_pat=pctile(tot_pat_asg), p(90)
bys appyear: egen p99_pat=pctile(tot_pat_asg), p(99)

gen p90=(tot_pat_asg>=p90_pat)

gen p99=(tot_pat_asg>=p99_pat)


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

preserve

collapse (mean) ripc3 ripc3_pat , by(appyear p90)

*Running IPC count per patent count

twoway (connected  ripc3_pat appyear if p90==1, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat_asg_p90.pdf", replace as(pdf)
}

restore

preserve

collapse (mean) ripc3 ripc3_pat , by(appyear p99)

*Running IPC count per patent count

twoway (connected  ripc3_pat appyear if p99==1, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of IPC3 per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ripc3_pat_asg_p99.pdf", replace as(pdf)
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
(line  ripc3 rpat if gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") )

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_10yr_asg.pdf", replace as(pdf)
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
(line ripc3 rpat if gr_5yr==5,  lwidth(medthick) lpattern(longdash_dot))  (line  ripc3 rpat if gr_5yr==6,  lwidth(medthick) lpattern("--."))  if rpat<=`maxrpat', ///
graphregion(color(white)) bgcolor(white) xtitle("Number of Patents",height(8) size($size_font)) xlabel(0(`dpat')`maxrpat', labsize($size_font)) ylabel(, nogrid labsize($size_font)) ///
ytitle("Number of IPC3",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1979") label(2 "1980-1984" ) label(3 "1985-1989") label(4 "1990-1994") label(5 "1995-1999" ) label(6 "2000-2004") )

if $save_fig==1 {
graph export "$figfolder/ripc3_rpat_5yr_asg.pdf", replace as(pdf)
}

restore

}
*----------------------------------------------------
*New entrants
*----------------------------------------------------
{
global iyear_pl 1980
global fyear_pl 2005

use "$data/main_pat_lev_CP$save_str.dta", clear


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
graph export "$figfolder/s_agn_entry.pdf", replace as(pdf)
}

keep if  appyear<= $fyear_pl

twoway (connected  s_agn_entry appyear, lcolor(navy) lwidth(medthick)),  ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_pl, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) 

if $save_fig==1 {
graph export "$figfolder/s_agn_entry_$fyear_pl.pdf", replace as(pdf)
}
}
*----------------------------------------------------
*HHI at the Assignee level
*----------------------------------------------------
{
use "$data/main_pat_lev_CP$save_str.dta", clear // only change this line

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


global pl_fyear 2005


*IPC3
*below p50
twoway (connected  HHI_ipc3 appyear if p50==0 , yaxis(1) lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3_asg_bp50_$pl_fyear.pdf", replace as(pdf)
}

*above p50
twoway (connected  HHI_ipc3 appyear if p50==1 , lcolor(navy) lwidth(medthick)) if appyear<$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Concentration (HHI) IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/HHI_ipc3_asg_ap50_$pl_fyear.pdf", replace as(pdf)
}
}
*----------------------------------------------------
*Self-citations
*----------------------------------------------------
{
use "$data/main_pat_lev_CP$save_str.dta", clear

drop if appyear==.

/*
*micro shares
gen s_asg_self_cite=b_cit_asg_sc/b_cit
gen s_ipc3_self_cite=b_cit_ipc3_sc/b_cit
*/

collapse (count) patent (sum) b_cit b_cit_asg_sc b_cit_ipc3_sc, by(appyear)

*Shares
gen b_cit_pat=b_cit/patent
gen asg_b_cit=b_cit_asg_sc/b_cit
gen ipc3_b_cit=b_cit_ipc3_sc/b_cit

*Backward citations

twoway (connected  b_cit_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Backward Citations per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/b_cit.pdf", replace as(pdf)
}

*Self-Citation Assignees

twoway (connected  asg_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Self-Citations of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/asg_b_cit.pdf", replace as(pdf)
}

*Self-Citation IPC3

twoway (connected  ipc3_b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Self-Citations of IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ipc3_b_cit.pdf", replace as(pdf)
}

}

*---------------------------------------
* Theil Index for IPC
*---------------------------------------
{
**Theil Index

use "$data/main_pat_lev_CP$save_str.dta", clear 

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
bys appyear asgnum: gen N_asg=_N
bys appyear asgnum ipc1: gen n_asg_ipc1=_N
bys appyear asgnum ipc3: gen n_asg_ipc3=_N

gen s_asg_ipc1=n_asg_ipc1/N_asg
gen s_asg_ipc3=n_asg_ipc3/N_asg

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

bys appyear : egen H_ipc1=sum((N_asg/N_pat)*dasg_year*(E_ipc1-E_asg_ipc1)/E_ipc1)
bys appyear : egen H_ipc3=sum((N_asg/N_pat)*dasg_year*(E_ipc3-E_asg_ipc3)/E_ipc3)

gen invE_ipc1=1/E_ipc1
gen invE_ipc3=1/E_ipc3


global pl_fyear 2005
	
**Entropy

*IPC1
twoway (connected  E_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC1 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc1.pdf", replace as(pdf)
}

twoway (connected  invE_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC1 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc1.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  E_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC3 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc3.pdf", replace as(pdf)
}

twoway (connected  invE_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC3 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc3.pdf", replace as(pdf)
}

**Theil index for Assignees

*IPC1
twoway (connected  H_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc1.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  H_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc3.pdf", replace as(pdf)
}


}

*---------------------------------------
* Decomposition: Theil Index for IPC
*---------------------------------------
{
**Theil Index

use "$data/main_pat_lev_CP$save_str.dta", clear 

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
bys appyear asgnum: gen N_asg=_N
bys appyear asgnum ipc1: gen n_asg_ipc1=_N
bys appyear asgnum ipc3: gen n_asg_ipc3=_N

gen s_asg_ipc1=n_asg_ipc1/N_asg
gen s_asg_ipc3=n_asg_ipc3/N_asg

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
bys appyear: egen p90_pat=pctile(dasg_year*N_asg), p(90)
bys appyear: egen p99_pat=pctile(dasg_year*N_asg), p(99)

gen group=1 if N_asg<p90_pat
	replace group=2 if N_asg>=p90_pat & N_asg<p99_pat
	replace group=3 if N_asg>=p99_pat & N_asg!=.
	
label define lbl_g 1 "Below p90" 2 "Between p90 and p99"  3 "Top 1%"

label values group lbl_g

/*

local ng 1000

**Firm size

*temporary dataset to define groups 
preserve
	duplicates drop appyear asgnum, force
	*create ranking
	bys appyear (N_asg): gen group = int(`ng'*(_n-1)/_N)+1
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
bys appyear group: egen H_g_ipc1=sum((N_asg/N_g)*dasg_year*(E_g_ipc1-E_asg_ipc1)/E_g_ipc1)
bys appyear group: egen H_g_ipc3=sum((N_asg/N_g)*dasg_year*(E_g_ipc3-E_asg_ipc3)/E_g_ipc3)

bys appyear: egen H_W_ipc1=sum((N_g/N_pat)*(E_g_ipc1/E_ipc1)*dg_year*H_g_ipc1)
bys appyear: egen H_W_ipc3=sum((N_g/N_pat)*(E_g_ipc3/E_ipc3)*dg_year*H_g_ipc3)


** 5. Total Theil Index and comparison

bys appyear : egen H_ipc1=sum((N_asg/N_pat)*dasg_year*(E_ipc1-E_asg_ipc1)/E_ipc1)
bys appyear : egen H_ipc3=sum((N_asg/N_pat)*dasg_year*(E_ipc3-E_asg_ipc3)/E_ipc3)

bys appyear : gen H2_ipc1=H_B_ipc1+H_W_ipc1
bys appyear : gen H2_ipc3=H_B_ipc3+H_W_ipc3


gen invE_ipc1=1/E_ipc1
gen invE_ipc3=1/E_ipc3

gen invE_g_ipc1=1/E_g_ipc1
gen invE_g_ipc3=1/E_g_ipc3


global pl_fyear 2005

***Plots
	
**Entropy

*IPC1
twoway (connected  E_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC1 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc1.pdf", replace as(pdf)
}

twoway (connected  invE_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC1 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc1.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  E_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC3 (Diversity)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_ipc3.pdf", replace as(pdf)
}

twoway (connected  invE_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC3 (Specialization)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_ipc3.pdf", replace as(pdf)
}

**Aggregate Theil index for Assignees

*IPC1
twoway (connected  H_ipc1 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc1.pdf", replace as(pdf)
}
	
*IPC3
twoway (connected  H_ipc3 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC3",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_ipc3.pdf", replace as(pdf)
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
graph export "$figfolder/deco_H_ipc1`lsave_str'.pdf", replace as(pdf)
}

twoway (connected  H_W_ipc1 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Within Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_W_ipc1`lsave_str'.pdf", replace as(pdf)
}

twoway (connected  H_B_ipc1 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Between Theil Index IPC1 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_B_ipc1`lsave_str'.pdf", replace as(pdf)
}

*IPC3
twoway (line  H_ipc3 appyear , lcolor(black) lwidth(medthick)) ///
(connected  H_B_ipc3 appyear , lcolor(navy) lwidth(medthick) mcolor(navy)) (connected  H_W_ipc3 appyear, lcolor(maroon) lwidth(medthick) ms(D) mcolor(maroon)) if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Decompostion Theil Index IPC3 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) label(1 "Total") label(2 "Between") label(3 "Within" ) )

if $save_fig==1 {
graph export "$figfolder/deco_H_ipc3`lsave_str'.pdf", replace as(pdf)
}


twoway (connected  H_W_ipc3 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Within Theil Index IPC3 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_W_ipc3`lsave_str'.pdf", replace as(pdf)
}
twoway (connected  H_B_ipc3 appyear , lcolor(navy) lwidth(medthick) mcolor(navy))  if dyear==1  & appyear<=$pl_fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$pl_fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Decompostion Theil Index IPC3 ",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_B_ipc3`lsave_str'.pdf", replace as(pdf)
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
graph export "$figfolder/E_g_ipc1`lsave_str'.pdf", replace as(pdf)
}

twoway  `pl_str_E_g_ipc3' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Entropy IPC3 (Diversity)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/E_g_ipc3`lsave_str'.pdf", replace as(pdf)
}

*Inverse Entropy
twoway  `pl_str_invE_g_ipc1' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC1 (Specialization)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_g_ipc1`lsave_str'.pdf", replace as(pdf)
}

twoway  `pl_str_invE_g_ipc3' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Inverse of Entropy IPC3 (Specialization)",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/invE_g_ipc3`lsave_str'.pdf", replace as(pdf)
}

*Theil
twoway  `pl_str_H_g_ipc1' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_g_ipc1`lsave_str'.pdf", replace as(pdf)
}

twoway  `pl_str_H_g_ipc3' if dg_year==1 & appyear<=$pl_fyear   , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Theil Index IPC3",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/H_g_ipc3`lsave_str'.pdf", replace as(pdf)
}

}

}
**********************************************************
**********************************************************
***Testing ground
**********************************************************
**********************************************************

*-----------------------
* Variables by groups
*-----------------------


use "$data/main_pat_lev_CP$save_str.dta", clear

drop if appyear<=$iyear | appyear==.

drop if asgnum==""

bys appyear asgnum: gen N_asg=_N
bys appyear asgnum: gen dasg_year=1 if asgnum[_n]!=asgnum[_n-1]


*Defining groups
local lsave_str _gr2_asg

*Patenting by year
bys appyear: egen p90_pat=pctile(dasg_year*N_asg), p(90)
bys appyear: egen p99_pat=pctile(dasg_year*N_asg), p(99)

gen group=1 if N_asg<p90_pat
	replace group=2 if N_asg>=p90_pat & N_asg<p99_pat
	replace group=3 if N_asg>=p99_pat & N_asg!=.
	
label define lbl_g 1 "Below p90" 2 "Between p90 and p99"  3 "Top 1%"

label values group lbl_g



collapse (mean) tsize m_ttb survive , by(appyear group)


levelsof group , local(lgroup)

local lab_str
local i=1

local lab : value label group

foreach ig of local lgroup{
local lbl_str `: label `lab' `ig''

local pl_str_tsize  `pl_str_tsize' (connected  tsize appyear if group==`ig')
local pl_str_m_ttb  `pl_str_m_ttb' (connected  m_ttb appyear if group==`ig')
local pl_str_survive  `pl_str_survive' (connected  survive appyear if group==`ig')

local lab_str  `lab_str' label( `i' "`lbl_str'") 
local i=`i'+1

}


*Team size
twoway `pl_str_tsize' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/tsize`lsave_str'.pdf", replace as(pdf)
}

*Time to build

twoway `pl_str_m_ttb' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/m_ttb`lsave_str'.pdf", replace as(pdf)
}

*Survival

twoway `pl_str_survive' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Survival",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) legend(region(lcolor(white)) `lab_str' cols(4) )

if $save_fig ==1 {
graph export "$figfolder/survive`lsave_str'.pdf", replace as(pdf)
}


***To-do

*1. Do the Theil, for a grouping of bottom, middle and top in size

*3. Assignee mobility

*2. Register age trends and dynamics of firms, look at literature

*3. Register inventor trends and churning, how does assortative matching been behaving? Look at Ma paper

*4. Dynamics of teams



***br
	
br patent appyear appyear asgnum  dasg 	

br categ1 appyear ipc1 ipc3 npat_ipc1  npat_ipc3 npat  rpat_ipc1  rpat_ipc3 rpat dipc3 nipc3 ripc3 nipc1 ripc1


