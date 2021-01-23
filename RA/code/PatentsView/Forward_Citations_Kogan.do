

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
 use "$datasets/f_cit_panel_pat_age_kogan.dta", replace

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
merge m:1 patent using "$datasets/tmp_dates_kogan.dta"
drop if _m==2
drop _m


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
graph export "$figfolder/dist_fcit_lags_cohorts_kogan.pdf", replace as(pdf)
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
graph export "$figfolder/cum_dist_fcit_kogan.pdf", replace as(pdf)
}

restore
}

*Forward Citation Measures
use "$datasets/f_cit_patent_kogan.dta", clear

*merge info
merge m:1 patent using "$datasets/tmp_dates_kogan.dta"
drop if _m==2
drop _m

keep if appyear!=.

drop if appyear<1975
drop if appyear>2015



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
graph export "$figfolder/`k'_kogan.pdf", replace as(pdf)
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
graph export "$figfolder/`k'_gyear_kogan.pdf", replace as(pdf)
}

}

restore
}



