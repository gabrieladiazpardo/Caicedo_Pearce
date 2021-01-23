*----------------------------------------------------*
*
*				USPTO Data - PatentsView
*		Create Dataset with all info. in USPTO
*
*----------------------------------------------------*

///////////////////////////////////////////////
/////// Import USPTO Rawdata
////////////////////////////////////////////

{
//////////////////////////////////////
//1A. Import IPC Classification
/////////////////////////////////////

{
*IPCs - International Patent Classification data for all patents (as of publication date)

*Aim: Retrieve, for each available patent, the classification level and section to create ipc3 - a unique 3-digit classification

insheet using "$raw/ipcr.tsv",clear

unique patent_id //6,936,056

keep patent_id section ipc_class subclass subgroup

tab ipc_class

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

gen ipc3=section+ipc_class

duplicates drop patent_id, force

*reports if ipc class contains, non numeric characters. (shouldn't)
gen nd=(missing(real(ipc_class)))

drop if nd==1 /// 163 where dropped since ipc class contained non-numeric characters

*verify all ipc3 are 3 digits long
gen char=strlen(ipc3)

*keep relevant vars
keep patent_id ipc3 subclass

rename patent_id patent


save "$datasets/uspto_ipc3.dta",replace

}

////////////////////////////////////////////////////////////////////////////////////////////
//1B. Import Firm Harmonization Data (PDPASS FIRMS) - Assignee  From 1969-2015
///////////////////////////////////////////////////////////////////////////////////////////

*-----Source: USPTO https://www.uspto.gov/web/offices/ac/ido/oeip/taf/data/misc/data_cd.doc/assignee_harmonization/cy2015/

{
****Fix PDPASS FIRMS 


insheet using "$rawdata/USPTO/PN_ASG_UPRD_69_15.txt",clear
rename v1 assignee
generate splitat=strpos(assignee," ")

list assignee if splitat==0

generate str1 patentnumber=" "
replace patentnumber=substr(assignee,1,splitat-1)

generate str1 assignee_number=""
replace assignee_number=substr(assignee,splitat+1,.)

drop splitat

generate splitat=strpos(assignee," ")
gen assignee_number2=substr(assignee_number,1,splitat-1)
gen assignee_number3=substr(assignee_number,splitat+1,.)

keep patentnumber assignee_number2 assignee_number3

rename assignee_number2 assignee_code
rename assignee_number3 assignee_harmonized

rename patentnumber patent_id


*gen miss assignee code
gen miss_assign=1 if assignee_code=="      0"
replace miss_assign=0 if miss_assign==.

rename patent_id patent

drop assignee_harmonized

duplicates drop patent, force

save "$datasets/uspto_assignee_harmonized.dta", replace

}


//////////////////////////////////////
//1C. Import Application date
/////////////////////////////////////

{
import delimited "$rawdata/USPTO/application.tsv", stringcols(2 3 4) clear 

drop id series_code number country
rename date appdate
split appdate, parse(-)		
destring appdate1 appdate2 appdate3, replace
gen app_date=mdy(appdate2, appdate3, appdate1)
format app_date %td	
rename (appdate2 appdate3 appdate1) (appmonth appday appyear)
drop appdate
rename app_date appdate
compress

drop if appyear>2020
save "$datasets/appdate_uspto.dta", replace


}


////////////////////////////////////////////////////////////////////////////
//1D.Import Data from PatentsView (Patent, Inventor) - Creation Pat-Inv Level
/////////////////////////////////////////////////////////////////////////////

{


/*

Important: Patents left in uspto_patent_inventor have 1)Inventor ID 2)Application date (patents without inventor or app date will be dropped)

*/

use "$rawdata/USPTO/patent.dta", clear

drop filename
rename id patent_id

*unique patent_id 

merge 1:m patent_id using "$rawdata/USPTO/patent_inventor.dta", gen (m1)

drop in 1/1

*812 patents dont have information on INVENTOR.

*only keep patents with data on inventors (drop 825 patents)
keep if m1==3

*merge m:1 patent_id using "`uspto_patent_assignee'", gen (m2)

*7,430,063 unique patents
*17,992,709 inventor-patents obs.


split date, parse(-)		

*fix dates
destring date1 date2 date3, replace
drop date
gen gdate=mdy(date2, date3, date1)
format gdate %td	
rename (date2 date3 date1) (gmonth gday gyear)

*Patents available from 1976 to 2020

*drop dup

sort patent_id

keep patent_id country inventor_id location_id gyear gdate

merge m:1 patent_id using "$datasets/appdate_uspto.dta", gen(m2)

/* 810 patents have information on application date, but not inventor*/
/* 38 observations have information on inventor, but not in application date*/


*Keep patents with 1) Application Dates 2)Inventor data
keep if m2==3

drop appmonth appday m2 country

rename patent_id patent


duplicates drop inventor_id patent, force

br if inventor_id=="" 
*42 observations with blank/missing inventor id. 
*seem like solo patents

*Santiago: Should we drop them?

compress

save "$datasets/uspto_patent_inventor.dta", replace


}


}

/////////////////////////////////////////////////////
//////// Merging Data to Patent-Inventor Dataset
/////////////////////////////////////////////////////

{

*open inventor-patent
use "$datasets/uspto_patent_inventor.dta", clear


merge m:1 patent using "$datasets/uspto_ipc3.dta", gen(m1)
label var m1 "Merge Patent-Inventor with IPC3 code"

/* Not matched - OBSERVATIONS (not patents) - 940,545 */

merge m:1 patent using "$datasets/uspto_assignee_harmonized.dta", gen(m2)
label var m2 "Merge Patent-Inventor with Harm Assignee Code"

/* Not matched - OBSERVATIONS  (not patents) - 5,105,531 */

label var patent "Patent ID"
label var inventor_id "Inventor ID"
label var location_id "Inventor Location"
label var gyear "Grant Year"
label var gdate "Grant Date"
label var appyear "Application Year"
label var appdate "Application Date"
label var subclass "IPC subclass"
label var ipc3 "IPC Code - 3 Digits"
label var assignee_code "Assignee Code"
label var miss_assign "=1 if Assignee Code reported as zero"

compress

save "$datasets/uspto_dataset.dta", replace

}


**************************************** Added by SC**************************************

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
//////// More Cleaning
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

use "$datasets/uspto_dataset.dta", clear

*Keep only appyear> 1975
keep if appyear>1975 & appyear!=.


bys patent: gen dpatent=1 if patent[_n]!=patent[_n-1]

bys appyear ipc3: egen n_ipc3=total(dpatent)
bys ipc3: egen max_n_ipc3=max(n_ipc3)

*Create dummy of rare ipc3
gen rare_ipc3=1 if max_n_ipc3<100
	replace rare_ipc3=0 if rare_ipc3==.
label var rare_ipc3 "IPC3 With Less Than 100 Patents per Year"

drop dpatent n_ipc3 max_n_ipc3 m*

save "$datasets/uspto_dataset.dta", replace

///////////////////////////////////////////////////////////////
//////// Create Patent-Level Data
/////////////////////////////////////////////////////////////

{

duplicates drop patent, force

drop inventor_id location_id 

br if patent==""

save "$datasets/uspto_patent_lev_dataset.dta", replace

}



