
*-----This data is in a cited, citing level. 

*-----This data is in a cited, citing level. 
 
{

use "$datasets/citations_by_yr_all", replace
 
drop ay_merge2

*create citing- cited to know the age of the cited patent. 
gen cit_pat_age=citing_appyear-cited_appyear

*Keep only patents cited between 0 to 8 years. 

keep if cit_pat_age>=0 & cit_pat_age<=8

*Para cada patente citada en cada año de vejez, cuantas veces fue citada maximo
bys patent cit_pat_age:  gen cit_yr=_N

*Dejar Panel nivel de citada, cada posible lag (0,5)
duplicates drop patent cit_pat_age, force

*Dejar sólo id de la patente citada y el numero maximo de citaciciones recibidas por cada lag 
keep patent cit_pat_age cit_yr


*Reshape para que quede a nivel de sólo patentes. Crear una variable que sea maximo de citaciones recibidas por cada lag. (0,5)
reshape wide cit_yr, i(patent) j(cit_pat_age)


*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen f_cit3= rowtotal( cit_yr0 cit_yr1 cit_yr2 cit_yr3)


*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen f_cit5= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 8. 
egen f_cit8= rowtotal( cit_yr*)

drop cit_yr*


label var f_cit3 "3-year Forward Citations (No Adjustment)"
label var f_cit5 "5-year Forward Citations (No Adjustment)"
label var f_cit8 "8-year Forward Citations (No Adjustment)"

**Esta base de datos sólo tiene las citas acumuladas - recibidas - para cada patente a los 3 años de edad, y a los 5 años de edad.

*Se le pega a cada patente y se sabe el acumulado de forward que recibio a los 3 y 5 años old.

save "$datasets/f_cit_all", replace



}

**********************
* Backward citations
**********************
{


use "$rawdata/uscites2020.dta", clear


***merge with relevant patent info
merge m:1 patent using "$datasets/tmp_patents_uspto_2.dta"
drop _merge


*merge to each citing patent the assignee (firm)
merge m:1 patent using "$datasets/tmp_first_assignee_uspto.dta"
drop _m


***Use ipc3 to identify self-citations 
merge m:1 patent using "$datasets/tmp_uspto_ipc3.dta" , keepusing(ipc3)
drop _m


rename assignee_id citing_pdp
rename ipc3 citing_ipc3
rename patent citing

rename cited patent

merge m:1 patent using "$datasets/tmp_first_assignee_uspto.dta"
drop _m

merge m:1 patent using "$datasets/tmp_uspto_ipc3.dta" , keepusing(ipc3)
drop _m

rename assignee_id cited_pdp
rename ipc3 cited_ipc3

*gen self_cite variable - Assugnee level. Citing assignee= cited assignee


**Que sea el mismo assignee en la cited y citing y que sean iguales porque tienen información (evitar =1 si no tiene info sobre el assignee - blank)
gen asg_self_cite=1 if cited_pdp==citing_pdp & cited_pdp~="" & cited_pdp~=""
	replace asg_self_cite=0 if asg_self_cite==.

*Citas a la misma subclase
gen ipc3_self_cite=1 if cited_ipc3==citing_ipc3 & cited_ipc3~="" & cited_ipc3~=""
	replace ipc3_self_cite=0 if ipc3_self_cite==.

	
*Citas identificadas 

gen ident_cit=1 if cited_pdp!="" & citing_pdp!=""
	replace ident_cit=0 if ident_cit==.

rename appyear citing_appyear

merge m:1 patent using "$datasets/tmp_patents_uspto_2.dta", gen(ay_merge2)

rename appyear cited_appyear
drop if citing=="" | patent==""

drop ay_merge2 

rename patent cited

order citing cited citing_appyear cited_appyear

sort citing citing_appyear

*label variables
label var citing "Citing Patent"
label var cited  "Cited Patent"
label var citing_appyear  "Citing Patent Application Year"
label var cited_appyear  "Cited Patent Application Year"
label var citing_pdp  "Citing Patent Assignee"
label var citing_ipc3 "Citing Patent IPC3"
label var cited_pdp  "Cited Patent Assignee"
label var cited_ipc3 "Cited Patent IPC3"
label var asg_self_cite "Self-citing Assignee"
label var ipc3_self_cite "Self-citing IPC3"

**Base de datos cited, citing level. Solo obs con assignee e ipc3. No se dropea las patentes que citan al mismo assignee, pero sí se identifican. 


*Para cada citing, NO CITED. Es backward. Cuantas citas para tras hace cada patente

*Cuantas diferentes cited hace una misma citing (una misma patente) - cuantas veces diferentes aparece una misma citing patents. Si aparece más de una vez es porque realiza mas de una cita. 

*--Numero de citas que hace en total backward
bys citing : gen b_cit=_N

*---Numero total de citas que hace una citing patent a la misma assignee
bys citing : egen cit_same_asg=sum(asg_self_cite)

*---Numero total de citas identificadas que tiene una patente
bys citing : egen cit_ident_asg=sum(ident_cit)

drop b_cit ident_cit

*Numero total de veces que una patente hace assignee self citations
bys citing asg_self_cite: gen temp_sc=_N if asg_self_cite==1
	replace temp_sc=0 if temp_sc==.
	
*Diferente número de citas que hace la citing patent a citas del mismo assignee	
bys citing : egen b_cit_asg_sc=max(temp_sc)
drop temp_sc


*Numero de veces que la patente cita patente de la misma ipc3
bys citing ipc3_self_cite: gen temp_sc=_N if ipc3_self_cite==1
	replace temp_sc=0 if temp_sc==.
	
*Diferente número de citas que hace la citing patent a citas del mismo ipc3
bys citing : egen b_cit_ipc3_sc=max(temp_sc)
drop temp_sc	
	


	
duplicates drop citing, force

rename citing patent 

keep patent asg_self_cite ipc3_self_cite cit_same_asg cit_same_asg cit_ident_asg b_cit_asg_sc b_cit_ipc3_sc b_cit

label var b_cit "Backward Citations"
label var b_cit_asg_sc "Backward Citations to Same Assignee"
label var b_cit_ipc3_sc "Backward Citations to Same IPC3"
label var cit_same_asg "Backward Citations to Same Assignee"
label var cit_ident_asg "Backward Citations to Identified Assignees"

save "$datasets/b_cit_all.dta",replace

}

