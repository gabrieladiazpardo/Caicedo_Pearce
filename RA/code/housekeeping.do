***********************************************************************
*
*						Housekeeping
*					Caicedo-Pearce Project
*
***********************************************************************

	cls
	clear all
	macro drop _all
	set more off
 	graph set window fontface "Garamond"
	
*Housekeeping

global dir "Caicedo_Pearce" 	

di("`c(username)'")
	
*-Santiago Caicedo
if "`c(username)'"=="Santiago"{

	global main "D:/Dropbox//`c(username)'/Research//${dir}"
	cd "${main}"

	}
	
*-Jeremy Pearce
else if "`c(username)'"=="JeremyPearce"{

	global main "/Users//`c(username)'/Dropbox//${dir}"
	cd "${main}"	

	}	
	
*-Gabriela Díaz (M)
else if "`c(username)'"=="gabrieladiaz"{

	global main "/Users//`c(username)'/Dropbox//${dir}"
	cd "${main}"
		
	}
	

*-Gabriela Díaz (W)
else if "`c(username)'"=="g.diazp"{

	global main "C:\Users\\`c(username)'\Dropbox\\${dir}"
	cd "${main}"

	}
	

*--Globals for folder "data"
global data "$main/data"
global wrkdata "$main/data/wrkdata"
global raw "$main/data/rawdata"
global output "$main/data/output"


*--Globals for folder "RA" 
global tables="$main/RA/output/tabfolder"
global datasets="$main/RA/output/datasets"
global rawdata="$main/RA/rawdata"


*verify
macro dir
pwd