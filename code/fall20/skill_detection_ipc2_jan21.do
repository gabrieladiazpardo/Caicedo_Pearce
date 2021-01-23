
***here we use the distance measure and build the following structure:

/*your type is the funciton of where you work when alone

then you have an ex ante probability you have X skill and an ex post probability of that skill.


****0--> 3


***probability they have it: give 1-probability to other producer

*/





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
global corporate 0

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


gen ipc2=substr(ipc3,1,2)


merge m:1 ipc2 using "$main/Caicedo_Pearce/data/sci_distance_long_ipc2_dec20.dta"

keep if _m==3


gen alone=0
replace alone=1 if tsize==1


foreach ipc in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {

gen `ipc'=0
replace `ipc'=1 if alone==1 & ipc2=="`ipc'"
bys categ1 (patnumpp1): gen sum`ipc' = sum(`ipc')
}



gen skill_ipc=0

foreach ipc in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {
replace `ipc'=1 if `ipc'>=1

gen p`ipc'=0 if `ipc'==0

}





egen s_ipc=rowtotal(pA0-pH0)
replace skill_ipc=s_ipc


foreach ipc in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {

gen `ipc'=0
replace `ipc'=1 if alone==1 & ipc2=="`ipc'"
bys categ1 (patnumpp1): gen sum`ipc' = sum(`ipc')
}

foreach ipc in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {
replace `ipc'=1 if ipc2=="`ipc'"
}

gen prob_ipc=0
foreach ipc in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {
replace sum`ipc'=1 if sum`ipc'>1 & sum`ipc'~=.
replace p`ipc'=1-d`ipc'
replace prob_ipc=prob_ipc + sum`ipc'*p`ipc'
}

bys categ1: egen min_patent=min(tsize)
***this delivers the initial skill set of the individual
bys patent: egen first_degree_max=max(prob_ipc)
bys patent: egen first_degree_min=min(prob_ipc)

gen exposure2=.
replace exposure2=first_degree_max if prob_ipc==first_degree_min & tsize==2
replace exposure2=first_degree_min if prob_ipc==first_degree_max & tsize==2
gen p_norm=first_degree_max+first_degree_min
gen projected2=prob_ipc/p_norm
gen exposure=.
replace exposure=prob_ipc if tsize==1
replace exposure=exposure2 if tsize==2
replace exposure=1 if exposure>1 & exposure~=.


***so now recognize if the individual has 

