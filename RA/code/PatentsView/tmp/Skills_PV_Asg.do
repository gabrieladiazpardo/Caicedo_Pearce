global figfolder="$main/slides/results/specialization"

**Saving options
global save_fig 1 //  0 //
global save_dataset  0 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font large // medlarge //


*open data
use "$datasets/Patentsview_Main.dta", clear

*merge firm share measures
keep patent gyear date appyear appdate categ1 invseq inventor_id ipc3 assignee tsize f_cit cit3 cit5 cit8 exp_cit_adj f_cit3 f_cit5 f_cit8
merge m:1 patent using "$datasets/PV_pat_asg_reduced.dta", nogen

drop ipc3
drop assignee inventor_id date
									
*create age
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


*Graph by asg share
preserve

*keep utility patents and drop rare ipc classes
keep if type_pat==7
drop if rare_ipc3_mean==1

collapse (mean) pr_* mg_* no_inventors, by(rpat gr_f10s)

save "$datasets/product_rpat_gr_f10s.dta", replace

use "$datasets/product_rpat_gr_f10s.dta",  clear

summ rpat [aw=no_inventors], d
return list


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

twoway (connected  `k' rpat if gr_f10s==1 & rpat<=$fpat, lcolor(navy) lwidth(medthick)) ///
(connected `k' rpat if gr_f10s==3  & rpat<=$fpat , lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Experience (# Patents)",height(8) size($size_font)) xlabel($ipat(5)$fpat, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(`lb' ,height(8) size($size_font)) legend(region(lcolor(white))) ///
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Top 10%" ) size(med) ) name(gr_`m', replace)

if $save_fig==1 {
graph export "$figfolder/`k'_rpat_gr_f10s_$fpat.pdf", replace as(pdf)
}
}

restore
