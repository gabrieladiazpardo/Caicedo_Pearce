*************************************************
* Facts Using PatentsView Data
* For Slides
* Santiago Caicedo
* Gabriela Diaz
* Winter 2021
************************************************

set more off

*global main "/Users/JeremyPearce/Dropbox"
global main "/Users/JeremyPearce/Dropbox"

**Folders
global data "$main/Caicedo_Pearce/data/output"

global datasets "$main/Caicedo_Pearce/RA/output/datasets"


**Saving options
global save_fig   1 //0 // 


graph set window fontface "Garamond"
global size_font medlarge // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots


global figfolder="$main/Caicedo_Pearce/slides/results/specialization"
global tabfolder="$main/Caicedo_Pearce/notes/tables"




**************************
* Create analysis groups
**************************

*Add firm deciles and group to dataset

/*

Warning: Just run it once, have to add it to data creation file!! SC:Jan 2021

**For patent level
use "$datasets/Patentsview_lev_dataset.dta", clear

merge m:1 assignee appyear using "$data/firmdecile_measure_by_firm.dta"
drop _merge

rename f10f f10s

label var f10s "Firm decile using stock of patents at start of application year"
label var firmseq  "Firm stock of patents at start of application year"

*Group firms
gen gr_f10s=1 if f10s<=5
	replace gr_f10s=2 if f10s>5 & f10s<=9
	replace gr_f10s=3 if f10s==10

label var gr_f10s "Group by firm decile using stock of patents"

save "$datasets/Patentsview_lev_dataset.dta", replace

**For main
use "$datasets/Patentsview_Main.dta", clear

merge m:1 assignee appyear using "$data/firmdecile_measure_by_firm.dta"
drop _merge

rename f10f f10s

label var f10s "Firm decile using stock of patents at start of application year"
label var firmseq  "Firm stock of patents at start of application year"

*Group firms
gen gr_f10s=1 if f10s<=5
	replace gr_f10s=2 if f10s>5 & f10s<=9
	replace gr_f10s=3 if f10s==10

label var gr_f10s "Group by firm decile using stock of patents"

save "$datasets/Patentsview_Main.dta", replace


******Group 90-10
use "$datasets/Patentsview_lev_dataset.dta", clear

gen gr1090=1 if f10s<=9
	replace gr1090=2 if f10s==10
	
label var gr1090 "Group 90-10 by firm using stock of patents"	

save "$datasets/Patentsview_lev_dataset.dta", replace


use "$datasets/Patentsview_Main.dta", clear

gen gr1090=1 if f10s<=9
	replace gr1090=2 if f10s==10
	
label var gr1090 "Group 90-10 by firm using stock of patents"	

save "$datasets/Patentsview_Main.dta", replace

*/

*************************
* Facts
*************************



*-----------------------------------------
* Facts 1: Team size and time to build
*-----------------------------------------
{

***Team size over time

use "$datasets/Patentsview_lev_dataset.dta", clear

*keep utility patents and drop rare ipc classes
keep if type_pat==7
drop if rare_ipc3_mean==1

drop if appyear<=$iyear

collapse (mean) tsize , by(gr1090 appyear)

twoway (connected  tsize appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected  tsize appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/team_size_gr_1090.pdf", replace as(pdf)
}


***Time to build

use "$datasets/Patentsview_lev_dataset.dta", clear

*keep utility patents and drop rare ipc classes
keep if type_pat==7
drop if rare_ipc3_mean==1

drop if appyear<=$iyear

collapse (mean) m_ttb , by(gr1090 appyear)

twoway (connected  m_ttb appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected  m_ttb appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Time to Build (Average of Team)",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/m_ttb_gr_1090.pdf", replace as(pdf)
}


}


*-----------------------------------------
* Facts 2: Specialization
*-----------------------------------------
{




}


*-----------------------------------------
* Facts 3: Innovation Concentration
*-----------------------------------------
{




}


*-----------------------------------------
* Facts 4: Economic Value of Patents 
*-----------------------------------------
{

***Forward citations

use "$datasets/Patentsview_lev_dataset.dta", clear

*keep utility patents and drop rare ipc classes
keep if type_pat==7
drop if rare_ipc3_mean==1

drop if appyear<=$iyear


gen cit3_tsize=cit3/tsize
gen f_cit3_tsize=f_cit3/tsize


reg f_cit3 i.appyear
predict fc
sum f_cit3
replace f_cit3=f_cit3-fc+`r(mean)'

reg cit3 i.appyear
predict c3
sum cit3
replace cit3=cit3-c3+`r(mean)'


reg cit3_tsize i.appyear
predict ct3
sum cit3_tsize
replace cit3_tsize=cit3_tsize-ct3+`r(mean)'

reg f_cit3_tsize i.appyear
predict fct3
sum f_cit3_tsize
replace f_cit3_tsize=f_cit3_tsize-fct3+`r(mean)'



collapse (mean) cit3 f_cit3 cit3_tsize f_cit3_tsize, by(gr1090 appyear)

*Forward citations (Adjusted)

twoway (connected  cit3 appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected  cit3 appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-Year Forward Citations (Adjusted)",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/cit3_gr_1090_jp_ayadj.pdf", replace as(pdf)
}

*Forward citations (Unadjusted)

twoway (connected f_cit3 appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected  f_cit3 appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-Year Forward Citations (Unadjusted)",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/f_cit3_gr_1090_jp_ayadj.pdf", replace as(pdf)
}

twoway (connected  cit3_tsize appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected cit3_tsize appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-Year Forward Citations (Adjusted)""by Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/cit3_tsize_gr_1090_jp_ayadj.pdf", replace as(pdf)
}

*Forward citations (Unadjusted)

twoway (connected  f_cit3_tsize appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected f_cit3_tsize appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("3-Year Forward Citations (Unadjusted)" "by Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/f_cit3_tsize_gr_1090_jp_ayadj.pdf", replace as(pdf)
}


}

*---------------------------
* Fact 6: Survival
*---------------------------
{
*Open PatentsView
use "$datasets/Patentsview_Main.dta", clear

*keep utility patents and drop rare ipc classes
keep if type_pat==7
drop if rare_ipc3_mean==1

*Reduced Version
keep patent date appyear type_pat inventor_id invseq categ1 ipc3 asgnum type_asg assignee tsize d_asg_org identified_ipc rare_ipc3_any rare_ipc3_mean appdate gr1090

compress


*keep comparable sample
keep if tsize>1

*------------------------------------*
*	Merge Dummies
*------------------------------------*

merge m:1 patent categ1 using "$datasets/survival_dummies_probability.dta", gen(m_dummy)

drop m_dummy


*count the number of inventors that have a next patent by appyear (pat-1)
bys appyear gr1090: egen Ndrpat_inv_group=total(dinv_next_pat)

*count the number of inventors that repeated coinventors in next patent
bys appyear gr1090: egen Ndrep_alo_coinv_group=total(drep_alo_coinv)

*count the number of inventors that repeated coinventors in next patent
bys appyear gr1090: egen Ndrep_all_coinv_group=total(drep_all_coinv)

*probability of at least one repeated coinventor
gen pr_alo_coinv_group=Ndrep_alo_coinv_group/Ndrpat_inv_group

*probability of all  coinventors
gen pr_all_coinv_group=Ndrep_all_coinv_group/Ndrpat_inv_group


collapse (mean) pr_alo_coinv_group pr_all_coinv_group, by(appyear gr1090)


twoway (connected  pr_alo_coinv_group appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected  pr_alo_coinv_group appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat at Least One Coinventor" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below 90%") label( 2 "Top 10%") size(med)) 

if $save_fig==1 {
graph export "$figfolder/pr_alo_coinv_gr_1090.pdf", replace as(pdf)
}

twoway (connected  pr_all_coinv_group appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected  pr_all_coinv_group appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Pr Repeat All Coinventor" ,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label( 1 "Below 90%") label( 2 "Top 10%") size(med)) 

if $save_fig==1 {
graph export "$figfolder/pr_all_coinv_gr_1090.pdf", replace as(pdf)
}

}

*----------------------------
*	Stock Market Value 
*----------------------------
{
*open kogan data
use "$datasets/kogan_patents.dta", clear

*fix diplicates in kogan data
duplicates tag patent, gen(dupl)
gen yes_xi=1 if xi!=. & dupl==1
replace yes_xi=0 if dupl==0
drop if yes_xi==.

drop yes_xi dupl gday gmonth gdate permno appmonth appday

*optional
drop class subclass

*rename vars (kogan)
findname, local(vars)
local no = "patent xi"
local lista: list vars - no
macro dir
foreach var of local lista{
rename `var' `var'_kog
}

tempfile kogan
save "`kogan'", replace

*open PV dataset
use "$datasets/Patentsview_lev_dataset.dta", clear

drop asg_self_cite ipc3_self_cite cit_same_asg cit_ident_asg b_cit_asg_sc b_cit_ipc3_sc cit3 cit5 cit8 exp_cit_adj  drep_alo_coinv pr_alo_coinv Nrep_coinv frac_rep_coinv mpat_frac_rep_coinv mrpat_frac_rep_coinv drep_all_coinv pr_all_coinv Ncoinv Nd_coinv

drop mainclass_uspc section_cpc survive subsection_cpc category_nber subcategory_nber non_selected_ipc is90s patnumpp1 ttb1 ttb2 i_ttb m_ttb 

*Merge Kogan to PV - Pat Level
merge 1:1 patent using "`kogan'", gen(in_both)

br patent app*

*Stock Value of Patents
preserve

*keep utility patents and drop rare ipc classes
keep if type_pat==7
drop if rare_ipc3_mean==1


collapse (mean) xi , by(gr1090 appyear)
drop if appyear<1975
drop if appyear>=2010

**Other options

global fyear_k 2010 //final year of plots

drop if gr1090==.

twoway (connected  xi appyear if gr1090==1 , lcolor(navy) lwidth(medthick)) (connected xi appyear if gr1090==2 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear_k, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Patent Stock Value",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/xi_gr_1090.pdf", replace as(pdf)
}

restore

}

*---------------------------
*	Interactions 
*---------------------------
{

************************************************
*Open Data + Creation of Variables*
************************************************
{

*Open dataset + merge
use "$datasets/Patentsview_Main.dta", clear 

keep patent appyear date categ1 tsize invseq appdate inventor_id gr1090 type_pat rare_ipc3_mean
																	
*generate inventor year
sort categ1 appyear

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
*preserve
*keep if tsize==1
*gen solo=1
*save "$datasets/solo_pats.dta", replace
*restore

********************
*Paired Dataset
********************

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


compress
drop numid2

********************************
*Append Solo Patents
*********************************
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
{
*dummy for change inventor - patent
bys id_inv (rpat) : gen d_pat_inv=1 if rpat[_n]!=rpat[_n-1]
}

*************************************************************************************
*Number of coinventors for each inventor, on each patent - Needs to match with tsize-1*
***************************************************************************************
{

*create total number of coinventors
bys id_inv rpat : gen no_tot_coinv=_N if solo!=1
replace no_tot_coinv=0 if solo==1

gen no_tot_coinv2=tsize-1
}

*****************************************************
*Create Interactions By Running Patent				*
******************************************************
{

*Creation of Variables
{

*Counter --------> Number of times inventor repeats patent with each coinventor

bys id_inv id_coinv (rpat): gen cont_rep_coinv=_n if rpat[_n]!=rpat[_n+1] & solo!=1	 
replace cont_rep_coinv=0 if solo==1

*----- Distinct Coinventors by Pat Count

gen dfirstpat_coinv=1 if cont_rep_coinv==1
replace dfirstpat_coinv=0 if dfirstpat_coinv==.

*---Number of distinct coinventors per patent - all obs
bys id_inv rpat: egen no_dist_coinv_pat=total(dfirstpat_coinv)

*---Number of distinct coinventors per patent - Not Cumulative
gen no_dist_coinv_per_pat=no_dist_coinv_pat if d_pat_inv==1

*--- Cumulative number of distinct coinventors
bys id_inv (rpat): gen num_dist_coinv_cum=sum(no_dist_coinv_pat) if d_pat_inv==1

*--Cumulative number of coinventors interactions by patent count

bys id_inv (rpat) : gen num_coinv_cum=sum(no_tot_coinv) if d_pat_inv==1

}

*Number of Coinventors By gr_f10s
{
preserve

keep if d_pat_inv==1

drop id_coinv

bys rpat: gen no_inventors=_N

collapse (mean) num_dist_coinv_cum no_inventors num_coinv_cum no_dist_coinv_per_pat, by(rpat gr1090)

save "$datasets/no_coinv_rpat_appyr_gr_1090.dta", replace

global ipat 0 //initial year of plots
global fpat 41 //final year of plots


*cum 
twoway (connected  num_coinv_cum rpat if gr1090==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected num_coinv_cum rpat if gr1090==2  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) ///
xlabel($ipat(5)$fpat , labsize($size_font) ) ///
ylabel(, nogrid labsize($size_font)) ///
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )


if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_gr_1090_$fpat.pdf", replace as(pdf)
}

*distinct

twoway (connected  num_dist_coinv_cum rpat if gr1090==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected num_dist_coinv_cum rpat if gr1090==2  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) ///
xlabel($ipat(5)$fpat , labsize($size_font) ) ///
ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_gr_1090_$fpat.pdf", replace as(pdf)
}

restore
}

}


}

}

*---------------------------
*	Productivity
*---------------------------
{
*open data
use "$datasets/Patentsview_Main.dta", clear

*merge firm share measures
keep patent gyear date appyear appdate categ1 invseq inventor_id ipc3 assignee tsize f_cit cit3 cit5 cit8 exp_cit_adj f_cit3 f_cit5 f_cit8 gr_f10s gr1090  type_pat rare_ipc3_mean
	
sort categ1 appyear

*inventor order
sort patent appdate
bys patent (invseq): gen invord=_n

*count running patent by inventors (total patents foreach inventor) - sorted by appdate
bys categ1 (appdate): gen rpat=_n

compress

order patent categ1 appyear appdate rpat

*--Citations with 3 yr f cit
gen mg_pr_3yr_fcit=f_cit3
*--Cumulative number of citations with 3 yr f cit
bys categ1 (rpat): gen pr_3yr_fcit=sum(mg_pr_3yr_fcit)
*--Citations with 3 yr f cit by tsize
gen mg_pr_3yr_fcit_tsize=f_cit3/tsize
*--Cumulative number of citations with 3 yr f cit by tsize
bys categ1 (rpat): gen pr_3yr_fcit_tsize=sum(mg_pr_3yr_fcit_tsize)


*Number of inventors by running patent
bys rpat: gen no_inventors=_N

sort inventor rpat
gen i_gr1090=gr1090 if rpat==1

bys categ1 : egen ini_gr1090=max(i_gr1090)
drop i_gr1090

*Graph by asg share
preserve

*keep utility patents and drop rare ipc classes
*keep if type_pat==7
*drop if rare_ipc3_mean==1

collapse (mean) pr_* mg_* no_inventors, by(rpat ini_gr1090)

save "$datasets/product_rpat_ini_gr_1090.dta", replace

global ipat 0
global fpat 41

global g mg_pr_3yr_fcit mg_pr_3yr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

twoway (connected  `k' rpat if ini_gr1090==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected `k' rpat if ini_gr1090==2  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) ///
legend(region(lcolor(white))  label(1 "Initial Patent in Bottom 90%") label(2 "Initial Patent in Top 10%" ) size(med) ) name(gr_`m', replace)

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_ini_gr_1090_$fpat.pdf", replace as(pdf)
}

}

restore


** Do it with groups based of current patent

*Graph by asg share
preserve

collapse (mean) pr_* mg_* no_inventors, by(rpat gr1090)

global ipat 0
global fpat 41

global g mg_pr_3yr_fcit mg_pr_3yr_fcit_tsize
local m=0

foreach k of global g{
local ++m

if `m'==1{
local lb "Productivity 3yr Fcit - Marginal"
}

if `m'==2{
local lb "Productivity 3yr Fcit/Tsize - Marginal"
}

twoway (connected  `k' rpat if gr1090==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected `k' rpat if gr1090==2  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) ///
legend(region(lcolor(white))  label(1 "Patent in Bottom 90%") label(2 "Patent in Top 10%" ) size(med) ) name(gr_`m', replace)

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_gr_1090_$fpat.pdf", replace as(pdf)
}

}

restore





}

*----------------------------
*	Cites vs Market Value 
*---------------------------
{

use "$datasets/kogan_patents.dta", clear

*fix diplicates in kogan data
duplicates tag patent, gen(dupl)
gen yes_xi=1 if xi!=. & dupl==1
replace yes_xi=0 if dupl==0
drop if yes_xi==.

drop yes_xi dupl gday gmonth gdate permno appmonth appday

*optional
drop class subclass

*rename vars (kogan)
findname, local(vars)
local no = "patent xi"
local lista: list vars - no
macro dir
foreach var of local lista{
rename `var' `var'_kog
}

tempfile kogan
save "`kogan'", replace

*open PV dataset
use "$datasets/Patentsview_lev_dataset.dta", clear

drop asg_self_cite ipc3_self_cite cit_same_asg cit_ident_asg b_cit_asg_sc b_cit_ipc3_sc drep_alo_coinv pr_alo_coinv Nrep_coinv frac_rep_coinv mpat_frac_rep_coinv mrpat_frac_rep_coinv drep_all_coinv pr_all_coinv Ncoinv Nd_coinv mainclass_uspc section_cpc survive subsection_cpc category_nber subcategory_nber non_selected_ipc is90s patnumpp1 ttb1 ttb2 i_ttb m_ttb 

*Merge Kogan to PV - Pat Level
merge 1:1 patent using "`kogan'", gen(in_both)

*log cit var
gen log_fcit3=log(1+f_cit3)
gen log_xi=log(xi)
*label var  log_fcit3 "$\beta$"

*create ipc1
gen ipc1=substr(ipc3,1,1)
egen ipc1_num =group(ipc1)
egen ipc3_num =group(ipc3)

drop if appyear<1975
drop if appyear>=2010

*Regression Tables (Excel)
foreach k of numlist 1975/2009{

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==1, noabs

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_90.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Bottom 90% , IPC3 FE, $\times$)  sdec(2) ctitle("Appyear `k'")

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==1, abs(i.ipc3_num)

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_90.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Bottom 90%, IPC3 FE, $\checkmark$ ) sdec(2) ctitle("Appyear `k'")

}

foreach k of numlist 1975/2009{

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==2, noabs

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_10.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Top 10% , IPC3 FE, $\times$)  sdec(2) ctitle("Appyear `k'")


reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==2, abs(i.ipc3_num)

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_10.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Top 10% , IPC3 FE, $\checkmark$ ) sdec(2) ctitle("Appyear `k'")

}


*Regressions for Coefplot
foreach z of numlist 1/2{
foreach k of numlist 1975/2009{

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==`z', noabs

estimate store m`z'_`k'

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==`z', abs(i.ipc3_num)

estimate store a`z'_`k'

}
}

*Without Controls
{
coefplot (m1_1976) (m2_1976, msymbol(Dh)), bylabel(1976) ///
      || m1_1977 m2_1977, bylabel(1977)  ///
	  || m1_1978 m2_1978, bylabel(1978)  ///
	  || m1_1979 m2_1979, bylabel(1979)  ///
	  || m1_1980 m2_1980, bylabel(1980)  ///
	  || m1_1981 m2_1981, bylabel(1981)  ///
	  || m1_1982 m2_1982, bylabel(1982)  ///
	  || m1_1983 m2_1983, bylabel(1983)  ///
	  || m1_1984 m2_1984, bylabel(1984)  ///
	  || m1_1985 m2_1985, bylabel(1985)  ///	
	  || m1_1986 m2_1986, bylabel(1986)  ///
	  || m1_1987 m2_1987, bylabel(1987)  ///
	  || m1_1988 m2_1988, bylabel(1988)  ///
      || m1_1989 m2_1989, bylabel(1989)  ///
      || m1_1990 m2_1990, bylabel(1990)  ///
      || m1_1991 m2_1991, bylabel(1991)  ///
      || m1_1992 m2_1992, bylabel(1992)  ///
      || m1_1993 m2_1993, bylabel(1993)  ///
	  || m1_1994 m2_1994, bylabel(1994)  ///
	  || m1_1995 m2_1995, bylabel(1995)  ///	
	  || m1_1996 m2_1996, bylabel(1996)  ///
	  || m1_1997 m2_1997, bylabel(1997)  ///
	  || m1_1998 m2_1998, bylabel(1998)  ///
      || m1_1999 m2_1999, bylabel(1999)  ///
      || m1_2000 m2_2000, bylabel(2000)  ///
      || m1_2001 m2_2001, bylabel(2001)  ///
      || m1_2002 m2_2002, bylabel(2002)  ///
      || m1_2003 m2_2003, bylabel(2003)  ///
	  || m1_2004 m2_2004, bylabel(2004)  ///
	  || m1_2005 m2_2005, bylabel(2005)  ///	
	  || m1_2006 m2_2006, bylabel(2006)  ///
	  || m1_2007 m2_2007, bylabel(2007)  ///
	  || m1_2008 m2_2008, bylabel(2008)  ///	  
	  || , bycoefs byopts(xrescale)   ///
          plotlabels("Bottom 90%" "Top 10%") drop(_cons) ///
		  vertical 															 ///
		  label 	                                              ///														 
		  plotregion(lcolor(white) fcolor(white))  							 ///
		  graphregion(lcolor(white) fcolor(white))  						 ///	  
		  yline(0, lpattern(dash) lwidth(*0.5))   							 ///
		  xtitle("Appyear", size(medsmall)) ///
		  levels(95) ///
		  msize(small) ///
		  xlabel(, labsize(vsmall) angle(vertical) nogextend labc(black))

if $save_fig ==1 {
graph export "$figfolder/coefplot_pat_val_nocontrols_gr_1090.pdf", replace as(pdf)
}

}	
	
	
*With Controls
{
coefplot (a1_1976) (a2_1976, msymbol(Dh)), bylabel(1976) ///
      || a1_1977 a2_1977, bylabel(1977)  ///
	  || a1_1978 a2_1978, bylabel(1978)  ///
	  || a1_1979 a2_1979, bylabel(1979)  ///
	  || a1_1980 a2_1980, bylabel(1980)  ///
	  || a1_1981 a2_1981, bylabel(1981)  ///
	  || a1_1982 a2_1982, bylabel(1982)  ///
	  || a1_1983 a2_1983, bylabel(1983)  ///
	  || a1_1984 a2_1984, bylabel(1984)  ///
	  || a1_1985 a2_1985, bylabel(1985)  ///	
	  || a1_1986 a2_1986, bylabel(1986)  ///
	  || a1_1987 a2_1987, bylabel(1987)  ///
	  || a1_1988 a2_1988, bylabel(1988)  ///
      || a1_1989 a2_1989, bylabel(1989)  ///
      || a1_1990 a2_1990, bylabel(1990)  ///
      || a1_1991 a2_1991, bylabel(1991)  ///
      || a1_1992 a2_1992, bylabel(1992)  ///
      || a1_1993 a2_1993, bylabel(1993)  ///
	  || a1_1994 a2_1994, bylabel(1994)  ///
	  || a1_1995 a2_1995, bylabel(1995)  ///	
	  || a1_1996 a2_1996, bylabel(1996)  ///
	  || a1_1997 a2_1997, bylabel(1997)  ///
	  || a1_1998 a2_1998, bylabel(1998)  ///
      || a1_1999 a2_1999, bylabel(1999)  ///
      || a1_2000 a2_2000, bylabel(2000)  ///
      || a1_2001 a2_2001, bylabel(2001)  ///
      || a1_2002 a2_2002, bylabel(2002)  ///
      || a1_2003 a2_2003, bylabel(2003)  ///
	  || a1_2004 a2_2004, bylabel(2004)  ///
	  || a1_2005 a2_2005, bylabel(2005)  ///	
	  || a1_2006 a2_2006, bylabel(2006)  ///
	  || a1_2007 a2_2007, bylabel(2007)  ///
	  || a1_2008 a2_2008, bylabel(2008)  ///	  
	  || , bycoefs byopts(xrescale)   ///
          plotlabels("Bottom 90%" "Top 10%") drop(_cons) ///
		  vertical 															 ///
		  label 	                                              ///														 
		  plotregion(lcolor(white) fcolor(white))  							 ///
		  graphregion(lcolor(white) fcolor(white))  						 ///	  
		  yline(0, lpattern(dash) lwidth(*0.5))   							 ///
		  xtitle("Appyear", size(medsmall)) ///
		  msymbol(D) ///
		  levels(95) ///
		  msize(small) ///
		  xlabel(, labsize(vsmall) angle(vertical) nogextend labc(black))

if $save_fig ==1 {
graph export "$figfolder/coefplot_pat_val_with_controls_gr_1090.pdf", replace as(pdf)
}
	
}		  

}
