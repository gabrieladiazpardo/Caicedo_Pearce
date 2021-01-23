clear all
set maxvar 32767
set matsize 11000
set more off


global ivdata "C:\Working Documents\_20150714 Data"
global ivdata_licensing "C:\Working Documents\_20150814 Data"
global workdir "C:\Working Documents\JeremyP\0218\CreativeDestruction\data"


use "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/uscites2015.dta", clear
***patent=citing

destring patent, force replace
***merge with relevant patent info:
**patent for string merge, patentnumer for numeric merge
merge m:1 patent using /Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/patent_ay_2.dta, gen(ay_merge)

drop if ay_merge~=3
drop ay_merge

merge m:1 patent using "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/patent_assignee2"
keep if _m==3
drop _m

rename assignee citing_pdp
rename patent citing

rename cited patent
merge m:1 patent using "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/patent_assignee2"
rename assignee cited_pdp
drop if _m==1
drop _m
gen self_cit=0



merge m:1 patent using "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data/wrkdata/patent_f10f.dta"

replace self_cit=1 if cited_pdp==citing_pdp & cited_pdp~=. & cited_pdp~=0
gen cit=1


rename appyear citing_appyear

/*
collapse (sum) self_cit cit, by(citing)
rename*/
**we can't drop caateg
*drop if cited_categ=citing_categ



merge m:1 patent using "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/patent_ay_2.dta", gen(ay_merge2)
*keep if ay_merge2==3
rename appyear cited_appyear
drop if citing==. | patent==.

rename patent cited
rename citing patent



save "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/citations_by_yr2",replace


**NEED TO APPEND PDPASS HERE

merge m:1 patent using "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/basicbib14_format_ipc.dta" , keepusing(ipc4)


rename patent cited

**Now we have appyear and IPC4: recall goal--do citation truncation using IPC4

***INTL CITATION SAME IDEA:

collapse top_firm, by(patent)
rename top_firm cit_top_share
save "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data/wrkdata/cit_top_share_bypatent.dta"


bysort cited citing_appyear:gen f_cityr=_N
gen dummy=1

bysort cited:egen forward_cit_total=total(dummy)
rename citing_appyear citingyear
gen ipc1=substr(ipc4,1,1)
keep f_cityr forward_cit_total cited citingyear ipc1


duplicates drop

save "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/Citation_event_time_ipc.dta",replace
*
***read in new revenue stuff
use "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/patent_ay_2.dta",clear
duplicates drop patent,force
rename patent cited
merge 1:m cited using "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/Citation_event_time_ipc.dta"
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
save "$workdir\Citation Profile1019.dta", replace


use "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/basicbib14_format_ipc.dta",clear

merge 1:m patent using "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/citations_by_yr2", gen(cit_merge)
drop if cit_merge==2
gen patent_age=citing_appyear-appyear
rename citing_appyear citingyear
gen dummy=1
bysort patent:egen f_cit=total(dummy) if patent_age<=20 | patent_age>=0
replace f_cit=0 if cit_merge==1
duplicates drop patent,force
gen ipc1=substr(ipc4,1,1)
keep patent appyear f_cit ipc1
merge m:1 ipc1 using "$workdir\Citation Profile1019.dta"
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
label var first_year "First Filing Year"
save "/Users/JeremyPearce/Dropbox/social_learning/patentcites_firms/life_cit_IPC1.dta",replace

