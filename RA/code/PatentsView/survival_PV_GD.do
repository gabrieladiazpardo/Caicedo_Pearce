*******************************************
*	Exploration Survival Measures- GD
*
******************************************

* Survival measures

global figfolder  "$main/output"


**Saving options
global save_fig 1 //  0 //
global save_dataset  1 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font large // medlarge //


**********************************************************************************************
* Survival measure
**********************************************************************************************

use "$datasets/Patentsview_Main.dta", clear

keep patent appyear date categ1 tsize invseq ipc3 appdate
																				
/*
*to test code
gen obs=_n
keep if obs<=1000000
*/

sort patent appyear
bys patent (invseq): gen invord=_n

gen ipc1=substr(ipc3,1,1)

drop ipc3

*count running patent by inventors (total patents foreach inventor)
bys categ1 (appdate): gen rpat=_n

compress

/*
save "$wrkdata/pat_inv_temp.dta", replace
use "$wrkdata/pat_inv_temp.dta", clear
*/

*create all pairs
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

*Create alternative measure for team size
keep if tsize>1

gen tsize2=tsize if tsize<=5
	replace tsize2=5 if tsize>5
	
	
*identify group unique groups inv-coinv
order patent date appyear id_inv id_coinv


*create an unique id for invent-coinv group (order matters)
egen g_coinv = group(id_inv id_coinv)

/*
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
*/

compress


**Identifiers year, patent, inventors

*dummy of change of appyear. Patents are sorted by year. Every new year there is a dummy=1
sort appyear 
gen dyear=1 if appyear[_n]!=appyear[_n-1]

*dummy of change of patent 
sort patent id_inv rpat
gen dpat=1 if patent[_n]!=patent[_n-1]

*dummy of change of inventor
sort id_inv
gen dinv=1 if id_inv[_n]!=id_inv[_n-1]

**Identifiers coinventors

*drep_coinv------->identifies for each inv that repeats coinventor in next patent. =1 if in the next patent repeats that coinventor. 
 
bys id_inv (id_coinv rpat) : gen drep_coinv=1 if id_coinv[_n]==id_coinv[_n+1]
	replace drep_coinv=0 if drep_coinv==.	

	 br if id_inv==2895138
	 br if id_inv==86
	 
**Optional - No. Times inventor repeats a coinventor

/*
*Counter - Number of times inventor repeats patent with each coinventor

bys id_inv id_coinv: gen cont_rep_coinv=_n if rpat[_n]!=rpat[_n+1]

*Times that each inventor repeats coinventor

bys id_inv id_coinv: egen times_rep_coinv=max(cont_rep_coinv)

*Max times an inventor repeats a coinventor

bys id_inv : egen max_rep_coinv=max(times_rep_coinv)

summ max_rep_coinv if dinv==1, d

drop times_rep_coinv
*/



*drep_alo_coinv------->for all the observations pat-inv-coinv all the observations of the inventor in the patent will have a =1 if the inventor repeats at least one coinventor in the next patent

bys id_inv rpat : egen drep_alo_coinv=max(drep_coinv)
	replace drep_alo_coinv=0 if drep_alo_coinv==.
	

*dinv_rpat---------> dummy to identify change in inventor for each running patent (1,2,3,4)	
bys rpat (id_inv appyear): gen dinv_rpat=1 if id_inv[_n-1]~=id_inv[_n]
	replace dinv_rpat=0 if dinv_rpat==.

	*Verify that the total transitions made by an inventor matches with the max number of rpat.
/*
bys id_inv	: egen tot_transitions_inv=total(dinv_rpat)
bys id_inv	: egen max_transitions_inv=max(rpat)
*/
	
*drpat_inv--------> dummy to identify inventors that have next patent (dummys se pone en la última obs del inventor antes de que patente una nueva patente)

bys id_inv (rpat): gen drpat_inv=1 if rpat[_n]~=rpat[_n+1] & rpat[_n+1]!=.
	replace drpat_inv=0 if drpat_inv==.
	 
	 compress

/*No se está exortando el denominador para poder computar las probabilidades ALO y All */

*GD - dnext_pat - Dummy si el individuo tendrá una próxima patente - Intento.
bys id_inv rpat patent:  egen dinv_next_pat=max(drpat_inv)

*--------------------------------------------------
** Probability of at least one repeated coinventor
*--------------------------------------------------

*--No. Inventors that have next patent by appyear:
*count the number of inventors that have a next patent by appyear

bys appyear : egen Ndrpat_inv=total(drpat_inv)

*--No. of Inventors that repeat at least one coinventor in the next patent:
*count the number of inventors that repeated at least one coinventor in next patent

bys appyear : egen Ndrep_alo_coinv=total(drep_alo_coinv*drpat_inv)

*probability of at least one repeated coinventor
gen pr_alo_coinv=Ndrep_alo_coinv/Ndrpat_inv

compress


*-------------------------------------------
** Fraction of repeated coinventors by year
*-------------------------------------------

*Number of repeated coinventors
bys patent : egen Nrep_coinv=total(drep_coinv*drpat_inv)

*fraction of repeated coinventors by patent
gen frac_rep_coinv=Nrep_coinv/tsize

*dummy of patents with inventors that have next patent
bys patent: egen dpat_rpat_inv=max(drpat_inv)
	replace dpat_rpat_inv=. if dpat_rpat_inv==0

*out of all patents
bys appyear : egen mpat_frac_rep_coinv=mean(frac_rep_coinv*dpat)

*out of all patents that have inventors that have next patent
bys appyear : egen mrpat_frac_rep_coinv=mean(frac_rep_coinv*dpat_rpat_inv*dpat)


*------------------------
* Repeat all coinventors
*------------------------

*dummy of inventors that repeated all coinventors
bys id_inv : gen drep_all_coinv=1 if Nrep_coinv==tsize
	replace drep_all_coinv=0 if drep_all_coinv==.

*count the number of inventors that repeated all coinventors in next patent
bys appyear : egen Ndrep_all_coinv=total(drep_all_coinv*drpat_inv)

*probability of all repeated coinventor
gen pr_all_coinv=Ndrep_all_coinv/Ndrpat_inv

*---------------------------------
* Temporary dataset for dummies. 
*---------------------------------

preserve

rename id_inv categ1

keep patent categ1 rpat drep_alo_coinv drep_all_coinv dinv_next_pat pr_all_coinv pr_alo_coinv Ndrpat_inv Ndrep_alo_coinv Nrep_coinv Ndrep_all_coinv tsize2

duplicates drop patent categ1, force

save "$datasets/survival_dummies_probability.dta", replace

restore

*-----------------------------------
*  Probability of having next patent
*-----------------------------------
*count the number of inventors 
bys appyear : egen Ninv=total(dinv)

*count the number of inventors that have a next patent by appyear
bys appyear : egen Ndrpat_inv2=total(drpat_inv*dinv)

*probability of all repeated coinventor
gen pr_rpat=Ndrpat_inv/Ninv

gen pr_rpat2=Ndrpat_inv2/Ninv

*-----------------------------------
*  Number of coinventors
*-----------------------------------

*total number of coinventors
bys id_inv (rpat): gen Ncoinv=_N

*identify distinct coinventors
bys id_inv (id_coinv): gen dinv_coinv=1 if id_coinv[_n]~=id_coinv[_n-1]

*total number of distinct coinventors
bys id_inv (rpat): egen Nd_coinv=total(dinv_coinv)

*fraction of new coinventors
gen frac_dcoinv=Nd_coinv/Ncoinv

*mean by appyear
bys appyear: egen mNcoinv=mean(Ncoinv*dinv)
bys appyear: egen mNd_coinv=mean(Nd_coinv*dinv)
bys appyear: egen mfrac_dcoinv=mean(frac_dcoinv*dinv)

bys id_inv (appyear) : egen iyear=min(appyear)


bys iyear: egen mNcoinv_iyear=mean(Ncoinv*dinv)
bys iyear: egen mNd_coinv_iyear=mean(Nd_coinv*dinv)
bys iyear: egen mfrac_dcoinv_iyear=mean(frac_dcoinv*dinv)

sort iyear
gen diyear=1 if iyear[_n]~=iyear[_n-1]



******************************
* Save dataset
******************************
*variables to save
label var pr_alo_coinv "Probability of repeating at least one coinventor"
label var frac_rep_coinv "Fraction of repeated coinventor"
label var mpat_frac_rep_coinv "Mean fraction of repeated coinventors (all patents)"
label var mrpat_frac_rep_coinv "Mean fraction of repeated coinventors (patents with invetors that have next patent)"  
label var pr_all_coinv  "Probability of repeating all coinventors"
*label var pr_rpat "Probability of having next patent"
label var drep_alo_coinv "Inventor repeats at least one coinventor in next patent"
label var drep_all_coinv "Inventor repeats all coinventors in next patent"
label var Nrep_coinv "Number of repeated coinventors in next patent"
label var Ncoinv   "Total lifetime coinventors of an inventor"
label var Nd_coinv "Different lifetime coinventors of an inventor"

if $save_dataset ==1 {

*full dataset

save "$datasets/survival_full_PV.dta", replace

preserve

rename id_inv categ1

keep patent categ1 pr_alo_coinv pr_all_coinv frac_rep_coinv mpat_frac_rep_coinv mrpat_frac_rep_coinv  drep_alo_coinv drep_all_coinv Nrep_coinv Ncoinv Nd_coinv

duplicates drop patent categ1, force

save "$datasets/survival_PV.dta", replace

restore

}

/*
*** browse
sort id_inv rpat id_coinv 
*br construction
br patent date appyear id_inv id_coinv rpat  drep_coinv  tsize  Nrep_coinv drep_alo_coinv drep_all_coinv drpat_inv dinv
*br result
br patent date appyear id_inv id_coinv rpat  drep_coinv  tsize  Nrep_coinv  Ndrep_all_coinv pr_all_coinv
*/

**Plots

*Probability has next patent
twoway (connected  pr_rpat appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Inventors Have Next Patent",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/pr_rpat.pdf", replace as(pdf)
}

*Probability has next patent
twoway (connected  pr_rpat2 appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Inventors Have Next Patent",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/pr_rpat.pdf", replace as(pdf)
}

*Probability repeat at least one coinventor
twoway (connected  pr_alo_coinv appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/pr_alo_coinv.pdf", replace as(pdf)
}

*Probability repeat all coinventors
twoway (connected  pr_all_coinv appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventors",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/pr_all_coinv.pdf", replace as(pdf)
}

*Fraction out of all patents
twoway (connected  mpat_frac_rep_coinv appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Frac of Repeated Coinventors ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/mpat_frac_rep_coinv.pdf", replace as(pdf)
}

*Fraction out of patents with at least one inventor with next patent
twoway (connected  mrpat_frac_rep_coinv appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Frac of Repeated Coinventors  ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/mrpat_frac_rep_coinv.pdf", replace as(pdf)
}


*Number of co-inventors
twoway (connected  mNcoinv appyear, lcolor(navy) lwidth(medthick)) (connected  mNd_coinv appyear, lcolor(maroon) lwidth(medthick) lp(dash)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Co-inventors  ",height(8) size($size_font)) legend(region(lcolor(white)) label(1 "Total") label(2 "Distinct") )  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/mNcoinv.pdf", replace as(pdf)
}

*Fraction of co-inventors
twoway (connected  mfrac_dcoinv appyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Different Co-inventors  ",height(8) size($size_font))   xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/mfrac_dcoinv.pdf", replace as(pdf)
}


*Number of co-inventors by iyear
twoway (connected  mNcoinv_iyear iyear, lcolor(navy) lwidth(medthick)) (connected  mNd_coinv_iyear iyear, lcolor(maroon) lwidth(medthick) lp(dash)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Co-inventors  ",height(8) size($size_font)) legend(region(lcolor(white)) label(1 "Total") label(2 "Distinct") ) xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/mNcoinv_iyear.pdf", replace as(pdf)
}

*Fraction of co-inventors by iyear
twoway (connected  mfrac_dcoinv_iyear iyear, lcolor(navy) lwidth(medthick)) if dyear==1 , ///
graphregion(color(white)) bgcolor(white) xtitle("Initial Year Year",height(8) size($size_font)) xlabel( , labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Fraction of Different Co-inventors  ",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))

if $save_fig ==1 {
graph export "$figfolder/mfrac_dcoinv.pdf", replace as(pdf)
}

