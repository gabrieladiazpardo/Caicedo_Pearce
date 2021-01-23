******************************************************
*
*				PatentsView Data
*
******************************************************

//////////////////////////////////////
//1. Import IPC Classification
/////////////////////////////////////

{
*IPCs - International Patent Classification data for all patents (as of publication date)

*Aim: Retrieve, for each available patent, the classification level and section to create ipc3 - a unique 3-digit classification

insheet using "$raw/ipcr.tsv",clear

unique patent_id //6,936,056

keep patent_id classification_level section ipc_class


gen ipc3=section+ipc_class

gen char=strlen(ipc3)

unique patent_id if char==3

duplicates drop patent_id, force


save "$datasets/uspto_ipc3.dta",replace

}


////////////////////////////////////////////////////////////////////////////////////////////
//2. Firms Harmonization (PDPASS FIRMS) - Assignee  From 1969-2015
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

save "$datasets/uspto_assignee_harmonized.dta", replace

}


//////////////////////////////////////
//3. Application date
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

save "$datasets/appdate_uspto.dta", replace


}
///////////////////////////////////////////////////////////////
//2. Clean Data from PatentsView (Patent, Inventor, Assignee)
/////////////////////////////////////////////////////////////

{




/////1. Import Assignee Information. Each patent has several assignees according to this data.


*use "$rawdata/USPTO/patent_assignee.dta", clear

*tempfile uspto_patent_assignee

*duplicates tag patent_id, generate(dup)

*duplicates drop patent_id, force

*compress

*save "`uspto_patent_assignee'", replace




/////2. Patent Data

use "$rawdata/USPTO/patent.dta", clear

drop filename
rename id patent_id

unique patent_id 

merge 1:m patent_id using "$rawdata/USPTO/patent_inventor.dta", gen (m1)

drop in 1/1

unique patent_id if m1==3
*7,430,063 unique patents have information on inventor level from 7,430,875 that were initially.

*only keep patents with data on inventors
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

keep patent_id country inventor_id location_id gyear gmonth gday gdate
}

///////////////////////////////////////////////////////////////
//3. Merge IPC3 and Patent Data
/////////////////////////////////////////////////////////////

{
merge m:1 patent_id using "$datasets/uspto_ipc3.dta", gen(m3)

* 940,217 obs did't have information on ipc3 data

*unique patent_id if char==3 //6,671,965 unique patents with ipc3

*drop patents that come from ipc3 
drop if m3==2


drop classification_level section ipc_class

}



///////////////////////////////////////////////////////////////
//4. Merge Firms Harmonization and Patent Data
/////////////////////////////////////////////////////////////

{
merge m:1 patent_id using "$datasets/uspto_assignee_harmonized.dta", gen(m4)


*unique patent_id if m4==3 // 5800992 have info on firm
*unique patent_id if char==3 & m4==3 // 5,448,543 -with ipc3 and info from firm


*drop patents with only info from firm

drop if m4==2 // 515,833 obs or patents are dropped

compress

}



///////////////////////////////////////////////////////////////
//5. Merge Firms Harmonization and Patent Data
/////////////////////////////////////////////////////////////


merge m:1 patent_id using "$datasets/appdate_uspto.dta", gen(m5)

/* not matched 810 from using*/




*-------------------------------------*
*		Necessary Drops
*
*--------------------------------------*


*rename patent to merge to uscites
rename patent_id patent

*1) FIRMS THAT MERGED FIRM CODE AND HAVE IPC OF 3 DIGIRS

keep if char==3 & m4==3

*2) FIRMS WITH ACTUAL FIRM CODE
drop if assignee_code=="      0" // 948,421 obs deleted


unique patent 
////  4,739,386 unique patents

compress


drop m3 m4 m5

drop assignee_code

drop gday gmonth appmonth appday

drop char

save "$datasets/uspto_patent_inventor_ipc3.dta", replace

}




///////////////////////////////////////////////////////////////
//5. Patent Level
/////////////////////////////////////////////////////////////

{


duplicates drop patent, force

drop inventor_id location_id 


**********************
*	Final Drops
*
**********************



save "$datasets/uspto_patent_ipc3.dta", replace

}

 //////////////////////
 ////6. ALL Patents in USPTO
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


