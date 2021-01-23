
**Saving options
global save_fig   1 //0 // 


graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2010 //final year of plots


global figfolder="$main/slides/results/specialization"

*assignee only organizations type 2 and 3
global org_asg 1

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


collapse (mean) xi , by(gr_f10s appyear)
drop if appyear<=1975
drop if appyear>=2010

drop if gr_f10s==.

twoway (connected  xi appyear if gr_f10s==1 , lcolor(navy) lwidth(medthick)) (connected xi appyear if gr_f10s==3 , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) ////
ytitle("Patent Stock Value",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Top 10%" ) size(med) )

if $save_fig ==1 {
graph export "$figfolder/xi_asg_share.pdf", replace as(pdf)
}

restore