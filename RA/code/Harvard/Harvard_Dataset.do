******************************************************
*				Harvard Data
*
******************************************************

//////////////////////////////////////
//1. Import Dates for Patents -
/////////////////////////////////////

{

insheet using "$raw/patent.csv", clear

**keep patent and year is all we need for this operation (note time between app and grant will matter)

keep patent appyear appdate gdate gyear
		
*--Grant Date
split gdate, parse(-)		
destring gdate1 gdate2 gdate3, replace
gen grant_date=mdy(gdate2, gdate3, gdate1)
format grant_date %td	
drop gdate1 gdate2 gdate3
	
	
*--App Date
split appdate, parse(-)		
destring appdate1 appdate2 appdate3, replace
gen app_date=mdy(appdate2, appdate3, appdate1)
format app_date %td	
drop appdate1 appdate2 appdate3	

drop gdate appdate


order patent appyear app_date gyear grant_date


gen letter_pat=(missing(real(patent)))

gen patent_id=patent
replace patent_id=substr(patent,2,8) if letter_pat==0


*unique patent_id if letter_pat==0 
*unique patent_id if letter_pat==1

compress

rename patent patstr
rename patent_id patent

keep patstr appyear app_date gyear grant_date patent

rename app_date appdate
rename grant_date gdate
order patent patstr

save "$datasets/Harvard_Patent.dta", replace


}

//////////////////////////////////////
//2. Import Inventor Dataset
/////////////////////////////////////

*a) Data-set for individuals-patent
{
***INDIVIDUALS -- individual, location, USPTO class, assignee (HBS), inventor order

insheet using "$raw/invpat.csv", clear


gen letter_pat=(missing(real(patent)))

gen patent_id=patent
replace patent_id=substr(patent,2,8) if letter_pat==0


keep city state country invseq asgnum patent lat lon letter_pat patent_id lower upper class patent_id letter_pat


**lower = lower threshold
egen categ1=group(lower)
egen categ2=group(upper)


split class, p("/")

gen uspto_class=class1


keep city state country invseq categ1 categ2 asgnum uspto_class patent lat lon letter_pat patent_id class

rename patent patstr
rename patent_id patent

drop letter_pat

order patent patstr

save "$datasets/Harvard_Individuals.dta", replace


}

 //////////////////////////////////////
//3. Import Assignee Info Dataset
/////////////////////////////////////

{
insheet using "$rawdata/Harvard/assignee.csv", clear
 
gen letter_pat=(missing(real(patent)))

gen patent_id=patent
replace patent_id=substr(patent,2,8) if letter_pat==0


tab asgseq
bys patent: egen first_asg=min(asgseq)

sort patent

keep if asgseq==first_asg

rename state state_asg

drop  asgseq nationality residence first_asg letter_pat state

rename patent patstr
rename patent_id patent
order patent patstr
rename city city_asg
rename country country_asg

compress

save "$datasets/Harvard_Patent_Assignee.dta", replace

 }
 
///////////////////////////////////
/////	Merges
///////////////////////////////////
 {
////////////////////////////////////////
////	Merging-Inventor Patent Data
////////////////////////////////////////
 
use "$datasets/Harvard_Patent.dta", clear
merge 1:m patent patstr using "$datasets/Harvard_Individuals.dta", gen(m_inv)
drop m_inv

drop if appyear==.


//////////////////////////////
///	Merge Assignee Info
//////////////////////////////

merge m:1 patent patstr using "$datasets/Harvard_Patent_Assignee.dta", gen(m_asg)
 *395,327 patent-inv without info 
drop if m_asg==2
egen asgid=group(asgnum)
drop m_asg

////////////////////////////////////////////////////////////
///	Merge IPC3 Codes from PatentsView (Harvard doesnt have)
////////////////////////////////////////////////////////////

merge m:1 patent using "$datasets/uspto_ipc3.dta", gen(m_ipc)
*942,788 not merged observations
drop if m_ipc==2

drop m_ipc

label var patent "Patent-ID"
label var patstr "Patent String"
label var appyear "Application Year"
label var appdate "Application Date"
label var gyear "Granted Year"
label var gdate "Granted Date"
label var city "Inventor - City"
label var state "Inventor - State"
label var country "Inventor - Country"
label var lat "Inventor - Latitude"
label var lon "Inventor - Longitude"
label var invseq "Inventor Sequence"
label var asgnum "Assignee number (str)"
label var class "Class Patent"
label var categ1 "Inventor ID (Lower)"
label var categ2 "Inventor ID (Upper)"
label var uspto_class "USPTO Class"
label var asgtype "Assignee Type"
label var assignee "Assigne Name"
label var asgid "Assignee ID (Numeric)"
label var ipc3 "IPC3"
label var subclass_ipc "IPC- Subclass"


*DO NOT RUN This Lines!
*drop section_ipc ipc_class ipc_version_indicator
*drop gyear appdate class asgtype assignee

compress

*! Do not run this line
*drop city state country lat lon categ2 uspto_class city_asg country_asg subclass_ipc

save "$datasets/Harvard_Dataset.dta", replace

}


//////////////////////////////////////////
///	TempFiles for Datasets for Citations
///////////////////////////////////////////

{
preserve
keep patent categ1 invseq
save "$datasets/tmp_Individuals_Harvard.dta", replace
restore

preserve
keep patent asgnum asgid
duplicates drop patent, force
drop if asgid==.
rename asgnum assignee_id
drop asgid
save "$datasets/tmp_Assignee_Harvard.dta", replace
restore

preserve
keep patent appyear gdate
duplicates drop patent, force
drop if appyear==.
save "$datasets/tmp_Patent_Harvard.dta", replace
restore

preserve
keep patent ipc3
duplicates drop patent, force
drop if ipc3==""
save "$datasets/tmp_ipc3_Harvard.dta", replace
restore

}
 
 //////////////////////////////
//////	Create Relevant Variables
/////////////////////////////////

{
use "$datasets/Harvard_Dataset.dta", clear

rename asgid assignee
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

**group firms
replace assignee=0 if assignee==.


label var assignee "Assignee code (Numeric)"
label var is90s "Indicator of 90s decade"
label var patnumpp1 "Running number of patents by inventor"
label var ttb1 " Time to build since last patent"
label var ttb2 "Time to build next patent" 
label var i_ttb "Average time to build (last and next patent)"
label var m_ttb "Mean of time to build by patent"
label var tsize  "Team size"

}


//////////////////////////////////////////////
/////	Merge Selected IPC
///////////////////////////////////////////

*identificador de cuales ipc's se dejan
{
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" , gen(non_selected_ipc)

tab ipc3 if non_selected_ipc==1

label var non_selected_ipc "NonSelected IPC"

replace non_selected_ipc=0 if non_selected_ipc==3

label define dd 1 " Not Matched (Non-Selected)" 0"Selected (Matched)", modify
label values non_selected_ipc
 
}


//////////////////////////////////////
/////	Identify Troubuling Patents
////////////////////////////////////
{

*ipc3
bys patent: gen dpatent=1 if patent[_n]!=patent[_n-1]
bys appyear ipc3: egen n_ipc3=total(dpatent)
bys ipc3: egen max_n_ipc3=max(n_ipc3)

*Create dummy of rare ipc3
gen rare_ipc3=1 if max_n_ipc3<100
	replace rare_ipc3=0 if rare_ipc3==.
label var rare_ipc3 "IPC3 With Less Than 100 Patents per Year"

drop dpatent n_ipc3 max_n_ipc3

*16,864 rare patents

compress

}


//////////////////////////
//////	Merge Citation Data
//////////////////////////////

{

*1)Merge Life Citations

merge m:1 patent using "RA/from server/output/datasets/life_cit_IPC1_Harvard.dta"
drop _m

drop tech_cat patent_age
rename exp_cit exp_cit_adj

*2) Merge Adjusted Cit and InvhCite measures

*merge 1:1 patent categ1 using "RA/from server/output/datasets/citation_adjusted_Harvard.dta", gen(cit_adj)
*drop if cit_adj==2
*drop cit_adj
**adjust citations: expected ctitations/ mean of time to build a patent

*gen ttb_cit=exp_cit/m_ttb

*Transformation of Adjusted Cites
*gen invh_ttb=ln(ttb_cit+(ttb_cit^2+1)^0.5)


* For citation measures
*label var ttb_cit "Expected forward citations divided time to build"
*label var invh_ttb "Inverse hyperbolic sine of expected citations"
*label var invh_cit "Inverse hyperbolic sine of expected citations"
*label var exp_cit "Expected Forward Citations (Normalized)"


label var exp_cit_adj "Expected Forward Citations (Adjusted)"
label var f_cit  "Forward Citations (20 years)"
label var cit3  " 3-year Forward Citations (Adjusted)"
label var cit5  "5-year Forward Citations (Adjusted)"


*3)Merge Forward Citations (Unadjusted)
*merge m:1 patent using "$datasets/f_cit_Harvard.dta"
*drop _m

*4) Merge Backward Citations (Unadjusted)
merge m:1 patent using "$datasets/b_cit_Harvard.dta"
drop if _m==2
compress
drop _m


}


///////////////////
//////Save Final Version of the Data
////////////////////

tab appyear
drop if appyear==.
keep if appyear>=1975 & appyear<=2010
save "$datasets/Harvard_Dataset.dta", replace

}


///////////////////////////////////////////////////////////////
//////// Create Patent-Level Data
/////////////////////////////////////////////////////////////

{

duplicates drop patent, force

drop invseq categ1

save "$datasets/Harvard_pat_lev_dataset.dta", replace


}

