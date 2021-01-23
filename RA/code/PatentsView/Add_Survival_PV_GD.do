**Saving options
global save_fig 1 //  0 //
global save_dataset  1 // 0 // 


**Graph options
graph set window fontface "Garamond"
global size_font large // medlarge //


**********************************************************************************************
* Survival measure
**********************************************************************************************
use "$datasets/survival_PV.dta", clear

*create all pairs
expand tsize
sort patent categ1

*contador de veces que aparece repetido inv-patente en la base en pares (numero de obs repetida es el numero de pares existentes de inventores dentro de una misma patente)
bys patent categ1: gen numid2 = _n

*generar id del coinventor 
by patent: gen id_coinv = categ1[tsize * numid2]

rename categ1 id_inv

*drop same pairs (including patents of tsize=1)
sort patent id_inv rpat

*dropear observaciones con el mismo id inventor. Se eliminan patentes con tsize=1
drop if id_inv==id_coinv

*Create alternative measure for team size
keep if tsize>1

gen tsize2=tsize if tsize<=5
	replace tsize2=5 if tsize>5
	
	
*identify group unique groups inv- coinv
order patent date appyear id_inv id_coinv


*generar un id unico de cada pareja de inventor y coinventor
egen g_coinv = group(id_inv id_coinv)

/*
*string for unique pair
tostring id_inv, replace
tostring id_coinv, replace

*dummy for dyad pair
generate first = cond(id_inv < id_coinv, id_inv, id_coinv)
generate second = cond(id_inv < id_coinv, id_coinv, id_inv)

*unique pair numner
egen id = group(first second)

drop first second

*back to numeric
destring id_inv, replace
destring id_coinv, replace
*/

compress


**Identifiers year, patent, inventors

*dummy of change of appyear
sort appyear 
gen dyear=1 if appyear[_n]!=appyear[_n-1]

*dummy of change of patent
sort patent id_inv rpat
gen dpat=1 if patent[_n]!=patent[_n-1]

*dummy of change of inventor
sort id_inv
gen dinv=1 if id_inv[_n]!=id_inv[_n-1]

**Identifiers coinventors

*drep_coinv-------identifies for each inv that repeat coinventor in next patent - lo pone en la patente previa

bys id_inv (id_coinv rpat) : gen drep_coinv=1 if g_coinv[_n]==g_coinv[_n+1]
	replace drep_coinv=0 if drep_coinv==.
	
*drep_alo_coinv-------para la patente previa le pone a todas sus observaciones 1 si al menos repite 1 coninventor - lo pone en la patente previa.

bys id_inv rpat : egen drep_alo_coinv=max( drep_coinv)
	replace drep_alo_coinv=0 if drep_alo_coinv==.
	

*dinv_rpat---------dummy to identify change in inventor for each running patent (1,2,3,4)	
bys rpat (id_inv appyear): gen dinv_rpat=1 if id_inv[_n-1]~=id_inv[_n]
	replace dinv_rpat=0 if dinv_rpat==.

*drpat_inv--------dummy to identify inventors that have next patent (dummys se pone en la última obs del inventor antes de que patente una nueva patente)
bys id_inv (rpat): gen drpat_inv=1 if rpat[_n]~=rpat[_n+1] & rpat[_n+1]!=.
	replace drpat_inv=0 if drpat_inv==.
	 
	 compress
	 
*GD - dnext_pat - Dummy si el individuo tendrá una próxima patente
bys id_inv rpat:  egen dinv_next_pat=max(drpat_inv)
	replace dinv_next_pat=0 if dinv_next_pat==.
	
	
*--------------------------------------------------
** Probability of at least one repeated coinventor
*--------------------------------------------------

*--Inventors next patent
*count the number of inventors that have a next patent by appyear
bys appyear : egen Ndrpat_inv=total(drpat_inv)

*count the number of inventors that have a next patent by appyear
bys appyear ipc1: egen Ndrpat_inv_ipc1=total(drpat_inv)

*count the number of inventors that have a next patent by appyear
bys appyear tsize2: egen Ndrpat_inv_tsize2=total(drpat_inv)


*--Coinventors 
*count the number of inventors that repeated coinventors in next patent
bys appyear : egen Ndrep_alo_coinv=total(drep_alo_coinv*drpat_inv)

*count the number of inventors that repeated coinventors in next patent
bys appyear ipc1: egen Ndrep_alo_coinv_ipc1=total(drep_alo_coinv*drpat_inv)

*count the number of inventors that repeated coinventors in next patent
bys appyear tsize2: egen Ndrep_alo_coinv_tsize2=total(drep_alo_coinv*drpat_inv)

*probability of at least one repeated coinventor
gen pr_alo_coinv=Ndrep_alo_coinv/Ndrpat_inv

*probability of at least one repeated coinventor (ipc)
gen pr_alo_coinv_ipc1=Ndrep_alo_coinv_ipc1/Ndrpat_inv_ipc1

*probability of at least one repeated coinventor (tsize)
gen pr_alo_coinv_tsize2=Ndrep_alo_coinv_tsize2/Ndrpat_inv_tsize2

drop Ndrep_alo_coinv Ndrep_alo_coinv_ipc1 Ndrep_alo_coinv_tsize2

compress

*-------------------------------------------
** Fraction of repeated coinventors by year
*-------------------------------------------

*Number of repeated coinventors
bys patent : egen Nrep_coinv=total(drep_coinv*drpat_inv)

*fraction of repeated coinventors by patent
gen frac_rep_coinv=Nrep_coinv/tsize

*dummy of patents with inventors that have next patent
bys patent: egen dpat_rpat_inv=max(drpat_inv)
	replace dpat_rpat_inv=. if dpat_rpat_inv==0

*out of all patents
bys appyear : egen mpat_frac_rep_coinv=mean(frac_rep_coinv*dpat)

*out of all patents that have inventors that have next patent
bys appyear : egen mrpat_frac_rep_coinv=mean(frac_rep_coinv*dpat_rpat_inv*dpat)

*GD - mean number of repeted coinventors per patent - this measure computed by ipc3 and tsize

bys appyear :  egen mNrep_coinv=mean(Nrep_coinv)

bys appyear ipc1:  egen mNrep_coinv_ipc1=mean(Nrep_coinv)

bys appyear tsize2  egen mNrep_coinv_tsize2=mean(Nrep_coinv)

*------------------------
* Repeat all coinventors
*------------------------

*dummy of inventors that repeated all coinventors
bys id_inv : gen drep_all_coinv=1 if Nrep_coinv==tsize
	replace drep_all_coinv=0 if drep_all_coinv==.

*count the number of inventors that repeated all coinventors in next patent
bys appyear : egen Ndrep_all_coinv=total(drep_all_coinv*drpat_inv)

*count the number of inventors that repeated all coinventors in next patent
bys appyear ipc1: egen Ndrep_all_coinv_ipc1=total(drep_all_coinv*drpat_inv)

*count the number of inventors that repeated all coinventors in next patent
bys appyear tsize2: egen Ndrep_all_coinv_tsize2=total(drep_all_coinv*drpat_inv)


*probability of all repeated coinventor
gen pr_all_coinv=Ndrep_all_coinv/Ndrpat_inv

*probability of all repeated coinventor (ipc1)
gen pr_all_coinv_ipc1=Ndrep_all_coinv_ipc1/Ndrpat_inv_ipc1

*probability of all repeated coinventor (tsize2)
gen pr_all_coinv_tsize2=Ndrep_all_coinv_tsize2/Ndrpat_inv_tsize2

drop Ndrep_all_coinv Ndrep_all_coinv_ipc1 Ndrep_all_coinv_tsize2

************************************
*Part 1 dataset - Probabilities
***********************************
preserve

rename id_inv categ1

keep patent categ1 tsize2 ipc1 pr_alo_coinv* pr_all_coinv* drep_alo_coinv drep_all_coinv dinv_next_pat

label var pr_alo_coinv "Probability of repeating at least one coinventor"
label var pr_alo_coinv_ipc1 "Probability of repeating at least one coinventor IPC1"
label var pr_alo_coinv_tsize2 "Probability of repeating at least one coinventor Team Size"

label var pr_all_coinv  "Probability of repeating all coinventors"
label var pr_all_coinv_ipc1  "Probability of repeating all coinventors IPC1"
label var pr_all_coinv_tsize2  "Probability of repeating all coinventors Team Size"

label var drep_alo_coinv "Inventor repeats at least one coinventor in next patent"
label var drep_all_coinv "Inventor repeats all coinventors in next patent"
label var dinv_next_pat "Inventor has next patent"

duplicates drop patent categ1, force

save "$datasets/survival_agg_measures.dta", replace

restore

drop Ndrpat_inv_ipc1 Ndrpat_inv_tsize2 pr_alo_coinv_ipc1 pr_alo_coinv_tsize2 pr_all_coinv_ipc1 pr_all_coinv_tsize2

