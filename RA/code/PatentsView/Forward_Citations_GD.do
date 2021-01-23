********************************************************************************
*
*
*
********************************************************************************


set more off

**Saving options
global save_fig   1 //0 // 

graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots


*in surv folder in reports
global figfolder="$main/RA/reports/Fall of Generalists/Second Version/Citations/figures"
global tabfolder="$main/RA/reports/Fall of Generalists/Second Version/Citations/tables"

*Matrix

*Compute the number of forward citations 
 use "$datasets/f_cit_panel_pat_age_reduced.dta", replace

*Compute unidentified 
bys cited: egen f_cit_cum_unidentified=total(cit_yr) if cit_pat_age==.
bys cited: egen f_cit_cum_unident=max(f_cit_cum_unidentified)
drop f_cit_cum_unidentified

count if f_cit_cum_unident!=. & f_cit_cum_unident==.
replace f_cit_cum_unident=0 if f_cit_cum_unident==.

*percentage of unidentified b_cit
gen share_unident=f_cit_cum_unident/f_cit*100

drop f_cit_cum_unident 
drop share_unident
 
rename cited patent

*percent by lag
gen percent_cit_pat=cit_yr/f_cit*100

*cumulative
bysort patent (cit_pat_age) : gen cum_fcit = sum(percent_cit_pat)

*merge info
merge m:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop if _m==2
drop _m
merge m:1 patent using "$datasets/ipc3_for_cit.dta"
drop if _m==2
drop _m

gen ipc1=substr(ipc3,1,1)
 
drop gyear appdate ipc3

*Distribution of Forward Citation Lags - Selected Cohorts
{

gen d_5_yrs=.


*cohorts every five years
gen gr_5yr=1 if appyear>=1975 & appyear<=1979
	replace gr_5yr=2 if appyear>=1980 & appyear<=1984
	replace gr_5yr=3 if appyear>=1985 & appyear<=1989
	replace gr_5yr=4 if appyear>=1990 & appyear<=1994
	replace gr_5yr=5 if appyear>=1995 & appyear<=1999
	replace gr_5yr=6 if appyear>=2000 & appyear<=2004
	replace gr_5yr=7 if appyear>=2005 & appyear<=2009
	replace gr_5yr=8 if appyear>=2010 & appyear<=2014



forvalues j=1975(5)2015 {
replace d_5_yrs=`j' if appyear==`j'
}


preserve

keep if cit_pat_age<51

collapse (mean) percent_cit_pat, by(cit_pat_age d_5_yrs)
sort d_5_yrs cit_pat_age
drop if d_5_yrs==.


*Number and share of patents by IPC1
tostring d_5_yrs, replace
drop if d_5_yrs=="9"

levelsof d_5_yrs, local(levels) 
local i=1
local pl_5_yrs

sort d_5_yrs cit_pat_age 

foreach l of local levels{
local pl_5_yrs  `pl_5_yrs' (connected percent_cit_pat cit_pat_age if d_5_yrs=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_5_yrs' , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Percent of all Citations" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/dist_fcit_lags_cohorts.pdf", replace as(pdf)
}


restore
 }
 
*cumulative by ipc1
{
preserve
keep if cit_pat_age<51

collapse (mean) cum_fcit, by(cit_pat_age ipc1)


*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected cum_fcit cit_pat_age if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulitive Percent" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/cum_dist_fcit_ipc.pdf", replace as(pdf)
}

restore
}

*cumulative
{
preserve

keep if cit_pat_age<51

collapse (mean) cum_fcit, by(cit_pat_age)

twoway  (connected cum_fcit cit_pat_age, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulitive Percent" ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/cum_dist_fcit.pdf", replace as(pdf)
}

restore
}

*Forward Citation Measures
use "$datasets/f_cit_patent.dta", clear

merge 1:1 patent using "$datasets/ipc3_for_cit.dta"
drop if _m==2
drop _m
merge 1:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop if _m==2
drop _m
keep if appyear!=.

drop if appyear<1975
drop if appyear>2015

gen ipc1=substr(ipc3,1,1)
drop if ipc1==""

*f_cit f_cit3 f_cit5 f_cit8 by ipc1
{

preserve

collapse (mean) f_cit f_cit3 f_cit5 f_cit8 , by(appyear ipc1)

local t=0

global g f_cit f_cit3 f_cit5 f_cit8

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
local lb "Forward Citations"
}

if `t'==2{
local lb "Forward Citations (3-Year)"
}

if `t'==3{
local lb "Forward Citations (5-Year)"
}

if `t'==4{
local lb "Forward Citations (8-Year)"
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'_ipc.pdf", replace as(pdf)
}

}

restore

}

*f_cit f_cit3 f_cit5 f_cit8

{

preserve

collapse (mean) f_cit f_cit3 f_cit5 f_cit8 , by(appyear)

local t=0

global g f_cit f_cit3 f_cit5 f_cit8

foreach k of global g{
local ++t


if `t'==1{
local lb "Forward Citations"
}

if `t'==2{
local lb "Forward Citations (3-Year)"
}

if `t'==3{
local lb "Forward Citations (5-Year)"
}

if `t'==4{
local lb "Forward Citations (8-Year)"
}

twoway (connected `k' appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore
}


*f_cit f_cit3 f_cit5 f_cit8 by ipc1 (Grant Year)
{

preserve

collapse (mean) f_cit f_cit3 f_cit5 f_cit8 , by(gyear ipc1)

local t=0

global g f_cit f_cit3 f_cit5 f_cit8

foreach k of global g{
local ++t

*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1


foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected `k' gyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}


if `t'==1{
local lb "Forward Citations"
}

if `t'==2{
local lb "Forward Citations (3-Year)"
}

if `t'==3{
local lb "Forward Citations (5-Year)"
}

if `t'==4{
local lb "Forward Citations (8-Year)"
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Grant Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'_ipc_gyear.pdf", replace as(pdf)
}

}

restore

}

*f_cit f_cit3 f_cit5 f_cit8 (Grant Year)

{

preserve

collapse (mean) f_cit f_cit3 f_cit5 f_cit8 , by(gyear)

local t=0

global g f_cit f_cit3 f_cit5 f_cit8

foreach k of global g{
local ++t


if `t'==1{
local lb "Forward Citations"
}

if `t'==2{
local lb "Forward Citations (3-Year)"
}

if `t'==3{
local lb "Forward Citations (5-Year)"
}

if `t'==4{
local lb "Forward Citations (8-Year)"
}

twoway (connected `k' gyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Grant Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'_gyear.pdf", replace as(pdf)
}

}

restore
}




************************************************************
*			Corrections
*
************************************************************
 
use "$datasets/f_cit_patent.dta", clear
 
merge 1:1 patent using "$datasets/ipc3_for_cit.dta"
drop _m

merge 1:1 patent using "$datasets/patents_uspto_for_cit.dta"
keep if appyear!=.

drop if appyear<1975
drop if appyear>2015

gen ipc1=substr(ipc3,1,1)
drop if ipc1==""
drop _m

*main entries mean - the average number of citations received by patents of each cohort in each technological field.
bys appyear ipc1: egen m_fcit_appyr_ipc=mean(f_cit)

*overall mean by field (bottom row)
bys ipc1: egen m_fcit_ipc=mean(f_cit)

*overall mean by year (right col)
bys appyear: egen m_fcit_appyear=mean(f_cit)

*generate correction matrix
gen correction=m_fcit_appyr_ipc/m_fcit_ipc


*1) remove all year, field and year-field effects
gen f_cit_yr_ipc_fe=f_cit/m_fcit_appyr_ipc

*2) remove only pure year effects
gen f_cit_yr_fe=f_cit/m_fcit_appyear

*3) remove only field effect
gen f_cit_ipc_fe=f_cit/m_fcit_ipc

*4) Removal of year effects and year-field interaction effects but not the main field effect.
gen f_cit_adj=f_cit/correction

*figs by ipc
{

preserve

collapse (mean) f_cit_yr_ipc_fe f_cit_yr_fe f_cit_ipc_fe f_cit_adj, by(appyear ipc1)

local t=0

global g f_cit_yr_ipc_fe f_cit_yr_fe f_cit_ipc_fe f_cit_adj


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
local lb "FCit No Yr or Field or Yr*Field"
local wd 0(1)4
}

if `t'==2{
local lb "FCit No Yr"
local wd 0(0.5)2
}

if `t'==3{
local lb "FCit No Field"
local wd 0(0.5)2
}

if `t'==4{
local lb "FCit No Yr or Yr*Field"
local wd 15(5)35
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(`wd' , nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)) `lab_str' cols(4) ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'_ipc.pdf", replace as(pdf)
}

}

restore

}


*figs
{

preserve

collapse (mean) f_cit_yr_ipc_fe f_cit_yr_fe f_cit_ipc_fe f_cit_adj, by(appyear)

local t=0

global g f_cit_yr_ipc_fe f_cit_yr_fe f_cit_ipc_fe f_cit_adj

foreach k of global g{
local ++t

if `t'==1{
local lb "FCit No Yr or Field or Yr*Field"
local wd 0(1)2
}

if `t'==2{
local lb "FCit No Yr"
local wd 0(1)4
}

if `t'==3{
local lb "FCit No Field"
local wd 0(0.5)2
}

if `t'==4{
local lb "FCit No Yr or Yr*Field"
local wd 17.5(0.5)19.5
}

twoway (connected `k' appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(`wd' , nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'.pdf", replace as(pdf)
}

}

restore
}
