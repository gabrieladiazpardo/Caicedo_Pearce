************************************************
*		Facts PatentsView
*
************************************************


*---------------------------
* Number of Classes by Year
*---------------------------
clear all

global figfolder="$main/RA/output/figfolder/patentsview"

**Saving options
global save_fig 1 //  0 //

**Graph options
*cd D:\Dropbox\Santiago\Stata\ado\personal
*set scheme scheme_papers  // Larger axis labels, tick labels, 

global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots


*******************************
*	A) IPC
*
*********************************
{

local rare_ipc 0
local non_selected_jp 1

if `non_selected_jp'==1{
local d_non_selected_jp drop if non_selected_ipc==1
local save_str_n _non_selected_jp
}

if `rare_ipc'==1{
local d_rare_ipc drop if rare_ipc==1
local save_str_r _rare_ipc
}


use "$datasets/Patentsview_lev_dataset.dta", clear

*Important! Non-Selected-JP and Rare-IPC

`d_non_selected_jp'
`d_rare_ipc'

keep appyear ipc3

duplicates drop appyear ipc3, force

encode ipc3, gen(ipc3n)

collapse (count) ipc3n, by(appyear)


twoway (connected  ipc3n appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(80(40)300, nogrid labsize($size_font)) ////
ytitle("Number of Distinct IPC (3 Characters)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ipc3`save_str_r'`save_str_n'.pdf", replace as(pdf)
}


}


*******************************
*	B) CPC
*
*********************************

{
use "$datasets/Patentsview_lev_dataset.dta", clear

sort appyear patent

bys appyear: gen tot_pat=_N
bys appyear section_cpc: gen n_section_cpc=_N
bys appyear subsection_cpc: gen n_subsection_cpc=_N

gen s_section_cpc=n_section_cpc/tot_pat
gen s_subsection_cpc=n_subsection_cpc/tot_pat

bys appyear section_cpc: gen sqs_section_cpc=s_section_cpc^2
bys appyear subsection_cpc: gen sqs_subsection_cpc=s_subsection_cpc^2

sort appyear section_cpc
gen temp=1 if section_cpc[_n]!=section_cpc[_n-1]
gen sqs_section_cpc_temp=temp*sqs_section_cpc

duplicates drop appyear subsection_cpc, force

keep appyear section_cpc subsection_cpc tot_pat n_section_cpc s_section_cpc n_subsection_cpc s_subsection_cpc

encode subsection_cpc, gen(subsection_cpcn)


*Number and share of patents by IPC1
levelsof section_cpc, local(levels) 

local i=1
local pl_n_str 
local pl_s_str 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  n_section_cpc appyear if section_cpc=="`l'")
local pl_s_str  `pl_s_str' (connected  s_section_cpc appyear if section_cpc=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_n_str' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/n_section_cpc.pdf", replace as(pdf)
}

twoway  `pl_s_str' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_section_cpc`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

}


*******************************
*	B) NBER
*
*********************************

{
use "$datasets/Patentsview_lev_dataset.dta", clear

sort appyear patent

bys appyear: gen tot_pat=_N
bys appyear category_nber: gen n_category_nber=_N
bys appyear subcategory_nber: gen n_subcategory_nber=_N

gen s_category_nber=n_category_nber/tot_pat
gen s_subcategory_nber=n_subcategory_nber/tot_pat

bys appyear category_nber: gen sqs_category_nber=s_category_nber^2
bys appyear subcategory_nber: gen sqs_subcategory_nber=s_subcategory_nber^2

sort appyear category_nber
gen temp=1 if category_nber[_n]!=category_nber[_n-1]
gen sqs_category_nber_temp=temp*sqs_category_nber

duplicates drop appyear subcategory_nber, force

keep appyear category_nber subcategory_nber tot_pat n_category_nber s_category_nber n_subcategory_nber s_subcategory_nber

*encode subcategory_nber, gen(subcategory_nbern)


*Number and share of patents by IPC1
levelsof category_nber, local(levels) 

local i=1
local pl_n_str 
local pl_s_str 

foreach l of local levels{
local pl_n_str  `pl_n_str' (connected  n_category_nber appyear if category_nber==`l')
local pl_s_str  `pl_s_str' (connected  s_category_nber appyear if category_nber==`l')
local lab_str  `lab_str' label( `i' `l') 
local i=`i'+1
}

twoway  `pl_n_str' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/n_category_nber.pdf", replace as(pdf)
}

twoway  `pl_s_str' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_category_nber.pdf", replace as(pdf)
}

}

*----------------------------------------
* B) All Number and share of Patents by IPC3 
*----------------------------------------
{
**Number of patents

local rare_ipc 0
local non_selected_jp 0

if `non_selected_jp'==1{
local d_non_selected_jp drop if non_selected_ipc==1
local save_str_n _non_selected_jp
}

if `rare_ipc'==1{
local d_rare_ipc drop if rare_ipc==1
local save_str_r _rare_ipc
}

use "$datasets/Patentsview_lev_dataset.dta", clear

`d_non_selected_jp'
`d_rare_ipc'

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

replace tot_pat=tot_pat/100000
*Total number of patents
twoway (connected  tot_pat appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents per 100,000",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/tot_pat`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

*Total number of patents not classified
twoway (connected  n_ipc3 appyear if ipc3n==. & appyear<=$fyear , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Not Classified",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/no_ipc`save_str_r'`save_str_n'.pdf", replace as(pdf)
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

twoway  `pl_n_str' if appyear<=$fyear, ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/n_ipc1`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

twoway  `pl_s_str' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Patents",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_ipc1`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

}

*---------------------------
* Number of inventors by Year
*---------------------------
{
use "$datasets/Patentsview_Main.dta",  clear

drop if categ1==.

keep categ1 appyear 

collapse (count) categ1, by(appyear)

twoway (connected  categ1 appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
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

use "$datasets/Patentsview_Main.dta", clear

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
}

*--------------------------------
* Distribution of number of patents by inventor
*--------------------------------

{

local nmaxpat 10
local dpat=round(`nmaxpat'/10)
local lw=max(round(`nmaxpat'/50),1)

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
graph export "$figfolder/ripc3_pa$save_str_solo.pdf", replace as(pdf)
}


restore
}


*--------------------------
* E)  Solo patents - all IPC3
*----------------------------
{
**Number of patents

local rare_ipc 0
local non_selected_jp 0

if `non_selected_jp'==1{
local d_non_selected_jp drop if non_selected_ipc==1
local save_str_n _non_selected_jp
}

if `rare_ipc'==1{
local d_rare_ipc drop if rare_ipc==1
local save_str_r _rare_ipc
}


use "$datasets/Patentsview_lev_dataset.dta", clear

`d_non_selected_jp'
`d_rare_ipc'


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
twoway  `pl_str_solo' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/n_ipc1_solo`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

*share in solo
twoway  `pl_s_str_solo' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_ipc1_solo`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

*share of solo
twoway  `pl_s_str' if appyear<=$fyear , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Share of Solo Patents by IPC1",height(8) size($size_font)) legend(region(lcolor(white)) `lab_str_s' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/s_solo_tot_ipc1`save_str_r'`save_str_n'.pdf", replace as(pdf)
}



duplicates drop appyear solo, force

*Total number of patents
twoway (connected  tot_pat_solo appyear if solo==0 & appyear<=$fyear, lcolor(navy) lwidth(medthick)) (connected  tot_pat_solo appyear if solo==1, lcolor(maroon) lwidth(medthick) ms(D)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label(1 "Team Patents (>1)") label(2 "Solo Patents"))

if $save_fig==1 {
graph export "$figfolder/tot_pat_solo`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

}

*--------------------------------------
* Patent quality  (Citations)
*--------------------------------------

***Patent quality per year

{
use "$datasets/Patentsview_lev_dataset.dta", clear


gen tprod_f_cit3=f_cit3/tsize
gen tprod_f_cit5=f_cit5/tsize

gen tprod_cit3=cit3/tsize
gen tprod_cit5=cit5/tsize

collapse (mean) f_cit3 f_cit5 f_cit8 cit3 cit5 cit8 tprod_f_cit3 tprod_cit3 tprod_f_cit5 tprod_cit5 , by(appyear)

**Patent quality: citations
twoway (connected  f_cit3  appyear if appyear<=$fyear , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit3.pdf", replace as(pdf)
}


twoway (connected  f_cit5  appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("5-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit5.pdf", replace as(pdf)
}

twoway (connected  f_cit8  appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("8-year Forward Citations",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/f_cit8.pdf", replace as(pdf)
}

twoway (connected  cit3  appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit3.pdf", replace as(pdf)
}


twoway (connected  cit5  appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("5-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit5.pdf", replace as(pdf)
}

twoway (connected  cit8  appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("8-year Forward Citations (Adjusted)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/cit8.pdf", replace as(pdf)
}

}

*.......................................
*	Backward Citations & self citations
*---------------------------------------

{
use "$datasets/Patentsview_lev_dataset.dta", clear

drop if appyear==.

/*
*micro shares
gen s_asg_self_cite=b_cit_asg_sc/b_cit
gen s_ipc3_self_cite=b_cit_ipc3_sc/b_cit
*/
egen pat =group(patent)
collapse (count) pat (sum) b_cit b_cit_asg_sc b_cit_ipc3_sc, by(appyear)

rename pat patent
*Shares
gen b_cit_pat=b_cit/patent
gen asg_=b_cit_asg_sc/b_cit
gen ipc3_b_cit=b_cit_ipc3_sc/b_cit

*Backward citations

twoway (connected  b_cit_pat appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Backward Citations per Patent",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/b_cit.pdf", replace as(pdf)
}

*Self-Citation Assignees

twoway (connected asg_ b_cit appyear, lcolor(navy) lwidth(medthick)) , ///
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


*----------------------------------------------------
*Basics: Assignees
*----------------------------------------------------
{

**Number of assignees by year

local org 0
local per 0

if `org'==1{
local d_org keep if d_asg_org==1
local save_str_n _org
}

if `per'==1{
local d_per keep if d_asg_org==0
local save_str_r _per
}



use "$datasets/Patentsview_lev_dataset.dta", clear


`d_org'
`d_per'


drop if asgnum==""
drop if appyear==.

keep appyear asgnum

duplicates drop appyear asgnum, force

egen asg_num=group(asgnum)

collapse (count) asg_num, by(appyear)

rename asg_num nasg

twoway (connected  nasg appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/nasg`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

}


**Share of identified assignees

{
local org 0
local per 0

if `org'==1{
local d_org keep if d_asg_org==1
local save_str_n _org
}

if `per'==1{
local d_per keep if d_asg_org==0
local save_str_r _per
}



use "$datasets/Patentsview_lev_dataset.dta", clear


`d_org'
`d_per'


global fyear_pl 2015

gen dasg=1 if asgnum!=""
	replace dasg=0 if asgnum==""
	
collapse (mean) dasg , by(appyear)

twoway (connected  dasg appyear if appyear<=$fyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/dasg`save_str_r'`save_str_n'.pdf", replace as(pdf)
}

}

*--------------------------------
* Number of Patents by Assignee
*--------------------------------
{

local org 0
local per 1

if `org'==1{
local d_org keep if d_asg_org==1
local save_str_n _org
}

if `per'==1{
local d_per keep if d_asg_org==0
local save_str_r _per
}

use "$datasets/Patentsview_lev_dataset.dta", clear


`d_org'
`d_per'


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
graph export "$figfolder/npat_asg_hist`save_str_r'`save_str_n'.pdf", replace as(pdf)
}
}
