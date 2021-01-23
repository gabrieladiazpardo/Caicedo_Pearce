****************************************************
* Create strongly balanced panel data for assignees 
****************************************************

*---------------------------------*
*		Turn on options
*---------------------------------*


global utility 1
global rare_any 0
global rare_all 0
global rare_mean 1

*assignee only organizations type 2 and 3
global org_asg 1


*Create new data set with all assignees in all years

use "$datasets/Patentsview_lev_dataset.dta", clear


if $org_asg==1 {
local l_org keep if d_asg_org==1
local l_type_asg keep if type_asg==2 | type_asg==3
local org_save_str _org_asg
`l_org'
`l_type_asg'
}

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



keep asgnum appyear

drop if appyear==. | asgnum==""

quietly: sum appyear

local lNyears=`r(max)'-`r(min)'+1

di("Expanding assignees to `lNyears' years")

keep asgnum

duplicates drop asgnum, force

expand  `lNyears'

sort asgnum

bys asgnum : gen appyear=_n

bys asgnum: replace appyear=appyear+1974

save "$datasets/main_asg_lev_bp_Patentsview.dta", replace


*Keep only relevant data at assignee level

use "$datasets/Patentsview_lev_dataset.dta", clear

drop if d_asg_org==0

drop if appyear<$iyear | appyear==.

drop if asgnum==""

bys appyear asgnum: gen Npat_asg=_N

keep appyear asgnum Npat_asg

duplicates drop asgnum appyear, force

*merge
merge 1:m asgnum appyear using "$datasets/main_asg_lev_bp_Patentsview.dta"

drop _m

sort asgnum appyear

replace Npat_asg=0 if Npat_asg==.

save "$datasets/main_asg_lev_bp_Patentsview.dta", replace
