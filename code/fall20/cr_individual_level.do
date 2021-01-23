***MAIN DATA CLEANING FOR CAICEDO-PEARCE PROJECT

***Date updated: Sept 4, 2020



global main "/Users/JeremyPearce/Dropbox"


global data "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data"
global raw "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data/rawdata"
global output "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data/output"
***This data comes from HBS inventor data where file was too big



**STARTED WITH INVENTOR NAMES, NOW ONTO patent data
**this comes from harvard NAMES: https://dataverse.harvard.edu/dataset.xhtml?persistentId=hdl:1902.1/15705
****FIRMS: https://www.uspto.gov/web/offices/ac/ido/oeip/taf/data/misc/data_cd.doc/assignee_harmonization/cy2014/
*****Summary of the data: https://www.researchgate.net/publication/228264129_National_Bureau_of_Economic_Research_Patent_Database_Data_Overview

*YEARS
insheet using "$raw/patent.csv", clear
**keep patent and year is all we need for this operation (note time between app and grant will matter)
keep patent appyear appdate gdate gyear
gen grant_date=date(gdate, "MDY")
gen app_date=date(appdate, "MDY")
drop gdate appdate
destring patent, force replace
drop if patent ==.

save "$output/dates_CP.dta"

/*
*FIRMS/USPTO CLASSES
*partial: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SJPHLG
use "$data/wrkdata/basicbib14.dta", clear
**keep patent and year is all we need for this operation (note time between app and grant will matter)
keep class assignee patent st_country asstype
destring patent, force replace
drop if patent ==.
save "$output/firms_CP.dta"

*/



*IPCs
*https://www.patentsview.org/download/
insheet using "$raw/ipcr.tsv",clear
**keep patent and year is all we need for this operation (note time between app and grant will matter)
keep patent_id classification_level section ipc_class
destring patent, force replace
keep if patent~=.
gen ipc3=section+ipc_class
gen char=strlen(ipc)
keep if char==3
keep patent ipc3
save "$output/patent_ipc3.dta",replace



***INDIVIDUALS -- individual, location, USPTO class, assignee (HBS), inventor order
insheet using "$raw/invpat.csv", clear
destring patent, force replace
keep if patent==.
**lower = lower threshood
egen categ1=group(lower)
egen categ2=group(upper)
split class, p("/")
destring class1, gen(uspto_class)
keep city state country invseq categ1 categ2 asgnum uspto_class patent lat lon
save "$output/individuals_CP.dta", replace

duplicates drop patent, force
keep patent asgnum
save "$output/firms_CP.dta", replace





****PDPASS FIRMS -- https://www.uspto.gov/web/offices/ac/ido/oeip/taf/data/misc/data_cd.doc/assignee_harmonization/cy2014/
insheet using "$raw/pn_asg_uprd_69_14.txt",clear
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
save "$output/firms2_CP.dta", replace









****CITATIONS -- honestly not sure about the diff bbetween online and local source. https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SJPHLG

use "$data/uscites2015.dta", clear


destring patent, force replace
***merge with relevant patent info:
**patent for string merge, patentnumer for numeric merge
merge m:1 patent using "$output/dates_CP.dta"

keep if _m==3
drop _merge
***USE FIRM TO DROP SELF-CITATIONS
merge m:1 patent using "$output/firms_CP.dta"
keep if _m==3
drop _m

rename asgnum citing_pdp
rename patent citing

rename cited patent
merge m:1 patent using "$output/firms_CP.dta"
rename asgnum cited_pdp
drop if _m==1
drop _m
drop if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~="0"
**we can't drop caateg
*drop if cited_categ=citing_categ

rename appyear citing_appyear


merge m:1 patent using "$output/dates_CP.dta", gen(ay_merge2)
*keep if ay_merge2==3
rename appyear cited_appyear
drop if citing==. | patent==.

merge m:1 patent using "$output/patent_ipc3.dta" , keepusing(ipc3)


rename patent cited

**Now we have appyear and IPC4: recall goal--do citation truncation using IPC4

***INTL CITATION SAME IDEA:



bysort cited citing_appyear:gen f_cityr=_N
gen dummy=1

bysort cited:egen forward_cit_total=total(dummy)
rename citing_appyear citingyear
gen ipc1=substr(ipc3,1,1)
keep f_cityr forward_cit_total cited citingyear ipc1


duplicates drop

save "$output/Citation_event_time_ipc.dta",replace






****BUILDING SKILLS BASED ON MERGED COMPONENTS:
use "$output/individuals_CP.dta", clear

merge m:1 patent using "$output/citations_CP.dta"
drop _m
/*
merge m:1 patent using "$output/technology_CP.dta"
drop _m

merge m:1 patent using "$output/dates_CP.dta"
drop _m
*/

bys categ1 (date patent): gen patnumpp1=_n
xtset categ1 patnumpp1
gen ttb=date-L.date



gen ptn=1
*replace ptn=1/ts
bys categ1 (patnumpp1): gen sum_ptn=sum(ptn)
gen prev_ptn=sum_ptn-ptn
replace prev_ptn=L.prev_ptn if ttb==0
bys patent: gen tot=_N
xtset categ1 patnumpp1



rename ipc3 cited_sub
merge m:1 cited_sub using "/mnt/fs0/share/akcigitlab/scipub/patents/IPC3_dependence_long_part.dta"
keep if _m==3
drop _m


bys patent: egen minvseq=min(invseq)
replace invseq=invseq+1 if minvseq==0


sort categ1 patnumpp1
gen dummy=1

gen connec_bb=.
gen mconnec_bb=.

gen depthrun=.
gen depthtotal=.

gen weight=1/tot
*replace weight=0 if weight~=1
bys categ1: gen totpat=_N
replace exp_cit=. if invseq!=1
bys appyear: egen mcit=mean(exp_cit)
replace exp_cit=exp_cit/mcit
bys patent:egen cit=mean(exp_cit)

replace exp_cit=cit

gen depth_unadj=.
rename g_ipc subcat_g
sum subcat_g
local classes=`r(max)'
forvalues i=1/`classes'{
***here we generate weights per person

***the goal here is simply to build a vector
gen val`i'=0
replace val`i'=weight*exp_cit if subcat_g==`i'
bys categ1 (patnumpp1): gen runningval`i'=sum(val`i')
bys categ1: egen totalval`i'=total(val`i')

replace runningval`i'=runningval`i'-val`i'
replace totalval`i'=totalval`i'-val`i'

***can turn this off whenever

gen dummy`i'=0
replace dummy`i'=1 if val`i'~=.
bys categ1 (patnumpp1): gen runone`i'=sum(dummy`i')
bys categ1 (patnumpp1): egen totone`i'=total(dummy`i')

gen runningtype`i'=runningval`i'/(runone`i'-1)
gen totaltype`i'=totalval`i'/(totone`i'-1)

replace depthrun=runningtype`i' if subcat_g==`i'
replace depthtotal=totaltype`i' if subcat_g==`i'

drop totone`i' runone`i' dummy`i' val`i'
**we can collapse to breadth later 

}



gen breadthrun=.

bys patent: gen teammem=_n
sum subcat_g
local classes=`r(max)'
local alpha=1
forvalues i=1/`classes'{
replace p`i'_=0 if subcat_g==`i'
***within patent, collect expertise
bys patent: egen tconnec`i'=total(totaltype`i')
gen connec`i'=p`i'_*tconnec`i'^`alpha'

}
egen breadthtype1=rowtotal(connec*)
drop tconnec*
drop connec*
local alpha=0
forvalues i=1/`classes'{
replace p`i'_=0 if subcat_g==`i'
bys patent: egen tconnec`i'=total(totaltype`i')
gen connec`i'=(p`i'_*tconnec`i')^`alpha'
replace connec`i'=0 if tconnec`i'==0
}
egen bt_ipc2=rowtotal(connec*)
drop connec*


****BREADTH AS RUNNING VARIABLE
sum subcat_g
local classes=`r(max)'
local alpha=1
forvalues i=1/`classes'{
bys patent: egen r2connec`i'=total(runningtype`i')
gen connec`i'=(p`i'_*r2connec`i')^`alpha'
replace connec`i'=0 if r2connec`i'==0
}
egen btr_ipc2=rowtotal(connec*)

local alpha=0

forvalues i=1/`classes'{
gen rconnec`i'=p`i'_*r2connec`i'^`alpha'
}
egen bte_ipc3=rowtotal(rconnec*)

bys patent: egen depthteam_e=total(depthtotal)
rename breadthtype1 breadthteam_e

forvalues i=1/`classes'{
local types `types' totaltype`i'

}



gen arcsin_e=ln(exp_cit+(exp_cit^2+1)^0.5)

preserve

keep patent categ1 depthrun breadthteam_e depthteam_e arcsin_e exp_cit appyear bt_ipc2 btr_ipc2
save "/mnt/fs0/share/akcigitlab/scipub/patents/citation_adj_skills_part_leave_out_IPC3_2010.dta",replace

restore




***MAIN dataset:


save "$output/main_CP.dta"

***merge our citing-cited pairs
merge 1:m patent using "$data1/citation75_10_clean_vnc"


drop _m

rename appyear new_appyear

rename patent citing
rename citation patent

merge m:1 patent using "$data1/patent.dta"

rename patent cited


save "$data2/citing_cited_years.dta", replace


***THEN WE WANT TO MERGE WITH ASSIGNEE INFO TO ELIMINATE SELF CITATIONS






**ANOTHER ASSIGNEE DATASET:
**See dropbox/Jeremy/07_uspto/01_assignee for do file working on this
insheet using "$data1/pn_asg_uprd_69_14.txt", clear
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

rename patentnumber patent
destring patent, force replace
drop if patent ==.

save "$data2/harmonized_assignee_patent_number.dta",replace

**merge in this case
use "$data1/class_destrung_vnc", clear
drop if patent ==.

*yikes
duplicates drop patent, force
*duplicates drop patent,force

merge 1:1 patent using "$data2/harmonized_assignee_patent_number.dta"
keep if _m ==3
drop _m

destring assignee_code, force gen(acode)

egen assignee_c = group(acode class)


save "$data2/class_assignee", replace

use "$data2/class_assignee", clear

merge 1:1 patent using "$data2/patentcsv.dta"

drop _m

merge 1:m patent using "$data2/inventor_data_firstname_lastname_state_1"

drop _m
save "$data2/inventor_data_w_patent_years", replace

****Now to graph:
*don't need to clear because we already have file



use "$data2/citing_cited_years", clear

drop _m
rename cited patent
merge m:1 patent using "$data2/class_assignee.dta"

rename class class1
rename subclass subclass1
rename subnum subnum1
rename assignee_code assignee_code1
rename acode acode1
rename assignee_harmonized assignee_harmonized1
rename assignee_c assignee_c1
drop _m

rename patent cited
rename citing patent


merge m:1 patent using "$data2/class_assignee.dta"

rename patent citing

save "$data2/merged_classes_citing_cited.dta",replace

****
use "$data2/merged_classes_citing_cited.dta", clear
drop _m
rename citing patent
merge m:1 patent using "/home/jgpearce/Documents/social_learning/big_ideas/data/pdpass_patent"
drop _m firmseq
rename pdpass pdpass_citing

rename patent citing
rename cited patent
merge m:1 patent using "/home/jgpearce/Documents/social_learning/big_ideas/data/pdpass_patent"
drop _m firmseq

rename pdpass pdpass_cited
rename patent cited

replace citing =. if pdpass_cited==pdpass_citing & pdpass_citing~=0

gen exploration=0
replace exploration=1 if pdpass_cited==pdpass_citing

bys citing: egen exploration_t =max(exploration)
***drop if the cite is a self-cite

drop if citing ==.

bysort cited new_appyear: gen num_cites = _N
save "$data2/merged_classes_citing_count_year_pdpass.dta",replace

use "$data2/merged_classes_citing_count_year_pdpass.dta",replace

**HERE WE ARE COLLECTING NUM CITES BY PATENT
drop if appyear ==.
drop if citing ==.


drop num_cites

drop if new_appyear > appyear +5
bysort cited: gen num_cites = _N

duplicates drop cited, force
drop *1 citing new*

rename cited patent

save "$data2/patent_with_citations_pdpass_1.dta",replace

***HERE WE USE the PDPASS/IPC data
use "$data1/pat_pd_ipc_76_06_vnc.dta", clear

duplicates drop patent, force
**THIS IS VERY QUESTIONABLE, ASK UFUK
tempfile pd
save `pd'



use "$data2/patent_with_citations.dta", clear


merge 1:m patent using "$data2/inventor_data_w_patent_years"

replace num_cites =0 if num_cites ==.
drop _m

merge m:1 patent using `pd'


** missed on 1.65 million observations


*carry forwarding IPC so that it fills out full dataset
bysort class subnum (patent): carryforward icl_class, gen(IPC)
gen npat = -patent
bysort class subnum (npat): carryforward IPC, replace


drop _m



***this has a 1 if it's ICT, 0 if hi-tech
merge m:1 IPC using "$data1/ICT2_vnc"


***KEEP IN MIND THIS IS ALL DUPLICATES DROPPED DATA
save "$data2/all_ICT_cites", replace


***HERE We want to merge with citation data for some results
use "$data2/all_ICT_cites", clear
**replace hi-tech =0
replace ICT =0 if ICT ==. & IPC ~=""
drop if IPC ==""
drop if appyear < 1975



***LET's ORGANiZE BY IPC CLASS

gen IPC1 = substr(IPC,1,1)

sum num_cites if IPC1=="A"
sum num_cites if IPC1=="B"
sum num_cites if IPC1=="C"
sum num_cites if IPC1=="D"
sum num_cites if IPC1=="E"
sum num_cites if IPC1=="F"
sum num_cites if IPC1=="G"
sum num_cites if IPC1=="H"








**(MORE READING IN:

global data1 "/mnt/ide0/home/jgpearce/Documents/Ufuk2/raw"
global graph1 "/mnt/ide0/home/jgpearce/Ufuk2/graphs/02_females_by_state"
global data2 "/mnt/ide0/home/jgpearce/Documents/Ufuk2/data2/13_citation_vnc"

***This data comes from HBS inventor data where file was too big

**See https://dataverse.harvard.edu/dataset.xhtml?persistentId=hdl:1902.1/15705

**lastname, street, zipcode, state, city, country, nationality have been dropped 
**original dataset is inventor_data_hbs, but so heavy for do-files
use "$data1/inventor_data_hbs_keep_last_country_state_vnc.dta", clear



split firstname
**take out extra components of name
drop firstname
rename firstname1 firstname
drop firstname2 firstname3 firstname4 firstname5 firstname6 firstname7

**take out periods from string, and rename invname to merge with gender set
gen invname = subinstr(firstname,".","",.)
**split up hyphen names
split invname, p(-)
*now invname1 is our main name
drop invname
drop firstname
rename invname1 invname

replace invname = lower(invname)

sort patent

merge m:1 invname using "$data1/firstname_gender_vnc"

drop if _m ==2

***All utility patents start with 0 so destringing won't be an issue
destring patent, force replace
drop if patent ==.

drop _m
rename invname firstname
drop invname*

save "$data2/inventor_data_firstname_lastname_state_1", replace

clear




**STARTED WITH INVENTOR NAMES, NOW ONTO patent data
**this comes from harvard website
*****Summary of the data: https://www.researchgate.net/publication/228264129_National_Bureau_of_Economic_Research_Patent_Database_Data_Overview

*insheet raw data downloaded from HBS site

insheet using "$data1/patent.csv", clear
**keep patent and appyear is all we need for this operation:
keep patent appyear
destring patent, force replace
drop if patent ==.

save "$data2/patentcsv.dta"

***merge our citing-cited pairs
merge 1:m patent using "$data1/citation75_10_clean_vnc"


drop _m

rename appyear new_appyear

rename patent citing
rename citation patent

merge m:1 patent using "$data1/patent.dta"

rename patent cited


save "$data2/citing_cited_years.dta", replace


***THEN WE WANT TO MERGE WITH ASSIGNEE INFO TO ELIMINATE SELF CITATIONS






**ANOTHER ASSIGNEE DATASET:
**See dropbox/Jeremy/07_uspto/01_assignee for do file working on this
insheet using "$data1/pn_asg_uprd_69_14.txt", clear
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

rename patentnumber patent
destring patent, force replace
drop if patent ==.

save "$data2/harmonized_assignee_patent_number.dta",replace

**merge in this case
use "$data1/class_destrung_vnc", clear
drop if patent ==.

*yikes
duplicates drop patent, force
*duplicates drop patent,force

merge 1:1 patent using "$data2/harmonized_assignee_patent_number.dta"
keep if _m ==3
drop _m

destring assignee_code, force gen(acode)

egen assignee_c = group(acode class)


save "$data2/class_assignee", replace

use "$data2/class_assignee", clear

merge 1:1 patent using "$data2/patentcsv.dta"

drop _m

merge 1:m patent using "$data2/inventor_data_firstname_lastname_state_1"

drop _m
save "$data2/inventor_data_w_patent_years", replace

****Now to graph:
*don't need to clear because we already have file



use "$data2/citing_cited_years", clear

drop _m
rename cited patent
merge m:1 patent using "$data2/class_assignee.dta"

rename class class1
rename subclass subclass1
rename subnum subnum1
rename assignee_code assignee_code1
rename acode acode1
rename assignee_harmonized assignee_harmonized1
rename assignee_c assignee_c1
drop _m

rename patent cited
rename citing patent


merge m:1 patent using "$data2/class_assignee.dta"

rename patent citing

save "$data2/merged_classes_citing_cited.dta",replace

****
use "$data2/merged_classes_citing_cited.dta", clear
replace citing =. if acode == acode1
***drop if the cite is a self-cite

drop if citing ==.

bysort cited new_appyear: gen num_cites = _N
save "$data2/merged_classes_citing_count_year.dta",replace

use "$data2/merged_classes_citing_count_year.dta",replace

***First merge with IPC on citing:

rename citing patent


**HERE WE ARE COLLECTING NUM CITES BY PATENT
drop if appyear ==.
drop if citing ==.


drop num_cites

*drop if new_appyear > appyear +5
bysort cited: gen tot_cites = _N
duplicates drop cited, force
drop *1 citing new* _m

rename cited patent
keep patent appyear tot_cites

save "$data2/patent_total_citations.dta",replace

***HERE WE USE the PDPASS/IPC data
use "$data1/pat_pd_ipc_76_06_vnc.dta", clear

duplicates drop patent, force
**THIS IS VERY QUESTIONABLE, ASK UFUK
tempfile pd
save `pd'



use "$data2/patent_with_citations.dta", clear


merge 1:m patent using "$data2/inventor_data_w_patent_years"

replace num_cites =0 if num_cites ==.
drop _m

merge m:1 patent using `pd'


** missed on 1.65 million observations


*carry forwarding IPC so that it fills out full dataset
bysort class subnum (patent): carryforward icl_class, gen(IPC)
gen npat = -patent
bysort class subnum (npat): carryforward IPC, replace


drop _m



***this has a 1 if it's ICT, 0 if hi-tech
merge m:1 IPC using "$data1/ICT2_vnc"


***KEEP IN MIND THIS IS ALL DUPLICATES DROPPED DATA
save "$data2/all_ICT_cites", replace


***HERE We want to merge with citation data for some results
use "$data2/all_ICT_cites", clear
**replace hi-tech =0
replace ICT =0 if ICT ==. & IPC ~=""
drop if IPC ==""
drop if appyear < 1975



***LET's ORGANiZE BY IPC CLASS

gen IPC1 = substr(IPC,1,1)

sum num_cites if IPC1=="A"
sum num_cites if IPC1=="B"
sum num_cites if IPC1=="C"
sum num_cites if IPC1=="D"
sum num_cites if IPC1=="E"
sum num_cites if IPC1=="F"
sum num_cites if IPC1=="G"
sum num_cites if IPC1=="H"
















**CAREERS OF INDIVIDUALS
use "$data4/categ1_career",clear

merge m:1 patent using "$data4/life_cit_IPC1.dta"
keep if _m==3
drop _m
duplicates drop categ1 patent, force
merge m:1 patent using "$data4/basicbib14_format_ipc.dta", keepusing(assignee gyear appyear ipc4 pdpass nclass)


keep if _m==3
drop _m

*rename ipc4 IPC
merge 1:1 patent categ1 using "$data4/survive_lifecit_0418", keepusing(IPC)
drop _m


gen ipc3=substr(IPC,1,3)
gen ipc2=substr(IPC,1,2)
keep if appyear<=2000
merge m:1 ipc3 using "/mnt/fs0/share/akcigitlab/scipub/patents/ipc3_keep_only"
replace ipc3="" if _m~=3
drop _m

bys nclass: egen mode_ipc=mode(ipc3)
replace ipc3=mode_ipc if ipc2==""

*replace ipc2=substr(ipc3,1,2)
egen g_ipc=group(ipc3)


***replace ipc2 if it doesn't fit

**MERGE W/ Citations


rename appdate date
bys categ1 (date patent): gen patnumpp1=_n
xtset categ1 patnumpp1
gen ttb=date-L.date



gen ptn=1
*replace ptn=1/ts
bys categ1 (patnumpp1): gen sum_ptn=sum(ptn)
gen prev_ptn=sum_ptn-ptn
replace prev_ptn=L.prev_ptn if ttb==0
bys patent: gen tot=_N
xtset categ1 patnumpp1



rename ipc3 cited_sub
merge m:1 cited_sub using "/mnt/fs0/share/akcigitlab/scipub/patents/IPC3_dependence_long_part.dta"
keep if _m==3
drop _m


bys patent: egen minvseq=min(invseq)
replace invseq=invseq+1 if minvseq==0


sort categ1 patnumpp1
gen dummy=1

gen connec_bb=.
gen mconnec_bb=.

gen depthrun=.
gen depthtotal=.

gen weight=1/tot
*replace weight=0 if weight~=1
bys categ1: gen totpat=_N
replace exp_cit=. if invseq!=1
bys appyear: egen mcit=mean(exp_cit)
replace exp_cit=exp_cit/mcit
bys patent:egen cit=mean(exp_cit)

replace exp_cit=cit

gen depth_unadj=.
rename g_ipc subcat_g
sum subcat_g
local classes=`r(max)'
forvalues i=1/`classes'{
***here we generate weights per person

***the goal here is simply to build a vector
gen val`i'=0
replace val`i'=weight*exp_cit if subcat_g==`i'
bys categ1 (patnumpp1): gen runningval`i'=sum(val`i')
bys categ1: egen totalval`i'=total(val`i')

replace runningval`i'=runningval`i'-val`i'
replace totalval`i'=totalval`i'-val`i'

***can turn this off whenever

gen dummy`i'=0
replace dummy`i'=1 if val`i'~=.
bys categ1 (patnumpp1): gen runone`i'=sum(dummy`i')
bys categ1 (patnumpp1): egen totone`i'=total(dummy`i')

gen runningtype`i'=runningval`i'/(runone`i'-1)
gen totaltype`i'=totalval`i'/(totone`i'-1)

replace depthrun=runningtype`i' if subcat_g==`i'
replace depthtotal=totaltype`i' if subcat_g==`i'

drop totone`i' runone`i' dummy`i' val`i'
**we can collapse to breadth later 

}



gen breadthrun=.

bys patent: gen teammem=_n
sum subcat_g
local classes=`r(max)'
local alpha=1
forvalues i=1/`classes'{
replace p`i'_=0 if subcat_g==`i'
***within patent, collect expertise
bys patent: egen tconnec`i'=total(totaltype`i')
gen connec`i'=p`i'_*tconnec`i'^`alpha'

}
egen breadthtype1=rowtotal(connec*)
drop tconnec*
drop connec*
local alpha=0
forvalues i=1/`classes'{
replace p`i'_=0 if subcat_g==`i'
bys patent: egen tconnec`i'=total(totaltype`i')
gen connec`i'=(p`i'_*tconnec`i')^`alpha'
replace connec`i'=0 if tconnec`i'==0
}
egen bt_ipc2=rowtotal(connec*)
drop connec*


****BREADTH AS RUNNING VARIABLE
sum subcat_g
local classes=`r(max)'
local alpha=1
forvalues i=1/`classes'{
bys patent: egen r2connec`i'=total(runningtype`i')
gen connec`i'=(p`i'_*r2connec`i')^`alpha'
replace connec`i'=0 if r2connec`i'==0
}
egen btr_ipc2=rowtotal(connec*)

local alpha=0

forvalues i=1/`classes'{
gen rconnec`i'=p`i'_*r2connec`i'^`alpha'
}
egen bte_ipc3=rowtotal(rconnec*)

bys patent: egen depthteam_e=total(depthtotal)
rename breadthtype1 breadthteam_e

forvalues i=1/`classes'{
local types `types' totaltype`i'

}



gen arcsin_e=ln(exp_cit+(exp_cit^2+1)^0.5)

preserve

keep patent categ1 depthrun breadthteam_e depthteam_e arcsin_e exp_cit appyear bt_ipc2 btr_ipc2
save "/mnt/fs0/share/akcigitlab/scipub/patents/citation_adj_skills_part_leave_out_IPC3_2010.dta",replace

restore
