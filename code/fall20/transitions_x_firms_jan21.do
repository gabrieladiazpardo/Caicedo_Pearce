*Exploration Facts
*Fall 2020

**Saving options
global save_fig 1 //  0 //
global save_dataset  0 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font large // medlarge //

set more off

global main "/Users/JeremyPearce/Dropbox"
*global main "D:/Dropbox/santiago/Research"

**Folders
global data "$main/Caicedo_Pearce/data/output"
global wrkdata "$main/Caicedo_Pearce/data/wrkdata"
global outdata "$main/Caicedo_Pearce/data/output"

global figfolder "$main/Caicedo_Pearce/notes/figures"


global datasets "$main/Caicedo_Pearce/RA/output/datasets"


**Saving options
global save_fig 1 //  0 //

*save string: data version
global save_str _SC

**Graph options
*cd D:\Dropbox\Santiago\Stata\ado\personal
*set scheme scheme_papers  // Larger axis labels, tick labels, 
graph set window fontface "Garamond"
global size_font large // medlarge //
***MAX TEAM SIZE
global tmax = 5 

*assignee only organizations type 2 and 3
global org_asg 1

**Other options
global iyear 1980 //initial year of plots
global fyear 2015 //final year of plots
global corporate 1

**USE
use "$datasets/Patentsview_Main.dta", clear
*use "$datasets/Patentsview_lev_dataset.dta", clear

keep if type_pat==7
drop if rare_ipc3_mean==1
***maybe only keep corporate ?
local corporate=$corporate
if `corporate'==1{
keep if type_asg==2
global corp corp
}

if `corporate'==1{
global corp
}

***CR IND data

egen g_ipc=group(ipc3)
xtset categ1 patnumpp1
gen is_repeat=.
replace is_repeat=1 if L.g_ipc==g_ipc
replace is_repeat=0 if L.g_ipc~=g_ipc & L.g_ipc~=.

gen is_team=0
replace is_team=1 if tsize>1
drop if tsize==.

gen is_repeat_firm=.
replace is_repeat_firm=1 if L.assignee==assignee & assignee~=. & L.assignee~=. & L.assignee~=0 & assignee~=0
replace is_repeat_firm=0 if L.assignee~=assignee & L.assignee~=. & assignee~=. & L.assignee~=0 & assignee~=0

gen ipc1=substr(ipc3,1,1)


merge m:1 patent using "$data/survival5_measure_by_team.dta"
drop _m

merge m:1 patent using "$data/firmdecile_measure_by_patent.dta"
replace f10=0 if assignee==0
keep if _m==1 | _m==3
drop _m
merge m:1 assignee appyear using"$data/firmpercile_measure_by_firm.dta"
replace f10=0 if assignee==0
keep if _m==1 | _m==3
drop _m

merge m:1 assignee appyear using "$data/firmdecile_measure_by_firm.dta"
replace f10f=0 if assignee==0
keep if _m==1 | _m==3
drop _m
destring patent, force replace
merge m:1 patent using "$wrkdata/self_cit_cit_citing.dta"
keep if _m==1 | _m==3

drop _m
merge m:1 patent using "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data/wrkdata/cit_top_share_bypatent.dta"
keep if _m==1 | _m==3


gen tf=.
replace tf=0 if f100<50
replace tf=1 if f100>=50 & f100<=99
replace tf=2 if f100==100

gen tfa=.
replace tfa=0 if f100p<50
replace tfa=1 if f100p>=50 & f100p<=99
replace tfa=2 if f100p==100


gen top_firm=0
replace top_firm=1 if f10f==10



gen self_share=self_cit/flat_cit

preserve
reg cit_top_share self_share i.g_ipc
predict cit_top
sum cit_top
gen cit_res=cit_top_share-cit_top+`r(mean)'

collapse cit_res, by(tf appyear)
gen bg=.
replace bg=cit_res if appyear==1980
*bys  tf: egen beg_val=mean(bg)
*replace cit_res=cit_res-beg_val
#delimit ;

twoway (connected cit_res appyear if appyear>=1980 & appyear<=2010 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2010 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2010 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Residual Share Citations to Top Firms",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/citshare_to_top_firms_3split_noay_ipc3.pdf",replace;
restore


preserve
reg cit_top_share self_share i.g_ipc i.appyear
predict cit_top
sum cit_top
gen cit_res=cit_top_share-cit_top+`r(mean)'

collapse cit_res, by(tf appyear)
gen bg=.
replace bg=cit_res if appyear==1980
*bys  tf: egen beg_val=mean(bg)
*replace cit_res=cit_res-beg_val
#delimit ;

twoway (connected cit_res appyear if appyear>=1980 & appyear<=2010 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2010 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2010 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Residual Share Citations to Top Firms",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/citshare_to_top_firms_3split_ay_ipc3.pdf",replace;
restore

preserve
gen count=1
collapse (sum) count, by(appyear tf)
rename count cit_res
gen cr=.
replace cr=cit_res if appyear==1980
bys tf: egen cr1980=mean(cr)
replace cit_res=cit_res/cr1980
sort tf appyear
#delimit ;

twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font) )
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font) )
ytitle("Activity of Inventors in Firms",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );

graph export "$figfolder/firm_top_firms_3split_jan21.pdf",replace;


restore




preserve
reg cit_top_share self_share i.g_ipc
predict cit_top
gen cit_res=cit_top_share-cit_top

collapse cit_res, by(top_firm appyear)
gen bg=.
replace bg=cit_res if appyear==1980
bys  top_firm: egen beg_val=mean(bg)
replace cit_res=cit_res-beg_val
#delimit ;

twoway (connected cit_res appyear if appyear>=1980 & appyear<=2010 & top_firm==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2010 & top_firm==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Residual Share Citations to Top Firms",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) );
graph export "$figfolder/citshare_to_top_firms_noay_ipc3.pdf",replace;

restore


preserve
bys categ1: egen mint=min(tsize)
keep if mint==1
xtset categ1 patnumpp1
keep if tsize==1
collapse is_repeat, by(tf appyear)
gen cit_res=is_repeat
#delimit ;

#delimit ;

twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Pr Repeated Technology",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/repeated_ipc_3split.pdf",replace;
restore



preserve
duplicates drop patent, force
collapse tsize, by(tf appyear)
rename tsize cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/tsize_50_49_1_jan21.pdf",replace;
restore





preserve
keep if tsize==1
by categ1 g_ipc (patnumpp1), sort: gen ipc_num = _n == 1
bys categ1 (patnumpp1): gen run_sum=sum(ipc_num)

sort categ1 patnumpp1
collapse run_sum, by(patnumpp1 tf)
rename run_sum cit_res
rename patnumpp1 appyear
#delimit ;
twoway (connected cit_res appyear if appyear<=20 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear<=20 &  tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if  appyear<=20 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Patent Experience",height(8) size($size_font))
 xlabel(0(5)20, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Unique IPCs",height(8) size($size_font))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/life_cycle_ts1_ipc_3split.pdf",replace;
restore;

preserve
keep if tsize==1 & is90s==0
by categ1 ipc1 (patnumpp1), sort: gen ipc_num = _n == 1
bys categ1 (patnumpp1): gen run_sum=sum(ipc_num)

sort categ1 patnumpp1
bys categ1 (patnumpp1): gen patnumpp2=_n
collapse run_sum, by(patnumpp2 tf)
rename run_sum cit_res
rename patnumpp2 appyear
#delimit ;
twoway (connected cit_res appyear if appyear<=20 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear<=20 &  tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if  appyear<=20 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Patent Experience",height(8) size($size_font))
 xlabel(0(5)20, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Unique IPCs",height(8) size($size_font))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/life_cycle_ts1_ipc1_3split.pdf",replace;
restore;




egen ttb_a=rowmean(ttb1 ttb2)


preserve



twowway (connected ttb_a appyeaer if tf==0) (connected ttb_a appyeaer if tf==1) (connected ttb_a appyeaer if tf==2)
restore

preserve
duplicates drop patent, force

collapse ttb_a, by(tf appyear)
gen tb=.
replace tb=ttb_a if appyear==1980
bys tf: egen mvtb=mean(tb)
replace ttb_a=ttb_a/mvtb

rename ttb_a cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Time to Build Patent",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/ttb_adj_50_49_1_jan21.pdf",replace;
restore;



egen ttb_a=rowmean(ttb1 ttb2) 
set more off
preserve
gen f_cit_corr=.
duplicates drop patent, force
keep if tsize<=8
gen lnt=ln(ttb_a+1)
gen lnf=ln(f_cit3+1)
gen lns=ln(self_cit+1)

reg lnf lnt i.tsize i.f10f
gen ub95=.
gen lb95=.
forvalues y=1980/2013{

reg lns lnt i.tsize i.f10f if appyear==`y'
replace f_cit_corr=_b[lnt] if appyear==`y'
replace ub95=f_cit_corr+1.96*_se[lnt] if appyear==`y'
replace lb95=f_cit_corr-1.96*_se[lnt] if appyear==`y'
}
collapse f_cit_corr ub95 lb95, by(appyear)
rename f_cit_corr cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 , lcolor(navy) lwidth(medthick)) 
 (rcap ub95 lb95 appyear if appyear>=1980 & appyear<=2015 , lcolor(navy) lwidth(medthick)), graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Coef(Log Time) on Log(Self Cite)",height(8) size($size_font)) 
legend(region(lcolor(white)) size(med) ) legend(off);
graph export "$figfolder/ttb_selfcorr_cit_jan21.pdf",replace;
restore;

set more off
preserve
gen f_cit_corr=.
duplicates drop patent, force
keep if tsize<=8
gen lnt=ln(ttb_a+1)
gen lnf=ln(f_cit3+1)
gen lns=ln(self_cit+1)

reg lnf lnt i.tsize i.f10f i.g_ipc
gen ub95=.
gen lb95=.
forvalues y=1980/2013{

reg lns lnt i.tsize i.f10f i.g_ipc if appyear==`y'
replace f_cit_corr=_b[lnt] if appyear==`y'
replace ub95=f_cit_corr+1.96*_se[lnt] if appyear==`y'
replace lb95=f_cit_corr-1.96*_se[lnt] if appyear==`y'
}
collapse f_cit_corr ub95 lb95, by(appyear)
rename f_cit_corr cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 , lcolor(navy) lwidth(medthick)) 
 (rcap ub95 lb95 appyear if appyear>=1980 & appyear<=2015 , lcolor(navy) lwidth(medthick)), graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Log (Self Cite) on Log(Time)",height(8) size($size_font)) 
legend(region(lcolor(white)) size(med) ) legend(off);
graph export "$figfolder/ttb_total_cit_jan21.pdf",replace;
restore;



preserve
gen count=1
duplicates drop patent, force
collapse (sum) count, by(tfa appyear)
/*gen c=.
replace c=count if appyear==1980
bys tf: egen mc=mean(c)
replace count=count/mc*/
rename count cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Patents",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/normedobscount_50_49_1_jan21.pdf",replace;


preserve
keep if firm_entrant==1
gen is2=.
replace is2=0 if tfa<=1
replace is2=1 if tfa==2

gen is1=.
replace is1=0 if tfa==0 | tfa==2
replace is1=1 if tfa==1

gen count=1
*duplicates drop patent, force
collapse is2 is1, by(appyear)
#delimit ;
twoway (connected is2 appyear if appyear>=1980 & appyear<=2015, lcolor(navy) lwidth(medthick)) 
(connected is1 appyear if appyear>=1980 & appyear<=2015, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) ,
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Entrant Rate",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1  "Upper 49%")  label(2 "Top 1%" ) size(med) );
graph export "$figfolder/normedobscount_50_49_1_jan21.pdf",replace;




preserve
*duplicates drop patent, force
collapse s_cit_share, by(tf appyear)
/*gen c=.
replace c=count if appyear==1980
bys tf: egen mc=mean(c)
replace count=count/mc*/
rename s_cit_share cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2013 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2013 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2013 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Self-Cite Share",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/selfcit_50_49_1_jan21.pdf",replace;



gen cit3_tsize=cit3/tsize
gen f_cit3_tsize=f_cit3/tsize

preserve
duplicates drop patent, force
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


collapse f_cit3_tsize cit3_tsize f_cit3 cit3, by(tf appyear)
rename f_cit3_tsize cit_res
#delimit ;
twoway (connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==0 , lcolor(navy) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected cit_res appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mfc(white) mcolor(purple) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font))
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("3-year Forward Citations/Team Size",height(8) size($size_font))  xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );
graph export "$figfolder/tsize_50_49_1_jan21.pdf",replace;



drop is90s
gen is90s=0
replace is90s=1 if appyear>=1995 & appyear<=2010

preserve
keep if tsize==1
by categ1 g_ipc (patnumpp1), sort: gen ipc_num = _n == 1
bys categ1 (patnumpp1): gen run_sum=sum(ipc_num)

sort categ1 patnumpp1
*replace patnumpp1=patnumpp1[_n-1]+1 if categ1==categ1[_n-1]
collapse run_sum, by(patnumpp1 is90s top_firm)
#delimit ;
keep if patnumpp1<=20;
twoway (connected run_sum patnumpp1 if is90s==0 & top_firm==0 , lcolor(navy) lwidth(medthick)) 
(connected run_sum patnumpp1 if is90s==0  & top_firm==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) ,
graphregion(color(white)) bgcolor(white) xtitle("Patent #",height(8) size($size_font))
 xlabel(, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Unique IPCs",height(8) size($size_font))
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) );
graph export "$figfolder/life_cycle_ts1_ipc_pre1995.pdf",replace;
twoway (connected run_sum patnumpp1 if is90s==1 & top_firm==0 , lcolor(navy) lwidth(medthick)) 
(connected run_sum patnumpp1 if is90s==1  & top_firm==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) ,
graphregion(color(white)) bgcolor(white) xtitle("Patent #",height(8) size($size_font))
 xlabel(, labsize($size_font) ) ylabel(, nogrid labsize($size_font))
ytitle("Unique IPCs",height(8) size($size_font)) 
legend(region(lcolor(white))  label(1 "Bottom 90%") label(2 "Top 10%" ) size(med) );
graph export "$figfolder/life_cycle_ts1_ipc_post1995.pdf",replace;

* (connected run_sum patnumpp1 if is90s==1 & top_firm==0 , lcolor(purple) lwidth(medthick)) 
*(connected run_sum patnumpp1 if is90s==1  & top_firm==1, lcolor(green) msymbol(Dh) mfc(white) lwidth(medthick))
restore



xtset categ1 patnumpp1
gen alone_both=0
replace alone_both=1 if L.is_team==0 & is_team==0
gen isrepeat_alone=.
replace isrepeat_alone=0 if alone_both==1
replace isrepeat_alone=1 if alone_both==1 & L.g_ipc==g_ipc & g_ipc~=.

gen team_both=0
replace team_both=1 if L.is_team==1 & is_team==1
gen isrepeat_team=.
replace isrepeat_team=0 if team_both==1
replace isrepeat_team=1 if team_both==1 & L.g_ipc==g_ipc & g_ipc~=.

gen mega_firm=0
replace mega_firm=1 if firmseq>5000 & firmseq~=.
gen firm_entrant=.
replace firm_entrant=0 if patnumpp1==L.patnumpp1+1 & L.assignee==assignee
replace firm_entrant=1 if patnumpp1==L.patnumpp1+1 & L.assignee~=assignee
replace firm_entrant=1 if patnumpp1==1

gen firm_exit=.
replace firm_exit=0 if patnumpp1==F.patnumpp1-1 & F.assignee==assignee
replace firm_exit=1 if patnumpp1==F.patnumpp1-1 & F.assignee~=assignee



/*replace c=firm_entrant if appyear==1980
bys tf: egen e1980=mean(c)
replace firm_entrant=firm_entrant/e1980*/

preserve
*replace firm_entrant=. if patnumpp1==1
gen count=1
collapse (sum) count (mean) firm_exit firm_entrant, by(appyear tf)
gen c=.
replace firm_entrant=firm_entrant/(firm_entrant+firm_exit)

sort tf appyear
#delimit ;

twoway (connected firm_entrant appyear if appyear>=1980 & appyear<=2015 & tf==0, lcolor(navy) lwidth(medthick)) 
(connected firm_entrant appyear if appyear>=1980 & appyear<=2015 & tf==1, lcolor(maroon) msymbol(Dh) mfc(white) lwidth(medthick)) 
(connected firm_entrant appyear if appyear>=1980 & appyear<=2015 & tf==2 , lcolor(purple)  msymbol(square) mcolor(purple) lwidth(medthick)) , graphregion(color(white))
xtitle("Application Year") ytitle("Firm Entrant Rate")
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font)) xline(1995, lcolor(red) lpattern(dash))
legend(region(lcolor(white))  label(1 "Bottom 50%") label(2 "Upper 49%")  label(3 "Top 1%" ) size(med) );

graph export "$figfolder/firm_size_entrant_$corp.pdf",replace;

restore



preserve
*replace firm_entrant=. if patnumpp1==1
keep if firm_entrant==1
gen percent=f100
collapse (mean) firm_exit percent, by(appyear)
sort appyear
#delimit ;

twoway (connected percent appyear if appyear>=1980 & appyear<=2015, lcolor(navy) lwidth(medthick)),
xtitle("Application Year") ytitle("Firm Percentile")
 xlabel(1980(5)2010, labsize($size_font) ) ylabel(, nogrid labsize($size_font) ) xline(1995, lcolor(red) lpattern(dash)) graphregion(color(white));

graph export "$figfolder/firm_size_firmentrant_$corp.pdf",replace;

restore



preserve
duplicates drop patent, force
gen count=1
collapse (sum) count, by(tf appyear)

bys appyear: egen tot=total(count)
gen prop=count/tot
twoway connected prop appyear if tf==2


restore




restore




preserve
*keep if patnumpp1==1
gen f5=.
replace f5=1 if f10f>=1 & f10f<=2
replace f5=2 if f10f>=3 & f10f<=4
replace f5=3 if f10f>=5 & f10f<=6
replace f5=4 if f10f>=7 & f10f<=8

replace f5=5 if f10f>=9 & f10f<=10
gen count=1
collapse (sum) count firm_exit firm_entrant, by(appyear f5)
gen c=.
replace firm_entrant=count
replace c=firm_entrant if appyear==1980
bys f5: egen e1980=mean(c)
replace firm_entrant=firm_entrant/e1980
xtset f5 appyear
#delimit ;
twoway (connected firm_entrant appyear if appyear>=1980 & appyear<=2010 & f5==1) 
(connected firm_entrant appyear if appyear>=1980 & appyear<=2010 & f5==2) 
(connected firm_entrant appyear if appyear>=1980 & appyear<=2010 & f5==3) 
(connected firm_entrant appyear if appyear>=1980 & appyear<=2010 & f5==4) 
(connected firm_entrant appyear if appyear>=1980 & appyear<=2010 & f5==5), graphregion(color(white))
xtitle("Application Year") ytitle("Firm Entrant Rate")
legend(order(1 "1st Firm Quintile" 2 "2nd Firm Quintile" 3 "3rd Firm Quintile" 4 "4th Firm Quintile" 5 "5th Firm Quintile")) ;

graph export "$figfolder/firm_size_entrant_$corp.pdf",replace;


#delimit ;
twoway (connected firm_exit appyear if appyear>=1980 & appyear<=2010 & f5==1) 
(connected firm_exit appyear if appyear>=1980 & appyear<=2010 & f5==2) 
(connected firm_exit appyear if appyear>=1980 & appyear<=2010 & f5==3) 
(connected firm_exit appyear if appyear>=1980 & appyear<=2010 & f5==4) 
(connected firm_exit appyear if appyear>=1980 & appyear<=2010 & f5==5), graphregion(color(white))
xtitle("Application Year") ytitle("Firm Exit Rate")
legend(order(1 "1st Firm Quintile" 2 "2nd Firm Quintile" 3 "3rd Firm Quintile" 4 "4th Firm Quintile" 5 "5th Firm Quintile")) ;

graph export "$figfolder/firm_size_exit_$corp.pdf",replace;

restore

preserve
#delimit ;
twoway (connected s_cit appyear if appyear>=1976 & appyear<=2014 & adj_top==0) 
(connected s_cit appyear if appyear>=1976 & appyear<=2014 & adj_top==1), graphregion(color(white))
ytitle("Self Citation Rate") legend(order(1 "Bottom 90%" 2 "Top 10%"));
graph export "$figfolder/self_cit_rate_by_top_firms_$corp.pdf",replace;


preserve

gen f5=.
replace f5=1 if f10f>=1 & f10f<=2
replace f5=2 if f10f>=3 & f10f<=4
replace f5=3 if f10f>=5 & f10f<=6
replace f5=4 if f10f>=7 & f10f<=8
replace f5=5 if f10f>=9 & f10f<=10


gen pre_firm=L.f5
gen post_firm=F.f5

keep if firm_entrant==1 | firm_exit==1
collapse pre_firm post_firm , by(appyear f5)
#delimit ;
twoway (connected pre_firm appyear if appyear>=1980 & appyear<=2010 & f5==1) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & f5==2) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & f5==3) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & f5==4) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & f5==5), graphregion(color(white))
xtitle("Application Year") ytitle("Previous Firm Size")
legend(order(1 "1st Firm Quintile" 2 "2nd Firm Quintile" 3 "3rd Firm Quintile" 4 "4th Firm Quintile" 5 "5th Firm Quintile")) ;

graph export "$figfolder/firm_movefrom_entrant_$corp.pdf",replace;


#delimit ;
twoway (connected post_firm appyear if appyear>=1980 & appyear<=2010 & f5==1) 
(connected post_firm appyear if appyear>=1980 & appyear<=2010 & f5==2) 
(connected post_firm appyear if appyear>=1980 & appyear<=2010 & f5==3) 
(connected post_firm appyear if appyear>=1980 & appyear<=2010 & f5==4) 
(connected post_firm appyear if appyear>=1980 & appyear<=2010 & f5==5), graphregion(color(white))
xtitle("Application Year") ytitle("Next Firm Size")
legend(order(1 "1st Firm Quintile" 2 "2nd Firm Quintile" 3 "3rd Firm Quintile" 4 "4th Firm Quintile" 5 "5th Firm Quintile")) ;

graph export "$figfolder/firm_moveto_exit_$corp.pdf",replace;

restore



preserve

gen top_firm=0
replace top_firm=1 if f10f==10

gen pre_firm=L.f10f
gen post_firm=F.f10f



keep if firm_entrant==1
collapse pre_firm post_firm , by(appyear top_firm)
replace pre_firm=pre_firm/10
replace post_firm=post_firm/10
#delimit ;
twoway (connected pre_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==0) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==1) , graphregion(color(white))
xtitle("Application Year") ytitle("Previous Firm Size")
legend(order(1 "Bottom 90%" 2 "Top 10%")) ;

graph export "$figfolder/firm_movefrom_entrant_t10_1.pdf",replace;


#delimit ;
twoway (connected post_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==0) 
(connected post_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==1) , graphregion(color(white))
xtitle("Application Year") ytitle("Next Firm Size")
legend(order(1 "Bottom 90%" 2 "Top 10%")) ;

graph export "$figfolder/firm_moveto_exit_t10_1.pdf",replace;

restore





preserve

gen top_firm=0
replace top_firm=1 if f10f==10

gen pre_firm=L.f10f
gen post_firm=F.f10f

keep if top_firm==1 | f10f<=5


collapse firm_exit , by(appyear top_firm)
gen pre_firm=firm_exit
#delimit ;
twoway (connected pre_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==0) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==1) , graphregion(color(white))
xtitle("Application Year") ytitle("Firm Exit Rate")
legend(order(1 "Bottom 50%" 2 "Top 10%")) ;

graph export "$figfolder/firm_exit_rate_t1_b50.pdf",replace;

restore



preserve

gen top_firm=0
replace top_firm=1 if f10f==10

gen pre_firm=L.f10f
gen post_firm=F.f10f
keep if tsize==3
keep if top_firm==1 | f10f<=5
drop firm_exit
rename ttb_a firm_exit
collapse firm_exit , by(appyear top_firm)
gen pre_firm=firm_exit
#delimit ;
twoway (connected pre_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==0) 
(connected pre_firm appyear if appyear>=1980 & appyear<=2010 & top_firm==1) , graphregion(color(white))
xtitle("Application Year") ytitle("Time to Build Patent")
legend(order(1 "Bottom 50%" 2 "Top 10%")) ;

graph export "$figfolder/ttb_compare_x_firm.pdf",replace;

restore





preserve

gen f5=.
replace f5=1 if f10f>=1 & f10f<=2
replace f5=2 if f10f>=3 & f10f<=4
replace f5=3 if f10f>=5 & f10f<=6
replace f5=4 if f10f>=7 & f10f<=8
replace f5=5 if f10f>=9 & f10f<=10

collapse f_cit3, by(patnumpp1 f5)


rename f_cit post_firm
rename patnumpp1 appyear


#delimit ;
twoway (connected post_firm appyear if appyear<=50 & f5==1) 
(connected post_firm appyear if appyear<=50  & f5==2) 
(connected post_firm appyear if appyear<=50  & f5==3) 
(connected post_firm appyear if appyear<=50  & f5==4) 
(connected post_firm appyear if appyear<=50  & f5==5), graphregion(color(white))
xtitle("Individual Patent #") ytitle("Citations")
legend(order(1 "1st Firm Quintile" 2 "2nd Firm Quintile" 3 "3rd Firm Quintile" 4 "4th Firm Quintile" 5 "5th Firm Quintile")) ;



restore




*Big Teams+Small Firms, Big Firms and Small Teams, Small Teams and Small Firms, Big+Big


***Splits by approximate size
gen f5=.
**Bottom 50%
replace f5= 1 if f10==1
**Approx Top 50%
replace f5=2 if f10==2
**Approx 30%-15%
replace f5=3 if f10==3
***Approx 15%-1%
replace f5=4 if f10>=4 & f10<=6
***approx top 1%
replace f5=5 if f10>=7 & f10~=.



preserve

collapse f_cit3, by(patnumpp1 f5)


rename f_cit post_firm
rename patnumpp1 appyear


#delimit ;
twoway (connected post_firm appyear if appyear<=50 & f5==1) 
(connected post_firm appyear if appyear<=50  & f5==2) 
(connected post_firm appyear if appyear<=50  & f5==3) 
(connected post_firm appyear if appyear<=50  & f5==4) 
(connected post_firm appyear if appyear<=50  & f5==5), graphregion(color(white))
xtitle("Individual Patent #") ytitle("Citations")
legend(order(1 "Bottom 50%" 2 "50-35%" 3 "30-15%" 4 "15-1%" 5 "Top 1%")) ;

restore



**fall in knowledge diffusion would be a fall in the rate of movement of inventor from top firm to lower firm:

gen fall_out=.
replace fall_out=0 if f5==5 & F.f5==5
replace fall_out=1 if f5==5 & F.f5<5

tabstat fall_out, by(appyear)



preserve

collapse f_cit3, by(patnumpp1 f5)


rename f_cit post_firm
rename patnumpp1 appyear
#delimit ;
twoway (connected post_firm appyear if appyear<=50 & f5==1) 
(connected post_firm appyear if appyear<=50  & f5==2) 
(connected post_firm appyear if appyear<=50  & f5==3) 
(connected post_firm appyear if appyear<=50  & f5==4) 
(connected post_firm appyear if appyear<=50  & f5==5), graphregion(color(white))
xtitle("Individual Patent #") ytitle("Citations")
legend(order(1 "Bottom 50%" 2 "50-35%" 3 "30-15%" 4 "15-1%" 5 "Top 1%")) ;

graph export "$figfolder/patent_num_cit_CP.pdf",replace;

restore



by assignee appyear, sort: gen nvals = _n == 1 

preserve
keep if f5==5 & appyear>=1976 & appyear<=2013
collapse (sum) nvals, by(appyear)
twoway connected nvals appyear, graphregion(color(white)) xtitle("Application Year") ytitle("Unique Firms in Top 1%") xline(1995) ylabel(0(20)140)
graph export "$figfolder/uniq_firms_intop1_CP.pdf",replace

restore



preserve

collapse fall_out, by(appyear)
keep if appyear>=1976 & appyear<=2015
twoway connected fall_out appyear, graphregion(color(white)) xtitle("Application Year") ytitle("Rate of Leaving Top 1% Firms") xline(1995)

graph export "$figfolder/firm_fallout_f5_timeseries.pdf",replace

restore





gen top_10=.
replace top_10=1 if f10f==10
gen total=0
replace total=1



preserve
collapse (sum) total top_10, by(appyear)
gen prop10=top_10/total
#delimit ;
twoway connected prop10 appyear if appyear>=1976 & appyear<=2015, graphregion(color(white)) 
xtitle("Application Year") ytitle("Share of Observations in Top Decile of Firms");

graph export "$figfolder/topcount_by_decile_jan21.pdf",replace

restore


preserve
duplicates drop patent, force
bys assignee appyear: gen count=_N
keep assignee appyear count
duplicates drop assignee appyear, force
bys appyear: egen c10=xtile(count), nq(10)
drop count
save "$datasets/firm_deciles_byyear_jan21.dta"
restore

merge m:1 assignee appyear using "$datasets/firm_deciles_byyear_jan21.dta"



gen t10_flow=.
replace t10_flow=1 if c10==10



preserve
collapse (sum) total t10_flow, by(appyear)
gen prop10=t10_flow/total
#delimit ;
twoway connected prop10 appyear if appyear>=1976 & appyear<=2015, graphregion(color(white)) 
xtitle("Application Year") ytitle("Share of Patents in Top Decile of Firms");

graph export "$figfolder/topcountflow_by_decile_jan21.pdf",replace;

restore





forvalues y=1980/2010{
corr xi lcit if appyear==`y' & adj_top==1
replace corr_meas=`r(rho)' if adj_top==1 & appyear==`y'
corr xi lcit if appyear==`y' & adj_top==0
replace corr_meas=`r(rho)' if adj_top==0 & appyear==`y'
}


gen lxi=ln(xi)
forvalues y=1980/2010{
corr lxi lcit if appyear==`y' & adj_top==1
replace corr_meas=`r(rho)' if adj_top==1 & appyear==`y'
corr lxi lcit if appyear==`y' & adj_top==0
replace corr_meas=`r(rho)' if adj_top==0 & appyear==`y'
}


forvalues y=1980/2010{
corr xi f_cit3 if appyear==`y' & adj_top==1
replace corr_meas=`r(rho)' if adj_top==1 & appyear==`y'
corr xi f_cit3 if appyear==`y' & adj_top==0
replace corr_meas=`r(rho)' if adj_top==0 & appyear==`y'
}


forvalues y=1976/2010{
corr lxi lcit if appyear==`y'
replace corr_meas=`r(rho)' if appyear==`y'
}


forvalues y=1976/2010{
corr xi f_cit3 if appyear==`y' 
replace corr_meas=`r(rho)' if appyear==`y'
}


preserve

collapse corr_meas, by(appyear adj_top)
#delimit ;
twoway (connected corr_meas appyear if appyear>=1980 & appyear<=2009 & adj_top==1);
 (connected corr_meas appyear if appyear>=1980 & appyear<=2009 & adj_top==0), graphregion(color(white)) 
 legend(order(1 "Largest firms" 2 "Smaller firms"));

restore

preserve
collapse corr_meas, by(appyear)
tsset appyear
gen r_corr=(L2.corr_meas+L.corr_meas+corr_meas)/3
#delimit ;
twoway (connected corr_meas appyear if appyear>=1976 & appyear<=2009 ),
graphregion(color(white)) ytitle("Corr(Log Private Value, Log Cite)") xlabel(1975(5)2010);
graph export "$figfolder/corr_logval_logcite_1976_2009.pdf",replace;
restore



****Ratio of self-citations



preserve
duplicates drop patent, force
replace f5=2 if f5>=2 & f5<=4
collapse tsize, by(f5 appyear)
rename tsize post_firm
#delimit ;
twoway (connected post_firm appyear if f5==1) 
(connected post_firm appyear if f5==2) 
(connected post_firm appyear if f5==5), graphregion(color(white))
xtitle("Application Year") ytitle("Team Size")
legend(order(1 "Bottom 50%" 2 "Upper 49%" 3 "Top 1%")) ;

graph export "$figfolder/teamsize_byfirmsize_jan21.pdf",replace;


restore






***repeated ipc by firm size
preserve
collapse isrepeat*, by(f10)
twoway scatter isrepeat_alone f10, graphregion(color(white)) ytitle("Repeated IPC Alone") xtitle("Firm Decile")
graph export "$figfolder/isrepeat_gipc_alone_f10_$corp.pdf",replace
twoway scatter isrepeat_team f10, graphregion(color(white)) ytitle("Repeated IPC Team") xtitle("Firm Decile")
graph export "$figfolder/isrepeat_gipc_team_f10_$corp.pdf",replace
restore

preserve
collapse isrepeat*, by(f10f)
twoway scatter isrepeat_alone f10f, graphregion(color(white)) ytitle("Repeated IPC Alone") xtitle("Firm Decile")
graph export "$figfolder/isrepeat_gipc_alone_f10f_$corp.pdf",replace
twoway scatter isrepeat_team f10f, graphregion(color(white)) ytitle("Repeated IPC Team") xtitle("Firm Decile")
graph export "$figfolder/isrepeat_gipc_team_f10f_$corp.pdf",replace
restore




preserve
keep if appyear==2000
collapse isrepeat*, by(f10)
twoway scatter isrepeat_alone f10, graphregion(color(white)) ytitle("Repeated IPC Alone") xtitle("Firm Decile")
graph export "$figfolder/isrepeat_gipc_alone_f10_ay2000_$corp.pdf",replace

twoway scatter isrepeat_team f10, graphregion(color(white)) ytitle("Repeated IPC Team") xtitle("Firm Decile")
graph export "$figfolder/isrepeat_gipc_team_f10_ay2000_$corp.pdf",replace
restore


xtset categ1 patnumpp1
gen spin_off=.
replace spin_off=0 if F.patnumpp1==patnumpp1+1 & f10>=7 & f10<=10
replace spin_off=1 if F.patnumpp1==patnumpp1+1 & (F.f10==0 | F.f10==1) & f10>=7 & f10<=10

gen spin_offf=.
replace spin_offf=0 if F.patnumpp1==patnumpp1+1 & f10f>=7 & f10f<=10
replace spin_offf=1 if F.patnumpp1==patnumpp1+1 & (F.f10f==0 | F.f10f==1) & f10f>=7 & f10f<=10



xtset categ1 patnumpp1

******Probability of Repeated IPC3/
gen change_decline=F.f10-f10
replace change_decline=. if F.assignee==assignee
gen change_decline_f=F.f10f-f10f
replace change_decline_f=. if F.assignee==assignee
gen is_repeat_firm_inv=1-is_repeat_firm

label var change_decline "Move change in firm size"
label var change_decline_f "Move change in firm size"
label var spin_off "Ind. Spin-off"
label var spin_offf "Ind. Spin-off"
label var survive "Surviving Team"
label var is_repeat "Next Is Repeat IPC"
label var is_repeat_firm "Next Is Repeat Ind-Firm"
label var is_repeat_firm_inv "Next Move x Firm"
label var patnumpp1 "Avg. Inventor Patent Age"
label var m_ttb "Average Time to Build"



**patent by cohort
bys categ1: egen min_year=min(appyear)
gen cohort=.
replace cohort=0 if min_year>=1975 & min_year<=1984
replace cohort=1 if min_year>=1985 & min_year<=1994
replace cohort=2 if min_year>=1995 & min_year<=2004
replace cohort=3 if min_year>=2005 & min_year<=2014

gen cohort_check=.
replace cohort_check=0 if appyear>=1975 & appyear<=1984
replace cohort_check=1 if appyear>=1985 & appyear<=1994
replace cohort_check=2 if appyear>=1995 & appyear<=2004
replace cohort_check=3 if appyear>=2005 & appyear<=2014

bys categ1 g_ipc (patnumpp1): gen new=_n==1
bys categ1 (patnumpp1): gen unique_ipc=sum(new)
gen new1=new
replace new1=0 if tsize>1
bys categ1 (patnumpp1): gen unique1_ipc=sum(new1)



***COHORT ANALYSIS
preserve
collapse (mean) unique1_ipc unique_ipc, by(patnumpp1 cohort)
#delimit ; 
twoway (line unique_ipc patnumpp1 if cohort==0 & patnumpp1<=100) 
(line unique_ipc patnumpp1 if cohort==1 & patnumpp1<=100) 
(line unique_ipc patnumpp1 if cohort==2 & patnumpp1<=100) 
(line unique_ipc patnumpp1 if cohort==3 & patnumpp1<=100), graphregion(color(white)) xtitle("Patent Number") 
legend(order(1 "1975-84" 2 "1985-94" 3 "1995-2004" 4 "2005-")) ytitle("Unique IPC");

graph export "$figfolder/cohort_analysis_4_allpat_$corp.pdf", replace as(pdf);
restore;
#delimit cr
preserve
keep if tsize==1
collapse (mean) unique1_ipc unique_ipc, by(patnumpp1 cohort)
keep if patnumpp1<=50
#delimit ; 
twoway (line unique1_ipc patnumpp1 if cohort==0 & patnumpp1<=100) 
(line unique1_ipc patnumpp1 if cohort==1 & patnumpp1<=100) 
(line unique1_ipc patnumpp1 if cohort==2 & patnumpp1<=100) 
(line unique1_ipc patnumpp1 if cohort==3 & patnumpp1<=100), graphregion(color(white)) xtitle("Patent Number") 
legend(order(1 "1975-84" 2 "1985-94" 3 "1995-2004" 4 "2005-")) ytitle("Unique IPC Sole-Author");

graph export "$figfolder/cohort_analysis_4_1pat_$corp.pdf", replace as(pdf);
restore;
#delimit cr


***COHORT ANALYSIS WITH "COHORT CHECK"
preserve
keep if tsize==1 & cohort==cohort_check
collapse (mean) unique1_ipc unique_ipc, by(patnumpp1 cohort)
keep if patnumpp1<=50
#delimit ; 
twoway (line unique1_ipc patnumpp1 if cohort==0 & patnumpp1<=100) 
(line unique1_ipc patnumpp1 if cohort==1 & patnumpp1<=100) 
(line unique1_ipc patnumpp1 if cohort==2 & patnumpp1<=100) 
(line unique1_ipc patnumpp1 if cohort==3 & patnumpp1<=100), graphregion(color(white)) xtitle("Patent Number") 
legend(order(1 "1975-84" 2 "1985-94" 3 "1995-2004" 4 "2005-")) ytitle("Unique IPC Sole-Author");

graph export "$figfolder/cohort_analysis_withincohort_4_1pat_$corp.pdf", replace as(pdf);
restore;
#delimit cr
preserve
keep if cohort_check==cohort
collapse (mean) unique1_ipc unique_ipc, by(patnumpp1 cohort)
keep if patnumpp1<=50
#delimit ; 
twoway (line unique_ipc patnumpp1 if cohort==0 & patnumpp1<=100) 
(line unique_ipc patnumpp1 if cohort==1 & patnumpp1<=100) 
(line unique_ipc patnumpp1 if cohort==2 & patnumpp1<=100) 
(line unique_ipc patnumpp1 if cohort==3 & patnumpp1<=100), graphregion(color(white)) xtitle("Patent Number") 
legend(order(1 "1975-84" 2 "1985-94" 3 "1995-2004" 4 "2005-")) ytitle("Unique IPC");

graph export "$figfolder/cohort_analysis_4_withincohort_$corp.pdf", replace as(pdf);
restore;
#delimit cr

gen count=1
***SHARE AMONGST TOP FIRMS
preserve
keep if patnumpp==10
gen top_firm=0
replace top_firm=1 if f10f==10 | f10f==9
collapse (sum) inv_p_year=count, by(top_firm appyear)
bys appyear: egen total=total(inv_p_year)
gen share_top=inv_p_year/total
keep if top_firm==1
twoway connected share_top appyear if appyear>=$iyear & appyear<=$fyear, graphregion(color(white)) xtitle("Year") ytitle("Share in Top Quintile")
graph export "$figfolder/share_inventorf_cumulative_flow_$corp.pdf", replace as(pdf)
restore


preserve
duplicates drop patent, force
gen top_firm=0
replace top_firm=1 if f10f==10 | f10f==9
collapse (mean) inv_p_year=f_cit5, by(top_firm appyear)
bys appyear: egen total=total(inv_p_year)
gen share_top=inv_p_year/total
keep if top_firm==1
twoway connected share_top appyear if appyear>=$iyear & appyear<=$fyear, graphregion(color(white)) xtitle("Year") ytitle("Rel. Cit. in Top Quintile")
graph export "$figfolder/share_inventorf_cumulative_flow_$corp.pdf", replace as(pdf)
restore

***BY IPC1:

***SHARE AMONGST TOP FIRMS
preserve
gen top_firm=0
replace top_firm=1 if f10f==10 | f10f==9
duplicates drop patent, force
collapse (sum) inv_p_year=count, by(top_firm appyear ipc1)
bys appyear ipc1: egen total=total(inv_p_year)
gen share_top=inv_p_year/total
keep if top_firm==1
#delimit ;
twoway (connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="A")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="B")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="C")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="D")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="E")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="F")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="G")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="H"), legend(order(1 "A" 2 "B" 3 "C" 4 "D" 5 "E" 6 "F" 7 "G" 8 "H"))
graphregion(color(white)) xtitle("Year") ytitle("Share in Top Quintile");
graph export "$figfolder/share_patentf_cumulative_ipc1_within.pdf", replace as(pdf);
restore;
#delimit cr

preserve
gen top_firm=0
keep if patnumpp1==1
replace top_firm=1 if f10f==10 | f10f==9
*duplicates drop patent, force
collapse (sum) inv_p_year=count, by(top_firm appyear ipc1)
bys appyear ipc1: egen total=total(inv_p_year)
gen share_top=inv_p_year/total
keep if top_firm==1
#delimit ;
twoway (connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="A")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="B")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="C")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="D")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="E")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="F")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="G")
(connected share_top appyear if appyear>=$iyear & appyear<=$fyear & ipc1=="H"), legend(order(1 "A" 2 "B" 3 "C" 4 "D" 5 "E" 6 "F" 7 "G" 8 "H"))
graphregion(color(white)) xtitle("Year") ytitle("Share in Top Quintile");
graph export "$figfolder/share_inventorf_1sttime_cumulative_ipc1_within.pdf", replace as(pdf);
restore




**SHARE PATENTS
preserve
duplicates drop patent, force
gen top_firm=0
replace top_firm=1 if f10f==10 | f10f==9
collapse (sum) patent_per_year=count, by(top_firm appyear)
bys appyear: egen total=total(patent_per_year)
gen share_top=patent_per_year/total
keep if top_firm==1
twoway connected share_top appyear if appyear>=$iyear & appyear<=$fyear, graphregion(color(white)) xtitle("Year") ytitle("Share in Top Quintile")
graph export "$figfolder/share_topf_cumulative_flow_$corp.pdf", replace as(pdf)
restore

***UNIQUE IPC PER FIRM
preserve
keep if tsize==1
collapse unique1_ipc unique_ipc patnumpp1, by(f10f)
gen unique_pp=unique1/patnumpp1
twoway (connected unique_pp f10), graphregion(color(white)) xtitle("Firm Decile") ytitle("Unique IPC per Patent") ylabel(0(0.05)0.30)
graph export "$figfolder/unique_pp_sole_f10f_$corp.pdf", replace as(pdf)
restore

preserve
collapse unique1_ipc unique_ipc patnumpp1, by(f10f)
gen unique_pp=unique_ipc/patnumpp1
twoway (connected unique_pp f10), graphregion(color(white)) xtitle("Firm Decile") ytitle("Unique IPC per Patent") ylabel(0(0.05)0.30)
graph export "$figfolder/unique_pp_all_f10f_$corp.pdf", replace as(pdf)
restore





**by team, overall, by team size, all vars
gen team=0
replace team=1 if tsize>1 & tsize~=.
**set of vars we plot by
local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive spin_off is_repeat_firm_inv change_decline change_decline_f

foreach v in `vars' {
	local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}



preserve
*keep if team==L.team
*keep if L.team==0
collapse `vars',  by(team appyear)
foreach v in `vars'{
 label var `v' "`l`v''"
 }

foreach var in `vars'{
local lab1: variable label `var'
di "`lab1'"
twoway (connected  `var' appyear if team==0, lwidth(medthick)) (connected  `var' appyear if team==1, lwidth(medthick))  , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Alone" 2 "In Team"))
graph export "$figfolder/`var'_overall_byteam_noteam_lagirrev_$corp.pdf", replace as(pdf)
}
restore



local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive spin_off is_repeat_firm_inv change_decline

foreach v in `vars' {
	local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}




****No split by size or team size
preserve
keep if appyear>=$iyear & appyear<=$fyear
local tmax=$tmax
replace tsize=`tmax' if tsize>`tmax' & tsize ~=.
replace survive=1 if survive==2
keep if assignee~=0
collapse `vars',  by(appyear)
foreach v in `vars'{
 label var `v' "`l`v''"
 }

foreach var in `vars'{
local lab1: variable label `var'
di "`lab1'"
twoway (connected  `var' appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/`var'_overall_`tmax'_2015_$corp.pdf", replace as(pdf)

}
restore

local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive spin_off is_repeat_firm_inv change_decline change_decline_f

foreach v in `vars' {
	local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}

****Control by size or team size
preserve
keep if appyear>=$iyear & appyear<=$fyear
local tmax=$tmax
replace tsize=`tmax' if tsize>`tmax' & tsize ~=.
replace survive=1 if survive==2
keep if assignee~=0
gen tsize2=tsize^2
foreach var in `vars'{
reg `var' i.g_ipc tsize tsize2 i.f10
predict p`var'
replace `var'=`var'-p`var'
}

collapse `vars',  by(appyear)
foreach v in `vars'{
 label var `v' "`l`v''"
 }

foreach var in `vars'{
local lab1: variable label `var'
di "`lab1'"
twoway (connected  `var' appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))
graph export "$figfolder/`var'_overall_`tmax'_controls_$corp.pdf", replace as(pdf)
}
restore




local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive spin_off is_repeat_firm_inv change_decline

foreach v in `vars' {
	local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}

****By team size
preserve
keep if appyear>=$iyear & appyear<=$fyear
local tmax=$tmax
replace tsize=`tmax' if tsize>`tmax' & tsize ~=.
replace survive=1 if survive==2




collapse `vars',  by(tsize appyear)


foreach v in `vars'{
 label var `v' "`l`v''"
 }

foreach var in `vars'{
local lab1: variable label `var'
di "`lab1'"
twoway (connected  `var' appyear if tsize==1, lwidth(medthick)) ///
(connected   `var' appyear if tsize==2, lwidth(medthick)) ///
(connected   `var' appyear if tsize==3, lwidth(medthick)) ///
(connected   `var' appyear if tsize==4, lwidth(medthick)) ///
(connected   `var' appyear if tsize==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("`lab1'",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label( 1 "1-person" ) label( 2 "2-person") label( 3 "3-person") label( 4 "4-person") label( 5 "5-person or more") size(med) ) 

graph export "$figfolder/`var'_byteamsize_`tmax'_$corp.pdf", replace as(pdf)

}

restore




local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive tsize spin_off

foreach v in `vars' {
	local l`v' : variable label `v'
       if `"`l`v''"' == "" {
		local l`v' "`v'"
}
}

******By Firm Size
preserve
keep if appyear>=$iyear & appyear<=$fyear
***drop if there's no additonal atent
xtset categ1 patnumpp1
replace survive=. if survive==0 & F.patnumpp1==.
duplicates drop patent, force
keep if assignee~=0 & assignee~=.
egen fsize= xtile(firmseq), by(appyear) nq(5)
local tmax=$tmax
replace tsize=`tmax' if tsize>`tmax' & tsize ~=.
keep if fsize>=1 & fsize<=5
collapse `vars',  by(fsize appyear)

foreach v in `vars'{
 label var `v' "`l`v''"
 }
foreach var in `vars'{
twoway (connected  `var' appyear if fsize==1, lwidth(medthick)) ///
(connected   `var' appyear if fsize==2, lwidth(medthick)) ///
(connected   `var' appyear if fsize==3, lwidth(medthick)) ///
(connected   `var' appyear if fsize==4, lwidth(medthick)) ///
(connected   `var' appyear if fsize==5, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(,height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) ///
legend(region(lcolor(white)) label( 1 "1st Quintile Firm Size" ) label( 2 "2nd Quintile") label( 3 "3rd Quintile") label( 4 "4th Quintile") label( 5 "5th Quintile") size(med) ) 

graph export "$figfolder/`var'_byfirmsize5_`tmax'_$corp.pdf", replace as(pdf)

}
restore





preserve
collapse f10f, by(patnumpp1 appyear)
keep if patnumpp1<=10
rename patnumpp1 xtilep
keep if appyear>=1980
bys appyear: egen meanf10=mean(f10f)
replace f10f=f10f/meanf10
gen blank=.
replace blank=f10f if appyear==1980
bys xtilep: egen m1980=mean(f10f)
replace f10f=f10f/m1980
sort xtilep appyear
#delimit ;
twoway (connected f10f appyear if xtilep==1) (connected f10f appyear if xtilep==2) 
(connected f10f appyear if xtilep==3) (connected f10f appyear if xtilep==4) (connected f10f appyear if xtilep==5)
(connected f10f appyear if xtilep==6) (connected f10f appyear if xtilep==7) (connected f10f appyear if xtilep==8)
(connected f10f appyear if xtilep==9) (connected f10f appyear if xtilep==10), xtitle("Year") ytitle("Mean Firm Decile") graphregion(color(white))
legend(order(1 "1st Patent" 2 "2nd Patent" 3 "3rd Patent" 4 "4th Patent" 5 "5th Patent" 6 "6th Patent" 7 "7th Patent" 8 "8th Patent" 9 "9th Patent" 10 "10th Patent"));
graph export "$figfolder/pearce/firm_dec_age_age_by_ind_renorm_$corp.pdf", replace;
restore




bys appyear: egen xtilep=xtile(patnumpp1), nq(10)

bys appyear: egen xtile4=xtile(patnumpp1), nq(4)
preserve
collapse f10f, by(xtilep appyear)
keep if appyear>=1980
bys appyear: egen meanf10=mean(f10f)
replace f10f=f10f/meanf10
gen blank=.
replace blank=f10f if appyear==1980
bys xtilep: egen m1980=mean(f10f)
replace f10f=f10f/m1980
sort xtilep appyear
#delimit ;
twoway (connected f10f appyear if xtilep==1) (connected f10f appyear if xtilep==2) 
(connected f10f appyear if xtilep==3) (connected f10f appyear if xtilep==4) (connected f10f appyear if xtilep==5)
(connected f10f appyear if xtilep==6) (connected f10f appyear if xtilep==7) (connected f10f appyear if xtilep==8)
(connected f10f appyear if xtilep==9) (connected f10f appyear if xtilep==10), xtitle("Year") ytitle("Mean Firm Decile") graphregion(color(white))
legend(order(1 "1st Decile" 2 "2nd Decile" 3 "3rd Decile" 4 "4th Decile" 5 "5th Decile" 6 "6th Decile" 7 "7th Decile" 8 "8th Decile" 9 "9th Decile" 10 "10th Decile"));
graph export "$figfolder/pearce/firm_dec_agedec_by_ind_renorm_$corp.pdf", replace;
restore





preserve
drop xtilep
rename xtile4 xtilep
collapse (mean) f10f xtilep, by(patent appyear)
replace xtilep=round(xtilep)
collapse f10f, by(xtilep appyear)
keep if appyear>=1980
bys appyear: egen meanf10=mean(f10f)
replace f10f=f10f/meanf10
gen blank=.
replace blank=f10f if appyear==1980
bys xtilep: egen m1980=mean(f10f)
replace f10f=f10f/m1980
sort xtilep appyear
#delimit ;
twoway (connected f10f appyear if xtilep==1) (connected f10f appyear if xtilep==2) 
(connected f10f appyear if xtilep==3) (connected f10f appyear if xtilep==4) , xtitle("Year") ytitle("Normalized Firm Size") graphregion(color(white))
legend(order(1 "1st Quantile" 2 "2nd Quantile" 3 "3rd Quantile" 4 "4th Quantile"));
graph export "$figfolder/pearce/firm_dec_agedec_by_ind_renorm_$corp.pdf", replace;
restore

global corp corp

preserve
drop xtilep
bys patent: egen mean_age=mean(patnumpp1)
replace xtile4=1 if mean_age>=1 & mean_age<=3
replace xtile4=2 if mean_age>=4 & mean_age<=6
replace xtile4=3 if mean_age>=7 & mean_age<=10
replace xtile4=4 if mean_age>10 & mean_age~=.
duplicates drop patent, force
rename xtile4 xtilep
collapse f10f, by(xtilep appyear)
keep if appyear>=1980
bys appyear: egen meanf10=mean(f10f)
replace f10f=f10f/meanf10
gen blank=.
replace blank=f10f if appyear==1980
bys xtilep: egen m1980=mean(f10f)
replace f10f=f10f/m1980
sort xtilep appyear
#delimit ;
twoway (connected f10f appyear if xtilep==1) (connected f10f appyear if xtilep==2) 
(connected f10f appyear if xtilep==3) (connected f10f appyear if xtilep==4) , xtitle("Year") ytitle("Normalized Firm Size") graphregion(color(white))
legend(order(1 "Patent 1-3" 2 "Patent 4-6" 3 "Patent 7-9" 4 "Patent 10+"));
graph export "$figfolder/pearce/firm_dec_agedec_by_ind_renorm4_10_$corp.pdf", replace;
restore








preserve
collapse f10f, by(xtilep appyear)

keep if appyear>=1980
#delimit ;
twoway (connected f10f appyear if xtilep==1) (connected f10f appyear if xtilep==2) 
(connected f10f appyear if xtilep==3) (connected f10f appyear if xtilep==4) (connected f10f appyear if xtilep==5)
(connected f10f appyear if xtilep==6) (connected f10f appyear if xtilep==7) (connected f10f appyear if xtilep==8)
(connected f10f appyear if xtilep==9) (connected f10f appyear if xtilep==10), xtitle("Year") ytitle("Mean Firm Decile") graphregion(color(white))
legend(order(1 "1st Decile" 2 "2nd Decile" 3 "3rd Decile" 4 "4th Decile" 5 "5th Decile" 6 "6th Decile" 7 "7th Decile" 8 "8th Decile" 9 "9th Decile" 10 "10th Decile"));
graph export "$figfolder/pearce/firm_dec_age_by_ind_$corp.pdf", replace;

restore





preserve

collapse xtilep, by(f10f appyear)

keep if appyear>=1980
rename xtilep xp
rename f10f xtilep
rename xp f10f
#delimit ;
twoway (connected f10f appyear if xtilep==1) (connected f10f appyear if xtilep==2) 
(connected f10f appyear if xtilep==3) (connected f10f appyear if xtilep==4) (connected f10f appyear if xtilep==5)
(connected f10f appyear if xtilep==6) (connected f10f appyear if xtilep==7) (connected f10f appyear if xtilep==8)
(connected f10f appyear if xtilep==9) (connected f10f appyear if xtilep==10), xtitle("Year (x Firm Decile)") ytitle("Mean Ind. Age Decile") graphregion(color(white))
legend(order(1 "1st Decile" 2 "2nd Decile" 3 "3rd Decile" 4 "4th Decile" 5 "5th Decile" 6 "6th Decile" 7 "7th Decile" 8 "8th Decile" 9 "9th Decile" 10 "10th Decile"));
graph export "$figfolder/pearce/individual_age_by_firm_$corp.pdf", replace

restore



******Corrs (Corr Age_i/Size_f and Corr Size_f Repeat inventor)
preserve
keep if appyear>=$iyear & appyear<=$fyear
keep if tsize==2

*keep if assignee~=. & assignee~=0
*gen fwd_asg=F.count
bys patent: egen mean_age=mean(patnumpp1)
bys patent: egen isrep=mean(is_repeat_firm)
bys patent: egen isrep2=mean(is_repeat_firm)

duplicates drop patent, force
replace firmseq=1 if assignee==0
gen lnc=firmseq
gen lnp=mean_age
gen cor1=.
gen cor2=.
gen cor3=.
gen cor4=.

forvalues i=$iyear/$fyear{
corr lnc  isrep if appyear==`i'
replace cor1=`r(rho)' if appyear==`i'
corr lnc lnp if appyear==`i'
replace cor2=`r(rho)' if appyear==`i'
corr lnc survive if appyear==`i'
replace cor3=`r(rho)' if appyear==`i'
corr lnc survive if appyear==`i'
replace cor4=`r(rho)' if appyear==`i'
}

local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive tsize cor1 cor2 cor3
collapse `vars', by(appyear)


twoway (connected cor2 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Inventor Age & Firm Size")
graph export "$figfolder/pearce/cor_patview_inventorage_firmseq_overtime_ts2_$corp.pdf", replace


twoway (connected cor3 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Survive Team & Firm Size")
graph export "$figfolder/pearce/cor_patview_survive_firmsize_overtime_ts2_$corp.pdf", replace

twoway (connected cor1 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Repeated Inventor & Firm Size")
graph export "$figfolder/pearce/cor_patview_repeat_firmsize_ts2_$corp.pdf", replace

restore


preserve
keep if appyear>=$iyear & appyear<=$fyear
*keep if assignee~=. & assignee~=0
*gen fwd_asg=F.count
bys patent: egen mean_age=mean(patnumpp1)
bys patent: egen mean_p10=mean(xtilep)
bys patent: egen isrep=mean(is_repeat_firm)
bys patent: egen isrep2=mean(is_repeat_firm)
replace xtilep=mean_p10
duplicates drop patent, force
*keep if firmseq<=10000 & patnumpp1<=100
replace firmseq=1 if assignee==0
gen lnc=ln(firmseq)
gen lnp=ln(mean_age)
gen cor1=.
gen cor2=.
gen cor3=.
gen cor4=.

forvalues i=$iyear/$fyear{
corr lnc lnp if appyear==`i'
replace cor1=`r(rho)' if appyear==`i'
corr mean_age firmseq if appyear==`i'
replace cor2=`r(rho)' if appyear==`i'
corr f10f xtilep if appyear==`i'
replace cor3=`r(rho)' if appyear==`i'
}

local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive tsize cor1 cor2 cor3
collapse `vars', by(appyear)


twoway (connected cor1 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Log Inventor Age & Log Firm Size")
graph export "$figfolder/pearce/cor_patview_lnage_lnfs_notopcoded_$corp.pdf", replace

twoway (connected cor2 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Inventor Age & Firm Size")
graph export "$figfolder/pearce/cor_patview_inventorage_firmseq_notopcoded_$corp.pdf", replace

twoway (connected cor3 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Normalized Inv. Age & Firm Size")
graph export "$figfolder/pearce/cor_patview_repeat_firmsize_notopcoded_$corp.pdf", replace

restore




preserve
keep if appyear>=$iyear & appyear<=$fyear
*keep if assignee~=. & assignee~=0
*gen fwd_asg=F.count
bys patent: egen mean_age=mean(patnumpp1)
bys patent: egen mean_p10=mean(xtilep)
bys patent: egen isrep=mean(is_repeat_firm)
bys patent: egen isrep2=mean(is_repeat_firm)
replace xtilep=mean_p10
duplicates drop patent, force
*keep if firmseq<=10000 & patnumpp1<=100
replace firmseq=1 if assignee==0
gen lnc=ln(firmseq)
gen lnp=ln(mean_age)
gen cor1=.
gen cor2=.
gen cor3=.
gen cor4=.

forvalues i=$iyear/$fyear{
corr f_cit5 lnc if appyear==`i'
replace cor1=`r(rho)' if appyear==`i'
corr f_cit5 f10f  if appyear==`i'
replace cor2=`r(rho)' if appyear==`i'
corr f_cit5 lnp  if appyear==`i'
replace cor3=`r(rho)' if appyear==`i'
corr f_cit5 xtilep  if appyear==`i'
replace cor4=`r(rho)' if appyear==`i'
}

local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive tsize cor1 cor2 cor3 cor4
collapse `vars', by(appyear)


twoway (connected cor1 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Log Firm Size")
graph export "$figfolder/pearce/cor_patview_cit_lfsize_notopcoded_$corp.pdf", replace

twoway (connected cor2 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Firm Decile")
graph export "$figfolder/pearce/cor_patview_cit_firmdec_notopcoded_$corp.pdf", replace

twoway (connected cor3 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Log Inv. Age")
graph export "$figfolder/pearce/cor_patview_cit_lage_notopcoded_$corp.pdf", replace

twoway (connected cor4 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Age Decile")
graph export "$figfolder/pearce/cor_patview_cit_agedec_notopcoded_$corp.pdf", replace

restore




preserve
keep if appyear>=$iyear & appyear<=$fyear
keep if tisze==2
*keep if assignee~=. & assignee~=0
*gen fwd_asg=F.count
bys patent: egen mean_age=mean(patnumpp1)
bys patent: egen mean_p10=mean(xtilep)
bys patent: egen isrep=mean(is_repeat_firm)
bys patent: egen isrep2=mean(is_repeat_firm)
replace xtilep=mean_p10
duplicates drop patent, force
bys appyear assignee: gen fcount=_N
gen lnf=ln(fcount)
*keep if firmseq<=10000 & patnumpp1<=100
replace firmseq=1 if assignee==0
gen lnc=ln(firmseq)
gen lnp=ln(mean_age)
gen cor1=.
gen cor2=.
gen cor3=.
gen cor4=.

forvalues i=$iyear/$fyear{
corr f_cit5 fcount if appyear==`i'
replace cor1=`r(rho)' if appyear==`i'
corr f_cit5 lnf  if appyear==`i'
replace cor2=`r(rho)' if appyear==`i'
corr f_cit5 lnp  if appyear==`i'
replace cor3=`r(rho)' if appyear==`i'
corr f_cit5 xtilep  if appyear==`i'
replace cor4=`r(rho)' if appyear==`i'
}

local vars is_repeat is_repeat_firm patnumpp1 m_ttb survive tsize cor1 cor2 cor3 cor4
collapse `vars', by(appyear)


twoway (connected cor1 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Firm Size")
graph export "$figfolder/pearce/cor_patview_cit_withiny_fc_notopcoded_$corp.pdf", replace

twoway (connected cor2 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Log Firm Size")
graph export "$figfolder/pearce/cor_patview_cit_withiny_lfc_notopcoded_$corp.pdf", replace

twoway (connected cor3 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Log Inv. Age")
graph export "$figfolder/pearce/cor_patview_cit_lage_notopcoded_$corp.pdf", replace

twoway (connected cor4 appyear if appyear>=$iyear & appyear<=$fyear), graphregion(color(white)) ytitle("Corr Cite & Age Decile")
graph export "$figfolder/pearce/cor_patview_cit_agedec_notopcoded_$corp.pdf", replace

restore








****PERSONAL DEVELOPMENT STUFF STUFF:


gen alone=0
replace alone=1 if tot==1
**if individual is ever alone
bys categ1: egen ever_alone=max(alone)
**numer of "ever alone" on patent + not ever alone on patent
bys patent: egen num_alone=total(ever_alone)
gen never_alone=tot-num_alone


gen patent_type1=type if ever_alone==1
bys patent: egen patent_type=mode(patent_type1)

gen exposed_class=.
replace exposed_class=other_type if tot==2 & alone==0


merge m:1 ipc2 using "$main/Caicedo_Pearce/data/sci_distance_long_ipc2_dec20.dta"

***generate class distance by the frequency to which an individual alone works in both classes and normalize from 0 to 1:


