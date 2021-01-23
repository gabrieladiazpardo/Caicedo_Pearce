

***This is old data from VNC
global data4 "/Users/JeremyPearce/Dropbox/Caicedo_Pearce/data"


*******************


use "$data4/categ1_career",clear

merge m:1 patent using "$data4/life_cit_IPC1.dta"
keep if _m==3
drop _m
duplicates drop categ1 patent, force
merge m:1 patent using "$data4/basicbib14_format_ipc.dta", keepusing(assignee gyear appyear ipc4 pdpass nclass)


keep if _m==3
drop _m

*rename ipc4 IPC
merge 1:1 patent categ1 using "$data4/all_data_exceptskill", keepusing(IPC)
drop _m


gen ipc3=substr(IPC,1,3)
gen ipc2=substr(IPC,1,2)
keep if appyear<=2000
merge m:1 ipc3 using "/mnt/fs0/share/akcigitlab/scipub/patents/ipc3_keep_only"
replace ipc3="" if _m~=3
drop _m

bys nclass: egen mode_ipc=mode(ipc3)
replace ipc3=mode_ipc if ipc2==""


***now we have 
