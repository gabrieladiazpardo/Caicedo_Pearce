*********************************
*		Skills					*
*								*
*********************************
global figfolder="$main/RA/reports/Fall of Generalists/Second Version/Skills/figures"
global tabfolder="$main/RA/reports/Fall of Generalists/Second Version/Skills/tables"

**Saving options
global save_fig 1 //  0 //
global save_dataset  0 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font med // medlarge //



**********************************************************************************************
* Open data
**********************************************************************************************

use "$datasets/Patentsview_Main.dta", clear

*Forward Citations Measures
keep patent gyear date appyear appdate categ1 invseq inventor_id ipc3 assignee tsize f_cit cit3 cit5 cit8 exp_cit_adj f_cit3 f_cit5 f_cit8

sort categ1 appyear

bys categ1 (appyear) : egen iyear=min(appyear)

gen age=appyear-iyear

*inventor order
sort patent appdate
bys patent (invseq): gen invord=_n

*count running patent by inventors (total patents foreach inventor) - sorted by appdate
bys categ1 (appdate): gen rpat=_n

compress

order patent categ1 appyear appdate rpat


*Group every 10 years
gen gr_10yr=1 if appyear>=1975 & appyear<=1984
	replace gr_10yr=2 if appyear>=1985 & appyear<=1994
	replace gr_10yr=3 if appyear>=1995 & appyear<=2004
	replace gr_10yr=4 if appyear>=2005 & appyear<=2014

	
/*
*Producitvity Measures
global j f_cit3 f_cit5

foreach k of global j{
replace `k'=0 if f_cit==0 & `k'==.
}
*/


*--Cumulative number of citations with 3 yr f cit

gen mg_pr_3yr_fcit=f_cit3
bys categ1 (rpat): gen pr_3yr_fcit=sum(mg_pr_3yr_fcit)


*--Cumulative number of citations with 5 yr f cit
gen mg_pr_5yr_fcit=f_cit5
bys categ1 (rpat): gen pr_5yr_fcit=sum(mg_pr_5yr_fcit)


*--Cumulative number of citations with f cit
gen mg_pr_fcit=f_cit
bys categ1 (rpat): gen pr_fcit=sum(mg_pr_fcit)


*--Cumulative number of citations with 3 yr f cit by tsize
gen mg_pr_3yr_fcit_tsize=f_cit3/tsize
bys categ1 (rpat): gen pr_3yr_fcit_tsize=sum(mg_pr_3yr_fcit_tsize)


*--Cumulative number of citations with 5 yr f cit by tsize
gen mg_pr_5yr_fcit_tsize=f_cit5/tsize
bys categ1 (rpat): gen pr_5yr_fcit_tsize=sum(mg_pr_5yr_fcit_tsize)


*--Cumulative number of citations with f cit by tsize
gen mg_pr_fcit_tsize=f_cit/tsize
bys categ1 (rpat): gen pr_fcit_tsize=sum(mg_pr_fcit_tsize)

*Number of inventors by running patent
bys rpat: gen no_inventors=_N

*br
br patent inventor_id f_cit f_cit3 f_cit5 mg_pr_fcit mg_pr_5yr_fcit mg_pr_3yr_fcit

*---Interactions
gen inter_pat=tsize-1
bys categ1 (rpat): gen inter_cum=sum(inter_pat)


order patent inventor_id categ1 rpat tsize f_cit mg_pr_fcit pr_fcit pr_fcit_tsize mg_pr_fcit_tsize f_cit3 mg_pr_3yr_fcit pr_3yr_fcit pr_3yr_fcit_tsize mg_pr_3yr_fcit_tsize f_cit5 mg_pr_5yr_fcit pr_5yr_fcit pr_5yr_fcit_tsize mg_pr_5yr_fcit_tsize
br patent inventor_id categ1 rpat tsize f_cit mg_pr_fcit pr_fcit pr_fcit_tsize mg_pr_fcit_tsize f_cit3 mg_pr_3yr_fcit pr_3yr_fcit pr_3yr_fcit_tsize mg_pr_3yr_fcit_tsize f_cit5 mg_pr_5yr_fcit pr_5yr_fcit pr_5yr_fcit_tsize mg_pr_5yr_fcit_tsize


*******************************
*		Rpat 
********************************
{

preserve

collapse (mean) pr_* mg_* no_inventors, by(rpat)

save "$datasets/product_rpat.dta", replace

summ rpat [aw=no_inventors], d
return list
local fpat `r(p90)'
local ypat `r(p99)'

global ipat 0 //initial year of plots
global fpat `fpat' //final year of some plots
global ypat `ypat' //final year of some plots


global g pr_3yr_fcit pr_5yr_fcit pr_fcit pr_3yr_fcit_tsize pr_5yr_fcit_tsize pr_fcit_tsize

local t=0

foreach k of global g{
local ++t

if `t'==1{
local lb "Productivity 3yr Fcit"
}

if `t'==2{
local lb "Productivity 5yr Fcit "
}

if `t'==3{
local lb "Productivity Fcit"
}

if `t'==4{
local lb "Productivity 3yr Fcit/Tsize"
}

if `t'==5{
local lb "Productivity 5yr Fcit/Tsize"
}

if `t'==6{
local lb "Productivity Fcit/Tsize"
}

twoway (connected `k' rpat if rpat<=`fpat', lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_$fpat.pdf", replace as(pdf)
}

twoway (connected `k' rpat if rpat<=`ypat', lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_$ypat.pdf", replace as(pdf)
}

}


global g mg_pr_3yr_fcit mg_pr_5yr_fcit mg_pr_fcit mg_pr_3yr_fcit_tsize mg_pr_5yr_fcit_tsize mg_pr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 5yr Fcit - Marginal"
}

if `m'==3{
local lb "Productivity Fcit - Marginal"
}

if `m'==4{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

if `m'==5{
local lb "Productivity 5yr Fcit/Tsize - Marginal"
}

if `m'==6{
local lb "Productivity Fcit/Tsize - Marginal"
}

twoway (connected `k' rpat if rpat<=`fpat', lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_$fpat.pdf", replace as(pdf)
}

twoway (connected `k' rpat if rpat<=`ypat', lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_$ypat.pdf", replace as(pdf)
}

}


restore
}

*******************************
*		Rpat and Decade
********************************
{
preserve

collapse (mean) pr_* mg_* no_inventors, by(rpat gr_10yr)

save "$datasets/product_rpat_gr_10yr.dta", replace

drop if  gr_10yr==.

global g pr_3yr_fcit pr_5yr_fcit pr_fcit pr_3yr_fcit_tsize pr_5yr_fcit_tsize pr_fcit_tsize
local t=0

foreach k of global g{
local ++t

if `t'==1{
local lb "Productivity 3yr Fcit"
}

if `t'==2{
local lb "Productivity 5yr Fcit"
}

if `t'==3{
local lb "Productivity Fcit"
}

if `t'==4{
local lb "Productivity 3yr Fcit/Tsize "
}

if `t'==5{
local lb "Productivity 5yr Fcit/Tsize"
}

if `t'==6{
local lb "Productivity Fcit/Tsize"
}

twoway (line `k' rpat if  gr_10yr==1 & rpat<=`fpat' , lcolor(navy) lwidth(medthick))  ///
(line `k' rpat if gr_10yr==2 & rpat<=`fpat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' rpat if gr_10yr==3 & rpat<=`fpat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' rpat if  gr_10yr==4 & rpat<=`fpat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_gr_10yr_$fpat.pdf", replace as(pdf)
}


twoway (line `k' rpat if  gr_10yr==1 & rpat<=`ypat' , lcolor(navy) lwidth(medthick))  ///
(line `k' rpat if gr_10yr==2 & rpat<=`ypat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' rpat if gr_10yr==3 & rpat<=`ypat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' rpat if  gr_10yr==4 & rpat<=`ypat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_gr_10yr_$ypat.pdf", replace as(pdf)
}

}


global g mg_pr_3yr_fcit mg_pr_5yr_fcit mg_pr_fcit mg_pr_3yr_fcit_tsize mg_pr_5yr_fcit_tsize mg_pr_fcit_tsize

local m=0

foreach k of global g{
local ++m


if `m'==1{
local lb "Productivity 3yr Fcit (Marginal)"
}

if `m'==2{
local lb "Productivity 5yr Fcit (Marginal)"
}

if `m'==3{
local lb "Productivity Fcit (Marginal)"
}

if `m'==4{
local lb "Productivity 3yr Fcit/Tsize (Marginal)"
}

if `m'==5{
local lb "Productivity 5yr Fcit/Tsize (Marginal)"
}

if `m'==6{
local lb "Productivity Fcit/Tsize (Marginal)"
}

twoway (line `k' rpat if  gr_10yr==1 & rpat<=`fpat' , lcolor(navy) lwidth(medthick))  ///
(line `k' rpat if gr_10yr==2 & rpat<=`fpat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' rpat if gr_10yr==3 & rpat<=`fpat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' rpat if  gr_10yr==4 & rpat<=`fpat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_gr_10yr_$fpat.pdf", replace as(pdf)
}

twoway (line `k' rpat if  gr_10yr==1 & rpat<=`ypat' , lcolor(navy) lwidth(medthick))  ///
(line `k' rpat if gr_10yr==2 & rpat<=`ypat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' rpat if gr_10yr==3 & rpat<=`ypat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' rpat if  gr_10yr==4 & rpat<=`ypat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_gr_10yr_$ypat.pdf", replace as(pdf)
}

}

restore

}

*********************************
*		Age
*********************************

{

preserve

collapse (mean) pr_* mg_*  no_inventors, by(age)

save "$datasets/product_age.dta", replace

global ipat 0 //initial year of plots
global fpat 20 //final year of plots

global g pr_3yr_fcit pr_5yr_fcit pr_fcit pr_3yr_fcit_tsize pr_5yr_fcit_tsize pr_fcit_tsize

local t=0

foreach k of global g{
local ++t


if `t'==1{
local lb "Productivity 3yr Fcit"
}

if `t'==2{
local lb "Productivity 5yr Fcit"
}

if `t'==3{
local lb "Productivity Fcit"
}

if `t'==4{
local lb "Productivity 3yr Fcit/Tsize"
}

if `t'==5{
local lb "Productivity 5yr Fcit/Tsize"
}

if `t'==6{
local lb "Productivity Fcit/Tsize"
}

twoway (connected `k' age if age<=$fpat, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Age of the Inventor",height(8) size($size_font)) xlabel($ipat(2)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/`k'_age_$fpat.pdf", replace as(pdf)
}

}


global g mg_pr_3yr_fcit mg_pr_5yr_fcit mg_pr_fcit mg_pr_3yr_fcit_tsize mg_pr_5yr_fcit_tsize mg_pr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 5yr Fcit - Marginal"
}

if `m'==3{
local lb "Productivity Fcit - Marginal"
}

if `m'==4{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

if `m'==5{
local lb "Productivity 5yr Fcit/Tsize - Marginal"
}

if `m'==6{
local lb "Productivity Fcit/Tsize - Marginal"
}

twoway (connected `k' age if age<=$fpat , lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Age of the Inventor",height(8) size($size_font)) xlabel($ipat(2)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white)))

if $save_fig==1 {
graph export "$figfolder/`k'_age_$fpat.pdf", replace as(pdf)
}

}

restore
}

*******************************
*		Age and Decade
********************************
{
preserve

collapse (mean) pr_* mg_* no_inventors, by(age gr_10yr)

save "$datasets/product_age_gr_10yr.dta", replace

drop if  gr_10yr==.

global g pr_3yr_fcit pr_5yr_fcit pr_fcit pr_3yr_fcit_tsize pr_5yr_fcit_tsize pr_fcit_tsize

local t=0

foreach k of global g{
local ++t


if `t'==1{
local lb "Productivity 3yr Fcit"
}

if `t'==2{
local lb "Productivity 5yr Fcit"
}

if `t'==3{
local lb "Productivity Fcit "
}

if `t'==4{
local lb "Productivity 3yr Fcit/Tsize"
}

if `t'==5{
local lb "Productivity 5yr Fcit/Tsize"
}

if `t'==6{
local lb "Productivity Fcit/Tsize"
}

twoway (line `k' age if  gr_10yr==1 & age<=$fpat , lcolor(navy) lwidth(medthick))  ///
(line `k' age if gr_10yr==2 & age<=$fpat, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' age if gr_10yr==3 & age<=$fpat, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' age if  gr_10yr==4 & age<=$fpat, lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Age of Inventor",height(8) size($size_font)) xlabel($ipat(2)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_age_gr_10yr_$fpat.pdf", replace as(pdf)
}
}



global g mg_pr_3yr_fcit mg_pr_5yr_fcit mg_pr_fcit mg_pr_3yr_fcit_tsize mg_pr_5yr_fcit_tsize mg_pr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 5yr Fcit - Marginal"
}

if `m'==3{
local lb "Productivity Fcit - Marginal"
}

if `m'==4{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

if `m'==5{
local lb "Productivity 5yr Fcit/Tsize - Marginal"
}

if `m'==6{
local lb "Productivity Fcit/Tsize - Marginal"
}

twoway (line `k' age if  gr_10yr==1 & age<=$fpat , lcolor(navy) lwidth(medthick))  ///
(line `k' age if gr_10yr==2 & age<=$fpat , lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' age if gr_10yr==3 & age<=$fpat , lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' age if  gr_10yr==4 & age<=$fpat , lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Age of Inventor",height(8) size($size_font)) xlabel($ipat(2)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_age_gr_10yr_$fpat.pdf", replace as(pdf)
}

}


restore
}


*********************************
*		Interactions
*********************************

*Number of inventors by running patent
bys inter_cum: gen no_inventors_intr=_N

summ inter_cum, d //this shall coincide with the weighted summ after the collapse

{

preserve

collapse (mean) pr_* mg_* no_inventors_intr, by(inter_cum)

save "$datasets/product_inter.dta", replace

summ inter_cum [aw=no_inventors_intr], d
return list
local fintr `r(p90)'

global iintr 0 //initial year of plots
global fintr `fintr' //final year of plots

global g pr_3yr_fcit pr_5yr_fcit pr_fcit pr_3yr_fcit_tsize pr_5yr_fcit_tsize pr_fcit_tsize

local t=0

foreach k of global g{
local ++t

if `t'==1{
local lb "Productivity 3yr Fcit"
}

if `t'==2{
local lb "Productivity 5yr Fcit "
}

if `t'==3{
local lb "Productivity Fcit"
}

if `t'==4{
local lb "Productivity 3yr Fcit/Tsize"
}

if `t'==5{
local lb "Productivity 5yr Fcit/Tsize"
}

if `t'==6{
local lb "Productivity Fcit/Tsize"
}

twoway (connected `k' inter_cum if inter_cum<=`fintr', lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Total interactions",height(8) size($size_font)) xlabel($iintr(10)$fintr, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'_inter_$fintr.pdf", replace as(pdf)
}

}


global g mg_pr_3yr_fcit mg_pr_5yr_fcit mg_pr_fcit mg_pr_3yr_fcit_tsize mg_pr_5yr_fcit_tsize mg_pr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 5yr Fcit - Marginal"
}

if `m'==3{
local lb "Productivity Fcit - Marginal"
}

if `m'==4{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

if `m'==5{
local lb "Productivity 5yr Fcit/Tsize - Marginal"
}

if `m'==6{
local lb "Productivity Fcit/Tsize - Marginal"
}

twoway (connected `k' inter_cum if inter_cum<=`fintr', lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Total interactions",height(8) size($size_font)) xlabel($iintr(10)$fintr, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/`k'_inter_$fintr.pdf", replace as(pdf)
}

}

restore
}


*********************************
*	Interactions and Decades
*********************************
{

preserve

collapse (mean) pr_* mg_* no_inventors_intr, by(inter_cum gr_10yr)

save "$datasets/product_inter_gr_10yr.dta", replace

drop if  gr_10yr==.

global g pr_3yr_fcit pr_5yr_fcit pr_fcit pr_3yr_fcit_tsize pr_5yr_fcit_tsize pr_fcit_tsize
local t=0

foreach k of global g{
local ++t

if `t'==1{
local lb "Productivity 3yr Fcit"
}

if `t'==2{
local lb "Productivity 5yr Fcit"
}

if `t'==3{
local lb "Productivity Fcit"
}

if `t'==4{
local lb "Productivity 3yr Fcit/Tsize "
}

if `t'==5{
local lb "Productivity 5yr Fcit/Tsize"
}

if `t'==6{
local lb "Productivity Fcit/Tsize"
}

twoway (line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==1, lcolor(navy) lwidth(medthick))  ///
(line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==4, lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Total interactions",height(8) size($size_font)) xlabel($iintr(10)$fintr, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_inter_gr_10yr_$fintr.pdf", replace as(pdf)
}

}


global g mg_pr_3yr_fcit mg_pr_5yr_fcit mg_pr_fcit mg_pr_3yr_fcit_tsize mg_pr_5yr_fcit_tsize mg_pr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 5yr Fcit - Marginal"
}

if `m'==3{
local lb "Productivity Fcit - Marginal"
}

if `m'==4{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

if `m'==5{
local lb "Productivity 5yr Fcit/Tsize - Marginal"
}

if `m'==6{
local lb "Productivity Fcit/Tsize - Marginal"
}

twoway (line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==1, lcolor(navy) lwidth(medthick))  ///
(line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==2, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==3, lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line `k' inter_cum if inter_cum<=`fintr' & gr_10yr==4, lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Total interactions",height(8) size($size_font)) xlabel($iintr(10)$fintr, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font))  ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig==1 {
graph export "$figfolder/`k'_inter_gr_10yr_$fintr.pdf", replace as(pdf)
}

}

restore

}


*************************
*	Temporary Graphs
**************************

preserve
collapse (mean) f_cit f_cit3 f_cit5 mg_pr_fcit mg_pr_5yr_fcit mg_pr_3yr_fcit no_inventors, by(rpat)
save "$datasets/fcit_rpat.dta", replace
restore
