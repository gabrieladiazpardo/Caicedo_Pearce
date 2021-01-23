******************************************************
*		Interactions
*
****************************************************

global figfolder="$main/RA/reports/Fall of Generalists/Second Version/Interactions/figures"
global tabfolder="$main/RA/reports/Fall of Generalists/Second Version/Interactions/tables"

**Saving options
global save_fig 1 //  0 //
global save_dataset  0 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font large // medlarge //


**********************************************************************************************
* Open data
**********************************************************************************************

use "$datasets/Patentsview_Main.dta", clear

keep patent appyear date categ1 tsize invseq ipc3 appdate inventor_id
																				
/*
*to test code
gen obs=_n
keep if obs<=1000000
*/

*generate inventor year
sort categ1 appyear

bys categ1 (appyear) : egen iyear=min(appyear)

gen age=appyear-iyear

*inventor order
sort patent appdate
bys patent (invseq): gen invord=_n

*count running patent by inventors (total patents foreach inventor) - sorted by appdate
bys categ1 (appdate): gen rpat=_n

compress

order patent categ1 appyear appdate

********************
*Solo patents Dataset
********************

preserve
keep if tsize==1
gen solo=1
save "$datasets/solo_pats.dta", replace
restore

expand tsize
sort patent categ1

*counter that identifies the number of diferent observations of the same inventor in a patent. This is an input to create co-inventor id.

bys patent categ1: gen numid2 = _n

*generar id del coinventor 
by patent: gen id_coinv = categ1[tsize * numid2]

rename categ1 id_inv

sort patent id_inv rpat

*drop same pairs (including patents of tsize=1)
drop if id_inv==id_coinv

*identify group unique groups inv-coinv
order patent appdate appyear id_inv id_coinv

*******************************************************
*	Create Unique ID for Pair (order matters)  *
*******************************************************

*create an unique id for invent-coinv group (order matters)
egen g_coinv = group(id_inv id_coinv)

*******************************************************
*	Create Unique ID for Pair (order doesn't matter)  *
*******************************************************

*string for unique pair
tostring id_inv, replace
tostring id_coinv, replace

*dummy for dyad pair
generate first = cond(id_inv < id_coinv, id_inv, id_coinv)
generate second = cond(id_inv < id_coinv, id_coinv, id_inv)

*unique pair numner
egen id = group(first second)

drop first second

*back to numeric
destring id_inv, replace
destring id_coinv, replace

********************************
*Append Solo Patents
*********************************

compress
drop numid2

rename id_inv categ1
append using "$datasets/solo_pats.dta"
rename categ1 id_inv 
sort id_inv rpat
replace solo=0 if solo==.

*replace data for solo patents
replace id_coinv=id_inv if solo==1

*****************************
*	Dummy's for change
******************************
*dummy for change inventor - patent
bys id_inv (rpat) : gen d_pat_inv=1 if rpat[_n]!=rpat[_n-1]

*Group every 10 years
gen gr_10yr=1 if appyear>=1975 & appyear<=1984
	replace gr_10yr=2 if appyear>=1985 & appyear<=1994
	replace gr_10yr=3 if appyear>=1995 & appyear<=2004
	replace gr_10yr=4 if appyear>=2005 & appyear<=2014

	
*************************************************************************************
*Number of coinventors for each inventor, on each patent - Needs to match with tsize-1			*
***************************************************************************************
{

*create total number of coinventors
bys id_inv rpat : gen no_tot_coinv=_N if solo!=1
replace no_tot_coinv=0 if solo==1

gen no_tot_coinv2=tsize-1

*This creates a dataset in inventor-patent level.

preserve

duplicates drop id_inv patent, force

drop id_coinv

global nosolo 0


if $nosolo==1 {
local d_solo drop if solo==1
local nosolo _nosolo
`d_solo'
}

collapse (mean) no_tot_coinv no_tot_coinv2, by (appyear)
save "$datasets/tot_no_coinv`nosolo'.dta", replace

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots



twoway (connected  no_tot_coinv appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))


if $save_fig ==1 {
graph export "$figfolder/no_coinv`nosolo'.pdf", replace as(pdf)
}

restore 





}

*********************************
*By Running Patent				*
*********************************
{

*Creation of Variables
{

*Counter --------> Number of times inventor repeats patent with each coinventor

bys id_inv id_coinv (rpat): gen cont_rep_coinv=_n if rpat[_n]!=rpat[_n+1] & solo!=1

	 br if id_inv==2895138
	 br if id_inv==1384659
	 
replace cont_rep_coinv=0 if solo==1

*----- Distinct Coinventors by Pat Count

gen dfirstpat_coinv=1 if cont_rep_coinv==1
replace dfirstpat_coinv=0 if dfirstpat_coinv==.

*---Number of distinct coinventors per patent - all obs
bys id_inv rpat: egen no_dist_coinv_pat=total(dfirstpat_coinv)

*---Number of distinct coinventors per patent - Not Cumulative
gen no_dist_coinv_per_pat=no_dist_coinv_pat if d_pat_inv==1


		*proof
		br if id_inv==2895138
		br if id_inv==1384659
		

*--- Cumulative number of distinct coinventors
bys id_inv (rpat): gen num_dist_coinv_cum=sum(no_dist_coinv_pat) if d_pat_inv==1

*proof
br if id_inv==877339
br if d_pat_inv==1 & id_inv==1384659

*--Cumulative number of coinventors interactions by patent count

bys id_inv (rpat) : gen num_coinv_cum=sum(no_tot_coinv) if d_pat_inv==1

}

*Collapse data for graphs - all sample
{
preserve

keep if d_pat_inv==1

drop id_coinv

bys rpat: gen no_inventors=_N

collapse (mean) num_dist_coinv_cum no_inventors num_coinv_cum, by(rpat)

save "$datasets/no_dist_coinv_rpat_appyr.dta", replace

summ rpat [aw=no_inventors], d
return list
local fpat `r(p90)'
local ypat `r(p99)'


global ipat 0 //initial year of plots
global fpat `fpat' //final year of plots
global ypat `ypat' //final year of plots

*distinct
twoway (connected  num_dist_coinv_cum rpat if rpat<=`fpat', lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_count_wd_$fpat.pdf", replace as(pdf)
}

*all
twoway (connected  num_coinv_cum rpat if rpat<=`fpat', lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_count_wd_$fpat.pdf", replace as(pdf)
}


*distinct
twoway (connected  num_dist_coinv_cum rpat if rpat<=$ypat, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_count_wd_$ypat.pdf", replace as(pdf)
}

*all
twoway (connected  num_coinv_cum rpat if rpat<=$ypat , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_count_wd_$ypat.pdf", replace as(pdf)
}

restore
}

*Collapse data for graphs - by decades
{

preserve

keep if d_pat_inv==1

drop id_coinv

bys rpat: gen no_inventors=_N

collapse (mean) num_dist_coinv_cum no_inventors num_coinv_cum no_dist_coinv_per_pat, by(rpat gr_10yr)

save "$datasets/no_dist_coinv_rpat_appyr_gr_10yr.dta", replace

*cum 
twoway (line num_coinv_cum rpat if gr_10yr==1 & rpat<=`fpat' , lcolor(navy) lwidth(medthick))  ///
(line  num_coinv_cum rpat if gr_10yr==2 & rpat<=`fpat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  num_coinv_cum rpat if gr_10yr==3 & rpat<=`fpat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  num_coinv_cum rpat if gr_10yr==4 & rpat<=`fpat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) ///
xlabel($ipat(5)$fpat , labsize($size_font) ) ///
ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))


if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_count_wd_gr_10yr_$fpat.pdf", replace as(pdf)
}

*distinct
twoway (line num_dist_coinv_cum rpat if gr_10yr==1 & rpat<=`fpat' , lcolor(navy) lwidth(medthick))  ///
(line  num_dist_coinv_cum rpat if gr_10yr==2 & rpat<=`fpat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  num_dist_coinv_cum rpat if gr_10yr==3 & rpat<=`fpat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  num_dist_coinv_cum rpat if gr_10yr==4 & rpat<=`fpat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) ///
xlabel($ipat(5)$fpat , labsize($size_font) ) ///
ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))


if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_count_wd_gr_10yr_$fpat.pdf", replace as(pdf)
}



*cum
twoway (line num_coinv_cum rpat if gr_10yr==1 & rpat<=`ypat' , lcolor(navy) lwidth(medthick))  ///
(line  num_coinv_cum rpat if gr_10yr==2 & rpat<=`ypat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  num_coinv_cum rpat if gr_10yr==3 & rpat<=`ypat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  num_coinv_cum rpat if gr_10yr==4 & rpat<=`ypat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_count_wd_gr_10yr_$ypat.pdf", replace as(pdf)
}

*distinct
twoway (line num_dist_coinv_cum rpat if gr_10yr==1 & rpat<=`ypat' , lcolor(navy) lwidth(medthick))  (line  num_dist_coinv_cum rpat if gr_10yr==2 & rpat<=`ypat', lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  num_dist_coinv_cum rpat if gr_10yr==3 & rpat<=`ypat', lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  num_dist_coinv_cum rpat if gr_10yr==4 & rpat<=`ypat', lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(20)$ypat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_count_wd_gr_10yr_$ypat.pdf", replace as(pdf)
}

}

}

**********************************
*By Inventor Experience			 *
**********************************
{

*Counter - we want to retrieve only one observation id_inv, id_coinv, age
*We can have duplicates of age, id_inv and id_coinv. In the same year they patented more than once.
sort id_inv id_coinv (age)

bys id_inv id_coinv age: gen tmp_cont_rep_coinv_age=_n

*dummy for first interaction in the inventors age
gen first_coinv_age=1 if tmp_cont_rep_coinv_age==1

*Create small data
preserve

*We only one to keep one observation of id_ind, id_coinv and age. Solo patents as well. 
keep if first_coinv_age==1

br if id_inv==1384659
	 
drop tmp_cont_rep_coinv_age first_coinv_age

*dummy change inventor - age
bys id_inv (age) : gen d_age_inv=1 if age[_n]!=age[_n-1]

*proof
br id_inv id_coinv age 

*create counter for each obs in each year
bys id_inv id_coinv (age): gen cont_rep_coinv_age=_n if age[_n]!=age[_n+1] & solo!=1
replace cont_rep_coinv_age=0 if solo==1

*first pat
gen dfirstpat_coinv_age=1 if cont_rep_coinv_age==1

*replace cero coinventors for solo patents
replace dfirstpat_coinv_age=0 if dfirstpat_coinv_age==.

*Number of distinct coinventors per patent
bys id_inv age: egen no_dist_coinv_pat_age=total(dfirstpat_coinv_age)

*Generate Number of Distincr Coinventors Per Age (Not Cumulative) - no_dist_coinv_per_age
gen no_dist_coinv_per_age=no_dist_coinv_pat_age if d_age_inv==1

*proof
br id_inv id_coinv age d_age_inv cont_rep_coinv_age dfirstpat_coinv_age no_dist_coinv_pat_age if id_inv==617754

*Cumulative Number of Distinct coinventors by age
bys id_inv (age): gen num_dist_coinv_cum_age=sum(no_dist_coinv_pat_age) if d_age_inv==1

*Number of interactions per Patent
bys id_inv age : gen tmp_num_coinv_age=_N if solo!=1
replace tmp_num_coinv_age=0 if solo==1

*Generate Number of Coinventors Per Age (Not Cumulative) - no_dist_coinv_per_age
gen no_coinv_per_age=tmp_num_coinv_age if d_age_inv==1

*Cumulative Number of Interactons
bys id_inv (age) : gen num_coinv_cum_age=sum(tmp_num_coinv_age) if d_age_inv==1
	
*graphs
save "$datasets/inv_age_coinv.dta", replace

restore


*preserve data
preserve

*open data
use "$datasets/inv_age_coinv.dta", clear

collapse (mean) num_dist_coinv_cum_age no_dist_coinv_per_age no_coinv_per_age num_coinv_cum_age, by(age gr_10yr)

drop if gr_10yr==.

sort gr_10yr age

graph set window fontface "Garamond"
global size_font large // medlarge //
global save_fig   1 //0 // 


global iage 0 //initial year of plots
global fage 20 //final year of plots

twoway (line num_dist_coinv_cum_age age if gr_10yr==1 & age<=$fage , lcolor(navy) lwidth(medthick)) ///
 (line  num_dist_coinv_cum_age age if gr_10yr==2 & age<=$fage , lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  num_dist_coinv_cum_age age if gr_10yr==3 & age<=$fage , lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  num_dist_coinv_cum_age age if gr_10yr==4 & age<=$fage , lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience (Age)",height(8) size($size_font)) xlabel($iage(2)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_inv_exp_gr_10yr.pdf", replace as(pdf)
}


twoway (line num_coinv_cum_age age if gr_10yr==1 & age<=$fage , lcolor(navy) lwidth(medthick)) ///
(line  num_coinv_cum_age age if gr_10yr==2 & age<=$fage , lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
(line  num_coinv_cum_age age if gr_10yr==3 & age<=$fage , lcolor(dkgreen) lwidth(medthick) lpattern("-..")) ///
(line  num_coinv_cum_age age if gr_10yr==4 & age<=$fage , lcolor(gray) lwidth(medthick) lpattern("---")) ///
, ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience (Age)",height(8) size($size_font)) xlabel($iage(2)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "1975-1984") label(2 "1985-1994" ) label(3 "1995-2004") label(4 "2005-2014"))

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_inv_exp_gr_10yr.pdf", replace as(pdf)
}


restore
*open data

preserve

use "$datasets/inv_age_coinv.dta", clear

collapse (mean) num_dist_coinv_cum_age no_dist_coinv_per_age no_coinv_per_age num_coinv_cum_age, by(age)

global iage 0 //initial year of plots
global fage 20 //final year of plots

twoway (connected  num_dist_coinv_cum_age age if age<=$fage , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience (Age)",height(8) size($size_font)) xlabel($iage(2)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_inv_exp.pdf", replace as(pdf)
}


twoway (connected  num_coinv_cum_age age if age<=$fage , lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience (Age)",height(8) size($size_font)) xlabel($iage(2)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_inv_exp.pdf", replace as(pdf)
}


restore

}

