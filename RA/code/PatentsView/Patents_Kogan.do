
**Saving options
global save_fig   1 //0 // 

graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2010 //final year of plots

*in surv folder in reports
global figfolder="$main/RA/reports/Fall of Generalists/Second Version/Citations/figures"
global tabfolder="$main/RA/reports/Fall of Generalists/Second Version/Citations/tables"

import delimited "$datasets/patents_xi.csv", stringcols(1) clear 

rename patnum patent 
label var patent "Patent ID"
label var fdate "Filling date of patent"
label var idate "Issue (grant) date of patent"
label var pdate "Publication date of patent"
label var permno "CRSP permno"
label var class "technology class"
label var subclass "technology subclass"
label var ncites "number of citations"
label var xi "value (millions of dollars (nominal)"

*---app Date / filling date
split fdate, parse(/)		
destring fdate1 fdate2 fdate3, replace
gen appdate=mdy(fdate1, fdate2, fdate3)
format appdate %td	
rename (fdate1 fdate2 fdate3) (appmonth appday appyear)

*---issue Date / grant date
split idate, parse(/)		
destring idate1 idate2 idate3, replace
gen gdate=mdy(idate1, idate2, idate3)
format gdate %td	
rename (idate1 idate2 idate3) (gmonth gday gyear)

drop pdate fdate idate

order patent app* g*

save "$datasets/kogan_patents.dta",replace

***********************************
*		Number of Cites(appyr)
*
************************************

use "$datasets/kogan_patents.dta",clear
collapse (mean) ncites,by(appyear)
keep if appyear>=1975 
keep if appyear<=2010


twoway (connected ncites appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application/Filling Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(Number of Citations ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/ncites_kogan_appyr.pdf", replace as(pdf)
}


***********************************
*		Number of Cites(gyr)
*
************************************

use "$datasets/kogan_patents.dta",clear
collapse (mean) ncites,by(gyear)
keep if gyear>=1975 
keep if gyear<=2010


twoway (connected ncites gyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Grant/Issue Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(Number of Citations ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/ncites_kogan_gyr.pdf", replace as(pdf)
}

************************************
*		Number of Patents (Appyear)
*
***********************************

use "$datasets/kogan_patents.dta",clear
egen pat=group(patent)

collapse (mean) pat,by(appyear)
keep if appyear>=1975 
keep if appyear<=2010

replace pat=pat/10000
twoway (connected pat appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application/Filling Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(Number of Patents (by 10,000) ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/npats_kogan_appyr.pdf", replace as(pdf)
}


************************************
*		Number of Patents (gyear)
*
***********************************

use "$datasets/kogan_patents.dta",clear
egen pat=group(patent)

collapse (mean) pat,by(gyear)
keep if gyear>=1975 
keep if gyear<=2010

replace pat=pat/10000
twoway (connected pat gyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Grant/Issue Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle(Number of Patents (by 10,000) ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/npats_kogan_gyr.pdf", replace as(pdf)
}


*********************************
*Patent Value (appyear)
*
************************************

use "$datasets/kogan_patents.dta",clear

collapse (mean) xi ,by(appyear)
keep if appyear>=1975 
keep if appyear<=2010

twoway (connected xi appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application/Filling Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Patent Stock Value" ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/value_pats_kogan_appyr.pdf", replace as(pdf)
}

*********************************
*Patent Value (gyear)
*
************************************

use "$datasets/kogan_patents.dta",clear

collapse (mean) xi ,by(gyear)
keep if gyear>=1975 
keep if gyear<=2010

twoway (connected xi gyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Grant/Issue Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Patent Stock Value" ,height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/value_pats_kogan_gyr.pdf", replace as(pdf)
}


******************************
*		Temporary data 
********************************

use "$datasets/kogan_patents.dta",clear
keep patent appyear gyear
compress

duplicates tag patent, gen(dp)
duplicates drop patent, force

drop dp

save"$datasets/tmp_dates_kogan.dta", replace



*****************************
*		Cites				*
*							*
*****************************

import delimited "$datasets/cites.csv", clear  stringcols(_all)

rename citing patent

merge m:1 patent using "$datasets/tmp_dates_kogan.dta"
drop _m
rename appyear citing_appyear
rename gyear citing_gyear

rename patent citing
rename cited patent

merge m:1 patent using "$datasets/tmp_dates_kogan.dta"
drop _m

rename patent cited
rename appyear cited_appyear
rename gyear cited_gyear

drop if citing=="" 
drop if cited==""

gen cit_pat_age=citing_appyear-cited_appyear
replace cit_pat_age=0 if cit_pat_age<0

*Para cada patente citada en cada año de vejez, cuantas veces fue citada maximo
bys cited cit_pat_age:  gen cit_yr=_N

*--Numero de citas que hace en total backward
bys cited : gen f_cit=_N

*media de lag cuando es citada
bys cited: egen mean_lag_fcit=mean(cit_pat_age)

*Dejar Panel nivel de citada, cada posible lag (0,114)
duplicates drop cited cit_pat_age, force

*Dejar sólo id de la patente citada y el numero maximo de citaciciones recibidas por cada lag 
keep cited cit_pat_age cit_yr f_cit mean_lag_fcit 

*total cites made cumulative; needs to match with b_cit
bys cited: egen f_cit_cum=total(cit_yr)

gen coinc=1 if f_cit==f_cit_cum
tab coinc, m // all match
drop coinc

bys cited: egen f_cit_cum_unidentified=total(cit_yr) if cit_pat_age==.
bys cited: egen f_cit_cum_unident=max(f_cit_cum_unidentified)
drop f_cit_cum_unidentified

replace f_cit_cum_unident=0 if f_cit_cum_unident==.

*percentage of unidentified b_cit
gen share_unident=f_cit_cum_unident/f_cit*100
compress

drop f_cit_cum share_unident

keep cited cit_pat_age cit_yr f_cit mean_lag_fcit

compress

save "$datasets/f_cit_panel_pat_age_kogan.dta", replace

use "$datasets/f_cit_panel_pat_age_kogan.dta",clear

keep cited cit_pat_age cit_yr f_cit 

replace cit_pat_age=5000 if cit_pat_age==.

rename cited patent 

reshape wide cit_yr, i(patent) j(cit_pat_age)

*generate rowtotal // needs to match with bcit
egen cum_f_cit=rowtotal(cit_yr*)

*verify match
br f_cit cum_f_cit //match.
 
*merge application date 
merge 1:1 patent using "$datasets/tmp_dates_kogan.dta"
drop _m 
*save data
compress
save "$datasets/f_cit_by_pat_age_wide_kogan.dta", replace


*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen f_cit3= rowtotal( cit_yr0 cit_yr1 cit_yr2 cit_yr3)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen f_cit5= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 8. 
egen f_cit8= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5 cit_yr6 cit_yr7 cit_yr8)

**********************
* Forward citations
**********************

rename cit_yr5000 f_cit_unident

egen f_cit_ident=rowtotal(cit_yr*)

*verify
br f_cit_unident f_cit_ident f_cit


label var f_cit3 "3-year Forward Citations"
label var f_cit5 "5-year Forward Citations"
label var f_cit8 "8-year Forward Citations"
label var f_cit_unident "Forward Citations with unidentified application year"
label var f_cit_ident "Forward Citations with identified application year"
label var f_cit "Forward Citations (Total Citations Received)"


keep patent f_cit_unident f_cit_ident f_cit f_cit3 f_cit5 f_cit8

order patent f_cit_unident f_cit_ident f_cit f_cit3 f_cit5 f_cit8

replace f_cit_unident=0 if f_cit_unident==.

compress

save "$datasets/f_cit_patent_kogan.dta", replace




*****************************
*		Cites				*
*							*
*****************************

import delimited "$datasets/cites.csv", clear  stringcols(_all)

rename citing patent

merge m:1 patent using "$datasets/tmp_dates_kogan.dta"
drop _m
rename appyear citing_appyear
rename gyear citing_gyear

rename patent citing
rename cited patent

merge m:1 patent using "$datasets/tmp_dates_kogan.dta"
drop _m

rename patent cited
rename appyear cited_appyear
rename gyear cited_gyear

drop if citing=="" 
drop if cited==""

gen cit_pat_age=citing_appyear-cited_appyear
replace cit_pat_age=0 if cit_pat_age<0


*Para cada patente citada en cada año de vejez, cuantas veces fue citada maximo
bys citing cit_pat_age:  gen cit_yr=_N

*--Numero de citas que hace en total backward
bys citing : gen b_cit=_N

*--Mean of the lag for all citations
bys citing : egen mean_pat_age=mean(cit_pat_age)

*Dejar Panel nivel de citada, cada posible lag (0,114)
duplicates drop citing cit_pat_age, force

*Dejar sólo id de la patente citada y el numero maximo de citaciciones recibidas por cada lag 
keep citing cit_pat_age cit_yr b_cit mean_pat_age

*total cites made cumulative; needs to match with b_cit
bys citing: egen b_cit_cum=total(cit_yr)

gen coinc=1 if b_cit==b_cit_cum
tab coinc, m // all match
drop coinc

*total cites made

bys citing: egen b_cit_cum_unidentified=total(cit_yr) if cit_pat_age==.
bys citing: egen b_cit_cum_unident=max(b_cit_cum_unidentified)
drop b_cit_cum_unidentified


replace b_cit_cum_unident=0 if b_cit_cum_unident==.

*percentage of unidentified b_cit
gen share_unident=b_cit_cum_unident/b_cit*100

compress
drop b_cit_cum


keep citing cit_pat_age cit_yr b_cit mean_pat_age share_unident

save "$datasets/b_cit_panel_pat_age_kogan.dta", replace

use "$datasets/b_cit_panel_pat_age_kogan.dta", clear

keep citing cit_pat_age cit_yr b_cit 

replace cit_pat_age=5000 if cit_pat_age==.

rename citing patent 

reshape wide cit_yr, i(patent) j(cit_pat_age)

*generate rowtotal // needs to match with bcit
egen cum_b_cit=rowtotal(cit_yr*)

*verify match
br b_cit cum_b_cit //match.
 
*merge application date 
merge 1:1 patent using "$datasets/tmp_dates_kogan.dta"
drop if _m==2
drop _m 

*save data
compress

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen b_cit3= rowtotal( cit_yr0 cit_yr1 cit_yr2 cit_yr3)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen b_cit5= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 8. 
egen b_cit8= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5 cit_yr6 cit_yr7 cit_yr8)

rename cit_yr5000 b_cit_unident
egen b_cit_ident=rowtotal(cit_yr*)
replace b_cit_unident=0 if b_cit_unident==.
replace b_cit_ident=0 if b_cit_ident==.

br b_cit_unident b_cit_ident b_cit
gen share_unident=b_cit_unident/b_cit*100

br b_cit_unident b_cit_ident b_cit share_unident

label var b_cit3 "3-year Backward Citations"
label var b_cit5 "5-year Backward Citations"
label var b_cit8 "8-year Backward Citations"
label var b_cit_unident "Backward Citations with unidentified application year"
label var b_cit_ident "Backward Citations with identified application year"
label var b_cit "Backward Citations (Total Citations Made)"
label var share_unident "Share of backward Citations with unidentified application year"

keep patent b_cit_unident b_cit_ident b_cit b_cit3 b_cit5 b_cit8 share_unident appyear

order patent appyear b_cit_unident b_cit_ident b_cit share_unident b_cit3 b_cit5 b_cit8

replace b_cit_unident=0 if b_cit_unident==.

compress

save "$datasets/b_cit_patent_kogan.dta", replace


