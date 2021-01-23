

/////////////////////////////////////////
//////	Exp Cites
//////////////////////////////////////


**Saving options
global save_fig   1 //0 // 

graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots


use "$datasets/life_cit_IPC1_all.dta",clear

collapse(mean)exp_cit f_cit, by(ipc1 appyear)

keep if appyear>1974
keep if appyear<2016

levelsof ipc1, local(levels) 
local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected exp_cit appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Lag (in years)",height(8) size($size_font)) ///
xlabel(1975(5)2015, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Expected Forward Citations" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/exp_cit_adj_ipc.pdf", replace as(pdf)
}


collapse(mean) exp_cit, by(appyear)

twoway (connected exp_cit appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Expected Forward Citations",height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/exp_cit_adj.pdf", replace as(pdf)
}

/////////////////////////////////////////
//////	Exp Cites Year Effects
//////////////////////////////////////

****BUILDING SKILLS BASED ON MERGED COMPONENTS:

*open inventors dataset
use "$datasets/tmp_inventors_uspto.dta", clear

*--merge forward citations to each patent
merge m:1 patent using "$datasets/life_cit_IPC1_all.dta"
drop _m

*--merge issue date to each patent
merge m:1 patent using "$datasets/tmp_patents_uspto_2.dta"
drop _m

*--merge ipc3 - subcateg to each patent
merge m:1 patent using "$datasets/tmp_uspto_ipc3.dta" 
drop _m

*--merge only choosed patents
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f"

*--keep only inventors with selected patents from "keep only"
keep if _m==3
drop _m



/*
merge m:1 patent using "$output/dates_CP.dta"
drop _m
*/


*--issue date
rename gdate date

egen pat=group(patent)


*---by inventor id (categ1), set counter for each of the different patents made
bys categ1 (date pat): gen patnumpp1=_n
xtset categ1 patnumpp1

*Lag
gen ttb=date-L.date



gen ptn=1
*replace ptn=1/ts


*--Suma total de diferentes patentes por inventor
bys categ1 (patnumpp1): gen sum_ptn=sum(ptn)

*--Acumulado de patentes hechos hasta ese periodo
gen prev_ptn=sum_ptn-ptn


*--Acumulado de patentes PREVIAS - la primera patente debe tener 0
replace prev_ptn=L.prev_ptn if ttb==0

*--Total de Patentes en los datos
bys pat: gen tot=_N

*--Panel Inventor-Patente 
xtset categ1 patnumpp1


*--Sub-Categoría 
rename ipc3 cited_sub

*--Mergear datos del IPC3_dependence_long_agg
merge m:1 cited_sub using "$datasets/IPC3_dependence_long_agg_all.dta"
keep if _m==3
drop _m


*--min invseq //cuantos inventores hay en el team

*1) First Way
bys patent: egen minvseq=min(invseq)
gen invseq2=invseq
replace invseq2=invseq+1 if minvseq==0


*2) Second Way (Without Invseq - simulating tsize)

bys patent: gen invcounter=_n if inventor_id!=""


sort categ1 patnumpp1

gen dummy=1

*gen connec_bb=.

*gen mconnec_bb=.

*gen depthrun=.

*gen depthtotal=.

*gen weight=1/tot


*replace weight=0 if weight~=1

bys categ1: gen totpat=_N

replace exp_cit=. if invcounter!=1

bys appyear: egen mcit=mean(exp_cit)

replace exp_cit=exp_cit/mcit

bys patent:egen cit=mean(exp_cit)

replace exp_cit=cit


duplicates drop patent, force

collapse (mean) exp_cit cit, by(appyear tech_cat)


keep if appyear>1974
keep if appyear<2016

tostring tech_cat, gen(ipc1)

levelsof ipc1, local(levels) 
local i=1
local pl_ipc1

foreach l of local levels{
local pl_ipc1  `pl_ipc1' (connected exp_cit appyear if ipc1=="`l'")
local lab_str  `lab_str' label( `i' "`l'") 
local i=`i'+1
}

twoway  `pl_ipc1' , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) ///
xlabel(1975(5)2015, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Expected Forward Citations Corrected" ,height(8) size($size_font)) ///
legend(region(lcolor(white)) `lab_str' cols(4) ) 


if $save_fig==1 {
graph export "$figfolder/exp_cit_adj_yrly_ipc.pdf", replace as(pdf)
}


collapse(mean)exp_cit, by(appyear)

twoway (connected exp_cit appyear, lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(, nogrid labsize($size_font)) ////
ytitle("Expected Forward Citations Corrected",height(8) size($size_font)) legend(region(lcolor(white))) xline(1995, lcolor(red) lpattern(dash))


if $save_fig==1 {
graph export "$figfolder/exp_cit_adj_yrly.pdf", replace as(pdf)
}

