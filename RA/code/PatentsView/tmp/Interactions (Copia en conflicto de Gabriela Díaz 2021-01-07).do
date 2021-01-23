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
* Survival measure
**********************************************************************************************

use "$datasets/Patentsview_Main.dta", clear

keep patent appyear date categ1 tsize invseq ipc3 appdate inventor_id
																				
/*
*to test code
gen obs=_n
keep if obs<=1000000
*/

enerate inventor year
sort categ1 appyear

bys categ1 (appyear) : egen iyear=min(appyear)

gen pat_inv_expr=appyear-iyear

*inventor order
sort patent appdate
bys patent (invseq): gen invord=_n

*count running patent by inventors (total patents foreach inventor) - sorted by appdate
bys categ1 (appdate): gen rpat=_n

compress

order patent categ1 appyear appdate

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

*create an unique id for invent-coinv group (order matters)
egen g_coinv = group(id_inv id_coinv)


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

compress

drop numid2

rename pat_inv_expr age

*****************************
*	dummy
******************************

*dummy of change of appyear. Patents are sorted by year. Every new year there is a dummy=1
sort appyear 
gen dyear=1 if appyear[_n]!=appyear[_n-1]

*dummy of change of patent 
sort patent id_inv rpat
gen dpat=1 if patent[_n]!=patent[_n-1]

*dummy of change of inventor
sort id_inv
gen dinv=1 if id_inv[_n]!=id_inv[_n-1]

*dummy change inventor - patent
bys id_inv (rpat) : gen d_pat_inv=1 if rpat[_n]!=rpat[_n-1]


*************************************************************************************
*Number of coinventors for each inventor, on each patent - Needs to match with tsize-1			*
***************************************************************************************
{
bys id_inv rpat : gen no_tot_coinv=_N
gen no_tot_coinv2=tsize-1

*This creates a dataset in inventor-patent level.
preserve
duplicates drop id_inv patent, force
drop id_coinv
collapse (mean) no_tot_coinv no_tot_coinv2, by (appyear)
*graph
restore 

}

*********************************
*By Running Patent				*
*********************************
{

*drep_coinv------->identifies for each inv that repeats coinventor in next patent. =1 if in the next patent repeats that coinventor. 
 
bys id_inv (id_coinv rpat) : gen drep_coinv=1 if id_coinv[_n]==id_coinv[_n+1]
	replace drep_coinv=0 if drep_coinv==.	

	 br if id_inv==2895138
	 br if id_inv==86
	 
**Optional - No. Times inventor repeats a coinventor

*Counter - Number of times inventor repeats patent with each coinventor

bys id_inv id_coinv (rpat): gen cont_rep_coinv=_n if rpat[_n]!=rpat[_n+1]


/*
*Times that each inventor repeats coinventor
bys id_inv id_coinv: egen times_rep_coinv=max(cont_rep_coinv)

*Max times an inventor repeats a coinventor
bys id_inv : egen max_rep_coinv=max(times_rep_coinv)
*/

*-----1) Distinct Coinventors by Pat Count

gen dfirstpat_coinv=1 if cont_rep_coinv==1
replace dfirstpat_coinv=0 if dfirstpat_coinv==.

*Number of distinct coinventors per patent
bys id_inv rpat: egen no_dist_coinv_pat=total(dfirstpat_coinv)
bys id_inv (rpat): gen num_dist_coinv_cum=sum(no_dist_coinv_pat) if d_pat_inv==1

*--2) Cumulative number of interactions by patent count

bys id_inv (rpat) : gen num_coinv_cum=sum(no_tot_coinv) if d_pat_inv==1

*Collapse data for graphs
preserve
keep if d_pat_inv==1
save "$datasets/no_dist_coinv.dta", replace

drop id_coinv

*bys id_inv (rpat) : gen num_dist_coinv_cum2=sum(no_dist_coinv_pat)

bys rpat: gen no_inventors=_N

collapse (mean) num_dist_coinv_cum no_inventors num_coinv_cum, by(rpat)

graph set window fontface "Garamond"
global size_font large // medlarge //
global save_fig   1 //0 // 


global ipat 0 //initial year of plots
global fpat 350 //final year of plots

twoway (connected  num_dist_coinv_cum rpat if rpat<=350, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(50)$fpat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulative Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_count.pdf", replace as(pdf)
}

global ipat 0 //initial year of plots
global fpat 350 //final year of plots

twoway (connected  num_coinv_cum rpat if rpat<=350, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(50)$fpat , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulative Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_count.pdf", replace as(pdf)
}

restore


}

**********************************
*By Inventor Experience			 *
**********************************
{
*Counter - we want to retrieve only one observation id_inv, id_coinv, age

sort id_inv id_coinv (age)

bys id_inv id_coinv age: gen tmp_cont_rep_coinv_age=_n

*dummy for first interaction in the inventors age
gen first_coinv_age=1 if tmp_cont_rep_coinv_age==1

preserve

keep if first_coinv_age==1

save "$datasets/inv_age_coinv.dta", replace

use "$datasets/inv_age_coinv.dta", clear

drop tmp_cont_rep_coinv_age first_coinv_dec

*dummy change inventor - age
bys id_inv (age) : gen d_age_inv=1 if age[_n]!=age[_n-1]

*proof
br id_inv id_coinv age first_coinv_dec tmp_cont_rep_coinv_age

*create counter for each obs in each year
bys id_inv id_coinv (age): gen cont_rep_coinv_age=_n if age[_n]!=age[_n+1]

*-----1) Distinct Coinventors by Pat Count

gen dfirstpat_coinv_age=1 if cont_rep_coinv_age==1
replace dfirstpat_coinv_age=0 if dfirstpat_coinv_age==.

*Number of distinct coinventors per patent
bys id_inv age: egen no_dist_coinv_pat_age=total(dfirstpat_coinv_age)

*proof
br if id_inv==617754 & id_coinv==955144
br id_inv id_coinv age d_age_inv cont_rep_coinv_age dfirstpat_coinv_age no_dist_coinv_pat_age if id_inv==617754

bys id_inv (age): gen num_dist_coinv_cum_age=sum(no_dist_coinv_pat_age) if d_age_inv==1

*--2) Cumulative number of interactions by patent count
bys id_inv age : gen tmp_num_coinv_age=_N
bys id_inv (age) : gen num_coinv_cum_age=sum(tmp_num_coinv_age) if d_age_inv==1



collapse (mean) num_dist_coinv_cum_age num_coinv_cum_age, by(age)

graph set window fontface "Garamond"
global size_font large // medlarge //
global save_fig   1 //0 // 


global iage 0 //initial year of plots
global fage 40 //final year of plots

twoway (connected  num_dist_coinv_cum_age age, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience (Age)",height(8) size($size_font)) xlabel($iage(5)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulative Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_inv_exp.pdf", replace as(pdf)
}

global ipat 0 //initial year of plots
global fpat 40 //final year of plots

twoway (connected  num_coinv_cum_age age, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience (Age)",height(8) size($size_font)) xlabel($iage(5)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulative Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_inv_exp.pdf", replace as(pdf)
}

restore

}


**********************************
*By Decade of Experience		 *
**********************************

{

gen decade=.
replace decade=1 if age>=0 & age<=9 
replace decade=2 if age>=10 & age<=19
replace decade=3 if age>=20 & age<=29 
replace decade=4 if age>=30 & age<=40 



sort id_inv id_coinv (decade)

bys id_inv id_coinv decade: gen tmp_cont_rep_coinv_dec=_n

*dummy for first interaction in the inventors age
gen first_coinv_dec=1 if tmp_cont_rep_coinv_dec==1

preserve

keep if first_coinv_dec==1

save "$datasets/inv_dec_coinv.dta", replace


use "$datasets/inv_dec_coinv.dta", clear

br id_inv id_coinv decade tmp_cont_rep_coinv_dec first_coinv_dec
drop tmp_cont_rep_coinv_dec first_coinv_dec

 
*dummy change inventor - age
bys id_inv (decade) : gen d_dec_inv=1 if decade[_n]!=decade[_n-1]


*create counter for each obs in each year
bys id_inv id_coinv (decade): gen cont_rep_coinv_dec=_n if decade[_n]!=decade[_n+1]

*-----1) Distinct Coinventors by Pat Count

gen dfirstpat_coinv_dec=1 if cont_rep_coinv_dec==1
replace dfirstpat_coinv_dec=0 if dfirstpat_coinv_dec==.

*Number of distinct coinventors per patent
bys id_inv decade: egen no_dist_coinv_pat_dec=total(dfirstpat_coinv_dec)


*proof
br if id_inv==617754 & id_coinv==955144
br id_inv id_coinv d_dec_inv decade cont_rep_coinv_dec dfirstpat_coinv_dec no_dist_coinv_pat_dec if id_inv==617754


bys id_inv (decade): gen num_dist_coinv_cum_dec=sum(no_dist_coinv_pat_dec) if d_dec_inv==1

*--2) Cumulative number of interactions by patent count
bys id_inv decade : gen tmp_num_coinv_dec=_N
bys id_inv (decade) : gen num_coinv_cum_dec=sum(tmp_num_coinv_dec) if d_dec_inv==1


collapse (mean) num_dist_coinv_cum_dec num_coinv_cum_dec, by(decade)

graph set window fontface "Garamond"
global size_font large // medlarge //
global save_fig   1 //0 // 


global iage 1 //initial year of plots
global fage 4 //final year of plots

twoway (connected  num_dist_coinv_cum_dec decade, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience in Decades",height(8) size($size_font)) xlabel($iage(1)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulative Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_inv_exp_dec.pdf", replace as(pdf)
}

global ipat 1 //initial year of plots
global fpat 4 //final year of plots

twoway (connected  num_coinv_cum_dec decade, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Inventor Experience in Decades",height(8) size($size_font)) xlabel($iage(1)$fage , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Cumulative Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white)) size(med) ) 

if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_inv_exp_dec.pdf", replace as(pdf)
}

restore

}


