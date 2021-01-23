
/////1. Import Assignee Information. Each patent has several assignees according to this data.


use "$rawdata/USPTO/patent_assignee.dta", clear

duplicates tag patent_id, generate(dup)

compress

save "$datasets/uspto_patent_assignee_", replace
