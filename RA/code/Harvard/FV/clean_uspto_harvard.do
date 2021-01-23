******************************************************
*
*				PatentsView Data
*
******************************************************

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

gen nd=(missing(real(ipc_class)))

drop if nd==1 /// 163 where dropped since ipc class contained non-numeric characters

gen char=strlen(ipc3)

keep patent_id ipc3 subclass

rename patent_id patent


save "$datasets/uspto_ipc3.dta",replace

}


////////////////////////////////////////////////////////////////////////////////////////////
//1B. Firms Harmonization (PDPASS FIRMS) - Assignee  From 1969-2015
///////////////////////////////////////////////////////////////////////////////////////////

*-----Source: USPTO https://www.uspto.gov/web/offices/ac/ido/oeip/taf/data/misc/data_cd.doc/assignee_harmonization/cy2015/

{
****PDPASS FIRMS 


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
import delimited "$datasets/application.tsv", stringcols(2 3 4) clear 

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


///////////////////////////////////////////////////////////////
//2A. Clean Data from PatentsView (Patent, Inventor)
/////////////////////////////////////////////////////////////

{


use "$rawdata/USPTO/patent.dta", clear

drop filename
rename id patent_id

*unique patent_id 

merge 1:m patent_id using "$rawdata/USPTO/patent_inventor.dta", gen (m1)

drop in 1/1

*812 patents dont have information on INVENTOR.

*only keep patents with data on inventors (drop 812 patents)
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
*42 observations with missing inventor id. 
*seem like solo patents

*Santiago: Should we drop them?

compress


save "$datasets/uspto_patent_inventor.dta", replace


}


///////////////////////////////////////////////////////////////
//2B. Patent Level
/////////////////////////////////////////////////////////////

{


duplicates drop patent, force

drop inventor_id location_id 

drop if patent==""

save "$datasets/uspto_patent.dta", replace

}










//////////////////////
////1D. ALL Patents in USPTO
///////////////////

{
use "$rawdata/USPTO/patent.dta", clear

drop filename
rename id patent_id

unique patent_id 


split date, parse(-)		

*fix dates
destring date1 date2 date3, replace
drop date
gen date=mdy(date2, date3, date1)
format date %td	
rename (date2 date3 date1) (month day year)

*Patents available from 1976 to 2020

*drop dup

sort patent_id

rename patent_id patent

keep patent year date

drop in 1/1

save "$datasets/all_patent_uspto.dta", replace

}













***********************************************************
*	Since Firms are only available up to 2015, info. on patents until that year
*
*
**************************************************************






******************************************************
*
*				Harvard Data
*
******************************************************

//////////////////////////////////////
//1. Import Dates for Patents
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


unique patent_id if letter_pat==0 //3984771 numeric patents
unique patent_id if letter_pat==1 //259201 non numeric patents

compress

rename patent patstr
rename patent_id patent


keep patstr appyear app_date gyear grant_date patent

save "$datasets/Harvard_Patent.dta", replace


}


//////////////////////////////////////
//2. Inventor-Patent Dataset
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


merge m:1 patstr patent using "$datasets/Harvard_Patent.dta", gen(m1)

compress

drop m1 letter_pat

save "$datasets/Harvard_Individuals_Dates.dta", replace


}


*b) Data-set for firms

{

use "$datasets/Harvard_Individuals_Dates.dta", clear


duplicates drop patent, force
keep patent patstr asgnum


gen miss_code=1 if asgnum==""
replace miss_code=0 if asgnum!=""

compress

*-This data set is patent - assignee code (firm code) - 3984771

save "$datasets/Harvard_Patent_Asgnum.dta", replace


}


//////////////////////////////////////
//3. Patent Class Dataset (Not essential)
/////////////////////////////////////

{

insheet using "$rawdata/Harvard/class.csv", clear

gen letter_pat=(missing(real(patent)))

gen patent_id=patent
replace patent_id=substr(patent,2,8) if letter_pat==0
 
}
 
 //////////////////////////////////////
//4. Assignee Dataset
/////////////////////////////////////

{
insheet using "$rawdata/Harvard/assignee.csv", clear
 
gen letter_pat=(missing(real(patent)))

gen patent_id=patent
replace patent_id=substr(patent,2,8) if letter_pat==0

duplicates tag patent, gen(dup)

sort patent

br if dup>0

keep if asgseq==0

drop dup 

save "$datasets/Harvard_Patent_Assignee.dta", replace

 }
 
///////////////////////////////////////
/////////5. Other Citation Data
////////////////////////////////////////
 
{

use "$rawdata/Harvard/basicbib.dta", clear

unique patent

gen letter_pat=(missing(real(patent))) // 12,770 have patent id with letter
*all digits patent = 7 


}

///////////////////////////////////////
/////////6. Merging Harvard Data
////////////////////////////////////////
{

use "$datasets/Harvard_Individuals_Dates.dta"
 
 rename patent str_patent
 rename patent_id patent
 
 merge m:1 patent using "$rawdata/Harvard/basicbib.dta", gen (m2)

 keep if m2==3
 
 ******If we merge basic bib, 3983048 unique patents.
 
 
}



















