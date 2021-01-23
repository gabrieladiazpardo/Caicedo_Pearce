*Variables to add to main_CP
* Santiago Caicedo
* Fall 2020


*global main "/Users/JeremyPearce/Dropbox"
global main "D:/Dropbox/santiago/Research"


global data "$main/Caicedo_Pearce/data"
global wrkdata "$main/Caicedo_Pearce/data/wrkdata"
global raw "$main/Caicedo_Pearce/data/rawdata"
global output "$main/Caicedo_Pearce/data/output"

*save string: data version
global save_str _SC


*read most recent version of the data

*use "$output/main_CP.dta", clear


**********************************************************************************************
* Simple quality measures:br 3 year, 5 year forward citation
**********************************************************************************************

*use file from cr_main_CP
*already excludes self-citations

 use "$wrkdata/citations_by_yr", replace
 
drop appdate gyear gday gmonth ay_merge2 _merge

gen cit_pat_age=citing_appyear-cited_appyear

keep if cit_pat_age>=0 & cit_pat_age<=5

bys patent cit_pat_age:  gen cit_yr=_N

duplicates drop patent cit_pat_age, force

keep patent cit_pat_age cit_yr

reshape wide cit_yr, i(patent) j(cit_pat_age)

egen f_cit3= rowtotal( cit_yr0 cit_yr1 cit_yr2 cit_yr3)

egen f_cit5= rowtotal( cit_yr*)

drop cit_yr*


label var f_cit3 "3-year Forward Citations (No Adjustment)"
label var f_cit5 "5-year Forward Citations (No Adjustment)"

save "$wrkdata/f_cit", replace


**********************
* Backward citations
**********************


use "$data/uscites2015.dta", clear


destring patent, force replace
**** 2,539,573 missing values


***merge with relevant patent info:
merge m:1 patent using "$wrkdata/patent_app_bib.dta"

keep if _m==3 
*3,155,812 observations deleted
drop _merge

***Use firm and ipc3 data to identify self-citations 
merge m:1 patent using "$output/firms_CP.dta"
keep if _m==3
*21,002,266 observations deleted!
drop _m


merge m:1 patent using "$output/patent_ipc3_dd.dta" , keepusing(ipc3)
drop _m


rename asgnum citing_pdp
rename ipc3 citing_ipc3
rename patent citing

rename cited patent

merge m:1 patent using "$output/firms_CP.dta"
drop if _m==1 
*8,271,231 observations deleted
drop _m

merge m:1 patent using "$output/patent_ipc3_dd.dta" , keepusing(ipc3)
drop _m

rename asgnum cited_pdp
rename ipc3 cited_ipc3

*gen self_cite variable
gen asg_self_cite=1 if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~="0"
	replace asg_self_cite=0 if asg_self_cite==.

gen ipc3_self_cite=1 if cited_ipc3==citing_ipc3 & cited_ipc3~="" & cited_ipc3~="0"
	replace ipc3_self_cite=0 if ipc3_self_cite==.

rename appyear citing_appyear

merge m:1 patent using "$wrkdata/patent_app_bib.dta", gen(ay_merge2)
destring gday gmonth gyear, replace
rename appyear cited_appyear
drop if citing==. | patent==.

drop ay_merge2 

drop gyear gday gmonth appdate

rename patent cited

order citing cited citing_appyear cited_appyear

sort citing citing_appyear

*label variables
label var citing "Citing Patent"
label var cited  "Cited Patent"
label var citing_appyear  "Citing Patent Application Year"
label var cited_appyear  "Cited Patent Application Year"
label var citing_pdp  "Citing Patent Assignee"
label var citing_ipc3 "Citing Patent IPC3"
label var cited_pdp  "Cited Patent Assignee"
label var cited_ipc3 "Cited Patent IPC3"
label var asg_self_cite "Self-citing Assignee"
label var ipc3_self_cite "Self-citing IPC3"

save "$wrkdata/citing_cited$save_str.dta",replace



**Backward citations and self-citations
use "$wrkdata/citing_cited$save_str.dta", clear

bys citing : gen b_cit=_N
bys citing asg_self_cite: gen temp_sc=_N if asg_self_cite==1
	replace temp_sc=0 if temp_sc==.
bys citing : egen b_cit_asg_sc=max(temp_sc)
drop temp_sc

bys citing ipc3_self_cite: gen temp_sc=_N if ipc3_self_cite==1
	replace temp_sc=0 if temp_sc==.
bys citing : egen b_cit_ipc3_sc=max(temp_sc)
drop temp_sc	
	

duplicates drop citing, force

rename citing patent 

keep patent b_cit b_cit_asg_sc b_cit_ipc3_sc

label var b_cit "Backward Citations"
label var b_cit_asg_sc "Backward Citations to Same Assignee"
label var b_cit_ipc3_sc "Backward Citations to Same IPC3"

save "$wrkdata/b_cit$save_str.dta",replace


***********************************
*Merge to main_CP
***********************************

use "$output/main_CP.dta", clear

merge m:1 patent using "$wrkdata/f_cit"
drop _merge

merge m:1 patent using "$wrkdata/b_cit$save_str"
drop _merge

save "$output/main_CP$save_str.dta",replace

***********************************
*Restrict to 1975 to 2010
***********************************
use "$output/main_CP$save_str.dta", clear

keep if appyear>=1975 & appyear<=2010

save "$output/main_CP$save_str.dta",replace

***********************************
* Update patent level dataset
***********************************

*Only keep patent level data

use "$output/main_CP$save_str.dta", clear

keep patent appyear exp_cit breadthteam_e depthteam_e invh_cit asgnum uspto_class date ipc3 m_ttb ttb_cit invh_ttb tsize survive cit3 cit5 f_cit3 f_cit5 b_cit b_cit_asg_sc b_cit_ipc3_sc

duplicates drop patent, force

save "$output/main_pat_lev_CP$save_str.dta", replace

*******************************************************************************************************************
*HAVE TO MERGE THIS TO MAIN CODE : OCT 2020

****************************************************
* Create strongly balanced panel data for assignees 
****************************************************


*Create new data set with all assignees in all years

use "$output/main_pat_lev_CP$save_str.dta", clear

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

save "$output/main_asg_lev_bp_CP$save_str.dta", replace


*Keep only relevant data at assignee level

use "$output/main_pat_lev_CP$save_str.dta", clear

drop if appyear<$iyear | appyear==.

drop if asgnum==""

bys appyear asgnum: gen Npat_asg=_N

keep appyear asgnum Npat_asg

duplicates drop asgnum appyear, force

*merge
merge 1:m asgnum appyear using "$output/main_asg_lev_bp_CP$save_str.dta"

drop _m

sort asgnum appyear

replace Npat_asg=0 if Npat_asg==.

save "$output/main_asg_lev_bp_CP$save_str.dta", replace






 