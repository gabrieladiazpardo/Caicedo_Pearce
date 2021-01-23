
*Fall 2020
set more off

**Saving options
global save_fig 1 //  0 //


graph set window fontface "Garamond"
global size_font large // medlarge //

**Other options
global iyear 1975 //initial year of plots
global fyear 2015 //final year of plots


global figfolder="$main/RA/output/figfolder/fall of generalists"
global tabfolder="$main/RA/output/tabfolder/fall of generalists"


*Options of sample
global utility 1
global rare_any 0
global rare_all 0
global rare_mean 1

**IPC3

{
use "$datasets/Patentsview_lev_dataset.dta", clear

if $utility==1 {
local l_utility keep if type_pat==7
local ut_save_str _only_utility
`l_utility'
}

if $rare_any==1 {
local l_rare_any drop if rare_ipc3_any==1
local any_save_str _rare_any
`l_rare_any'
}

if $rare_all==1 {
local l_rare_all drop if rare_ipc3_all==1
local all_save_str _rare_all
`l_rare_all'

}

if $rare_mean==1 {
local l_rare_mean drop if rare_ipc3_mean==1
local mean_save_str _rare_mean
`l_rare_mean'
}

keep appyear ipc3 

duplicates drop appyear ipc3, force

encode ipc3, gen(ipc3n)

collapse (count) ipc3n, by(appyear)

twoway (connected  ipc3n appyear, lcolor(navy) lwidth(medthick)) , ///
graphregion(color(white)) bgcolor(white) xtitle("Application Year",height(8) size($size_font)) xlabel($iyear(5)$fyear, labsize($size_font)) ylabel(80(20)280, nogrid labsize($size_font)) ////
ytitle("Number of Distinct IPC (3 Characters)",height(8) size($size_font)) xline(1995, lcolor(red) lpattern(dash))

if $save_fig==1 {
graph export "$figfolder/ipc3`any_save_str'`all_save_str'`mean_save_str'`ut_save_str'.pdf", replace as(pdf)
}

}
