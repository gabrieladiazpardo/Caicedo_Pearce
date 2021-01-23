**********************
* Backward citations
**********************

use "$rawdata/uscites2020.dta", clear


***merge with relevant patent info
merge m:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop if _m==2
drop _merge

rename patent citing
rename cited patent
rename appyear citing_appyear

merge m:1 patent using "$datasets/patents_uspto_for_cit.dta", gen(ay_merge2)
drop if ay_merge2==2
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

**Base de datos cited, citing level. Solo obs con assignee e ipc3. No se dropea las patentes que citan al mismo assignee, pero sí se identifican. 


*Para cada citing, NO CITED. Es backward. Cuantas citas para tras hace cada patente

*Cuantas diferentes cited hace una misma citing (una misma patente) - cuantas veces diferentes aparece una misma citing patents. Si aparece más de una vez es porque realiza mas de una cita. 

*create citing- cited to know the age of the cited patent. 
gen cit_pat_age=citing_appyear-cited_appyear

*Fix Patent Age
count if cit_pat_age<0
count if cit_pat_age>114 & cit_pat_age!=.
replace cit_pat_age=0 if cit_pat_age<0
replace cit_pat_age=114 if cit_pat_age>114 & cit_pat_age!=.

tab cit_pat_age, m

*Para cada patente citada en cada año de vejez, cuantas veces fue citada maximo
bys citing cit_pat_age:  gen cit_yr=_N

*--Numero de citas que hace en total backward
bys citing : gen b_cit=_N

*--Mean of the lag for all citations
bys citing : egen mean_pat_age=mean(cit_pat_age)

*Dejar Panel nivel de citada, cada posible lag (0,114)
duplicates drop citing cit_pat_age, force

*Dejar sólo id de la patente citada y el numero maximo de citaciciones recibidas por cada lag 
keep citing cit_pat_age cit_yr b_cit mean_pat_age

*total cites made cumulative; needs to match with b_cit
bys citing: egen b_cit_cum=total(cit_yr)

gen coinc=1 if b_cit==b_cit_cum
tab coinc, m // all match
drop coinc

*total cites made

bys citing: egen b_cit_cum_unidentified=total(cit_yr) if cit_pat_age==.
bys citing: egen b_cit_cum_unident=max(b_cit_cum_unidentified)
drop b_cit_cum_unidentified

count if b_cit_cum_ident!=. & b_cit_cum_unident==.
replace b_cit_cum_unident=0 if b_cit_cum_unident==.

*percentage of unidentified b_cit
gen share_unident=b_cit_cum_unident/b_cit*100

compress
drop b_cit_cum
save "$datasets/b_cit_panel_pat_age.dta", replace

keep citing cit_pat_age cit_yr b_cit mean_pat_age share_unident

save "$datasets/b_cit_panel_pat_age_reduced.dta", replace


*Reshape para que quede a nivel de sólo patentes. Crear una variable que sea maximo de citaciones recibidas por cada lag. (0,5)

keep citing cit_pat_age cit_yr b_cit 

replace cit_pat_age=5000 if cit_pat_age==.

rename citing patent 

reshape wide cit_yr, i(patent) j(cit_pat_age)

*generate rowtotal // needs to match with bcit
egen cum_b_cit=rowtotal(cit_yr*)

*verify match
br b_cit cum_b_cit //match.
 
*merge application date 
merge 1:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop if _m==2
drop _m appdate

*save data
compress
save "$datasets/b_cit_by_pat_age_wide.dta", replace


*Compute b_cit cumulative

use "$datasets/b_cit_by_pat_age_wide.dta", clear

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen b_cit3= rowtotal( cit_yr0 cit_yr1 cit_yr2 cit_yr3)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen b_cit5= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 8. 
egen b_cit8= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5 cit_yr6 cit_yr7 cit_yr8)

rename cit_yr5000 b_cit_unident
egen b_cit_ident=rowtotal(cit_yr*)
replace b_cit_unident=0 if b_cit_unident==.
replace b_cit_ident=0 if b_cit_ident==.

br b_cit_unident b_cit_ident b_cit
gen share_unident=b_cit_unident/b_cit*100

br b_cit_unident b_cit_ident b_cit share_unident

label var b_cit3 "3-year Backward Citations"
label var b_cit5 "5-year Backward Citations"
label var b_cit8 "8-year Backward Citations"
label var b_cit_unident "Backward Citations with unidentified application year"
label var b_cit_ident "Backward Citations with identified application year"
label var b_cit "Backward Citations (Total Citations Made)"
label var share_unident "Share of backward Citations with unidentified application year"

keep patent b_cit_unident b_cit_ident b_cit b_cit3 b_cit5 b_cit8 share_unident appyear

order patent appyear b_cit_unident b_cit_ident b_cit share_unident b_cit3 b_cit5 b_cit8

replace b_cit_unident=0 if b_cit_unident==.

compress

save "$datasets/b_cit_patent.dta", replace