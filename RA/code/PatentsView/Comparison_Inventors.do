
*globals
global figfolder="$main/RA/output/figfolder/comparison"
global tabfolder="$main/RA/output/tabfolder/comparison"

**Other options
global iyear 1975 //initial year of plots
global fyear 2010 //final year of plots

graph set window fontface "Garamond"
global size_font large // medlarge //

global save_str _allpat

**Saving options
global save_fig 1 //  0 //




*Open PV data
use "$datasets/Patentsview_Main.dta", clear

keep patent patent appyear type_pat inventor_id invseq categ1 tsize

tab invseq

*rename for PV
findname, local(vars)
local no = "patent invseq"
local list: list vars - no

foreach y of local list {
rename `y' `y'_pv
}

gen d_pv=1
label var d_pv "Patent Reported on PatentsView"


*fix invseq (key)
sort patent invseq
bys patent : gen invseq2=_n
replace invseq2=invseq2-1

rename invseq or_invseq_pv
rename invseq2 invseq


*Make years comparable between the two datasets
drop if appyear>2010

tempfile pv_inventor

save "`pv_inventor'", replace


*open harvard data
use "$datasets/Harvard_Dataset.dta", clear

keep patent appyear invseq categ1 tsize

*fix invseq (key)
sort patent invseq
bys patent : gen invseq2=_n
replace invseq2=invseq2-1

rename invseq or_invseq_h
rename invseq2 invseq


*rename for PV
findname, local(vars)
local no = "patent invseq"
local list: list vars - no

foreach y of local list {
rename `y' `y'_h
}

gen d_h=1

***********************************
*		Merge Data PV + H
*
***********************************

merge 1:1 patent invseq using "`pv_inventor'", gen(merge)

label var invseq "Inventor Sequence (Harmonized)"

replace d_h=0 if d_h==.
label var d_h "Patent Available in Harvard"

replace d_pv=0 if d_pv==.
label var d_pv "Patent Available in PatentsView"

label var or_invseq_h "Original Inventor Sequence Harvard"
label var or_invseq_pv "Original Inventor Sequence PatentsView"

*Patents that report a different number of inventors in both datasets
gen dtsize0=1 if tsize_pv!=tsize_h & tsize_pv!=. & tsize_h!=.
bys patent : egen dif_tsize=max(dtsize0)
label var dif_tsize "Patents that Report a Different Number of Inventors in both datasets"

drop dtsize0 

*source of data
rename merge source
label define vv 1"Only in Harvard" 2"Only in PatentsView" 3"Both Datasets"
label values source vv
label var source "Source"

unique patent if dif_tsize==1

/* 2194 different patents report diferent number of inventors in patentsview or harvard  */

*Generate Harmonized Appyear 
gen appyear=.
replace appyear=appyear_pv if source==2 | source==3
replace appyear=appyear_h if source==1

label var appyear "Harmonized Appyear"
label var appyear_h "Original Appyear Harvard"
label var appyear_pv "Original Appyear PatentsView"


order patent invseq appyear categ1_h categ1_pv inventor_id_pv tsize_pv tsize_h dif_tsize source d_h d_pv or_invseq_h_h or_invseq_pv type_pat_pv appyear_h appyear_pv

sort patent invseq


*Differences in the Inventors Identification

*Inventors only Identified in Harvard

*1) From the sample of patents processed from harvard and uspto ALL have info. on inventors:


*1) Only in Harvard

unique patent if source==1 // 263481; 458,922 inventors


*2) Only in PatentsView

unique patent if source==2  // 130,1674; 3,078,255 inventors




***********************************
*	Unidentified Inventors
*
**********************************

*Patents that report different number of inventors (USPTO vs Harvard)

*--Dummy for missing by each dataset
	gen dminv_h=(categ1_h==.)
	gen dminv_pv=(categ1_pv==.)
	
*Dummy if PV Assignee different from missing 
gen nm_inv_pv=(categ1_pv!=.)

*Identify Patents in Harvard different from missing 
gen ident_inv_h=1 if categ1_h!=.

*****************************************
*	Unidentified Assignees by Dataset (All)
*
*****************************************

{
preserve

collapse (mean) dminv_h dminv_pv, by(appyear)

twoway (connected dminv_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected dminv_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees" 2 "PatentsView Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Fraction of Unidentified Inventors",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/comparison_frac_unident_inv$save_str.pdf", replace as (pdf)
}


restore
	

}

*****************************************
*	Unidentified Assignees Only Merged Patents
*
*****************************************

{
preserve
keep if source==3
collapse (mean) dminv_h dminv_pv, by(appyear)

twoway (connected dminv_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected dminv_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees" 2 "PatentsView Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Fraction of Unidentified Inventors",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/comparison_frac_unident_inv.pdf", replace as (pdf)
}


restore
	

}


*****************************************
*	III) Missings by each dataset  (All)
*
*****************************************

{
tab dminv_h dminv_pv

local i=0
foreach x of numlist 0/1{
	foreach y of numlist 0/1{
	local ++i
	count if dminv_pv==`x' & dminv_h==`y'
	return list
	scalar t_`i'=r(N)
	dis t_`i'
}
}

local j=0
foreach x of numlist 0/1{
local ++j
count if dminv_pv==`x'
scalar pv_`j'=r(N)
dis pv_`j'
count if dminv_h==`x'
scalar h_`j'=r(N)
dis h_`j'
count 
scalar gt=r(N)
}

matrix Y=J(3,3,.)
foreach n of numlist 1/2 {
matrix Y[1,1]=t_1
matrix Y[1,2]=t_3
matrix Y[2,1]=t_2
matrix Y[2,2]=t_4
matrix Y[3,`n']=pv_`n'
matrix Y[`n',3]=h_`n'
matrix Y[3,3]=gt
}
	
	
frmttable using "${tabfolder}/Raw_Missing_Inv$save_str.tex", tex fragment replace sdec(0 \0) /// 
	statmat(Y) ///
rtitles("Not-Missing Harvard"\"Missing Harvard"\"Total") ///
ctitles("","Not-Missing PV","Missing PV","Total") title("Missing PV and Harvard (All Sample)")

/*85.77% not missing assignee in both Harvard and PatentsView*/
}


*****************************************
*	III) Missings by each dataset (Only Merged)
*
*****************************************

{
keep if source==3
{
tab dminv_h dminv_pv

local i=0
foreach x of numlist 0/1{
	foreach y of numlist 0/1{
	local ++i
	count if dminv_pv==`x' & dminv_h==`y'
	return list
	scalar t_`i'=r(N)
	dis t_`i'
}
}

local j=0
foreach x of numlist 0/1{
local ++j
count if dminv_pv==`x'
scalar pv_`j'=r(N)
dis pv_`j'
count if dminv_h==`x'
scalar h_`j'=r(N)
dis h_`j'
count 
scalar gt=r(N)
}

matrix Y=J(3,3,.)
foreach n of numlist 1/2 {
matrix Y[1,1]=t_1
matrix Y[1,2]=t_3
matrix Y[2,1]=t_2
matrix Y[2,2]=t_4
matrix Y[3,`n']=pv_`n'
matrix Y[`n',3]=h_`n'
matrix Y[3,3]=gt
}
	
	
frmttable using "${tabfolder}/Raw_Missing_Inv.tex", tex fragment replace sdec(0 \0) /// 
	statmat(Y) ///
rtitles("Not-Missing Harvard"\"Missing Harvard"\"Total") ///
ctitles("","Not-Missing PV","Missing PV","Total") title("Missing PV and Harvard (All Sample)")

/*85.77% not missing assignee in both Harvard and PatentsView*/
}

}



******************************
*	Figures on Inventors     *	
******************************

{
preserve

keep categ1_h categ1_pv appyear

collapse (count) categ1_h  categ1_pv, by(appyear)


twoway (connected categ1_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected categ1_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Identified Inventors",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Harvard Inventors" 2 "PatentsView Inventors") size(small) rows(1) region(c(none)))

graph export "$figfolder/identified_inventors.pdf", replace as(pdf)


restore

}


{
preserve

keep if source==1 | source==3
duplicates drop patent, force	
bys appyear: gen tot_pat_h=_N

duplicates drop appyear, force

save "$datasets/t_pat_h.dta", replace	
	
restore


preserve

keep if source==2 | source==3
duplicates drop patent, force	
bys appyear: gen tot_pat_pv=_N

duplicates drop appyear, force

save "$datasets/t_pat_pv.dta", replace	
	
restore


preserve

use "$datasets/t_pat_h.dta", clear
merge 1:1 appyear using "$datasets/t_pat_pv.dta"

replace tot_pat_h=tot_pat_h/1000
replace tot_pat_pv=tot_pat_pv/1000
twoway (connected tot_pat_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected tot_pat_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Number of Patents in Thousands",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash)) legend(order(1 "Harvard" 2 "PatentsView") size(small) rows(1) region(c(none)))

graph export "$figfolder/patents_by_datasets.pdf", replace as(pdf)


restore

}

 
 {

 *Dummy for Identified Assignee in Harvard by each Appyear
	bys appyear categ1_h : gen diff_pv_by_h0=1 if categ1_pv[_n]!=categ1_pv[_n-1] & ident_inv_h==1
	
	*Retrieve Diff Codes for Assignee in PatentsView if it is an Identified Assignee in Harvard
	gen dif_codes=categ1_pv if diff_pv_by_h0==1
	
	br categ1_h appyear dif_codes source diff_pv_by_h0
	
	*preserve
	preserve
	
	keep if dif_codes!=. 
		
	egen gr_samp=group(appyear categ1_h)
	
	sort gr_samp dif_codes
	
	*Por cada patente de harvard en un app year cuantos differentes assignees diferentes tiene en PatentsView
	bys gr_samp dif_codes : gen no_dif_pv=1 if categ1_pv[_n]!=categ1_pv[_n-1] & ident_inv_h==1
	bys gr_samp : egen different_inv_pv=sum(no_dif_pv)
	
	duplicates drop gr_samp, force
	
	sort appyear
	

collapse (mean) different_inv_pv, by(appyear)


twoway (connected different_inv_pv appyear, lcolor(navy) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(1(0.01)1.05, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Av. Number of different PV Inventor" "For every H Inventor by Appyear",height(10) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/comparison_no_pv_inv_per_h_inv.pdf", replace as (pdf)
}

}



*****************************
*Exploring Unique Pat with diff inventors - PV vs Harvard
*****************************

tab source if dif_tsize==1
unique patent if dif_tsize==1

/*2194 patents report different tsize in PV and Harvard */
