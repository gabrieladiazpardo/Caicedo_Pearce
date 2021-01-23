***MAIN DATA CLEANING FOR CAICEDO-PEARCE PROJECT

***Date updated: Sept 4, 2020
* Sept 10, 2020 : added labels and saved a patent level dataset (Santiago)


****THIS FILE WILL CREATE INDIVIDUAL X PATENT LEVEL DATA, SKILLS, CITATIONS. LISTS SOURCES


*global main "/Users/JeremyPearce/Dropbox"
global main "/Users/JeremyPearce/Dropbox"


global data "$main/Caicedo_Pearce/data"
global wrkdata "$main/Caicedo_Pearce/data/wrkdata"
global raw "$main/Caicedo_Pearce/data/rawdata"
global output "$main/Caicedo_Pearce/data/output"
***This data comes from HBS inventor data where file was too big


*****Summary of the patent data general: https://www.researchgate.net/publication/228264129_National_Bureau_of_Economic_Research_Patent_Database_Data_Overview

**INVENTOR DISAMBIGUATION AND PATENTSVIEW (ipc classification)
**this comes from harvard NAMES: https://dataverse.harvard.edu/dataset.xhtml?persistentId=hdl:1902.1/15705
*https://www.patentsview.org/download/

**---FOR compustat merge---
****FIRMS: https://www.uspto.gov/web/offices/ac/ido/oeip/taf/data/misc/data_cd.doc/assignee_harmonization/cy2014/

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
duplicates drop
save "$output/patent_ipc3.dta",replace



***INDIVIDUALS -- individual, location, USPTO class, assignee (HBS), inventor order
insheet using "$raw/invpat.csv", clear
destring patent, force replace
keep if patent~=.
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
merge m:1 patent using "$wrkdata/patent_app_bib.dta"

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


merge m:1 patent using "$wrkdata/patent_app_bib.dta", gen(ay_merge2)
destring gday gmonth gyear,replace
*keep if ay_merge2==3
rename appyear cited_appyear
drop if citing==. | patent==.

merge m:1 patent using "$output/patent_ipc3_dd.dta" , keepusing(ipc3)

save "$wrkdata/citations_by_yr",replace




***INTL CITATION SAME IDEA:


rename patent cited
bysort cited citing_appyear:gen f_cityr=_N
gen dummy=1

bysort cited:egen forward_cit_total=total(dummy)
rename citing_appyear citingyear
gen ipc1=substr(ipc3,1,1)
keep f_cityr forward_cit_total cited citingyear ipc1


duplicates drop

save "$output/Citation_event_time_ipc.dta",replace


***read in new revenue stuff
use "$wrkdata/patent_app_bib.dta",clear
duplicates drop patent,force
rename patent cited
merge 1:m cited using "$output/Citation_event_time_ipc.dta"
rename cited patent
keep if _merge==3
drop _m
gen patent_age=citingyear-appyear
gen dummy=1
keep if patent_age>=0 & patent_age<=20
encode ipc1, gen(tech_cat)
bysort tech_cat patent_age: egen total_patent_tech=total(dummy)
bysort tech_cat patent_age: egen cit_tech=total(f_cityr)
bysort tech_cat: egen total_cit_tech=total(f_cityr)
gen cit_per_tech=cit_tech/total_patent_tech

rename cit_per_tech cit
collapse (mean) cit,by(patent_age tech_cat ipc1)
reshape wide cit, i(tech_cat ipc1) j(patent_age)

egen total_cit=rowtotal(cit*)
gen afcit0=cit0
gen pdf_cit0=cit0/total_cit
gen cdf_cit0=cit0/total_cit

forvalues x=1/20{
replace cit`x'=0 if cit`x'==.
}

forvalues x=1/20{
local y=`x'-1
gen afcit`x'=afcit`y'+cit`x'
gen pdf_cit`x'=cit`x'/total_cit
gen cdf_cit`x'=afcit`x'/total_cit
}
order tech_cat ipc1 cit0 cit1 cit2 cit3 cit4 cit5 cit6 cit7 cit8 cit9 cit10 cit11 cit12 cit13 cit14 cit15 cit16 cit17 cit18 cit19 cit20 pdf_cit0 pdf_cit1 pdf_cit2 pdf_cit3 pdf_cit4 pdf_cit5 pdf_cit6 pdf_cit7 pdf_cit8 pdf_cit8 pdf_cit9 pdf_cit10 pdf_cit11 pdf_cit12 pdf_cit13 pdf_cit14 pdf_cit15 pdf_cit16 pdf_cit17 pdf_cit18 pdf_cit19 pdf_cit20 cdf_cit0 cdf_cit1 cdf_cit2 cdf_cit3 cdf_cit4 cdf_cit5 cdf_cit6 cdf_cit7 cdf_cit8 cdf_cit8 cdf_cit9 cdf_cit10 cdf_cit11 cdf_cit12 cdf_cit13 cdf_cit14 cdf_cit15 cdf_cit16 cdf_cit17 cdf_cit18 cdf_cit19 cdf_cit20
save "$wrkdata\Citation Profile0920.dta", replace


use "$wrkdata/patent_app_bib.dta",clear
drop gday gmonth gyear
merge 1:m patent using "$wrkdata/citations_by_yr", gen(cit_merge)
drop if cit_merge==2
gen patent_age=citing_appyear-appyear
rename citing_appyear citingyear
gen dummy=1
bysort patent:egen f_cit=total(dummy) if patent_age<=20 | patent_age>=0
replace f_cit=0 if cit_merge==1
duplicates drop patent,force
gen ipc1=substr(ipc3,1,1)
keep patent appyear f_cit ipc1
merge m:1 ipc1 using "$wrkdata\Citation Profile0920.dta"
keep if _merge==3
gen patent_age=2015-appyear
duplicates drop patent,force
gen exp_cit=.
forvalues x=0/20{
replace exp_cit=f_cit/cdf_cit`x' if patent_age==`x'
}

replace exp_cit=f_cit if patent_age>20

keep patent exp_cit tech_cat patent_age f_cit appyear patent_age

duplicates drop patent,force
label var f_cit "forward citation(max 20 year)"
label var patent_age "Current Age"
label var exp_cit "Expected Forward Citation"
save "$output/life_cit_IPC1.dta",replace




***IPC3 connectivity*****
use "$data/uscites2015.dta", clear
rename patent citing
rename cited patent

sort patent



merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"
keep if _m==3
drop _m
rename ipc3 subcat_g

rename subcat_g cited_sub
rename patent cited


rename citing patent
sort patent
destring patent, force replace
drop if patent==.
merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"
keep if _m==3
drop _merge



rename ipc3 citing_sub
rename patent citing
***what period do we want?
keep cited_sub citing_sub

gen dummy = 1
sort cited_sub citing_sub
collapse (sum) dummy, by(cited_sub citing_sub)
sort cited_sub citing_sub
drop if cited_sub==""

rename dummy citcount

sort citing_sub
bys citing_sub: egen total1 = total(citcount)
bys citing_sub: egen total2 = total(citcount) if cited_sub == citing_sub
bys citing_sub: egen same_prox=mean(total2)

gen p2p_prox1=(citcount / total1)
gen p2p_prox2=(citcount / same_prox)
replace p2p_prox1=p2p_prox2 if cited_sub==citing_sub

gen same_prox2=.
replace same_prox=p2p_prox1 if cited_sub==citing_sub
bys citing_sub: egen sprox=mean(same_prox2)
gen dependence=p2p_prox2
drop if cited_sub=="" | citing_sub==""

preserve
***When we merge this to soviet data, we want to 
gen g_ipc3 = trim(cited_sub)
sort g_ipc3
egen g_ipc=group(g_ipc3)
drop cited*
drop p2p_prox2
rename dependence p2p_prox2
keep p2p_prox2 citing_sub g_ipc
reshape wide p2p_prox2, i(citing_sub) j(g_ipc)
rename p2p_prox2* p*_
rename citing_sub cited_sub
save "$wrkdata/IPC3_dependence_long_agg.dta", replace
restore






****BUILDING SKILLS BASED ON MERGED COMPONENTS:
use "$output/individuals_CP.dta", clear
duplicates drop patent categ1, force
merge m:1 patent using "$output/life_cit_IPC1.dta"
drop _m

merge m:1 patent using "$wrkdata/patent_idate.dta"
drop _m

merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"
keep if _m==3
drop _m
/*
merge m:1 patent using "$output/dates_CP.dta"
drop _m
*/
rename idate date
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
merge m:1 cited_sub using "$wrkdata/IPC3_dependence_long_agg.dta"
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
**MOVE TO SERVER
egen subcat_g=group(ipc3)
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
egen breadthrun=rowtotal(connec*)

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



gen invh_cit=ln(exp_cit+(exp_cit^2+1)^0.5)

preserve

keep patent categ1 depthrun breadthrun breadthteam_e depthteam_e invh_cit exp_cit appyear
save "$output/citation_adjusted_breadthdepth_sep20.dta",replace

restore


use "$output/citation_adjusted_breadthdepth_sep20.dta",replace

drop if appyear==.
**there is the occasiaonl duplicate
duplicates drop categ1 patent, force
merge 1:1 patent categ1 using "$output/individuals_CP.dta"

keep if _m==3
drop _m

merge m:1 patent using "$wrkdata/patent_idate.dta"
drop _m
merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"
keep if _m==3
drop _m


gen is90s=.
replace is90s=0 if appyear>=1980 & appyear<=1990
replace is90s=1 if appyear>=1991 & appyear<=2000



***time to build:
rename idate date
bys categ1 (date patent): gen patnumpp1=_n
xtset categ1 patnumpp1
gen ttb1=date-L.date
gen ttb2=F.date-date

gen i_ttb=(ttb1+ttb2)/2
replace i_ttb=ttb1 if ttb2==.
replace i_ttb=ttb2 if ttb1==.


bys patent: egen m_ttb=mean(i_ttb)


**adjust citations:

gen ttb_cit=exp_cit/m_ttb

gen invh_ttb=ln(ttb_cit+(ttb_cit^2+1)^0.5)
bys patent: gen tsize=_N

**group firms
egen assignee =group(asgnum)
replace assignee=0 if assignee==.
keep if appyear>=1975 & appyear<=2010



save "$output/main_CP.dta",replace

***create survival measure
preserve
keep date categ1 patent invseq
rename categ1 categ
bys patent: egen minv=min(invseq)
replace invseq=invseq+1 if minv==0
reshape wide categ, i(patent) j(invseq)
egen group1=group(categ1)
egen group2=group(categ1 categ2)
egen group3=group(categ1 categ2 categ3)
egen group4=group(categ1 categ2 categ3 categ4)
bys patent (date): gen count=_n



reshape long categ, i(patent) j(invseq)
bys categ (date): gen patnumpp1=_n
bys categ (patnumpp1): gen survive1=1 if F.group1==group1
bys categ (patnumpp1): gen survive2=1 if F.group2==group2
bys categ (patnumpp1): gen survive3=1 if F.group3==group3
bys categ (patnumpp1): gen survive4=1 if F.group4==group4


drop if categ==.

gen survive=.


forvalues i=1/4{
replace survive`i'=0 if survive`i'==.
replace survive`i'=. if group`i'==.
replace survive=survive`i' if tsize==`i'
}

bys patent: egen max_s=max(survive)

keep patent max_s
rename max_s survive
duplicates drop
save "$output/patent_max_survive.dta"

restore


***±Merge dataset:

use "$output/main_CP.dta",clear

merge m:1 patent using "$output/patent_max_survive.dta"
drop _m


***Add labels:

use "$output/main_CP.dta",clear

*Add labels
label var  categ1  "Inventor id (lower)"
label var  categ2  "Inventor id (upper)"
label var appyear "Application year"
label var depthrun "Depth (running)"
label var depthteam_e  "Depth team"
label var breadthrun  "Breadth (running)"
label var breadthteam_e "Breadth team"
label var invh_cit "Inverse hyperbolic sine of expected citations"
label var uspto_class  "USPTO Class"
label var date "???"
label var ipc3  "IPC three digits"
label var num "???"
label var is90s "Indicator of 90s decade"
label var patnumpp1 "Running number of patents by inventor"
label var ttb1 " Time to build since last patent"
label var ttb2 "Time to build next patent" 
label var i_ttb "Average time to build (last and next patent)"
label var m_ttb "Mean of time to build by patent"
label var ttb_cit "Expected forward citations divided time to build"
label var invh_ttb "Inverse hyperbolic sine of expected citations"
label var tsize  "Team size"
label var survive "Team survives (up to teams of size 4)"



save "$output/main_CP.dta",replace




***build specialization based on USPTO classes and subcategories


use "$output/main_CP.dta",clear

merge m:1 patent using "$wrkdata/nber_subcategory.dta"

bys uspto_class: egen mode_sub=mode(subcat)
replace mode_sub=subcat if subcat~=.
egen subcat_g=group(mode_sub)





keep categ1 patnumpp1 patent date uspto_class subcat_g
***you can build skills based on subcategory, which seems reasonbale for now:
bys patent: gen tsize=_N

sum subcat_g
local classes=`r(max)'
forvalues i=1/`classes'{
***here we generate weights per person

***the goal here is simply to build a vector
gen exp`i'=0
***only replace if team size = 1?
replace exp`i'=1 if subcat_g==`i' & tsize==1
****running sum
bys categ1 (patnumpp1): gen countexp`i'=sum(exp`i')
*bys categ1: egen totalexp`i'=total(exp`i')


** adjustment to take current patent out
replace countexp`i'=countexp`i'-exp`i'
*replace totalexp`i'=totalexp`i'-exp`i'

drop exp`i'
*gen sharet`i'=totalexp`i'/rttotal

drop rtcount



}


sum subcat_g
local classes=`r(max)'
forvalues i=1/`classes'{

egen rtcount=rowtotal(countexp*)
*egen rttotal=rowtotal(totalexp*)

gen shareexp`i'=countexp`i'/rtcount
*gen sharet`i'=totalexp`i'/rttotal

drop rtcount



}


keep patent categ1 countexp* shareexp* subcat_g

save $output/runningskills_soleauthor_091520.dta






gen cat=.
replace cat=1 if subcat_g<=6
replace cat=2 if  subcat_g>6 & subcat_g<=11
replace cat=3 if  subcat_g>11& subcat_g<=15
replace cat=4 if  subcat_g>15 & subcat_g<=22
replace cat=5 if subcat_g>22 & subcat_g<=28
replace cat=6 if subcat_g>28 & subcat_g<=37



***********************************
* Create the patent level dataset
***********************************

*Only keep patent level data

use "$output/main_CP.dta", clear

keep patent appyear exp_cit breadthteam_e depthteam_e invh_cit asgnum uspto_class date ipc3 num m_ttb ttb_cit invh_ttb tsize survive

duplicates drop patent, force

save "$output/main_pat_lev_CP.dta", replace


***we still need to make distance measures, type measures, etc.









*****************
*****IPC STUFF*******
*****************

insheet using "$raw/ipcr.tsv",clear


destring patent_id, force gen(patent)

keep patent ipc3 section ipc_class
gen adjip=length(ipc_class)
gen str0="0"
replace ipc_class=str0+ipc_class if  adjip==1
gen ipc3=section+ipc_class
bys patent: gen count=_N
bys ipc3: gen count_i=_N
drop if count_i<100
bys patent: egen max_i=max(count_i)
gen digit1=substr(ipc3,1,1)
gen digit2=substr(ipc3,2,1)
gen digit3=substr(ipc3,3,1)

keep if (digit1 == "A") | (digit1 == "B") |(digit1 == "C") |(digit1 == "D") |(digit1 == "E") |(digit1 == "F") |(digit1 == "G") |(digit1 == "H")
keep if (digit2 == "0") | (digit2 == "1") |(digit2 == "2") |(digit2 == "3") |(digit2 == "4") |(digit2 == "5") |(digit2 == "6") |(digit2 == "7") |(digit2 == "8") |(digit2 == "9")
keep if (digit3 == "0") | (digit3 == "1") |(digit3 == "2") |(digit3 == "3") |(digit3 == "4") |(digit3 == "5") |(digit3 == "6") |(digit3 == "7") |(digit3 == "8") |(digit3 == "9")

**keep 

