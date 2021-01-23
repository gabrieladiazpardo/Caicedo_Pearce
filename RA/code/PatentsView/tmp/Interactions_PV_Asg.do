
global figfolder="$main/slides/results/specialization"

**Saving options
global save_fig 1 //  0 //
global save_dataset  0 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font large // medlarge //


************************************************
*Open Data + Creation of Variables*
************************************************
{
*Create reduced data with gs10gr
use "$datasets/Patentsview_lev_dataset.dta", clear

drop asg_self_cite ipc3_self_cite cit_same_asg cit_ident_asg b_cit_asg_sc b_cit_ipc3_sc cit3 cit5 cit8 exp_cit_adj  drep_alo_coinv pr_alo_coinv Nrep_coinv frac_rep_coinv mpat_frac_rep_coinv mrpat_frac_rep_coinv drep_all_coinv pr_all_coinv Ncoinv Nd_coinv

drop mainclass_uspc section_cpc survive subsection_cpc category_nber subcategory_nber non_selected_ipc is90s patnumpp1 ttb1 ttb2 i_ttb m_ttb 

keep patent asgnum assignee rare_ipc3_mean type_pat f10s gr_f10s
compress

save "$datasets/PV_pat_asg_reduced.dta", replace

*Open dataset + merge
use "$datasets/Patentsview_Main.dta", clear

keep patent appyear date categ1 tsize invseq ipc3 appdate inventor_id

*Merge New Measures
merge m:1 patent using "$datasets/PV_pat_asg_reduced.dta", nogendrop ipc3
drop ipc3
drop assignee inventor_id date
																		
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

collapse (mean) num_dist_coinv_cum no_inventors num_coinv_cum no_dist_coinv_per_pat, by(rpat gr_f10s)

save "$datasets/no_coinv_rpat_appyr_gr_f10s.dta", replace

global ipat 0 //initial year of plots
global fpat 41 //final year of plots


*cum 
twoway (connected  num_coinv_cum rpat if gr_f10s==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected num_coinv_cum rpat if gr_f10s==3  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) ///
xlabel($ipat(5)$fpat , labsize($size_font) ) ///
ylabel(, nogrid labsize($size_font)) ///
ytitle("Cum. Number of Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Top 10%" ) size(med) )


if $save_fig ==1 {
graph export "$figfolder/num_coinv_cum_pat_gr_f10s_$fpat.pdf", replace as(pdf)
}

*distinct

twoway (connected  num_dist_coinv_cum rpat if gr_f10s==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected num_dist_coinv_cum rpat if gr_f10s==3  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) ///
xlabel($ipat(5)$fpat , labsize($size_font) ) ///
ylabel(, nogrid labsize($size_font)) ////
ytitle("Cum. Number of Distinct Coinventors",height(8) size($size_font)) ///
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/num_dist_coinv_cum_pat_gr_f10s_$fpat.pdf", replace as(pdf)
}

restore
}

}
