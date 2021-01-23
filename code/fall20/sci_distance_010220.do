*Exploration Facts
*Fall 2020

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



****PERSONAL DEVELOPMENT STUFF STUFF:


gen alone=0
replace alone=1 if tsize==1

****************************************************************
* PART 1.5: p2p distance based on IPC-2 - Ufuk
****************************************************************


keep if alone==1
keep categ1 ipc3



drop if length(ipc3) < 3

gen cited_ipc2 = substr(ipc3,1,2)

gen cited_digit1 = substr(ipc3,1,1)
gen cited_digit2 = substr(ipc3,2,1)

keep if (cited_digit1 == "A") | (cited_digit1 == "B") |(cited_digit1 == "C") |(cited_digit1 == "D") |(cited_digit1 == "E") |(cited_digit1 == "F") |(cited_digit1 == "G") |(cited_digit1 == "H")
keep if (cited_digit2 == "0") | (cited_digit2 == "1") |(cited_digit2 == "2") |(cited_digit2 == "3") |(cited_digit2 == "4") |(cited_digit2 == "5") |(cited_digit2 == "6") |(cited_digit2 == "7") |(cited_digit2 == "8") |(cited_digit2 == "9")

rename cited_ipc2 digit12


forvalue i=0/9 {
generate A`i' = 0
}
forvalue i=0/9 {
generate B`i' = 0
}
forvalue i=0/9 {
generate C`i' = 0
}
forvalue i=0/9 {
generate D`i' = 0
}
forvalue i=0/9 {
generate E`i' = 0
}
forvalue i=0/9 {
generate F`i' = 0
}
forvalue i=0/9 {
generate G`i' = 0
}
forvalue i=0/9 {
generate H`i' = 0
}

forvalue i=0/9 {
replace A`i' = 1 if digit12 == "A" + string(`i')
}
forvalue i=0/9 {
replace B`i' = 1 if digit12 == "B" + string(`i')
}
forvalue i=0/9 {
replace C`i' = 1 if digit12 == "C" + string(`i')
}
forvalue i=0/9 {
replace D`i' = 1 if digit12 == "D" + string(`i')
}
forvalue i=0/9 {
replace E`i' = 1 if digit12 == "E" + string(`i')
}
forvalue i=0/9 {
replace F`i' = 1 if digit12 == "F" + string(`i')
}
forvalue i=0/9 {
replace G`i' = 1 if digit12 == "G" + string(`i')
}
forvalue i=0/9 {
replace H`i' = 1 if digit12 == "H" + string(`i')
}


quietly collapse (sum) A0-H9, by(categ1)

foreach letter1 in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {
foreach letter2 in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {
gen in_intersection = 0
replace in_intersection = 1 if `letter1' & `letter2'
gen in_union = 0
replace in_union = 1 if `letter1' | `letter2'
egen intersection = total(in_intersection)
egen union = total(in_union)
gen d`letter1'`letter2'= 1 - (intersection / union)
display "`myname'" 
display ``myname''
drop intersection union in_intersection in_union
}
}


local i=1
foreach letter1 in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {
foreach letter2 in A0 A2 A4 A6 B0 B2 B3 B4 B6 B8 C0 C1 C2 C3 D0 D1 D2 E0 E2 F0 F1 F2 F4 G0 G1 G2 H0 {


rename d`letter1'`letter2'  d`letter1'_`letter2'

*local i=`i'+1
}
}

duplicates drop

rename d*_ *


egen mean=rowmean(A* B* C* D* E* F* G* H*)
save "$main/Caicedo_Pearce/data/sci_distance_long_ipc2_dec20.dta"
