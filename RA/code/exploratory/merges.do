
************************************************************
*		Exploring Errors in the Merges of MainCP
*
***********************************************************



////////////////////////////////////////////////////////////////////////////////////////////
//6. Creation of citations_by_yr and Citation_event_time_ipc 
///////////////////////////////////////////////////////////////////////////////////////////

*! citations_by_yr: *data of cited patent and citing patent - cleaned by self-citations (still not a panel)

*! Citation_event_time_ipc: Clean Citations Dataset and create a patent-year dataset with cumulative citations, and max citations per year

*1) import data of the patent citated by each citing patent. Merges information about the citing patent (app year and grant date)
{

****CITATIONS -- honestly not sure about the diff bbetween online and local source. https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SJPHLG

use "$data/uscites2015.dta", clear
*67,509,081 cites. This dataset is patent cited - citing patent level 

unique patent // 5,200,210 unique citing patents
unique cited // 5,7624,13 unique citing patents


*vars - 1) patent 2) cited patent
destring patent, force replace

***merge with relevant patent info:
**patent for string merge, patentnumer for numeric merge 
merge m:1 patent using "$wrkdata/patent_app_bib.dta"

*vars merged 1) application date 2)application year 3)year granted  4)month granted 5)day granted


keep if _m==3

unique patent if _m==3 //4,858,661 unique patents


drop _merge // 64,969,366 patents with the cited patent, app date, grant date

}


*2) create a panel dataset patent-year level cited with the number of cumulative citations over the years, max citations for each year, ipc1 

{
*merge to each citing patent the assignee (firm)
merge m:1 patent using "$output/firms_CP.dta"

*21,002,266 not matched. Principally because this contains cites until 2015 and Firms_CP only to 2010 (Source:Harvard)



keep if _m==3
drop _m




***USE FIRM TO DROP SELF-CITATIONS ON THE SAME ASSIGNEE

rename asgnum citing_pdp
rename patent citing



****************************************
*		Merge info on the cited patent
*
**************************************



rename cited patent
merge m:1 patent using "$output/firms_CP.dta"
rename asgnum cited_pdp


*9,140,184 of the cited patents are lost


drop if _m==1
drop _m

*Drop assignees citing same assignee
drop if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~="0"
**we can't drop caateg
*drop if cited_categ=citing_categ


*patent = cited patent
*citing = citing patent that cites cited

*application yeat for citing patent
rename appyear citing_appyear


*merge information on application and grant to citing patent

merge m:1 patent using "$wrkdata/patent_app_bib.dta", gen(ay_merge2)

*1,590,239 not matched with dates

*keep if ay_merge2==3

destring gday gmonth gyear, replace


rename appyear cited_appyear
drop if citing==. | patent==.

************************
*	For now
* 6598994 unique cited
*	3452985 unique citing
************************

*merge ipc3 info to the cited pat.
merge m:1 patent using "$output/patent_ipc3_dd.dta" , keepusing(ipc3)

*-----patent_ipc3_dd contains ipc3 *4,210,575 didn't have 


*Save data of cited patent and citing patent (still not a panel)
save "$wrkdata/citations_by_yr",replace



***INTL CITATION SAME IDEA:

rename patent cited

*Numero maximo de veces que fue citado en un mismo año
bysort cited citing_appyear:gen f_cityr=_N

*Numero máximo de veces que fue citado (veces que aparece en la base de datos)
bys cited : gen f_cit_tot=_N
gen dummy=1


*total de veces que fue citado a lo largo de los años
bysort cited: egen forward_cit_total=total(dummy)

*año que fue citada la patente
rename citing_appyear citingyear

*crear ipc3 para la patente citada
gen ipc1=substr(ipc3,1,1)

*
keep f_cityr forward_cit_total cited citingyear ipc1


*dejar base nivel (patente, año  que fue citada) - y se deja el total de citas que tuvo cada año (f_cityr)
duplicates drop

sort cited citingyear


save "$output/Citation_event_time_ipc.dta",replace
}



////////////////////////////////////////////////////////////////////////////////////////////
//7. Creation of Citation Profile0920
///////////////////////////////////////////////////////////////////////////////////////////

*--Created PDF, CDF and average ratio of number of citations of the tecnology/total patents of the tecnology by each lag (Year Cited-App Year)
{
***read in new revenue stuff

*--Open Data: patent, appyear, grantyear, grantdate
use "$wrkdata/patent_app_bib.dta",clear



duplicates drop patent,force


*--citations
rename patent cited

*--Unir información panel patente-años y su appyear, grantyear, grantdate
merge 1:m cited using "$output/Citation_event_time_ipc.dta"


rename cited patent

*Solo dejar patentes con información de su fecha, citas cumulativas
keep if _merge==3


drop _m

*******************************************
* ESTA BASE ESTÁ A NIVEL DE CITED PATENT. Info de Appdate, gyear, dday, gmonth, appyear es DE LA CITED. 
*
*********************************************


*Diferencia de año citado-año aplicación patente (lag)
gen patent_age=citingyear-appyear

gen dummy=1


sort patent citingyear


*Solo se dejan patentes que citaron hace 20 años o menos. 
*Diferencia positiva porque es año citado- año que hicieron
keep if patent_age>=0 & patent_age<=20


*Numero por cada ipc1 category (Tecnología)
encode ipc1, gen(tech_cat)


*dummy=1 por cada año diferente que aparece la patente. Es decir, si total_patent_tech=2 es porque la citaron en dos años diferentes. ESTO NO SIGNIFICA QUE FUE CITADA EN TOTAL DOS VECES. ES EL TOTAL DE AÑOS DIFERENTES EN LOS QUE FUE CITADA.

*Se agrega a nivel de tecnología; por tecnología, cuantos años diferentes la citaron en total. 

bysort tech_cat patent_age: egen total_patent_tech=total(dummy)


*Por cada posible patent age (0-20), cuantas veces está citada una misma tecnología (total de citas a patentes de una misma tec - segun que tan vieja es)

bysort tech_cat patent_age: egen cit_tech=total(f_cityr)



**************************************************
*Siempre cit_tech>=total_patent_tech
***************************************************





*ratio citas por cada tecnología= numero citas cada patente/total de dif patentes citadas
gen cit_per_tech=cit_tech/total_patent_tech


*Cuantas citas hay en total por cada tecnología

bysort tech_cat: egen total_cit_tech=total(f_cityr)


rename cit_per_tech cit



*--Por cada año de citacion de una patente, sacar el radio de citaciones
collapse (mean) cit,by(patent_age tech_cat ipc1)

sort tech_cat patent_age 

*-Por cada tecnología, saque el promedio de citas en cada lag
reshape wide cit, i(tech_cat ipc1) j(patent_age)

*--Suma de los ratios para cada año
egen total_cit=rowtotal(cit*)


gen afcit0=cit0
gen pdf_cit0=cit0/total_cit
gen cdf_cit0=cit0/total_cit

*-reemplazar por 0 if missing
forvalues x=1/20{
replace cit`x'=0 if cit`x'==.
}


*--Sacar PDF y CDF para cada lag
forvalues x=1/20{
local y=`x'-1
gen afcit`x'=afcit`y'+cit`x'
gen pdf_cit`x'=cit`x'/total_cit
gen cdf_cit`x'=afcit`x'/total_cit
}


order tech_cat ipc1 cit0 cit1 cit2 cit3 cit4 cit5 cit6 cit7 cit8 cit9 cit10 cit11 cit12 cit13 cit14 cit15 cit16 cit17 cit18 cit19 cit20 pdf_cit0 pdf_cit1 pdf_cit2 pdf_cit3 pdf_cit4 pdf_cit5 pdf_cit6 pdf_cit7 pdf_cit8 pdf_cit8 pdf_cit9 pdf_cit10 pdf_cit11 pdf_cit12 pdf_cit13 pdf_cit14 pdf_cit15 pdf_cit16 pdf_cit17 pdf_cit18 pdf_cit19 pdf_cit20 cdf_cit0 cdf_cit1 cdf_cit2 cdf_cit3 cdf_cit4 cdf_cit5 cdf_cit6 cdf_cit7 cdf_cit8 cdf_cit8 cdf_cit9 cdf_cit10 cdf_cit11 cdf_cit12 cdf_cit13 cdf_cit14 cdf_cit15 cdf_cit16 cdf_cit17 cdf_cit18 cdf_cit19 cdf_cit20


save "$wrkdata\Citation Profile0920.dta", replace
}



////////////////////////////////////////////////////////////////////////////////////////////
//8. life_cit_IPC1
///////////////////////////////////////////////////////////////////////////////////////////

*---For each patent, creates the number of forward citations (cumulative for 20 years) and the expected citations depending on the class ipc1 (tecnology). Retrieves the average citation of the tecnology at lag=3 and, average citation of the tecnology lag=5

{

*--patente, app year
use "$wrkdata/patent_app_bib.dta",clear

*--Keep patent, app year
drop gday gmonth gyear

*--Merge to cited data the app year (dataset of cited-citing)

merge 1:m patent using "$wrkdata/citations_by_yr", gen(cit_merge)
*still a dyadics 

drop if cit_merge==2

*lag (citing app year - cited app year)
gen patent_age=citing_appyear-appyear

rename citing_appyear citingyear

gen dummy=1

*--Para cada difernte patente - saque el total de citas diferentes que le hicieron a lo largo de los 20 años

bysort patent:egen f_cit=total(dummy) if patent_age<=20 | patent_age>=0

*--Poner 0 citas si tiene fecha y no citas
replace f_cit=0 if cit_merge==1

*--Panel a nivel de año
duplicates drop patent,force


gen ipc1=substr(ipc3,1,1)
keep patent appyear f_cit ipc1

sort patent appyear

*-- a cada patente de clase ipc pegarle el citation profile del ipc

merge m:1 ipc1 using "$wrkdata/Citation Profile0920.dta"
keep if _merge==3

*--Edad de la patente (sólo se cogen patentes hasta 2015)
gen patent_age=2015-appyear

*--Para cada diferente pat en la data

duplicates drop patent,force
gen exp_cit=.

*--Crear esperado de citas dado la edad de la patente:

forvalues x=0/20{
replace exp_cit=f_cit/cdf_cit`x' if patent_age==`x'
}

replace exp_cit=f_cit if patent_age>20

*--Dejan ratio de citas a 3 años y a 5 años de la misma tecnologia
keep patent exp_cit tech_cat patent_age f_cit appyear patent_age cit3 cit5

duplicates drop patent,force


label var f_cit "forward citation(max 20 year)"
label var patent_age "Current Age"
label var exp_cit "Expected Forward Citation" ///that depends on the tecnology

save "$output/life_cit_IPC1.dta",replace


}

use "$output/life_cit_IPC1.dta",clear
sort patent appyear

////////////////////////////////////////////////////////////////////////////////////////////
//9. IPC3_dependence_long_agg 
///////////////////////////////////////////////////////////////////////////////////////////

{

***IPC3 connectivity*****
use "$data/uscites2015.dta", clear
rename patent citing
rename cited patent

sort patent


*pegarle el ipc3 subcategoria (tecnologia) a la cited patent
merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m

*identificador de cuales cited patentes se dejan
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"

*keep only matched
keep if _m==3
drop _m
rename ipc3 subcat_g

rename subcat_g cited_sub
rename patent cited

*transformación para pegarle a citing
rename citing patent
sort patent
destring patent, force replace
drop if patent==.


*pegarle el ipc3 subcategoria (tecnologia) a la citing patent
merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m

*identificador de cuales citing patentes se dejan
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"

*keep only matched
keep if _m==3
drop _merge


rename ipc3 citing_sub
rename patent citing

//until here we have a citing-cited panel with tecnology subcat



***what period do we want?

*--keep citations from subcat to subcat
keep cited_sub citing_sub

gen dummy = 1
sort cited_sub citing_sub

*collapse sacar la suma de citas de una a otra categoría en total
collapse (sum) dummy, by(cited_sub citing_sub)

sort cited_sub citing_sub
drop if cited_sub==""

*contador de citaciones de una categoría a otra
rename dummy citcount

sort citing_sub

*same
unique cited_sub
unique citing_sub

*--Para subcat que cita - genere el total de citaciones en toda a la base (a diferentes y a la misma subcat)

*Esta generando tanto el total de citaciones que se hace a sí misma, como hace a todas las 121 subclases restantes. Total de citas en toda la vida (total de citas que hace cada patente)
bys citing_sub: egen total1 = total(citcount)


*--Para subcat que cita - genere el total de citaciones en toda a la base (a la misma subcat)

*Esta generando tanto el total de citaciones que se hace a sí misma. Total de citas en toda la vida (total de citas que hace a patentes de su misma clase). Solo lo pone en la observacion subcat=subcat

bys citing_sub: egen total2 = total(citcount) if cited_sub == citing_sub


*--Pegarle la informacion de citas a si misma en todas las obs
bys citing_sub: egen same_prox=mean(total2)


*-Citas a esa categoría específica/total hechas por la sucategoria (% de citas a cada subcategoria/todas las citas a todas las cateogrías)
gen p2p_prox1=(citcount / total1)


*-Citas a esa categoria / proporcion a citas de su misma clase. (% de citas a cada subcategoria/todas las citas a su misma clase)
gen p2p_prox2=(citcount / same_prox)


*-Reemplazar en la proporcion 1  por la proporción 2 si es la misma subcategoría
replace p2p_prox1=p2p_prox2 if cited_sub==citing_sub



gen same_prox2=.

*--Reemplazar en el total de citas a si misma por el % de citas a cada subcategoria todas las citas a todas las cateogrías si es la misma subcategoría
replace same_prox=p2p_prox1 if cited_sub==citing_sub


*--Generar la media a todas las obvservaciones de same_prox2 (que no tiene nada)
bys citing_sub: egen sprox=mean(same_prox2)


*--Dependence= %(citas a esa categoría/citas a su subclase)
gen dependence=p2p_prox2


drop if cited_sub=="" | citing_sub==""



preserve
***When we merge this to soviet data, we want to ??


*Generar IPC3 de la cited
gen g_ipc3 = trim(cited_sub)

*Generar IPC1 (Grupos de la IPC) de la cited
sort g_ipc3
egen g_ipc=group(g_ipc3)


*-Se quita subclass inicial se deja IPC3, IPC1 para Cites
drop cited*


*-Drop original
drop p2p_prox2

*-Rename dependence (es la misma= citas a cada subcat/citas a la misma subcat)
rename dependence p2p_prox2


*--Dejar solo % citas a la misma subcat, citado y IPC1
keep p2p_prox2 citing_sub g_ipc

*--Para cada subcategoría sacar la proporción que le hacen a cada IPC1
reshape wide p2p_prox2, i(citing_sub) j(g_ipc)

*--Renombrar probabilidades - % (citas hechas a cada ipc1/citas hechas a si misma)
rename p2p_prox2* p*_

*--Proporción de que cada IPC1 (tecnología) cite a cada Subcategoría
rename citing_sub cited_sub
save "$wrkdata/IPC3_dependence_long_agg.dta", replace
restore

}



////////////////////////////////////////////////////////////////////////////////////////////
//10. Construction of Main_CP based on merged components.
///////////////////////////////////////////////////////////////////////////////////////////

*1. gen citation_adjusted_breadthdepth_sep20
{
****BUILDING SKILLS BASED ON MERGED COMPONENTS:

*open inventors dataset
use "$output/individuals_CP.dta", clear



duplicates drop patent categ1, force



*--merge forward citations to each patent
merge m:1 patent using "$output/life_cit_IPC1.dta"
drop _m

*--merge issue date to each patent
merge m:1 patent using "$wrkdata/patent_idate.dta"
drop _m

*--merge ipc3 - subcateg to each patent
merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m

*--merge only choosed patents
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"

*--keep only inventors with selected patents from "keep only"
keep if _m==3
drop _m



/*
merge m:1 patent using "$output/dates_CP.dta"
drop _m
*/


*--issue date
rename idate date


*---by inventor id (categ1), set counter for each of the different patents made
bys categ1 (date patent): gen patnumpp1=_n
xtset categ1 patnumpp1

*Lag
gen ttb=date-L.date



gen ptn=1
*replace ptn=1/ts


*--Suma total de diferentes patentes por inventor
bys categ1 (patnumpp1): gen sum_ptn=sum(ptn)

*--Acumulado de patentes hechos hasta ese periodo
gen prev_ptn=sum_ptn-ptn


*--Acumulado de patentes PREVIAS - la primera patente debe tener 0
replace prev_ptn=L.prev_ptn if ttb==0

*--Total de Patentes en losd atos
bys patent: gen tot=_N

*--Panel Inventor-Patente 
xtset categ1 patnumpp1


*--Sub-Categoría 
rename ipc3 cited_sub

*--Mergear datos del IPC3_dependence_long_agg
merge m:1 cited_sub using "$wrkdata/IPC3_dependence_long_agg.dta"
keep if _m==3
drop _m

*--min invseq //cuantos inventores hay en el team
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

///////////////////////////////////////////////
/////		Vectors per person
//////
////////////////////////////////////////////////

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

/////////////
//	Depth (Individual)
//////////////


replace depthrun=runningtype`i' if subcat_g==`i'

replace depthtotal=totaltype`i' if subcat_g==`i'

drop totone`i' runone`i' dummy`i' val`i'



**we can collapse to breadth later 

}

/////////////
//	breadth (Individual)
//////////////

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





/////////////
//	breadth and depth (team)
//////////////

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




*invh_cit

gen invh_cit=ln(exp_cit+(exp_cit^2+1)^0.5)

preserve

keep patent categ1 depthrun breadthrun breadthteam_e depthteam_e invh_cit exp_cit appyear
save "$output/citation_adjusted_breadthdepth_sep20.dta",replace

restore
}


*2. use constructed citation_adjusted_breadthdepth_sep20 and merge ipc3, inventors, issue date

{
use "$output/citation_adjusted_breadthdepth_sep20.dta",replace


drop if appyear==.


**there is the occasiaonl duplicate



*--Merge inventors-patent
duplicates drop categ1 patent, force
merge 1:1 patent categ1 using "$output/individuals_CP.dta"

keep if _m==3
drop _m

*--merge issue date
merge m:1 patent using "$wrkdata/patent_idate.dta"
drop _m

*--merge ipc3
merge m:1 patent using "$output/patent_ipc3_dd.dta" 
drop _m

*--merge patents 
merge m:1 ipc3 using "$wrkdata/ipc3_keep_only"
keep if _m==3
drop _m

*---Dummy for 90's
gen is90s=.
replace is90s=0 if appyear>=1980 & appyear<=1990
replace is90s=1 if appyear>=1991 & appyear<=2000



***time to build:
rename idate date


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


**adjust citations: expected ctitations/ mean of time to build a patent

gen ttb_cit=exp_cit/m_ttb

*Transformation of Adjusted Cites
gen invh_ttb=ln(ttb_cit+(ttb_cit^2+1)^0.5)


*Generate Team Size
bys patent: gen tsize=_N

**group firms

egen assignee =group(asgnum)
replace assignee=0 if assignee==.
keep if appyear>=1975 & appyear<=2010


}


*3. save Main_CP


save "$output/main_CP.dta",replace



use "$output/main_CP.dta",clear

///////////////////////////////////////
///////	11. Creation patent_max_survive
//////////////////////////////////////

{

***create survival measure
preserve

*todos los inventores tienen una importancia en la patente 
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

}



/////////////////////////////////////////////////////////////////////////
///////	12. Gen Final Main_CP: Merge Main_CP and patent_max_survive1 and Citation Measures
/////////////////////////////////////////////////////////////////////////

{
***±Merge dataset:

use "$output/main_CP.dta",clear

merge m:1 patent using "$output/patent_max_survive.dta"
drop _m



*** Add citation measures

merge m:1 patent using "$output/life_cit_IPC1.dta"
drop _m

drop tech_cat  patent_age num


save "$output/main_CP.dta", replace


}

/////////////////////////////////////////////////////////////////////////
///////	13. add Labels to Main_CP
/////////////////////////////////////////////////////////////////////////

***Add labels:
{
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
label var date "Issue Date"
label var ipc3  "IPC three digits"
*label var num "???"
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

* For citation measures
label var exp_cit "Expected Forward Citations (Normalized)"
label var f_cit  "Forward Citations (20 years)"
label var cit3  " 3-year Forward Citations (Adjusted)"
label var cit5  "5-year Forward Citations (Adjusted)"


save "$output/main_CP.dta",replace
}





/////////////////////////////////////////////////////////////////////////
///////	14. Merge Main_CP and NBER subcategories.
/////////////////////////////////////////////////////////////////////////

{
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



}


/////////////////////////////////////////////////////////////////////////
///////	15. Create the patent-level dataset
/////////////////////////////////////////////////////////////////////////


*Only keep patent level data

use "$output/main_CP.dta", clear




*********************************************************************************************************
*********************************************************************************************************
* Additional appyears <1975, >2010 appeared with very few observations: ask Jeremy sept 17 ,2020
*********************************************************************************************************
*********************************************************************************************************

keep if appyear>=1975 & appyear<=2010

save "$output/main_CP.dta",replace

keep patent appyear exp_cit breadthteam_e depthteam_e invh_cit asgnum uspto_class date ipc3 m_ttb ttb_cit invh_ttb tsize survive 

duplicates drop patent, force

save "$output/main_pat_lev_CP.dta", replace


***we still need to make distance measures, type measures, etc.

