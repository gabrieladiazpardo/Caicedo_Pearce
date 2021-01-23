***EVALUATE THE MAIN QUESTIONS FOR THE INSTRUMENT VARIABLE STRATEGY
***Date created: Sept 16, 2020




global main "/Users/JeremyPearce/Dropbox"


global data "$main/Caicedo_Pearce/data"
global wrkdata "$main/Caicedo_Pearce/data/wrkdata"
global raw "$main/Caicedo_Pearce/data/rawdata"
global output "$main/Caicedo_Pearce/data/output"


global results "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/slides/results"


use "$output/main_CP.dta",clear
duplicates drop patent, force
merge 1:1 patent using "$output/dates_CP.dta"
drop _m

*keep for the lags prior to policy

format appdate %td
format gdate %td
gen grant_lag=gdate-appdate

***ANNOUNCEMENT ON Dec 8, 1994; policy change on mdy(12,8,1995)
***https://en.wikipedia.org/wiki/Uruguay_Round_Agreements_Act#:~:text=4809%2C%20enacted%20December%208%2C%201994,World%20Trade%20Organization%20(WTO).
keep if appdate <mdy(9,27,1994)
bys uspto_class: egen class_lag=mean(grant_lag)

***mean lag ranges from 10-90 1.62yrs --> 2.31yrs (class-lvl)  1.04yrs --> 2.92yrs (patent-lvl)
merge 1:1 patent using "$wrkdata/nber_subcategory.dta"
drop _m
bys uspto_class: egen mode_sub=mode(subcat)
replace mode_sub=subcat if subcat~=.
egen subcat_g=group(mode_sub)


bys subcat_g: egen subcat_lag=mean(grant_lag)


preserve
duplicates drop uspto_class, force
keep uspto_class class_lag
save "$wrkdata/grant_lag_uspto.dta",replace
restore

preserve
duplicates drop subcat_g, force
keep subcat_g subcat_lag
save "$wrkdata/grant_lag_subcat.dta",replace
restore




***RESET

use "$output/main_CP.dta",clear
duplicates drop patent, force

***may lose dates--REVISIT
merge 1:1 patent using "$output/dates_CP.dta"
drop _m

*keep for the lags prior to policy

format appdate %td
format gdate %td
gen grant_lag=gdate-appdate

merge m:1 uspto_class using "$wrkdata/grant_lag_uspto.dta"
drop _m
merge 1:1 patent using "$wrkdata/nber_subcategory.dta"


drop _m
merge 1:1 patent using "$wrkdata/self_cit_cit_citing.dta"

drop _m
merge 1:1 patent using "$data/firmpercile_measure_by_patent.dta"

gen tf=.
replace tf=0 if f100<50
replace tf=1 if f100>=50 & f100<=99
replace tf=2 if f100==100
gen self_share=self_cit/flat_cit



preserve

collapse ttb_a, by(tf appyear)
gen tb=.
replace tb=ttb_a if appyear==1980
bys tf: egen mvtb=mean(tb)
replace ttb_a=ttb_a/mvtb


twowway (connected ttb_a appyeaer if tf==0) (connected ttb_a appyeaer if tf==1) (connected ttb_a appyeaer if tf==2)
restore

preserve
gen appmonth=month(appdate)
gen ttb_a=ln(self_cit+1)
collapse ttb_a, by(appmonth appyear)


gen month=ym(appyear,appmonth)
sort month
tsset month
sum month if month==ym(1995,6)
local late=`r(mean)'

sum month if month==ym(1994,12)
local early=`r(mean)'
sum ttb_a if month==`early'
replace ttb_a=ttb_a-`r(mean)'
sum month if month==ym(1993,1)
local min=`r(mean)'
sum month if month==ym(1998,1)
local max=`r(mean)'
tsset month
gen ttb3=(ttb+L.ttb+F.ttb)/3
format month %tm
#delimit ;
twoway (connected ttb3 month if appyear>=1993 & appyear<=1997), 
graphregion(color(white)) xtitle("Application Date") ytitle("3-yr MA Log Self Citations")
xline(`early') xline(`late') xlabel(`min'(12)`max');
graph export "$results/lncit3_by_event_1993_1998.pdf",replace;
restore



**RAW PLOTS
preserve
gen appmonth=month(appdate)
gen dow=dow(appdate)
gen dummy=1
keep if appdate~=.
collapse (sum) dummy (mean) appmonth appyear, by(appdate dow)
gen log_p=dummy
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log
sum ma_log
*replace ma_log=ma_log/`r(max)'
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Applications")
graph export "$results/totalapplication_freq_by_week_0920.pdf",replace

restore


***LOG APPLICATIONS
preserve
gen appmonth=month(appdate)
gen dow=dow(appdate)
gen dummy=1
keep if appdate~=.
collapse (sum) dummy (mean) appmonth appyear, by(appdate dow)
gen log_p=log(dummy)
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log
sum ma_log
replace ma_log=ma_log/`r(max)'
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Log Applications")
graph export "$results/log_application_freq_by_week.pdf",replace

restore




preserve
gen appmonth=month(appdate)
gen dow=dow(appdate)
gen dummy=1
keep if appdate~=.
collapse (sum) dummy (mean) class_lag appmonth appyear, by(appdate dow)

sum dummy,d
***relative frequency runs from 0 to 1
replace dummy=dummy/`r(max)'


***exposure measure runs from 0 to 1
sum class_lag,d
replace class_lag=class_lag/`r(max)'

gen log_p=class_lag*dummy
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log


*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Daily Avg Exposure x Activity")
graph export "$results/intensity_adjusted_applciations_0920.pdf",replace

restore






****SURROUNDING YEARS, BY MONTH

preserve
gen appmonth=month(appdate)
gen dow=dow(appdate)
gen dummy=1
keep if appdate~=.
collapse (sum) dummy (mean) class_lag, by(appyear appmonth)

sum dummy,d
***relative frequency runs from 0 to 1
replace dummy=dummy/`r(max)'


***exposure measure runs from 0 to 1
sum class_lag,d
replace class_lag=class_lag/`r(max)'

gen log_p=class_lag*dummy


*drop if dow==0 | dow==6
keep if appyear >=1993 &  appyear <=1997
gen ym=ym(appyear, appmonth)
format ym %tm
twoway (scatter log_p ym) (lfit log_p ym if ym>ym(1994,9) & ym<=ym(1995,6), lwidth(thick)) (lfit log_p ym if ym>ym(1995,6), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Month") ytitle("Daily Avg Exposure x Activity")
graph export "$results/intensity_adjusted_applciations_months_0920.pdf",replace

restore






gen appmonth=month(appdate)
gen ym=ym(appyear, appmonth)

sort ym

***THIS TAKES A WHILE
egen corr_gc = corr( grant_lag class_lag) , by(ym)



preserve
gen dummy=1
keep if appdate~=.
collapse (sum) dummy (mean) class_lag, by( appyear appdate ym)
sort ym
egen corr_gc = corr( dummy class_lag) , by(ym)

***

keep if appyear>=1993 & appyear<=1997
collapse corr_gc, by(ym)
format ym %tm
twoway (scatter corr_gc ym) (lfit corr_gc ym if ym>ym(1994,9) & ym<=ym(1995,6), lwidth(thick)) (lfit corr_gc ym if ym>ym(1995,6), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Month") ytitle("Corr Class Lag and Application Count")
graph export "$results/intensity_adjusted_applications_correls_0920.pdf",replace

restore




tabstat tsize if appyear<1995, by(subcat) stats(N mean)

tabstat tsize if appyear>1995, by(subcat) stats(N mean)


***FOR INDIVIDUAL LEVEL ANALYSIS
use "$output/main_CP.dta",clear

***may lose dates--REVISIT
merge m:1 patent using "$output/dates_CP.dta"
drop _m

*keep for the lags prior to policy

format appdate %td
format gdate %td
gen grant_lag=gdate-appdate

merge m:1 uspto_class using "$wrkdata/grant_lag_uspto.dta"
drop _m
merge m:1 patent using "$wrkdata/nber_subcategory.dta"



tabstat patnumpp1, by(appyear) stats(N mean)

gen appmonth=month(appdate)

preserve
collapse (mean) patnumpp1, by(patent appyear appmonth)
gen dummy=1
collapse (sum) dummy (mean) patnumpp1, by(appyear appmonth)

gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'
replace dummy=dummy/1000
#delimit ;
twoway (connected dummy ym, lwidth(thick) lcolor(blue) mcolor(blue) ) 
(connected patnumpp1 ym , lwidth(thick) lcolor(red) mcolor(red) yaxis(2)),   xlabel(`start'(12)`end')
legend(order(1 "Application Count (000's)" 2 "Avg Inventor 'Age'")) graphregion(color(white))  xtitle("Application Date") ytitle("Applications (Blue)") ytitle("Inventor 'Age' (Red)", axis(2));
graph export "$results/inventor_age_n_applications_0920.pdf",replace;

restore


**THE BIG THREE ALL TOGETHER
preserve
collapse (mean) patnumpp1, by(patent appyear appmonth)
gen dummy=1
collapse (sum) dummy (mean) patnumpp1 tsize, by(appyear appmonth)

gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'
replace dummy=dummy/1000
#delimit ;
twoway (connected dummy ym, lwidth(thick) lcolor(blue) mcolor(blue) ) 
(connected patnumpp1 ym , lwidth(thick) lcolor(red) mcolor(red) yaxis(2)),   xlabel(`start'(12)`end')
legend(order(1 "Application Count (000's)" 2 "Avg Inventor 'Age'")) graphregion(color(white))  xtitle("Application Date") ytitle("Applications (Blue)") ytitle("Inventor 'Age' (Red)", axis(2));
graph export "$results/inventor_age_n_applications_0920.pdf",replace;

restore


***COULD INVENTOR AGE BE COMPOSITIONAL?


set matsize 11000
preserve
collapse (mean) patnumpp1 tsize, by(patent appyear appmonth uspto_class)
gen dummy=1
reg patnumpp1 i.uspto_class i.tsize i.appmonth
predict p1
replace patnumpp1=patnumpp1-p1

collapse (sum) dummy (mean) patnumpp1, by(appyear appmonth)

gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'
replace dummy=dummy/1000
#delimit ;
twoway (connected dummy ym, lwidth(thick) lcolor(blue) mcolor(blue) ) 
(connected patnumpp1 ym , lwidth(thick) lcolor(red) mcolor(red) yaxis(2)),  xlabel(`start'(12)`end')
legend(order(1 "Application Count (000's)" 2 "Avg Inventor 'Age'")) graphregion(color(white))  xtitle("Application Date") ytitle("Applications (Blue)") ytitle("Inventor Adjusted 'Age' (Red)", axis(2));
graph export "$results/inventor_classadj_age_n_applications_0920.pdf",replace

restore




***month adjustment
preserve
collapse (mean) patnumpp1 tsize, by(patent appyear appmonth uspto_class)
gen dummy=1
**monthly cycles too
reg patnumpp1 i.uspto_class i.tsize i.appmonth
predict p1
replace patnumpp1=patnumpp1-p1

collapse (sum) dummy (mean) patnumpp1, by(appyear appmonth)
reg dummy i.appmonth
predict pred
replace dummy=dummy-pred


gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'
*replace dummy=dummy/1000
#delimit ;
twoway (connected dummy ym, lwidth(thick) lcolor(blue) mcolor(blue) ) 
(connected patnumpp1 ym , lwidth(thick) lcolor(red) mcolor(red) yaxis(2)),  xlabel(`start'(12)`end')
legend(order(1 "Applications, month-adjusted" 2 "Avg Inventor 'Age'")) graphregion(color(white))  xtitle("Application Date") ytitle("Applications (Blue)") ytitle("Inventor Adjusted 'Age' (Red)", axis(2));
graph export "$results/inventor_classadj_age_n_applications_monthadj_0920.pdf",replace

restore




***month adjustment,tsize
preserve
collapse (mean) patnumpp1 tsize, by(patent appyear appmonth uspto_class)
gen dummy=1
**monthly cycles too
reg tsize i.uspto_class 
predict p1
sum tsize
replace patnumpp1=tsize-p1+`r(mean)'

collapse (sum) dummy (mean) patnumpp1, by(appyear appmonth)
reg dummy i.appmonth
predict pred
replace dummy=dummy-pred
drop pred

reg patnumpp1 i.appmonth
predict pred
sum patnumpp1
replace patnumpp1=patnumpp1-pred+`r(mean)'


gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'
replace dummy=dummy/1000
tsset ym
gen dummy1=(dummy+L.dummy+L2.dummy)/3
gen ts1=(patnumpp1+L.patnumpp1+L2.patnumpp1)/3

#delimit ;
twoway (connected dummy1 ym, lwidth(thick) lcolor(blue) mcolor(blue) ) 
(connected ts1 ym , lwidth(thick) lcolor(red) mcolor(red) yaxis(2)),  xlabel(`start'(12)`end')
legend(order(1 "Applications (000's)" 2 "Adj. Team Size")) graphregion(color(white))  xtitle("Application Date, 3-month moving average") ytitle("Applications (Blue)") ytitle("Team Size (Red)", axis(2));
graph export "$results/inventor_classadj_tsize_n_applications_monthadj_0920.pdf",replace

restore


preserve
collapse (mean) patnumpp1 tsize, by(patent appyear appmonth uspto_class)
gen dummy=1

reg tsize i.uspto_class
predict p1
replace patnumpp1=tsize-p1

collapse (sum) dummy (mean) tsize patnumpp1, by(appyear appmonth)


gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'

#delimit ;
twoway (connected tsize ym, lwidth(thick) lcolor(blue) mcolor(blue) ) 
(connected patnumpp1 ym , lwidth(thick) lcolor(red) mcolor(red) yaxis(2)), 
legend(order(1 "Team Size" 2 "Class Adj. Team Size")) graphregion(color(white))  
xtitle("Application Date") ytitle("Team Size (Blue)") xlabel(`start'(12)`end')
 ytitle("Class Adj. Team Size (Red)", axis(2));
graph export "$results/teamsize_adj_unadj_0920.pdf",replace;

restore








***SPLIT BY EXPOSED/UNEXPOSED
preserve
gen ln_cit=ln(exp_cit)
collapse (mean) patnumpp1 ln_cit tsize class_lag, by(patent appyear appmonth uspto_class)

gen exposed=.
***TWO YEARS OR LESS
sum class_lag,d
replace exposed=0 if class_lag<`r(p25)'
replace exposed=1 if class_lag<`r(p50)' & class_lag>=`r(p25)'
replace exposed=2 if class_lag<`r(p75)' & class_lag>=`r(p50)'
replace exposed=3 if class_lag>`r(p75)' & class_lag~=.

gen dummy=1


collapse (sum) dummy (mean) ln_cit tsize patnumpp1, by(appyear appmonth exposed)


gen ym=ym(appyear,appmonth)
keep if appyear>=1993 & ym<=ym(1998,1)
format ym %tm
sum ym if ym==ym(1993,1)
local start=`r(mean)'
sum ym if ym==ym(1998,1)
local end=`r(mean)'



sum ym if ym==ym(1995,6)
local line=`r(mean)'
#delimit ;
twoway (connected ln_cit ym if exposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected ln_cit ym if exposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected ln_cit ym if exposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected ln_cit ym if exposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Log Citations") xlabel(`start'(12)`end') xline(`line');
graph export "$results/teamsize_unadj_exposed_unexp.pdf",replace;

restore





preserve
collapse (mean) patnumpp1 tsize class_lag, by(patent appyear appmonth uspto_class)

gen exposed=.
***TWO YEARS OR LESS
sum class_lag,d
replace exposed=0 if class_lag<`r(p25)'
replace exposed=1 if class_lag<`r(p50)' & class_lag>=`r(p25)'
replace exposed=2 if class_lag<`r(p75)' & class_lag>=`r(p50)'
replace exposed=3 if class_lag>`r(p75)' & class_lag~=.

gen dummy=1
keep if exposed~=.

collapse (sum) dummy (mean) tsize patnumpp1, by(appyear appmonth exposed)



gen ym=ym(appyear,appmonth)


replace tsize=ln(tsize)

**renormalize to be the same at start of sample
gen tss=.
replace tss=tsize if appyear==1995 & appmonth==3
bys exposed: egen min_ts=min(tss)
replace tsize=tsize-min_ts

* & ym<=ym(1998,1)

sort exposed ym
keep if appyear==1995
format ym %tm
sum ym if ym==ym(1995,1)
local start=`r(mean)'
sum ym if ym==ym(1995,12)
local end=`r(mean)'
sum ym if ym==ym(1995,6)
local line=`r(mean)'


#delimit ;
twoway (connected tsize ym if exposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected tsize ym if exposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected tsize ym if exposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected tsize ym if exposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Log Team Size") xlabel(`start'(3)`end') xline(`line');
graph export "$results/lnteamsize_unadj_exposed_unexp_1years.pdf",replace;

restore


******BY DAY
preserve
collapse (mean) patnumpp1 tsize class_lag, by(patent appyear appmonth uspto_class appdate)

gen exposed=.
***TWO YEARS OR LESS
sum class_lag,d
replace exposed=0 if class_lag<`r(p25)'
replace exposed=1 if class_lag<`r(p50)' & class_lag>=`r(p25)'
replace exposed=2 if class_lag<`r(p75)' & class_lag>=`r(p50)'
replace exposed=3 if class_lag>`r(p75)' & class_lag~=.

gen dummy=1
keep if exposed~=.

collapse (sum) dummy (mean) tsize patnumpp1, by(appdate exposed)





*replace tsize=ln(tsize)
**renormalize to be the same at start of sample
keep if appdate>=mdy(5,10,1995) & appdate<=mdy(7,15,1995)
sort exposed appdate
xtset exposed appdate
rename dummy log_p

drop tsize
rename log_p tsize
sum appdate if appdate==mdy(6,7,1995)
local line=`r(mean)'
drop if appdate==.
#delimit ;
twoway (connected tsize appdate if exposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected tsize appdate if exposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected tsize appdate if exposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected tsize appdate if exposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Patent Count") xline(`line');
graph export "$results/count_unadj_exposed_noma_1month.pdf",replace;
#delimit cr
rename tsize log_p

gen ma_count=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
rename ma_count tsize

sort exposed appdate
#delimit ;
twoway (connected tsize appdate if exposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected tsize appdate if exposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected tsize appdate if exposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected tsize appdate if exposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Patent Count") xline(`line');
graph export "$results/count_unadj_exposed_ma_1month.pdf",replace;

restore



preserve
collapse (mean) patnumpp1 tsize class_lag, by(patent appyear appmonth uspto_class appdate)

gen exposed=.
***TWO YEARS OR LESS
sum class_lag,d
replace exposed=0 if class_lag<`r(p25)'
replace exposed=1 if class_lag<`r(p50)' & class_lag>=`r(p25)'
replace exposed=2 if class_lag<`r(p75)' & class_lag>=`r(p50)'
replace exposed=3 if class_lag>`r(p75)' & class_lag~=.

gen dummy=1
keep if exposed~=.

collapse (sum) dummy (mean) tsize patnumpp1, by(appdate exposed)





*replace tsize=ln(tsize)
**renormalize to be the same at start of sample
keep if appdate>=mdy(5,10,1995) & appdate<=mdy(7,15,1995)
sort exposed appdate
xtset exposed appdate

sum appdate if appdate==mdy(6,7,1995)
local line=`r(mean)'
drop if appdate==.
#delimit ;
twoway (connected tsize appdate if exposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected tsize appdate if exposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected tsize appdate if exposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected tsize appdate if exposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Team Size") xline(`line');
graph export "$results/event_1995/teamsize_unadj_exposed_noma_1month.pdf",replace;
#delimit cr
rename tsize log_p

gen ma_count=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
rename ma_count tsize

sort exposed appdate
#delimit ;
twoway (connected tsize appdate if exposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected tsize appdate if exposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected tsize appdate if exposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected tsize appdate if exposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Team Size") xline(`line');
graph export "$results/event_1995/teamsize_unadj_exposed_ma_1month.pdf",replace;

restore

tabstat ttb, by(appyear) stats(N mean)


preserve
keep if class_ag>25.14 & class_ag~=.
gen appmonth=month(appdate)
collapse (sum) dummy (mean) appmonth appyear, by(appdate dow)
gen log_p=log(dummy)
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Log Applications")
graph export "$graphs/policy_ins_bymweek_log_exposed.pdf",replace

restore

preserve
keep if class_ag<21.2 & class_ag~=.
gen appmonth=month(appdate)
collapse (sum) dummy (mean) appmonth appyear, by(appdate dow)
gen log_p=log(dummy)
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Log Applications") ylabel(4(.5)6)
graph export "$graphs/policy_ins_bymweek_log_unexposed.pdf",replace

restore



preserve
keep if class_ag<21.2 & class_ag~=.
gen appmonth=month(appdate)
collapse (sum) dummy (mean) appmonth appyear breadth2nd, by(appdate dow)
gen log_p=breadth2nd
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Breadth") ylabel(.2(.05).4)
graph export "$graphs/policy_ins_bymweek_breadth_unexposed.pdf",replace

restore


preserve
keep if class_ag>25.14
gen appmonth=month(appdate)
collapse (sum) dummy (mean) appmonth appyear breadth2nd, by(appdate dow)
gen log_p=breadth2nd
tsset appdate
gen ma_log=(L1.log_p+L2.log_p+L3.log_p+L4.log_p+L5.log_p+L6.log_p+L7.log_p)/7
replace ma_log=f.ma_log
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Breadth")
graph export "$graphs/policy_ins_bymweek_breadth_exposed.pdf",replace

restore





preserve
keep if class_ag<21.2 & class_ag~=.
gen appmonth=month(appdate)
replace teampnum=0 if teampnum==1 & teampnum~=.
replace teampnum=1 if teampnum>1 & teampnum~=.
collapse (sum) dummy (mean) appmonth appyear breadth2nd teampnum, by(appdate dow)
gen log_p=breadth2nd
tsset appdate
gen ma_log=teampnum
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Pr Repeat Team") ylabel(.2(.1).6)
graph export "$graphs/policy_ins_bymweek_tpnp_unexposed.pdf",replace

restore


preserve
keep if class_ag>25.14 & class_ag~=.
gen appmonth=month(appdate)
replace teampnum=0 if teampnum==1 & teampnum~=.
replace teampnum=1 if teampnum>1 & teampnum~=.
collapse (sum) dummy (mean) appmonth appyear breadth2nd teampnum, by(appdate dow)
gen log_p=breadth2nd
tsset appdate
gen ma_log=teampnum
*drop if dow==0 | dow==6
drop if appdate<mdy(1,8,1995)
keep if (appmonth>=3 & appmonth<=10) & appyear==1995
keep if dow==4

twoway (scatter ma_log appdate) (lfit ma_log appdate if appdate<mdy(6,8,1995), lwidth(thick)) (lfit ma_log appdate if appdate>mdy(6,8,1995), lwidth(thick)), legend(off) graphregion(color(white)) xtitle("Application Date") ytitle("Pr Repeat Team") ylabel(.2(.1).6)
graph export "$graphs/policy_ins_bymweek_tpnp_exposed.pdf",replace

restore




***NOW WE HAVE MEASURE OF EXPOSURE BY CLASS, firm, and individual

ivregress 2sls resid_cit (resbreadth=expo_shockadj) if avgcbreada>.33 & date<mdy(6,8,1995)





***FOR INDIVIDUAL LEVEL ANALYSIS
use "$output/main_CP.dta",clear

***may lose dates--REVISIT
merge m:1 patent using "$output/dates_CP.dta"
drop _m

*keep for the lags prior to policy

format appdate %td
format gdate %td
gen grant_lag=gdate-appdate

merge m:1 uspto_class using "$wrkdata/grant_lag_uspto.dta"
drop _m
merge m:1 patent using "$wrkdata/nber_subcategory.dta"


***LOOK AT INDIVIDUALS WHO ARE EXPOSED:
gen ilag=.
replace ilag=grant_lag if appyear<1995
bys categ1: egen prelag=mean(ilag)
gen iexposed=.
sum prelag,d
replace iexposed=0 if prelag<`r(p25)'
replace iexposed=1 if prelag<`r(p50)' & prelag>=`r(p25)'
replace iexposed=2 if prelag<`r(p75)' & prelag>=`r(p50)'
replace iexposed=3 if prelag>`r(p75)' & prelag~=.

xtset categ1 patnumpp1
gen ttb=appdate-L.appdate


gen appmonth=month(appdate)

gen event_month=0
replace event_month=1 if appdate<mdy(6,8,1995) & appyear==1995 & (appmonth==5 | appmonth==6)


bys patent: gen tot=_N

reghdfe invh_cit event_month##i.iexposed, absorb(g_ipc categ1 appyear)
reghdfe invh_cit event_month##i.iexposed i.tot, absorb(g_ipc categ1 appyear)
gen surv_empt=survive
replace surv_empt=0 if surv_empt==.
reghdfe surv_empt event_month##i.iexposed i.tot, absorb(g_ipc categ1 appyear)

reghdfe survive event_month##i.iexposed i.tot, absorb(g_ipc categ1 appyear)



preserve
duplicates drop patent, force
reghdfe survive event_month##i.iexposed, absorb(g_ipc appyear)
reghdfe survive event_month##i.iexposed i.tot, absorb(g_ipc appyear)
reghdfe invh_cit event_month##i.iexposed, absorb(g_ipc appyear)
reghdfe invh_cit event_month##i.iexposed i.tot, absorb(g_ipc appyear)

restore


preserve
keep if appyear>=1996 & appyear<=2000
collapse invh_cit, by(patnumpp1)
keep if patnumpp1<=100
twoway connected invh_cit patnumpp1, graphregion(color(white)) ytitle("Log Citations")
graph export "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/slides/results/event_1995/invh_cit_age.pdf"
restore


preserve
keep if appyear>=1996 & appyear<=2000
collapse invh_cit ttb, by(patnumpp1)
keep if patnumpp1<=40
gen cit_ttb=invh_cit/ttb
twoway connected cit_ttb patnumpp1, graphregion(color(white)) ytitle("Time-adjusted Log Citations") 
graph export "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/slides/results/event_1995/invh_cit_ttb_age.pdf",replace
restore




preserve
keep if appyear>=1996 & appyear<=2000
collapse invh_cit ttb, by(patnumpp1)
keep if patnumpp1<=40
gen cit_ttb=invh_cit/ttb
twoway connected cit_ttb patnumpp1, graphregion(color(white)) ytitle("Time-adjusted Log Citations") 
graph export "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/slides/results/event_1995/invh_cit_ttb_age.pdf",replace
restore


preserve
gen early=.
replace early=1 if appyear>=1980 & appyear<1995
replace early=2 if appyear==1995
replace early=3 if appyear>1995 & appyear<2005
collapse invh_cit ttb tot, by(patnumpp1 early)
keep if patnumpp1<=25
gen cit_ttb=invh_cit/ttb
gen cit_tot=invh_cit/tot
#delimit ;
twoway (connected cit_ttb patnumpp1 if early==1, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected cit_ttb patnumpp1 if early==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected cit_ttb patnumpp1 if early==3, lwidth(thick) lcolor(purple) mcolor(purple) ) , 
legend(order(1 "Prior to 1995" 2 "1995" 3 "Post 1995")) graphregion(color(white))  
ytitle("Time-adjusted Log Citations");
graph export "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/slides/results/event_1995/invh_cit_ttb_age_group.pdf",replace;
#delimit ;
twoway (connected cit_tot patnumpp1 if early==1, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected cit_tot patnumpp1 if early==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected cit_tot patnumpp1 if early==3, lwidth(thick) lcolor(purple) mcolor(purple) ) , 
legend(order(1 "Prior to 1995" 2 "1995" 3 "Post 1995")) graphregion(color(white))  
ytitle("Team-adjusted Log Citations");
graph export "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/slides/results/event_1995/invh_cit_tot_age_group.pdf",replace;
restore


preserve
bys patent: egen mttb=mean(ttb)
bys patent: egen mlag=mean(class_lag)
bys patent: egen mtsize=mean(tsize)
bys patent: egen mpat=mean(patnumpp1)
bys patent: egen msurvive=mean(survive)


collapse (mean) mpat mtsize mlag mttb msurvive, by(appyear appmonth iexposed)

gen ym=ym(appyear,appmonth)

rename m* *
format ym %tm
sum ym if ym==ym(1995,6)
local xline1=`r(mean)'
sum ym if ym==ym(1994,12)
local xline2=`r(mean)'
keep if appyear>=1993 & appyear<=1997

#delimit ;
twoway (connected survive ym if iexposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected survive ym if iexposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected survive ym if iexposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected survive ym if iexposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Forward Survival") xline(`xline1') xline(`xline2');
graph export "$results/survival_personalexposure_ym9397.pdf", replace;



#delimit ;
twoway (connected tsize ym if iexposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected tsize ym if iexposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected tsize ym if iexposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected tsize ym if iexposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Team Size") xline(`xline1') xline(`xline2');
graph export "$results/teamsize_personalexposure_ym9397.pdf", replace;



#delimit ;
twoway (connected pat ym if iexposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected pat ym if iexposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected pat ym if iexposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected pat ym if iexposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Inventor age") xline(`xline1') xline(`xline2');
graph export "$results/invage_personalexposure_ym9397.pdf", replace;


#delimit ;
twoway (connected ttb ym if iexposed==3, lwidth(thick) lcolor(blue) mcolor(blue) ) 
 (connected ttb ym if iexposed==2, lwidth(thick) lcolor(green) mcolor(green) ) 
 (connected ttb ym if iexposed==1, lwidth(thick) lcolor(purple) mcolor(purple) ) 
(connected ttb ym if iexposed==0, lwidth(thick) lcolor(red) mcolor(red)), 
legend(order(1 "Most Exposed" 2 "More Exposed" 3 "Less Exposed"  4 "Least Exposed")) graphregion(color(white))  
xtitle("Application Date") ytitle("Time to patent") xline(`xline1') xline(`xline2');
graph export "$results/ttb_personalexposure_ym9397.pdf", replace;




gen exposed=.
***TWO YEARS OR LESS
sum class_lag,d
replace exposed=0 if class_lag<`r(p25)'
replace exposed=1 if class_lag<`r(p50)' & class_lag>=`r(p25)'
replace exposed=2 if class_lag<`r(p75)' & class_lag>=`r(p50)'
replace exposed=3 if class_lag>`r(p75)' & class_lag~=.






