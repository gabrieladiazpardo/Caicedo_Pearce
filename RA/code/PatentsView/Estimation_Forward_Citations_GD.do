***********************
* Forward citations
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
bys cited cit_pat_age:  gen cit_yr=_N

*--Numero de citas que hace en total backward
bys cited : gen f_cit=_N

*media de lag cuando es citada
bys cited: egen mean_lag_fcit=mean(cit_pat_age)

*Dejar Panel nivel de citada, cada posible lag (0,114)
duplicates drop cited cit_pat_age, force

*Dejar sólo id de la patente citada y el numero maximo de citaciciones recibidas por cada lag 
keep cited cit_pat_age cit_yr f_cit mean_lag_fcit 

*total cites made cumulative; needs to match with b_cit
bys cited: egen f_cit_cum=total(cit_yr)

gen coinc=1 if f_cit==f_cit_cum
tab coinc, m // all match
drop coinc

*total cites made
bys cited: egen f_cit_cum_identified=total(cit_yr) if cit_pat_age!=.
bys cited: egen f_cit_cum_ident=max(f_cit_cum_identified)
drop f_cit_cum_identified

*total cites unidentified
gen f_cit_cum_unident=f_cit-f_cit_cum_ident

*percentage of unidentified b_cit
gen share_unident=f_cit_cum_unident/f_cit*100

compress
drop f_cit_cum
save "$datasets/f_cit_panel_pat_age.dta", replace

keep cited cit_pat_age cit_yr f_cit mean_lag_fcit 
compress
save "$datasets/f_cit_panel_pat_age_reduced.dta", replace


keep cited cit_pat_age cit_yr f_cit 

replace cit_pat_age=5000 if cit_pat_age==.

rename cited patent 

reshape wide cit_yr, i(patent) j(cit_pat_age)

*generate rowtotal // needs to match with bcit
egen cum_f_cit=rowtotal(cit_yr*)

*verify match
br f_cit cum_f_cit //match.
 
*merge application date 
merge 1:1 patent using "$datasets/patents_uspto_for_cit.dta"
drop _m appdate

*save data
compress
save "$datasets/f_cit_by_pat_age_wide.dta", replace


*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen f_cit3= rowtotal( cit_yr0 cit_yr1 cit_yr2 cit_yr3)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 3. 
egen f_cit5= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5)

*Se crea el acumulado. Cuantas citas ha recibido desde el año 0 hasta el 8. 
egen f_cit8= rowtotal(cit_yr0 cit_yr1 cit_yr2 cit_yr3 cit_yr4 cit_yr5 cit_yr6 cit_yr7 cit_yr8)
**********************
* Forward citations
**********************

rename cit_yr5000 f_cit_unident

egen f_cit_ident=rowtotal(cit_yr*)

*verify
br f_cit_unident f_cit_ident f_cit


label var f_cit3 "3-year Forward Citations"
label var f_cit5 "5-year Forward Citations"
label var f_cit8 "8-year Forward Citations"
label var f_cit_unident "Forward Citations with unidentified application year"
label var f_cit_ident "Forward Citations with identified application year"
label var f_cit "Forward Citations (Total Citations Received)"


keep patent f_cit_unident f_cit_ident f_cit f_cit3 f_cit5 f_cit8

order patent f_cit_unident f_cit_ident f_cit f_cit3 f_cit5 f_cit8

replace f_cit_unident=0 if f_cit_unident==.

compress

save "$datasets/f_cit_patent.dta", replace
