**************************************************
*		Citation Datasets Input: Harvard
*
**************************************************

/////////////////////////////////////////////////////////////////////////////////////////////
//1. Creation of citations_by_yr and Citation_event_time_ipc 
///////////////////////////////////////////////////////////////////////////////////////////

{

*1) import data of the patent citated by each citing patent. Merges information about the citing patent (app year and grant date). Creates citations_by_yr

*! citations_by_yr: *data of cited patent and citing patent - cleaned by self-citations (still not a panel)

{
use "$rawdata/USPTO/uscites2020.dta", clear

merge m:1 patent using "$datasets/tmp_Patent_Harvard.dta"

drop if _m==2
drop _m

/*
We are only dropping those patents in Patent File that aren't "citing"= in other words, citing=.
*/

*2) create a panel dataset patent-year level cited with the number of cumulative citations over the years, max citations for each year, ipc1 
*merge to each citing patent the assignee (firm)

merge m:1 patent using "$datasets/tmp_Assignee_Harvard.dta", gen(m2)

drop if m2==2
drop m2

/*
We are only dropping those patents in Patent File that aren't "citing"= in other words, citing=.
*/

***USE FIRM TO DROP SELF-CITATIONS ON THE SAME ASSIGNEE

rename assignee_id citing_pdp
rename patent citing

rename cited patent

merge m:1 patent using "$datasets/tmp_Assignee_Harvard.dta"
rename assignee_id cited_pdp


drop if _m==2
drop _m


*DROP SELF CITATIONS?
gen asg_self_cite=1 if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~=""
	replace asg_self_cite=0 if asg_self_cite==.
	
	*9,288,845 are self cit, From the same assignee to the same assignee.
		
*application yeat for citing patent
rename appyear citing_appyear

*merge information on application and grant to cited patent

merge m:1 patent using "$datasets/tmp_Patent_Harvard.dta", gen(ay_merge2)
drop if ay_merge2==2
*14,365,498 not merged cited patents (obs)

rename appyear cited_appyear
*keep if ay_merge2==3
drop if citing=="" | patent==""

*merge ipc3 info to the cited pat.
merge m:1 patent using "$datasets/tmp_ipc3_Harvard.dta" , keepusing(ipc3)
drop if _m==2
drop _m

*Save data of cited patent and citing patent (still not a panel)
save "$datasets/citations_by_yr_Harvard.dta",replace

}

*2) create a panel dataset patent-year level cited with the number of forward citations over the years, max citations for each year, ipc1: Citation_event_time_ipc

*! Citation_event_time_ipc: Clean Citations Dataset and create a patent-year dataset with cumulative citations, and max citations per year


{

drop ay_merge2
rename patent cited

*Numero maximo de veces que fue citado en un mismo año
bysort cited citing_appyear:gen f_cityr=_N if citing_appyear!=.

*Numero máximo de veces que fue citado (veces que aparece en la base de datos)
bys cited : gen f_cit_tot=_N
gen dummy=1


*total de veces que fue citado a lo largo de los años
bysort cited: egen forward_cit_total=total(dummy)

*año que fue citada la patente
rename citing_appyear citingyear

*crear ipc3 para la patente citada
gen ipc1=substr(ipc3,1,1)

keep f_cityr forward_cit_total cited citingyear ipc1

compress

*dejar base nivel (patente, año  que fue citada) - y se deja el total de citas que tuvo cada año (f_cityr)
duplicates drop cited citingyear, force

sort cited citingyear

drop if citingyear==.
save "$datasets/Citation_event_time_ipc_Harvard.dta",replace

}

}

////////////////////////////////////////////////////////////////////////////////////////////
//2. Creation of Citation Profile
///////////////////////////////////////////////////////////////////////////////////////////

*--Created PDF, CDF and average ratio of number of citations of the tecnology/total patents of the tecnology by each lag (Year Cited-App Year)
{
***read in new revenue stuff

*--Open Data: patent, appyear, grantyear, grantdate
use "$datasets/tmp_Patent_Harvard.dta",clear

rename patent cited

*--Unir información panel patente-años y su appyear, grantyear, grantdate
merge 1:m cited using "$datasets/Citation_event_time_ipc_Harvard.dta"

rename cited patent

*Solo dejar patentes con información de su fecha, citas cumulativas
keep if _merge==3
drop _m


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



*--Por cada año de citacion de una patente, sacar el ratio de citaciones
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


save "$datasets/Citation Profile1020_Harvard.dta", replace


}


////////////////////////////////////////////////////////////////////////////////////////////
//3. Creation of life_cit_IPC1
///////////////////////////////////////////////////////////////////////////////////////////

*---For each patent, creates the number of forward citations (cumulative for 20 years) and the expected citations depending on the class ipc1 (tecnology). Retrieves the average citation of the tecnology at lag=3 and, average citation of the tecnology lag=5

{

*--patente, app year
use "$datasets/tmp_Patent_Harvard.dta",clear

*--Merge to cited data the app year (dataset of cited-citing)

merge 1:m patent using "$datasets/citations_by_yr_Harvard.dta", gen(cit_merge)
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

merge m:1 ipc1 using "$datasets/Citation Profile1020_Harvard.dta"
keep if _merge==3

*--Edad de la patente (sólo se cogen patentes hasta 2020)
gen patent_age=2010-appyear

*--Para cada diferente pat en la data

duplicates drop patent,force
gen exp_cit=.

*--Crear esperado de citas dado la edad de la patente:

forvalues x=0/20{
replace exp_cit=f_cit/cdf_cit`x' if patent_age==`x'
}

replace exp_cit=f_cit if patent_age>20

*--Dejan ratio de citas a 3 años y a 5 años de la misma tecnologia
keep patent exp_cit tech_cat patent_age f_cit appyear patent_age cit3 cit5 cit8

label var f_cit "forward citation(max 20 year)"
label var patent_age "Current Age"
label var exp_cit "Expected Forward Citation" ///that depends on the tecnology

sort patent appyear

save "$datasets/life_cit_IPC1_Harvard.dta",replace



}

////////////////////////////////////////////////////////////////////////////////////////////
//4.Creation of IPC3_dependence_long_agg 
///////////////////////////////////////////////////////////////////////////////////////////

{

***IPC3 connectivity*****
use "$rawdata/USPTO/uscites2020.dta", clear
rename patent citing
rename cited patent

*pegarle el ipc3 subcategoria (tecnologia) a la cited patent
merge m:1 patent using "$datasets/tmp_ipc3_Harvard.dta" 
drop _m

*identificador de cuales ipc's se dejan
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" 

*keep only matched
keep if _m==3
drop _m
rename ipc3 subcat_g

rename subcat_g cited_sub
rename patent cited

*transformación para pegarle a citing
rename citing patent
sort patent

*pegarle el ipc3 subcategoria (tecnologia) a la citing patent
merge m:1 patent using "$datasets/tmp_ipc3_Harvard.dta"
drop _m

*identificador de cuales citing patentes se dejan
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f.dta" 

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
save "$datasets/IPC3_dependence_long_agg_Harvard.dta", replace

}


////////////////////////////////////////////////////////////////////////////////////////////
//5. Creation of citation_adjusted + Breadh and Depth Data
///////////////////////////////////////////////////////////////////////////////////////////

{
****BUILDING SKILLS BASED ON MERGED COMPONENTS:

*open inventors dataset
use "$datasets/tmp_Individuals_Harvard.dta", clear

*--merge forward citations to each patent
merge m:1 patent using "$datasets/life_cit_IPC1_Harvard.dta"
drop _m

*--merge issue date to each patent
merge m:1 patent using "$datasets/tmp_Patent_Harvard.dta"
drop _m

*--merge ipc3 - subcateg to each patent
merge m:1 patent using "$datasets/tmp_ipc3_Harvard.dta" 
drop _m

*--merge only choosed patents
merge m:1 ipc3 using "$datasets/patent_ipc3_100_f"

*--keep only inventors with selected patents from "keep only"
keep if _m==3
drop _m


*--issue date
rename gdate date

egen pat=group(patent)


*---by inventor id (categ1), set counter for each of the different patents made
bys categ1 (date pat): gen patnumpp1=_n
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
bys pat: gen tot=_N

*--Panel Inventor-Patente 
xtset categ1 patnumpp1


*--Sub-Categoría 
rename ipc3 cited_sub

*--Mergear datos del IPC3_dependence_long_agg
merge m:1 cited_sub using "$datasets/IPC3_dependence_long_agg_Harvard.dta"
keep if _m==3
drop _m


*--min invseq //cuantos inventores hay en el team

*1) First Way
bys patent: egen minvseq=min(invseq)
gen invseq2=invseq
replace invseq2=invseq+1 if minvseq==0


*2) Second Way (Without Invseq - simulating tsize)

bys patent: gen invcounter=_n if categ1!=.


sort categ1 patnumpp1

gen dummy=1

gen connec_bb=.

gen mconnec_bb=.

gen depthrun=.

gen depthtotal=.

gen weight=1/tot


*replace weight=0 if weight~=1

bys categ1: gen totpat=_N

replace exp_cit=. if invcounter!=1

bys appyear: egen mcit=mean(exp_cit)

replace exp_cit=exp_cit/mcit

bys patent:egen cit=mean(exp_cit)

replace exp_cit=cit

{


**MOVE TO SERVER

gen depth_unadj=.

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

}

*invh_cit

gen invh_cit=ln(exp_cit+(exp_cit^2+1)^0.5)

keep patent categ1 invh_cit exp_cit totpat
save "$datasets/citation_adjusted_Harvard.dta",replace

}
