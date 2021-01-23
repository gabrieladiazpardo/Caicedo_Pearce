***************************************************
*		Assignee Comparison - PV vs Harvard		  *
*												  *
*												  *
***************************************************

*globals
global figfolder="$main/RA/output/figfolder/comparison"
global tabfolder="$main/RA/output/tabfolder/comparison"

**Other options
global iyear 1975 //initial year of plots
global fyear 2010 //final year of plots

graph set window fontface "Garamond"
global size_font medlarge // medlarge //
global save_str _allpat

**Saving options
global save_fig 1 //  0 //

*Open PV
use "$datasets/Patentsview_lev_dataset.dta", clear

keep patent appyear type_pat asgnum type_asg assignee d_asg_org

*rename for PV
findname, local(vars)
local no = "patent"
local list: list vars - no

foreach y of local list {
rename `y' `y'_pv
}

*Make years comparable between the two datasets
drop if appyear_pv>2010

*Merge harvard Data
merge 1:1 patent using "$datasets/Harvard_pat_lev_dataset.dta", keepusing(asgnum assignee appyear)

*rename for H
local vars asgnum assignee appyear

foreach y of local vars {
rename `y' `y'_h
}

/*
not matched - 1,562,961
	from master (PV) - 1,301,338 
	from using (Harvard) - 261,623 
*/

rename _m source
label define vv 1"Only in PatentsView" 2"Only in Harvard" 3"Both Datasets"
label values source vv
label var source "Source"

gen appyear=.
replace appyear=appyear_pv if source==1 | source==3
replace appyear=appyear_h if source==2

label var appyear "Harmonized Appyear"
label var appyear_h "Original Appyear Harvard"
label var appyear_pv "Original Appyear PatentsView"


order patent appyear asgnum_pv asgnum_h assignee_pv assignee_h d_asg_org_pv source type_pat_pv appyear_pv appyear_h


sort patent

*--Dummy for missing by each dataset
	gen dmasg_h=(asgnum_h=="")
	gen dmasg_pv=(asgnum_pv=="")
	
*Dummy if PV Assignee different from missing 
gen nm_asg_pv=(asgnum_pv!="")
*Identify Patents in Harvard	 different from missing 
gen ident_asg_h=1 if asgnum_h!=""
	
	*-----------------------------------------------------*
	*				All Sample of Patents PV+H
	*
	*------------------------------------------------------*
	
	
*****************************************
*	I) Identified Assignees by Dataset
*
*****************************************
{
preserve

drop if asgnum_pv==""

keep appyear assignee_pv

duplicates drop appyear assignee_pv, force

collapse (count) assignee_pv, by(appyear)

save "$datasets/count_assignee_pv.dta", replace
restore



preserve

drop if asgnum_h==""

keep appyear assignee_h

duplicates drop appyear assignee_h, force

collapse (count) assignee_h, by(appyear)

save "$datasets/count_assignee_h.dta", replace

restore

preserve

use "$datasets/count_assignee_pv.dta", clear

merge 1:1 appyear using "$datasets/count_assignee_h.dta"


twoway (connected assignee_h  appyear, lcolor(navy) lwidth(medthick)) ///
(connected assignee_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard" 2 "PatentsView") size(small) rows(1) region(c(none))) ////
ytitle("No. of Identified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))




if $save_fig==1 {
graph export "$figfolder/ident_asg$save_str.pdf", replace as(pdf)
}

restore

}

*****************************************
*	II) Unidentified Assignees by Dataset
*
*****************************************

{
preserve

collapse (mean) dmasg_h dmasg_pv, by(appyear)

twoway (connected dmasg_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected dmasg_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees" 2 "PatentsView Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Fraction of Unidentified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/comparison_frac_unident_asg$save_str.pdf", replace as (pdf)
}


restore
	

}


*****************************************
*	III) Missings by each dataset 
*
*****************************************

{
tab dmasg_h dmasg_pv

local i=0
foreach x of numlist 0/1{
	foreach y of numlist 0/1{
	local ++i
	count if dmasg_pv==`x' & dmasg_h==`y'
	return list
	scalar t_`i'=r(N)
	dis t_`i'
}
}

local j=0
foreach x of numlist 0/1{
local ++j
count if dmasg_pv==`x'
scalar pv_`j'=r(N)
dis pv_`j'
count if dmasg_h==`x'
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
	
	
frmttable using "${tabfolder}/Raw_Missing_Asg$save_str.tex", tex fragment replace sdec(0 \0) /// 
	statmat(Y) ///
rtitles("Not-Missing Harvard"\"Missing Harvard"\"Total") ///
ctitles("","Not-Missing PV","Missing PV","Total") title("Missing PV and Harvard (All Sample)")

/*85.77% not missing assignee in both Harvard and PatentsView*/

}


*******************************************************
*	IV) Unidentified H Correspond to some Type in PV
*
********************************************************

{

preserve

keep if dmasg_h==1 & dmasg_pv==0
tab type_asg, nol

matrix define S=J(15,2,.)

foreach n of numlist 1/9{
count if type_asg==`n'
matrix S[`n',1]=r(N)
count
matrix S[15,1]=r(N)
matrix S[`n',2]=S[`n',1]/S[15,1]*100
matrix S[15,2]=100
}

foreach r of numlist 12/15{

local k `r'-2

count if type_asg==`r'
matrix S[`k',1]=r(N)
count
matrix S[15,1]=r(N)
matrix S[`k',2]=S[`k',1]/S[15,1]*100

count if type_asg==17
matrix S[14,1]=r(N)
matrix S[14,2]=S[14,1]/S[15,1]*100
}


	
frmttable using "${tabfolder}/Type_Miss_Harvard$save_str.tex", tex fragment replace sdec(0 \2) /// 
	statmat(S) ///
rtitles("Unassigned"\"US Company or Corporation"\"Foreign Company or Corporation"\"US Individual"\"Foreign Individual"\"US  Federal Government"\"Foreign Government"\"US County Government"\"US State Government"\"PI- US Company or Corporation"\"PI- Foreign Company or Corporation"\"PI - US Individual"\"PI - Foreign Individual"\"PI - Foreign Government"\"Total") ///
ctitles("","Type Assignee","%",) title("Type of Assignee if Missing in Harvard (All Patents)")

restore

}



*****************************************
*	I) Other Way - Identified Assignees by Appyear
*
*****************************************
	
	{

*Foreach different appyear 
bys appyear asgnum_h : gen dasg_h=1 if asgnum_h[_n]!=asgnum_h[_n-1] & ident_asg_h==1
bys appyear : egen dif_asg_h=sum(dasg_h)
	
*Fotrsvh Patent in PV
	gen ident_asg_pv=1 if asgnum_pv!=""

	bys appyear asgnum_pv : gen dasg_pv=1 if asgnum_pv[_n]!=asgnum_pv[_n-1] & ident_asg_pv==1
	bys appyear : egen dif_asg_pv=sum(dasg_pv)


preserve

collapse (mean) dif_asg_h dif_asg_pv , by(appyear)

twoway (connected dif_asg_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected dif_asg_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard" 2 "PatentsView") size(small) rows(1) region(c(none))) ////
ytitle("No. of Different Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

restore

	}
	
	
*****************************************
*	V) Number of PV assignee for every H assignee by appyear
*****************************************
	{
		
	*Dummy for Identified Assignee in Harvard by each Appyear
	bys appyear asgnum_h : gen diff_pv_by_h0=1 if asgnum_pv[_n]!=asgnum_pv[_n-1] & ident_asg_h==1
	
	*Retrieve Diff Codes for Assignee in PatentsView if it is an Identified Assignee in Harvard
	gen dif_codes=asgnum_pv if diff_pv_by_h0==1
	
	br asgnum_h appyear dif_codes source diff_pv_by_h0
	
	*preserve
	preserve
	
	keep if dif_codes!="" 
		
	egen gr_samp=group(appyear asgnum_h)
	
	sort gr_samp dif_codes
	
	*Por cada patente de harvard en un app year cuantos differentes assignees diferentes tiene en PatentsView
	bys gr_samp dif_codes : gen no_dif_pv=1 if asgnum_pv[_n]!=asgnum_pv[_n-1] & ident_asg_h==1
	bys gr_samp : egen different_asg_pv=sum(no_dif_pv)
	
	duplicates drop gr_samp, force
	
	sort appyear
	

collapse (mean) different_asg_pv, by(appyear)

twoway (connected different_asg_pv appyear, lcolor(navy) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(1(0.05)1.2, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Av. Number of different PV assignees" "For every H assignee by Appyear",height(10) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/comparison_no_pv_asg_per_h_asg.pdf", replace as (pdf)
}

restore



}




	*-----------------------------------------------------*
	*				Analysis only on Matched Patents
	*
	*------------------------------------------------------*


preserve
*--- I) Sample of matched patents

keep if source==3


*I) Missings by each dataset (General)

{
tab dmasg_h dmasg_pv

local i=0
foreach x of numlist 0/1{
	foreach y of numlist 0/1{
	local ++i
	count if dmasg_pv==`x' & dmasg_h==`y'
	return list
	scalar t_`i'=r(N)
	dis t_`i'
}
}

local j=0
foreach x of numlist 0/1{
local ++j
count if dmasg_pv==`x'
scalar pv_`j'=r(N)
dis pv_`j'
count if dmasg_h==`x'
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
	
	
frmttable using "${tabfolder}/Raw_Missing_Asg.tex", tex fragment replace sdec(0 \0) /// 
	statmat(Y) ///
rtitles("Not-Missing Harvard"\"Missing Harvard"\"Total") ///
ctitles("","Not-Missing PV","Missing PV","Total") title("Missing PV and Harvard")

/*85.77% not missing assignee in both Harvard and PatentsView*/

}


*II) Unidentified H Correspond to some Type in PV

{

keep if dmasg_h==1 & dmasg_pv==0
tab type_asg, nol

matrix define S=J(15,2,.)

foreach n of numlist 1/9{
count if type_asg==`n'
matrix S[`n',1]=r(N)
count
matrix S[15,1]=r(N)
matrix S[`n',2]=S[`n',1]/S[15,1]*100
matrix S[15,2]=100
}

foreach r of numlist 12/15{

local k `r'-2

count if type_asg==`r'
matrix S[`k',1]=r(N)
count
matrix S[15,1]=r(N)
matrix S[`k',2]=S[`k',1]/S[15,1]*100

count if type_asg==17
matrix S[14,1]=r(N)
matrix S[14,2]=S[14,1]/S[15,1]*100
}


	
frmttable using "${tabfolder}/Type_Miss_Harvard.tex", tex fragment replace sdec(0 \2) /// 
	statmat(S) ///
rtitles("Unassigned"\"US Company or Corporation"\"Foreign Company or Corporation"\"US Individual"\"Foreign Individual"\"US  Federal Government"\"Foreign Government"\"US County Government"\"US State Government"\"PI- US Company or Corporation"\"PI- Foreign Company or Corporation"\"PI - US Individual"\"PI - Foreign Individual"\"PI - Foreign Government"\"Total") ///
ctitles("","Type Assignee","%",) title("Type of Assignee if Missing in Harvard")


}

restore



*III) Unidentified Asg is Merged
preserve

keep if source==3

collapse (mean) dmasg_h dmasg_pv, by(appyear)

twoway (connected dmasg_h appyear, lcolor(navy) lwidth(medthick)) ///
(connected dmasg_pv appyear, lcolor(maroon) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees" 2 "PatentsView Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Fraction of Unidentified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/comparison_frac_unident_asg.pdf", replace as (pdf)
}


restore



*********************
*		Other Figures
*
**********************



{
	
preserve

*No missing Assigne PatentsView but missing in Harvard

gen m_h_nm_pv=(asgnum_pv!="" & asgnum_h=="")	


*Sum of Not Missing Patents from PV for eg

collapse (mean) m_h_nm_pv, by(appyear)

twoway (connected m_h_nm_pv appyear, lcolor(navy) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees" 2 "PatentsView Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Fraction of Unidentified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

*graph export "$figfolder/comparison_frac_unident_asg.pdf", replace as (pdf)

restore


}


{
preserve

collapse (sum) nm_asg_pv dmasg_h , by(appyear)

gen div=nm_asg_pv/dmasg_h
twoway (connected div appyear, lcolor(navy) lwidth(medthick)), ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) legend(order(1 "Harvard Assignees" 2 "PatentsView Assignees") size(small) rows(1) region(c(none))) ////
ytitle("Fraction of Unidentified Assignees",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

*graph export "$figfolder/comparison_frac_unident_asg.pdf", replace as (pdf)

restore

}





