*********************************************************
*														*
*														*
*														*
*********************************************************


use "$datasets/kogan_patents.dta", clear

*fix diplicates in kogan data
duplicates tag patent, gen(dupl)
gen yes_xi=1 if xi!=. & dupl==1
replace yes_xi=0 if dupl==0
drop if yes_xi==.

drop yes_xi dupl gday gmonth gdate permno appmonth appday

*optional
drop class subclass

*rename vars (kogan)
findname, local(vars)
local no = "patent xi"
local lista: list vars - no
macro dir
foreach var of local lista{
rename `var' `var'_kog
}

tempfile kogan
save "`kogan'", replace

*open PV dataset
use "$datasets/Patentsview_lev_dataset.dta", clear

drop asg_self_cite ipc3_self_cite cit_same_asg cit_ident_asg b_cit_asg_sc b_cit_ipc3_sc drep_alo_coinv pr_alo_coinv Nrep_coinv frac_rep_coinv mpat_frac_rep_coinv mrpat_frac_rep_coinv drep_all_coinv pr_all_coinv Ncoinv Nd_coinv

drop mainclass_uspc section_cpc survive subsection_cpc category_nber subcategory_nber non_selected_ipc is90s patnumpp1 ttb1 ttb2 i_ttb m_ttb 

*Merge Kogan to PV - Pat Level
merge 1:1 patent using "`kogan'", gen(in_both)

*log cit var
gen log_fcit3=log(1+f_cit3)
gen log_xi=log(xi)

*create ipc1
gen ipc1=substr(ipc3,1,1)
egen ipc1_num =group(ipc1)
egen ipc3_num =group(ipc3)


drop if appyear<1975
drop if appyear>=2010

reghdfe log_xi log_fcit3 if appyear==1975 & gr1090==1, abs(i.ipc3_num)
return list

label var  log_fcit3 "$\beta$"


*Regression Tables (Excel)
foreach k of numlist 1975/2009{

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==1, noabs

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_90.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Bottom 90% , IPC3 FE, $\times$)  sdec(2) ctitle("Appyear `k'")

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==1, abs(i.ipc3_num)

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_90.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Bottom 90%, IPC3 FE, $\checkmark$ ) sdec(2) ctitle("Appyear `k'")

}

foreach k of numlist 1975/2009{

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==2, noabs

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_10.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Top 10% , IPC3 FE, $\times$)  sdec(2) ctitle("Appyear `k'")


reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==2, abs(i.ipc3_num)

outreg2 using "${tabfolder}/Fcit_Market_Value_gr_10.xls", excel append ///
onecol label addtext (Appyear,`k', Group, Top 10% , IPC3 FE, $\checkmark$ ) sdec(2) ctitle("Appyear `k'")

}


*Regressions for Coefplot
foreach z of numlist 1/2{
foreach k of numlist 1975/2009{

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==`z', noabs

estimate store m`z'_`k'

reghdfe log_xi log_fcit3 if appyear==`k' & gr1090==`z', abs(i.ipc3_num)

estimate store a`z'_`k'

}
}

*Without Controls
coefplot (m1_1976) (m2_1976, msymbol(Dh)), bylabel(1976) ///
      || m1_1977 m2_1977, bylabel(1977)  ///
	  || m1_1978 m2_1978, bylabel(1978)  ///
	  || m1_1979 m2_1979, bylabel(1979)  ///
	  || m1_1980 m2_1980, bylabel(1980)  ///
	  || m1_1981 m2_1981, bylabel(1981)  ///
	  || m1_1982 m2_1982, bylabel(1982)  ///
	  || m1_1983 m2_1983, bylabel(1983)  ///
	  || m1_1984 m2_1984, bylabel(1984)  ///
	  || m1_1985 m2_1985, bylabel(1985)  ///	
	  || m1_1986 m2_1986, bylabel(1986)  ///
	  || m1_1987 m2_1987, bylabel(1987)  ///
	  || m1_1988 m2_1988, bylabel(1988)  ///
      || m1_1989 m2_1989, bylabel(1989)  ///
      || m1_1990 m2_1990, bylabel(1990)  ///
      || m1_1991 m2_1991, bylabel(1991)  ///
      || m1_1992 m2_1992, bylabel(1992)  ///
      || m1_1993 m2_1993, bylabel(1993)  ///
	  || m1_1994 m2_1994, bylabel(1994)  ///
	  || m1_1995 m2_1995, bylabel(1995)  ///	
	  || m1_1996 m2_1996, bylabel(1996)  ///
	  || m1_1997 m2_1997, bylabel(1997)  ///
	  || m1_1998 m2_1998, bylabel(1998)  ///
      || m1_1999 m2_1999, bylabel(1999)  ///
      || m1_2000 m2_2000, bylabel(2000)  ///
      || m1_2001 m2_2001, bylabel(2001)  ///
      || m1_2002 m2_2002, bylabel(2002)  ///
      || m1_2003 m2_2003, bylabel(2003)  ///
	  || m1_2004 m2_2004, bylabel(2004)  ///
	  || m1_2005 m2_2005, bylabel(2005)  ///	
	  || m1_2006 m2_2006, bylabel(2006)  ///
	  || m1_2007 m2_2007, bylabel(2007)  ///
	  || m1_2008 m2_2008, bylabel(2008)  ///	  
	  || , bycoefs byopts(xrescale)   ///
          plotlabels("Bottom 90%" "Top 10%") drop(_cons) ///
		  vertical 															 ///
		  label 	                                              ///														 
		  plotregion(lcolor(white) fcolor(white))  							 ///
		  graphregion(lcolor(white) fcolor(white))  						 ///	  
		  yline(0, lpattern(dash) lwidth(*0.5))   							 ///
		  xtitle("Appyear", size(medsmall)) ///
		  levels(95) ///
		  msize(small) ///
		  xlabel(, labsize(vsmall) angle(vertical) nogextend labc(black))

if $save_fig ==1 {
graph export "$figfolder/coefplot_pat_val_nocontrols_gr_1090.pdf", replace as(pdf)
}
	
	
	
*With Controls	
coefplot (a1_1976) (a2_1976, msymbol(Dh)), bylabel(1976) ///
      || a1_1977 a2_1977, bylabel(1977)  ///
	  || a1_1978 a2_1978, bylabel(1978)  ///
	  || a1_1979 a2_1979, bylabel(1979)  ///
	  || a1_1980 a2_1980, bylabel(1980)  ///
	  || a1_1981 a2_1981, bylabel(1981)  ///
	  || a1_1982 a2_1982, bylabel(1982)  ///
	  || a1_1983 a2_1983, bylabel(1983)  ///
	  || a1_1984 a2_1984, bylabel(1984)  ///
	  || a1_1985 a2_1985, bylabel(1985)  ///	
	  || a1_1986 a2_1986, bylabel(1986)  ///
	  || a1_1987 a2_1987, bylabel(1987)  ///
	  || a1_1988 a2_1988, bylabel(1988)  ///
      || a1_1989 a2_1989, bylabel(1989)  ///
      || a1_1990 a2_1990, bylabel(1990)  ///
      || a1_1991 a2_1991, bylabel(1991)  ///
      || a1_1992 a2_1992, bylabel(1992)  ///
      || a1_1993 a2_1993, bylabel(1993)  ///
	  || a1_1994 a2_1994, bylabel(1994)  ///
	  || a1_1995 a2_1995, bylabel(1995)  ///	
	  || a1_1996 a2_1996, bylabel(1996)  ///
	  || a1_1997 a2_1997, bylabel(1997)  ///
	  || a1_1998 a2_1998, bylabel(1998)  ///
      || a1_1999 a2_1999, bylabel(1999)  ///
      || a1_2000 a2_2000, bylabel(2000)  ///
      || a1_2001 a2_2001, bylabel(2001)  ///
      || a1_2002 a2_2002, bylabel(2002)  ///
      || a1_2003 a2_2003, bylabel(2003)  ///
	  || a1_2004 a2_2004, bylabel(2004)  ///
	  || a1_2005 a2_2005, bylabel(2005)  ///	
	  || a1_2006 a2_2006, bylabel(2006)  ///
	  || a1_2007 a2_2007, bylabel(2007)  ///
	  || a1_2008 a2_2008, bylabel(2008)  ///	  
	  || , bycoefs byopts(xrescale)   ///
          plotlabels("Bottom 90%" "Top 10%") drop(_cons) ///
		  vertical 															 ///
		  label 	                                              ///														 
		  plotregion(lcolor(white) fcolor(white))  							 ///
		  graphregion(lcolor(white) fcolor(white))  						 ///	  
		  yline(0, lpattern(dash) lwidth(*0.5))   							 ///
		  xtitle("Appyear", size(medsmall)) ///
		  msymbol(D) ///
		  levels(95) ///
		  msize(small) ///
		  xlabel(, labsize(vsmall) angle(vertical) nogextend labc(black))

if $save_fig ==1 {
graph export "$figfolder/coefplot_pat_val_with_controls_gr_1090.pdf", replace as(pdf)
}
	
		  


