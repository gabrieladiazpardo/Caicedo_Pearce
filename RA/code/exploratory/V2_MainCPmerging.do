

*save string: data version
global save_str _uspto


////////////////////////////////////////////////////////////////////////////////////////////
//1. Creation of citations_by_yr and Citation_event_time_ipc 
///////////////////////////////////////////////////////////////////////////////////////////

*! citations_by_yr: *data of cited patent and citing patent - cleaned by self-citations (still not a panel)

*! Citation_event_time_ipc: Clean Citations Dataset and create a patent-year dataset with cumulative citations, and max citations per year

*1) import data of the patent citated by each citing patent. Merges information about the citing patent (app year and grant date)

*-------------------------------*
*		Citing
*
*--------------------------------*
{

use "$datasets/uspto_patent_ipc3.dta", clear

merge 1:m patent using "$data/uscites2015.dta", gen (m0)

*------not matched (9,682,327 obs)

unique patent if m0==3 
// 4,393,534 matched patents

unique patent if m0==1 
//2,233,409 not matched from uspto

unique patent if m0==2 
// 806,676 from uscites2015

tab gyear if m0==1 
 

*only keep citing patents in uspto
keep if m0==3 
// 4,393,5340 unique patents
*---Patents that have both IPC3 and Assignee Harmonized Code


*Rename variables for citing
rename patent citing 

rename (gdate gyear ipc3 assignee_harmonized appyear appdate) (gdate_citing gyear_citing ipc3_citing citing_pdp appyear_citing appdate_citing)


/* ACTION DATE = DATE CITE*/

drop country


rename appyear_citing citing_appyear

*-------------------------------*
*		Citations_by_year
*
*--------------------------------*


*Merge Data for Cited
rename cited patent

drop if citing==""
drop if patent==.


tostring patent, replace

merge m:1 patent using "$datasets/uspto_patent_ipc3.dta", gen (m1)



/*
 14,862,276 not matched
From Master=  13,314,735
From using= 1,547,541  	

*/


keep if m1==3


rename (gdate gyear ipc3 assignee_harmonized appyear appdate) (gdate_cited gyear_cited ipc3_cited cited_pdp appyear_cited appdate_cited)

drop country m1 m0 

**Drop self citations

count if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~="0"
****4,963,020

drop if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~="0"


compress

*Save data of cited patent and citing patent (still not a panel)
save "$datasets/citations_by_yr$save_str.dta",replace

}

*2) create a panel dataset patent-year level cited with the number of forward citations over the years, max citations for each year, ipc1 

{
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
gen ipc1_cited=substr(ipc3_cited,1,1)

keep f_cityr forward_cit_total cited citingyear ipc1_cited

compress


*dejar base nivel (patente, año  que fue citada) - y se deja el total de citas que tuvo cada año (f_cityr)
duplicates drop cited citingyear, force

sort cited citingyear

save "$datasets/Citation_event_time_ipc$save_str.dta",replace


}


////////////////////////////////////////////////////////////////////////////////////////////
//2. Creation of Citation Profile0920
///////////////////////////////////////////////////////////////////////////////////////////

*--Created PDF, CDF and average ratio of number of citations of the tecnology/total patents of the tecnology by each lag (Year Cited-App Year)
{
***read in new revenue stuff

*--Open Data: patent, appyear, grantyear, grantdate
use "$datasets/uspto_patent_ipc3.dta", clear

*--citations
rename patent cited

*--Unir información panel patente-años y su appyear, grantyear, grantdate
merge 1:m cited using "$datasets/Citation_event_time_ipc$save_str.dta"

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

************************
*Until now, 3,002,301 cited patents
*
*************************

*Numero por cada ipc1 category (Tecnología)
encode ipc1_cited, gen(tech_cat)


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
collapse (mean) cit,by(patent_age tech_cat ipc1_cited)

sort tech_cat patent_age 

*-Por cada tecnología, saque el promedio de citas en cada lag
reshape wide cit, i(tech_cat ipc1_cited) j(patent_age)

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


save "$datasets/Citation Profile1020$save_str.dta", replace
}


////////////////////////////////////////////////////////////////////////////////////////////
//8. life_cit_IPC1
///////////////////////////////////////////////////////////////////////////////////////////

*---For each patent, creates the number of forward citations (cumulative for 20 years) and the expected citations depending on the class ipc1 (tecnology). Retrieves the average citation of the tecnology at lag=3 and, average citation of the tecnology lag=5

{

use "$datasets/all_patent_uspto.dta", clear
 
drop if appyear>2015 /*We are merging all patents reported in upsto. However our citation measures are until 2015. Replace them as 0 citations would be wrong*/

merge 1:m patent using "$datasets/citations_by_yr_uspto", gen(cit_merge)

/*2,693,069 not matched from all patents; therefore they are not "cited"*/

drop if cit_merge==2


*lag (citing app year - cited app year)
gen patent_age=citing_appyear-appyear

rename citing_appyear citingyear
gen dummy=1

*--Para cada difernte patente - saque el total de citas diferentes que le hicieron a lo largo de los 20 años

bysort patent:egen f_cit=total(dummy) if patent_age<=20 | patent_age>=0


*--Poner 0 citas si tiene fecha y no citas
replace f_cit=0 if cit_merge==1
// 3,693,069 were cited 0  - is it true????

*--Panel a nivel de año
duplicates drop patent,force


gen ipc1_cited=substr(ipc3_cited,1,1)
keep patent appyear f_cit ipc1_cited

sort patent appyear

*-- a cada patente de clase ipc pegarle el citation profile del ipc

merge m:1 ipc1_cited using "$datasets/Citation Profile1020$save_str.dta"
keep if _merge==3 // 2,780,683  not mached


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
label var exp_cit "Expected Forward Citation" 
///that depends on the tecnology

sort patent appyear

save "$datasets/life_cit_IPC1$save_str.dta",replace


}


////////////////////////////////////////////////////////////////////////////////////////////
//9. IPC3_dependence_long_agg 
///////////////////////////////////////////////////////////////////////////////////////////



***IPC3 connectivity*****

{
****1) CITED
use "$data/uscites2015.dta", clear
rename patent citing
rename cited patent_id
tostring patent_id, replace

sort patent_id

*pegarle el ipc3 subcategoria (tecnologia) a la cited patent

merge m:1 patent_id using "$datasets/uspto_ipc3.dta" 
drop _m
drop classification_level char
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" 


/* 14,095,494 obs not matched; 3,151,255 from ipc */ 

keep if _m==3
drop _m

rename ipc3 subcat_g
rename subcat_g cited_sub
rename patent cited

*transformación para pegarle a citing
rename citing patent_id


****1) CITING
*identificador de cuales citing patentes se dejan
merge m:1 patent_id using "$datasets/uspto_ipc3.dta" 
drop _m
drop classification_level char
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" 

keep if _m==3
drop _m



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
save "$datasets/IPC3_dependence_long_agg$save_str.dta", replace
restore


}




//////////////////////
////
////////////////////

use "$datasets/uspto_patent_inventor_ipc3.dta", clear

rename inventor_id categ1

*--merge patents ipc3
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" 
keep if _m==3
drop _m


merge m:1 patent using "$datasets/life_cit_IPC1$save_str.dta"
drop _m

*Not merged 4,425,968!!!


*---Dummy for 90's
gen is90s=.
replace is90s=0 if appyear>=1980 & appyear<=1990
replace is90s=1 if appyear>=1991 & appyear<=2000



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
