*********************************************************
*				PatentsView Data						*
*		           Main CPC								*
*														*
*********************************************************

**Saving options
global reduced 1

*******************************************
*	1) Cleaning Rawdata from PatentsView
*
*******************************************

///////////////////////////////////////////////
/// USPC Current Class - Keep First Sequence
////////////////////////////////////////////////

{
*Note: This dataset contains info. on USPC Classification. However, this classification is not consistant through time. We keep only the first classification.

import delimited "$rawdata/USPTO/uspc_current.tsv", stringcols(4) clear
drop uuid
bys patent_id: egen m=min(sequence)
drop if patent_id==""
gen d_keep=1 if sequence==m
keep if d_keep==1
drop m d_keep sequence
compress

duplicates drop patent_id, force
*rename
rename patent_id patent
rename mainclass_id mainclass_uspc
rename subclass_id subclass_uspc

save "$datasets/uspc_current_fixed.dta", replace
}

////////////////////////////////////////////////
//// CPC Current Class - Keep First Sequence
////////////////////////////////////////////////

{
import delimited "$rawdata/USPTO/cpc_current.tsv", colrange(2:8) stringcols(_all) clear

drop subgroup_id category

destring sequence, replace
drop if patent_id==""
bys patent_id: egen m=min(sequence)
gen d_keep=1 if sequence==m
keep if d_keep==1
drop m d_keep sequence
compress


*rename

rename patent_id patent
rename section_id section_cpc
rename subsection_id subsection_cpc
rename group_id group_cpc


save "$datasets/cpc_current_fixed.dta", replace


/*
*----Merge Description Subsection and Group

*Description of Subsection

merge m:1 subsection_id using "$rawdata/USPTO/cpc_subsection.dta", gen (m1)
drop if m1==2
drop m1

*Description of Group

merge m:1 group_id using "$rawdata/USPTO/cpc_group.dta", gen (m2)
drop if m2==2
drop m2

*Description of Section

A - Human Necessitites 
B - Performing Operations; Transporting
C - Chemistry; Metallurgy
D - Textiles; Paper
E - Fixed Constructions
F - Mechanical Engineering; Lighting; Heating; Weapons; Blasting Engines or Pumps
G - Physics
H - Electricity
Y - General Tagging of New Technological Developments
*/

}

////////////////////////////////////////////////////////////////
//// Inventor Sequence (RAW) - Retrieve Sequence for Inventors
///////////////////////////////////////////////////////////////

{
use "$rawdata/USPTO/rawinventor.dta", clear
drop if inventor_id==""

duplicates drop patent_id inventor_id, force 


keep patent_id inventor_id sequence
destring sequence, replace
compress
save "$rawdata/USPTO/modify/inv_seq.dta", replace
}

//////////////////////////////////////////////////////////////
//// Assignee Sequence (RAW) - identify first assignee in order 
/////////////////////////////////////////////////////////////

{
use "$rawdata/USPTO/rawassignee.dta", clear
drop uuid
bys patent_id: egen m=min(sequence)
drop if patent_id==""
gen d_keep=1 if sequence==m
keep if d_keep==1
drop m d_keep
tab sequence
keep patent_id assignee_id
gen first_assignee=1
compress
save "$rawdata/USPTO/modify/assignee_first_seq.dta", replace
}


////////////////////////////////////////////////////
//////	Application Year Dataset
///////////////////////////////////////////////

{
import delimited "$rawdata/USPTO/application.tsv", stringcols(2 3 4) clear 

drop series_code number country
rename date appdate
split appdate, parse(-)		
destring appdate1 appdate2 appdate3, replace
gen app_date=mdy(appdate2, appdate3, appdate1)
format app_date %td	
rename (appdate2 appdate3 appdate1) (appmonth appday appyear)
drop appdate
rename app_date appdate
compress

drop appmonth appday
 
rename id number
rename patent_id patent

save "$datasets/appdate_uspto.dta", replace

}

/////////////////////////////////////
//////	Import IPC Classification
/////////////////////////////////////

{
*IPCs - International Patent Classification data for all patents (as of publication date)

*Aim: Retrieve, for each available patent, the classification level and section to create ipc3 - a unique 3-digit classification

insheet using "$raw/ipcr.tsv",clear

keep patent_id section ipc_class subclass sequence ipc_version_indicator

/*

A = Human Necessitites
B = Performing Operations; Transporting
C = Chemistry; Metallurgy
D = Textiles; Paper; Others
E = Fixed Constructions
F = Mechanical Engineering; Lighting; Heating; Weapons; Blasting
G = Physics
H = Electricity

*/


*Fix Section

replace section = upper(section)


*Fix IPC Classification
		
global pg `""1" "2" "3" "4" "5" "6" "7" "8" "9""' 
	
local i=0

foreach s of global pg{
local ++i
replace ipc_class="0`i'" if ipc_class=="`s'"
}


global t `""O1" "O2" "O3" "O4" "O5" "O6" "O7" "O8" "O9""' 
	
local i=0

foreach t of global t{
local ++i
replace ipc_class="0`i'" if ipc_class=="`t'"
}

drop if patent_id==""
bys patent_id: egen m=min(sequence)
gen d_keep=1 if sequence==m

keep if d_keep==1

drop sequence m d_keep 

*reports if ipc class contains, non numeric characters. (shouldn't)
gen nd=(missing(real(ipc_class)))
drop if nd==1 
/// 161 where dropped since ipc class contained non-numeric characters

*rare sections

drop nd

gen rare_section=0
global r `""I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0""'

foreach i of global r {
replace rare_section=1 if section=="`i'"
}


*ipc3
gen ipc3=section+ipc_class if rare_section==0

*978 patents without ipc3 due to rare section

*fix subclass
replace subclass = upper(subclass)

compress

*optional
keep if rare_section==0
drop rare_section

*rename
rename patent_id patent
rename section section_ipc
rename subclass subclass_ipc

*dataset for cit
preserve
keep patent ipc3
compress
save "$datasets/ipc3_for_cit.dta", replace
restore

save "$datasets/uspto_ipc3.dta",replace

}


/////////////////////////////////////
//////	Fix NBER Codes
/////////////////////////////////////
{
use "$rawdata/USPTO/nber.dta", clear

drop uuid

label define cat 1 "Chemical" ///
2 "Cmp&Cmm" ///
3 "Drgs&Med" ///
4 "Elec" ///
5 "Mech" ///
6 "Others", modify


label define subcat 11 "Agriculture,Food,Textiles" 12 "Coating" 13 "Gas" ///
14 "Organic Compounds" ///
15 "Resins" ///
19 "Miscellaneous" ///
21 "Communications" ///
22 "Computer Hardware & Software" ///
23 "Computer Peripherials" ///
24 "Information Storage" ///
25 "Electronic business methods and software" ///
31 "Drugs" ///
32 "Surgery & Med Inst." ///
33 "Genetics" ///
39 "Miscellaneous" ///
41 "Electrical Devices" ///
42 "Electrical Lighting" ///
43 "Measuring & Testing" ///
44 "Nuclear & X-rays" ///
45 "Power Systems" ///
46 "Semiconductor Devices" ///
49 "Miscellaneous" ///
51 "Mat. Proc & Handling" ///
52 "Metal Working" ///
53 "Motors & Engines + Parts" ///
54 "Optics" ///
55 "Transportation" ///
59 "Miscellaneous" ///
61 "Agriculture,Husbandry,Food" ///
62 "Amusement Devices" ///
63 "Apparel & Textile" ///
64 "Earth Working & Wells" ///
65 "Furniture,House Fixtures" ///
66 "Heating" ///
67 "Pipes & Joints" ///
68 "Receptacles" ///
69 "Miscellaneous", modify

destring category_id subcategory_id, replace

label values category_id cat
label values subcategory_id subcat

compress

*rename
rename patent_id patent
rename category_id category_nber
rename subcategory_id subcategory_nber

save "$datasets/nber_categories.dta", replace

}


////////////////////////////////////////////////
//// Reduce Location Dataset
////////////////////////////////////////////////
{
use "$rawdata/USPTO/location.dta", clear
keep id country lat* lon* city 
compress
save "$rawdata/USPTO/modify/tmp_loc.dta", replace

}

/////////////////////////////////////
////	Merge all Inventors-Info
/////////////////////////////////////

{

*----------------------------------------*
*		Merge Inventor's Information
*			(Patent-Inventor)
*----------------------------------------*

{

//Import Patentid, Inventor, Inventor Disambiguated Location
use "$rawdata/USPTO/patent_inventor.dta", clear

drop if inventor_id==""

//merge inventors sequence
merge 1:1 patent_id inventor_id using "$rawdata/USPTO/modify/inv_seq.dta", gen (m1)
drop m1
*not merged=0

//Merge Inventor's Name
rename inventor_id id 
merge m:1 id using "$rawdata/USPTO/inventor.dta", gen (m2)
rename id inventor_id 
drop m2
*not merged=0
rename sequence invseq
rename name_first name_inv
rename name_last lastname_inv

}

*----------------------------------------*
*		Merge Inventor's Location
*			(Patent-Inventor)
*----------------------------------------*

{
rename location_id id

///////Merge Inventor's Disambiguated Location
merge m:1 id using "$rawdata/USPTO/modify/tmp_loc.dta", gen (m3)

*drop locations without patents
drop if m3==2
rename id loc_inv_id

rename (latitude longitude country city) (lat_inv lon_inv country_inv city_inv)
drop m3

compress

rename patent_id patent

egen categ1=group(inventor_id)

if $reduced==1 {
keep patent inventor_id invseq loc_inv_id categ1
}

label var loc_inv_id "ID Location Inventor"
label var invseq "Inventor Sequence"
label var categ1 "Inventor ID - Numeric"
label var inventor_id "Inventor ID"

if $reduced==0 {
label var name_inv "Name inventor"
label var lastname_inv "Last Name Inventor"
label var city_inv "City Inventor"
label var country_inv "Country Inventor"
label var lat_inv "Latitude Inventor"
label var lon_inv "Longitude Inventor"

}




compress
save "$datasets/inventors_uspto.dta", replace

}


}

/////////////////////////////////////
//////	Merge all Assignees
/////////////////////////////////////

{
*----------------------------------------*
*		Merge Assignee Location
*			(Patent-Inventor)
*----------------------------------------*
{
use "$rawdata/USPTO/patent_assignee.dta", clear

egen loc_asg=group(location_id)

*Fix duplicates in location for same assignee-patent
duplicates tag patent_id assignee_id, gen (dup_assg)

bys patent_id assignee_id: egen md_loc=mode(loc_asg) if dup_assg>0
bys patent_id assignee_id: gen tmp_md_loc=loc_asg if _n==1 & dup_assg>0 & md_loc==.
bys patent_id assignee_id: egen tmp_md_loc2=max(tmp_md_loc) if dup_assg>0 & md_loc==.
replace md_loc=tmp_md_loc2 if md_loc==.
drop tmp_md_loc tmp_md_loc2

gen locat_asg=.
replace locat_asg=loc_asg if dup_assg==0
replace locat_asg=md_loc if dup_assg>0
drop md_loc

preserve

keep location_id loc_asg
rename loc_asg locat_asg
rename location_id loc_id_strg
duplicates drop locat_asg loc_id_strg, force
tempfile assg_org_loc
save "`assg_org_loc'", replace

restore

merge m:1 locat_asg using  "`assg_org_loc'", gen(m1)
drop if m1==2
drop m1


duplicates drop patent_id assignee_id, force 

*duplicates on assignee patent = 4,065. *Duplicates in terms of assignee_id and patent. This is because an assignee id conditioned in a patent can report up to three different locations

drop location_id dup_assg loc_asg
rename locat_asg loc_asg
rename loc_id_strg location_id

*merge first assignee in sequence
merge m:1 patent_id assignee_id using "$rawdata/USPTO/modify/assignee_first_seq.dta", gen(m1)

sort patent_id

*verify only one firm with first_assignee
duplicates tag patent_id, gen(dp)
br if dp>0
replace first_assignee=0 if first_assignee==.

drop m1 dp
}

*----------------------------------------*
*		Merge Assignee's Information
*			(Patent-Inventor)
*----------------------------------------*
{
rename assignee_id id

*dataset about different assignees
merge m:1 id using "$rawdata/USPTO/assignee.dta", gen (m2)

*506,170 info about assignees without patent that didn't merge (not patent-assignees)
drop if m2==2
drop m2 

lab define typ 1 "Unassigned" 2 "US Company or Corporation" 3"Foreign Company or Corporation" 4 "US Individual" 5"Foreign Individual" 6"US  Federal Government" 7"Foreign Government" 8" US County Government" 9"US State Government" 12" PI- US Company or Corporation" 13" PI- Foreign Company or Corporation" 14 "PI - US Individual" 15"PI - Foreign Individual" 17"PI - Foreign Government", modify

label values type typ

compress
}

*----------------------------------------*
*		Merge Assignee's  Location
*			(Patent-Inventor)
*----------------------------------------*
{
rename id assignee_id
rename location_id id

merge m:1 id using "$rawdata/USPTO/modify/tmp_loc.dta", gen (m3)

drop if m3==2
*drop locations without patents

drop m3

rename name_first first_name_asg_per
rename name_last last_name_asg_per
rename id loc_asg_id
rename type type_asg
rename city city_asg
rename country country_asg
rename latitude lat_asg
rename longitude lon_asg

tab first_assignee 
*6,563,095 unique patents

}

*----------------------------------------*
*	Keep Fist Assignee in sequence
*
*----------------------------------------*
{
 
keep if first_assignee==1
drop first_assignee

sort patent_id

rename patent_id patent

if $reduced==1 {
keep patent assignee_id loc_asg_id type_asg organization
}

if $reduced==0 {
label var loc_asg "Location Assignee"
label var city_asg "City Assignee"
label var country_asg "Country Assignee" 
label var lat_asg "Latitude Assignee"
label var lon_asg "Longitude Assignee"
label var first_name_asg_per "First Name if Assignee is Person"
label var last_name_asg_per "Last Name if Assignee is Person"
}

egen assignee =group(assignee_id)

label var assignee "Assignee (Numeric)"
label var type_asg "Type Assignee"
label var organization "Organization Namr"
label var patent "Patent ID"
label var assignee_id "Assignee ID (Str)"
label var loc_asg_id "ID Location Assignee"

compress

*--For Citation Data
preserve
keep patent assignee assignee_id
compress
save "$datasets/assignee_for_cit.dta", replace
restore

save "$datasets/first_assignee_uspto.dta", replace

}

}


************************************
*	2) Crating PatentsView_Main
*
*
************************************

/////////////////////////////////////
//////	All Patents Available Data
/////////////////////////////////////

{
use "$rawdata/USPTO/patent.dta", clear

keep id type number date

rename id patent_id

split date, parse(-)		

*fix dates
destring date1 date2 date3, replace
drop date
gen gdate=mdy(date2, date3, date1)
format gdate %td	
rename (date2 date3 date1) (gmonth gday gyear)

drop gday gmonth

compress

rename patent_id patent


*merge app date
merge 1:1 patent using "$datasets/appdate_uspto.dta", gen(m1)


*temporary dataset for citations
preserve
drop type number
drop gdate
compress
save "$datasets/patents_uspto_for_cit.dta", replace
restore

/* 21 patents dont have info on patent date*/

*Keep patents with 1) Application Dates 2)Inventor data
keep if m1==3
drop m1

*generate dummy for utility patent

gen type_pat=.

local i=0
levelsof type, local(l_type)

foreach y of local l_type{
local ++i
replace type_pat=`i' if type=="`y'"
label define dd `i'"`y'", modify
label values type_pat dd
}

drop type

if $reduced==1 {
keep patent gyear gdate appyear appdate type_pat
}

label var patent "Patent"
label var gyear "Grant Year"
label var gdate "Grant Date"
label var appyear "Application Year"
label var appdate "Application Date"
label var type_pat "Type Patent (6 classifications)"

compress

save "$datasets/patents_uspto.dta", replace

}

//////////////////////////////////////////////
/////	Merge Patent Info + Inventors
///////////////////////////////////////////

{

*Open patents+grant date
use "$datasets/patents_uspto.dta", clear

*merge inventors
merge 1:m patent using "$datasets/inventors_uspto.dta", gen (m2)
*823 not merged patents
keep if m2==3
drop m2

sort patent

}


//////////////////////////////////////////////
/////	Merge Inv-Patent + IPC3 info
///////////////////////////////////////////

{
merge m:1 patent using "$datasets/uspto_ipc3.dta", gen(m3)
*942,768 not merged observations
drop if m3==2
drop m3

if $reduced==1 {
drop section_ipc ipc_class ipc_version_indicator
}

label var subclass_ipc "Subclass IPC"
label var ipc3 "IPC3 Classification"

}

//////////////////////////////////////////////
/////	Merge Inv-Patent + Assignee Info
///////////////////////////////////////////

{
merge m:1 patent using "$datasets/first_assignee_uspto.dta", gen(m4)
*1,139,172 not merged observations on first assignee
drop if m4==2
drop m4

if $reduced==1 {
drop loc_inv_id loc_asg_id organization
}


}


//////////////////////////////////////////////
/////	Merge Other Classification Criteria
///////////////////////////////////////////

{

*1) USPC Current
merge m:1 patent using "$datasets/uspc_current_fixed.dta", gen(m5)
* 2,369,655 not matched
drop if m5==2
drop m5

*2) CPC Current
merge m:1 patent using "$datasets/cpc_current_fixed.dta", gen(m6)
* 1,292,703 not matched
drop if m6==2
drop m6


*3) NBER
merge m:1 patent using "$datasets/nber_categories.dta", gen(m7)
drop if m7==2
drop m7
*5,968,480 not matched

if $reduced==1 {
drop subclass_uspc group_cpc
}


if $reduced==0 {
label var type_asg "Type Assignee"
label var loc_asg_id "Location ID Assignee"
label var loc_inv_id "Location ID Inventor"
label var subclass_uspc "USPC Subclass"
label var category_nber "NBER Category"
label var group_cpc "CPC Group" 
label var section_cpc "CPC Section"
label var section_ipc "IPC Section"
label var ipc_class "IPC Class"
label var loc_asg "Location Assignee (Numeric)"
label var organization "Org. Assignee"
label var city_asg "City Assignee"
label var country_asg "Country Assignee"
label var lat_asg "Latitude Asignee"
label var lon_asg "Longitude Asignee"
label var ipc_version_indicator "IPC Version Indicator" 
}


label var patent "Patent ID"
label var inventor_id "Inventor ID"
label var gyear "Grant Year"
label var gdate "Grant Date"
label var appyear "Application Year"
label var appdate "Application Date"
label var invseq "Inventor Sequence"
label var ipc3 "IPC3 Classification"
label var assignee_id "Assignee ID"
label var section_cpc "Section CPC"
label var subsection_cpc "Subsection CPC"
label var category_nber "NBER Category"
label var subcategory_nber "NBER Subcategory"
label var mainclass_uspc "USPC Main Class"
label var subclass_ipc "Subclass IPC"
label var categ1 "Inventor ID - Numeric"
label var assignee "Assignee ID -Numeric"

compress


}


//////////////////////////////////////////////
/////	Merge Selected IPC
///////////////////////////////////////////

*Jeremy's IPC identification
{
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" , gen(non_selected_ipc)

tab ipc3 if non_selected_ipc==1

label var non_selected_ipc "Non-Selected IPC - Jeremy"

replace non_selected_ipc=0 if non_selected_ipc==3

label define dd 1 " Not Matched (Non-Selected)" 0"Selected (Matched)", modify
label values non_selected_ipc
 
}



////////////////////////////////////////////////////////////////
///////	Keep Relevant Periods and Save First PatentsView Main
/////////////////////////////////////////////////////////////////

{
*93,320 patents with appyear> 1975 
count if appyear<1975

*Keep only appyear> 1975
keep if appyear>1974 & appyear!=.

compress

save "$datasets/Patentsview_Main.dta", replace

}

//////////////////////////////////////////
///	TempFiles for Datasets for Citations
///////////////////////////////////////////

{

use "$datasets/Patentsview_Main.dta", clear
keep assignee_id patent
duplicates drop patent, force
compress
save "$datasets/tmp_first_assignee_uspto.dta", replace

use "$datasets/Patentsview_Main.dta", clear
keep patent ipc3
duplicates drop patent, force
compress
save "$datasets/tmp_uspto_ipc3.dta", replace

use "$datasets/Patentsview_Main.dta", clear
keep patent appyear gdate
duplicates drop patent, force
compress
save "$datasets/tmp_patents_uspto_2.dta", replace


use "$datasets/Patentsview_Main.dta", clear
keep patent inventor_id invseq categ1
compress
save "$datasets/tmp_inventors_uspto.dta", replace

}

***Run in server for Citing data

//////////////////////////////
//////	Create Relevant Variables
/////////////////////////////////

{

use "$datasets/Patentsview_Main.dta", clear

*---Dummy for 90's
gen is90s=.
replace is90s=0 if appyear>=1980 & appyear<=1990
replace is90s=1 if appyear>=1991 & appyear<=2000

***time to build:
rename gdate date

*---by inventor id (categ1), set counter for each of the different patents made
bys categ1 (date patent): gen patnumpp1=_n

xtset categ1 patnumpp1

*--Lag (Difference actual Patent and the one before)
gen ttb1=date-L.date

*--Lag (Difference actual Patent and the next one)
gen ttb2=F.date-date


*--Average Time to Built
gen i_ttb=(ttb1+ttb2)/2
replace i_ttb=ttb1 if ttb2==.
replace i_ttb=ttb2 if ttb1==.


*--Average Time to Built a Patentt
bys patent: egen m_ttb=mean(i_ttb)

*Generate Team Size
bys patent: gen tsize=_N

*--group firms
replace assignee=0 if assignee==.


label var non_selected_ipc "Non Selected IPC"
label var assignee "Assignee code (Numeric)"
label var is90s "Indicator of 90s decade"
label var patnumpp1 "Running number of patents by inventor"
label var ttb1 " Time to build since last patent"
label var ttb2 "Time to build next patent" 
label var i_ttb "Average time to build (last and next patent)"
label var m_ttb "Mean of time to build by patent"
label var tsize  "Team size"


*Assignee - Organization or person?
	
		gen per0=strpos(assignee_id,"per_")
		gen per=cond(per0>0,1,cond(per0==0,0,.))
		
		gen org0=strpos(assignee_id,"org_")
		gen org=cond(org0>0,1,cond(org0==0,0,.))
		
		tab per org if assignee_id!=""
		
*dummy if assignee is organization
		gen d_asg_org=. if assignee_id!=""
		replace d_asg_org=1 if org==1 & assignee_id!=""
		replace d_asg_org=0 if per==1 & assignee_id!=""
		drop per* org*
		
		label var d_asg_org "Dummy if assignee is Organization"
		
}


//////////////////////////
//////	Merge Citation Data
//////////////////////////////

{


*1)Merge Life Citations

merge m:1 patent using "$datasets/life_cit_IPC1_all.dta"
drop _m

drop tech_cat patent_age
rename exp_cit exp_cit_adj

/*
*2) Merge Adjusted Cit and InvhCite measures

merge 1:1 patent categ1 using "$datasets/citation_adjusted_all.dta", gen(cit_adj)
drop if cit_adj==2
drop cit_adj
**adjust citations: expected ctitations/ mean of time to build a patent

gen ttb_cit=exp_cit/m_ttb

*Transformation of Adjusted Cites
gen invh_ttb=ln(ttb_cit+(ttb_cit^2+1)^0.5)


* For citation measures
label var invh_cit "Inverse hyperbolic sine of expected citations"
label var exp_cit "Expected Forward Citations (Normalized)"
label var exp_cit_adj "Expected Forward Citations (Adjusted)"
label var f_cit  "Forward Citations (20 years)"
label var cit3  " 3-year Forward Citations (Adjusted)"
label var cit5  "5-year Forward Citations (Adjusted)"
label var ttb_cit "Expected forward citations divided time to build"
label var invh_ttb "Inverse hyperbolic sine of expected citations"

drop totpat

*/
*3)Merge Forward Citations (Unadjusted)
merge m:1 patent using "$datasets/f_cit_all.dta"
drop _m

*4) Merge Backward Citations (Unadjusted)
merge m:1 patent using "$datasets/b_cit_all.dta"
drop if _m==2
drop _m


*5) Merge Survival JP

merge m:1 patent using "$main/RA/from server/output/datasets/patent_max_survive.dta", gen(m_surv)
drop if m_surv==2
drop m_surv

label var survive "Survival"



*6) Merge Survival SC

merge m:1 patent categ1 using "$main/RA/from server/output/datasets/survival_PV.dta", gen(m_surv_sc)
drop if m_surv_sc==2
drop m_surv_sc


compress
save "$datasets/Patentsview_Main.dta", replace

}

//////////////////////////////////////
/////	Identify Rare IPC3 classes
////////////////////////////////////
{

*dummy for identified ipc3
gen identified_ipc=1 if ipc3!=""
	replace identified_ipc=0 if ipc3==""
label var identified_ipc "=1 if identified IPC"

*ipc3
bys patent: gen dpatent=1 if patent[_n]!=patent[_n-1] & identified_ipc==1
bys appyear ipc3: egen n_ipc3=total(dpatent) if identified_ipc==1


*Create dummy of rare ipc3 all years
bys ipc3: egen max_n_ipc3=max(n_ipc3) if identified_ipc==1
gen rare_ipc3_all=1 if max_n_ipc3<100
	replace rare_ipc3_all=0 if rare_ipc3==.
label var rare_ipc3 "IPC3 With Less Than 100 Patents All Years"

*16,864 rare patents

*Create dummy of rare ipc3 any years
bys ipc3: egen min_n_ipc3=min(n_ipc3) if identified_ipc==1
gen rare_ipc3_any=1 if min_n_ipc3<=100 & identified_ipc==1
	replace rare_ipc3_any=0 if rare_ipc3_any==. & identified_ipc==1
label var rare_ipc3_any "IPC3 With Less Than 100 Patents in Any Years"

*Create dummy of rare ipc3 in sample years
bys ipc3: egen mean_n_ipc3=mean(n_ipc3) if identified_ipc==1
gen rare_ipc3_mean=1 if mean_n_ipc3<=100 & identified_ipc==1
	replace rare_ipc3_mean=0 if rare_ipc3_mean==. & identified_ipc==1
label var rare_ipc3_mean "IPC3 With Less Than 100 Patents on Average"

drop dpatent n_ipc3 min_n_ipc3 max_n_ipc3 mean_n_ipc3

}


///////////////////////////
//////	Rename
//////////////////////////

rename assignee_id asgnum

*Keep patents up to 2015
keep if appyear<=2015

compress

///////////////////
//////Save Final Version of the Data
////////////////////

save "$datasets/Patentsview_Main.dta", replace

///////////////////////////////////////////////////////////////
//////// Create Patent-Level Data
/////////////////////////////////////////////////////////////

{

duplicates drop patent, force

drop inventor_id invseq categ1

save "$datasets/Patentsview_lev_dataset.dta", replace


}