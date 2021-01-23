**********************************************
*	Backward Citation Distribution (Exploration)
*******************************************

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

*open data
use "$datasets/b_cit_panel_pat_age_reduced.dta", replace

rename citing patent

*percent by lag
gen percent_cit_pat=cit_yr/b_cit*100

*cumulative
bysort patent (cit_pat_age) : gen cum_bcit = sum(percent_cit_pat)

*merge info
merge m:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop _m
merge m:1 patent using "$datasets/ipc3_for_cit.dta"
drop _m

gen ipc1=substr(ipc3,1,1)
 
drop gyear appdate ipc3


*dummy of change of patent 
sort patent
gen dpat=1 if patent[_n]!=patent[_n-1]


*Cohorts (Groups every 5 years)
gen d_5_yrs=.

*Dummy for selected cohorts
forvalues j=1975(5)2015 {
replace d_5_yrs=`j' if appyear==`j'
}

gen gr_5yr=1 if appyear>=1975 & appyear<=1979
	replace gr_5yr=2 if appyear>=1980 & appyear<=1984
	replace gr_5yr=3 if appyear>=1985 & appyear<=1989
	replace gr_5yr=4 if appyear>=1990 & appyear<=1994
	replace gr_5yr=5 if appyear>=1995 & appyear<=1999
	replace gr_5yr=6 if appyear>=2000 & appyear<=2004
	replace gr_5yr=7 if appyear>=2005 & appyear<=2009
	replace gr_5yr=8 if appyear>=2010 & appyear<=2014

	*Cohorts (Groups every 10 years)
gen gr_10yr=1 if appyear>=1975 & appyear<=1984
	replace gr_10yr=2 if appyear>=1985 & appyear<=1994
	replace gr_10yr=3 if appyear>=1995 & appyear<=2004
	replace gr_10yr=4 if appyear>=2005 & appyear<=2014
	
*Dummy for selected 2k years
gen d_yr_2k=. 
forvalues j=2000(2)2010{
replace d_yr_2k=`j' if appyear==`j'
}

*Dummy for selected cohorts
gen d_yrs=.

local i=0
forvalues j=1975(5)2020 {
local ++i
replace d_yrs=`i' if appyear==`j'
}
	
	*Cohorts (Groups every 3 years - 2k)
gen gr_2kyr=1 if appyear>=2005 & appyear<=2007
	replace gr_2kyr=2 if appyear>=2008 & appyear<=2010
	replace gr_2kyr=3 if appyear>=2011 & appyear<=2013
	replace gr_2kyr=4 if appyear>=2014 & appyear<=2016
	replace gr_2kyr=5 if appyear>=2017 & appyear<=2019

	
*Distribution of Backward Citation Lags - Selected Cohorts
{
*cohorts every five years


preserve

keep if cit_pat_age<51

collapse (mean) percent_cit_pat, by(cit_pat_age d_5_yrs)
sort d_5_yrs cit_pat_age
drop if d_5_yrs==.


*Number and share of patents by IPC1
tostring d_5_yrs, replace

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
graph export "$figfolder/dist_bcit_lags_cohorts.pdf", replace as(pdf)
}


restore
 }
 
*Distribution of Backward Citation Lags - Grouped Cohorts
{ 
 
preserve

keep if cit_pat_age<51

collapse (mean) percent_cit_pat, by(cit_pat_age gr_10yr)
sort gr_10yr cit_pat_age
drop if gr_10yr==.

 
twoway (connected percent_cit_pat cit_pat_age if gr_10yr==1) (connected percent_cit_pat cit_pat_age if gr_10yr==2) (connected percent_cit_pat cit_pat_age if gr_10yr==3) (connected percent_cit_pat cit_pat_age if gr_10yr==4)  , ///
graphregion(color(white)) bgcolor(white) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Percent of all Citations" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) label(1 "1975-1984 ") label(2 "1985-1994 ") label(3 "1995-2004") label(4 "2005-2014") )

 if $save_fig==1 {
graph export "$figfolder/dist_bcit_lags_10yr_gr_cohorts.pdf", replace as(pdf)
}

restore
}
 
 
*Distribution of Backward Citation Lags - 2K Cohorts
 {


preserve

keep if cit_pat_age<51

collapse (mean) percent_cit_pat, by(cit_pat_age d_yr_2k)
sort d_yr_2k cit_pat_age
drop if d_yr_2k==.


*Number and share of patents by IPC1
tostring d_yr_2k, replace

levelsof d_yr_2k, local(levels) 
local i=1
local pl_2k_yrs

sort d_yr_2k cit_pat_age 

foreach l of local levels{
local pl_2k_yrs  `pl_2k_yrs' (connected percent_cit_pat cit_pat_age if d_yr_2k=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_2k_yrs' , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Percent of all Citations" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/dist_bcit_lags_2k_cohorts.pdf", replace as(pdf)
}


restore
 }
 
*distribution age<50 by ipc1
{
preserve

keep if cit_pat_age<51
collapse (mean) percent_cit_pat, by(cit_pat_age ipc1)


*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected percent_cit_pat cit_pat_age if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Percent of all Citations" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/dist_bcit_lags_ipc.pdf", replace as(pdf)
}

restore
}

*distribution age<50
{
preserve

keep if cit_pat_age<51
collapse (mean) percent_cit_pat, by(cit_pat_age)

twoway  (connected percent_cit_pat cit_pat_age, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Percent of all Citations" ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/dist_bcit_lags.pdf", replace as(pdf)
}

restore

*distribution age>50  - Very Noisy
preserve
keep if cit_pat_age>50
collapse (mean) percent_cit_pat, by(cit_pat_age)

keep if cit_pat_age<90
twoway  (connected percent_cit_pat cit_pat_age, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Lags> 50 years",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Percent of all Citations" ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/dist_bcit_lags_after_50years.pdf", replace as(pdf)
}

restore
}


*cumulative by ipc1
{
preserve

keep if cit_pat_age<51

collapse (mean) cum_bcit, by(cit_pat_age ipc1)


*Number and share of patents by IPC1
levelsof ipc1, local(levels) 
local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected cum_bcit cit_pat_age if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulitive Percent" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/cum_dist_bcit_ipc.pdf", replace as(pdf)
}

restore
}

*cumulative
{
preserve

keep if cit_pat_age<51

collapse (mean) cum_bcit, by(cit_pat_age)

twoway  (connected cum_bcit cit_pat_age, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulitive Percent" ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/cum_dist_bcit.pdf", replace as(pdf)
}

restore
}

*mean Backward Lag (in years)
{
preserve
duplicates drop patent, force

*cohorts every five years

matrix A=J(10,5,.)

foreach n of numlist 1/10{

summ mean_pat_age if d_yrs==`n'
return list
matrix A[`n',1]=r(N)
matrix A[`n',2]=r(mean)
matrix A[`n',3]=r(sd)
matrix A[`n',4]=r(min)
matrix A[`n',5]=r(max)

frmttable using "$tabfolder/matrix_b_cit.tex", tex fragment replace sdec(0,2,2,0,0) /// 
	statmat(A) 	///
ctitles("","No. Patents","Mean", "SD", "Min", "Max") ////
rtitles("1975"\"1980"\ "1985"\ "1990"\"1995"\"2000"\"2005"\"2010"\"2015"\"2020") title("Mean Backward Lag (in years)")

}
restore
}

*mean Backward Lag for patents with average bcit (in years)
{


gen d_mean_b_cit=1 if b_cit>13 & b_cit<18
tab d_yrs if d_mean_b_cit==1 

preserve
duplicates drop patent, force

matrix Y=J(10,5,.)

foreach n of numlist 1/10{

summ mean_pat_age if d_yrs==`n' & d_mean_b_cit==1 

return list

matrix Y[`n',1]=r(N)
matrix Y[`n',2]=r(mean)
matrix Y[`n',3]=r(sd)
matrix Y[`n',4]=r(min)
matrix Y[`n',5]=r(max)

frmttable using "$tabfolder/matrix_lag_b_cit_average.tex", tex fragment replace sdec(0,2,2,0,0) /// 
	statmat(Y) 	///
ctitles("","No. Patents","Mean", "SD", "Min", "Max") ////
rtitles("1975"\"1980"\"1985"\ "1990"\"1995"\"2000"\"2005"\"2010"\"2015"\"2020") title("Mean Backward Lag (in years)")

}

restore

}

*mean Backward Lag (in years) - Year 2000's
{
preserve
duplicates drop patent, force

*cohorts every five years

matrix A=J(5,5,.)

foreach n of numlist 1/5{

summ mean_pat_age if gr_2kyr==`n'
return list
matrix A[`n',1]=r(N)
matrix A[`n',2]=r(mean)
matrix A[`n',3]=r(sd)
matrix A[`n',4]=r(min)
matrix A[`n',5]=r(max)

frmttable using "$tabfolder/matrix_b_cit_y2k.tex", tex fragment replace sdec(0,2,2,0,0) /// 
	statmat(A) 	///
ctitles("","No. Patents","Mean", "SD", "Min", "Max") ////
rtitles("2005-2007"\"2008-2010"\ "2011-2013"\ "2014-2016"\"2017-2019") title("Mean Backward Lag (in years)")

}
restore
}

*open new data
{
use "$datasets/b_cit_patent.dta", clear

drop if b_cit==.

br b_cit_unident b_cit_ident b_cit share_unident


local t=0
global g share_unident b_cit b_cit3 b_cit5 b_cit8


drop if appyear<1975
drop if appyear>2015

merge 1:1 patent using "$datasets/ipc3_for_cit.dta"
drop if _m==2
drop _m

merge 1:1 patent using "$datasets/patents_uspto_for_cit.dta", keepusing(gyear)
drop if _m==2
drop _m

gen ipc1=substr(ipc3,1,1)

drop if ipc1==""
drop ipc3
}

*b_cit_unident b_cit b_cit3 b_cit5 b_cit8 by ipc1
{

preserve

collapse (mean) share_unident b_cit b_cit3 b_cit5 b_cit8 , by(appyear ipc1)

local t=0

global g share_unident b_cit b_cit3 b_cit5 b_cit8

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
local lb "% of Cites Made with Unknown AppYear"
}

if `t'==2{
local lb "Backward Citations"
}

if `t'==3{
local lb "Backward Citations (3-Year)"
}

if `t'==4{
local lb "Backward Citations (5-Year)"
}

if `t'==5{
local lb "Backward Citations (8-Year)"
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

*b_cit_unident b_cit b_cit3 b_cit5 b_cit8
{

preserve

collapse (mean) share_unident b_cit b_cit3 b_cit5 b_cit8 , by(appyear)

local t=0

global g share_unident b_cit b_cit3 b_cit5 b_cit8

foreach k of global g{
local ++t

if `t'==1{
local lb "% of Cites Made with Unknown AppYear"
}

if `t'==2{
local lb "Backward Citations"
}

if `t'==3{
local lb "Backward Citations (3-Year)"
}

if `t'==4{
local lb "Backward Citations (5-Year)"
}

if `t'==5{
local lb "Backward Citations (8-Year)"
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

*b_cit_unident b_cit b_cit3 b_cit5 b_cit8 by ipc1 - grant year
{

preserve

collapse (mean) share_unident b_cit b_cit3 b_cit5 b_cit8 , by(gyear ipc1)

local t=0

global g share_unident b_cit b_cit3 b_cit5 b_cit8

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
local lb "% of Cites Made with Unknown AppYear"
}

if `t'==2{
local lb "Backward Citations"
}

if `t'==3{
local lb "Backward Citations (3-Year)"
}

if `t'==4{
local lb "Backward Citations (5-Year)"
}

if `t'==5{
local lb "Backward Citations (8-Year)"
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


*b_cit_unident b_cit b_cit3 b_cit5 b_cit8 - grant year
{

preserve

collapse (mean) share_unident b_cit b_cit3 b_cit5 b_cit8 , by(gyear)

local t=0

global g share_unident b_cit b_cit3 b_cit5 b_cit8

foreach k of global g{
local ++t

if `t'==1{
local lb "% of Cites Made with Unknown AppYear"
}

if `t'==2{
local lb "Backward Citations"
}

if `t'==3{
local lb "Backward Citations (3-Year)"
}

if `t'==4{
local lb "Backward Citations (5-Year)"
}

if `t'==5{
local lb "Backward Citations (8-Year)"
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
