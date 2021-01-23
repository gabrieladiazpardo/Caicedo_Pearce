********************************
*
*		Dictionary
*
********************************

use "$output/main_CP.dta",clear

preserve
    describe, replace
    list
    export excel using "${directory}/description_main_CP.xlsx", replace first(var)
restore
