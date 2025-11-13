********************************************************************************
* DATASET CLEANING AND RE-STRUCTURING *
********************************************************************************
/*		
Project: SPIA_BIHS_2024
Author : Saumya Singla & Tanjim Ul Islam
Date Created : 7th May 2024
Latest Edit : Saumya Singla & Tanjim Ul Islam
Last edit by: October 17th 2024

Description: This inputs xlsx/csv files, cleans, merges, adds the resurveys 
and produces the final .dta modules

INPUT: SPIA_BIHS_MAIN_2024 and SPIA_BIHS_Resurvey_2024 csv, excel and modules 
OUTPUT: Cleaned modules 

*/


********************************************************************************
* Installations * 
********************************************************************************
	
	** Install odksplit
	cap which 	odksplit
	if _rc 		net install odksplit, all replace ///
				from("https://raw.githubusercontent.com/ARCED-Foundation/odksplit/master")
	adoupdate odksplit, update	
	
	
	**# Setting globals
	
	clear all
	set maxvar 32000
	set more off, permanently
	capture log close // capture avoids code interruptions 	
	
	
	**# Preparing the module a1 identifier dataset
	
	use "${bihs2015}${slash}001_r2_mod_a_male", clear
	
	keep if flag_a==1
	
	drop if hh_type==1
	
	tostring a01, replace
	
	split a01, p(.) g(a01new)
	
	ren (a01new1 a01 a01new2) (a01_12 a01combined_15 a01split_serial_15)
	
	destring a01split_serial_15, replace
	
	g a01split_hh_15 = (a01split_serial_15 != .)
	
	
	la var a01_12 "Household ID from BIHS 2012"
	la var a01combined_15 "Household ID for BIHS 2015"
	la var a01split_serial_15 "Split serial for BIHS 2015"
	la var a01split_hh_15 "Did the household split in 2015?"
	la def a01split_hh_15 1 "Yes" 0 "No"
	
	la val a01split_hh_15 a01split_hh_15
	
	keep a01combined_15 a01_12 a01split_serial_15 a01split_hh_15
	
	tempfile bihs_15
	save `bihs_15', replace
	
	
	use "${bihs2018}${slash}009_bihs_r3_male_mod_a", clear
	keep if consent_a==1
	
	split hhid2, p(.) g(a01r2)
	
	ren (a01 a01r21 a01r22 a01r23) (a01combined_18 a01_15 a01split_serial_1 a01split_serial_18)
	
	
	/*Initially merging with the split HHs with one split i.e. decimal point*/
	replace a01_15 = a01_15 + "." + a01split_serial_1 if a01split_serial_1 != ""

	ren a01_15 a01combined_15

	merge m:1 a01combined_15 using `bihs_15'
	
	preserve
	
	keep if _merge==1
	
	drop a01split_serial_18 a01split_serial_1
	
	/*Now, considering the HHs that may have split in 2018 itself. i.e.: a HH 
    is 500 and it splits into 500.1 and 500.2. Those won't merge with the 2015
	hhid. Hence, only keeping the integer parts of the HH IDs to merge those
	HHs properly*/
	split a01combined_15, p(.) g(a01combined_15_)
	
	drop a01combined_15 
	
	ren (a01combined_15_1 a01combined_15_2 _merge) (a01combined_15 a01split_serial_18 old_merge)

	tempfile master_a
	save `master_a', replace 
	
	restore 
	
	preserve
	
	keep if _merge==2
	
	drop a01combined_18 a01split_serial_1 a01split_serial_18 _merge hhid2
	
	merge 1:m a01combined_15 using `master_a'
	
	tempfile main
	save `main', replace
		
	
	/*
	
	
   Result                      Number of obs
    -----------------------------------------
    Not matched                           351
        from master                       254  (_merge==1)
        from using                         97  (_merge==2)

    Matched                               553  (_merge==3)
    -----------------------------------------

	
	The 254 HHs are the attrited HHs from 2015 to 2018. The 97 that did 
	not match from the using data [2018 data] are HHs that were not surveyed
	successfully in 2015 but was surveyed successfully in 2018. Considering 2015
	as the base, I am not considering these 97 HHs for attrition calculations.
	
	Furthermore, in the deidentified dataset, I have created a separate variable
	that tags these HHs to easily identify them
	
	*/
	restore 
	
	keep if _merge==3
	
	drop _merge a01split_serial_1
	
	append using `main'
	
	
	g a01absent_15 = (a01_12 == "")
	
	la var a01absent_15 "Household is absent in BIHS 2015 but present in 2018"
	
	la def a01absent_15 1 "Yes" 0 "No"
	
	la val a01absent_15 a01absent_15
	
	replace a01_12 = a01combined_15 if a01_12 ==""
	
	recode a01split_hh_15 . = -98 
	
	la def a01split_hh_15 1 "Yes" 0 "No" -98 "Household was absent in BIHS 15 but present in 18", modify
	
	g a01attrition_18 = (_merge==1)
	
	la var a01attrition_18 "HH attrition in 2018"
	
	la def a01attrition_18 1 "Yes" 0 "No"
	
	la val a01attrition_18 a01attrition_18
	
	drop _merge
	
	tostring a01combined_18, replace 
	
	replace a01combined_18 = a01combined_15 if a01combined_18 =="."
	
	
	destring a01split_serial_18, replace
	
	g a01split_hh_18 = (a01split_serial_18 != .)
	
	la var a01combined_15 "Household ID for BIHS 2015"
	la var a01combined_18 "Household ID for BIHS 2018"
	la var a01split_serial_18 "Split serial for BIHS 2018"
	la var a01split_hh_18 "Did the household split in 2018?"
	
	la def a01split_hh_18 1 "Yes" 0 "No"
	
	la val a01split_hh_18 a01split_hh_18
	
	
	keep a01* hhid2
	
	ren hhid2 hhid2018
	
	la var hhid2018 "Household ID for BIHS 2018 (string)"
	
	tempfile merge_15_18
	save `merge_15_18', replace
	
	
	use "${bihs2012}${slash}001_mod_a_male", clear
	
	drop if Sample_type==1
	
	keep a01 Sample_type 
	
	ren a01 a01_12
	
	tostring a01_12, replace
	
	merge 1:m a01_12 using `merge_15_18'
	
	g a01attrition_15 = (_merge==1)
	
	la var a01attrition_15 "HH attrition in 2015"
	
	la def a01attrition_15 1 "Yes" 0 "No"
	
	la val a01attrition_15 a01attrition_15
	
	drop _merge
	
	la var a01_12 "Household ID for BIHS 2012"
	
	replace a01combined_18 = a01_12 if a01attrition_15==1
	replace a01combined_15 = a01_12 if a01attrition_15==1
	
	recode a01attrition_18 . = -98
	
	la def a01attrition_18 1 "Yes" 0 "No" -98 "Attrition in 2015", modify
	
	la val a01attrition_18 a01attrition_18
	
	tempfile merge_12_15_18
	save `merge_12_15_18', replace
	
	/* The deidentified dataset is created by dropping the union, mouza, village
	name, gps, phone number from the actual raw data. All other variables are kept */
	
	import excel "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx" , firstrow sheet(data) clear
	
	keep if a1recruitment == 1
	
	recode a1hhid 823.2 = 823.1 if KEY == "uuid:89bef9aa-8fb1-4047-a7cf-f53b1469c453" //fixing hhid due to enumerator mistake
	
	tostring a1hhid a1split_hh_serial a1total_split a1split_hh_serial, replace
	gen a1hhid_combined = a1hhid
	
	replace a1hhid_combined = a1hhid + "." + a1split_hh_serial if a1split_hh_serial != "."
	order a1hhid_combined, after(a1hhid)
	
	replace a1hhid_combined = "5036.1.2" if a1hhid == "5036.1" & a1total_split == "3" //enumerator mistake
	replace a1hhid_combined = "5036.1.3" if a1hhid == "5036.1" & a1split_hh_serial == "2" //enumerator mistake
	replace a1hhid_combined = "1194.2.1" if a1hhid_combined == "1194.2" //enumerator mistake
	
	duplicates drop a1hhid_combined, force // Same interview got submitted two times for some reason, dropping the duplicates
	
	tempfile main_pre
	save `main_pre', replace
	
	preserve
	
	import delimited using "${raw_data}${slash}csv${slash}land_resurvey_roster", clear
		
	keep a1hhid_combined
	
	tempfile resurvey
	save `resurvey', replace
	
	restore
	
	append using `resurvey'
	
	duplicates tag a1hhid_combined, gen(dup)
	
	drop if dup == 1
	
	ren a1hhid a01combined_18

	tostring a01combined_18, replace
	
	tempfile main_data
	save `main_data', replace

	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(data) clear
	
	duplicates drop a1hhid_combined, force // Same interview got submitted two times for some reason, dropping the duplicates
	
	drop if a1recruitment != 1
	
	ren a1hhid a01combined_18
	tostring a01combined_18, replace
	
	merge 1:1 a1hhid_combined using `main_pre', nogen keep(3) keepusing(a1hhloc a1split_hh a1total_split a1split_hh_serial a1religion a1language a1language_oth a1ethnicity a1ethnicity_oth) //Merging these variables from the main survey because these questions were not asked in the resurvey
	
	tempfile resurvey_data
	save `resurvey_data', replace
	
	append using `main_data', force
	
	merge m:1 a01combined_18 using `merge_12_15_18' , nogen keep(3)
	
	tempfile raw24
	save `raw24', replace 
	
	u "${bihs2018}${slash}158_BIHS sampling weights_r3", clear
	ren a01 a01combined_18
	drop hh_type
	
	tostring a01combined_18, replace
	ren (hhweight popweight) (hhweight_18 popweight_18)
	
	la var hhweight_18 "BIHS household sampling weight 2018"
	la var popweight_18 "BIHS population weight 2018"
	
	merge 1:m a01combined_18 using `raw24', nogen keep(3)
	
	tempfile raw24_18
	save `raw24_18', replace 
	
	u "${bihs2015}${slash}BIHS FTF 2015 survey sampling weights", clear
	
	ren a01 a01combined_15
	drop hh_type dvcode ftf_hhwgt ftf_popwgt round
	
	tostring a01combined_15, replace
	ren (hhweight popweight) (hhweight_15 popweight_15)
	
	la var hhweight_15 "BIHS household sampling weight 2015"
	la var popweight_15 "BIHS population weight 2015"
	
	
	merge 1:m a01combined_15 using `raw24_18', nogen keep(3)
	
	tempfile raw24_18_15
	save `raw24_18_15', replace
	
	u "${bihs2012}${slash}BIHS_FTF baseline sampling weights", clear
	
	ren a01 a01_12
	drop sample_type dvcode ftf_hhwgt ftf_popwgt round
	
	tostring a01_12, replace
	ren (hhweight popweight) (hhweight_12 popweight_12)
	
	la var hhweight_12 "BIHS household sampling weight 2015"
	la var popweight_12 "BIHS population weight 2015"
	
	merge 1:m a01_12 using `raw24_18_15', nogen keep(3)
		 
	order a01combined_18 hhid2018 a01attrition_18 a01split_hh_18 a01split_serial_18 ///
	a01combined_15 a01attrition_15 a01absent_15 a01split_hh_15 a01split_serial_15 a01_12 ///
	Sample_type hhweight* popweight*, after(a1split_hh_serial)
	
	duplicates drop a1hhid_combined, force // Same interview got submitted three times for some reason, dropping the duplicates

	preserve
	
	keep a1hhid_combined SubmissionDate starttime endtime
	
	tempfile time
	save `time', replace
	
	restore 
	
	keep a1hhloc a1religion a1language ///
	a1language_oth a1ethnicity a1ethnicity_oth a1division divisionname ///
	a1district districtname a1upazila upazilaname a1union a1mouza a1village ///
	a01* a1split_hh a1total_split a1split_hh_serial ///
	a1hhid_combined hhweight* monitorid superid enumid
	
	

	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_a1.dta", replace
	
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${temp_data}${slash}SPIA_BIHS_2024_module_a1.dta") label(English) dateformat(MDY) clear save("${final_data}${slash}SPIA_BIHS_2024_module_a1.dta")
	
	merge 1:1 a1hhid_combined using `time', nogen
	
	
	la var monitorid "Monitor ID"
	la var superid "Supervisor ID"
	la var enumid	"Enumerator ID"
	la var a1division "Division code"
	la var a1district "District code"
	la var a1upazila  "Upazila code"
	la var a1union "Union code"
	la var a1mouza "Mouza code"
	la var a1village "Village code" 
	la var a01combined_18 "Household ID in BIHS 2018"
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", replace
	

	g obs_div = 1
	
	collapse(count) obs_div, by(divisionname)
	
	tempfile div_obs
	save `div_obs', replace
	
	import excel "${raw_data}${slash}BIHS_Round_2_3_SPIA-BIHS_round_weights.xlsx", firstrow clear 
	
	ren Division divisionname
	
	drop if divisionname == ""
	
	merge 1:1 divisionname using `div_obs', nogen keep(3)
	
	destring predicted_hh_24, replace
	
	g hhweight_24 = round(predicted_hh_24/obs_div, .01)
	
	keep divisionname hhweight_24
	
	merge 1:m divisionname using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen
	
	la var hhweight_24 "BIHS household sampling weight 2024"
	la var a1split_hh "HH split since BIHS 2018"
	order hhweight_24, after(a1ethnicity_oth)
	order divisionname, after(a1division)
	order a1hhid_combined, before(a1division)
	order a01split_serial_15, after(a01split_hh_15)
	order a01split_serial_18, after(a01split_hh_18)
	order a01_12, after(a01combined_15)
	order a01attrition_15, after(a01split_serial_15)
	order a01attrition_18, after(a01split_serial_18)
	order monitorid superid enumid, after(a1hhid_combined)
	
	la var a1hhloc "HH located in the same upazila as the previous round"
	la var hhweight_12 "BIHS household sampling weight 2012"
	la def a1religion 1	"Muslim" ///
					  2 "Hindu" ///
					  3 "Christian" ///
					  4	"Buddhist" ///
					  -96 "Other (specify)"
					  
	la val a1religion a1religion


	drop a01attrition* a1language_oth
	
	destring a1total_split a1split_hh_serial, replace
	
	sort divisionname districtname upazilaname
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", replace
	
	**# 3.2.2 Finding the true panel HHs
	merge m:1 a01combined_18 using `merge_12_15_18'
	
	drop if a01attrition_15 == 1 | a01attrition_18 == 1 
	
	
	g a01attrition_24 = (_merge==2)

	collapse(min) a01attrition_24, by(a01_12)
	
	g round = 2024
	
	collapse(mean) a01attrition_24, by(round)
	
	g attrition = round(a01attrition_24*100, .01)
	
	tempfile attrition_24
	save `attrition_24', replace
	
	u `merge_12_15_18', clear
	
	collapse(min) a01attrition_15, by(a01_12)
	
	g round = 2015
	
	collapse(mean) a01attrition_15, by(round)
	
	g attrition = round(a01attrition_15*100, .01)
	
	tempfile attrition_15
	save `attrition_15', replace
	
	u `merge_12_15_18', clear
	
	drop if a01attrition_15 == 1
	
	collapse(min) a01attrition_18, by(a01_12)
	
	g round = 2018
	
	collapse(mean) a01attrition_18, by(round)
	
	g attrition = round(a01attrition_18*100, .01)
	
	tempfile attrition_18
	save `attrition_18', replace
	
	u `attrition_15', clear
	append using `attrition_18'
	append using `attrition_24'

	la var attrition "Attrition of original panel HH (%)"
	
	
	********************************************************************************
	**# MODULE A2-4
	********************************************************************************
	* Input main module A file (de-identified file) 
	 {
	import excel "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx" , firstrow sheet(data) clear
	keep if a1recruitment == 1 

	recode a1hhid 823.2 = 823.1 if KEY == "uuid:89bef9aa-8fb1-4047-a7cf-f53b1469c453" //fixing hhid due to enumerator mistake

	// generate a1hhid_combined - that accounts for the split HHs
	tostring a1hhid a1split_hh_serial a1total_split a1split_hh_serial, replace
	gen a1hhid_combined = a1hhid
	replace a1hhid_combined = a1hhid + "." + a1split_hh_serial if a1split_hh_serial != "." //logic used from 
	order a1hhid_combined, after(a1hhid)

	replace a1hhid_combined = "5036.1.2" if a1hhid == "5036.1" & a1total_split == "3" //enumerator mistake
	replace a1hhid_combined = "5036.1.3" if a1hhid == "5036.1" & a1split_hh_serial == "2" //enumerator mistake
	replace a1hhid_combined = "1194.2.1" if a1hhid_combined == "1194.2" //enumerator mistake

	// drop all surveys where there was no consent 
	drop if a1recruitment != 1 

	//drop some duplicate surveys  - 4 duplicate surveys (retaining the survey entered at a later day)
	duplicates tag a1hhid_combined , gen(dup_hhid)

	bysort a1hhid_combined: gen n = _n 
	drop if dup_hhid > 0 & n == 1 
	drop dup_hhid n 

	// Duplicates still remain, dropping those by reiterating the previous process
	duplicates tag a1hhid_combined , gen(dup_hhid)
	bysort a1hhid_combined: gen n = _n 
	drop if dup_hhid > 0 & n == 1 
	drop dup_hhid n 

	// Duplicates still remain, dropping those by reiterating the previous process
	duplicates tag a1hhid_combined , gen(dup_hhid)
	bysort a1hhid_combined: gen n = _n 
	drop if dup_hhid > 0 & n == 1 
	drop dup_hhid n

	 
	save "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified", replace 

	preserve 
	import excel "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx" , firstrow sheet(a2hhroster) clear // Latest data with the missing observations that Tanjim downloaded on the 14th Oct

	drop if a2mem_id == "3415.2" & a2prim_daily_activity == . 
	drop if a2mem_id == "3277.3" & a2n_migration == . 
	rename KEY KEY_a2
	rename PARENT_KEY KEY
	tempfile a2
	save "`a2'", replace
	restore 

	//merge with the roster file 
	merge 1:m KEY using "`a2'" , nogenerate keep(1 3)

	// generate identifier (this includes both split and non-split households)
	tostring a2index, replace 
	egen a2mem_id_2024 = concat(a1hhid_combined a2index) , punct(.)
	tempfile a2hhroster_new
	save  "`a2hhroster_new'" , replace

	cap odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
	data("`a2hhroster_new'") label(English) dateformat(MDY) ///
	clear save("${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear)
	save "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta" , replace 

	// Clean Variable 
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear

	// keep module A variables - 375 variables,32603 obs 
	 keep a1* a2* a3* a4* SETOFa2sec_daily_repeat SETOFa2sec_monthly_repeat SETOFnum_migration num_migration_count ///
	 KEY SubmissionDate SETOFa2hhroster starttime endtime monitorid monitorname ///
	 superid supername enumid enumname divisionname upazilaname duration ///
	 hh_head_age SETOFa5hh_own_repeat SETOFa5vehicle_own_repeat SETOFa5comm_own_repeat ///
	 SETOFa5animal_own_repeat SETOFa5agri_own_repeat b1repeat_count b1fishing_count

	// Module A1 Cleaning 
	* Submission Date * 
	gen submissiondate = dofc(SubmissionDate)
	format %td submissiondate

	** Module A2 ** 
	* Age 
	replace a2mem_age = 100 if a2mem_age > 100 & a2mem_age != . 
	tab a2mem_status if a2mem_age == .  

	* HH_head_age
	replace hh_head_age = 95 if hh_head_age == 113 //replace 

	* Days worked 
	replace a2prim_daily_n_days = 219 if a2prim_daily_n_days == 2190

	* Module A3 - Secondary activity 
	split a2sec_daily_activity, p(" ")
	drop a2sec_daily_activity
	rename a2sec_daily_activity1 a2sec_daily_activity 
	destring a2sec_daily_activity a2sec_daily_activity2 , replace 

	rename SETOFnum_migration setofnum_migration_main
	gen setofnum_migration_empty = _n 
	tostring setofnum_migration_empty , replace
	replace setofnum_migration_main = setofnum_migration_empty if setofnum_migration_main == "" 

	** Module A4 ** 
	split a4earning_source, p(" ")
	drop a4earning_source a4earning_source3
	order a4earning_source1 a4earning_source2 , after(a4employment_district) 
	destring a4earning_source1 a4earning_source2 , replace

	drop setofnum_migration_empty submissiondate 
	save "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_nomig.dta", replace 
	********************************************************************************     
	* RESURVEY - CLEANING + MERGING * 
	********************************************************************************
	*** Module A ***
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(data) clear
	drop if SETOFmodule_d1 == "uuid:040b8f68-0060-494a-9f90-35a992f746c4/module_d-module_d1" 

	// drop all surveys where there was no consent 
	drop if a1recruitment != 1 

	//drop some duplicate surveys  - 4 duplicate surveys (retaining the survey entered at a later day)
	duplicates tag a1hhid_combined , gen(dup_hhid)
	duplicates drop a1hhid_combined, force // Same interview got submitted two times for some reason, dropping the duplicates


	save "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , replace  

	preserve 
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx"  , firstrow sheet(a2hhroster) clear
	drop if a2mem_id == "3415.2" & a2prim_daily_activity == . 
	drop if a2mem_id == "3277.3" & a2n_migration == . 
	duplicates drop PARENT_KEY a2mem_id , force // retaining the first 
	rename KEY KEY_a2
	rename PARENT_KEY KEY
	tempfile a2_resurvey
	save `a2_resurvey', replace
	restore 
	merge 1:m KEY using "`a2_resurvey'" , nogenerate keep(3)

	* keep module A variables - 375 variables,32603 obs 
	keep a1* a2* a3* a4* SETOFa2hhroster SETOFa2sec_daily_repeat SETOFa2sec_monthly_repeat ///
	SETOFnum_migration num_migration_count KEY SubmissionDate starttime endtime monitorid monitorname ///
	superid supername enumid enumname divisionname upazilaname duration b1repeat_count b1fishing_count
	 
	drop a2n_mem_2018 // This is not the proper number in the resurvey. It only accounts for the number of members in the resurvey roster.

	rename a2mem_id a2mem_id_2024

	** Module A1 Cleaning **
	* Submission Date * 
	gen submissiondate = dofc(SubmissionDate)
	format %td submissiondate

	** Module A2 ** 
	* Days worked 
	replace a2prim_daily_n_days = 219 if a2prim_daily_n_days == 2190

	* Secondary activity 
	split a2sec_daily_activity, p(" ")
	drop a2sec_daily_activity
	rename a2sec_daily_activity1 a2sec_daily_activity 
	destring a2sec_daily_activity a2sec_daily_activity2 , replace 

	** Module A4 ** 
	split a4earning_source, p(" ")
	drop a4earning_source 
	order a4earning_source1 a4earning_source2 , after(a4employment_district) 
	destring a4earning_source1 a4earning_source2 , replace 

	rename SETOFnum_migration setofnum_migration_resurvey
	gen setofnum_migration_empty = _n 
	tostring setofnum_migration_empty , replace
	replace setofnum_migration_resurvey = setofnum_migration_empty if setofnum_migration_resurvey == "" 

	* Drop variables with all missings 
	missings dropvars , force 
	destring a1hhid, replace
	// save dataset 
	save "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_resurvey_nomig.dta", replace 

	*************** Merge the two datasets ***********************************
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_nomig.dta", clear 
	destring a1hhid a2index, replace 
	cap drop _merge
	merge 1:1 a2mem_id_2024 using "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_resurvey_nomig.dta" , update replace // only one observation doesn't match because HH was dropped due to no primary activity. 

	// make resurvey variable 
	gen resurvey = 0 
	replace resurvey = 1 if _merge == 5 
	drop _merge 

	**** drop all households that refused to be resurveyed *** 
	preserve 
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(data) clear
	drop if SETOFmodule_d1 == "uuid:040b8f68-0060-494a-9f90-35a992f746c4/module_d-module_d1" 
	// drop all surveys where there was no consent 
	keep if a1recruitment != 1 
	gen no_resur_consent = 1 
	keep no_resur_consent a1hhid_combined 
	duplicates drop 
	tempfile no_consent
	save "`no_consent'"
	restore
	merge m:1 a1hhid_combined using "`no_consent'" , nogenerate
	drop if no_resur_consent == 1 

	***** cleaning member ids/household head age/agri head age ******
	split a2mem_id_2024, p(.)

	drop a2mem_id_20241
	destring a2mem_id_20242 a2mem_id_20243 a2mem_id_20244, replace

	replace a2mem_id_20244 = a2mem_id_20243 if mi(a2mem_id_20244)
	replace a2mem_id_20244 = a2mem_id_20242 if mi(a2mem_id_20244)

	drop a2mem_id_20242 a2mem_id_20243 submissiondate setofnum_migration_empty 

	ren a2mem_id_20244 a2mem_id_new

	destring a2index, replace
	gen a2hh_head_id = a2mem_id_new if a2index == a2hh_head // Only 5 HHs remain without a HH head because -98 (NA) was selected, enumerator mistake. NA was provided to account for non agri HHs in the agri hh head question. In hindsight, the options should have been separated and not include NA in the hh head question

	gen a2agri_decision_id = a2mem_id_new if a2index == a2agri_decision & (b1repeat_count > 0 | b1fishing_count > 0) // It seems the enumerators selected options for a lot of non agri HHs where they should have selected NA. I am coding it conditionally so that the id is only created for agri control hhs and fishing hhs.

	order a2hh_head_id, after(a2hh_head) 
	order a2agri_decision_id, after (a2agri_decision) 

	label var a2hh_head_id "member id of the HH head"
	label var a2agri_decision_id "id of the member who takes agricultral decisions"

	drop a2hh_head a2agri_decision b1repeat_count b1fishing_count a1division divisionname ///
	a1district a1upazila upazilaname a1union a1mouza ///
	a1village a1hhid a1hhloc a1recruitment a1split_hh a1total_split a1split_hh_serial ///
	a2n_mem_2018 SubmissionDate starttime endtime duration monitorid monitorname ///
	superid supername enumid enumname

	* ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	save "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", replace
	******************************************************************************** 
	*** MERGING WITH MIGRATION ****
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear
	drop if resurvey == 1 // remove everyone who would need to be overwritten.  

	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-a2current_mem-num_migration.csv", varnames(1) clear 
	rename setofnum_migration setofnum_migration_main
	tempfile migration
	save "`migration'"
	restore
	merge 1:m setofnum_migration_main using "`migration'" , nogenerate keep(1 3)

	split a2migrationcountry, p("|")
	drop a2migrationcountry a2migrationcountry2 
	rename a2migrationcountry1 a2migrationcountry

	* other migration_countries
	replace a2migration_country_oth = "Dubai" if inlist(a2migration_country_oth, "Dubai cilo", "Dobay","Dobai","Dubai, abudain", ///
	"Dubay" , "Dubhai" , "Duby", "Duvai")
	replace a2migration_country_oth = "Kuwait" if a2migration_country_oth == "Koyet"
	replace a2migration_country_oth = "U.K." if a2migration_country_oth == "London"
	replace a2migration_country_oth = "Russia" if inlist(a2migration_country_oth, "Moshko" , "Mosque") 
	replace a2migration_country_oth = "Saudi Arabia" if inlist(a2migration_country_oth, "Saudi arab", "Saudi")

	* Did you send a remittance?
	replace a2remittance_pyear = -98 if a2remittance_pyear == . 

	tempfile mig_main 
	save "`mig_main'"

	******** merging resurveys with migration ************
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear
	keep if resurvey == 1 
	preserve
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", firstrow sheet(num_migration) clear
	rename SETOFnum_migration setofnum_migration_resurvey
	tempfile migration
	save "`migration'"
	restore
	merge 1:m setofnum_migration_resurvey using "`migration'" 

	split a2migrationcountry, p("|")
	drop a2migrationcountry a2migrationcountry2 
	rename a2migrationcountry1 a2migrationcountry

	* other migration_countries
	replace a2migration_country_oth = "Dubai" if inlist(a2migration_country_oth, "Dubai cilo", "Dobay","Dobai","Dubai, abudain", ///
	"Dubay" , "Dubhai" , "Duby", "Duvai")
	replace a2migration_country_oth = "Kuwait" if a2migration_country_oth == "Koyet"
	replace a2migration_country_oth = "U.K." if a2migration_country_oth == "London"
	replace a2migration_country_oth = "Russia" if inlist(a2migration_country_oth, "Moshko" , "Mosque") 
	replace a2migration_country_oth = "Saudi Arabia" if inlist(a2migration_country_oth, "Saudi arab", "Saudi")

	* Did you send a remittance?
	replace a2remittance_pyear = -98 if a2remittance_pyear == . 
	drop _merge 

	tempfile mig_resurvey 
	save "`mig_resurvey'"

	*** append the people who are in the main survey *******
	append using "`mig_main'"

	* Define/Modify Labels
	label define a1religion_name 1 "Muslim" 2 "Hindu" 3 "Christian" 4 "Buddhist" -96 "Other" 
	label define a2mem_status_l1 -96 "Other reason for being permanent" 1 ///
	"Both previous and current round" 4 "New Member (divorce or separation)" 6 "Residing elsewhere for studies" , modify
	label define  a3edu_type_l1 5 "University" 6 "Open University" , modify

	#delimit ;
	label define  a4_earning_l1 ///
	1 "Earth work (govt program)" ///
	2	"Earth work (other)" ///
	3	"Sweeper" ///
	4	"Scavenger" ///
	5	"Tea garden worker" ///
	6	"Construction labor" ///
	7	"Factory worker" ///
	8	"Transport worker (bus/truck helper)" ///
	9	"Apprentice" ///
	10	"Farm Laborer" ///
	11	"Rickshaw/van pulling" ///
	12	"Driver of motor vehicle" ///
	13	"Tailor/seamstress" ///
	14	"Blacksmith" ///
	15	"Potter" ///
	16	"Cobbler" ///
	17	"Hair cutter" /// 
	18	"Clothes washer" ///
	19	"Porter" ///
	20	"Goldsmith/silversmith" ///
	21	"Repairman (appliances)" ///
	22	"Mechanic (vehicles)" ///
	23	"Plumber" /// 
	24	"Electrician" ///
	25	"Carpenter" ///
	26	"Mason/Construction Rod Welder" ///
	27	"Milk collector" ///
	28	"Livestock Vet medicine seller" ///
	29	"Livestock Feed supplier" ///
	30	"Commercially feed producer" ///
	31	"Animal Breeder" ///
	32	"Veterinary/paravet doctor" ///
	33	"Other wage labor" ///
	34	"Government/parastatal" ///
	35	"Service (private sector)" ///
	36	"NGO worker" ///
	37	"House maid" ///
	38	"Teacher (GoB-Primary school)" ///
	39	"Teacher (Non GoB Primary school)." ///
	40	"Teacher (GoB High school)" ///
	41	"Teacher (Non-GoB High school)" ///
	42	"Teacher (college, university)" ///
	43	"Doctor" ///
	44	"Rural physician" ///
	45	"Midwife" ///
	46	"Herbal doctor/Kabiraj" ///
	47	"Engineer" ///
	48	"Lawyer/deed writer/Moktar" ///
	49	"Religious leader (Imam/Muazzem/Khadem/Purohit)" ///
	50	"Lodging master" ///
	51	"Private tutor/house tutor" ///
	52	"Small trader (roadside stand or stall)" ///
	53	"Medium trader (shop or small store)" ///
	54	"Large trader (large shop or whole sale)" ///
	55	"Fish Trader" ///
	56	"Contractor" ///
	57	"Food Processing" ///
	58	"Small industry" ///
	59	"Handicrafts" ///
	60	"Other salaried worker (specify)" ///
	61	"Land rent(cash/share)" ///
	62	"House Rent" ///
	63	"Other rent(shop/productive asset)" ///
	64	"Business(purchase-sell)" ///
	65	"Business(production)" ///
	66	"Loan business(use of interest)" ///
	67	"Remittance (Country)" ///
	68	"Remittance (Abroad)" ///
	69	"Social safety net/pension" ///
	70	"Income/profit from agriculture" ///
	-96	"Others(specify)" , modify ;
	#delimit cr

	#delimit ;
	label define  a2highest_class_l1 ///
	-1 "Never attended school" ///
	-2 "Reads in pre-primary" ///
	0 "Reads in class I" ///
	1 "Completed class I" ///
	2  "Completed class II" ///
	3 "Completed class III" /// 
	4  "Completed class IV" ///
	5  "Completed class V" ///
	6  "Completed class VI"  ///
	7  "Completed class VII" ///
	8  "Completed class VIII" ///
	9  "Completed class IX" ///
	10  "Completed Secondary School/Dakhil" ///
	11  "HSC/Alim First Year" ///
	12  "Completed HSC/Alim" ///
	13  "BA/BSC/Fazil First Year" ///
	14  "BA/BSC/Fazil Second Year"  ///
	15  "BA/BSC/Fazil Third Year" ///
	16  "BA/BSC/Fazil Fourth Year"  /// 
	17  "MA/MSC and above/Kamil" ///
	18  "SSC Candidate" ///
	19  "HSC Candidate" ///
	20  "Medical/MBBS" ///
	21  "Nursing" ///
	22  "Engineer" ///
	23  "Diploma Engineer" ///
	24  "Vocational/Technical Education" ///
	-96 "Other (specify)" , modify ;
	#delimit cr

	#delimit ;
	label define a2_primaryres_relation_l1 ///
	1 "Primary respondent" ///
	2 "Primary respondent's Husband/wife" ///
	3 "Son/daughter" ///
	4 "Daughter/Son-in-law" ///
	5 "Grandson/daughter" ///
	6 "Father/mother" ///
	7 "Brother/sister" ///
	8 "Niece/Nephew" ///
	9 "Primary respondent's cousin" ///
	10	"Relationship with primary respondent's spouse/in-laws" ///
	11	"Brother/Sister-in-law" ///
	12	"Spouse's's niece/nephew" ///
	13	"Spouse's cousin" ///
	14 "Other relative" ///
	15 "Household help" /// 
	16 "Other Non relative/friends" , modify ;
	#delimit cr
	 
	#delimit ;
	label define a2_literacy_l1 ///
	1 "Cannot read and write" ///
	2 "Can sign only" ///
	3 "Can read only" ///
	4 "Can read and write" , modify ;
	#delimit cr

	label define yesno_l1 0 "No" 1 "Yes" -98 "NA" , modify

	* Add value labels 
	label value a1religion a1religion_name 
	label value a1language a1language_l1  
	label value a1ethnicity a1ethnicity_l1
	label value a2primaryres_relation a2_primaryres_relation_l1
	label value a2literacy a2_literacy_l1
	label value a2highest_class a2highest_class_l1
	label value a2sec_daily_activity a2sec_daily_activity2 a2prim_daily_activity_l1
	label value a2sec_monthly_activity a2prim_monthly_activity_l1
	label value a4earning_source1 a4earning_source2 a4_earning_l1
	label value a2migration_destination a2remittance_pyear yesno_l1

	* Rename variables
	rename a4employment_division a4employment_divisioncode
	rename a4employmentdivision  a4employment_divisionname
	rename a4employment_district a4employment_districtcode
	rename a4employmentdistrict  a4employment_districtname 
	rename a2migration_division a2migration_divisioncode
	rename a2migrationdivision  a2migration_divisionname   
	rename a2migration_district a2migration_districtcode
	rename a2migrationdistrict a2migration_districtname
	rename a2migration_country a2migration_countrycode
	rename a2migrationcountry a2migration_countryname

	*Re-label variables
	label var a2mem_age "Age" 
	label var a2mem_gender "Gender"
	label var a2primaryres_relation "Relation to primary repondent"
	label var a2literacy "Literacy"
	label var a2highest_class "Highest class passed"
	label var a2secondary_daily_wage "Do you have any secondary daily-wage work?"
	label var a2daily_wage  "In past year, did you/family member work for a daily wage?"
	label var a2prim_daily_activity  "What activity did you/family member perform?"
	label var a2prim_daily_n_days "How many days in the past year did you work?"
	label var a2prim_daily_name "Name of daily primary activity"
	label var a2sec_daily_activity "Name of secondary activity -1"
	label var a2sec_daily_activity2 "Name of secondary activity -2"
	label var a2monthly_wage "In past year, did you/family member work for a monthly salary?" 
	label var a2sec_monthly_activity "Name of secondary monthly activity"
	label var a2migration "Did the member move away for at least 6 months?"
	label var a2migration_destination "Did the member move outside the country?"
	label var a3attend_now "Currently attending educ. institute (Primary resp.)"
	label var a3edu_type "Institute Type(PR)"
	label var a3edu_type_oth "Currently attending educ. institure(PR)"
	label var a3advice "Recieved advice to attend agriculture-related training(PR)"
	label var a2mem_id_new "Unique identifier for each HH member"
	label var a4earning_source1 "main source of HH earning - 1"
	label var a4earning_source2 "main source of HH earning - 2"
	label var a4employment_divisioncode "Emp-Division Code"
	label var a4employment_divisionname "Emp-Division Name"
	label var a4employment_districtcode "Emp-District Code"
	label var a4employment_districtname "Emp-District Name" 
	label var a2prim_daily_wage_rate "What is the daily wage rate?"
	label var a2prim_monthly_activity "Does any member work for a monthly salary?"
	label var a2prim_monthly_wage_rate "What is the monthly wage?"
	  
	label var a2migration_id "Migration ID"        
	label var a2duration "Duration of migration"
	label var a2migration_destination "Destination of migration code"
	label var a2migration_divisioncode "Division code"
	label var a2migration_divisionname "Division name of migration"
	label var a2migration_districtcode "District code of migration"
	label var a2migration_districtname "District name of migration"
	label var a2migration_countrycode "Country code of migration"
	label var a2migration_countryname "Country name of migration"
	label var a2migration_country_oth "Country of migration(Other)"
	label var a2remittance_pyear "Remittance(Yes/No)"
	label var a2remittance_amount "Remittance(Cash)"
	label var a2remittance_inkind "Remittance(In-Kind)" 
	label var a1hhid_combined "HHID with split id included"
	label var a2hhroster_count "Number of family members"
	label var a2mem_id "HHID+ Member id (2018)"
	label var a2mem_id_2024 "HHID + Member id (2024)"
	label var a2mem_id_new "Member id (2024)"
	label var a2mem_status "Member status in the current round"

	* Drop variables with all missings 
	missings dropvars , force //a1religion_name a1religion_oth a1language_oth dropped

	* Drop Variables not necessary (these have already been cleaned or these merging variables)
	drop PARENT_KEY KEY SETOFa2hhroster SETOFa2sec_daily_repeat SETOFa2sec_monthly_repeat ///
	num_migration_count SETOFa5hh_own_repeat SETOFa5vehicle_own_repeat SETOFa5comm_own_repeat ///
	SETOFa5animal_own_repeat SETOFa5agri_own_repeat setofnum_migration_main setofnum_migration_resurvey resurvey parent_key key

	* Order Variables
	order a1* a2index a2mem_id a2add_mem a2mem_id_2024 a2mem_id_new a2mem_status a2mem_age a2mem_gender a2primaryres_relation a2* ///
	a2literacy a2highest_class a2daily_wage a2prim_daily_activity a2prim_daily_n_days ///
	a2prim_daily_wage_rate a2secondary_daily_wage a2monthly_wage a2prim_monthly_activity ///
	a2prim_monthly_activity_oth a2prim_monthly_n_mth a2prim_monthly_wage_rate ///
	a2secondary_monthly_wage a2sec_monthly_activity a2migration a2migration_purpose ///
	a2migration_purpose_oth a2n_migration a2migration_id a2duration a2migration_destination ///
	a2migration_divisioncode a2migration_divisionname a2migration_districtcode /// 
	a2migration_districtname a2migration_countrycode a2migration_country_oth /// 
	a2remittance_pyear a2remittance_amount a2remittance_inkind a2migration_countryname ///
	a2add_mem a2hhroster_count a2agri_decision a2hh_head a2sec_daily_activity a2sec_daily_activity2 a3* a4* 

	* Sort Data 
	sort a2mem_id_2024 

	/* NOTES:
	unique(a1hhid_combined)
	Number of unique values of a1hhid_combined is  5562
	Number of unique members:  37045
	Number of records is  37401
	I drop observations in two places - 1 if there are duplicate household entries in the HH roster and secondly if there are duplicate HH member ids in the 
	a2hh_roster which contains information on all HH members. 
	*/ 

	* some adjustments 
	rename hh_head_age a2_hh_head_age
	order a1* a2* a3* a4*  

	duplicates tag a2mem_id_new a2migration_id , gen(dup)
	drop if dup == 4 
	drop dup

	drop a2literacyname a2highestclass
	* Save the dataset

	save "${final_data}${slash}SPIA_BIHS_2024_module_a2_4.dta" , replace

	 }

	********************************************************************************
	**# Module A5-6
	********************************************************************************
	 {
	** Module A5 ** 
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear

	* Keep module A5 and A6 variables  
	 keep a5* a6* SETOFa5hh_own_repeat SETOFa5vehicle_own_repeat ///
	 SETOFa5comm_own_repeat SETOFa5animal_own_repeat SETOFa5agri_own_repeat ///
	 KEY a1hhid_combined
	 
	* save label names 
	foreach v of var * {
	 local l`v' : variable label `v'
	 if `"`l`v''"' == "" {
	 local l`v' "`v'"
	 }
	}
	 
	* Since these are HH level questions - only keep one observation per household. 
	collapse (first) a5* KEY SETOFa5hh_own_repeat SETOFa5vehicle_own_repeat ///
	SETOFa5comm_own_repeat SETOFa5animal_own_repeat SETOFa5agri_own_repeat a6* , by(a1hhid_combined)

	foreach v of var * {
	label var `v' `"`l`v''"'
	}

	merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1" , nogenerate keep(3) 
	drop a1division divisionname a1district districtname a1upazila upazilaname a1union a1mouza a1village a01combined_18 a01combined_15 a01_12 a01split_hh_15 a01split_serial_15 a01absent_15 a01split_hh_18 a01split_serial_18 a1hhloc a1split_hh a1total_split a1split_hh_serial a1religion a1language a1ethnicity a1ethnicity_oth hhweight_24

	rename a5hh_own_* hh_item_* 

	* Import the a5hh_own_repeat dataset
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_a-module_a5-a5hh_own_repeat.csv", varnames(1) clear 
	drop a5hh_own_name key
	label var a5hh_own_qty "Quantity owned"
	label var a5hh_own_pc "Percent of total"
	label var a5hh_own_yr "Year of purchase"
	label var a5hhown_pur_price "Year of purchase"
	label var a5hhown_mar_value "Current market value(Rs.)"

	reshape wide a5hh_own_qty a5hh_own_pc a5hh_own_yr a5hhown_pur_price a5hhown_mar_value, i(setofa5hh_own_repeat) j(a5hh_own_id)

	rename setofa5hh_own_repeat SETOFa5hh_own_repeat
	rename a5hh_own_* hh_item_* 
	rename a5hhown_* hh_item_*

	tempfile a5_own
	save "`a5_own'"
	restore

	merge 1:1 SETOFa5hh_own_repeat using "`a5_own'" , nogenerate keep(1 3)

	* Import the vehicle dataset 
	rename a5vehicle_own_* vehicle_*  
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_a-module_a5-a5vehicle_own_repeat.csv", varnames(1) clear 
	drop a5vehicle_own_name key

	label var a5vehicle_own_qty "Quantity owned"
	label var a5vehicle_own_pc "Percent of total"
	label var a5vehicle_own_yr "Year of purchase"
	label var a5vehicleown_pur_price "Year of purchase"
	label var a5vehicleown_mar_value "Current market value(Rs.)"

	reshape wide a5vehicle_own_qty a5vehicle_own_pc a5vehicle_own_yr a5vehicleown_pur_price a5vehicleown_mar_value, i(setofa5vehicle_own_repeat) j(a5vehicle_own_id)
	rename a5vehicle_own_* vehicle_* 
	rename a5vehicleown_* vehicle_*
	rename setofa5vehicle_own_repeat SETOFa5vehicle_own_repeat

	tempfile a5_vehicle
	save "`a5_vehicle'"
	restore

	merge 1:1 SETOFa5vehicle_own_repeat using "`a5_vehicle'" , nogenerate keep(1 3)

	* Import the communication dataset 
	rename a5comm_own_* communication_*  
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_a-module_a5-a5comm_own_repeat.csv", varnames(1) clear 
	drop a5comm_own_name key

	label var a5comm_own_qty "Quantity owned"
	label var a5comm_own_pc "Percent of total"
	label var a5comm_own_yr "Year of purchase"
	label var a5commown_pur_price "Year of purchase"
	label var a5commown_mar_value "Current market value(Rs.)"

	reshape wide a5comm_own_qty a5comm_own_pc a5comm_own_yr a5commown_pur_price a5commown_mar_value, i(setofa5comm_own_repeat) j(a5comm_own_id)
	rename a5comm_own_* communication_* 
	rename a5commown_* communication__*
	rename setofa5comm_own_repeat SETOFa5comm_own_repeat

	tempfile a5_comm
	save "`a5_comm'"
	restore

	merge 1:1 SETOFa5comm_own_repeat using "`a5_comm'" , nogenerate keep(1 3)

	* Import the animal dataset 
	rename a5animal_own_* animal_*  
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_a-module_a5-a5animal_own_repeat.csv", varnames(1) clear 
	drop a5animal_own_name key

	label var a5animal_own_qty "Quantity owned"
	label var a5animal_own_pc "Percent of total"
	label var a5animal_own_yr "Year of purchase"
	label var a5animalown_pur_price "Year of purchase"
	label var a5animalown_mar_value "Current market value(Rs.)"

	reshape wide a5animal_own_qty a5animal_own_pc a5animal_own_yr a5animalown_pur_price a5animalown_mar_value, i(setofa5animal_own_repeat) j(a5animal_own_id)
	rename a5animal_own_* animal_* 
	rename a5animalown_* animal__*
	rename setofa5animal_own_repeat SETOFa5animal_own_repeat

	tempfile a5_animal
	save "`a5_animal'"
	restore

	merge 1:1 SETOFa5animal_own_repeat using "`a5_animal'" , nogenerate keep(1 3)

	* Import the agricultural equipment dataset 
	rename a5agri_own_* agri_equipment_*  
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_a-module_a5-a5agri_own_repeat.csv", varnames(1) clear 
	drop a5agri_own_name key

	label var a5agri_own_qty "Quantity owned"
	label var a5agri_own_pc "Percent of total"
	label var a5agri_own_yr "Year of purchase"
	label var a5agriown_pur_price "Year of purchase"
	label var a5agriown_mar_value "Current market value(Rs.)"

	reshape wide a5agri_own_qty a5agri_own_pc a5agri_own_yr a5agriown_pur_price a5agriown_mar_value, i(setofa5agri_own_repeat) j(a5agri_own_id)
	rename a5agri_own_* agri_equipment_* 
	rename a5agriown_* agri_equipment__*
	rename setofa5agri_own_repeat SETOFa5agri_own_repeat

	tempfile a5_agri
	save "`a5_agri'"
	restore

	merge 1:1 SETOFa5agri_own_repeat using "`a5_agri'" , nogenerate keep(1 3)

	** other HH characteristics 
	#delimit ;
	label define a5_floor_l1 ///
	1 "Natural floor Earth/sand" ///
	2 "Rudimentary floor wood planks" ///
	3 "Palm/bamboo" ///
	4 "Finished floor or polished wood" ///
	5 "Cement/Ceramic tiles" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define a5_roof_l1 ///
	1 "No roof" ///
	2 "Thatch/palm/leaf/sod" ///
	3 "Palm/bamboo/wooden planks" ///
	4 "Metal/Wood/Tin" ///
	5 "Ceramic tiles/Cement/Roofing shingles" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define a5_flush_l1 ///
	1 "Flush to piped sewer system/septic tank" ///
	2 "Pit latrine with slab" ///
	3 "Pit latrine without slab/open pit" ///
	4 "No facilities or field" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define a5_water_l1 ///
	1 "Piped water to house" ///
	2 "Public tap/standpipe" ///
	3 "Tanker-truck" ///
	4 "Tubewell/borehole" ///
	5 "Well" /// 
	6 "Rainwater" ///
	7 "Surface water" ///
	-96 "Other" , modify ;
	#delimit cr

	label value a5hhi_floor a5_floor_l1
	label value a5hhi_roof a5_roof_l1
	label value a5hhi_toilet a5_flush_l1
	label value a5hhi_drinking_water a5_water_l1

	* LABEL VARIABLES 
	label var a5hhi_floor "Main material for the dwelling floor"
	label var a5hhi_roof "Main material for the dwelling roof"
	label var a5hhi_toilet "Toilet facility for the household members"
	label var a5hhi_drinking_water "Main source of drinking water for the household members"

	* RENAME VARIABLES 
	rename a5hhi_floor hh_floor
	rename a5hhi_roof hh_roof
	rename a5hhi_toilet hh_toilet
	rename a5hhi_drinking_water hh_drinking_water
	rename a6savings hh_savings
	rename a6saving_mechanism_* saving_mechanism_*

	* DROP 
	drop a5hh_own hh_item_repeat_count a5vehicle_own vehicle_repeat_count a5comm_own ///
	communication_repeat_count a5animal_own animal_repeat_count a5agri_own SETOFa5hh_own_repeat ///
	SETOFa5vehicle_own_repeat SETOFa5comm_own_repeat SETOFa5animal_own_repeat SETOFa5agri_own_repeat agri_equipment_repeat_count ///
	a5hhi_floor_oth a5hhi_roof_oth a5hhi_toilet_oth a5hhi_drinking_water_oth saving_mechanism_oth KEY a6saving_mechanism ///
	hh_item__98 vehicle__98 communication__98 animal__98  parent_key

	* ORDER
	order a1hhid_combined hh_item_1 hh_item_qty1 hh_item_pc1 hh_item_yr1 hh_item_pur_price1 hh_item_mar_value1 ///
	hh_item_2 hh_item_qty2 hh_item_pc2 hh_item_yr2 hh_item_pur_price2 hh_item_mar_value2 hh_item_3 ///
	hh_item_qty3 hh_item_pc3 hh_item_yr3 hh_item_pur_price3 hh_item_mar_value3 hh_item_4 hh_item_qty4 ///
	hh_item_pc4 hh_item_yr4 hh_item_pur_price4 hh_item_mar_value4 hh_item_5 hh_item_qty5 hh_item_pc5 ///
	hh_item_yr5 hh_item_pur_price5 hh_item_mar_value5 hh_item_6 hh_item_qty6 hh_item_pc6 hh_item_yr6 ///
	hh_item_pur_price6 hh_item_mar_value6 hh_item_7 hh_item_qty7 hh_item_pc7 hh_item_yr7 ///
	hh_item_pur_price7 hh_item_mar_value7 hh_item_8 hh_item_qty8 hh_item_pc8 hh_item_yr8 ///
	hh_item_pur_price8 hh_item_mar_value8 vehicle_1 vehicle_qty1 vehicle_pc1 ///
	vehicle_yr1 vehicle_pur_price1 vehicle_mar_value1 vehicle_2 vehicle_qty2 vehicle_pc2 ///
	vehicle_yr2 vehicle_pur_price2 vehicle_mar_value2 vehicle_3 vehicle_qty3 vehicle_pc3 ///
	vehicle_yr3 vehicle_pur_price3 vehicle_mar_value3 vehicle_4 vehicle_qty4 vehicle_pc4 ///
	vehicle_yr4 vehicle_pur_price4 vehicle_mar_value4 vehicle_5 vehicle_qty5 vehicle_pc5 ///
	vehicle_yr5 vehicle_pur_price5 vehicle_mar_value5 vehicle_6 vehicle_qty6 vehicle_pc6 /// 
	vehicle_yr6 vehicle_pur_price6 vehicle_mar_value6 vehicle_7 vehicle_qty7 vehicle_pc7 /// 
	vehicle_yr7 vehicle_pur_price7 vehicle_mar_value7 communication_1 communication_qty1 ///
	communication_pc1 communication_yr1 communication__pur_price1 communication__mar_value1 ///
	communication_2 communication_qty2 communication_pc2 communication_yr2 communication__pur_price2 ///
	communication__mar_value2 communication_3 communication_qty3 communication_pc3 communication_yr3 communication__pur_price3 ///
	communication__mar_value3 communication_4 communication_qty4 communication_pc4 communication_yr4 communication__pur_price4 ///
	communication__mar_value4 communication_5 communication_qty5 communication_pc5 communication_yr5 ///
	communication__pur_price5 communication_6 communication__mar_value5 communication_qty6 communication_pc6 ///
	communication_yr6 communication__pur_price6 communication__mar_value6 ///
	animal_1 animal_qty1 animal_pc1 animal_yr1 animal__pur_price1 animal__mar_value1 ///
	animal_2 animal_qty2 animal_pc2 animal_yr2 animal__pur_price2 animal__mar_value2 /// 
	animal_3 animal_qty3 animal_pc3 animal_yr3 animal__pur_price3 animal__mar_value3 /// 
	animal_4 animal_qty4 animal_pc4 animal_yr4 animal__pur_price4 animal__mar_value4 ///
	agri_equipment_1 agri_equipment_qty1 agri_equipment_pc1 agri_equipment_yr1 agri_equipment__pur_price1 agri_equipment__mar_value1 ///
	agri_equipment_2 agri_equipment_qty2 agri_equipment_pc2 agri_equipment_yr2 agri_equipment__pur_price2 agri_equipment__mar_value2 ///
	agri_equipment_3 agri_equipment_qty3 agri_equipment_pc3 agri_equipment_yr3 agri_equipment__pur_price3 agri_equipment__mar_value3 ///
	agri_equipment_4 agri_equipment_qty4 agri_equipment_pc4 agri_equipment_yr4 agri_equipment__pur_price4 agri_equipment__mar_value4 ///
	agri_equipment_5 agri_equipment_qty5 agri_equipment_pc5 agri_equipment_yr5 agri_equipment__pur_price5 agri_equipment__mar_value5 ///
	agri_equipment_6 agri_equipment_qty6 agri_equipment_pc6 agri_equipment_yr6 agri_equipment__pur_price6 agri_equipment__mar_value6 ///
	agri_equipment_7 agri_equipment_qty7 agri_equipment_pc7 agri_equipment_yr7 agri_equipment__pur_price7 agri_equipment__mar_value7 ///
	agri_equipment_8 agri_equipment_qty8 agri_equipment_pc8 agri_equipment_yr8 agri_equipment__pur_price8 agri_equipment__mar_value8 ///
	agri_equipment_9 agri_equipment_qty9 agri_equipment_pc9 agri_equipment_yr9 agri_equipment__pur_price9 agri_equipment__mar_value9 ///
	agri_equipment_10 agri_equipment_qty10 agri_equipment_pc10 agri_equipment_yr10 agri_equipment__pur_price10 agri_equipment__mar_value10 ///
	agri_equipment_11 agri_equipment_qty11 agri_equipment_pc11 agri_equipment_yr11 agri_equipment__pur_price11 agri_equipment__mar_value11 ///
	agri_equipment_12 agri_equipment_qty12 agri_equipment_pc12 agri_equipment_yr12 agri_equipment__pur_price12 agri_equipment__mar_value12 ///
	agri_equipment_13 agri_equipment_qty13 agri_equipment_pc13 agri_equipment_yr13 agri_equipment__pur_price13 agri_equipment__mar_value13 ///
	agri_equipment_14 agri_equipment_qty14 agri_equipment_pc14 agri_equipment_yr14 agri_equipment__pur_price14 agri_equipment__mar_value14 ///
	agri_equipment_15 agri_equipment_qty15 agri_equipment_pc15 agri_equipment_yr15 agri_equipment__pur_price15 agri_equipment__mar_value15 ///
	agri_equipment_16 agri_equipment_qty16 agri_equipment_pc16 agri_equipment_yr16 agri_equipment__pur_price16 agri_equipment__mar_value16 ///
	agri_equipment_17 agri_equipment_qty17 agri_equipment_pc17 agri_equipment_yr17 agri_equipment__pur_price17 agri_equipment__mar_value17 ///
	agri_equipment_18 agri_equipment_qty18 agri_equipment_pc18 agri_equipment_yr18 agri_equipment__pur_price18 agri_equipment__mar_value18 ///
	agri_equipment_19 agri_equipment_qty19 agri_equipment_pc19 agri_equipment_yr19 agri_equipment__pur_price19 agri_equipment__mar_value19 ///
	agri_equipment_20 agri_equipment_qty20 agri_equipment_pc20 agri_equipment_yr20 agri_equipment__pur_price20 agri_equipment__mar_value20 ///
	agri_equipment_21 agri_equipment_qty21 agri_equipment_pc21 agri_equipment_yr21 agri_equipment__pur_price21 agri_equipment__mar_value21 ///
	agri_equipment_22 agri_equipment_qty22 agri_equipment_pc22 agri_equipment_yr22 agri_equipment__pur_price22 agri_equipment__mar_value22 ///
	agri_equipment_23 agri_equipment_qty23 agri_equipment_pc23 agri_equipment_yr23 agri_equipment__pur_price23 agri_equipment__mar_value23 ///
	agri_equipment__98 agri_equipment_oth hh_floor hh_roof hh_toilet hh_drinking_water hh_savings saving_mechanism_*

	rename hh_item_* a5_hh_item_*
	rename vehicle_* a5_vehicle_*
	rename communication_* a5_communication_*
	rename animal_*  a5_animal_*
	rename agri_equipment_*  a5_agri_equipment_*
	rename hh_* a5_hh_*
	rename a5_hh_savings a6_hh_savings
	rename saving_mechanism_*  a6_saving_mechanism_*

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	
	drop starttime endtime SubmissionDate
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_a5_6.dta", replace

	 }
	
	**# B1-5 main survey
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b1plot_roster") firstrow clear
	drop KEY
	ren PARENT_KEY KEY
	
	merge m:1 SETOFb1plot_roster using `main_data', nogen keep(3)
	
	tempfile bonedata
	save `bonedata', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("module_b2_3") firstrow clear
	drop KEY
	ren (b2land_select PARENT_KEY) (plot_num KEY)
	
	merge m:1 KEY using `main_data', nogen keep(2 3)
	
	/*
	test command: merge m:1 KEY using `main_data'
	
    Result                      Number of obs
    -----------------------------------------
    Not matched                         4,567
        from master                     2,062  (_merge==1)
        from using                      2,505  (_merge==2)

    Matched                            13,632  (_merge==3)
    -----------------------------------------
	
	Here, the unmatched data from the master is due to the 730 dropped HH due to
	enumerators skipping questions.
	
	The unmatched data from using is because the HHs from the main data are non
	agri HHs
	
	*/
	
	tempfile b2_3
	save `b2_3', replace
	

	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("module_b4") firstrow clear
	ren (b4land_select PARENT_KEY KEY b4crop_season b4land_id b4crop b4plot_index) (plot_num KEY KEY_B4 b2crop_season b2land_id b2crop b2land_index)
	
	merge m:1 KEY using `main_data', nogen keep(2 3)
	duplicates drop a1hhid_combined plot_num b2land_index, force
	tempfile b4
	save `b4', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("module_b5") firstrow clear
	ren (b5land_select PARENT_KEY KEY b5crop_season b5land_id b5crop b5plot_index) (plot_num KEY KEY_B5 b2crop_season b2land_id b2crop b2land_index)
	
	merge m:1 KEY using `main_data', nogen keep(2 3)
	duplicates drop a1hhid_combined plot_num b2land_index, force 
	merge 1:1 a1hhid_combined plot_num b2land_index using `b4', nogen keep(3)
	
	/*
	
	  Result                      Number of obs
    -----------------------------------------
    Not matched                            10
        from master                         7  (_merge==1)
        from using                          3  (_merge==2)

    Matched                            16,156  (_merge==3)
    -----------------------------------------
	
	These have probably happened due to the enumerators denoting a plot as agri
	first and non agri then similar to the explanation below. As it only happened
	for a miniscule number of plots, I'll drop them and only keep the matched
	ones.

	
	*/
	
	tempfile b4_5
	save `b4_5', replace
	
	u `b2_3', clear
	
	merge m:1 a1hhid_combined plot_num b2land_index using `b4_5', nogen keep(1 3)
	
	/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                            26
        from master                         2  (_merge==1)
        from using                         24  (_merge==2)

    Matched                            16,135  (_merge==3)
    -----------------------------------------
	
	The hypothesis regarding these 26 unmatched observations is that
	the enumerators coded these plots as agri plots at first and took
	information regarding agriculture including module b4. The way
	the surveyCTO is coded is that module b4 and b5 opens the same
	number of times that module b2 is filled up. Thus, when they filled 
	it up the first time, data got inserted here into the repeat group.
	But when they recoded these plots as non agricultural later on, 
	module b2 closed but the entries in module b4 remained.
	In the two HHs in the _merge==1 case, I found that this HH was 
	a non agri HH. Thus, the agricultural info was taken and then 
	discarded here. For the 24 cases in using, 2 are for the HH which
	became from agri to non agri. For the other cases, I assume certain 
	plots were coded as non agricultural, but the others remained agri 
	plots keeping the HH as agricultural.
	As this happens for a very small number of cases, I am discarding 
	the using data here because it cannot be matched with crop data and
	keeping the master and matched observations.
	*/
	

	
	merge m:1 a1hhid_combined plot_num using `bonedata', nogen
	
	
	/*
	test command: 
	merge m:1 a1hhid_combined plot_num using `b1data'
	
	Result                      Number of obs
    -----------------------------------------
    Not matched                        29,245
        from master                     4,567  (_merge==1)
        from using                     24,678  (_merge==2)

    Matched                            13,632  (_merge==3)
    -----------------------------------------

	Here, the unmatched data from master did not match because it was not merged
	when b2 was merged with main long data. 4567 matches with 4567 from before.
	
	In the unmatched data from using, 7,836 of the plots were not with the HH
	in 2018 round and this round both. Out of the 16,842, no agri activities 
	took place in 12,743. Among the 4,099 where agri activities are done, the
	HH takes decision for only	731 plots as active farmers. out of the 731,
	618 are ponds where HH takes active decision. Thus, they should not merge
	with B2. Among the remaining 113, 28 were taken solely for seedbeds. That
	leaves us with 85 plots from 66 HH which should be used in crop cultivation
	in the past year but no crop cultivation data has been collected by enums.
	
	*/
	
	
	tempfile b1_5
	save `b1_5', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b4machine_repeat") firstrow clear
	drop KEY
	ren (PARENT_KEY) (KEY_B4)
	
	drop if mi(b4machine_rent)
	
	replace b4machine_name = "Power tiller" if b4machine_name == "পাওয়ার টিলার"
	replace b4machine_name = "Tractor" if b4machine_name == "ট্রাক্টর"
	replace b4machine_name = "Plough" if b4machine_name == "লাঙ্গল/জোয়াল"	
	replace b4machine_name = "Manual" if b4machine_name == "কোদাল/ম্যানুয়াল"	
	
	reshape wide b4machine_rent b4machine_name, i(KEY_B4) j(b4machine_id)
		
	merge 1:m KEY_B4 using `b1_5', nogen keep(2 3)
		
	tempfile b1_5_repeat
	save `b1_5_repeat', replace
	
	
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b5dry_repeat") firstrow clear
	drop KEY
	ren (PARENT_KEY) (KEY_B5)
	
	drop if mi(b5dry_how_index)
	
	reshape wide b5dry_how, i(KEY_B5) j(b5dry_how_index)
	
	merge 1:m KEY_B5 using `b1_5_repeat', nogen keep(2 3)
	
	tempfile b1_5_final
	save `b1_5_final', replace
	
	ren plot_num b1plot_num
	
	preserve
	
	g b1plot_left_2018 = (b1plot_status==12)
	
	collapse(sum) b1plot_left_2018, by(a1hhid_combined)
	
	tempfile left_plots
	save `left_plots', replace
	
	restore
	
	merge m:1 a1hhid_combined using `left_plots', nogen
	
	g b1plot_roster_count_clean = b1plot_roster_count - b1plot_left_2018
	
	g b1n_plot_2018_clean = b1n_plot_2018 - b1plot_left_2018

	drop if b1plot_status==12  //Dropping the ones not with HH in 2018 and this round both
	
	foreach var of varlist b2paddyvariety b2paddyintercropvariety {
	split `var', p(|) 
	}
	
	drop b2paddyvariety2 b2paddyintercropvariety2 b2paddyvariety b2paddyintercropvariety
	
	ren (b2paddyvariety1 b2paddyintercropvariety1) (b2paddyvariety b2paddyintercropvariety)
	
	keep a1hhid_combined b1* b2* b3* b4* b5* KEY enum_comment f1*

	
	//Dropping surveyCTO releated variables
	drop b2landname_size b2plot_type b2plottype b2soil_type b2soiltype b2plot_size ///
	b2season_name b2land_season b2land_id ///
	b2plant_boro b2plant_boro_no b2plant_aman b2plant_aman_no b2plant_aus b2plant_aus_no ///
	b2plant23boro b2plant23boro_no b2add_plot b1owncrop_list b1pond_list b2tot_boro ///
	b2tot_aman b2tot_aus b2tot23boro b2tot_rice b3net_har_b_aus_loc b3net_har_b_aus_loc ///
	b3tot_har_b_aus_loc b3net_har_t_aus_loc b3int_net_har_t_aus_loc b3tot_har_t_aus_loc ///
	b3net_har_t_aus_hyv b3int_net_har_t_aus_hyv b3tot_har_t_aus_hyv b3net_har_t_aus_hyb ///
	b3int_net_har_t_aus_hyb b3tot_har_t_aus_hyb b3net_har_b_aman_loc b3int_net_har_b_aman_loc ///
	b3tot_har_b_aman_loc b3net_har_t_aman_loc b3int_net_har_t_aman_loc b3tot_har_t_aman_loc ///
	b3net_har_t_aman_hyv b3int_net_har_t_aman_hyv b3tot_har_t_aman_hyv b3net_har_t_aman_hyb ///
	b3int_net_har_t_aman_hyb b3tot_har_t_aman_hyb b3net_har_boro_loc b3int_net_har_boro_loc ///
	b3tot_har_boro_loc b3net_har_boro_hyv b3int_net_har_boro_hyv b3tot_har_boro_hyv ///
	b3net_har_boro_hyb b3int_net_har_boro_hyb b3tot_har_boro_hyb b3net_har_wheat_loc ///
	b3int_net_har_wheat_loc b3tot_har_wheat_loc b3net_har_wheat_hyv b3int_net_har_wheat_hyv ///
	b3tot_har_wheat_hyv b3net_har_maize b3int_net_har_maize b3tot_har_maize b3net_har_barley ///
	b3int_net_har_barley b3tot_har_barley b3net_har_job b3int_net_har_job b3tot_har_job ///
	b3net_har_cheena b3int_net_har_cheena b3tot_har_cheena b3net_har_kaun ///
	b3int_net_har_kaun b3tot_har_kaun b3net_har_joar b3int_net_har_joar b3tot_har_joar ///
	b3net_har_bojra b3int_net_har_bojra b3tot_har_bojra b3net_har_cereal ///
	b3int_net_har_cereal b3tot_har_cereal b1land_name b1landname_size ///
	b1add_plot b1owncrop_index b1pond_index b3int_net_har_b_aus_loc
	
	order b1plot_num, after(b1fishing_count)
	
	order b2* b3* b4* b5*, after(b1_boro23_size)
	
	order f1* enum_comment, after(b3int_qty_net_harvest)
	
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_main.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_main.dta") label(English) dateformat(MDY) clear save("${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_main.dta")
	
	**# Resurvey B1-5

	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(b1plot_roster) clear
	drop KEY
	ren PARENT_KEY KEY
	
	merge m:1 KEY SETOFb1plot_roster using `resurvey_data', nogen keep(3) // 34 lands from 3 HH do not match for duplicate submissions as we dropped the duplicate submissions and new KEYs are created for each new submissions
	tempfile boneresurvey
	save `boneresurvey', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("module_b2_3") firstrow clear
	drop KEY
	ren (b2land_select PARENT_KEY) (plot_num KEY)
	
	merge m:1 KEY using `resurvey_data', nogen keep(2 3)

	tempfile b2_3resurvey
	save `b2_3resurvey', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("module_b4") firstrow clear
	ren (b4land_select PARENT_KEY KEY b4crop_season b4land_id b4crop b4plot_index) (plot_num KEY KEY_B4 b2crop_season b2land_id b2crop b2land_index)
	
	merge m:1 KEY using `resurvey_data', nogen keep(2 3)
	
	tempfile b4resurvey
	save `b4resurvey', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("module_b5") firstrow clear
	ren (b5land_select PARENT_KEY KEY b5crop_season b5land_id b5crop b5plot_index) (plot_num KEY KEY_B5 b2crop_season b2land_id b2crop b2land_index)
	
	merge m:1 KEY using `resurvey_data', nogen keep(2 3)
	merge 1:1 a1hhid_combined plot_num b2land_index using `b4resurvey', nogen keep(3)

	tempfile b4_5resurvey
	save `b4_5resurvey', replace
	
	u `b2_3resurvey', clear
	
	merge m:1 a1hhid_combined plot_num b2land_index using `b4_5resurvey', nogen keep(1 3)
	merge m:1 a1hhid_combined plot_num using `boneresurvey', nogen

	tempfile b1_5resurvey
	save `b1_5resurvey', replace

	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b4machine_repeat") firstrow clear
	drop KEY
	ren (PARENT_KEY) (KEY_B4)
	
	drop if mi(b4machine_rent)
	
	replace b4machine_name = "Power tiller" if b4machine_name == "পাওয়ার টিলার"
	replace b4machine_name = "Tractor" if b4machine_name == "ট্রাক্টর"
	replace b4machine_name = "Plough" if b4machine_name == "লাঙ্গল/জোয়াল"	
	replace b4machine_name = "Manual" if b4machine_name == "কোদাল/ম্যানুয়াল"	
	
	reshape wide b4machine_rent b4machine_name, i(KEY_B4) j(b4machine_id)
		
	merge 1:m KEY_B4 using `b1_5resurvey', nogen keep(2 3)
		
	tempfile b1_5_repeat_re
	save `b1_5_repeat_re', replace
	

	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b5dry_repeat") firstrow clear
	drop KEY
	ren (PARENT_KEY) (KEY_B5)
	
	drop if mi(b5dry_how_index)
	
	reshape wide b5dry_how, i(KEY_B5) j(b5dry_how_index)
	
	merge 1:m KEY_B5 using `b1_5_repeat_re', nogen keep(2 3)
	
	tempfile b1_5_final_re
	save `b1_5_final_re', replace
	

	ren plot_num b1plot_num
	preserve
	g b1plot_left_2018 = (b1plot_status==12)
	collapse(sum) b1plot_left_2018, by(a1hhid_combined)
	tempfile left_plots_re
	save `left_plots_re', replace
	restore
	
	merge m:1 a1hhid_combined using `left_plots_re', nogen
	g b1plot_roster_count_clean = b1plot_roster_count - b1plot_left_2018
	g b1n_plot_2018_clean = b1n_plot_2018 - b1plot_left_2018


	drop if b1plot_status==12  //Dropping the ones not with HH in 2018 and this round both
	
	
	
	keep a1hhid_combined b1* b2* b3* b4* b5* KEY enum_comment f1*

	
	//Dropping surveyCTO releated variables
	drop b2landname_size b2plot_type b2plottype b2soil_type b2soiltype b2plot_size ///
	b2season_name b2land_season b2land_id ///
	b2plant_boro b2plant_boro_no b2plant_aman b2plant_aman_no b2plant_aus b2plant_aus_no ///
	b2plant23boro b2plant23boro_no b2add_plot b1owncrop_list b1pond_list b2tot_boro ///
	b2tot_aman b2tot_aus b2tot23boro b2tot_rice ///
	b1land_name b1landname_size ///
	b1add_plot b1owncrop_index b1pond_index
	
	order b1plot_num, after(b1fishing_count)
	
	order b2* b3* b4* b5*, after(b1_boro23_size)
	
	order f1* enum_comment, after(b3int_qty_net_harvest)
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_resurvey.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
	data("${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_resurvey.dta") label(English) dateformat(MDY) clear save("${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_resurvey.dta")
		
	append using "${temp_data}${slash}SPIA_BIHS_2024_module_b1_5_main.dta", force

	gen agri_control_household = (b1repeat_count > 0) | (b1fishing_count > 0)



	tempfile b1_5final
	save `b1_5final', replace
	
	order b1plot_num, after(b1fishing_count)
	
	order b2* b3* b4* b5*, after(b1_boro23_size)
	
	order f1* enum_comment, after(b3int_qty_net_harvest)
	
	egen: a1hhid_plotnum = concat(a1hhid_combined b1plot_num), p(.) 
	
	la var a1hhid_plotnum "Unique plot identifier for plot roster"

	duplicates drop a1hhid_plotnum b2crop_season b2crop b2crop_intertype b2split_clean, force 

	save "${temp_data}${slash}SPIA_BIHS_2024_module_b1_5", replace
	
	**# Clean module B1-5
	
	u "${temp_data}${slash}SPIA_BIHS_2024_module_b1_5", clear
	
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen
	
		//plot size and plot status cleaning
	
	destring b1plot_size_2018, replace
	
	g b1plotsize_difference = b1plotsize_decimal - b1plot_size_2018
	
	recode b1plotsize_decimal 0.000001/100000 = 0 if b1plot_owner==7 & b1plot_status==4 & b1plotsize_difference==0
	
	recode b1plot_status 2 = 1 if inrange(b1plot_owner, 1, 6) & b1plotsize_difference==0 & b1plot_status==2
	
	recode b1plotsize_decimal 0.000001/100000 = . if (b1plot_owner==-96 | b1plot_owner==7) & b1plotsize_difference==0 & b1plot_status==2
	
	recode b1plotsize_decimal 0.000001/100000 = 0 if b1plot_owner==7 & b1plotsize_difference==0 & b1plot_status==4
	
	recode b1plot_status 7 = 1 if b1plot_status_2018 == "New Purchase" & b1plotsize_difference == 0
	
	recode b1plot_status 9 = 1 if b1plot_status_2018 == "New Mortgage" & b1plotsize_difference == 0
	
	recode b1plot_status 8 = 1 if (b1plot_status_2018 == "New Mortgage" | b1plot_status_2018 == "New inheritance" | b1plot_status_2018 == "Inherited or Household Split") & b1plotsize_difference == 0 & a1split_hh == 0
	
	recode b1plot_status 1 = 13 if b1plotsize_difference!=0 & !mi(b1plotsize_difference)
	
	recode b1plotsize_decimal 0.000001/100000 = 0 if b1plot_status_2018 == "Sold" ///
	& b1plotsize_difference>0 & !mi(b1plotsize_difference) & b1plot_status == 2 ///
	& b1plot_size_2018 == 0
	
	recode b1plotsize_decimal 0.000001/100000 = 3 if b1plot_status_2018 == "Sold" ///
	& b1plotsize_difference>0 & !mi(b1plotsize_difference) & b1plot_status == 2 ///
	& b1plot_size_2018 == 3
	
	recode b1plotsize_decimal 0.000001/100000 = 0 if b1plot_acquired == 6 ///
	& b1plotsize_difference>0 & !mi(b1plotsize_difference) & b1plot_status == 4
	
	recode b1plot_status 8 = 14 if a1split_hh == 0 & b1plotsize_difference<0 ///
	& !mi(b1plotsize_difference)
	
	replace b2area = b1plotsize_decimal if b2area == 0
	
	
		
	/*The following plots have the same size in both rounds with a 0 size. This
	means they are not required for our purpose. Looking at size from 2018, 
	136/138 had 0 size then as well. Thus, they should be dropped because
	it is not part of the land roster in 18 or 24.
	*/
	
	drop if b1plotsize_decimal == 0 & b1plot_status == 1
	
	/*If the plot status is given as rented and the size on survey day is 0 decimal,
	then it means that the plot was rented but let go. Checked the plot status 
	in 2018 for these plots and found that 42 of these plots were used in 2018.
	Thus, recoding those as 4 "Mortgaged in/ Rented plot has been released". As the 
	options are adjacent to each other, the enumerator probably made a mistake here
	while selecting*/
	
	recode b1plot_status 5 = 4 if b1plotsize_decimal == 0 & b1plot_status == 5
	
	/* There are 3 plots that are acquired through Rented/shared/leased/Mortgaged–in
	but coded as new inheritance. This should be a mistake in trerms of entry,
	recoding it as new mortgage */
	
	recode b1plot_status 8 = 9 if b1plot_acquired == 6
	
	/*The rent paid for a 26 decimal plot is 60000 which seems unlikely, recoding
	it to missing.*/
	
	recode b1_ope_rent_paid 60000 = .
	
	/* There are two leased out/rented out plots for which the rents received
	is 10,000 but the size is only 7 and 10 decimals which are too low to warrant
	such a high rent, recoding the rent to missing. */
	
	recode b1_ope_rent_received 10000 = . if (b1plotsize_decimal == 7 | ///
	b1plotsize_decimal == 10)


	/*Recoding plots with high sizes in areas planted question (b2area)
	because their current plot size and land utilization plot size is 
	significantly lower meaning the b2area is likely a mistaken figure*/
	
	g b2diff_1 = b2area - b1_boro24_size
	
	g b2diff_2 = b2area - b1_aman_size
	
	g b2diff_3 = b2area - b1_aus_size
	
	g b2diff_4 = b2area - b1_boro23_size
	/*
	Displaying the observations I want to recode 
	
	br if b2diff_1 <= -50 | b2diff_2 <= -50 | b2diff_3 <= -50 | b2diff_4 <= -50 | ///
	(b2diff_1 >= 50 & !mi(b2diff_1)) | (b2diff_2 >= 50 & !mi(b2diff_2)) ///
	| (b2diff_3 >= 50 & !mi(b2diff_3)) | (b2diff_4 >= 50 & !mi(b2diff_4))
	*/
	recode b2area 200 = 16.5 if b1_boro24_size == 16.5 & a1hhid_combined == "1579"
	
	recode b2area 240 = 6 if b1_boro24_size == 6 & a1hhid_combined == "4759"
	
	recode b2area 240 = 12 if b1_boro24_size == 12 & a1hhid_combined == "3489"
	
	recode b2area 280 = 30 if b1_boro24_size == 30 & a1hhid_combined == "1431"
	
	recode b2area 230 = 320 if b1_boro24_size == 320 & a1hhid_combined == "4965.1"
	
	recode b2area 280 = 18 if b1_boro24_size == 18 & a1hhid_combined == "677.1"
	
	recode b2area 280 = 16 if b1_boro24_size == 16 & a1hhid_combined == "2531"
	
	recode b2area 300 = 54 if b1_boro24_size == 54 & a1hhid_combined == "4293"
	
	recode b2area 330 = 40 if b1_boro24_size == 40 & a1hhid_combined == "708"

	recode b2area 330 = 20 if b1_boro24_size == 20 & a1hhid_combined == "708"
	
	recode b2area 340 = 33 if b1_boro24_size == 33 & a1hhid_combined == "4245"
	
	recode b2area 360 = 9 if b1_boro24_size == 9 & a1hhid_combined == "1007.1.1"
	
	recode b2area 380 = 22 if b1_boro24_size == 22 & a1hhid_combined == "1980"
	
	recode b2area 400 = 40 if b1_boro24_size == 40 & a1hhid_combined == "853"
	
	recode b2area 400 = 10 if b1_boro24_size == 10 & a1hhid_combined == "3290"
	
	recode b2area 420 = 10 if b1_boro24_size == 10 & a1hhid_combined == "2405"
	
	recode b2area 480 = 22 if b1_boro24_size == 22 & a1hhid_combined == "2094"
	
	recode b2area 480 = 30 if b1_boro24_size == 30 & a1hhid_combined == "526.1"
	
	recode b2area 480 = 16.5 if b1_boro24_size == 16.5 & a1hhid_combined == "3463"
	
	recode b2area 600 = 30 if b1_boro24_size == 30 & a1hhid_combined == "1076"
	
	recode b2area 600 = 25 if b1_boro24_size == 25 & a1hhid_combined == "3852"
	
	recode b2area 600 = 10 if b1_boro24_size == 10 & a1hhid_combined == "1408.1"
	
	recode b2area 600 = 11 if b1_boro24_size == 11 & a1hhid_combined == "495.2"	
	
	recode b2area 600 = 15 if b1_boro24_size == 15 & a1hhid_combined == "1269"	
	
	recode b2area 800 = 40 if b1_boro24_size == 40 & a1hhid_combined == "1393.1"
	
	recode b2area 1000 = 33 if b1_boro24_size == 33 & a1hhid_combined == "1250"
	
	recode b1_boro23_size 50000 = 30 if b1_boro24_size == 30 & a1hhid_combined == "5091.1"
	
	recode b2area 1360 = 30 if b1_boro24_size == 30 & a1hhid_combined == "5091.1"
	
	recode b2area 1440 = 23 if b1_boro24_size == 23 & a1hhid_combined == "877"
	
	recode b2area 1600 = 9 if b1_boro24_size == 9 & a1hhid_combined == "3666"
	
	recode b2area 18 = 4 if b1_boro24_size == 4 & a1hhid_combined == "4451"
	
	recode b2area 20 = 3.3 if b1_boro24_size == 3.3 & a1hhid_combined == "4194"
	
	recode b2area 22 = 7 if b1_boro24_size == 7 & a1hhid_combined == "3118.11"
	
	recode b2area 24 = 13 if b1_boro24_size == 13 & a1hhid_combined == "1696"
	
	recode b2area 25 = 1 if b1_boro24_size == 1 & a1hhid_combined == "634"
	
	recode b2area 25 = 15 if b1_boro24_size == 15 & a1hhid_combined == "4806"
	
	recode b2area 25 = 10 if b1_boro24_size == 10 & a1hhid_combined == "3463"
	
	recode b2area 27 = 16 if b1_boro24_size == 16 & a1hhid_combined == "480"
	
	recode b2area 28 = 18 if b1_boro24_size == 18 & a1hhid_combined == "1199"
	
	recode b2area 28 = 14 if b1_boro24_size == 14 & a1hhid_combined == "2969"
	
	recode b2area 28 = 6 if b1_boro23_size == 6 & a1hhid_combined == "3550"
	
	recode b2area 30 = 10 if b1_boro24_size == 10 & a1hhid_combined == "1290"
	
	recode b2area 30 = 18 if b1_boro24_size == 18 & a1hhid_combined == "681"
	
	recode b2area 30 = 10 if b1_boro24_size == 10 & a1hhid_combined == "4825"
	
	recode b2area 30 = 15 if b1_boro24_size == 15 & a1hhid_combined == "3391"
	
	recode b2area 30 = 3.5 if b1_boro23_size == 3.5 & a1hhid_combined == "3550"
	
	recode b2area 30 = 13 if b1_boro23_size == 13 & a1hhid_combined == "4825"
	
	recode b2area 30 = 20 if b1_boro24_size == 20 & a1hhid_combined == "2260.2"
	
	recode b2area 30 = 10 if b1_boro23_size == 10 & a1hhid_combined == "1092"
	
	recode b2area 30 = 18 if b1_boro24_size == 18 & a1hhid_combined == "910"
	
	recode b1_boro24_size .15 = 15 if a1hhid_combined == "4886" & b2area == 15
	
	recode b2area 16 = 0.5 if b1_boro24_size == 0.5 & a1hhid_combined == "2341.1"
	
	
	recode b1_aman_size .18 = 18 if a1hhid_combined == "1828" & b2area == 18
	
	recode b2area 30 = 15 if b1_boro24_size == 0.5 & a1hhid_combined == "4825"
	
	recode b2area 33 = 15 if b1_boro24_size == 15 & a1hhid_combined == "3480"

	recode b2area 35 = 10 if b1_boro24_size == 10 & a1hhid_combined == "3551"
	
	recode b2area 35 = 14 if b1_boro24_size == 14 & a1hhid_combined == "3499"
	
	recode b2area 35 = 3 if b1_boro24_size == 3 & a1hhid_combined == "3480"
	
	recode b2area 35 = 10 if b1_boro24_size == 10 & a1hhid_combined == "2496"
	
	recode b2area 40 = 20 if b1_boro24_size == 20 & a1hhid_combined == "1124"
	
	recode b2area 40 = 18 if b1_boro24_size == 18 & a1hhid_combined == "1965"
	
	recode b2area 40 = 1 if b1_boro24_size == 1 & a1hhid_combined == "535.1"
	
	recode b2area 40 = 16 if b1_boro24_size == 16 & a1hhid_combined == "1247"
	
	recode b2area 40 = 7 if b1_boro24_size == 7 & a1hhid_combined == "4576"
	
	recode b2area 40 = 20 if b1_boro24_size == 20 & a1hhid_combined == "4566"
	
	recode b2area 40 = 7 if b1_boro24_size == 7 & a1hhid_combined == "4581"
	
	recode b2area 40 = 10 if b1_boro24_size == 10 & a1hhid_combined == "2712"
	
	recode b2area 40 = 20 if b1_boro24_size == 20 & a1hhid_combined == "4606"
	
	recode b2area 40 = 26 if b1_boro24_size == 26 & a1hhid_combined == "4460"
	
	recode b2area 40 = 20 if b1_boro24_size == 20 & a1hhid_combined == "1207"
	
	recode b2area 40 = 5 if b1_boro24_size == 5 & a1hhid_combined == "3550"
	
	recode b2area 40 = 20 if b1_boro24_size == 20 & a1hhid_combined == "3310"
	
	recode b2area 45 = 13 if b1_boro24_size == 13 & a1hhid_combined == "3778"
	
	recode b2area 45 = 6 if b1_boro24_size == 6 & a1hhid_combined == "3640"
	
	recode b2area 45 = 13 if b1_boro24_size == 13 & a1hhid_combined == "1694"
	
	recode b2area 45 = 7.5 if b1_boro24_size == 7.5 & a1hhid_combined == "3550"
	
	recode b2area 45 = 8 if b1_boro24_size == 8 & a1hhid_combined == "3830"
	
	recode b2area 50 = 26 if b1_boro24_size == 26 & a1hhid_combined == "3837"
	
	recode b2area 50 = 20 if b1_boro24_size == 20 & a1hhid_combined == "868"
	
	recode b2area 50 = 20 if b1_boro24_size == 20 & a1hhid_combined == "3010"
	
	recode b2area 60 = 30 if b1_boro24_size == 30 & a1hhid_combined == "3129"
	
	recode b2area 60 = 15 if b1_aman_size == 15 & a1hhid_combined == "3068"
	
	recode b2area 60 = 27 if b1_boro24_size == 27 & a1hhid_combined == "1723"
	
	recode b2area 60 = 50 if b1_aman_size == 50 & a1hhid_combined == "791"
	
	recode b2area 60 = 30 if b1_aman_size == 30 & a1hhid_combined == "3035.2"
	
	recode b2area 60 = 32 if b1_boro24_size == 32 & a1hhid_combined == "3401"
	
	recode b2area 60 = 24 if b1_boro24_size == 24 & a1hhid_combined == "2531"
	
	recode b2area 60 = 15 if b1_boro24_size == 15 & a1hhid_combined == "681"
	
	recode b2area 65 = 30 if b1_boro24_size == 30 & a1hhid_combined == "4900"
	
	recode b2area 75 = 4 if b1_boro24_size == 4 & a1hhid_combined == "4416"
	
	recode b2area 75 = 32 if b1_boro24_size == 32 & a1hhid_combined == "1718"
	
	recode b2area 80 = 12 if b1_boro24_size == 12 & a1hhid_combined == "4227.1"
	
	recode b2area 90 = 5 if b1_boro24_size == 5 & a1hhid_combined == "610"
	
	recode b2area 99 = 66 if b1_boro24_size == 66 & a1hhid_combined == "1247"
	
	recode b2area 100 = 4 if b1_boro24_size == 4 & a1hhid_combined == "761.2"
	
	recode b2area 100 = 20 if b1_boro24_size == 20 & a1hhid_combined == "1311"

	recode b2area 110 = 22 if b1_boro24_size == 22 & a1hhid_combined == "4358"
	
	recode b2area 120 = 38 if b1_boro24_size == 38 & a1hhid_combined == "1143.1"
	
	recode b2area 120 = 12 if b1_boro24_size == 12 & a1hhid_combined == "204"
	
	recode b2area 120 = 20 if b1_boro24_size == 20 & a1hhid_combined == "708"
	
	recode b2area 120 = 13 if b1_boro24_size == 13 & a1hhid_combined == "3348"
	
	recode b2area 120 = 24 if b1_boro24_size == 24 & a1hhid_combined == "4578"
	
	recode b2area 120 = 40 if b1_boro24_size == 40 & a1hhid_combined == "708"
	
	recode b2area 125 = 37 if b1_boro24_size == 37 & a1hhid_combined == "3476"
	
	recode b2area 150 = 10 if b1_boro24_size == 10 & a1hhid_combined == "706"
	
	recode b2area 160 = 26 if b1_boro24_size == 26 & a1hhid_combined == "1691"
	
	** Outlier correction based on replies from DATA (data firm)
	
	recode b2boroseedbed_dur 4 = 39 if a1hhid_combined == "1200" & b2crop_season == 1 & b2crop == 10
	
	recode b2boroseedbed_dur 1 = 36 if a1hhid_combined == "2053" & b2crop_season == 1 & b2crop == 11
	
	recode b2boroseedbed_dur 2 = 28 if a1hhid_combined == "5159" & b2crop_season == 1 & b2crop == 10
	
	recode b2boroseedbed_dur 7 = 30 if a1hhid_combined == "3118.11" & b2crop_season == 1 & b2crop == 10
	
	recode b2paddy_seedprice 4000 = 400 if a1hhid_combined == "2495" & b2crop_season == 1 & b2crop == 10
	
	recode b2paddy_seedprice 6000 = 80 if a1hhid_combined == "3463" & b2crop_season == 1 & b2crop == 10
	
	recode b2paddy_seedprice 6000 = 80 if a1hhid_combined == "3463" & b2crop_season == 1 & b2crop == 10
	
	recode b2paddy_seedprice 6000 = 80 if a1hhid_combined == "3463" & b2crop_season == 4 & b2crop == 10
	
	recode b2paddy_seedprice 5000 = 80 if a1hhid_combined == "3463" & b2crop_season == 4 & b2crop == 10
	
	recode b2paddy_seedprice 60000 = 80 if a1hhid_combined == "3463" & b2crop_season == 1 & b2crop == 10
	
	recode b2paddy_seedprice 6000 = 60 if a1hhid_combined == "3463" & b2crop_season == 2 & b2crop == 7
	
	recode b2paddy_seedprice 1000/10000000 = .
	
	** harvest cleaning
	
	egen b3plot_harvest_qty = rowtotal(b3qty_harvest b3int_qty_harvest)
	
	g b2area_hectare = b2area*0.004046483
	
	order b2area_hectare, after(b2area)
	
	g b3plot_harvest_ton = b3plot_harvest_qty/907.18474
	
	g b3yield_hectare = b3plot_harvest_ton/b2area_hectare
	
	la var b3yield_hectare "Yield (Ton/Hectare)"
	
	la var b2area_hectare "Area (hectare)"
	
	la var b3plot_harvest_ton "Total harvest on the plot (tons)"
	
	la var b3plot_harvest_qty "Total harvest on the plot (kg)"
		
	
	recode b3qty_harvest 0.000001/100000000 = . if b3yield_hectare > 20 & !mi(b2paddy_variety)
	
	recode b3int_qty_harvest 0.000001/100000000 = . if b3yield_hectare > 20 & !mi(b2paddy_variety)
	
	recode b3plot_harvest_ton 0.000001/100000000 = . if b3yield_hectare > 20 & !mi(b2paddy_variety)
	
	recode b3plot_harvest_qty 0.000001/100000000 = . if b3yield_hectare > 20 & !mi(b2paddy_variety)
	
	recode b3yield_hectare 0.000001/100000000 = . if b3yield_hectare > 20 & !mi(b2paddy_variety)
	
	
	
	
	
	
	
	
	preserve
	
	/*For hhs that have exited agriculture and currently has profit/income from
	agriculture, recoding the operational status for lands which are own operated
	given they do not have any lands operated by them in the crop production
	module*/
	collapse(max) agri_control_household (first) hhweight* a01* a1split_hh_serial a1split_hh a1district a1division districtname divisionname, by(a1hhid_combined)
	
	tempfile exit2024
	save `exit2024', replace
	
		
	use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
	

	g agri_control_household_18	= cond(h1_sl == 99, 0, 1)
	

	collapse (max) agri_control_household_18, by(a01)
		
	tostring a01, replace
	ren a01 a01combined_18
	
	merge 1:m a01combined_18 using `exit2024', nogen keep(3)
	
	
	
	g agri_exit = 1 if agri_control_household == 0 & agri_control_household_18 == 1
	recode agri_exit . = 0 if agri_control_household == 1 & agri_control_household_18 == 1
	
	keep if agri_exit == 1 
	
	tempfile exit_hh
	save `exit_hh', replace
	
	u "${final_data}${slash}SPIA_BIHS_2024_module_a2_4.dta", clear
	
	collapse (first) a4earning_source*, by(a1hhid_combined)
	
	merge 1:1 a1hhid_combined using `exit_hh', nogen keep(3)
	
    g freq = (a4earning_source1 == 70) | (a4earning_source2 == 70)
	
	tempfile exit_earning
	save `exit_earning', replace
	
	restore
	
	
	
	
	merge m:1 a1hhid_combined using `exit_earning', nogen keepusing(freq)
	

	
	recode b1_operation_status 1 = 15 if freq == 1 & b1plot_type != 8 & b1_boro24_utilize == 6
	recode b1_operation_status 2 = . if freq == 1 & b1plot_type != 8
	recode b1_operation_status 4 = . if freq == 1 & b1plot_type != 8
	recode b1_operation_status 6 = . if freq == 1 & b1plot_type != 8
	recode b1_operation_status 12 = . if freq == 1 & b1plot_type != 8
	
	drop freq
	
	/*Enumerator comments stated that they mistakenly provided agriculture
	production data for HH 122 and 318 Aman season. Cleaning that portion*/
	
	preserve 
	
	keep if a1hhid_combined ==  "122"
	
	drop b2crop_name b2intercrop_name b2other_variety b2paddyvariety b4machine_name* ///
	b2paddyintercropvariety b4landname_size b4season_name b4crop_name b4machine_type* ///
	b5landname_size b5season_name b5crop_name *_oth b5powersource b5irrigation_pay_label ///
	b5causeshortage b5weed_control b2potatovariety b2swpotatovariety b2maizevariety ///
	b2wheatvariety b2lentilvariety b2chickpeavariety b2peanutvariety  b2other_intervariety ///
	b5reasonmotor b5reason_nopipe b5reirrigate_decide
	
	local varnames b1cropping_decision b1plot_fishing b1soil_type b1plot_distance ///
	b1plot_duration b1flood_depth b1_operation_status b1_ope_rent_paid b1_ope_rent_received ///
	b1_boro24_utilize b1_aman_utilize b1_boro24_size b1_aman_utilize b1_aus_utilize ///
	b1_aus_size b1_boro23_utilize b1_boro23_size b2land_index b2crop_season b2split_land b2split_serial b2crop ///
	b2paddy_yes b2any_intercrop b2intercrop b2paddy_variety b2paddy_varietytype ///
	b2paddy_sapling b2paddy_seedprice b2boroseedbed_dur b2boro_plot_dur b2potato_variety ///
	 b2swpotato_variety b2maize_variety b2wheat_variety  b2lentil_variety b2chickpea_variety ///
	 b2peanut_variety b2crop_varietytype b2area b2plantdate b2plantweek b2harvestdate b2harvestweek ///
	b2paddy_intercrop_variety b2paddy_intercrop_seedprice b2paddy_intercroptype ///
	b2potato_inter_variety b2swpotato_inter_variety b2maize_intervariety ///
	b2wheat_intervariety b2lentil_intervariety b2chickpea_intervariety ///
	b2peanut_intervariety b2crop_intertype ///
	b2plantdate_intercrop b2plantweek_intercrop b2harvestdate_intercrop ///
	b2harvestweek_intercrop b2area_hectare b3qty_harvest b3qty_paid_owner ///
	b3qty_paid_irrigation b3qty_paid_rent b3qty_net_harvest b3int_qty_harvest ///
	b3int_qty_paid_owner b3int_qty_paid_irrigation b3int_qty_paid_rent ///
	b3int_qty_net_harvest b3plot_harvest_qty b3plot_harvest_ton b3yield_hectare ///
	b4machine_rent1 b4machine_rent2 b4machine_rent3 b4machine_rent4 b4plottype ///
	b4soiltype b4plot_size b4split_serial b4area b4use_animal b4bullock_days b4animal_cost ///
	b4use_machine b4machine_repeat_count b4use_machine_plant b4machineplant_cost ///
	b4use_mach_fertilizer b4mach_fertilizer_cost b4use_mach_pesticide b4mach_pesticide_cost ///
	b4use_machine_weed b4mach_weed_cost b4use_mach_harvest b4mach_harvest_cost ///
	b5dry_how1 b5dry_how2 b5dry_how3 b5dry_how4 b5dry_how5 b5dry_how6 b5dry_how7 ///
	b5dry_how8 b5dry_how9 b5dry_how10 b5dry_how11 b5dry_how12 b5dry_how13 b5dry_how14 ///
	b5dry_how15 b5dry_how16 b5dry_how17 b5dry_how18 b5dry_how19 b5dry_how20 b5dry_how21 ///
	b5dry_how22 b5plottype b5soiltype b5plot_size b5split_serial b5area b5mainwater_source ///
	b5alter_water_source b5ground_source b5reason_motor b5pump_type b5pump_owned ///
	b5power_source b5n_irrigation_boro b5irrigation_duration b5depth_irrigation b5additional_pipe ///
	b5distance_pump b5irrigation_pay_unit b5water_price b5tot_water_cost b5relative_height ///
	b5p3years_shortage b5cause_shortage b5awd_use b5awd_curr_season b5awd_know ///
	b5awd_duration b5water_management b5duration_1stdrying b5duration_dry b5dry_state ///
	b5ndry_this_season b5dry_repeat_count b5dry_assess b5dry_assess_cm ///
	b5reirrigate_decide_1 b5reirrigate_decide_6 b5reirrigate_decide_3 b5reirrigate_decide_4 ///
	b5reirrigate_decide_5 b5reirrigate_decide_2 b5reirrigate_decide_label b5sell_water_vill ///
	b5water_committee b5plant_method b5distance_seedling b5distance_row b5use_insecticide ///
	b5weed_control_1 b5weed_control_2 b5weed_control_3 b5weed_control_4 b5weed_control_5 b5weed_control__96



	
	recode b1agri_activities 1 = 0
	
	foreach var of local varnames {
		
		recode `var' 0/1000000000 = .
	}
	
	
	tempfile hh_122
	save `hh_122', replace
	
	restore 
	
	drop if a1hhid_combined ==  "318" & b2crop_season == 2
	
	drop if a1hhid_combined ==  "122"
	
	append using `hh_122'
	
	//egen:  a1hhid_plotnum = concat(a1hhid_combined b1plot_num), p(.)
	
	order a1hhid_plotnum, after(b1plot_num)
	
	
	
	** Labelling variables
	
	la var a01combined_18 "Household ID for BIHS 2018"
	
	la var b1plot_num "Serial of the plot"
	
	la var b1market_value "Current market value of the plot per decimal"
	
	la var b1n_plot_2018_clean "Num of plots owned/under operation in 2018"
	
	la var b1plot_left_2018 "Num of plots that HH released/sold/bestowed in 2018"
	
	la var b1repeat_count "Number of plots where HH farms"
	
	la var b1fishing_count "Number of ponds/plots where HH practics aquaculture"
	
	la var b1plotsize_decimal "Size of land currently owned or operated (decimals)"
	
	la var b1cropping_decision "HH member take agricultural/aquaculture decisions for this plot (past 4 seasons)"
	
	la var b1plot_fishing "Aquaculture done on this plot in the past 4 seasons"
	
	la var a1hhid_plotnum "Unique plot number combining HHID and plot number"
	
	la var b1_ope_rent_paid "Amount paid per month for rented/leased in plots"
	
	la var b1_ope_rent_received "Amount received per month for rented/leased out plots"
	
	la var b2land_index "Repeat index for module B2"
	
	la var b2crop_season "Cultivation season"
	
	la var b2crop "Crop name"
	
	la var b1plot_roster_count_clean "Number of plots owned/under operation in 2024"
	
	order b1plot_left_2018 b1plot_roster_count_clean b1n_plot_2018_clean, after(b1repeat_count)
	
	order b3plot_harvest_qty b3plot_harvest_ton b3yield_hectare, after(b3int_qty_net_harvest)
	
	**# Cleaning module B2
	
	/* Now, we get the indication if lands are split for farming from b2split_land
	variable. I am going to make a new variable to signify unique land ID for
	Module B2 with: B1 plot number + Season Number + Serial of the split/0 if the
	land is not split*/
	
	preserve
	
	drop if mi(b2crop_season)
	
	drop b2split_serial
	
	egen b1hhid_plot_season = concat(a1hhid_plotnum b2crop_season), p(.)
	
	egen b1plot_season = concat(b1plot_num b2crop_season), p(.)
	
	bys b1hhid_plot_season: g b2split_serial = _n if b2split_land == 1
	
	recode b2split_serial . = 0
	
	
	egen b2land_serial = concat(b1plot_season b2split_serial), p(.)
	
	la var b2land_serial "Land sl. with plot no., season, split serial (0 if not split)"
	
	la var b2split_serial "Serial of the split for split lands"
	
	drop b1hhid_plot_season b1plot_season
	
	
	
	tempfile b2edit
	save `b2edit', replace
	
	restore
	
	keep if mi(b2crop_season)
	
	append using `b2edit'
	
	order b2split_serial b2land_serial, after(b2split_land)
	
	
	// recoding crop names 
	
	recode b2crop -86 = 39 if b2crop_name == "Badam |  Badam"
	recode b2crop -86 = 142 if b2crop_name == "Chopa ghas |  Chopa ghas"
	recode b2crop -86 = 142 if b2crop_name == "Ghaskhet |  Ghaskhet"
	recode b2crop -86 = 142 if b2crop_name == "Japani pang chuing ghas |  Japani pang chuing ghas"
	recode b2crop -86 = 142 if b2crop_name == "Nepier |  Nepier"
	recode b2crop -86 = 142 if b2crop_name == "Nipier |  Nipier"
	
	
	
	
	recode b2crop -86/-79 = 143 if regex(b2crop_name, "Pat")
	
	
	
	recode b2crop -86/-79 = 142 if regex(b2crop_name, "gas") | regex(b2crop_name, "Gas") | ///
	regex(b2crop_name, "ghas") | regex(b2crop_name, "gash") | regex(b2crop_name, "Ghas") | regex(b2crop_name, "Gash") | ///
	regex(b2crop_name, "Ghsh") | regex(b2crop_name, "ঘাস ")  | regex(b2crop_name, "ges") | regex(b2crop_name, "Napeir")
	
	recode b2crop -86/-79 = 119 if regex(b2crop_name, "Alo")
	
	recode b2crop -86/-79 = 27 if regex(b2crop_name, "Dal") | regex(b2crop_name, "dul") 
	
	recode b2crop -86/-79 = 1 if regex(b2crop_name, "Dhan")  
	
	recode b2crop -86/-79 = 39 if regex(b2crop_name, "Badam")  

	
	
	
	recode b2crop -86/-1 = 144
	
	replace b2crop_name = "" if b2crop != 144
	
	split b2crop_name, p(|)
	
	drop b2crop_name2
	
	ren b2crop_name1 b2crop_name_oth
	
	la var b2crop_name_oth "Other crop name (specify)"
	
	order b2crop_name_oth, after(b2crop)
	
	recode b2intercrop -86/-79 = 142 if regex(b2intercrop_name, "gas") |  regex(b2intercrop_name, "Gas")
	
	recode b2intercrop -86/-1 = 144
	
	replace b2intercrop_name = "" if b2intercrop != 144
	
	split b2intercrop_name, p(|)
	
	drop b2intercrop_name2
	
	ren b2intercrop_name1 b2intercrop_name_oth
	
	la var b2intercrop_name_oth "Other intercrop name (specify)"
	
	order b2intercrop_name_oth, after(b2intercrop)
	
	
	
	//Cleaning Boro paddy variety
	
	
	split b2paddyvariety, p(|) 
	
	drop b2paddyvariety2 b2paddyvariety
	ren b2paddyvariety1 b2paddyvariety
	
	recode b2paddy_variety -86/-83=180 if b2paddyvariety=="Banghobondhu" | b2paddyvariety=="Bangabondu" ///
	| b2paddyvariety=="Bangibondhu 100" | b2paddyvariety=="Bangabandhu" | b2paddyvariety=="Bangabondhu" ///
	| b2paddyvariety=="Bangobando 100" | b2paddyvariety=="Boggobondu" | b2paddyvariety=="Bonggo bondhu" ///
	| b2paddyvariety=="Bonggobondhu" | b2paddyvariety=="Bongo bondhu dhan" | b2paddyvariety=="Bongo bondhu" ///
	| b2paddyvariety=="Bongobandhu" | b2paddyvariety=="Bongobondhu 100" | b2paddyvariety=="Bongobondhu 100" ///
	|b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondu" | b2paddyvariety=="bongobondhu 100"

	recode b2paddy_variety -85/-83=180 if b2paddyvariety=="Bonggobondhu" | b2paddyvariety=="Bongobando" ///
	| b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondhu 100" | b2paddyvariety=="Bangobondhu" | b2paddyvariety=="bongobondhu 100" ///
	| b2paddyvariety=="Banghobondhu" | b2paddyvariety=="Bangabondu" ///
	| b2paddyvariety=="Bangibondhu 100" | b2paddyvariety=="Bangabandhu" | b2paddyvariety=="Bangabondhu" ///
	| b2paddyvariety=="Bangobando 100" | b2paddyvariety=="Boggobondu" | b2paddyvariety=="Bonggo bondhu" ///
	| b2paddyvariety=="Bonggobondhu" | b2paddyvariety=="Bongo bondhu dhan" | b2paddyvariety=="Bongo bondhu" ///
	| b2paddyvariety=="Bongobandhu" | b2paddyvariety=="Bongobondhu 100" | b2paddyvariety=="Bongobondhu 100" ///
	|b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondu" | b2paddyvariety=="bongobondhu 100"
	
	recode b2paddy_variety -84/-83=180 if b2paddyvariety=="Bonggobondhu" | b2paddyvariety=="Bonggobondu" ///
	| b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondo" | b2paddyvariety=="Boro 303, bongobonbu" | b2paddyvariety=="bongobondhu 100" ///
	| b2paddyvariety=="Banghobondhu" | b2paddyvariety=="Bangabondu" ///
	| b2paddyvariety=="Bangibondhu 100" | b2paddyvariety=="Bangabandhu" | b2paddyvariety=="Bangabondhu" ///
	| b2paddyvariety=="Bangobando 100" | b2paddyvariety=="Boggobondu" | b2paddyvariety=="Bonggo bondhu" ///
	| b2paddyvariety=="Bonggobondhu" | b2paddyvariety=="Bongo bondhu dhan" | b2paddyvariety=="Bongo bondhu" ///
	| b2paddyvariety=="Bongobandhu" | b2paddyvariety=="Bongobondhu 100" | b2paddyvariety=="Bongobondhu 100" ///
	|b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondhu" | b2paddyvariety=="Bongobondu" | b2paddyvariety=="bongobondhu 100"
	
	
	
	
	recode b2paddy_variety -86/-83=181 if b2paddyvariety=="Boro dhan jira" | b2paddyvariety=="Jira" | ///
	b2paddyvariety=="Jira (khato)" | b2paddyvariety=="Jira 34" | b2paddyvariety=="Jira Dhan" | ///
	b2paddyvariety=="Jira dhan" | b2paddyvariety=="Jira katari" | b2paddyvariety=="Jira sail" | ///
	b2paddyvariety=="Jira shahi" | b2paddyvariety=="Jira shail" | b2paddyvariety=="Jira14" | ///
	b2paddyvariety=="Jira34" | b2paddyvariety=="Jira52" | b2paddyvariety=="Jirashail" | ///
	b2paddyvariety=="Kato jira" | b2paddyvariety=="Kato jirasail boro" | b2paddyvariety=="Kato jirasail boro" | ///
	b2paddyvariety=="Katojira boro" | b2paddyvariety=="Katojira sail" | b2paddyvariety=="Khato Jira" | ///
	b2paddyvariety=="Rashian jira" | b2paddyvariety=="jeera" | b2paddyvariety=="jira" | b2paddyvariety=="jira dhan" | ///
	b2paddyvariety=="jiradan" | b2paddyvariety=="90 Jira" | b2paddyvariety=="Khato jira" | b2paddyvariety=="Lomba jhira" ///
	| b2paddyvariety=="Zira" | b2paddyvariety=="Jarashal dhan"
	
	

	
	recode b2paddy_variety -86/-83=181 if b2paddyvariety=="Jira" | b2paddyvariety=="Jira dhan" | ///
	a1hhid_combined=="425" | b2paddyvariety=="Jira master" | b2paddyvariety=="Jira34" | ///
	b2paddyvariety=="Jirashail" | b2paddyvariety=="Kalojira" | b2paddyvariety=="Khato jira" | ///
	b2paddyvariety=="Lomba jira" | b2paddyvariety=="Shahi jira" | b2paddyvariety=="Jeera"
	
	recode b2paddy_variety -86/-83=181 if b2paddyvariety=="Jira" | b2paddyvariety=="Jira90" | ///
	b2paddyvariety=="Jirasahi" | b2paddyvariety=="Lomba jira"
	
	
	recode b2paddy_variety -86/-83=116 if b2paddyvariety=="Aman sorna" | b2paddyvariety=="Amon  Sorna 5" | ///
	a1hhid_combined=="425" | b2paddyvariety=="Amon Dhan Sorna 5" | b2paddyvariety=="Amon Khato Sorna" | ///
	b2paddyvariety=="Amon Sorna 5" | b2paddyvariety=="Amon gotisorna" | b2paddyvariety=="Giuti sorna" | ///
	b2paddyvariety=="Ghotisarna" | b2paddyvariety=="Goti Sorna dan" | b2paddyvariety=="Goti Sorno" | ///
	b2paddyvariety=="Guti Sorna" | b2paddyvariety=="Guti atop sorna" | b2paddyvariety=="Guti shorno" | ///
	b2paddyvariety=="Guti sonna" | b2paddyvariety=="Guti sorna" | b2paddyvariety=="Guti sorno" | ///
	b2paddyvariety=="Guti surna" | b2paddyvariety=="Mota sorna" | b2paddyvariety=="Nepaly sorna" | ///
	b2paddyvariety=="Sada guti sorna dhan" | b2paddyvariety=="Sorna" | b2paddyvariety=="Sorna 5" | ///
	b2paddyvariety=="Sorna 5 Amon" | b2paddyvariety=="Sorna dan" | b2paddyvariety=="Sorna dhan" | ///
	b2paddyvariety=="Sorna- 5" | b2paddyvariety=="Sorna-5" | b2paddyvariety=="Sorna5" ///
	| b2paddyvariety=="Sorna_5" | b2paddyvariety=="Sorno 5" | b2paddyvariety=="Sorno 5" ///
	| b2paddyvariety=="Sornoguti" | b2paddyvariety=="Sornoo gote" | b2paddyvariety=="sorna" ///
	| b2paddyvariety=="গুটি স্বর্ণা" | b2paddyvariety=="স্বর্ন-৫" | b2paddyvariety=="Goti sorno" ///
	| b2paddyvariety=="Guti shorna" | b2paddyvariety=="Guti sonna" | b2paddyvariety=="Guti sorna" ///
	| b2paddyvariety=="Guti surna" | b2paddyvariety=="Khato sorna" | b2paddyvariety=="Goti sorna" ///
	| b2paddyvariety=="Shorna" | b2paddyvariety=="Shorno - 5" | b2paddyvariety=="Shorno -5" ///
	| b2paddyvariety=="Shorno 5" | b2paddyvariety=="Shorno five" | b2paddyvariety=="Surna" ///
	| b2paddyvariety=="Surna 5" | b2paddyvariety=="Deshisarna" | b2paddyvariety=="Ghotisarna" ///
	| b2paddyvariety=="Sonna" | b2paddyvariety=="Sonna 5" | b2paddyvariety=="Sonra-5" | ///
	b2paddyvariety=="Swarna pass" | b2paddyvariety=="sorno" | b2paddyvariety=="সরনা ৫"  | ///
	b2paddyvariety=="Amon  Sorna 5" | b2paddyvariety=="Amon Sorna 5" | b2paddyvariety=="Amon.Sorna 5" | ///
	b2paddyvariety=="Goti sorna" | b2paddyvariety=="Goti sorno" | b2paddyvariety=="Goti surna" | ///
	b2paddyvariety=="Goti surna" | b2paddyvariety=="Khato sorna" | b2paddyvariety=="Sada sorna" | ///
	b2paddyvariety=="Sada sorna dha" | b2paddyvariety=="Sorna" | b2paddyvariety=="Sorna 5" | ///
	b2paddyvariety=="Sorna 5 amon" | b2paddyvariety=="Sorna-5" | b2paddyvariety=="Sorna/ benikochi" | ///
	b2paddyvariety=="Sorno 5" | b2paddyvariety=="Guti shorna" | b2paddyvariety=="Guti sonna" | ///
	b2paddyvariety=="Guti sonna" | b2paddyvariety=="Guti sorna" | b2paddyvariety=="Guti surna" | ///
	b2paddyvariety=="Shorna-5" | b2paddyvariety=="Surna" | b2paddyvariety=="Surna 5" | ///
	| b2paddyvariety=="Ghotisarna" | b2paddyvariety=="Sonna" | b2paddyvariety=="Sonna 5" | ///
	b2paddyvariety=="Sonra-5" | b2paddyvariety=="Sorna 5" | b2paddyvariety=="Sorna mota" | b2paddyvariety=="Ghotisarna" ///
	| b2paddyvariety=="Sonna" | b2paddyvariety=="Sonna 5" | b2paddyvariety=="Sonra-5"
	
	
	
	
	recode b2paddy_variety -86/-83=116 if b2paddyvariety=="Swarna pass" | b2paddyvariety=="sorno" | b2paddyvariety=="সরনা ৫"  | ///
	b2paddyvariety=="Amon  Sorna 5" | b2paddyvariety=="Amon Sorna 5" | b2paddyvariety=="Amon.Sorna 5" | ///
	b2paddyvariety=="Goti sorna" | b2paddyvariety=="Goti sorno" | b2paddyvariety=="Goti surna" | ///
	b2paddyvariety=="Goti surna" | b2paddyvariety=="Khato sorna" | b2paddyvariety=="Sada sorna" | ///
	b2paddyvariety=="Sada sorna dha" | b2paddyvariety=="Sorna" | b2paddyvariety=="Sorna 5" | ///
	b2paddyvariety=="Sorna 5 amon" | b2paddyvariety=="Sorna-5" | b2paddyvariety=="Sorna/ benikochi" | ///
	b2paddyvariety=="Sorno 5" | b2paddyvariety=="Guti shorna" | b2paddyvariety=="Guti sonna" | ///
	b2paddyvariety=="Guti sonna" | b2paddyvariety=="Guti sorna" | b2paddyvariety=="Guti surna" | ///
	b2paddyvariety=="Shorna-5" | b2paddyvariety=="Surna" | b2paddyvariety=="Surna 5" | ///
	| b2paddyvariety=="Ghotisarna" | b2paddyvariety=="Sonna" | b2paddyvariety=="Sonna 5" | ///
	b2paddyvariety=="Sonra-5"
	
	recode b2paddy_variety -86/-83=116 if b2paddyvariety=="Sorna 5" | b2paddyvariety=="Sorna mota" | b2paddyvariety=="Ghotisarna" ///
	| b2paddyvariety=="Sonna" | b2paddyvariety=="Sonna 5" | b2paddyvariety=="Sonra-5"
	
	
	recode b2paddy_variety -86/-83=182 if b2paddyvariety=="Boro teg gold" | b2paddyvariety=="Taj gold"	| ///
	b2paddyvariety=="Tajgol" | b2paddyvariety=="Tej gold" | b2paddyvariety=="Tej gul" | b2paddyvariety=="Tejghol" | ///
	b2paddyvariety=="Tejgol" | b2paddyvariety=="Tejgold" | b2paddyvariety=="Tejgon" | ///
	b2paddyvariety=="Tejgor jath" | b2paddyvariety=="Tejgul" | b2paddyvariety=="Tejgul Hybrid" | ///
	b2paddyvariety=="Tez gul" | b2paddyvariety=="tejgol"
	
	recode b2paddy_variety -86/-83=183 if b2paddyvariety=="Amon Mamun Dhan" | b2paddyvariety=="Mamun" | ///
	b2paddyvariety=="Mamun dhan" | b2paddyvariety=="Mamun chikon"
	
	recode b2paddy_variety -86/-83=184 if b2paddyvariety=="Ronjit" | b2paddyvariety=="Ronjit Eri" | ///
	b2paddyvariety=="Ronjid" | b2paddyvariety=="Ronjiet" | b2paddyvariety=="Ranjit" | ///
	b2paddyvariety=="Amon Ronjit Dhan" | b2paddyvariety=="Amon Ronojit Dhan" | ///
	b2paddyvariety=="Amon Ronzit Dhan" | b2paddyvariety=="Ronjit Dhan" | ///
	b2paddyvariety=="Ronjit amon" | b2paddyvariety=="Rongit"
		
	recode b2paddy_variety -86/-83=144 if b2paddyvariety=="Bina 15"
	
	recode b2paddy_variety -86/-83=146 if b2paddyvariety=="Bina 17"
	
	recode b2paddy_variety -86/-83=185 if b2paddyvariety=="Boro Dhan Katari" | b2paddyvariety=="Boro Katari Dhan" | ///
	b2paddyvariety=="Katari" | b2paddyvariety=="Katari Dhan" | b2paddyvariety=="Kathari" | ///
	b2paddyvariety=="Khathari 34" | b2paddyvariety=="katari" | b2paddyvariety=="Jamai katari" | ///
	b2paddyvariety=="Katari bog" | b2paddyvariety=="Katari bok" | b2paddyvariety=="Katari vog" | ///
	b2paddyvariety=="Katari vog (bogurar dan)" | b2paddyvariety=="Katari vog," | b2paddyvariety=="Katari vogh" | ///
	b2paddyvariety=="Katarivog" | b2paddyvariety=="Kathari bog" | b2paddyvariety=="Katire Vog dan" | ///
	b2paddyvariety=="katari vog" | b2paddyvariety=="Katare boro" | b2paddyvariety=="Katari bog" | ///
	b2paddyvariety=="Katari bok" | b2paddyvariety=="Catarivog" | b2paddyvariety=="কাটারি"
	
		
	recode b2paddy_variety -86/-83=127 if b2paddyvariety=="Hira dhan" | b2paddyvariety=="Hira" | ///
	b2paddyvariety=="Hira 1"
	
	
	
	recode b2paddy_variety -86/-83=111 if b2paddyvariety=="Cui miniket" | b2paddyvariety=="Minicket" | ///
	b2paddyvariety=="Miniket" | b2paddyvariety=="Red miniket" | b2paddyvariety=="Rod Miniket" | ///
	b2paddyvariety=="Rod Minikit" | b2paddyvariety=="Rod miniket" | b2paddyvariety=="Rotminiket" | ///
	b2paddyvariety=="Rud Menikit"
	
	recode b2paddy_variety -86/-83=186 if b2paddyvariety=="Boro Dhan Hira 2" | b2paddyvariety=="Boro Hira 2" | ///
	b2paddyvariety=="Bro Dhan Hira 2" | b2paddyvariety=="Hira 2" | b2paddyvariety=="Hira-2" | ///
	b2paddyvariety=="Hira2" | b2paddyvariety=="Hera 2" | b2paddyvariety=="হিরা ২"
	
	recode b2paddy_variety -86/-83=187 if b2paddyvariety=="Boro Dhan Hira 6" | b2paddyvariety=="Hira6"
		
	recode b2paddy_variety -86/-83=188 if b2paddyvariety=="Hira 19" | b2paddyvariety=="Hira=19"
	
	recode b2paddy_variety -86/-83=189 if b2paddyvariety=="Danegola.amon" | b2paddyvariety=="Dani gold" | /// 
	b2paddyvariety=="Dani golden" | b2paddyvariety=="Danigol" | b2paddyvariety=="Danigold" | ///
	b2paddyvariety=="Danigoold" | b2paddyvariety=="Danigul" | b2paddyvariety=="Dhan Egal" | ///
	b2paddyvariety=="Dhan Egol" | b2paddyvariety=="Dhani Gold" | b2paddyvariety=="Dhani gol" | ///
	b2paddyvariety=="Dhani Gold, Amon" | b2paddyvariety=="Dhani ghul" | b2paddyvariety=="Dhani gold" | ///
	b2paddyvariety=="Dhani gul" | b2paddyvariety=="Dhani gur" | b2paddyvariety=="Dhanigol" | ///
	b2paddyvariety=="Dhanigold" | b2paddyvariety=="Dhanigool" | b2paddyvariety=="Dhanigul" | ///
	b2paddyvariety=="Dhanigur" | b2paddyvariety=="Dhanikul" | b2paddyvariety=="Dhanikul dhan" | ///
	b2paddyvariety=="Dhanikur" | b2paddyvariety=="Dhini Gold" | b2paddyvariety=="Dhnikur"
		
	recode b2paddy_variety -86/-83=112 if b2paddyvariety=="Faijam" | b2paddyvariety=="Paijam" | b2paddyvariety=="Payjam"
	
	recode b2paddy_variety -86/-83=190 if b2paddyvariety=="Jhono Raj" | b2paddyvariety=="Jonak Raj" | ///
	b2paddyvariety=="Jono crach" | b2paddyvariety=="Jono rag" | b2paddyvariety=="Jonocrash" | ///
	b2paddyvariety=="Jonok  Raj" | b2paddyvariety=="Jonok Raj" | b2paddyvariety=="Jonok raj" | ///
	b2paddyvariety=="Jonok raj," | b2paddyvariety=="Jonok raz" | b2paddyvariety=="Jonokraj" | ///
	b2paddyvariety=="Jonokrajl,National Agrecare 4" | b2paddyvariety=="Jonokraz" | ///
	b2paddyvariety=="Jonoraj" | b2paddyvariety=="jonok raj"
	
	recode b2paddy_variety -86/-83=191 if b2paddyvariety=="Shuvo lata" | b2paddyvariety=="Shuvo lata (boro)" | ///
	b2paddyvariety=="Shuvolota" | b2paddyvariety=="Sobol lota boro" | b2paddyvariety=="Sobor lota" | ///
	b2paddyvariety=="Sobur lota" | b2paddyvariety=="Sublota" | b2paddyvariety=="Subol lota" | ///
	b2paddyvariety=="Subol lota,uccho folonsil" | b2paddyvariety=="Subolota" | ///
	b2paddyvariety=="Subon lota" | b2paddyvariety=="Suvol lota" | ///
	b2paddyvariety=="Suvol lota( Boro)" | b2paddyvariety=="shuvo lata" | b2paddyvariety=="শুভলতা"
	
	
	recode b2paddy_variety -86/-83= 192 if regex(b2paddyvariety, "mota") | regex(b2paddyvariety, "Mota")
	
	recode b2paddy_variety -85/-83 = -86
	
	recode b2paddy_variety 180 = 99
	
	label define b2paddy_variety 1 "Chandina BR-1 (Boro/Aus)" ///
								2 "Mala BR-2 (Boro/Aus)" ///
								3 "Biplob BR-3 (Aus/Aman)" ///
								4 "Brishail BR-4* (Aman)" ///
								5 "Dulavhoge BR-5* (Aman)" ///
								6 "BR-6 (Boro/Aus)" ///
								7 "Bribalam BR-7 (Boro/Aus)"  ///
								8 "Asa BR-8 (Boro/Aus)" ///
								9 "Sufoza BR-9 (Boro/Aus)" ///
								10 "Progoti BR-10 (Aman)" ///
								11 "Mukta BR-11 (Aman)" ///
								12 "Moyna BR-12 (Boro/Aus)" ///
								13 "Gazi BR-14 (Boro/Aus)" ///
								14 "Mohini BR-15 (Boro/aus)" ///
								15 "Shahi Balam BR-16(Boro/Aus)" ///
								16 "Hasi BR-17 (Boro)" ///
								17 "Shahjalal BR-18 (Boro)" ///
								18 "Mongal BR-19 (Boro)" ///
								19 "Nizami BR-20 (Aus)"  ///
								20 "Niamat BR-21 (Aus)"  ///
								21 "Kiron BR-22* (Aman)"  ///
								22 "Dyshary BR-23 (Aman)"  ///
								23 "Rahmat BR-24 (Aus)" ///
								  24  "Noya Pajam BR-25 (Aman)" ///
								  25  "Sraboni BR-26 (Aus)" ///
								  26  "Bri Dhan BR-27 (Aus)" ///
								  27  "Bri Dhan BR-28 (Boro)" ///
								  28  "Bri Dhan BR-29 (Boro)" ///
								  29  "Bri Dhan BR-30 (Aman)" ///
								  30  "Bri Dhan BR-31 (Aman)" ///
								  31  "Bri Dhan BR-32 (Aman)" ///
								  32  "Bri Dhan BR-33 (Aman)" ///
								  33  "Bri Dhan BR-34 (Aman)" ///
								  34  "Bri Dhan BR-35 (Boro)" ///
								  35  "Bri Dhan BR-36 (Boro)" ///
								  36  "Bri Dhan BR-37 (Aman)" ///
								  37  "Bri Dhan BR-38 (Aman)" ///
								  38  "Bri Dhan BR-39 (Aman)" ///
								  39  "Bri Dhan BR-40 (Aman)" ///
								  40  "Bri Dhan BR-41 (Aman)" ///
								  41  "Bri Dhan BR-42 (Aus)" ///
								  42  "Bri Dhan BR-43 (Aus)" ///
								  43  "Bri Dhan BR-44 (Aman)" ///
								  44  "Bri Dhan BR-45 (Boro)" ///
								  45  "Bri Dhan BR-46 (Aman)" ///
								  46  "Bri Dhan BR-47 (Boro)" ///
								  47  "Bri Dhan BR-48 (Aus)" ///
								  48  "Bri Dhan BR-49 (Aman)" ///
								  49  "Bri Dhan BR-50 (Banglamoti) (Boro)" ///
								  50  "Bri Dhan BR-51 (Aman)" ///
								  51  "Bri Dhan BR-52 (Aman)" ///
								  52  "Bri Dhan BR-53 (Aman)" ///
								  53  "Bri Dhan BR-54 (Aman)" ///
								  54  "Bri Dhan BR-55 (Boro/Aus)" ///
								  55  "Bri Dhan BR-56 (Aman)" ///
								  56  "Bri Dhan BR-57 (Aman)" ///
								  57  "Bri Dhan BR-58 (Boro)" ///
								  58  "Bri Dhan BR-59 (Boro)" ///
								  59  "Bri Dhan BR-60 (Boro)" ///
								  60  "Bri Dhan BR-61 (Boro)" ///
								  61  "Bri Dhan BR-62 Zinc Enriched (Aman)" ///
								  62  "Bri Dhan BR-63 Shorubalam (Boro)" ///
								  63  "Bri Dhan BR-64 Zinc Enriched (Boro)" ///
								  64  "Bri Dhan BR-65 (Aus)" ///
								  65  "Bri Dhan BR-66 Drought Tolerant (Aman)" ///
								  66  "Bri Dhan BR-67 Saline Tolerant (Boro)" ///
								  67  "Bri Dhan BR-68 (Boro)" ///
								  68  "Bri Dhan BR-69 Weed Resistant (Boro)" ///
								  69  "Bri Dhan 70" ///
								  70  "Bri Dhan 71" ///
								  71  "Bri Dhan 72" ///
								  72  "Bri Dhan 73" ///
								  73  "Bri Dhan 74" ///
			  			 74  "Bri Dhan 75" ///
                         75  "Bri Dhan 76" ///
                         76  "Bri Dhan 77" ///
                         77  "Bri Dhan 78" ///
                         78  "Bri Dhan 79" ///
                         79  "Bri Dhan 80" ///
                         80  "Bri Dhan 81" ///
                         81  "Bri Dhan 82" ///
                         82  "Bri Dhan 83" ///
                         83  "Bri Dhan 84" ///
                         84  "Bri Dhan 85" ///
                         85  "Bri Dhan 86" ///
                         86  "Bri Dhan 87" ///
                         87  "Bri Dhan 88" ///
                         88  "Bri Dhan 89" ///
                         89  "Bri Dhan 90" ///
                         90  "Bri Dhan 91" ///
                         91  "Bri Dhan 92" ///
                         92  "Bri Dhan 93" ///
                         93  "Bri Dhan 94" ///
                         94  "Bri Dhan 95" ///
                         95  "Bri Dhan 96" ///
                         96  "Bri Dhan 97" ///
                         97  "Bri Dhan 98" ///
                         98  "Bri Dhan 99" ///
                         99  "Bri Dhan 100" ///
                         100 "Bri Dhan 101" ///
                         101 "Bri Dhan 102" ///
                         102 "Bri Dhan 103" ///
                         103 "Bri Dhan 104" ///
                         104 "Bri Dhan 105" ///
                         105 "Bri Dhan 106" ///
                         106 "Nerica(new rice for africa)" ///
                         107 "Haridhan" ///
                         108 "Asiruddin" ///
                         109 "Kajallata" ///
                         110 "Khude kajal" ///
                         111 "Miniket" ///
                         112 "Paijam" ///
                         113 "Shapla" ///
                         114 "Bashmati" ///
                         115 "Jamaibabu" ///
                         116 "Guti/rajshahi/lalshorna" ///
                         117 "Bhojon(white/coarse)" ///
                         118 "Binni dhan" ///
                         119 "Tepi dhan" ///
                         120 "Alok" ///
                         121 "Sonar bangla" ///
                         122 "Jagoron" ///
                         123 "Shakti 1" ///
                         124 "Shakti 2" ///
                         125 "Aloron 1" ///
                         126 "Aloron 2" ///
                         127 "Hira" ///
                         128 "ACI" ///
                         129 "Lal Teer" ///
                         130 "BINA 1" ///
                         131 "BINA 2" ///
                         132 "BINA 3" ///
                         133 "BINA 4" ///
                         134 "BINA 5" ///
                         135 "BINA 6(Boro/aus)" ///
                         136 "BINA 7(Aman)" ///
                         137 "BINA 8(Boro/Aus)" ///
                         138 "BINA 9" ///
                         139 "BINA 10 (Boro)" ///
                         140 "BINA 11(aman/aus)" ///
                         141 "BINA 12 (aman)" ///
                         142 "BINA 13 (aman)" ///
                         143 "BINA 14 (boro)" ///
                         144 "BINA 15 (aman)" ///
                         145 "BINA 16(aman)" ///
                         146 "BINA 17" ///
                         147 "BINA 18" ///
                         148 "BINA 19" ///
                         149 "BINA 20" ///
                         150 "BINA 21" ///
                         151 "BINA 22" ///
                         152 "BINA 23" ///
                         153 "BINA 24" ///
                         154 "BINA 25" ///
                         155 "Bri Hybrid-1(Boro)" ///
                         156 "Bri Hybrid-2(Boro)" ///
                         157 "Bri Hybrid-3(Boro)" ///
                         158 "Bri Hybrid-4(Boro Aman)" ///
                         159 "Bri hybrid 5" ///
                         160 "Bri hybrid 6" ///
                         161 "Bri hybrid 7" ///
                         162 "Bri hybrid 8" ///
                         163 "Binashail(aman)" ///
                         164 "Iratom 24(Boro)" ///
                         165 "Taj" ///
                         166 "HS" ///
                         167 "Shonali" ///
                         168 "Surma" ///
                         169 "Padma" ///
                         170 "Bijoy" ///
                         171 "Borkot" ///
                         172 "Raja" ///
                         173 "Chitra" ///
                         174 "Shobujmoti" ///
                         175 "Kajol" ///
                         176 "Rajkumar" ///
                         177 "Robi" ///
                         178 "BU Aromatic Hybrid Dhan-1" ///
                         179 "BU Aromatic Dhan-2" ///
						180 "Bongobondhu" ///
						181 "Jira" ///
						182 "Tej gold" ///
						183 "Mamun (Aman)" ///
						184 "Ronjit" ///
						185 "Katari" ///
						186 "Hira 2" ///
						187 "Hira 6" ///
						188 "Hira 19" ///
						189 "Dhani gold/Danigol/Dhanikul/Dhanigul" ///
						190 "Jonok Raj" ///
						191 "Shuvo Lota" ///
						192 "Mota (round bold seed)" ///
						-86 "Others", modify
						
						la val b2paddy_variety b2paddy_variety
		
	recode b2potato_variety -96 = 36 if regex(b2potato_variety_oth, "BRAC") | regex(b2potato_variety_oth, "Brac")
	
	recode b2potato_variety -96 = 23 if regex(b2potato_variety_oth, "Diamond") | regex(b2potato_variety_oth, "Daimon") | ///
	regex(b2potato_variety_oth, "Damiond") | regex(b2potato_variety_oth, "Daymon") | ///
	regex(b2potato_variety_oth, "Dimo") | regex(b2potato_variety_oth, "Daymon") | ///
	regex(b2potato_variety_oth, "diamond")	
	
	
	recode b2potato_variety -96 = 24 if regex(b2potato_variety_oth, "Dash") | regex(b2potato_variety_oth, "Dashi") | ///
	regex(b2potato_variety_oth, "Dasi") | regex(b2potato_variety_oth, "Deshi") | regex(b2potato_variety_oth, "Desi") | ///
	regex(b2potato_variety_oth, "deshi")
	
	recode b2potato_variety -96 = 25 if regex(b2potato_variety_oth, "Eistik") | regex(b2potato_variety_oth, "Estik") | ///
	regex(b2potato_variety_oth, "Istik") | regex(b2potato_variety_oth, "Stick") | regex(b2potato_variety_oth, "Stik")  | ///
	regex(b2potato_variety_oth, "Istik") | regex(b2potato_variety_oth, "Stick") | regex(b2potato_variety_oth, "Stik") | ///
	regex(b2potato_variety_oth, "stick")	
	
	recode b2potato_variety -96 = 26 if regex(b2potato_variety_oth, "Stric") | regex(b2potato_variety_oth, "Strik")
	
	
	recode b2potato_variety -96 = 27 if regex(b2potato_variety_oth, "Pakhri") | ///
	regex(b2potato_variety_oth, "Pakre") | regex(b2potato_variety_oth, "Pakri") | ///
	regex(b2potato_variety_oth, "pakri")
	

	recode b2potato_variety -96 = 38 if regex(b2potato_variety_oth, "Gol alu") | regex(b2potato_variety_oth, "Lal")
	
	recode b2potato_variety -96 = 28 if regex(b2potato_variety_oth, "Holender")
	
	recode b2potato_variety -96 = 29 if regex(b2potato_variety_oth, "Hibret") | regex(b2potato_variety_oth, "Hibright") ///
	| regex(b2potato_variety_oth, "Ispahani hybrid")
	
	recode b2potato_variety -96 = 30 if regex(b2potato_variety_oth, "Karech") | regex(b2potato_variety_oth, "Karis alu") ///
	| regex(b2potato_variety_oth, "Kariz") | regex(b2potato_variety_oth, "karis") | ///
	 regex(b2potato_variety_oth, "karch")
	
	recode b2potato_variety -96 = 31 if regex(b2potato_variety_oth, "Kartinal") | regex(b2potato_variety_oth, "Kathi lal") | ///
	regex(b2potato_variety_oth, "Kathi nal") | regex(b2potato_variety_oth, "Kati") 
	
	recode b2potato_variety -96 = 37 if regex(b2potato_variety_oth, "Stari") | ///
	regex(b2potato_variety_oth, "Stories") | regex(b2potato_variety_oth, "Isteris") | ///
	regex(b2potato_variety_oth, "Stadis") | regex(b2potato_variety_oth, "Studis")
	
	recode b2potato_variety -96 = 32 if regex(b2potato_variety_oth, "Magi") | regex(b2potato_variety_oth, "Majic")
	
	recode b2potato_variety -96 = 33 if regex(b2potato_variety_oth, "Mujika")
	
	recode b2potato_variety -96 = 34 if regex(b2potato_variety_oth, "Saital") | regex(b2potato_variety_oth, "Satal") | ///
	regex(b2potato_variety_oth, "Shatel")
	
	recode b2potato_variety -96 = 35 if regex(b2potato_variety_oth, "Sunshine") | regex(b2potato_variety_oth, "Surjo mukhi") | ///
	regex(b2potato_variety_oth, "Shurjo mukhi")
	
	la def b2potato_variety 1 "BARI ALU-01" ///
							2 "BARI ALU-12" ///
							3 "BARI ALU-22" ///
							4 "BARI Alu-46" ///
							5 "BARI Alu-53" ///
							6 "BARI Alu-68" ///
							7 "BARI Alu-69" ///
							8 "BARI Alu-70" ///
							9 "BARI Alu-71" ///
							10 "BARI Alu-72" ///
							11 "BARI Alu-73" ///
							12 "BARI Alu-74" ///
							13 "BARI Alu-75" ///
							14 "BARI Alu-76" ///
							15 "BARI Alu-77" ///
							16 "BARI Alu-78" ///
							17 "BARI Alu-79" ///
							18 "BARI Alu-81" ///
							19 "BARI Alu-87" ///
							20 "BARI Alu-88" ///
							21 "BARI TPS-1" ///
							22 "BARI TPS-2" ///
							23 "Diamond" ///
							24 "Local/Deshi" ///
							25 "Stick" ///
							26 "Stric/Strik" ///
							27 "Red round/Pakri" ///
							28 "Holender" ///
							29 "Ispahani hybrid/hybrid" ///
							30 "Kariz/Karis/Karech" ///
							31 "Kartinal/Kathi lal/kathi nal/Starics/Starik/Staris" ///
							32 "Magic" ///
							33 "Mujika" ///
							34 "Saital/Satal" ///
							35 "Sunshine/Surjo mukhi" ///
							36 "BRAC" ///
							37 "Staris" ///
							38 "Round red potato" ///
							-96	"Others", modify

							
							la val b2potato_variety b2potato_variety

	
	
	recode b2maize_variety -96 = 25 if regex(b2maize_variety_oth, "555")
	
	recode b2maize_variety -96 = 26 if regex(b2maize_variety_oth, "77-55") //Bari Hybrid 77-55
	
	recode b2maize_variety -96 = 27 if regex(b2maize_variety_oth, "71") //Bijoy 71
	
	recode b2maize_variety -96 = 28 if regex(b2maize_variety_oth, "tiger") | ///
	regex(b2maize_variety_oth, "Tiger") | regex(b2maize_variety_oth, "tigar") | ///
	regex(b2maize_variety_oth, "Taigar") // Double Tiger
	
	recode b2maize_variety -96 = 29 if regex(b2maize_variety_oth, "Hivret") | ///
	regex(b2maize_variety_oth, "Hybrid") | regex(b2maize_variety_oth, "Haibbit") | ///
	regex(b2maize_variety_oth, "Haibirit") | regex(b2maize_variety_oth, "Haibit") | ///
	regex(b2maize_variety_oth, "Haibrit") | regex(b2maize_variety_oth, "Hibrit") | ///
	regex(b2maize_variety_oth, "Hybried") // Hybrid
	
	recode b2maize_variety -96 = 30 if regex(b2maize_variety_oth, "Parfact") | ///
	regex(b2maize_variety_oth, "Parfek") | regex(b2maize_variety_oth, "Parfet") |  ///
	regex(b2maize_variety_oth, "Perfect") // Perfect
	
	recode b2maize_variety -96 = 31 if regex(b2maize_variety_oth, "Rocket") | ///
	regex(b2maize_variety_oth, "Roket") | regex(b2maize_variety_oth, "Rocat") |  ///
	regex(b2maize_variety_oth, "Perfect") // Rocket
	

					label define b2maize_variety ///
					1 "BARI Hybrid Maize 1" ///
					2 "BARI Hybrid Maize 2" ///
					3 "BARI Hybrid Maize 4" ///
					4 "BARI Hybrid Maize-12" ///
					5 "BARI Hybrid Maize-13" ///
					6 "BARI Hybrid Maize-14" ///
					7 "BARI Hybrid Maize-15" ///
					8 "BARI Hybrid Maize-16" ///
					9 "BARI Hybrid Maize-17" ///
					10 "BARI Hybrid Maize-3" ///
					11 "BARI Hybrid Maize-5" ///
					12 "BARI Hybrid Maize-6" ///
					13 "BARI Hybrid Maize-7" ///
					14 "BARI Hybrid Maize-8" ///
					15 "BARI Hybrid Maize-9" ///
					16 "BARI Maize-5" ///
					17 "BARI Maize-6" ///
					18 "BARI Maize-7" ///
					19 "Bari Misty Maize" ///
					20 "BARI sweetcorn-1" ///
					21 "Barnali" ///
					22 "Khoibhutta" ///
					23 "Mohor" ///
					24 "Suvra" ///
					25 "Variety referred as 555" ///
					26 "Bari Hybrid 77-55" ///
					27 "Bijoy 71" ///
					28 "Double Tiger" ///
					29 "Respondent stated hybrid" ///
					30 "Perfect" ///
					31 "Rocket" ///					
					-96	"Other (specify)", modify
					
					la val b2maize_variety b2maize_variety
					
					
	
	**# Cleaning harvest date
	/* Cleaning the harvest dates that were before the planting dates based on 
	replies from DATA*/
	
	recode b2harvestdate 22736 = 23101 if a1hhid_combined == "295" & b2crop == 9 &  b1plot_num == 3
	
	recode b2plantdate 23000/24000 = . if a1hhid_combined == "1007.2" & b2crop == 38 &  b1plot_num == 3
	
	recode b2harvestdate 23000/24000 = . if a1hhid_combined == "1007.2" & b2crop == 38 &  b1plot_num == 3
	
	recode b2harvestdate 22980 = 23345 if a1hhid_combined == "489" & b2crop == 142 &  b1plot_num == 2
	
	recode b2harvestdate 22950 = 23315 if a1hhid_combined == "490.1" & b2crop == 65 &  b1plot_num == 11
	
	recode b2harvestdate 22980 = 23130 if a1hhid_combined == "1200" & b2crop == 10 &  b1plot_num == 8
	
	recode b2plantdate 23284 = 23314 if a1hhid_combined == "3217" & b2crop == 119 &  b1plot_num == 5
	
	recode b2harvestdate 23042 = 23407 if a1hhid_combined == "3217" & b2crop == 119 &  b1plot_num == 5
	
	recode b2plantdate 23589 = 23223 if a1hhid_combined == "3209" & b2crop == 7 &  b1plot_num == 3
	
	recode b2harvestdate 23101 = 23466 if a1hhid_combined == "2383" & b2crop == 10 &  b1plot_num == 4
	
	recode b2harvestdate 23101 = 23466 if a1hhid_combined == "2383" & b2crop == 10 &  b1plot_num == 2

	recode b2harvestdate 23101 = 23466 if a1hhid_combined == "2383" & b2crop == 10 &  b1plot_num == 3
	
	recode b2harvestdate 22736 = 23101  if a1hhid_combined == "2381.1" & b2crop == 11 &  b1plot_num == 2
	
	recode b2plantdate 23376 = 23407 if a1hhid_combined == "2774" & b2crop == 10 &  b1plot_num == 5
	
	recode b2harvestdate 23042 = 23467 if a1hhid_combined == "2774" & b2crop == 10 &  b1plot_num == 5
	
	recode b2plantdate 23345 = 22980 if a1hhid_combined == "2761" & b2crop == 38 &  b1plot_num == 2
	
	recode b2harvestdate 23101 = 23042 if a1hhid_combined == "2761" & b2crop == 38 &  b1plot_num == 2

	recode b2harvestweek 1 = 4 if a1hhid_combined == "2761" & b2crop == 38 &  b1plot_num == 2
		
	recode b2harvestdate 23131 = 23467 if a1hhid_combined == "2777" & b2crop == 10 &  b1plot_num == 5
	
	recode b2harvestweek 2 = 4 if a1hhid_combined == "2777" & b2crop == 10 &  b1plot_num == 5 & b2harvestdate == 23467

	recode b2harvestdate 23131 = 23497 if a1hhid_combined == "2778" & b2crop == 10 &  b1plot_num == 4
	
	recode b2plantdate 23711 = 23345 if a1hhid_combined == "4707" & b2crop == 10 &  b1plot_num == 9

	recode b2harvestdate 22980 = 23345 if a1hhid_combined == "2839.1" & b2crop == 79 &  b1plot_num == 11
	
	recode b2harvestdate 22705 = 23070 if a1hhid_combined == "2821" & b2crop == 11 &  b1plot_num == 14
	
	recode b2harvestdate 23042 = 23345 if a1hhid_combined == "3463" & b2crop == 7 &  b1plot_num == 2
	
	recode b2plantdate 23589 = 23223 if a1hhid_combined == "3463" & b2crop == 7 &  b1plot_num == 2
	
	recode b2harvestdate 23497 = 23345 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 10
	
	recode b2plantdate 23528 = 23223 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 10
	
	recode b2harvestdate 23131 = 23467 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 2
	
	recode b2harvestdate 23042 = 23101 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 5
	
	recode b2plantdate 23345 = 23011 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 5
	
	recode b2harvestdate 23162 = 23101 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 8
	
	recode b2plantdate 23376 = 23011 if a1hhid_combined == "3463" & b2crop == 10 &  b1plot_num == 8
	
	recode b2harvestdate 23070 = 23101 if a1hhid_combined == "3476" & b2crop == 10 &  b1plot_num == 2
	
	recode b2plantdate 23345 = 23376 if a1hhid_combined == "3476" & b2crop == 10 &  b1plot_num == 2
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "3461" & b2crop == 10 &  b1plot_num == 14
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "3461" & b2crop == 10 &  b1plot_num == 20
	
	recode b2harvestdate 23042 = 23407 if a1hhid_combined == "4163.2" & b2crop == 44 &  b1plot_num == 3
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "4163.2" & b2crop == 142 &  b1plot_num == 5

	recode b2harvestdate 23131 = 23497 if a1hhid_combined == "1591" & b2crop == 11 &  b1plot_num == 12
	
	recode b2harvestdate 22950 = 23315 if a1hhid_combined == "1600.21" & b2crop == 7 &  b1plot_num == 18
	
	recode b2harvestdate 23711 = 23345 if a1hhid_combined == "4583" & b2crop == 6 &  b1plot_num == 5
	
	recode b2plantdate 23923 = 23192 if a1hhid_combined == "4583" & b2crop == 6 &  b1plot_num == 5
	
	recode b2harvestdate 22980 = 23345 if a1hhid_combined == "4594" & b2crop == 7 &  b1plot_num == 9
	
	recode b2harvestdate 23042 = 23497 if a1hhid_combined == "4585" & b2crop == 11 &  b1plot_num == 7
	
	recode b2harvestdate 23042 = 23407 if a1hhid_combined == "4600" & b2crop == 119 &  b1plot_num == 5
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "1791.3" & b2crop == 11 &  b1plot_num == 7
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "1797.2" & b2crop == 11 &  b1plot_num == 6
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "1797.2" & b2crop == 11 &  b1plot_num == 8
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "1797.2" & b2crop == 11 &  b1plot_num == 7
	
	recode b2harvestdate 23101 = 23467 if a1hhid_combined == "1798" & b2crop == 11 &  b1plot_num == 3
	
	recode b2harvestdate 23131 = 23497 if a1hhid_combined == "1784" & b2crop == 11 &  b1plot_num == 6
	
	recode b2harvestdate 23070 = 23467 if a1hhid_combined == "5159" & b2crop == 10 &  b1plot_num == 6
	
	recode b2harvestdate 23042 = 23467 if a1hhid_combined == "5159" & b2crop == 10 &  b1plot_num == 6
	
	// recoding paddy seasons based on planting dates
	
	g paddy_season = 1 if inrange(b2plantdate, 23315, 23434) & !mi(b2paddy_variety)
	recode paddy_season . = 2 if inrange(b2plantdate, 23162, 23314) & !mi(b2paddy_variety)
	recode paddy_season . = 3 if inrange(b2plantdate, 23070, 23130) & !mi(b2paddy_variety)
	recode paddy_season . = 4 if inrange(b2plantdate, 22948, 23069) & !mi(b2paddy_variety)
	
	la def paddy_season 1 "Boro 23-24 (Paddy)" 2 "Aman 23 (Paddy)" 3 "Aus 23 (Paddy)" 4 "Boro 22-23 (Paddy)"
	la val paddy_season paddy_season
	
	recode b2crop_season 1 = 2 if paddy_season == 2
	recode b2crop_season 1 = 4 if paddy_season == 4
	recode b2crop_season 2 = 1 if paddy_season == 1
	recode b2crop_season 2 = 3 if paddy_season == 3
	recode b2crop_season 2 = 4 if paddy_season == 4
	
	recode b2crop_season 4 = 1 if paddy_season == 1
	recode b2crop_season 4 = 2 if paddy_season == 2
	recode b2crop_season 4 = 3 if paddy_season == 3
	
	recode b2crop_season 3 = 1 if paddy_season == 1
	
	
	drop paddy_season
	
	**# Cleaning module B4
	
	la var b4use_animal "Have animals been used to prepare the land this season?"
	la var b4animal_cost "Total animal cost"
	la var b4use_machine "Has machinery been used to prepare the land this season?"
	la var b4machine_rent1 "Rental cost of power tiller in the given season"
	la var b4machine_rent2 "Rental cost of tractor in the given season"
	la var b4machine_rent3 "Rental cost of plough in the given season"
	la var b4machine_rent4 "Rental cost of manual in the given season"
	
	la var b4machine_type_1 "Has power tiller been used to prepare the land?"
	la var b4machine_type_2 "Has tractor been used to prepare the land?"
	la var b4machine_type_3 "Has plough been used to prepare the land?"
	la var b4machine_type_4 "Has manual been used to prepare the land?"
	
	la var b4use_machine_plant "Has machinery been used for planting this season?"
	la var b4use_mach_fertilizer "Has machinery been used for fertilizer this season?"
	la var b4use_mach_pesticide "Has machinery been used for pesticide this season?"
	la var b4use_machine_weed "Has machinery been used for weeding this season?"
	la var b4use_mach_harvest "Has machinery been used for harvesting this season?"
	
	order b4machine_rent1, after(b4machine_type_1)
	order b4machine_rent2, after(b4machine_type_2)
	order b4machine_rent3, after(b4machine_type_3)
	order b4machine_rent4, after(b4machine_type_4)
	
	drop b4machine_name1 b4machine_name2 b4machine_name3 b4machine_name4 ///
	b4plottype b4soiltype b4plot_size b4area b4season_name b4crop_name ///
	b4landname_size b4split_serial b4machine_repeat_count
	
	
	g b4animal_cost_hectare = round(b4animal_cost/b2area_hectare, .01)
	g b4machine_rent1_hectare = round(b4machine_rent1/b2area_hectare, .01)
	g b4machine_rent2_hectare = round(b4machine_rent2/b2area_hectare, .01)
	g b4machine_rent3_hectare = round(b4machine_rent3/b2area_hectare, .01)
	g b4machine_rent4_hectare = round(b4machine_rent4/b2area_hectare, .01)
	g b4machineplant_cost_hectare = round(b4machineplant_cost/b2area_hectare, .01)
	g b4mach_fertilizer_cost_hectare = round(b4mach_fertilizer_cost/b2area_hectare, .01)
	g b4mach_pesticide_cost_hectare = round(b4mach_pesticide_cost/b2area_hectare, .01)
	g b4mach_weed_cost_hectare = round(b4mach_weed_cost/b2area_hectare, .01)
	g b4mach_harvest_cost_hectare = round(b4mach_harvest_cost/b2area_hectare, .01)	
	
	la var b4animal_cost_hectare "Total animal cost per hectare"
	la var b4machine_rent1_hectare "Rental cost of power tiller/hectare in the given season"
	la var b4machine_rent2_hectare "Rental cost of tractor/hectare in the given season"
	la var b4machine_rent3_hectare "Rental cost of plough/hectare in the given season"
	la var b4machine_rent4_hectare "Rental cost of manual/hectare in the given season"
	la var b4machineplant_cost_hectare "Cost/projected cost for using machines for planting per hectare"
	la var b4mach_fertilizer_cost_hectare "Cost/projected cost for using machines for fertilizers per hectare"
	la var b4mach_pesticide_cost_hectare "Cost/projected cost for using machines for pesticide per hectare"
	la var b4mach_weed_cost_hectare "Cost/projected cost for using machines for weeding per hectare"
	la var b4mach_harvest_cost_hectare "Cost/projected cost for using machines for harvesting per hectare"
	
	order b4animal_cost_hectare, after(b4animal_cost)
	order b4machine_rent1_hectare, after(b4machine_rent1)
	order b4machine_rent2_hectare, after(b4machine_rent2)
	order b4machine_rent3_hectare, after(b4machine_rent3)
	order b4machine_rent4_hectare, after(b4machine_rent4)
	order b4machineplant_cost_hectare, after(b4machineplant_cost)
	order b4mach_fertilizer_cost_hectare, after(b4mach_fertilizer_cost)
	order b4mach_pesticide_cost_hectare, after(b4mach_pesticide_cost)
	order b4mach_weed_cost_hectare, after(b4mach_weed_cost)
	order b4mach_harvest_cost_hectare, after(b4mach_harvest_cost)
	
	
	**# Cleaning module B5
	
	drop b5landname_size b5plottype b5soiltype b5plot_size ///
	b5season_name b5crop_name b5area b5dry_repeat_count b5reasonmotor b5powersource ///
	b5irrigation_pay_label b5causeshortage b5reirrigate_decide_label
	
	
	
	order b5dry_how*, after(b5ndry_this_season)
	
	la def b5reason_motor 1	"No BMDA tube well" ///
	2 "Serial was late" ///
	3 "I missed my place in the serial" ///
	4 "BMDA pump stopped working" ///
	5 "Electricity problems in pumping the BMDA pump" ///
	-96	"Other (specify)", modify
	
	la val b5reason_motor b5reason_motor
	
	recode b5pump_type -96 = 1 if regex(b5pump_type_oth, "proyojon") | regex(b5pump_type_oth, "Birsti") | ///
	regex(b5pump_type_oth, "Birst") | regex(b5pump_type_oth, "Bisti") | regex(b5pump_type_oth, "Bonna") | ///
	regex(b5pump_type_oth, "Birst") | regex(b5pump_type_oth, "Briste") | regex(b5pump_type_oth, "Bristi") | ///
	regex(b5pump_type_oth, "pani dey na") | regex(b5pump_type_oth, "Pani Diana") | regex(b5pump_type_oth, "Pani daina")	| ///
	regex(b5pump_type_oth, "Pani daine") | regex(b5pump_type_oth, "Pani daoya lage nai") | regex(b5pump_type_oth, "Pani dawa hiy nai") | ///
	regex(b5pump_type_oth, "Pani dawa hoy nai") | regex(b5pump_type_oth, "Pani dawa lagana") | regex(b5pump_type_oth, "Pani day ni") | ///
	regex(b5pump_type_oth, "Pani dayni") | regex(b5pump_type_oth, "Pani dea lageni") | regex(b5pump_type_oth, "Pani dei na") | ///
	regex(b5pump_type_oth, "Pani deini") | regex(b5pump_type_oth, "Pani dey nai") | regex(b5pump_type_oth, "Pani dite hoyna") | ///
	regex(b5pump_type_oth, "Pani dorkar hoi ni") | regex(b5pump_type_oth, "Pani drkr nhi") | regex(b5pump_type_oth, "Pani laga na") | ///
	regex(b5pump_type_oth, "Pani laga nai") | regex(b5pump_type_oth, "Pani lage na") | regex(b5pump_type_oth, "Pani lage n") | ///
	regex(b5pump_type_oth, "Pani lage ni") | regex(b5pump_type_oth, "Pani lageni") | regex(b5pump_type_oth, "Pani lagi na") | ///
	regex(b5pump_type_oth, "Pani lge") | regex(b5pump_type_oth, "Panir dawa hoy nai") | regex(b5pump_type_oth, "Panir pawa lage nai") | ///
	regex(b5pump_type_oth, "Seas") | regex(b5pump_type_oth, "Sech") | regex(b5pump_type_oth, "Ses") | regex(b5pump_type_oth, "pani dey nei")
	
	
	recode b5pump_type -96 = 11 if regex(b5pump_type_oth, "Balti") | regex(b5pump_type_oth, "balti") | ///
	regex(b5pump_type_oth, "Kolshe") | regex(b5pump_type_oth, "Kolshi")
	
	recode b5pump_type -96 = 12 if regex(b5pump_type_oth, "Nodi") | regex(b5pump_type_oth, "Nadi")
	
	la def b5power_source 	1	"Electricity (grid)" ///
							2	"Electricity (solar panel)" ///
							3	"Petrol/Diesel/Gasoline" ///
							4	"Natural Gas" ///
							5	"LP Gas", modify
							
	la val b5power_source b5power_source
	
	la var b5depth_irrigation "Approx. depth of irrigation water during each irrigation [cm]"
	la var b5water_price "What is the price of water per unit"
	la var b5relative_height "Height of the plot relative to other plots irrigated from the same source"
	la var b5awd_use "Have you ever used this pipe to monitor the water level below the soil surface"
	
	
	la def b5cause_shortage 1 "Lack of rainfall/water in the river" ///
							2	"Lack of water in the dam" ///
							3	"Fall in groundwater level" ///
							4	"Water too saline" ///
							5	"Electricity failure" ///
							6	"Dispute with irrigation organization" ///
							-96	"Other (specify)"
							
	la val b5cause_shortage b5cause_shortage

	
	g b5tot_water_cost_hectare = round(b5tot_water_cost/b2area_hectare, .01)
	
	la var b5tot_water_cost_hectare "Total water cost per hectare this season"
	
	order b5tot_water_cost_hectare, after(b5tot_water_cost)
	
	forvalues i = 1/22 {
	la def b5dry_how`i' 1	"Plot dried naturally" ///
			2 "removed the water from the plot" ///
			3	"Not let it dry, depends on sl of the pump", modify
			
	la val b5dry_how`i' b5dry_how`i'
	
	la var b5dry_how`i' "How did the plot dry?"

	}
	
	la var b5reirrigate_decide_1 "Respondent decides when to reirrigate"
	la var b5reirrigate_decide_2 "Me and farmer with adjacent plot [Joint irrigation]"
	la var b5reirrigate_decide_3 "The adjacent/neighboring farmer decides when to reirrigate"
	la var b5reirrigate_decide_4 "Tube well owner decides when to reirrigate"
	la var b5reirrigate_decide_5 "Deep driver/Tubewell operator (Government Owned)"
	la var b5reirrigate_decide_6 "Deep driver/Tubewell operator/Water seller (Private)"

	
	forvalues j = 1/6 {
		
		la def b5reirrigate_decide_`j' 0 "No" 1 "Yes"
		
		la val b5reirrigate_decide_`j' b5reirrigate_decide_`j'
	}
	
	ren b5weed_control__96 b5weed_control_6
	
	la var b5weed_control_6 "Weeding not required"
	
	forvalues j = 1/6 {
		
		la def b5weed_control_`j' 0 "No" 1 "Yes"
		
		la val b5weed_control_`j' b5weed_control_`j'
	}
	
	
	/*Cleaning the land index because for some hh, the first repeat instance is not showing. Either the enumerator did not enter the data for the first repeat instance/deleted it or it's a surveyCTO error. Need the first repeat instance to clean the water committee and sell of water variable as they should only come once and not multiple times within a repeat group.*/
	
	recode b2land_index 2 = 1 if a1hhid_combined == "1"
	recode b2land_index 2 = 1 if a1hhid_combined =="1124"
	recode b2land_index 2 = 1 if a1hhid_combined =="1558.1"
	recode b2land_index 2 = 1 if a1hhid_combined =="1722"
	recode b2land_index 2 = 1 if a1hhid_combined =="1791.1"
	recode b2land_index 2 = 1 if a1hhid_combined =="1828"
	recode b2land_index 2 = 1 if a1hhid_combined =="2100"
	recode b2land_index 2 = 1 if a1hhid_combined =="2181"
	recode b2land_index 2 = 1 if a1hhid_combined =="2360"
	recode b2land_index 2 = 1 if a1hhid_combined =="2777"
	recode b2land_index 2 = 1 if a1hhid_combined =="2886"
	recode b2land_index 2 = 1 if a1hhid_combined =="296.1"
	recode b2land_index 2 = 1 if a1hhid_combined =="3078.1"
	recode b2land_index 2 = 1 if a1hhid_combined =="316.3"
	recode b2land_index 2 = 1 if a1hhid_combined =="3215"
	recode b2land_index 2 = 1 if a1hhid_combined =="4222"
	recode b2land_index 2 = 1 if a1hhid_combined =="4355"
	recode b2land_index 2 = 1 if a1hhid_combined =="4585"
	recode b2land_index 2 = 1 if a1hhid_combined =="4597"
	recode b2land_index 2 = 1 if a1hhid_combined =="4705"
	recode b2land_index 2 = 1 if a1hhid_combined =="4855"
	recode b2land_index 2 = 1 if a1hhid_combined =="4867"
	recode b2land_index 2 = 1 if a1hhid_combined =="5160"
	recode b2land_index 2 = 1 if a1hhid_combined =="5173"
	recode b2land_index 2 = 1 if a1hhid_combined =="5351"
	recode b2land_index 2 = 1 if a1hhid_combined =="863"
	
	recode b5sell_water_vill 0/1 = . if b2land_index > 1 & !mi(b2land_index)
	recode b5water_committee -98/1 = . if b2land_index > 1 & !mi(b2land_index)
	
	ren b5n_irrigation_boro b5n_irrigation
	
	** Module F recoding
	
	// Recoding shocks and harvests based on enumerator comments
	
	recode f1shock_event_2 0 = 1 if a1hhid_combined == "2344"
	
	recode f1shock_event_1 0 = 1 if a1hhid_combined == "4646"
	
	recode f1shock_event_2 0 = 1 if a1hhid_combined == "4656"
	
	recode f1shock_event_2 0 = 1 if a1hhid_combined == "4819"
	
	recode f1shock_event_2 0 = 1 if a1hhid_combined == "4973"
	
	recode f1shock_event_1 0 = 1 if a1hhid_combined == "5158.1"
	
	
	
	recode b3qty_harvest 0 = . if b3plot_harvest_qty == 0 & b2crop_season == 1 ///
	& f1shock_event_1 == 0 & f1shock_event_2 == 0
	
	recode b3int_qty_harvest 0 = . if b3plot_harvest_qty == 0 & b2crop_season == 1 ///
	& f1shock_event_1 == 0 & f1shock_event_2 == 0
	
	recode b3plot_harvest_ton 0 = . if b3plot_harvest_qty == 0 & b2crop_season == 1 ///
	& f1shock_event_1 == 0 & f1shock_event_2 == 0
	
	recode b3yield_hectare 0 = . if b3plot_harvest_qty == 0 & b2crop_season == 1 ///
	& f1shock_event_1 == 0 & f1shock_event_2 == 0
	
	recode b3plot_harvest_qty 0 = . if b3plot_harvest_qty == 0 & b2crop_season == 1 ///
	& f1shock_event_1 == 0 & f1shock_event_2 == 0
	
	** dropping unnecessary variables
	
	drop b1plottype b1soiltype b5split_serial b2split_serial b2paddy_yes ///
	b2potatovariety b2crop_name b2intercrop_name b2swpotatovariety b2maizevariety ///
	b2wheatvariety b2lentilvariety b2chickpeavariety b2peanutvariety ///
	b2paddy_intercrop_variety b2paddyvariety b2diff_1 b2diff_2 b2diff_3 b2diff_4 ///
	b1plotsize_difference b5weed_control_oth ///
	b3qty_net_harvest b3int_qty_net_harvest b3plot_harvest_qty ///
	b3plot_harvest_ton b3yield_hectare b1n_plot_2018 b1n_plot_2024_main ///
	b1sum_newplot_main b1plot_roster_count b1sum_newplot_resurvey ///
	b1sum_newplot b1land_new_resurvey b2other_variety b2other_intervariety ///
	enum_comment a1division divisionname a1district districtname a1upazila ///
	upazilaname a1union a1mouza a1village a01combined_18 a01combined_15 ///
	a01_12 a01split_hh_15 a01split_serial_15 a01absent_15 a01split_hh_18 ///
	a01split_serial_18 a1hhloc a1split_hh a1total_split a1split_hh_serial ///
	a1religion a1language a1ethnicity a1ethnicity_oth hhweight_24

	
	ren b2paddyintercropvariety b2paddy_intercrop_variety
	
	order b2paddy_intercrop_variety, after(b2harvestweek)
	
	la var agri_control_household "Household takes decisions regarding agricultural and aquaculture production"
	
	
	
	order KEY, after(agri_control_household)
	
	
	la var b2land_serial "Land sl. for Module B2-B5 with plot no., season, split serial (0 if not split)"
	la var b2split_clean "Serial of the split (0 if not split)"
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", replace
	
	**# Module B6
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b6season_repeat") firstrow clear
	
	drop if b6seedbed_crop == ""
	
	drop b6seedbed_crop_* 
	ren (KEY PARENT_KEY) (KEY_CROP KEY)
	
	tempfile b6_season
	save `b6_season', replace
	
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b6crop_repeat") firstrow clear
	
	ren (PARENT_KEY KEY) (KEY_CROP KEY_LAND)
	
	drop b6seedbed_land*
	
	merge m:1 KEY_CROP using `b6_season', nogen
	
	tempfile b6_crop
	save `b6_crop', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b6seedbed_land_rep") firstrow clear
	
	ren PARENT_KEY KEY_LAND
	
	split KEY_LAND, p(/) gen(KEY) 
	
	drop b6seedbed_land_index b6seedbed_land_name KEY
	
	ren KEY1 KEY
	
	merge m:1 KEY_LAND using `b6_crop', nogen
			
	merge m:1 KEY using `main_data', nogen keep(2 3)
	
	keep a1hhid_combined paddy_variety_oth* b6* KEY
	ren b6seedbed_land_id b1plot_num
	
	keep if b6seedbed_prep == 1
	
	drop b6crop_season b6season_repeat b6seedbed_crop_index ///
	b6seedbed_crop_name b6season_name b6seedbed_crop b6seedbed_prep
	
	order a1hhid_combined b1plot_num b6season_id b6seedbed_crop_id ///
	b6seedbed_paddy b6seedbed_decimal b6seed_amount b6seed_cost b6labor_cost ///
	b6family_labor_cost b6fertilizer_cost b6irrigation_cost b6oth_cost
		
	la def b6season_id 1 "Boro (rabi) 2024" ///
					   2 "Aman (kharif2 ) 2023" ///
					   3 "Aus (kharif1 ) 2023" ///
					   4 "Boro (rabi) 2022-2023" ///
					   5 "Yearly"
					   
	la val b6season_id b6season_id
	
	ren (b6seedbed_paddy b6seedbed_crop_id) (b2paddy_variety b2crop)
	
	
	tempfile b6main
	save `b6main', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b6season_repeat") firstrow clear
	
	drop if b6seedbed_crop == ""
	
	drop b6seedbed_crop_* 
	ren (KEY PARENT_KEY) (KEY_CROP KEY)
	
	tempfile b6_season_re
	save `b6_season_re', replace
	
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b6crop_repeat") firstrow clear
	
	ren (PARENT_KEY KEY) (KEY_CROP KEY_LAND)
	
	drop b6seedbed_land*
	
	merge m:1 KEY_CROP using `b6_season_re', nogen
	
	tempfile b6_crop_re
	save `b6_crop_re', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b6seedbed_land_rep") firstrow clear
	
	ren PARENT_KEY KEY_LAND
	
	split KEY_LAND, p(/) gen(KEY) 
	
	drop b6seedbed_land_index b6seedbed_land_name KEY
	
	ren KEY1 KEY
	
	merge m:1 KEY_LAND using `b6_crop_re', nogen
		
	merge m:1 KEY using `resurvey_data', nogen keep(2 3)
	
	keep a1hhid_combined  paddy_variety_oth* b6* KEY
	ren b6seedbed_land_id b1plot_num
	
	keep if b6seedbed_prep == 1
	
	drop b6crop_season b6season_repeat b6seedbed_crop_index ///
	b6seedbed_crop_name b6season_name b6seedbed_crop b6seedbed_prep
	
	order a1hhid_combined b1plot_num b6season_id b6seedbed_crop_id ///
	b6seedbed_paddy b6seedbed_decimal b6seed_amount b6seed_cost b6labor_cost ///
	b6family_labor_cost b6fertilizer_cost b6irrigation_cost b6oth_cost
	
	
	
	la def b6season_id 1 "Boro (rabi) 2024" ///
					   2 "Aman (kharif2 ) 2023" ///
					   3 "Aus (kharif1 ) 2023" ///
					   4 "Boro (rabi) 2022-2023" ///
					   5 "Yearly"
					   
	la val b6season_id b6season_id
	
	ren (b6seedbed_paddy b6seedbed_crop_id) (b2paddy_variety b2crop)
	
	split b2paddy_variety, p(" ")
	drop b2paddy_variety
	ren b2paddy_variety1 b2paddy_variety
	destring b2paddy_variety*, replace
	
	drop b6seedbed_paddy* b6crop_season* b6crop_repeat_count
	
	append using `b6main'
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_b6.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${temp_data}${slash}SPIA_BIHS_2024_module_b6.dta") label(English) dateformat(MDY) clear save("${temp_data}${slash}SPIA_BIHS_2024_module_b6.dta")
	
	**# Module B7
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("module_b7") firstrow clear
	
	drop if b7crops_1 == .
	
	drop b7crops_* b7season_name SETOF*
	
	
	
	ren (PARENT_KEY KEY) (KEY KEY_CROPS)
	
	tempfile module_b7
	save `module_b7', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b7crops_repeat") firstrow clear
	
	
	drop b7crops_index b7tot_sold b7tot_distribution SETOF* b7saletime_repeat_count

	
	ren (PARENT_KEY KEY) (KEY_CROPS KEY_SALES)
	
	merge m:1 KEY_CROPS using `module_b7', nogen
	
	drop b7qty_harvest_leased
	
	forvalues i = 1/145 {
	recode b7crops_id . = `i' if b7crops == "`i'"
	
	}
	
	drop if b7crops_id == .
	
	ren (b7crops_id b7crop_name) (b2crop b2crop_name)
	
	recode b2crop -86 = 39 if b2crop_name == "Badam |  Badam"
	recode b2crop -86 = 142 if b2crop_name == "Chopa ghas |  Chopa ghas"
	recode b2crop -86 = 142 if b2crop_name == "Ghaskhet |  Ghaskhet"
	recode b2crop -86 = 142 if b2crop_name == "Japani pang chuing ghas |  Japani pang chuing ghas"
	recode b2crop -86 = 142 if b2crop_name == "Nepier |  Nepier"
	recode b2crop -86 = 142 if b2crop_name == "Nipier |  Nipier"
	
	
	
	
	recode b2crop -86/-79 = 143 if regex(b2crop_name, "Pat")
	
	recode b2crop -86/-79 = 119 if regex(b2crop_name, "Alo |  Alo")
	
	
	recode b2crop -86/-79 = 142 if regex(b2crop_name, "gas") | regex(b2crop_name, "Gas") | ///
	regex(b2crop_name, "ghas") | regex(b2crop_name, "gash") | regex(b2crop_name, "Ghas") | regex(b2crop_name, "Gash") | ///
	regex(b2crop_name, "Ghsh") | regex(b2crop_name, "ঘাস ")  | regex(b2crop_name, "ges") | regex(b2crop_name, "Napeir")
	
	
	
	recode b2crop -86/-79 = 27 if regex(b2crop_name, "Dal")
	
	recode b2crop -86/-79 = 1 if regex(b2crop_name, "Dhan")  

	
	
	recode b2crop -86/-1 = 144
	
	replace b2crop_name = "" if b2crop != 144
	
	split b2crop_name, p(|)
	
	drop b2crop_name2 b2crop_name
	
	ren b2crop_name1 b7crop_name_oth
	
	la var b7crop_name_oth "Other crop name (specify)"
	
	la def b7season_id 1 "Boro (rabi) 2024" ///
	2 "Aman (kharif2 ) 2023" ///
	3 "Aus (kharif1 ) 2023" ///
	4 "Boro (rabi) 2022-2023" ///
	5 "Yearly" ///
	6 "N/A"
	
	la val b7season_id b7season_id
	
	la var b7season_id "Cultivation season"
	
	tempfile b7crops
	save `b7crops', replace
	
	drop b7sale_time*
	
	 
	
	merge m:1 KEY using `main_data', keepusing(a1hhid_combined) nogen keep(3)
	
	
	/*
	
	 Result                      Number of obs
    -----------------------------------------
    Not matched                         3,497
        from master                       822  (_merge==1)
        from using                      2,675  (_merge==2)

    Matched                             5,145  (_merge==3)
    -----------------------------------------
	
	The HHs not matching from using are non agri HHs and HHs that did not
	harvest their crops yet or had yearly crops on the field. The HHs not 
	matching from the master are the ones from the resurveyed list. 

	*/
	order a1hhid_combined b7season_id b7crops b2crop b7crop_name_oth ///
	b7qty_received_leased b7qty_consumed b7qty_given_away ///
	b7qty_animal_feed b7seed_next_year
	
	drop KEY_* 
	
	
	
	tempfile b7crop_prod
	save `b7crop_prod', replace
	
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b7saletime_repeat") firstrow clear
	
	drop if b7place_sale_1 == .
	
	drop b7place_sale_* b7sale_time_name SETOF*
	
	ren (PARENT_KEY KEY) (KEY_SALES KEY_PLACE)
	
	merge m:1 KEY_SALES using `b7crops', nogen
	
	drop if b7sale_time == "5"
	
	tempfile b7crops_sales
	save `b7crops_sales', replace
	
		
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b7place_sale_repeat") firstrow clear
	
	drop if mi(b7quantity_sold)
	
	drop KEY SETOFb7place_sale_repeat b7place_sale_name b7place_sale_oth
	
	recode b7place_sale_id 5 = 1
	
	ren PARENT_KEY KEY_PLACE
	
	merge m:1 KEY_PLACE using `b7crops_sales', nogen
	
	drop b7qty* b7seed_next_year b7sale_time_1 b7sale_time_2 b7sale_time_3 ///
	b7sale_time_4 b7sale_time_5
		
	merge m:1 KEY using `main_data', keepusing(a1hhid_combined) nogen keep(3)
	
	keep a1hhid_combined b7crops b2crop b7crop_name_oth b7sale_time b7sale_time_id ///
	b7place_sale b7place_sale_id b7quantity_sold b7market_rate b7total_price ///
	b7distance_place_sale b7duration_place_sale b7season_id
	
	order a1hhid_combined b7season_id b7crops b2crop b7crop_name_oth b7sale_time b7sale_time_id ///
	b7place_sale b7place_sale_id b7quantity_sold b7market_rate b7total_price ///
	b7distance_place_sale b7duration_place_sale
	
	la def b7sale_time_id 1	"within one month" ///
						  2 "after one month" /// 
						  3	"after two months" /// 
						  4	"after three months" ///
						  5	"did not sell"
						  
	la val b7sale_time_id b7sale_time_id
	
	
	
	la def b7place_sale_id 1 "Farm gate" ///
						   2 "Village market (within own village)" ///
						   3 "Village market (outside of own village)" ///
						   4 "Town market"
	
	la val b7place_sale_id b7place_sale_id
	

	la var b7sale_time_id "How long after the harvest was it sold?"
	la var b7place_sale_id "Place of sale"
	
	
	tempfile b7place_sale
	save `b7place_sale', replace
	
	
	
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("module_b7") firstrow clear
	
	drop if b7crops_1 == .
	
	drop b7crops_* b7season_name SETOF*
	
	
	
	ren (PARENT_KEY KEY) (KEY KEY_CROPS)
	
	tempfile module_b7re
	save `module_b7re', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b7crops_repeat") firstrow clear
	
	
	drop b7crops_index b7tot_sold b7tot_distribution SETOF* b7saletime_repeat_count

	
	ren (PARENT_KEY KEY) (KEY_CROPS KEY_SALES)
	
	merge m:1 KEY_CROPS using `module_b7re', nogen
	
	drop b7qty_harvest_leased
	
	forvalues i = 1/145 {
	recode b7crops_id . = `i' if b7crops == "`i'"
	
	}
	
	drop if b7crops_id == .
	
	ren (b7crops_id b7crop_name) (b2crop b2crop_name)
	
	recode b2crop -86 = 39 if b2crop_name == "Badam |  Badam"
	recode b2crop -86 = 142 if b2crop_name == "Chopa ghas |  Chopa ghas"
	recode b2crop -86 = 142 if b2crop_name == "Ghaskhet |  Ghaskhet"
	recode b2crop -86 = 142 if b2crop_name == "Japani pang chuing ghas |  Japani pang chuing ghas"
	recode b2crop -86 = 142 if b2crop_name == "Nepier |  Nepier"
	recode b2crop -86 = 142 if b2crop_name == "Nipier |  Nipier"
	
	
	
	
	recode b2crop -86/-79 = 143 if regex(b2crop_name, "Pat")
	
	recode b2crop -86/-79 = 119 if regex(b2crop_name, "Alo |  Alo")
	
	
	recode b2crop -86/-79 = 142 if regex(b2crop_name, "gas") | regex(b2crop_name, "Gas") | ///
	regex(b2crop_name, "ghas") | regex(b2crop_name, "gash") | regex(b2crop_name, "Ghas") | regex(b2crop_name, "Gash") | ///
	regex(b2crop_name, "Ghsh") | regex(b2crop_name, "ঘাস ")  | regex(b2crop_name, "ges") | regex(b2crop_name, "Napeir")
	
	
	
	recode b2crop -86/-79 = 27 if regex(b2crop_name, "Dal") | regex(b2crop_name, "dul") 
	
	recode b2crop -86/-79 = 1 if regex(b2crop_name, "Dhan")  
	
	recode b2crop -86/-79 = 39 if regex(b2crop_name, "Badam") 

	
	
	recode b2crop -86/-1 = 144
	
	replace b2crop_name = "" if b2crop != 144
	
	split b2crop_name, p(|)
	
	drop b2crop_name2 b2crop_name
	
	ren b2crop_name1 b7crop_name_oth
	
	la var b7crop_name_oth "Other crop name (specify)"
	
	la def b7season_id 1 "Boro (rabi) 2024" ///
	2 "Aman (kharif2 ) 2023" ///
	3 "Aus (kharif1 ) 2023" ///
	4 "Boro (rabi) 2022-2023" ///
	5 "Yearly" ///
	6 "N/A"
	
	la val b7season_id b7season_id
	
	la var b7season_id "Cultivation season"
	
	tempfile b7crops_re
	save `b7crops_re', replace
	
	drop b7sale_time*
	
	 
	
	merge m:1 KEY using `resurvey_data', keepusing(a1hhid_combined) nogen keep(3)
	
	
	/*
	
	 Result                      Number of obs
    -----------------------------------------
    Not matched                           329
        from master                        10  (_merge==1)
        from using                        319  (_merge==2)

    Matched                             1,183  (_merge==3)
    -----------------------------------------

	
	The HHs not matching from using are non agri HHs and HHs that did not
	harvest their crops yet or had yearly crops on the field. The HHs not 
	matching from the master are the duplicate submissions with different keys

	*/
	order a1hhid_combined b7season_id b7crops b2crop b7crop_name_oth ///
	b7qty_received_leased b7qty_consumed b7qty_given_away ///
	b7qty_animal_feed b7seed_next_year
	
	drop KEY_* 

	append using `b7crop_prod'
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b7_crop_production.dta", replace
		
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${final_data}${slash}SPIA_BIHS_2024_module_b7_crop_production.dta") label(English) dateformat(MDY) clear save("${final_data}${slash}SPIA_BIHS_2024_module_b7_crop_production.dta")

	la var b7crop_name_oth "Other crop name (specify)"
	
	la var b7season_id "Cultivation season"
	
	ren b2crop b7crop
	
	la var b7crop "Crop name"
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b7_crop_production.dta", replace
	
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b7saletime_repeat") firstrow clear
	
	drop if b7place_sale_1 == .
	
	drop b7place_sale_* b7sale_time_name SETOF*
	
	ren (PARENT_KEY KEY) (KEY_SALES KEY_PLACE)
	
	merge m:1 KEY_SALES using `b7crops_re', nogen
	
	drop if b7sale_time == "5"
	
	tempfile b7crops_sales_re
	save `b7crops_sales_re', replace
	
		
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b7place_sale_repeat") firstrow clear
	
	drop if mi(b7quantity_sold)
	
	drop KEY SETOFb7place_sale_repeat b7place_sale_name b7place_sale_oth
	
	recode b7place_sale_id 5 = 1
	
	ren PARENT_KEY KEY_PLACE
	
	merge m:1 KEY_PLACE using `b7crops_sales_re', nogen
	
	drop b7qty* b7seed_next_year b7sale_time_1 b7sale_time_2 b7sale_time_3 ///
	b7sale_time_4 b7sale_time_5
	
	merge m:1 KEY using `resurvey_data', keepusing(a1hhid_combined) nogen keep(3)
	
	keep a1hhid_combined b7crops b2crop b7crop_name_oth b7sale_time b7sale_time_id ///
	b7place_sale b7place_sale_id b7quantity_sold b7market_rate b7total_price ///
	b7distance_place_sale b7duration_place_sale b7season_id
	
	order a1hhid_combined b7season_id b7crops b2crop b7crop_name_oth b7sale_time b7sale_time_id ///
	b7place_sale b7place_sale_id b7quantity_sold b7market_rate b7total_price ///
	b7distance_place_sale b7duration_place_sale
	
	la def b7sale_time_id 1	"within one month" ///
						  2 "after one month" /// 
						  3	"after two months" /// 
						  4	"after three months" ///
						  5	"did not sell"
						  
	la val b7sale_time_id b7sale_time_id
	
	
	
	la def b7place_sale_id 1 "Farm gate" ///
						   2 "Village market (within own village)" ///
						   3 "Village market (outside of own village)" ///
						   4 "Town market"
	
	la val b7place_sale_id b7place_sale_id
	

	la var b7sale_time_id "How long after the harvest was it sold?"
	la var b7place_sale_id "Place of sale"
	
	append using `b7place_sale'
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b7_place_sale.dta", replace
	
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${final_data}${slash}SPIA_BIHS_2024_module_b7_place_sale.dta") label(English) dateformat(MDY) clear save("${final_data}${slash}SPIA_BIHS_2024_module_b7_place_sale.dta")

	la var b7sale_time_id "How long after the harvest was it sold?"
	la var b7place_sale_id "Place of sale"
	la var b7quantity_sold "Quantity sold"
	la var b7crop_name_oth "Other crop name (specify)"
	la var b7season_id "Cultivation season"
	
	ren b2crop b7crop
	
	la var b7crop "Crop name"
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b7_place_sale.dta", replace



	
	**# Module B8
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("b8grain_stock_repeat") firstrow clear
	drop if mi(b8jan)
	
	drop b8grain_stock_name KEY SETOFb8grain_stock_repeat
	
	ren PARENT_KEY KEY
	
	merge m:1 KEY using `main_data', nogen ///
	keepusing(a1hhid_combined b1repeat_count b8grain_stock b8gov_warehouse_use b8enroll_warehouse) keep(2 3) 
	
	tempfile grain_stock
	save `grain_stock', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("b8grain_stock_repeat") firstrow clear
	drop if mi(b8jan)
	
	drop b8grain_stock_name KEY SETOFb8grain_stock_repeat
	
	ren PARENT_KEY KEY
	
	merge m:1 KEY using `resurvey_data', nogen ///
	keepusing(a1hhid_combined b1repeat_count b8grain_stock b8gov_warehouse_use b8enroll_warehouse) keep(2 3) 
	
	append using `grain_stock'
	
	
	la def b8grain_stock_id 1 "Paddy" ///
							2 "Rice" ///
							3 "Wheat" ///
							4 "Maize" ///
							5 "Lentil" ///
							6 "Mustard" ///
							-98	"None of the above"
							
	la val b8grain_stock_id b8grain_stock_id
	
	bys a1hhid_combined: g serial = _n
	
	recode b8grain_stock_id . = -98
	
	recode b8gov_warehouse_use 0/1 = . if serial > 1
	recode b8enroll_warehouse 1/6 = . if serial > 1
	
	drop serial b1repeat_count
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_b8.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${temp_data}${slash}SPIA_BIHS_2024_module_b8.dta") label(English) dateformat(MDY) clear save("${temp_data}${slash}SPIA_BIHS_2024_module_b8.dta")
	
	la var b8grain_stock "Grains in stock (in kg) at any time during the past twelve months"
	la var b8grain_stock_id "Grain name"
	la var b8gov_warehouse_use "Usage of the Warehouse Receipt System in village or upazila"
	
	order a1hhid_combined b8grain_stock b8grain_stock_id, before(b8jan)
	
	order b8gov_warehouse_use b8enroll_warehouse, before(KEY)
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_b8.dta", replace
	
	
	**# Clean Module B6
	
	u "${temp_data}${slash}SPIA_BIHS_2024_module_b6.dta", clear
	
	la var b1plot_num "Plot number from plot roster B1"
	la var b2crop "Seedbed crop"
	
	drop if b6seedbed_decimal == 0
	
	order b2paddy_variety*, after(b2crop)
	
	
	rename b2paddy_variety b2paddy_variety1

	
	
	local others "_oth _oth_two _oth_three _oth_four"
	
	forvalues i = 1/4 {
		
		
		
		foreach var of local others  {
			
			recode b2paddy_variety`i' -86/-83=180 if paddy_variety`var' =="Banghobondhu" | paddy_variety`var' =="Bangabondu" ///
    | paddy_variety`var' =="Bangibondhu 100" | paddy_variety`var' =="Bangabandhu" | paddy_variety`var' =="Bangabondhu" ///
    | paddy_variety`var' =="Bangobando 100" | paddy_variety`var' =="Boggobondu" | paddy_variety`var' =="Bonggo bondhu" ///
    | paddy_variety`var' =="Bonggobondhu" | paddy_variety`var' =="Bongo bondhu dhan" | paddy_variety`var' =="Bongo bondhu" ///
    | paddy_variety`var' =="Bongobandhu" | paddy_variety`var' =="Bongobondhu 100" | paddy_variety`var' =="Bongobondhu" ///
    | paddy_variety`var' =="Bongobondu" | paddy_variety`var' =="bongobondhu 100"
	
	recode b2paddy_variety`i' -86/-83=181 if paddy_variety`var'=="Boro dhan jira" | paddy_variety`var'=="Jira" | ///
    paddy_variety`var'=="Jira (khato)" | paddy_variety`var'=="Jira 34" | paddy_variety`var'=="Jira Dhan" | ///
    paddy_variety`var'=="Jira dhan" | paddy_variety`var'=="Jira katari" | paddy_variety`var'=="Jira sail" | ///
    paddy_variety`var'=="Jira shahi" | paddy_variety`var'=="Jira shail" | paddy_variety`var'=="Jira14" | ///
    paddy_variety`var'=="Jira34" | paddy_variety`var'=="Jira52" | paddy_variety`var'=="Jirashail" | ///
    paddy_variety`var'=="Kato jira" | paddy_variety`var'=="Kato jirasail boro" | paddy_variety`var'=="Katojira boro" | ///
    paddy_variety`var'=="Katojira sail" | paddy_variety`var'=="Khato Jira" | paddy_variety`var'=="Rashian jira" | ///
    paddy_variety`var'=="jeera" | paddy_variety`var'=="jira" | paddy_variety`var'=="jira dhan" | paddy_variety`var'=="jiradan" | ///
    paddy_variety`var'=="90 Jira" | paddy_variety`var'=="Khato jira" | paddy_variety`var'=="Lomba jhira" | ///
    paddy_variety`var'=="Zira" | paddy_variety`var'=="Jarashal dhan" | paddy_variety`var'=="Jira" | paddy_variety`var'=="Jira dhan" | ///
    paddy_variety`var'=="Jira master" | paddy_variety`var'=="Jira34" | ///
    paddy_variety`var'=="Jirashail" | paddy_variety`var'=="Kalojira" | paddy_variety`var'=="Khato jira" | ///
    paddy_variety`var'=="Lomba jira" | paddy_variety`var'=="Shahi jira" | paddy_variety`var'=="Jeera" | ///
    paddy_variety`var'=="Jira" | paddy_variety`var'=="Jira90" | ///
    paddy_variety`var'=="Jirasahi" | paddy_variety`var'=="Lomba jira"
	
	recode b2paddy_variety`i' -86/-83=116 if paddy_variety`var'=="Aman sorna" | paddy_variety`var'=="Amon  Sorna 5" | ///
    paddy_variety`var'=="Amon Dhan Sorna 5" | paddy_variety`var'=="Amon Khato Sorna" | ///
    paddy_variety`var'=="Amon Sorna 5" | paddy_variety`var'=="Amon gotisorna" | paddy_variety`var'=="Giuti sorna" | ///
    paddy_variety`var'=="Ghotisarna" | paddy_variety`var'=="Goti Sorna dan" | paddy_variety`var'=="Goti Sorno" | ///
    paddy_variety`var'=="Guti Sorna" | paddy_variety`var'=="Guti atop sorna" | paddy_variety`var'=="Guti shorno" | ///
    paddy_variety`var'=="Guti sonna" | paddy_variety`var'=="Guti sorna" | paddy_variety`var'=="Guti sorno" | ///
    paddy_variety`var'=="Guti surna" | paddy_variety`var'=="Mota sorna" | paddy_variety`var'=="Nepaly sorna" | ///
    paddy_variety`var'=="Sada guti sorna dhan" | paddy_variety`var'=="Sorna" | paddy_variety`var'=="Sorna 5" | ///
    paddy_variety`var'=="Sorna 5 Amon" | paddy_variety`var'=="Sorna dan" | paddy_variety`var'=="Sorna dhan" | ///
    paddy_variety`var'=="Sorna- 5" | paddy_variety`var'=="Sorna-5" | paddy_variety`var'=="Sorna5" ///
    | paddy_variety`var'=="Sorna_5" | paddy_variety`var'=="Sorno 5" | paddy_variety`var'=="Sorno 5" ///
    | paddy_variety`var'=="Sornoguti" | paddy_variety`var'=="Sornoo gote" | paddy_variety`var'=="sorna" ///
    | paddy_variety`var'=="গুটি স্বর্ণা" | paddy_variety`var'=="স্বর্ন-৫" | paddy_variety`var'=="Goti sorno" ///
    | paddy_variety`var'=="Guti shorna" | paddy_variety`var'=="Guti sonna" | paddy_variety`var'=="Guti sorna" ///
    | paddy_variety`var'=="Guti surna" | paddy_variety`var'=="Khato sorna" | paddy_variety`var'=="Goti sorna" ///
    | paddy_variety`var'=="Shorna" | paddy_variety`var'=="Shorno - 5" | paddy_variety`var'=="Shorno -5" ///
    | paddy_variety`var'=="Shorno 5" | paddy_variety`var'=="Shorno five" | paddy_variety`var'=="Surna" ///
    | paddy_variety`var'=="Surna 5" | paddy_variety`var'=="Deshisarna" | paddy_variety`var'=="Ghotisarna" ///
    | paddy_variety`var'=="Sonna" | paddy_variety`var'=="Sonna 5" | paddy_variety`var'=="Sonra-5" | ///
    paddy_variety`var'=="Swarna pass" | paddy_variety`var'=="sorno" | paddy_variety`var'=="সরনা ৫"  | ///
    paddy_variety`var'=="Amon  Sorna 5" | paddy_variety`var'=="Amon Sorna 5" | paddy_variety`var'=="Amon.Sorna 5" | ///
    paddy_variety`var'=="Goti sorna" | paddy_variety`var'=="Goti sorno" | paddy_variety`var'=="Goti surna" | ///
    paddy_variety`var'=="Goti surna" | paddy_variety`var'=="Khato sorna" | paddy_variety`var'=="Sada sorna" | ///
    paddy_variety`var'=="Sada sorna dha" | paddy_variety`var'=="Sorna" | paddy_variety`var'=="Sorna 5" | ///
    paddy_variety`var'=="Sorna 5 amon" | paddy_variety`var'=="Sorna-5" | paddy_variety`var'=="Sorna/ benikochi" | ///
    paddy_variety`var'=="Sorno 5" | paddy_variety`var'=="Guti shorna" | paddy_variety`var'=="Guti sonna" | ///
    paddy_variety`var'=="Guti sonna" | paddy_variety`var'=="Guti sorna" | paddy_variety`var'=="Guti surna" | ///
    paddy_variety`var'=="Shorna-5" | paddy_variety`var'=="Surna" | paddy_variety`var'=="Surna 5" | ///
    | paddy_variety`var'=="Ghotisarna" | paddy_variety`var'=="Sonna" | paddy_variety`var'=="Sonna 5" | ///
    paddy_variety`var'=="Sonra-5" | paddy_variety`var'=="Sorna 5" | paddy_variety`var'=="Sorna mota" | paddy_variety`var'=="Ghotisarna" ///
    | paddy_variety`var'=="Sonna" | paddy_variety`var'=="Sonna 5" | paddy_variety`var'=="Sonra-5"

	recode b2paddy_variety`i' -86/-83=182 if paddy_variety`var'=="Boro teg gold" | paddy_variety`var'=="Taj gold" | ///
    paddy_variety`var'=="Tajgol" | paddy_variety`var'=="Tej gold" | paddy_variety`var'=="Tej gul" | paddy_variety`var'=="Tejghol" | ///
    paddy_variety`var'=="Tejgol" | paddy_variety`var'=="Tejgold" | paddy_variety`var'=="Tejgon" | ///
    paddy_variety`var'=="Tejgor jath" | paddy_variety`var'=="Tejgul" | paddy_variety`var'=="Tejgul Hybrid" | ///
    paddy_variety`var'=="Tez gul" | paddy_variety`var'=="tejgol"
	
	recode b2paddy_variety`i' -86/-83=183 if paddy_variety`var'=="Amon Mamun Dhan" | paddy_variety`var'=="Mamun" | ///
    paddy_variety`var'=="Mamun dhan" | paddy_variety`var'=="Mamun chikon"
    
	recode b2paddy_variety`i' -86/-83=184 if paddy_variety`var'=="Ronjit" | paddy_variety`var'=="Ronjit Eri" | ///
    paddy_variety`var'=="Ronjid" | paddy_variety`var'=="Ronjiet" | paddy_variety`var'=="Ranjit" | ///
    paddy_variety`var'=="Amon Ronjit Dhan" | paddy_variety`var'=="Amon Ronojit Dhan" | ///
    paddy_variety`var'=="Amon Ronzit Dhan" | paddy_variety`var'=="Ronjit Dhan" | ///
    paddy_variety`var'=="Ronjit amon" | paddy_variety`var'=="Rongit"
        
	recode b2paddy_variety`i' -86/-83=144 if paddy_variety`var'=="Bina 15"
    
	recode b2paddy_variety`i' -86/-83=146 if paddy_variety`var'=="Bina 17"
    
	recode b2paddy_variety`i' -86/-83=185 if paddy_variety`var'=="Boro Dhan Katari" | paddy_variety`var'=="Boro Katari Dhan" | ///
    paddy_variety`var'=="Katari" | paddy_variety`var'=="Katari Dhan" | paddy_variety`var'=="Kathari" | ///
    paddy_variety`var'=="Khathari 34" | paddy_variety`var'=="katari" | paddy_variety`var'=="Jamai katari" | ///
    paddy_variety`var'=="Katari bog" | paddy_variety`var'=="Katari bok" | paddy_variety`var'=="Katari vog" | ///
    paddy_variety`var'=="Katari vog (bogurar dan)" | paddy_variety`var'=="Katari vog," | paddy_variety`var'=="Katari vogh" | ///
    paddy_variety`var'=="Katarivog" | paddy_variety`var'=="Kathari bog" | paddy_variety`var'=="Katire Vog dan" | ///
    paddy_variety`var'=="katari vog" | paddy_variety`var'=="Katare boro" | paddy_variety`var'=="Katari bog" | ///
    paddy_variety`var'=="Katari bok" | paddy_variety`var'=="Catarivog" | paddy_variety`var'=="কাটারি"
    
	recode b2paddy_variety`i' -86/-83=127 if paddy_variety`var'=="Hira dhan" | paddy_variety`var'=="Hira" | ///
    paddy_variety`var'=="Hira 1"
    
	recode b2paddy_variety`i' -86/-83=111 if paddy_variety`var'=="Cui miniket" | paddy_variety`var'=="Minicket" | ///
    paddy_variety`var'=="Miniket" | paddy_variety`var'=="Red miniket" | paddy_variety`var'=="Rod Miniket" | ///
    paddy_variety`var'=="Rod Minikit" | paddy_variety`var'=="Rod miniket" | paddy_variety`var'=="Rotminiket" | ///
    paddy_variety`var'=="Rud Menikit"
    
	recode b2paddy_variety`i' -86/-83=186 if paddy_variety`var'=="Boro Dhan Hira 2" | paddy_variety`var'=="Boro Hira 2" | ///
    paddy_variety`var'=="Bro Dhan Hira 2" | paddy_variety`var'=="Hira 2" | paddy_variety`var'=="Hira-2" | ///
    paddy_variety`var'=="Hira2" | paddy_variety`var'=="Hera 2" | paddy_variety`var'=="হিরা ২"
    
	recode b2paddy_variety`i' -86/-83=187 if paddy_variety`var'=="Boro Dhan Hira 6" | paddy_variety`var'=="Hira6"
    
	recode b2paddy_variety`i' -86/-83=188 if paddy_variety`var'=="Hira 19" | paddy_variety`var'=="Hira=19"
    
	recode b2paddy_variety`i' -86/-83=189 if paddy_variety`var'=="Danegola.amon" | paddy_variety`var'=="Dani gold" | /// 
    paddy_variety`var'=="Dani golden" | paddy_variety`var'=="Danigol" | paddy_variety`var'=="Danigold" | ///
    paddy_variety`var'=="Danigoold" | paddy_variety`var'=="Danigul" | paddy_variety`var'=="Dhan Egal" | ///
    paddy_variety`var'=="Dhan Egol" | paddy_variety`var'=="Dhani Gold" | paddy_variety`var'=="Dhani gol" | ///
    paddy_variety`var'=="Dhani Gold, Amon" | paddy_variety`var'=="Dhani ghul" | paddy_variety`var'=="Dhani gold" | ///
    paddy_variety`var'=="Dhani gul" | paddy_variety`var'=="Dhani gur" | paddy_variety`var'=="Dhanigol" | ///
    paddy_variety`var'=="Dhanigold" | paddy_variety`var'=="Dhanigool" | paddy_variety`var'=="Dhanigul" | ///
    paddy_variety`var'=="Dhanigur" | paddy_variety`var'=="Dhanikul" | paddy_variety`var'=="Dhanikul dhan" | ///
    paddy_variety`var'=="Dhanikur" | paddy_variety`var'=="Dhini Gold" | paddy_variety`var'=="Dhnikur"
    
	recode b2paddy_variety`i' -86/-83=112 if paddy_variety`var'=="Faijam" | paddy_variety`var'=="Paijam" | paddy_variety`var'=="Payjam"
    
	recode b2paddy_variety`i' -86/-83=190 if paddy_variety`var'=="Jhono Raj" | paddy_variety`var'=="Jonak Raj" | ///
    paddy_variety`var'=="Jono crach" | paddy_variety`var'=="Jono rag" | paddy_variety`var'=="Jonocrash" | ///
    paddy_variety`var'=="Jonok  Raj" | paddy_variety`var'=="Jonok Raj" | paddy_variety`var'=="Jonok raj" | ///
    paddy_variety`var'=="Jonok raj," | paddy_variety`var'=="Jonok raz" | paddy_variety`var'=="Jonokraj" | ///
    paddy_variety`var'=="Jonokrajl,National Agrecare 4" | paddy_variety`var'=="Jonokraz" | ///
    paddy_variety`var'=="Jonoraj" | paddy_variety`var'=="jonok raj"
    
	recode b2paddy_variety`i' -86/-83=191 if paddy_variety`var'=="Shuvo lata" | paddy_variety`var'=="Shuvo lata (boro)" | ///
    paddy_variety`var'=="Shuvolota" | paddy_variety`var'=="Sobol lota boro" | paddy_variety`var'=="Sobor lota" | ///
    paddy_variety`var'=="Sobur lota" | paddy_variety`var'=="Sublota" | paddy_variety`var'=="Subol lota" | ///
    paddy_variety`var'=="Subol lota,uccho folonsil" | paddy_variety`var'=="Subolota" | ///
    paddy_variety`var'=="Subon lota" | paddy_variety`var'=="Suvol lota" | ///
    paddy_variety`var'=="Suvol lota( Boro)" | paddy_variety`var'=="shuvo lata" | paddy_variety`var'=="শুভলতা"
    
	recode b2paddy_variety`i' -86/-83=192 if regex(paddy_variety`var', "mota") | regex(paddy_variety`var', "Mota")


 
			
		}
		
		recode b2paddy_variety`i' -85/-83 = -86
	
	recode b2paddy_variety`i' 180 = 99
	
	label define b2paddy_variety`i' 1 "Chandina BR-1 (Boro/Aus)" ///
								2 "Mala BR-2 (Boro/Aus)" ///
								3 "Biplob BR-3 (Aus/Aman)" ///
								4 "Brishail BR-4* (Aman)" ///
								5 "Dulavhoge BR-5* (Aman)" ///
								6 "BR-6 (Boro/Aus)" ///
								7 "Bribalam BR-7 (Boro/Aus)"  ///
								8 "Asa BR-8 (Boro/Aus)" ///
								9 "Sufoza BR-9 (Boro/Aus)" ///
								10 "Progoti BR-10 (Aman)" ///
								11 "Mukta BR-11 (Aman)" ///
								12 "Moyna BR-12 (Boro/Aus)" ///
								13 "Gazi BR-14 (Boro/Aus)" ///
								14 "Mohini BR-15 (Boro/aus)" ///
								15 "Shahi Balam BR-16(Boro/Aus)" ///
								16 "Hasi BR-17 (Boro)" ///
								17 "Shahjalal BR-18 (Boro)" ///
								18 "Mongal BR-19 (Boro)" ///
								19 "Nizami BR-20 (Aus)"  ///
								20 "Niamat BR-21 (Aus)"  ///
								21 "Kiron BR-22* (Aman)"  ///
								22 "Dyshary BR-23 (Aman)"  ///
								23 "Rahmat BR-24 (Aus)" ///
                          24  "Noya Pajam BR-25 (Aman)" ///
                          25  "Sraboni BR-26 (Aus)" ///
                          26  "Bri Dhan BR-27 (Aus)" ///
                          27  "Bri Dhan BR-28 (Boro)" ///
                          28  "Bri Dhan BR-29 (Boro)" ///
                          29  "Bri Dhan BR-30 (Aman)" ///
                          30  "Bri Dhan BR-31 (Aman)" ///
                          31  "Bri Dhan BR-32 (Aman)" ///
                          32  "Bri Dhan BR-33 (Aman)" ///
                          33  "Bri Dhan BR-34 (Aman)" ///
                          34  "Bri Dhan BR-35 (Boro)" ///
                          35  "Bri Dhan BR-36 (Boro)" ///
                          36  "Bri Dhan BR-37 (Aman)" ///
                          37  "Bri Dhan BR-38 (Aman)" ///
                          38  "Bri Dhan BR-39 (Aman)" ///
                          39  "Bri Dhan BR-40 (Aman)" ///
                          40  "Bri Dhan BR-41 (Aman)" ///
                          41  "Bri Dhan BR-42 (Aus)" ///
                          42  "Bri Dhan BR-43 (Aus)" ///
                          43  "Bri Dhan BR-44 (Aman)" ///
                          44  "Bri Dhan BR-45 (Boro)" ///
                          45  "Bri Dhan BR-46 (Aman)" ///
                          46  "Bri Dhan BR-47 (Boro)" ///
                          47  "Bri Dhan BR-48 (Aus)" ///
                          48  "Bri Dhan BR-49 (Aman)" ///
                          49  "Bri Dhan BR-50 (Banglamoti) (Boro)" ///
                          50  "Bri Dhan BR-51 (Aman)" ///
                          51  "Bri Dhan BR-52 (Aman)" ///
                          52  "Bri Dhan BR-53 (Aman)" ///
                          53  "Bri Dhan BR-54 (Aman)" ///
                          54  "Bri Dhan BR-55 (Boro/Aus)" ///
                          55  "Bri Dhan BR-56 (Aman)" ///
                          56  "Bri Dhan BR-57 (Aman)" ///
                          57  "Bri Dhan BR-58 (Boro)" ///
                          58  "Bri Dhan BR-59 (Boro)" ///
                          59  "Bri Dhan BR-60 (Boro)" ///
                          60  "Bri Dhan BR-61 (Boro)" ///
                          61  "Bri Dhan BR-62 Zinc Enriched (Aman)" ///
                          62  "Bri Dhan BR-63 Shorubalam (Boro)" ///
                          63  "Bri Dhan BR-64 Zinc Enriched (Boro)" ///
                          64  "Bri Dhan BR-65 (Aus)" ///
                          65  "Bri Dhan BR-66 Drought Tolerant (Aman)" ///
                          66  "Bri Dhan BR-67 Saline Tolerant (Boro)" ///
                          67  "Bri Dhan BR-68 (Boro)" ///
                          68  "Bri Dhan BR-69 Weed Resistant (Boro)" ///
                          69  "Bri Dhan 70" ///
                          70  "Bri Dhan 71" ///
                          71  "Bri Dhan 72" ///
                          72  "Bri Dhan 73" ///
                          73  "Bri Dhan 74" ///
			  			 74  "Bri Dhan 75" ///
                         75  "Bri Dhan 76" ///
                         76  "Bri Dhan 77" ///
                         77  "Bri Dhan 78" ///
                         78  "Bri Dhan 79" ///
                         79  "Bri Dhan 80" ///
                         80  "Bri Dhan 81" ///
                         81  "Bri Dhan 82" ///
                         82  "Bri Dhan 83" ///
                         83  "Bri Dhan 84" ///
                         84  "Bri Dhan 85" ///
                         85  "Bri Dhan 86" ///
                         86  "Bri Dhan 87" ///
                         87  "Bri Dhan 88" ///
                         88  "Bri Dhan 89" ///
                         89  "Bri Dhan 90" ///
                         90  "Bri Dhan 91" ///
                         91  "Bri Dhan 92" ///
                         92  "Bri Dhan 93" ///
                         93  "Bri Dhan 94" ///
                         94  "Bri Dhan 95" ///
                         95  "Bri Dhan 96" ///
                         96  "Bri Dhan 97" ///
                         97  "Bri Dhan 98" ///
                         98  "Bri Dhan 99" ///
                         99  "Bri Dhan 100" ///
                         100 "Bri Dhan 101" ///
                         101 "Bri Dhan 102" ///
                         102 "Bri Dhan 103" ///
                         103 "Bri Dhan 104" ///
                         104 "Bri Dhan 105" ///
                         105 "Bri Dhan 106" ///
                         106 "Nerica(new rice for africa)" ///
                         107 "Haridhan" ///
                         108 "Asiruddin" ///
                         109 "Kajallata" ///
                         110 "Khude kajal" ///
                         111 "Miniket" ///
                         112 "Paijam" ///
                         113 "Shapla" ///
                         114 "Bashmati" ///
                         115 "Jamaibabu" ///
                         116 "Guti/rajshahi/lalshorna" ///
                         117 "Bhojon(white/coarse)" ///
                         118 "Binni dhan" ///
                         119 "Tepi dhan" ///
                         120 "Alok" ///
                         121 "Sonar bangla" ///
                         122 "Jagoron" ///
                         123 "Shakti 1" ///
                         124 "Shakti 2" ///
                         125 "Aloron 1" ///
                         126 "Aloron 2" ///
                         127 "Hira" ///
                         128 "ACI 5" ///
                         129 "Lal Teer" ///
                         130 "BINA 1" ///
                         131 "BINA 2" ///
                         132 "BINA 3" ///
                         133 "BINA 4" ///
                         134 "BINA 5" ///
                         135 "BINA 6(Boro/aus)" ///
                         136 "BINA 7(Aman)" ///
                         137 "BINA 8(Boro/Aus)" ///
                         138 "BINA 9" ///
                         139 "BINA 10 (Boro)" ///
                         140 "BINA 11(aman/aus)" ///
                         141 "BINA 12 (aman)" ///
                         142 "BINA 13 (aman)" ///
                         143 "BINA 14 (boro)" ///
                         144 "BINA 15 (aman)" ///
                         145 "BINA 16(aman)" ///
                         146 "BINA 17" ///
                         147 "BINA 18" ///
                         148 "BINA 19" ///
                         149 "BINA 20" ///
                         150 "BINA 21" ///
                         151 "BINA 22" ///
                         152 "BINA 23" ///
                         153 "BINA 24" ///
                         154 "BINA 25" ///
                         155 "Bri Hybrid-1(Boro)" ///
                         156 "Bri Hybrid-2(Boro)" ///
                         157 "Bri Hybrid-3(Boro)" ///
                         158 "Bri Hybrid-4(Boro Aman)" ///
                         159 "Bri hybrid 5" ///
                         160 "Bri hybrid 6" ///
                         161 "Bri hybrid 7" ///
                         162 "Bri hybrid 8" ///
                         163 "Binashail(aman)" ///
                         164 "Iratom 24(Boro)" ///
                         165 "Taj" ///
                         166 "HS" ///
                         167 "Shonali" ///
                         168 "Surma" ///
                         169 "Padma" ///
                         170 "Bijoy" ///
                         171 "Borkot" ///
                         172 "Raja" ///
                         173 "Chitra" ///
                         174 "Shobujmoti" ///
                         175 "Kajol" ///
                         176 "Rajkumar" ///
                         177 "Robi" ///
                         178 "BU Aromatic Hybrid Dhan-1" ///
                         179 "BU Aromatic Dhan-2" ///
						180 "Bongobondhu" ///
						181 "Jira" ///
						182 "Tej gold" ///
						183 "Mamun (Aman)" ///
						184 "Ronjit" ///
						185 "Katari" ///
						186 "Hira 2" ///
						187 "Hira 6" ///
						188 "Hira 19" ///
						189 "Dhani gold/Danigol/Dhanikul/Dhanigul" ///
						190 "Jonok Raj" ///
						191 "Shuvo Lota" ///
						192 "Mota (round bold seed)" ///
						-86 "Others", modify
						
						la val b2paddy_variety`i' b2paddy_variety`i'
						
			la var b2paddy_variety`i' "Paddy variety `i'"
		
		
		ren b2paddy_variety`i' b6seedbed_paddy`i'
		
	}
		
	recode b6seedbed_decimal 360 = .
	
	drop b6crop_repeat_count paddy_variety* b6crop_season_*
	
	ren b2crop b6seedbed_crop
	
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b6.dta", replace
	
	**# Clean Module B7	
	u "${final_data}${slash}SPIA_BIHS_2024_module_b7_place_sale.dta", clear
	
	drop if b7crop == 144
	
	egen crop_sum = concat(a1hhid_combined b7season_id b7crop), p(.)
	
	collapse(sum) b7tot_sold = b7quantity_sold (first) a1hhid_combined, by(crop_sum)
	
	tempfile crop_sales
	save `crop_sales', replace
		
	u "${final_data}${slash}SPIA_BIHS_2024_module_b7_crop_production.dta", clear

	drop if b7crop == 144
	
	egen crop_sum = concat(a1hhid_combined b7season_id b7crop), p(.)
	
	
	duplicates drop crop_sum b7qty_received_leased b7qty_consumed b7qty_given_away b7qty_animal_feed b7seed_next_year, force
	
	collapse(sum) b7qty_received_leased b7qty_consumed b7qty_given_away b7qty_animal_feed b7seed_next_year (first) a1hhid_combined, by(crop_sum)
	
	merge 1:1 crop_sum using `crop_sales', nogen
	
	egen tot_distribution = rowtotal(b7tot_sold b7qty_consumed b7qty_given_away b7qty_animal_feed b7seed_next_year)
	
	tempfile crop_prod
	save `crop_prod', replace
	
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	keep if agri_control_household == 1
	
	drop if b2crop == 144 | b2crop == .
	
	egen b3qty_given_harvest = rowtotal(b3qty_paid_owner b3qty_paid_irrigation b3qty_paid_rent)

	gen b3qty_net_harvest = b3qty_harvest - b3qty_given_harvest
	
	egen b3int_qty_given_harvest = rowtotal(b3int_qty_paid_owner b3int_qty_paid_irrigation b3int_qty_paid_rent)
	
	gen b3int_qty_net_harvest = b3int_qty_harvest - b3int_qty_given_harvest
	
	
	order b3qty_given_harvest b3qty_net_harvest, after(b3qty_paid_rent)
	order b3int_qty_given_harvest b3int_qty_net_harvest, after(b3int_qty_paid_rent)
	
	la var b3qty_given_harvest "Harvest (kg) given away to owner, irrigation, rent for main crop"
	la var b3int_qty_given_harvest "Harvest (kg) given away to owner, irrigation, rent for intercrop"
	la var b3qty_net_harvest "Harvest (kg) after giving to owner, irrigation, rent for main crop"
	la var b3int_qty_net_harvest "Harvest (kg) after giving to owner, irrigation, rent for intercrop"
	
	egen crop_sum = concat(a1hhid_combined b2crop_season b2crop), p(.)
	
	collapse(sum) b3qty_harvest b3qty_net_harvest (first) a1hhid_combined b2crop_season b2crop (max) b2harvestdate b2harvestweek, by(crop_sum) 

	tempfile main_yield
	save `main_yield', replace 
	
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	
	keep if agri_control_household == 1
	
	drop if b2intercrop == 144 | b2intercrop == . 
	
	egen b3qty_given_harvest = rowtotal(b3qty_paid_owner b3qty_paid_irrigation b3qty_paid_rent)
	
	gen b3qty_net_harvest = b3qty_harvest - b3qty_given_harvest
	
	egen b3int_qty_given_harvest = rowtotal(b3int_qty_paid_owner b3int_qty_paid_irrigation b3int_qty_paid_rent)
	
	gen b3int_qty_net_harvest = b3int_qty_harvest - b3int_qty_given_harvest
	
	egen crop_sum = concat(a1hhid_combined b2crop_season b2intercrop), p(.)
	
	collapse(sum) b3int_qty_harvest b3int_qty_net_harvest (first) a1hhid_combined b2crop_season b2crop (max) b2harvestdate b2harvestweek, by(crop_sum)
	
	ren (b3int_qty_harvest b3int_qty_net_harvest) (b3qty_harvest b3qty_net_harvest)
	
	append using `main_yield'
	
	collapse(sum) b3qty_harvest b3qty_net_harvest (first) a1hhid_combined b2crop_season b2crop (max) b2harvestdate b2harvestweek, by(crop_sum)
	
	merge 1:1 crop_sum using `crop_prod' //, nogen
	
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen
	
	keep if _merge == 3
	
	egen tot_prod = rowtotal(b7qty_received_leased b3qty_harvest)
	egen tot_prod_net = rowtotal(b7qty_received_leased b3qty_net_harvest)
	
	g diff = tot_prod - tot_distribution
	
	g diff_net = tot_prod_net - tot_distribution
	
	**# Clean Module B8
	
	u "${temp_data}${slash}SPIA_BIHS_2024_module_b8.dta", clear
	
	egen total_grain = rowtotal(b8jan b8dec b8nov b8oct b8sept b8august b8july ///
	b8june b8may b8april b8march b8february)
	
	recode b8july 40000 = 4000 if a1hhid_combined == "3333"
	recode b8april 27000 = 2700 if a1hhid_combined == "3488"
	recode b8june 200200 = 200 if a1hhid_combined == "3850"
	recode b8dec 200200 = 200 if a1hhid_combined == "1206"
	recode b8nov 32080 = 80 if a1hhid_combined == "3931"
	
	drop total_grain
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_b8.dta", replace
	
	**# Module C1	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("c1fertilizer_repeat") firstrow clear
	drop KEY PARENT_KEY
	
	replace c1fertilizer_name = "Urea" if c1fertilizer_name == "ইউরিয়া" 
	replace c1fertilizer_name = "TSP" if c1fertilizer_name == "টিএসপি"
	replace c1fertilizer_name = "Muriate of Potas"	if c1fertilizer_name == "মিউরেট অফ পটাশ"
	replace c1fertilizer_name = "cow-dung/green manure"	if c1fertilizer_name == "গরুর গোবর"
	replace c1fertilizer_name = "DAP" if c1fertilizer_name == "ডিএপি"
	replace c1fertilizer_name = "Other chemical fertilizer" if c1fertilizer_name == "অন্যান্য কেমিকাল সার"

	
	reshape wide c1fertilizer_name c1fertilizer_type c1fertilizer_type_oth c1fert_n_time_before ///
	c1fert_amt_before c1fert_use_gap_before c1fert_n_time_after c1fert_amt_after ///
	c1fert_use_gap_after, i(SETOFc1fertilizer_repeat) j(c1fertilizer_id)
	
	forvalues i = 1/6 {
			la def c1fertilizer_type`i' 1 "Soil-based Organic" ///
										2 "Soil-based Inorganic" ///
										3 "Foliar feeds Organic" ///
										4 "Foliar feeds Inorganic" ///
										-96 "Others(specify)"
			
			la val c1fertilizer_type`i' c1fertilizer_type`i'
			
	}


	
	tempfile c1fert
	save `c1fert', replace
		
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("c1pesticide_repeat") firstrow clear
	drop KEY PARENT_KEY 
	
	reshape wide c1pesticide_name c1pesticide_dosage c1pesticide_unit c1pesticide_n_timee ///
	c1pesticideuse_reason, i(SETOFc1pesticide_repeat) j(c1pesticide_id)
	
	
	forvalues i = 1/6 { 
						la def c1pesticide_unit`i' 1 "ml" 2 "gram"
						la val c1pesticide_unit`i' c1pesticide_unit`i'
						
						la def c1pesticideuse_reason`i' 1 "Preventive" 2 "Protective" ///
						3 "Both preventive and protective"
						la val c1pesticideuse_reason`i' c1pesticideuse_reason`i'						
	}
	
	tempfile c1pest
	save `c1pest', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx", sheet("module_c1") firstrow clear
	drop KEY c1zerotillage_type_oth c1fertilizer_repeat_count ///
	c1pesticide_repeat_count c1seasonname
	
	ren PARENT_KEY KEY
	
	la def c1season_id 1 "Boro (rabi) 2024" ///
						2 "Aman (kharif2) 2023" ///
						3 "Aus (kharif1) 2023" ///
						4 "Boro (rabi) 2022-2023" ///
						5 "Yearly"
						
	la val c1season_id c1season_id

	
	merge m:1 SETOFc1pesticide_repeat using `c1pest', nogen
		
	merge m:1 SETOFc1fertilizer_repeat using `c1fert', nogen
	
	tempfile c1
	save `c1', replace
	
	
	u `main_data', clear
	keep a1hhid_combined  c1* KEY

	drop c1plot_area c1land_id c1split_clean c1land_season_* *_list c1landname_new ///
	c1season_random
		
	foreach var of varlist c1borocrop c1amancrop c1auscrop c1boro23crop c1yearlycrop {
	split `var', p(|)
	
	drop `var' `var'2
	ren `var'1 `var'
	
	}
	
	order c1boro* c1aman* c1aus* c1boro23* c1yearly*, after(c1land_select)
	order c1boro23_crop, before(c1boro23crop)
	
	merge 1:m KEY using `c1', nogen keep(3)
	
	
	drop if c1land_select == .
	
	drop c1crop_season_* KEY c1fertilizer_1 c1fertilizer_2 c1fertilizer_3 ///
	c1fertilizer_4 c1fertilizer_5 c1fertilizer_6 SETOF*
	
	order c1fertilizer_oth, before(c1fertilizer_type6)
	
	ren c1fertilizer_oth c1other_fertilizer_name_6
	
	
	tempfile main_c1
	save `main_c1', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("c1fertilizer_repeat") firstrow clear
	drop KEY PARENT_KEY
	
	replace c1fertilizer_name = "Urea" if c1fertilizer_name == "ইউরিয়া" 
	replace c1fertilizer_name = "TSP" if c1fertilizer_name == "টিএসপি"
	replace c1fertilizer_name = "Muriate of Potas"	if c1fertilizer_name == "মিউরেট অফ পটাশ"
	replace c1fertilizer_name = "cow-dung/green manure"	if c1fertilizer_name == "গরুর গোবর"
	replace c1fertilizer_name = "DAP" if c1fertilizer_name == "ডিএপি"
	replace c1fertilizer_name = "Other chemical fertilizer" if c1fertilizer_name == "অন্যান্য কেমিকাল সার"

	
	reshape wide c1fertilizer_name c1fertilizer_type c1fertilizer_type_oth c1fert_n_time_before ///
	c1fert_amt_before c1fert_use_gap_before c1fert_n_time_after c1fert_amt_after ///
	c1fert_use_gap_after, i(SETOFc1fertilizer_repeat) j(c1fertilizer_id)
	
	forvalues i = 1/6 {
			la def c1fertilizer_type`i' 1 "Soil-based Organic" ///
										2 "Soil-based Inorganic" ///
										3 "Foliar feeds Organic" ///
										4 "Foliar feeds Inorganic" ///
										-96 "Others(specify)"
			
			la val c1fertilizer_type`i' c1fertilizer_type`i'
			
	}


	
	tempfile c1fert_re
	save `c1fert_re', replace
		
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("c1pesticide_repeat") firstrow clear
	drop KEY PARENT_KEY 
	
	reshape wide c1pesticide_name c1pesticide_dosage c1pesticide_unit c1pesticide_n_timee ///
	c1pesticideuse_reason, i(SETOFc1pesticide_repeat) j(c1pesticide_id)
	
	
	forvalues i = 1/5 { 
						la def c1pesticide_unit`i' 1 "ml" 2 "gram"
						la val c1pesticide_unit`i' c1pesticide_unit`i'
						
						la def c1pesticideuse_reason`i' 1 "Preventive" 2 "Protective" ///
						3 "Both preventive and protective"
						la val c1pesticideuse_reason`i' c1pesticideuse_reason`i'						
	}
	
	tempfile c1pest_re
	save `c1pest_re', replace
	
	import excel using "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx", sheet("module_c1") firstrow clear
	drop KEY c1zerotillage_type_oth c1fertilizer_repeat_count ///
	c1pesticide_repeat_count c1seasonname
	
	ren PARENT_KEY KEY
	
	la def c1season_id 1 "Boro (rabi) 2024" ///
						2 "Aman (kharif2) 2023" ///
						3 "Aus (kharif1) 2023" ///
						4 "Boro (rabi) 2022-2023" ///
						5 "Yearly"
						
	la val c1season_id c1season_id

	
	merge m:1 SETOFc1pesticide_repeat using `c1pest_re', nogen
		
	merge m:1 SETOFc1fertilizer_repeat using `c1fert_re', nogen
	
	tempfile c1_re
	save `c1_re', replace
	
	
	u `resurvey_data', clear
	keep a1hhid_combined  c1* KEY

	drop c1land_season_* *_list c1landname_new
		
	foreach var of varlist c1borocrop c1amancrop c1auscrop c1boro23crop c1yearlycrop {
	split `var', p(|)
	
	drop `var' `var'2
	ren `var'1 `var'
	
	}
	
	order c1boro* c1aman* c1aus* c1boro23* c1yearly*, after(c1land_select)
	order c1boro23_crop, before(c1boro23crop)
	
	merge 1:m KEY using `c1_re', nogen keep(3)
	
	
	drop if c1land_select == .
	
	drop c1crop_season_* KEY c1fertilizer_1 c1fertilizer_2 c1fertilizer_3 ///
	c1fertilizer_4 c1fertilizer_5 c1fertilizer_6 SETOF*
	
	order c1fertilizer_oth, before(c1fertilizer_type6)
	
	ren c1fertilizer_oth c1other_fertilizer_name_6
	
	tostring c1fertilizer_type_oth*, replace
	
	append using `main_c1'
	
	
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_c1.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${final_data}${slash}SPIA_BIHS_2024_module_c1.dta") label(English) dateformat(MDY) clear save("${final_data}${slash}SPIA_BIHS_2024_module_c1.dta")
	
	la var c1zerotillage_type "What kind of zero tillage system did you use on the land?"
	
	drop c1plot_type c1soil_type
	
	order c1fertilizer_name1 c1fertilizer_type1 c1fertilizer_type_oth1 ///
	c1fert_n_time_before1 c1fert_amt_before1 c1fert_use_gap_before1 ///
	c1fert_n_time_after1 c1fert_amt_after1 c1fert_use_gap_after1 ///
	c1fertilizer_name2 c1fertilizer_type2 c1fertilizer_type_oth2 ///
	c1fert_n_time_before2 c1fert_amt_before2 c1fert_use_gap_before2 ///
	c1fert_n_time_after2 c1fert_amt_after2 c1fert_use_gap_after2 ///
	c1fertilizer_name3 c1fertilizer_type3 c1fertilizer_type_oth3 ///
	c1fert_n_time_before3 c1fert_amt_before3 c1fert_use_gap_before3 ///
	c1fert_n_time_after3 c1fert_amt_after3 c1fert_use_gap_after3 ///
	c1fertilizer_name4 c1fertilizer_type4 c1fertilizer_type_oth4 ///
	c1fert_n_time_before4 c1fert_amt_before4 c1fert_use_gap_before4 ///
	c1fert_n_time_after4 c1fert_amt_after4 c1fert_use_gap_after4 ///
	c1fertilizer_name5 c1fertilizer_type5 c1fertilizer_type_oth5 ///
	c1fert_n_time_before5 c1fert_amt_before5 c1fert_use_gap_before5 ///
	c1fert_n_time_after5 c1fert_amt_after5 c1fert_use_gap_after5 ///
	c1fertilizer_name6 c1other_fertilizer_name_6 c1fertilizer_type6 ///
	c1fertilizer_type_oth6 c1fert_n_time_before6 c1fert_amt_before6 ///
	c1fert_use_gap_before6 c1fert_n_time_after6 c1fert_amt_after6 ///
	c1fert_use_gap_after6, after(c1fertilizer)
	
	order c1other_fertilizer_name_6, before(c1fertilizer_type6)
	
	la var c1other_fertilizer_name_6 "Name of other fertilizer"
	
	order c1pesticide_name1 c1pesticide_dosage1 c1pesticide_unit1 c1pesticide_n_timee1 ///
	c1pesticideuse_reason1 c1pesticide_name2 c1pesticide_dosage2 c1pesticide_unit2 ///
	c1pesticide_n_timee2 c1pesticideuse_reason2 c1pesticide_name3 c1pesticide_dosage3 ///
	c1pesticide_unit3 c1pesticide_n_timee3 c1pesticideuse_reason3 c1pesticide_name4 ///
	c1pesticide_dosage4 c1pesticide_unit4 c1pesticide_n_timee4 c1pesticideuse_reason4 ///
	c1pesticide_name5 c1pesticide_dosage5 c1pesticide_unit5 c1pesticide_n_timee5 ///
	c1pesticideuse_reason5 c1pesticide_name6 c1pesticide_dosage6 c1pesticide_unit6 ///
	c1pesticide_n_timee6 c1pesticideuse_reason6, after(c1n_pesticide)
	
	forvalues i = 1/6 {
				la var c1fertilizer_type`i' "What type of fertilizer is it?"
				la var c1fertilizer_type_oth`i' "Specify other"
				la var c1fert_n_time_before`i' "How many times did you apply it before planting?"
				la var c1fert_amt_before`i' "How much amount did you use (kg) before planting? (on avg)"
				la var c1fert_use_gap_before`i' "Typically how many days before planting did you use the fertilizer?"
				la var c1fert_n_time_after`i' "How many times did you apply it after planting?"
				la var c1fert_amt_after`i' "How much amount did you use (kg) after planting? (on avg)"
				la var c1fert_use_gap_after`i' "Typically how many days after planting did you use the fertilizer?"

			
	}
	
	forvalues i = 1/6 {
		
				la var c1pesticide_name`i' "Name of pesticide, insecticide, or herbicide"
				la var c1pesticide_dosage`i' "What was the dosage you used?"
				la var c1pesticide_unit`i' "What is the unit of pesticide usage"
				la var c1pesticide_n_timee`i' "How many times did you apply it?"
				la var c1pesticideuse_reason`i' "Chemical pesticide use preventive/responsive"
	
	}
	
	drop c1plotsize_decimal
	
	save "${final_data}${slash}SPIA_BIHS_2024_module_c1.dta", replace
	
	
	**# Preparing module C2-4 dataset
	u `main_data', clear
	keep if scan_barcode_one != ""
	keep a1hhid_combined c2* c3* c4* c1land_select c1plot_area scan* 
	
	tostring c2reasonseed_mixed_oth, replace 
	tempfile main_c2
	save `main_c2', replace
	
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(data) clear	
	duplicates drop a1hhid_combined, force // Same interview got submitted two times for some reason, dropping the duplicates

	keep a1hhid_combined c2* c3* c4* b2tot_boro a1recruitment c1land_select
	
	ren b2tot_boro b2tot_boro_re 
	merge 1:1 a1hhid_combined using `main_pre', nogen keep(3) keepusing(c1plot_area scan* b2tot_boro)
	la var b2tot_boro_re "b2tot_boro_re"
	
	preserve
	keep if a1recruitment != 1 & scan_barcode_one != ""
	keep a1hhid_combined scan*
	export excel "${dna_table}${slash}resurvey_refused_barcodes.xlsx", sheet(data) firstrow(variables) replace
	
	restore 
	
	count if b2tot_boro_re > 0 & b2tot_boro == 0
		
	g c2new_boro = `r(N)'
	
	la var c2new_boro "N of non boro HH in survey but boro in resurvey"
	
	preserve
	
	keep if  scan_barcode_one != "" 
	
	keep if a1recruitment == 1 & b2tot_boro_re == 0 & b2tot_boro > 0
	
	keep a1hhid_combined scan_barcode*
	
	ren (scan_barcode_one scan_barcode_two) (scan_barcode_1 scan_barcode_2)
	
	reshape long scan_barcode_, i(a1hhid_combined) j(barcode_serial)
	export excel "${dna_table}${slash}boro_main_not_boro_resurvey.xlsx", sheet(data) firstrow(variables) replace
	levelsof scan_barcode_, local(not_boro)
	
	restore
	drop b2tot_boro b2tot_boro_re
	
	keep if scan_barcode_one != ""
	tostring c2image_intervariety, replace
	append using `main_c2'
	
	recode a1recruitment . = 1
	g two_sample = (scan_barcode_two != "")
	la var two_sample "Two samples have been taken from this plot"
	la def two_sample 0 "No" 1 "Yes"
	la val two_sample two_sample
	ren (scan_barcode_one scan_barcode_two) (scan_barcode_1 scan_barcode_2)
	
	reshape long scan_barcode_, i(a1hhid_combined) j(barcode_serial)
	
	
	foreach val of local not_boro {
	replace scan_barcode_ = "" if regex(scan_barcode_, "`val'")
	}
	
	keep if scan_barcode_ != ""
	
	bys a1hhid_combined: g n = _n
	
	count if n == 1 & a1recruitment == 1
	
	g c2n_boro = `r(N)'
	
	la var c2n_boro "N of boro HH before the resurvey HH addition"
	
	g c2n_boro_final = c2n_boro + c2new_boro
	
	la var c2n_boro_final "Number of total boro HH in 2023-24"

	local drop_barcode "3265 1245 2722 2941 3479 1795 0088 2870 2471 0078 1966 1998" //dropping blank or fungus samples
	
	preserve
	import excel "${dna_data}${slash}missing_barcode_list_replated.xlsx" , firstrow sheet(Sheet1) clear
	drop if FoundYesNo == "Yes" | FoundYesNo == "yes" |  FoundYesNo == "before_fungus" ///
	|  FoundYesNo == "blank_before"
	
	levelsof barcode, local(replate)
	restore 
	
	
	foreach val of local drop_barcode {
	replace scan_barcode_ = "" if regex(scan_barcode_, "`val'")
	}
	

	foreach val of local replate {
	replace scan_barcode_ = "" if regex(scan_barcode_, "`val'")
	}
	
	
	duplicates tag scan_barcode_, gen(dup2)
	duplicates tag a1hhid_combined scan_barcode_, gen(dup)
	
	preserve 
	keep a1hhid_combined scan_barcode_ barcode_serial dup
	
	keep if dup == 1
	drop dup
	export excel "${dna_table}${slash}duplicate_barcode_same_hh.xlsx", sheet(data) firstrow(variables) replace
	
	restore 
	
	replace scan_barcode_ = "" if dup2 > 0 & dup == 0
	replace scan_barcode_ = "" if dup2 > 0 & barcode_serial == 2
	
	order a1hhid_combined scan_barcode_ dup2
	
	keep if a1recruitment == 1
	
	drop a1recruitment dup* n
	
	drop if scan_barcode_ == ""
	
	reshape wide scan_barcode_, i(a1hhid_combined) j(barcode_serial)
	
	
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_c2_4", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
data("${temp_data}${slash}SPIA_BIHS_2024_module_c2_4") label(English) dateformat(MDY) clear save("${temp_data}${slash}SPIA_BIHS_2024_module_c2_4")
	
	ren (c1plot_area two_sample scan_barcode_1 scan_barcode_2 c1land_select) ///
	(c2plot_area c2two_sample c2scan_barcode_1 c2scan_barcode_2 c2land_select)
	
	order a1hhid_combined c2* c3* c4*
	
	save "${temp_data}${slash}SPIA_BIHS_2024_module_c2_4", replace
	**# Cleaning Module C2-4
	u  "${temp_data}${slash}SPIA_BIHS_2024_module_c2_4", clear
	
	
	// cleaning paddy varieties
	foreach var of varlist c2paddymainvariety c2paddyintervariety {
	split `var', p(|) 
	}
	
	drop c2paddymainvariety2 c2paddyintervariety2 c2paddymainvariety c2paddyintervariety
	
	ren (c2paddymainvariety1 c2paddyintervariety1) (c2paddymainvariety c2paddyintervariety)
	
	recode c2paddy_mainvariety -86/-83=180 if c2paddymainvariety=="Banghobondhu" | c2paddymainvariety=="Bangabondu" ///
    | c2paddymainvariety=="Bangibondhu 100" | c2paddymainvariety=="Bangabandhu" | c2paddymainvariety=="Bangabondhu" ///
    | c2paddymainvariety=="Bangobando 100" | c2paddymainvariety=="Boggobondu" | c2paddymainvariety=="Bonggo bondhu" ///
    | c2paddymainvariety=="Bonggobondhu" | c2paddymainvariety=="Bongo bondhu dhan" | c2paddymainvariety=="Bongo bondhu" ///
    | c2paddymainvariety=="Bongobandhu" | c2paddymainvariety=="Bongobondhu 100" | c2paddymainvariety=="Bongobondhu 100" ///
    | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondu" | c2paddymainvariety=="bongobondhu 100"

	recode c2paddy_mainvariety -85/-83=180 if c2paddymainvariety=="Bonggobondhu" | c2paddymainvariety=="Bongobando" ///
    | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondhu 100" | c2paddymainvariety=="Bangobondhu" ///
	| c2paddymainvariety=="bongobondhu 100" | c2paddymainvariety=="Banghobondhu" | c2paddymainvariety=="Bangabondu" ///
    | c2paddymainvariety=="Bangibondhu 100" | c2paddymainvariety=="Bangabandhu" | c2paddymainvariety=="Bangabondhu" ///
    | c2paddymainvariety=="Bangobando 100" | c2paddymainvariety=="Boggobondu" | c2paddymainvariety=="Bonggo bondhu" ///
    | c2paddymainvariety=="Bonggobondhu" | c2paddymainvariety=="Bongo bondhu dhan" | c2paddymainvariety=="Bongo bondhu" ///
    | c2paddymainvariety=="Bongobandhu" | c2paddymainvariety=="Bongobondhu 100" | c2paddymainvariety=="Bongobondhu 100" ///
    | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondu" | c2paddymainvariety=="bongobondhu 100"

	recode c2paddy_mainvariety -84/-83=180 if c2paddymainvariety=="Bonggobondhu" | c2paddymainvariety=="Bonggobondu" ///
    | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondo" | c2paddymainvariety=="Boro 303, bongobonbu" | c2paddymainvariety=="bongobondhu 100" ///
    | c2paddymainvariety=="Banghobondhu" | c2paddymainvariety=="Bangabondu" ///
    | c2paddymainvariety=="Bangibondhu 100" | c2paddymainvariety=="Bangabandhu" | c2paddymainvariety=="Bangabondhu" ///
    | c2paddymainvariety=="Bangobando 100" | c2paddymainvariety=="Boggobondu" | c2paddymainvariety=="Bonggo bondhu" ///
    | c2paddymainvariety=="Bonggobondhu" | c2paddymainvariety=="Bongo bondhu dhan" | c2paddymainvariety=="Bongo bondhu" ///
    | c2paddymainvariety=="Bongobandhu" | c2paddymainvariety=="Bongobondhu 100" | c2paddymainvariety=="Bongobondhu 100" ///
    | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondhu" | c2paddymainvariety=="Bongobondu" | c2paddymainvariety=="bongobondhu 100"

	recode c2paddy_mainvariety -86/-83=181 if c2paddymainvariety=="Boro dhan jira" | c2paddymainvariety=="Jira" | ///
    c2paddymainvariety=="Jira (khato)" | c2paddymainvariety=="Jira 34" | c2paddymainvariety=="Jira Dhan" | ///
    c2paddymainvariety=="Jira dhan" | c2paddymainvariety=="Jira katari" | c2paddymainvariety=="Jira sail" | ///
    c2paddymainvariety=="Jira shahi" | c2paddymainvariety=="Jira shail" | c2paddymainvariety=="Jira14" | ///
    c2paddymainvariety=="Jira34" | c2paddymainvariety=="Jira52" | c2paddymainvariety=="Jirashail" | ///
    c2paddymainvariety=="Kato jira" | c2paddymainvariety=="Kato jirasail boro" | c2paddymainvariety=="Kato jirasail boro" | ///
    c2paddymainvariety=="Katojira boro" | c2paddymainvariety=="Katojira sail" | c2paddymainvariety=="Khato Jira" | ///
    c2paddymainvariety=="Rashian jira" | c2paddymainvariety=="jeera" | c2paddymainvariety=="jira" | c2paddymainvariety=="jira dhan" | ///
    c2paddymainvariety=="jiradan" | c2paddymainvariety=="90 Jira" | c2paddymainvariety=="Khato jira" | c2paddymainvariety=="Lomba jhira" ///
    | c2paddymainvariety=="Zira" | c2paddymainvariety=="Jarashal dhan"

	recode c2paddy_mainvariety -86/-83=181 if c2paddymainvariety=="Jira" | c2paddymainvariety=="Jira dhan" | ///
    | c2paddymainvariety=="Jira master" | c2paddymainvariety=="Jira34" | ///
    c2paddymainvariety=="Jirashail" | c2paddymainvariety=="Kalojira" | c2paddymainvariety=="Khato jira" | ///
    c2paddymainvariety=="Lomba jira" | c2paddymainvariety=="Shahi jira" | c2paddymainvariety=="Jeera"
	
	
	recode c2paddy_mainvariety -86/-83=181 if c2paddymainvariety=="Jira" | c2paddymainvariety=="Jira90" | ///
	c2paddymainvariety=="Jirasahi" | c2paddymainvariety=="Lomba jira"
	
	
recode c2paddy_mainvariety -86/-83=116 if c2paddymainvariety=="Aman sorna" | c2paddymainvariety=="Amon  Sorna 5" | ///
	a1hhid_combined=="425" | c2paddymainvariety=="Amon Dhan Sorna 5" | c2paddymainvariety=="Amon Khato Sorna" | ///
	c2paddymainvariety=="Amon Sorna 5" | c2paddymainvariety=="Amon gotisorna" | c2paddymainvariety=="Giuti sorna" | ///
	c2paddymainvariety=="Ghotisarna" | c2paddymainvariety=="Goti Sorna dan" | c2paddymainvariety=="Goti Sorno" | ///
	c2paddymainvariety=="Guti Sorna" | c2paddymainvariety=="Guti atop sorna" | c2paddymainvariety=="Guti shorno" | ///
	c2paddymainvariety=="Guti sonna" | c2paddymainvariety=="Guti sorna" | c2paddymainvariety=="Guti sorno" | ///
	c2paddymainvariety=="Guti surna" | c2paddymainvariety=="Mota sorna" | c2paddymainvariety=="Nepaly sorna" | ///
	c2paddymainvariety=="Sada guti sorna dhan" | c2paddymainvariety=="Sorna" | c2paddymainvariety=="Sorna 5" | ///
	c2paddymainvariety=="Sorna 5 Amon" | c2paddymainvariety=="Sorna dan" | c2paddymainvariety=="Sorna dhan" | ///
	c2paddymainvariety=="Sorna- 5" | c2paddymainvariety=="Sorna-5" | c2paddymainvariety=="Sorna5" ///
	| c2paddymainvariety=="Sorna_5" | c2paddymainvariety=="Sorno 5" | c2paddymainvariety=="Sorno 5" ///
	| c2paddymainvariety=="Sornoguti" | c2paddymainvariety=="Sornoo gote" | c2paddymainvariety=="sorna" ///
	| c2paddymainvariety=="গুটি স্বর্ণা" | c2paddymainvariety=="স্বর্ন-৫" | c2paddymainvariety=="Goti sorno" ///
	| c2paddymainvariety=="Guti shorna" | c2paddymainvariety=="Guti sonna" | c2paddymainvariety=="Guti sorna" ///
	| c2paddymainvariety=="Guti surna" | c2paddymainvariety=="Khato sorna" | c2paddymainvariety=="Goti sorna" ///
	| c2paddymainvariety=="Shorna" | c2paddymainvariety=="Shorno - 5" | c2paddymainvariety=="Shorno -5" ///
	| c2paddymainvariety=="Shorno 5" | c2paddymainvariety=="Shorno five" | c2paddymainvariety=="Surna" ///
	| c2paddymainvariety=="Surna 5" | c2paddymainvariety=="Deshisarna" | c2paddymainvariety=="Ghotisarna" ///
	| c2paddymainvariety=="Sonna" | c2paddymainvariety=="Sonna 5" | c2paddymainvariety=="Sonra-5" | ///
	c2paddymainvariety=="Swarna pass" | c2paddymainvariety=="sorno" | c2paddymainvariety=="সরনা ৫"  | ///
	c2paddymainvariety=="Amon  Sorna 5" | c2paddymainvariety=="Amon Sorna 5" | c2paddymainvariety=="Amon.Sorna 5" | ///
	c2paddymainvariety=="Goti sorna" | c2paddymainvariety=="Goti sorno" | c2paddymainvariety=="Goti surna" | ///
	c2paddymainvariety=="Goti surna" | c2paddymainvariety=="Khato sorna" | c2paddymainvariety=="Sada sorna" | ///
	c2paddymainvariety=="Sada sorna dha" | c2paddymainvariety=="Sorna" | c2paddymainvariety=="Sorna 5" | ///
	c2paddymainvariety=="Sorna 5 amon" | c2paddymainvariety=="Sorna-5" | c2paddymainvariety=="Sorna/ benikochi" | ///
	c2paddymainvariety=="Sorno 5" | c2paddymainvariety=="Guti shorna" | c2paddymainvariety=="Guti sonna" | ///
	c2paddymainvariety=="Guti sonna" | c2paddymainvariety=="Guti sorna" | c2paddymainvariety=="Guti surna" | ///
	c2paddymainvariety=="Shorna-5" | c2paddymainvariety=="Surna" | c2paddymainvariety=="Surna 5" | ///
	| c2paddymainvariety=="Ghotisarna" | c2paddymainvariety=="Sonna" | c2paddymainvariety=="Sonna 5" | ///
	c2paddymainvariety=="Sonra-5" | c2paddymainvariety=="Sorna 5" | c2paddymainvariety=="Sorna mota" | c2paddymainvariety=="Ghotisarna" ///
	| c2paddymainvariety=="Sonna" | c2paddymainvariety=="Sonna 5" | c2paddymainvariety=="Sonra-5"
	
	
recode c2paddy_mainvariety -86/-83=116 if c2paddymainvariety=="Swarna pass" | c2paddymainvariety=="sorno" | c2paddymainvariety=="সরনা ৫"  | ///
	c2paddymainvariety=="Amon  Sorna 5" | c2paddymainvariety=="Amon Sorna 5" | c2paddymainvariety=="Amon.Sorna 5" | ///
	c2paddymainvariety=="Goti sorna" | c2paddymainvariety=="Goti sorno" | c2paddymainvariety=="Goti surna" | ///
	c2paddymainvariety=="Goti surna" | c2paddymainvariety=="Khato sorna" | c2paddymainvariety=="Sada sorna" | ///
	c2paddymainvariety=="Sada sorna dha" | c2paddymainvariety=="Sorna" | c2paddymainvariety=="Sorna 5" | ///
	c2paddymainvariety=="Sorna 5 amon" | c2paddymainvariety=="Sorna-5" | c2paddymainvariety=="Sorna/ benikochi" | ///
	c2paddymainvariety=="Sorno 5" | c2paddymainvariety=="Guti shorna" | c2paddymainvariety=="Guti sonna" | ///
	c2paddymainvariety=="Guti sonna" | c2paddymainvariety=="Guti sorna" | c2paddymainvariety=="Guti surna" | ///
	c2paddymainvariety=="Shorna-5" | c2paddymainvariety=="Surna" | c2paddymainvariety=="Surna 5" | ///
	| c2paddymainvariety=="Ghotisarna" | c2paddymainvariety=="Sonna" | c2paddymainvariety=="Sonna 5" | ///
	c2paddymainvariety=="Sonra-5" | c2paddymainvariety=="Sorna 5" | c2paddymainvariety=="Sorna mota" | c2paddymainvariety=="Ghotisarna" ///
	| c2paddymainvariety=="Sonna" | c2paddymainvariety=="Sonna 5" | c2paddymainvariety=="Sonra-5"
	
	

	
	recode c2paddy_mainvariety -86/-83=116 if c2paddymainvariety=="Sorna 5" | c2paddymainvariety=="Sorna mota" | c2paddymainvariety=="Ghotisarna" ///
	| c2paddymainvariety=="Sonna" | c2paddymainvariety=="Sonna 5" | c2paddymainvariety=="Sonra-5"
	
	
	recode c2paddy_mainvariety -86/-83=182 if c2paddymainvariety=="Boro teg gold" | c2paddymainvariety=="Taj gold"	| ///
	c2paddymainvariety=="Tajgol" | c2paddymainvariety=="Tej gold" | c2paddymainvariety=="Tej gul" | c2paddymainvariety=="Tejghol" | ///
	c2paddymainvariety=="Tejgol" | c2paddymainvariety=="Tejgold" | c2paddymainvariety=="Tejgon" | ///
	c2paddymainvariety=="Tejgor jath" | c2paddymainvariety=="Tejgul" | c2paddymainvariety=="Tejgul Hybrid" | ///
	c2paddymainvariety=="Tez gul" | c2paddymainvariety=="tejgol"
	
	recode c2paddy_mainvariety -86/-83=183 if c2paddymainvariety=="Amon Mamun Dhan" | c2paddymainvariety=="Mamun" | ///
	c2paddymainvariety=="Mamun dhan" | c2paddymainvariety=="Mamun chikon"
	
	recode c2paddy_mainvariety -86/-83=184 if c2paddymainvariety=="Ronjit" | c2paddymainvariety=="Ronjit Eri" | ///
	c2paddymainvariety=="Ronjid" | c2paddymainvariety=="Ronjiet" | c2paddymainvariety=="Ranjit" | ///
	c2paddymainvariety=="Amon Ronjit Dhan" | c2paddymainvariety=="Amon Ronojit Dhan" | ///
	c2paddymainvariety=="Amon Ronzit Dhan" | c2paddymainvariety=="Ronjit Dhan" | ///
	c2paddymainvariety=="Ronjit amon" | c2paddymainvariety=="Rongit"
		
	recode c2paddy_mainvariety -86/-83=144 if c2paddymainvariety=="Bina 15"
	
	recode c2paddy_mainvariety -86/-83=146 if c2paddymainvariety=="Bina 17"
	
	recode c2paddy_mainvariety -86/-83=185 if c2paddymainvariety=="Boro Dhan Katari" | c2paddymainvariety=="Boro Katari Dhan" | ///
	c2paddymainvariety=="Katari" | c2paddymainvariety=="Katari Dhan" | c2paddymainvariety=="Kathari" | ///
	c2paddymainvariety=="Khathari 34" | c2paddymainvariety=="katari" | c2paddymainvariety=="Jamai katari" | ///
	c2paddymainvariety=="Katari bog" | c2paddymainvariety=="Katari bok" | c2paddymainvariety=="Katari vog" | ///
	c2paddymainvariety=="Katari vog (bogurar dan)" | c2paddymainvariety=="Katari vog," | c2paddymainvariety=="Katari vogh" | ///
	c2paddymainvariety=="Katarivog" | c2paddymainvariety=="Kathari bog" | c2paddymainvariety=="Katire Vog dan" | ///
	c2paddymainvariety=="katari vog" | c2paddymainvariety=="Katare boro" | c2paddymainvariety=="Katari bog" | ///
	c2paddymainvariety=="Katari bok" | c2paddymainvariety=="Catarivog" | c2paddymainvariety=="কাটারি"
	
		
	recode c2paddy_mainvariety -86/-83=127 if c2paddymainvariety=="Hira dhan" | c2paddymainvariety=="Hira" | ///
	c2paddymainvariety=="Hira 1"

	
	recode c2paddy_mainvariety -86/-83=111 if c2paddymainvariety=="Cui miniket" | c2paddymainvariety=="Minicket" | ///
	c2paddymainvariety=="Miniket" | c2paddymainvariety=="Red miniket" | c2paddymainvariety=="Rod Miniket" | ///
	c2paddymainvariety=="Rod Minikit" | c2paddymainvariety=="Rod miniket" | c2paddymainvariety=="Rotminiket" | ///
	c2paddymainvariety=="Rud Menikit"
	
	recode c2paddy_mainvariety -86/-83=186 if c2paddymainvariety=="Boro Dhan Hira 2" | c2paddymainvariety=="Boro Hira 2" | ///
	c2paddymainvariety=="Bro Dhan Hira 2" | c2paddymainvariety=="Hira 2" | c2paddymainvariety=="Hira-2" | ///
	c2paddymainvariety=="Hira2" | c2paddymainvariety=="Hera 2" | c2paddymainvariety=="হিরা ২"
	
	recode c2paddy_mainvariety -86/-83=187 if c2paddymainvariety=="Boro Dhan Hira 6" | c2paddymainvariety=="Hira6"
		
	recode c2paddy_mainvariety -86/-83=188 if c2paddymainvariety=="Hira 19" | c2paddymainvariety=="Hira=19"
	
	recode c2paddy_mainvariety -86/-83=189 if c2paddymainvariety=="Danegola.amon" | c2paddymainvariety=="Dani gold" | /// 
	c2paddymainvariety=="Dani golden" | c2paddymainvariety=="Danigol" | c2paddymainvariety=="Danigold" | ///
	c2paddymainvariety=="Danigoold" | c2paddymainvariety=="Danigul" | c2paddymainvariety=="Dhan Egal" | ///
	c2paddymainvariety=="Dhan Egol" | c2paddymainvariety=="Dhani Gold" | c2paddymainvariety=="Dhani gol" | ///
	c2paddymainvariety=="Dhani Gold, Amon" | c2paddymainvariety=="Dhani ghul" | c2paddymainvariety=="Dhani gold" | ///
	c2paddymainvariety=="Dhani gul" | c2paddymainvariety=="Dhani gur" | c2paddymainvariety=="Dhanigol" | ///
	c2paddymainvariety=="Dhanigold" | c2paddymainvariety=="Dhanigool" | c2paddymainvariety=="Dhanigul" | ///
	c2paddymainvariety=="Dhanigur" | c2paddymainvariety=="Dhanikul" | c2paddymainvariety=="Dhanikul dhan" | ///
	c2paddymainvariety=="Dhanikur" | c2paddymainvariety=="Dhini Gold" | c2paddymainvariety=="Dhnikur" | regex(c2paddymainvariety, "Arizet")
	
		
	recode c2paddy_mainvariety -86/-83=112 if c2paddymainvariety=="Faijam" | c2paddymainvariety=="Paijam" | c2paddymainvariety=="Payjam"
	
	recode c2paddy_mainvariety -86/-83=190 if c2paddymainvariety=="Jhono Raj" | c2paddymainvariety=="Jonak Raj" | ///
	c2paddymainvariety=="Jono crach" | c2paddymainvariety=="Jono rag" | c2paddymainvariety=="Jonocrash" | ///
	c2paddymainvariety=="Jonok  Raj" | c2paddymainvariety=="Jonok Raj" | c2paddymainvariety=="Jonok raj" | ///
	c2paddymainvariety=="Jonok raj," | c2paddymainvariety=="Jonok raz" | c2paddymainvariety=="Jonokraj" | ///
	c2paddymainvariety=="Jonokrajl,National Agrecare 4" | c2paddymainvariety=="Jonokraz" | ///
	c2paddymainvariety=="Jonoraj" | c2paddymainvariety=="jonok raj"
	
	recode c2paddy_mainvariety -86/-83=191 if c2paddymainvariety=="Shuvo lata" | c2paddymainvariety=="Shuvo lata (boro)" | ///
	c2paddymainvariety=="Shuvolota" | c2paddymainvariety=="Sobol lota boro" | c2paddymainvariety=="Sobor lota" | ///
	c2paddymainvariety=="Sobur lota" | c2paddymainvariety=="Sublota" | c2paddymainvariety=="Subol lota" | ///
	c2paddymainvariety=="Subol lota,uccho folonsil" | c2paddymainvariety=="Subolota" | ///
	c2paddymainvariety=="Subon lota" | c2paddymainvariety=="Suvol lota" | ///
	c2paddymainvariety=="Suvol lota( Boro)" | c2paddymainvariety=="shuvo lata" | c2paddymainvariety=="শুভলতা"
	
	recode c2paddy_mainvariety -86/-83= 192 if regex(c2paddymainvariety, "mota") | regex(c2paddymainvariety, "Mota")
	
	recode c2paddy_mainvariety -85/-83 = -86
	
	recode c2paddy_mainvariety -86= 193 if regex(c2paddymainvariety, "BR 108")
	
	recode c2paddy_mainvariety -86 = 194 if regex(c2paddymainvariety, "108")
	
	recode c2paddy_mainvariety -86 = 195 if regex(c2paddymainvariety, "1203")
	
	recode c2paddy_mainvariety -86 = 196 if regex(c2paddymainvariety, "70")
	
	recode c2paddy_mainvariety -86 = 197 if regex(c2paddymainvariety, "Afta")
	
	recode c2paddy_mainvariety -86 = 198 if regex(c2paddymainvariety, "1205") | regex(c2paddymainvariety, "Singenta") | regex(c2paddymainvariety, "Sinjenta")

	recode c2paddy_mainvariety -86 = 199 if regex(c2paddymainvariety, "AZ")
	recode c2paddy_mainvariety -86 = 160 if regex(c2paddymainvariety, "Ahsan")
	recode c2paddy_mainvariety -86 = 128 if regex(c2paddymainvariety, "aci") | regex(c2paddymainvariety, "Aci") 
	recode c2paddy_mainvariety -86 = 201 if regex(c2paddymainvariety, "China 15") ///
	| regex(c2paddymainvariety, "Chaina") | regex(c2paddymainvariety, "Cainij")  ///
	| regex(c2paddymainvariety, "Chines Dhan")
	
	recode c2paddy_mainvariety -86 = 14 if regex(c2paddymainvariety, "15")
	recode c2paddy_mainvariety -86 = 25 if regex(c2paddymainvariety, "26")
	recode c2paddy_mainvariety -86 = 13 if regex(c2paddymainvariety, "BR- 14 amon") | ///
	regex(c2paddymainvariety, "Boro Dhan Bi are 14")
	recode c2paddy_mainvariety -86 = 202 if regex(c2paddymainvariety, "Babilon 2") | ///
	regex(c2paddymainvariety, "Babylon")
	recode c2paddy_mainvariety -86 = 117 if regex(c2paddymainvariety, "Bhojon Dhan") | regex(c2paddymainvariety, "Vojon dhan")
	recode c2paddy_mainvariety -86 = 213 if regex(c2paddymainvariety, "Bog") | regex(c2paddymainvariety, "Sampa") | regex(c2paddymainvariety, "Sompa")
	recode c2paddy_mainvariety -86 = 99 if regex(c2paddymainvariety, "100") | regex(c2paddymainvariety, "বঙ্গবন্ধু") | regex(c2paddymainvariety, "Vggobondho")
	recode c2paddy_mainvariety -86 = 11 if regex(c2paddymainvariety, "11")
	recode c2paddy_mainvariety -86 = 21 if regex(c2paddymainvariety, "22")
	recode c2paddy_mainvariety -86 = 203 if regex(c2paddymainvariety, "Brac")
	recode c2paddy_mainvariety -86 = 22 if regex(c2paddymainvariety, "23")
	recode c2paddy_mainvariety -86 = 204 if regex(c2paddymainvariety, "kka")
	recode c2paddy_mainvariety -86 = 127 if regex(c2paddymainvariety, "Hira")
	recode c2paddy_mainvariety -86 = 205 if regex(c2paddymainvariety, "Ispahani") ///
	| regex(c2paddymainvariety, "Ispahany 9")
	recode c2paddy_mainvariety -86 = 181 if regex(c2paddymainvariety, "Jiradhan")
	
	recode c2paddy_mainvariety -86 = 190 if regex(c2paddymainvariety, "Janak raz") | regex(c2paddymainvariety, "Jonok")
	
	recode c2paddy_mainvariety -86 = 185 if regex(c2paddymainvariety, "Katari") | regex(c2paddymainvariety, "Katre boro")
	
	recode c2paddy_mainvariety -86 = 206 if regex(c2paddymainvariety, "Kathali") | regex(c2paddymainvariety, "Khatali vog") | regex(c2paddymainvariety, "কাঠালি")
	
	recode c2paddy_mainvariety -86 = 207 if regex(c2paddymainvariety, "Khato") | regex(c2paddymainvariety, "Kato") | regex(c2paddymainvariety, "Kahto") | regex(c2paddymainvariety, "খাটো বাবু")
	
	recode c2paddy_mainvariety -86 = 208 if regex(c2paddymainvariety, "Krecebid") | regex(c2paddymainvariety, "Kresebid") | regex(c2paddymainvariety, "Krishibid 2")
	
	recode c2paddy_mainvariety -86 = 209 if regex(c2paddymainvariety, "Nakko") | regex(c2paddymainvariety, "Nafko") | regex(c2paddymainvariety, "Nappo")
	
	recode c2paddy_mainvariety -86 = 211 if regex(c2paddymainvariety, "Sathi") | regex(c2paddymainvariety, "সাথী ধান")
	
	recode c2paddy_mainvariety -86 = 212 if regex(c2paddymainvariety, "40-94") | c2paddymainvariety == "89" | c2paddymainvariety == "14dhan" | ///
	regex(c2paddymainvariety, "1303") | regex(c2paddymainvariety, "6353") | regex(c2paddymainvariety, "6453")
	
	recode c2paddy_mainvariety -86 = 212 if regex(c2paddymainvariety, "Durbar") | regex(c2paddymainvariety, "Jhalak") | ///
	regex(c2paddymainvariety, "Jamuna") | regex(c2paddymainvariety, "Mital") | regex(c2paddymainvariety, "National") | ///
	regex(c2paddymainvariety, "Petrocam") | regex(c2paddymainvariety, "Subor") | regex(c2paddymainvariety, "sera")
	
	recode c2paddy_mainvariety -86 = 212 if regex(c2paddymainvariety, "ybrid") | regex(c2paddymainvariety, "777") ///
	| regex(c2paddymainvariety, "hibred") | regex(c2paddymainvariety, "haibrid") | regex(c2paddymainvariety, "Gurmuda highbred")
	
	recode c2paddy_mainvariety -86 = 214 if regex(c2paddymainvariety, "Name sara jat.bijer jater name aita")
	
	recode c2paddy_mainvariety -86 = 181 if regex(c2paddymainvariety, "Zira")

	recode c2paddy_mainvariety 180 = 99
	
	recode c2paddy_mainvariety 194 = 197
	recode c2paddy_mainvariety 196 = 197

	recode c2paddy_intercropvariety -86/-83 = 99 if regex(c2paddyintervariety, "Bangobando 100")
	recode c2paddy_intercropvariety -85/-83 = -86

	
	label define c2paddy_mainvariety 1 "Chandina BR-1 (Boro/Aus)" ///
								2 "Mala BR-2 (Boro/Aus)" ///
								3 "Biplob BR-3 (Aus/Aman)" ///
								4 "Brishail BR-4* (Aman)" ///
								5 "Dulavhoge BR-5* (Aman)" ///
								6 "BR-6 (Boro/Aus)" ///
								7 "Bribalam BR-7 (Boro/Aus)"  ///
								8 "Asa BR-8 (Boro/Aus)" ///
								9 "Sufoza BR-9 (Boro/Aus)" ///
								10 "Progoti BR-10 (Aman)" ///
								11 "Mukta BR-11 (Aman)" ///
								12 "Moyna BR-12 (Boro/Aus)" ///
								13 "Gazi BR-14 (Boro/Aus)" ///
								14 "Mohini BR-15 (Boro/aus)" ///
								15 "Shahi Balam BR-16(Boro/Aus)" ///
								16 "Hasi BR-17 (Boro)" ///
								17 "Shahjalal BR-18 (Boro)" ///
								18 "Mongal BR-19 (Boro)" ///
								19 "Nizami BR-20 (Aus)"  ///
								20 "Niamat BR-21 (Aus)"  ///
								21 "Kiron BR-22* (Aman)"  ///
								22 "Dyshary BR-23 (Aman)"  ///
								23 "Rahmat BR-24 (Aus)" ///
                          24  "Noya Pajam BR-25 (Aman)" ///
                          25  "Sraboni BR-26 (Aus)" ///
                          26  "Bri Dhan BR-27 (Aus)" ///
                          27  "Bri Dhan BR-28 (Boro)" ///
                          28  "Bri Dhan BR-29 (Boro)" ///
                          29  "Bri Dhan BR-30 (Aman)" ///
                          30  "Bri Dhan BR-31 (Aman)" ///
                          31  "Bri Dhan BR-32 (Aman)" ///
                          32  "Bri Dhan BR-33 (Aman)" ///
                          33  "Bri Dhan BR-34 (Aman)" ///
                          34  "Bri Dhan BR-35 (Boro)" ///
                          35  "Bri Dhan BR-36 (Boro)" ///
                          36  "Bri Dhan BR-37 (Aman)" ///
                          37  "Bri Dhan BR-38 (Aman)" ///
                          38  "Bri Dhan BR-39 (Aman)" ///
                          39  "Bri Dhan BR-40 (Aman)" ///
                          40  "Bri Dhan BR-41 (Aman)" ///
                          41  "Bri Dhan BR-42 (Aus)" ///
                          42  "Bri Dhan BR-43 (Aus)" ///
                          43  "Bri Dhan BR-44 (Aman)" ///
                          44  "Bri Dhan BR-45 (Boro)" ///
                          45  "Bri Dhan BR-46 (Aman)" ///
                          46  "Bri Dhan BR-47 (Boro)" ///
                          47  "Bri Dhan BR-48 (Aus)" ///
                          48  "Bri Dhan BR-49 (Aman)" ///
                          49  "Bri Dhan BR-50 (Banglamoti) (Boro)" ///
                          50  "Bri Dhan BR-51 (Aman)" ///
                          51  "Bri Dhan BR-52 (Aman)" ///
                          52  "Bri Dhan BR-53 (Aman)" ///
                          53  "Bri Dhan BR-54 (Aman)" ///
                          54  "Bri Dhan BR-55 (Boro/Aus)" ///
                          55  "Bri Dhan BR-56 (Aman)" ///
                          56  "Bri Dhan BR-57 (Aman)" ///
                          57  "Bri Dhan BR-58 (Boro)" ///
                          58  "Bri Dhan BR-59 (Boro)" ///
                          59  "Bri Dhan BR-60 (Boro)" ///
                          60  "Bri Dhan BR-61 (Boro)" ///
                          61  "Bri Dhan BR-62 Zinc Enriched (Aman)" ///
                          62  "Bri Dhan BR-63 Shorubalam (Boro)" ///
                          63  "Bri Dhan BR-64 Zinc Enriched (Boro)" ///
                          64  "Bri Dhan BR-65 (Aus)" ///
                          65  "Bri Dhan BR-66 Drought Tolerant (Aman)" ///
                          66  "Bri Dhan BR-67 Saline Tolerant (Boro)" ///
                          67  "Bri Dhan BR-68 (Boro)" ///
                          68  "Bri Dhan BR-69 Weed Resistant (Boro)" ///
                          69  "Bri Dhan 70" ///
                          70  "Bri Dhan 71" ///
                          71  "Bri Dhan 72" ///
                          72  "Bri Dhan 73" ///
                          73  "Bri Dhan 74" ///
			  			 74  "Bri Dhan 75" ///
                         75  "Bri Dhan 76" ///
                         76  "Bri Dhan 77" ///
                         77  "Bri Dhan 78" ///
                         78  "Bri Dhan 79" ///
                         79  "Bri Dhan 80" ///
                         80  "Bri Dhan 81" ///
                         81  "Bri Dhan 82" ///
                         82  "Bri Dhan 83" ///
                         83  "Bri Dhan 84" ///
                         84  "Bri Dhan 85" ///
                         85  "Bri Dhan 86" ///
                         86  "Bri Dhan 87" ///
                         87  "Bri Dhan 88" ///
                         88  "Bri Dhan 89" ///
                         89  "Bri Dhan 90" ///
                         90  "Bri Dhan 91" ///
                         91  "Bri Dhan 92" ///
                         92  "Bri Dhan 93" ///
                         93  "Bri Dhan 94" ///
                         94  "Bri Dhan 95" ///
                         95  "Bri Dhan 96" ///
                         96  "Bri Dhan 97" ///
                         97  "Bri Dhan 98" ///
                         98  "Bri Dhan 99" ///
                         99  "Bri Dhan 100" ///
                         100 "Bri Dhan 101" ///
                         101 "Bri Dhan 102" ///
                         102 "Bri Dhan 103" ///
                         103 "Bri Dhan 104" ///
                         104 "Bri Dhan 105" ///
                         105 "Bri Dhan 106" ///
                         106 "Nerica(new rice for africa)" ///
                         107 "Haridhan" ///
                         108 "Asiruddin" ///
                         109 "Kajallata" ///
                         110 "Khude kajal" ///
                         111 "Miniket" ///
                         112 "Paijam" ///
                         113 "Shapla" ///
                         114 "Bashmati" ///
                         115 "Jamaibabu" ///
                         116 "Guti/rajshahi/lalshorna" ///
                         117 "Bhojon(white/coarse)" ///
                         118 "Binni dhan" ///
                         119 "Tepi dhan" ///
                         120 "Alok" ///
                         121 "Sonar bangla" ///
                         122 "Jagoron" ///
                         123 "Shakti 1" ///
                         124 "Shakti 2" ///
                         125 "Aloron 1" ///
                         126 "Aloron 2" ///
                         127 "Hira" ///
                         128 "ACI" ///
                         129 "Lal Teer" ///
                         130 "BINA 1" ///
                         131 "BINA 2" ///
                         132 "BINA 3" ///
                         133 "BINA 4" ///
                         134 "BINA 5" ///
                         135 "BINA 6(Boro/aus)" ///
                         136 "BINA 7(Aman)" ///
                         137 "BINA 8(Boro/Aus)" ///
                         138 "BINA 9" ///
                         139 "BINA 10 (Boro)" ///
                         140 "BINA 11(aman/aus)" ///
                         141 "BINA 12 (aman)" ///
                         142 "BINA 13 (aman)" ///
                         143 "BINA 14 (boro)" ///
                         144 "BINA 15 (aman)" ///
                         145 "BINA 16(aman)" ///
                         146 "BINA 17" ///
                         147 "BINA 18" ///
                         148 "BINA 19" ///
                         149 "BINA 20" ///
                         150 "BINA 21" ///
                         151 "BINA 22" ///
                         152 "BINA 23" ///
                         153 "BINA 24" ///
                         154 "BINA 25" ///
                         155 "Bri Hybrid-1(Boro)" ///
                         156 "Bri Hybrid-2(Boro)" ///
                         157 "Bri Hybrid-3(Boro)" ///
                         158 "Bri Hybrid-4(Boro Aman)" ///
                         159 "Bri hybrid 5" ///
                         160 "Bri hybrid 6" ///
                         161 "Bri hybrid 7" ///
                         162 "Bri hybrid 8" ///
                         163 "Binashail(aman)" ///
                         164 "Iratom 24(Boro)" ///
                         165 "Taj" ///
                         166 "HS" ///
                         167 "Shonali" ///
                         168 "Surma" ///
                         169 "Padma" ///
                         170 "Bijoy" ///
                         171 "Borkot" ///
                         172 "Raja" ///
                         173 "Chitra" ///
                         174 "Shobujmoti" ///
                         175 "Kajol" ///
                         176 "Rajkumar" ///
                         177 "Robi" ///
                         178 "BU Aromatic Hybrid Dhan-1" ///
                         179 "BU Aromatic Dhan-2" ///
						180 "Bongobondhu" ///
						181 "Jira" ///
						182 "Tej gold" ///
						183 "Mamun (Aman)" ///
						184 "Ronjit" ///
						185 "Katari" ///
						186 "Hira 2" ///
						187 "Hira 6" ///
						188 "Hira 19" ///
						189 "Dhani gold/Danigol/Dhanikul/Dhanigul" ///
						190 "Jonok Raj" ///
						191 "Shuvo Lota" ///
						192 "Mota (round bold seed)" ///
						193 "BR-108" ///
						194 "Aftab LP 108" ///
						195 "Spa hybrid 1203" ///
						196 "Aftab 70" ///
						197 "Aftab hyrbrids" /// 
						198 "Syngenta hybrids" ///
						199 "AZ" ///
						200 "ACI" ///
						201 "Chinese" ///
						202 "Babylon" ///	
						203 "BRAC" ///
						204 "Chokka" ///
						205 "Ispahani hybrids" ///
						206 "Kathali" ///
						207 "Khato babu 10" ///
						208 "Krishibid" ///
						209 "NAFCO 2" ///
						211 "Sathi" ///
						212 "Miscellaneous hybrid varieties" ///
						213 "Bogura Sampa" ///
						214 "Do not know" ///
						-86 "Others", modify
						
						la val c2paddy_mainvariety c2paddy_mainvariety
						
	label define c2paddy_intercropvariety 1 "Chandina BR-1 (Boro/Aus)" ///
								2 "Mala BR-2 (Boro/Aus)" ///
								3 "Biplob BR-3 (Aus/Aman)" ///
								4 "Brishail BR-4* (Aman)" ///
								5 "Dulavhoge BR-5* (Aman)" ///
								6 "BR-6 (Boro/Aus)" ///
								7 "Bribalam BR-7 (Boro/Aus)"  ///
								8 "Asa BR-8 (Boro/Aus)" ///
								9 "Sufoza BR-9 (Boro/Aus)" ///
								10 "Progoti BR-10 (Aman)" ///
								11 "Mukta BR-11 (Aman)" ///
								12 "Moyna BR-12 (Boro/Aus)" ///
								13 "Gazi BR-14 (Boro/Aus)" ///
								14 "Mohini BR-15 (Boro/aus)" ///
								15 "Shahi Balam BR-16(Boro/Aus)" ///
								16 "Hasi BR-17 (Boro)" ///
								17 "Shahjalal BR-18 (Boro)" ///
								18 "Mongal BR-19 (Boro)" ///
								19 "Nizami BR-20 (Aus)"  ///
								20 "Niamat BR-21 (Aus)"  ///
								21 "Kiron BR-22* (Aman)"  ///
								22 "Dyshary BR-23 (Aman)"  ///
								23 "Rahmat BR-24 (Aus)" ///
                          24  "Noya Pajam BR-25 (Aman)" ///
                          25  "Sraboni BR-26 (Aus)" ///
                          26  "Bri Dhan BR-27 (Aus)" ///
                          27  "Bri Dhan BR-28 (Boro)" ///
                          28  "Bri Dhan BR-29 (Boro)" ///
                          29  "Bri Dhan BR-30 (Aman)" ///
                          30  "Bri Dhan BR-31 (Aman)" ///
                          31  "Bri Dhan BR-32 (Aman)" ///
                          32  "Bri Dhan BR-33 (Aman)" ///
                          33  "Bri Dhan BR-34 (Aman)" ///
                          34  "Bri Dhan BR-35 (Boro)" ///
                          35  "Bri Dhan BR-36 (Boro)" ///
                          36  "Bri Dhan BR-37 (Aman)" ///
                          37  "Bri Dhan BR-38 (Aman)" ///
                          38  "Bri Dhan BR-39 (Aman)" ///
                          39  "Bri Dhan BR-40 (Aman)" ///
                          40  "Bri Dhan BR-41 (Aman)" ///
                          41  "Bri Dhan BR-42 (Aus)" ///
                          42  "Bri Dhan BR-43 (Aus)" ///
                          43  "Bri Dhan BR-44 (Aman)" ///
                          44  "Bri Dhan BR-45 (Boro)" ///
                          45  "Bri Dhan BR-46 (Aman)" ///
                          46  "Bri Dhan BR-47 (Boro)" ///
                          47  "Bri Dhan BR-48 (Aus)" ///
                          48  "Bri Dhan BR-49 (Aman)" ///
                          49  "Bri Dhan BR-50 (Banglamoti) (Boro)" ///
                          50  "Bri Dhan BR-51 (Aman)" ///
                          51  "Bri Dhan BR-52 (Aman)" ///
                          52  "Bri Dhan BR-53 (Aman)" ///
                          53  "Bri Dhan BR-54 (Aman)" ///
                          54  "Bri Dhan BR-55 (Boro/Aus)" ///
                          55  "Bri Dhan BR-56 (Aman)" ///
                          56  "Bri Dhan BR-57 (Aman)" ///
                          57  "Bri Dhan BR-58 (Boro)" ///
                          58  "Bri Dhan BR-59 (Boro)" ///
                          59  "Bri Dhan BR-60 (Boro)" ///
                          60  "Bri Dhan BR-61 (Boro)" ///
                          61  "Bri Dhan BR-62 Zinc Enriched (Aman)" ///
                          62  "Bri Dhan BR-63 Shorubalam (Boro)" ///
                          63  "Bri Dhan BR-64 Zinc Enriched (Boro)" ///
                          64  "Bri Dhan BR-65 (Aus)" ///
                          65  "Bri Dhan BR-66 Drought Tolerant (Aman)" ///
                          66  "Bri Dhan BR-67 Saline Tolerant (Boro)" ///
                          67  "Bri Dhan BR-68 (Boro)" ///
                          68  "Bri Dhan BR-69 Weed Resistant (Boro)" ///
                          69  "Bri Dhan 70" ///
                          70  "Bri Dhan 71" ///
                          71  "Bri Dhan 72" ///
                          72  "Bri Dhan 73" ///
                          73  "Bri Dhan 74" ///
			  			 74  "Bri Dhan 75" ///
                         75  "Bri Dhan 76" ///
                         76  "Bri Dhan 77" ///
                         77  "Bri Dhan 78" ///
                         78  "Bri Dhan 79" ///
                         79  "Bri Dhan 80" ///
                         80  "Bri Dhan 81" ///
                         81  "Bri Dhan 82" ///
                         82  "Bri Dhan 83" ///
                         83  "Bri Dhan 84" ///
                         84  "Bri Dhan 85" ///
                         85  "Bri Dhan 86" ///
                         86  "Bri Dhan 87" ///
                         87  "Bri Dhan 88" ///
                         88  "Bri Dhan 89" ///
                         89  "Bri Dhan 90" ///
                         90  "Bri Dhan 91" ///
                         91  "Bri Dhan 92" ///
                         92  "Bri Dhan 93" ///
                         93  "Bri Dhan 94" ///
                         94  "Bri Dhan 95" ///
                         95  "Bri Dhan 96" ///
                         96  "Bri Dhan 97" ///
                         97  "Bri Dhan 98" ///
                         98  "Bri Dhan 99" ///
                         99  "Bri Dhan 100" ///
                         100 "Bri Dhan 101" ///
                         101 "Bri Dhan 102" ///
                         102 "Bri Dhan 103" ///
                         103 "Bri Dhan 104" ///
                         104 "Bri Dhan 105" ///
                         105 "Bri Dhan 106" ///
                         106 "Nerica(new rice for africa)" ///
                         107 "Haridhan" ///
                         108 "Asiruddin" ///
                         109 "Kajallata" ///
                         110 "Khude kajal" ///
                         111 "Miniket" ///
                         112 "Paijam" ///
                         113 "Shapla" ///
                         114 "Bashmati" ///
                         115 "Jamaibabu" ///
                         116 "Guti/rajshahi/lalshorna" ///
                         117 "Bhojon(white/coarse)" ///
                         118 "Binni dhan" ///
                         119 "Tepi dhan" ///
                         120 "Alok" ///
                         121 "Sonar bangla" ///
                         122 "Jagoron" ///
                         123 "Shakti 1" ///
                         124 "Shakti 2" ///
                         125 "Aloron 1" ///
                         126 "Aloron 2" ///
                         127 "Hira" ///
                         128 "ACI 5" ///
                         129 "Lal Teer" ///
                         130 "BINA 1" ///
                         131 "BINA 2" ///
                         132 "BINA 3" ///
                         133 "BINA 4" ///
                         134 "BINA 5" ///
                         135 "BINA 6(Boro/aus)" ///
                         136 "BINA 7(Aman)" ///
                         137 "BINA 8(Boro/Aus)" ///
                         138 "BINA 9" ///
                         139 "BINA 10 (Boro)" ///
                         140 "BINA 11(aman/aus)" ///
                         141 "BINA 12 (aman)" ///
                         142 "BINA 13 (aman)" ///
                         143 "BINA 14 (boro)" ///
                         144 "BINA 15 (aman)" ///
                         145 "BINA 16(aman)" ///
                         146 "BINA 17" ///
                         147 "BINA 18" ///
                         148 "BINA 19" ///
                         149 "BINA 20" ///
                         150 "BINA 21" ///
                         151 "BINA 22" ///
                         152 "BINA 23" ///
                         153 "BINA 24" ///
                         154 "BINA 25" ///
                         155 "Bri Hybrid-1(Boro)" ///
                         156 "Bri Hybrid-2(Boro)" ///
                         157 "Bri Hybrid-3(Boro)" ///
                         158 "Bri Hybrid-4(Boro Aman)" ///
                         159 "Bri hybrid 5" ///
                         160 "Bri hybrid 6" ///
                         161 "Bri hybrid 7" ///
                         162 "Bri hybrid 8" ///
                         163 "Binashail(aman)" ///
                         164 "Iratom 24(Boro)" ///
                         165 "Taj" ///
                         166 "HS" ///
                         167 "Shonali" ///
                         168 "Surma" ///
                         169 "Padma" ///
                         170 "Bijoy" ///
                         171 "Borkot" ///
                         172 "Raja" ///
                         173 "Chitra" ///
                         174 "Shobujmoti" ///
                         175 "Kajol" ///
                         176 "Rajkumar" ///
                         177 "Robi" ///
                         178 "BU Aromatic Hybrid Dhan-1" ///
                         179 "BU Aromatic Dhan-2" ///
						180 "Bongobondhu" ///
						181 "Jira" ///
						182 "Tej gold" ///
						183 "Mamun (Aman)" ///
						184 "Ronjit" ///
						185 "Katari" ///
						186 "Hira 2" ///
						187 "Hira 6" ///
						188 "Hira 19" ///
						189 "Dhani gold/Danigol/Dhanikul/Dhanigul" ///
						190 "Jonok Raj" ///
						191 "Shuvo Lota" ///
						192 "Mota (round bold seed)" ///
						-86 "Others", modify
						
						la val c2paddy_intercropvariety c2paddy_intercropvariety
						
						
	la var c3rice_plant_decision "Rice variety type decision maker"
	la var c3plant_method "Rice seeds planting method"
	la var c3seed_reusage "N of seasons seeds for main variety re-used"
	la var c4belief_mainvariety "Certainty regarding accuracy of the self-reported main variety"
	la var c4belief_intervariety "Certainty regarding accuracy of the self-reported intercropped variety"
	la var c4main_seed_quality "Quality of the main variety?"
	la var c4inter_seed_quality "Quality of the intercropped variety"
	la var c4main_seed_source "Seed source for main variety"
	la var c4inter_seed_source "Seed source for intercropped variety"
	la var c4reliablemainvar_source "Reliability of the main variety source"
	la var c4reliableintvar_source "Reliability of the intercropped variety source"
	la var c4farmer_rank "Self reported farmer rank about the no. of accurate predictions"
	la var c4corr_var_prediction "Farmer perception on the number of correctly predicted varieties"
	la var c2plot_area "Plot area calculated in surveyCTO from plot boundary (meters-squared)"

	drop c4main_source_name c4inter_source_name c4interseedsource_oth
	
	recode c4main_seed_source -96 = 6 if regex(c4mainseedsource_oth, "mem") | ///
	regex(c4mainseedsource_oth, "Badc") | regex(c4mainseedsource_oth, "Krishi")
	
	recode c4main_seed_source -96 = 8 if regex(c4mainseedsource_oth, "Baj") | ///
	regex(c4mainseedsource_oth, "Baz") | regex(c4mainseedsource_oth, "Bis") | ///
	regex(c4mainseedsource_oth, "Biz") | regex(c4mainseedsource_oth, "Cara") | ///
	regex(c4mainseedsource_oth, "Chara") | regex(c4mainseedsource_oth, "chara") | ///
	regex(c4mainseedsource_oth, "kine")
	
	
	recode c4main_seed_source -96 = 4 if regex(c4mainseedsource_oth, "Br")
	
	recode c4main_seed_source -96 = 9 if regex(c4mainseedsource_oth, "Chacar") | ///
	regex(c4mainseedsource_oth, "Nana") | regex(c4mainseedsource_oth, "Vaiyer")
	
	drop c2paddymainvariety
	
	replace c2paddyintervariety = "" if c2paddy_intercropvariety != -86
	ren c2paddyintervariety c2paddyintervariety_oth
	la var c2paddyintervariety_oth "Specify other intercropped paddy"
	order c2paddy_intercropvariety c2paddyintervariety_oth
						
		
		tempfile c2_4
		save `c2_4', replace
		
		
		
		import excel "${dir}${slash}Data${slash}DNA fingerprinting${slash}bangladesh_rice_assignment_results.xlsx" , firstrow clear
		drop M
		
		

		
		duplicates drop SPIA_sample_ID Reference_name SPIA_ref_ID Variety , force
		duplicates tag SPIA_sample_ID , gen(dup)
		rename SPIA_sample_ID c2scan_barcode_1 
		drop if Sample_name == "SPIA_BIHS_2072" & Reference_name == "NA"
		drop if Reference_name == "NA"
		
		drop dup
		
		tempfile DNA
		save "`DNA'"

		
		u `c2_4', clear
		
		keep if c2scan_barcode_2 != "" 
		drop c2scan_barcode_1
		rename c2scan_barcode_2 c2scan_barcode_1
		// gen barcode_2 = 1 
		tempfile duplicate
		save "`duplicate'"

		u `c2_4', clear 
		drop c2scan_barcode_2
		append using "`duplicate'"
		sort a1hhid_combined c2scan_barcode_1 
		drop if c2scan_barcode_1 == ""
		

		merge 1:m c2scan_barcode_1 using "`DNA'" , keep(3) nogenerate 
		 
		gen Variety_clean = subinstr(Variety, "BD-", " Bri Dhan BR-", .)
		encode Variety_clean, gen(Variety_num) label(Variety_clean)
		
		duplicates drop a1hhid_combined c2paddy_mainvariety Variety_clean ,force
				
		rename c2scan_barcode_1 c2scan_barcode
		
		la var c2two_sample "Two samples taken from HH"
		
		drop Variety Var1 Sample_name Sample_attribute Top_Reference Reference_name ///
		SPIA_ref_ID Status
		
		
		
		ren (Top_IBS Top_Purity var1_Ho Variety_clean Variety_num c2reasonseed_mixed__96) (c2top_ibs c2top_purity c2heterozygosity c2variety_clean c2variety_num c2reasonseed_mixed_96)
		
		la var c2top_ibs "Score for closest matching reference to the sample (DNA fingerprinting)"
		la var c2top_purity "% similarity of loci between the samples and references (DNA fingerprinting)"
		la var c2heterozygosity "Rate of presence of different alleles at genetic loci (DNA fingerprinting)"
		la var c2variety_clean "DNA fingerprinting paddy variety name"
		la var c2variety_num "DNA fingerprinting paddy variety (code)"
		la var c2paddy_mainvariety "Main paddy variety (self report)"
		la var c2paddy_intercropvariety "Intercropped paddy variety (self report)"
		la var c2scan_barcode "Scan barcode for the leaf sample pot"
		la var c2reasonseed_mixed_96 "Other (specify)"
		
		order a1hhid_combined c2* c3* c4*
		order c2scan_barcode, after(c2land_select)
		order c2paddy_intercropvariety c2paddyintervariety_oth, after(c2paddy_mainvariety_oth)
		
		save "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , replace	
		
		
			**# Module C5
		
	import excel "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified.xlsx" , firstrow sheet(module_c5) clear

	merge m:1 SETOFmodule_c5 using `main_data' , keep(3) nogen
	
	tempfile merged_c5
	save `merged_c5', replace
	
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(module_c5) clear
	
	merge m:1 SETOFmodule_c5 using `resurvey_data', nogen keep(3)
	
	append using `merged_c5', force
	
	keep a1hhid_combined c1land_select SETOFmodule_c5 c1boro_crop c1borocrop ///
	c1aman_crop c1amancrop c1aus_crop c1auscrop c1boro23_crop c1yearly_crop c5*
	keep if c1land_select != . //no land selected - not agri household 
	
	
	save "${temp_data}${slash}SPIA_BIHS_Main_2024_module_c5.dta", replace

	* Label variables  
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_2024_Varnames.xlsx") ///
	data("${temp_data}${slash}SPIA_BIHS_Main_2024_module_c5.dta") label(English) dateformat(MDY) ///
	clear save("${temp_data}${slash}SPIA_BIHS_Main_2024_module_c5.dta")
	
	

	* order 
	order a1hhid_combined c1land_select c5* SETOFmodule_c5
	sort a1hhid_combined c1land_select c5season_id

	** clean season name 
	replace c5season_name = "Aus (Kharif-1) (2023)" if c5season_name == "আউস (খরিফ- 1) (2023)"
	replace c5season_name = "Aman (Kharif-2) (2023)" if c5season_name == "আমন (খরিফ- 2) (2023)"
	replace c5season_name = "Annual" if c5season_name == "বাৎসরিক"
	replace c5season_name = "Boro (Rabi) (2022-23)" if c5season_name == "বোরো(রবি) (2022-23)"
	replace c5season_name = "Boro (Rabi) (2023-24)" if c5season_name == "বোরো(রবি) (2024)"  

	** drop seasons where there was no activity - ** 
	drop if c5tillage == . & c5seed == . & c5urea == . & c5weeded == . & c5herbicide == . &  ///
	c5insecticide == . & c5hv_fam_lab_days == . & c5threshing_system == . &  c5crop_prod_amt == .

	** rename family labor days/ hired labor days and daily wage variables 
	rename c5plfam_lab_days c5pl_fam_lab_hours

	foreach x in c5sb c5tp c5wd c5hv c5thr {
	rename `x'_fam_lab_days `x'_fam_lab_hours 
	}

	foreach x in c5pl c5sb c5tp c5wd c5hv c5thr {
	rename `x'_hired_lab_days `x'_hired_lab_hours 
	}

	foreach x in c5pl c5sb c5tp c5wd c5hv c5thr {
	rename `x'_daily_wage `x'_total_wage	
	}
	
	
	
	tempfile c5old
	save `c5old', replace
		
	preserve
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	keep if !mi(b2area)
	keep if b2crop_season == 1
	egen coll_var = concat(a1hhid_combined b1plot_num b2crop_season b2crop), p(.)
	
	collapse(first) a1hhid_combined b1plot_num b2crop_season b2crop (sum) b2area, by(coll_var)
	
	tempfile c5area_boro
	save "`c5area_boro'", replace
	
	
	restore
	
	preserve
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	keep if !mi(b2area)
	keep if b2crop_season == 2
	egen coll_var = concat(a1hhid_combined b1plot_num b2crop_season b2crop), p(.)
	
	collapse(first) a1hhid_combined b1plot_num b2crop_season b2crop (sum) b2area, by(coll_var)
	
	tempfile c5area_aman
	save "`c5area_aman'", replace
	
	
	restore
	
	preserve
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	keep if !mi(b2area)
	keep if b2crop_season == 3
	egen coll_var = concat(a1hhid_combined b1plot_num b2crop_season b2crop), p(.)
	
	collapse(first) a1hhid_combined b1plot_num b2crop_season b2crop (sum) b2area, by(coll_var)
	
	tempfile c5area_aus
	save "`c5area_aus'", replace
	
	
	restore
	
	preserve
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	keep if !mi(b2area)
	keep if b2crop_season == 4
	egen coll_var = concat(a1hhid_combined b1plot_num b2crop_season b2crop), p(.)
	
	collapse(first) a1hhid_combined b1plot_num b2crop_season b2crop (sum) b2area, by(coll_var)
	
	tempfile c5area_boro23
	save "`c5area_boro23'", replace
	
	
	restore
	
	preserve
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	keep if !mi(b2area)
	keep if b2crop_season == 5
	egen coll_var = concat(a1hhid_combined b1plot_num b2crop_season b2crop), p(.)
	
	collapse(first) a1hhid_combined b1plot_num b2crop_season b2crop (sum) b2area, by(coll_var)
	
	tempfile c5area_yearly
	save "`c5area_yearly'", replace
	
	
	restore
		
	foreach i in boro aman aus boro23 yearly {
		

			u `c5old', clear
		
	
	ren (c1land_select c5season_id c1`i'_crop) (b1plot_num b2crop_season b2crop)
	
	
	
	merge m:1 a1hhid_combined b1plot_num b2crop_season b2crop using "`c5area_`i''" , nogen keep(3) keepusing(b2area)
	
	tempfile c5`i'
	save "`c5`i''", replace
		
	}
	
	clear
	tempfile c5new
	save `c5new', emptyok
	
	foreach i in boro aman aus boro23 yearly {
	
		append using "`c5`i''"
		save `c5new', replace
		
	
	}
	
	drop c1boro_crop c1borocrop ///
	c1aman_crop c1amancrop c1aus_crop c1auscrop c1boro23_crop c1yearly_crop
	
	ren (b1plot_num b2crop_season) (c1land_select c5season_id)
	
	

	* plough cost
	replace c5plough_cost = . if c5plough_cost == 0 // if not rented then should be missing - this will bring the average down 
	* outliers
	g c5plough_cost_dec = c5plough_cost/b2area
	replace c5plough_cost = . if c5plough_cost < 100 & b2area > 2 
	replace c5plough_mach_cost = . if c5plough_mach_cost == 0
	g c5plough_mach_cost_dec = c5plough_mach_cost/b2area
	
	replace c5plough_mach_cost = . if c5plough_mach_cost_dec <= 1 
	
	g c5seed_cost_dec = c5seed_cost/c5seed


	** DO THIS FOR ALL ACTIVITIES 
	foreach x in c5pl c5sb c5tp c5wd c5hv c5thr {
	** calculate total hours worked and the hourly wage
	gen total_till_`x' = `x'_fam_lab_hours + `x'_hired_lab_hours
	gen wage_per_hour_`x' = round((`x'_total_wage/total_till_`x'),1)
	order total_till_`x' wage_per_hour_`x', after(`x'_hired_lab_hours)
	replace wage_per_hour_`x' = . if wage_per_hour_`x' == 0 

	** replace the hourly wage with 5 percentile if lower than that
	gen wage_hour_low_issue_`x' = 1 if wage_per_hour_`x' < 40 & wage_per_hour_`x' != . 
	gen wage_hour_top_issue_`x' = 1 if wage_per_hour_`x' > 200 & wage_per_hour_`x' != .
	 
	winsor2 wage_per_hour_`x', suffix(_w) cuts(5 100)
	drop wage_per_hour_`x'
	rename wage_per_hour_`x'_w wage_per_hour_`x'

	** Total wage bottom percentile: For all lands where the hourly wage is less than 40 taka - we replace the total cost by total_till*wage_per_hour(fixed)
	replace `x'_total_wage = total_till_`x'*wage_per_hour_`x' if wage_hour_low_issue_`x' == 1
	replace `x'_total_wage = . if `x'_total_wage == 0 

	** Total wage top percentile: For hourly wage more than 400? 300? 200? per hour  - replace the number of hours worked with 8. (Assume the current figure to be days)
	replace `x'_hired_lab_hours = `x'_hired_lab_hours*8 if wage_hour_top_issue_`x' == 1 
	replace `x'_fam_lab_hours = `x'_fam_lab_hours*8 if wage_hour_top_issue_`x' == 1 
	replace total_till_`x' = total_till_`x'*8 if wage_hour_top_issue_`x' == 1 
	drop wage_per_hour_`x' total_till_`x' wage_hour_top_issue_`x' wage_hour_low_issue_`x'
	}
	replace c5sb_total_wage = (c5sb_hired_lab_hours + c5sb_fam_lab_hours)*40 if c5sb_total_wage == 1 

	replace c5harvest_combine_cost = c5harvest_mach_cost if c5harvest_combine_cost == . // In the first 2-3 days of the survey, we had missed separating the reaper and combine harvester cost in separate variables. c5harvest_mach_cost was then broken into two. I am putting the value of this variable in the combine harvester cost

	drop c5harvest_mach_cost 
	
	ren (b2crop b2area) (c5crop c5area)
	
		  la def c5crop 1 "B Aus (local)" ///
						2 "TAus (local)" ///
						3 "TAus (HYV)" ///
						4 "T Aus (hybrid)" ///
						5 "BAman (local)" ///
						6 "T Aman(local)" ///
						7 "T.Aman (HYV)" ///
						8 "T.Aman (hybrid)" ///
						9 "Boro(local)" ///
						10 "Boro (HYV)" ///
						11 "Boro (hybrid)" ///
						12 "Wheat (local)" ///
						13 "Wheat (HYV)" ///
						14 "Maize" ///
						15 "Barley" ///
						16 "Job" ///
						17 "Cheena" ///
						18 "Kaun(Italian millet)" ///
						19 "Joar(Great millet)" ///
						20 "Bojra(Pearl millet)" ///
						-86 "Other (Major Cereal)" ///
						22 "Dhonche" ///
						23 "Jute" ///
						24 "Cotton" ///
						25 "Bamboo" ///
						-85 "Other (Fibre)" ///
						27 "Lentil(Moshur)" ///
						28 "Mung" ///
						29 "Black gram (Mashkalai)" ///
						30 "Chickling Vetch(Khesari)" ///
						31 "Chick pea (Chhola)" ///
						32 "Pigeon pea (Aarohor)" ///
						33 "Field pea (Motor)" ///
						34 "Soybean (Gori kalai or Kali motor)" ///
						-84 "Other Pulses" ///
						36 "Sesame" ///
						37 "Linseed(tishi)" ///
						38 "Mustard" ///
						39 "Ground nut/peanut" ///
						40 "Soybean" ///
						41 "Castor (rerri)" ///
						-83 "Others Oilseeds" ///
						43 "Chili" ///
						44 "Onion" ///
						45 "Garlic" ///
						46 "Turmeric" ///
						47 "Ginger" ///
						48 "Dhania/Coriander" ///
						-82 "Other spices" ///
						50 "Pumpkin" ///
						51 "Bringal eggplant" ///
						52 "BT Brinjal one or Bari brinjal one" ///
						53 "BT Brinjal two or Bari brinjal two" ///
						54 "BT Brinjal three or Bari brinjal three" ///
						55 "BT Brinjal four or Bari brinjal four" ///
						56 "Patal" ///
						57 "Okra" ///
						58 "Ridge gourd" ///
						59 "Bitter gourd" ///
						60 "Arum" ///
						61 "Ash gourd" ///
						62 "Cucumber" ///
						63 "Carrot" ///
						64 "Cow pea" ///
						65 "Snake gourd" ///
						66 "Danta" ///
						67 "Green banana/plantain" ///
						68 "Cauliflower" ///
						69 "Water gourd" ///
						70 "Sweet gourd" ///
						71 "Tomato" ///
						72 "Radish" ///
						73 "Turnip" ///
						74 "Green Papaya" ///
						75 "Kakrol" ///
						76 "Yam Stem" ///
						-81 "Other green Vegetables" ///
						78 "DrumStick" ///
						79 "Bean" ///
						80 "Coriander leaf" ///
						81 "Pui Shak" ///
						82 "Palang Shak (Spinach)" ///
						83 "Lal Shak" ///
						84 "Kalmi Shak" ///
						85 "Danta Shak" ///
						86 "Kachu Shak" ///
						87 "Lau Shak" ///
						88 "Mula Shak" ///
						89 "Khesari Shak" ///
						91 "Potato Leaves" ///
						92 "Cabbage" ///
						93 "Chinese cabbage" ///
						94 "Banana" ///
						95 "Mango" ///
						96 "Pineapple" ///
						97 "Jack fruit" ///
						98 "Papaya" ///
						99 "Water melon" ///
						100 "Bangi/Phuti/Musk melon" ///
						101 "Litchis" ///
						102 "Guava" ///
						103 "Ataa" ///
						104 "Orange" ///
						105 "Lemon" ///
						106 "Shaddock (pomelo)" ///
						107 "Black berry" ///
						-80 "Other fruits" ///
						109 "Boroi(Bitter Plum)" ///
						110 "Rose Apple" ///
						111 "Wood Apple" ///
						112 "Ambada/Hoq Plum" ///
						113 "Pomegranate" ///
						114 "Bilimbi" ///
						115 "Chalta" ///
						116 "Tamarind(pulp)" ///
						117 "Olive(wild)" ///
						118 "Coconut/Green Coconut" ///
						119 "Potato" ///
						120 "Sweet potato" ///
						121 "Mulberry(Tunt)" ///
						122 "Orange flesh sweet potato" ///
						123 "Sugurcan" ///
						124 "Date" ///
						125 "Palm" ///
						126 "Date Juice" ///
						127 "Tea" ///
						128 "Tobacco" ///
						129 "Bettlenut" ///
						130 "Bettleleaf" ///
						131 "Other Tobacco like crop" ///
						132 "Cut flower" ///
						133 "Paddy seedbed" ///
						134 "Tomato seedbed" ///
						135 "Bringal seedbed" ///
						136 "Cauliflower seedbed" ///
						137 "Cabbage seedbed" ///
						138 "Kohlrabi seedbed" ///
						139 "Tobacco seedbed" ///
						140 "Onion seedbed" ///
						141 "Chili seedbed" ///
						-79 "Other seedbed" ///
						-98 "N/A" ///
						142 "Grass" ///
						143 "Jute leaf/Paat shak" ///
						144 "Others", modify ///
						
						la val c5crop c5crop

	

	foreach x in c5pl c5sb c5tp c5wd c5hv c5thr {
	label var `x'_fam_lab_hours "Family labour (total hours)"
	}
	foreach x in c5pl c5sb c5tp c5wd c5hv c5thr {
	label var `x'_hired_lab_hours "Hired labour (total hours)"
	}

	foreach x in c5pl c5sb c5tp c5wd c5hv c5thr {
	label var `x'_total_wage "Total wage (Tk.)"
	}
	
	
	foreach x in c5urea c5tsp c5potash c5oth_chem_cost {
		
		g `x'_dec = `x'/c5area
	}
	
	g c5seedling_cost_dec = c5seedling_cost/c5area
	
	g c5urea_cost_kg = c5urea_cost/c5urea
	
	g c5tsp_cost_kg = c5tsp_cost/c5tsp
	
	g c5potash_cost_kg = c5potash_cost/c5potash
	
	recode c5tp_machine_cost 8 = 0
	
	drop *_dec *_kg SETOFmodule_c5
	
	order c5crop c5area, after(c5season_name)
	
	la var c5crop "Crop name"
	la var c5area "Area planted [Decimal]"
	la var c5threshing_system "Threshing system"
	la var c5crop_season_5 "Yearly"

	save "${final_data}${slash}SPIA_BIHS_2024_module_c5.dta", replace
	
	
	********************************************************************************     
	**# Module D1 
	********************************************************************************  
	 {
	** D1-A *** 
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified.dta", clear
	
	keep a1hhid_combined module_d1_count SETOFmodule_d1
	rename SETOFmodule_d1 setofmodule_d1
	collapse (first) a1hhid_combined module_d1_count, by(setofmodule_d1)

	preserve 
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_d-module_d1.csv", varnames(1) clear //unique HHs: 2742
	tempfile d1
	save "`d1'"
	restore 

	merge 1:m setofmodule_d1 using "`d1'"
	keep if _merge == 3 //one from master doesn't have an ID. 2742 HHs in D1
	sort a1hhid_combined d1cgiartech_id
	drop d1tech_stopreason_* parent_key key _merge setofmodule_d1 module_d1_count d1index

	* rename 
	rename d1tech_stopreason d1cgiartech_stopreason

	* replace substring in d1cgiartech_name
	replace d1cgiartech_name = subinstr(d1cgiartech_name,"(ম্যাজিক পাইপ)","", .)
	 
	* create new variables using d1tech_stopreason
	split d1cgiartech_stopreason, p(" ")
	drop d1cgiartech_stopreason
	destring d1cgiartech_stopreason* , replace 

	duplicates drop a1hhid_combined d1cgiartech_id , force
	 
	* save temporary dataset 
	tempfile d1_machinery_main 
	save "`d1_machinery_main'"

	****** Module D1-A - Adding Resurveys ******
	use "${raw_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear

	keep a1hhid_combined module_d1_count SETOFmodule_d1
	rename SETOFmodule_d1 setofmodule_d1

	collapse (first) a1hhid_combined module_d1_count, by(setofmodule_d1)
	drop if setofmodule_d1 == ""

	preserve 
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(module_d1) clear 
	tempfile d1
	rename SETOFmodule_d1 setofmodule_d1
	save "`d1'"
	restore 

	merge 1:m setofmodule_d1 using "`d1'"
	keep if _merge == 3 
	sort a1hhid_combined d1cgiartech_id
	rename PARENT_KEY parent_key
	rename KEY key
	drop d1tech_stopreason_* parent_key key _merge setofmodule_d1 module_d1_count d1index

	* replace substring in d1cgiartech_name
	replace d1cgiartech_name = subinstr(d1cgiartech_name,"(ম্যাজিক পাইপ)","", .)
	 
	* create new variables using d1tech_stopreason
	split d1tech_stopreason, p(" ")
	drop d1tech_stopreason
	destring d1tech_stopreason* , replace

	rename d1tech_stopreason1 d1cgiartech_stopreason1
	rename d1tech_stopreason2 d1cgiartech_stopreason2

	* save re-survey dataset 
	tempfile d1_machinery_resurvey
	save "`d1_machinery_resurvey'" 

	****** Module D1-A - Merging ******
	* merge with the main data
	use "`d1_machinery_main'" , clear 
	append using "`d1_machinery_resurvey'" 
	 
	* label value 
	#delimit ;
	label define reason_not_to ///
	1 "Not available in the market" ///
	2 "Don't know about this technology" ///
	3 "Use new technologies" /// 
	4 "This technology is obsolete" ///
	5 "This technology is expensive" ///
	6 "Lack of skills to manage it" ///
	7 "This technology is not suitable for use" ///
	8 "Parts for this machine are not available" ///
	9 "Lack of skilled manpower for repair" ///
	10 "This machine cannot be rented" , modify ;
	#delimit cr
	label value d1cgiartech_stopreason1 d1cgiartech_stopreason2 d1cgiartech_stopreason3 reason_not_to

	* label variable 
	label var d1cgiartech_id "Technology ID"        
	label var d1cgiartech_name "Technology name"
	label var d1cgiartech_know "Are you aware of this technology?"
	label var d1cgiartech_usage "Do you use this technology now?"
	label var d1cgiartech_owner "If yes, is it rented or owned?"
	label var d1cgiartech_past "Have you used this technology in the past?"
	label var d1cgiartech_startyear "When did you start using this technology?"
	label var d1cgiartech_stopyear "If you no longer use it, when did you stop using it?"
	label var d1cgiartech_stopreason1 "Reason for not using it now: 1"
	label var d1cgiartech_stopreason2 "Reason for not using it now: 2"
	label var d1cgiartech_stopreason3 "Reason for not using it now: 3"
	label var d1cgiartech_introyear "When was it first available in your village?" 
	label var a1hhid_combined "household ID"

	* Order
	order a1hhid_combined d1cgiartech_id d1cgiartech_name d1cgiartech_know ///
	d1cgiartech_usage d1cgiartech_owner d1cgiartech_introyear d1cgiartech_past /// 
	d1cgiartech_startyear d1cgiartech_stopyear d1cgiartech_stopreason1 d1cgiartech_stopreason2 d1cgiartech_stopreason3
	 
	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	* save the final dataset 
	save "${final_data}${slash}SPIA_BIHS_2024_module_d1_machinery.dta", replace
	********************************************************************************
	
	*** D1-B ***
	
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified.dta", clear
	keep a1hhid_combined SETOFmodule_d1_2
	rename SETOFmodule_d1_2 setofmodule_d1_2
	collapse (first) a1hhid_combined , by(setofmodule_d1_2) // 2741 unique obs

	preserve 
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_d-module_d1_2.csv", varnames(1) clear 
	tempfile d1_2
	save "`d1_2'"
	restore 

	merge 1:m setofmodule_d1_2 using "`d1_2'"
	keep if _merge == 3 
	drop _merge
	drop d1trait_name d1trait_stopreason_* d1trait_index setofmodule_d1_2 parent_key key 
	rename d1trait_name_eng d1trait_name 
	rename d1trait_stopreason d1cgiartrait_stopreason

	* create new variables using d1tech_stopreason
	split d1cgiartrait_stopreason, p(" ")
	foreach x in 1 2 3 4 {
	replace d1cgiartrait_stopreason`x' = "" if inlist(d1cgiartrait_stopreason`x',"jat","jay","na","dhan","bebihar")
	replace d1cgiartrait_stopreason`x' = "" if inlist(d1cgiartrait_stopreason`x', "kori","Onno","Pora","Uchofolonsil","Karon","Posol") 
	replace d1cgiartrait_stopreason`x' = "" if inlist(d1cgiartrait_stopreason`x', "abohawar","fosol","kom","hoy","kom","sathy","miliye")	
	}
	destring d1cgiartrait_stopreason* , replace

	drop d1cgiartrait_stopreason d1cgiartrait_stopreason4

	* sort
	sort a1hhid_combined d1trait_id

	* save re-survey dataset 
	tempfile d1_seed_main
	save "`d1_seed_main'" 

	****** Module D1-B - Adding Resurveys ******
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear
	keep a1hhid_combined SETOFmodule_d1_2
	rename SETOFmodule_d1_2 setofmodule_d1_2

	collapse (first) a1hhid_combined , by(setofmodule_d1_2)
	drop if setofmodule_d1_2 == ""

	preserve 
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(module_d1_2) clear 
	rename SETOFmodule_d1_2 setofmodule_d1_2
	tempfile d1_2
	save "`d1_2'"
	restore 

	merge 1:m setofmodule_d1_2 using "`d1_2'"
	keep if _merge == 3 
	drop _merge
	drop d1trait_name d1trait_stopreason_* d1trait_index setofmodule_d1_2 PARENT_KEY KEY
	rename d1trait_name_eng d1trait_name 
	rename d1trait_stopreason d1cgiartrait_stopreason

	* create new variables using d1tech_stopreason
	split d1cgiartrait_stopreason, p(" ")
	foreach x in 1 2 {
	replace d1cgiartrait_stopreason`x' = "" if inlist(d1cgiartrait_stopreason`x',"jat","jay","na","dhan","bebihar")
	replace d1cgiartrait_stopreason`x' = "" if inlist(d1cgiartrait_stopreason`x', "kori","Onno","Pora","Uchofolonsil","Karon","Posol") 
	replace d1cgiartrait_stopreason`x' = "" if inlist(d1cgiartrait_stopreason`x', "abohawar","fosol","kom","hoy","kom","sathy","miliye")	
	}
	destring d1cgiartrait_stopreason* , replace

	drop d1cgiartrait_stopreason 

	* sort
	sort a1hhid_combined d1trait_id

	* save re-survey dataset 
	tempfile d1_seed_resurvey
	save "`d1_seed_resurvey'" 

	****** Module D1-B - Merging ******
	* merge with the main data
	use "`d1_seed_main'" , clear 
	append using "`d1_seed_resurvey'" 
	 
	replace d1trait_name = "Blast resistant" if regexm(d1trait_name, "Blast-resistant")
	replace d1trait_name = "Moderately resistance to blast" if regexm(d1trait_name, "Moderately resistanc")
	replace d1trait_name = "Stemphylium blight resistant" if regexm(d1trait_name, "Resistance to Stemph")
	replace d1trait_name = "Rust/foot/root resistant" if regexm(d1trait_name, "Rust foot and root r")
	replace d1trait_name = "UG99-tolerant" if regexm(d1trait_name, "Ug99- tolerant")
	replace d1trait_name = "Bio-fortified[Protein/Iron enriched]" if regexm(d1trait_name, "Bio-fortified")

	* label value 
	#delimit ;
	label define reason_not_to_trait ///
	1 "Not available in the market" ///
	2 "Do not know about the technology" ///
	3 "Replaced with new tech" /// 
	4 "It became obsolete" ///
	5 "Technology is inappropriate" ///
	6 "Expensive", modify ;
	#delimit cr
	label value d1cgiartrait_stopreason1 d1cgiartrait_stopreason2 d1cgiartrait_stopreason3 reason_not_to_trait

	label define yesno 0 "No" 1 "Yes" 
	label value d1cgiartrait_know d1cgiartrait_usage d1cgiartrait_past yesno

	* rename seed variety names 
	rename d1trait_name d1cgiartrait_name
	rename d1trait_id d1cgiartrait_id

	* label variable 
	label var a1hhid_combined "Household ID"
	label var d1cgiartrait_id "Trait id"
	label var d1cgiartrait_name "Trait name"
	label var d1cgiartrait_know "Are you aware of this trait?" 
	label var d1cgiartrait_usage "Do you use a variety with this trait now?"
	label var d1cgiartrait_past "Have you used a variety with this trait in the past?"
	label var d1cgiartrait_startyear "When did you start using a variety with this trait?"
	label var d1cgiartrait_stopyear "If you no longer use it, when did you stop using it?"
	label var d1cgiartrait_introyear "When was this trait first available in your village?"
	label var d1cgiartrait_stopreason1 "Reason for not using it now:1"
	label var d1cgiartrait_stopreason2 "Reason for not using it now:2"
	label var d1cgiartrait_stopreason3 "Reason for not using it now:3" 

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	save "${final_data}${slash}SPIA_BIHS_2024_module_d1_seedtechnology.dta", replace
	
	 }
	********************************************************************************
	**# MODULE D2
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1division a1district a1upazila a1union a1mouza a1village ///
	a1hhid a1hhid_combined d2* 

	drop d2paddy_harvest d2paddy_thresh d2paddy_bag d2paddy_storage d2paddy_thresh__96 ///
	d2paddy_storage__96 a1hhid a1division a1district a1upazila a1union a1mouza a1village

	drop if d2plant_paddy == . 

	* label variable 
	label var a1hhid_combined "Household ID"
	label var d2plant_paddy "Did you plant paddy in the past year?"
	label var d2paddy_harvest_1 "Harvest the paddy rice:sickle/scythe"
	label var d2paddy_harvest_2 "Harvest the paddy rice:motorized harvester"
	label var d2paddy_harvest_3 "Harvest the paddy rice:not yet harvested"

	label var d2paddy_thresh_1 "Thresh the rice:Trampled by cattle/oxen"    
	label var d2paddy_thresh_2 "Thresh the rice:Beat with sticks"
	label var d2paddy_thresh_3 "Thresh the rice:Beat with a flail"
	label var d2paddy_thresh_4 "Thresh the rice:Used a treadle thresher"
	label var d2paddy_thresh_5 "Thresh the rice:Used a motorized thresher"
	label var d2paddy_thresh_6 "Thresh the rice:Did not thresh"
	label var d2paddy_thresh_oth "Thresh the rice:Other(specify)"

	label var d2paddy_bag_1 "Put the paddy rice in bags/containers:in rice warehouse"
	label var d2paddy_bag_2 "Put the paddy rice in bags/containers:in the drum"
	label var d2paddy_bag_3 "Put the paddy rice in bags/containers:in the sack"
	label var d2paddy_bag_0 "Donot put paddy rice in bags/containers"

	label var d2paddy_storage_1 "Storage location of paddy/rice:Residential house"    
	label var d2paddy_storage_2 "Storage location of paddy/rice:Cribs"
	label var d2paddy_storage_3 "Storage location of paddy/rice:Granaries"
	label var d2paddy_storage_4 "Storage location of paddy/rice:Warehouses"
	label var d2paddy_storage_5 "Storage location of paddy/rice:Storage silos"
	label var d2paddy_storage_6 "Storage location of paddy/rice:Do not store"
	label var d2paddy_storage_oth "Storage location of paddy/rice:Other(specify)"

	label var d2insect_attack "Rice has ever been attacked by insects/rodents/disease while in storage?"

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	save "${final_data}${slash}SPIA_BIHS_2024_module_d2.dta", replace
	 }
	********************************************************************************
	**# MODULE D3
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1hhid a1hhid_combined d3* 

	drop d3ag_advice_topic d3ag_advice_topic__96 d3ag_advice_go_topic ///
	d3ag_advice_go_topic__96 d3ngo_advice_topic d3ngo_advice_topic__96 a1hhid 

	collapse (first) d3* , by(a1hhid_combined)

	labe var a1hhid_combined "Household ID"

	#delimit ;
	label define info_source ///
	1 "Own family" ///
	2 "Friend/neighbor" ///
	3 "Agricultural inputs dealer" /// 
	4 "Agricultural extension worker" ///
	5 "NGO/private company representative" ///
	6 "Farmer's School" ///
	7 "Radio program" ///
	8 "Television" ///
	9 "Mobile phone messages" ///
	10 "Internet" ///
	-96 "Other" , modify ;
	#delimit cr
	label define yesno_l1 0 "No" 1 "Yes" -98 "NA" , modify

	label value d3ag_visit d3ag_advice_utility d3ag_visit_go d3ag_advice_go_utility ///
	d3ngo_visit d3ngo_advice_utility yesno_l1
	label value d3ngo_advice_topic_* d3ag_advice_go_topic_*  yesno_l1
	label value d3ag_advice_topic_1 d3ag_advice_topic_2 d3ag_advice_topic_3 d3ag_advice_topic_4 d3ag_advice_topic_5 d3ag_advice_topic_6 d3ag_advice_topic_7 d3ag_advice_topic_8 d3ag_advice_topic_9  yesno_l1
	label value d3reliable_source info_source

	label var d3ag_advice_topic_1 "Advice by AGO(visit):Seed"        
	label var d3ag_advice_topic_2 "Advice by AGO(visit):Sapling"
	label var d3ag_advice_topic_3 "Advice by AGO(visit):Fertilizer"
	label var d3ag_advice_topic_4 "Advice by AGO(visit):Irrigation use"
	label var d3ag_advice_topic_5 "Advice by AGO(visit):Pesticide"
	label var d3ag_advice_topic_6 "Advice by AGO(visit):Insecticide"
	label var d3ag_advice_topic_7 "Advice by AGO(visit):Using farm machinery"
	label var d3ag_advice_topic_8 "Advice by AGO(visit):Fisheries"
	label var d3ag_advice_topic_9 "Advice by AGO(visit):Livestock"
	label var d3ag_advice_topic_oth "Advice by AGO(visit):Others"

	label var d3ag_advice_go_topic_1 "Advice by AGO(call):Seed"     
	label var d3ag_advice_go_topic_2 "Advice by AGO(call):Sapling"
	label var d3ag_advice_go_topic_3 "Advice by AGO(call):Fertilizer"
	label var d3ag_advice_go_topic_4 "Advice by AGO(call):Irrigation use"
	label var d3ag_advice_go_topic_5 "Advice by AGO(call):Pesticide"
	label var d3ag_advice_go_topic_6 "Advice by AGO(call):Insecticide"
	label var d3ag_advice_go_topic_7 "Advice by AGO(call):Using farm machinery"
	label var d3ag_advice_go_topic_8 "Advice by AGO(call):Fisheries"
	label var d3ag_advice_go_topic_9 "Advice by AGO(call):Livestock"
	label var d3agadvice_go_topic_oth "Advice by AGO(call):Others"

	label var d3ngo_advice_topic_1 "Advice by NGO:Seed"       
	label var d3ngo_advice_topic_2 "Advice by NGO:Sapling"
	label var d3ngo_advice_topic_3 "Advice by NGO:Fertilizer"
	label var d3ngo_advice_topic_4 "Advice by NGO:Irrigation use"
	label var d3ngo_advice_topic_5 "Advice by NGO:Pesticide"
	label var d3ngo_advice_topic_6 "Advice by NGO:Insecticide"
	label var d3ngo_advice_topic_7 "Advice by NGO:Using farm machinery"
	label var d3ngo_advice_topic_8 "Advice by NGO:Fisheries"
	label var d3ngo_advice_topic_9 "Advice by NGO:Livestock"
	label var d3ngo_advice_topic_oth "Advice by NGO:Others"

	label var d3reliable_source "Information source you rely on for growing your rice crops"
	label var d3ag_visit "Received a visit from an AG extension officer?"
	label var d3ag_advice_utility "Was the advice given useful?"
	label var d3ag_visit_go "Did you go to the AG extension/call them?"
	label var d3ag_advice_go_utility "Was the advice given useful?"
	label var d3ngo_visit "Have you received a visit/call/visted an NGO?"
	label var d3ngo_advice_utility "Was the advice given useful?"

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	save "${final_data}${slash}SPIA_BIHS_2024_module_d3.dta", replace
	 }
	********************************************************************************
	**# MODULE E 
	********************************************************************************
	 {
	* Module E1-E4
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_er.csv", varnames(1) clear
	keep e1pond_id e1plot_type fish_list fish_name module_e1_4_count setofmodule_e1_4 parent_key key setofmodule_er
	rename e1pond_id b1plot_num 
	duplicates drop setofmodule_er b1plot_num , force //dropping duplicate values since we are only interested in the plot per year. 

	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_e1_4.csv", varnames(1) clear
	keep if inlist(e1fish_index,"1","2")
	tempfile e1
	save "`e1'"
	restore 
	merge 1:m setofmodule_e1_4 using "`e1'" , nogenerate keep(1 3) //11 ponds have duplicate entries that we drop
	tempfile er
	save "`er'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	keep a1hhid_combined SETOFmodule_er module_er_count
	rename SETOFmodule_er setofmodule_er
	keep if setofmodule_er != ""
	duplicates drop 
	merge 1:m setofmodule_er using "`er'" , nogenerate keep(3) // 8 plots/5 households donot match - check in the resurveys/maybe didn't consent to resurvey
	tempfile er_comb
	save "`er_comb'"

	** keep pond_id of plots that do aquaculture ** 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
	keep KEY b1fishing_count a1hhid_plotnum b1plotsize_decimal ///
	b1plot_fishing b1flood_depth b1_operation_status a1hhid_combined b1plot_num 
	keep if b1plot_fishing == 1 
	duplicates drop 
	merge 1:m a1hhid_combined b1plot_num using "`er_comb'" , nogenerate keep(2 3) //65 plots from module b1 don't match and 19 plots from er don't match.

	* Number of unique values of a1hhid_combined is  681
	* Number of unique values of a1hhid_combined b1plot_num is 760

	** drop those that need to be resurveyed or those that said no to being resurveyed 
	preserve
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear 
	collapse (max) resurvey , by(a1hhid_combined) 
	drop if resurvey == 1 
	tempfile resurvey
	save "`resurvey'"
	restore 
	merge m:1 a1hhid_combined using "`resurvey'" , nogenerate keep(3)
	drop resurvey

	tempfile main_survey_e1
	save "`main_survey_e1'"

	* Number of unique values of a1hhid_combined is  608
	* Number of unique values of a1hhid_combined b1plot_num is  679
	* Note 73 households and 81 plots are dropped because of the resurveys.

	************* append resurveys *************************
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(module_er) clear 
	keep e1pond_id e1plot_type fish_list fish_name module_e1_4_count SETOFmodule_e1_4 PARENT_KEY KEY SETOFmodule_er
	rename e1pond_id b1plot_num 
	rename SETOFmodule_er setofmodule_er
	rename SETOFmodule_e1_4 setofmodule_e1_4
	duplicates drop setofmodule_er b1plot_num , force //dropping duplicate values since we are only interested in the plot per year. 

	preserve
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(module_e1_4) clear 
	keep if inlist(e1fish_index,1,2)
	rename SETOFmodule_e1_4 setofmodule_e1_4
	tempfile e1_resurvey
	save "`e1_resurvey'"
	restore 
	merge 1:m setofmodule_e1_4 using "`e1_resurvey'" , nogenerate keep(1 3) //4 ponds have duplicate entries that we drop
	tempfile er_resurvey
	save "`er_resurvey'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear
	keep a1hhid_combined SETOFmodule_er module_er_count
	rename SETOFmodule_er setofmodule_er
	keep if setofmodule_er != ""
	duplicates drop 
	merge 1:m setofmodule_er using "`er_resurvey'" , nogenerate keep(3) // 3 plots don't match to any household
	tempfile er_comb_resurvey
	save "`er_comb_resurvey'"

	** keep pond_id of plots that do aquaculture ** 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
	keep KEY b1fishing_count a1hhid_plotnum b1plotsize_decimal ///
	b1plot_fishing b1flood_depth b1_operation_status a1hhid_combined b1plot_num 
	keep if b1plot_fishing == 1 
	duplicates drop 
	merge 1:m a1hhid_combined b1plot_num using "`er_comb_resurvey'" , nogenerate keep(2 3) 

	tostring e1fish_index , replace
	tostring e1pond_type_oth , replace 

	gen resurvey = 1 

	tempfile resurvey_e1
	save "`resurvey_e1'"

	use "`main_survey_e1'" , clear 
	append using "`resurvey_e1'" , force 

	duplicates tag a1hhid_combined b1plot_num , gen(dup)
	drop if dup == 3 & resurvey != 1 
	************ cleaning *******************************

	* make the date variable 
	gen e1purchase_finger_time_1 = date(e1purchase_finger_time, "MDY")
	format e1purchase_finger_time_1 %td
	drop e1purchase_finger_time
	rename e1purchase_finger_time_1 e1purchase_finger_time
	gen e1purchase_finger_month=month(e1purchase_finger_time)
	order e1purchase_finger_time e1purchase_finger_month, before(e1source_fingerling) 

	* fingerlings 
	split e1source_fingerling, p(" ")
	drop e1source_fingerling  e1source_fingerling_*
	rename e1source_fingerling1 e1source_fingerling_1
	rename e1source_fingerling2 e1source_fingerling_2
	rename e1source_fingerling3 e1source_fingerling_3
	destring e1source_fingerling_* , replace

	*****
	* LABEL VALUE 
	#delimit ;
	label define pond_type ///
	1 "Pond" ///
	2 "Channel" ///
	3 "Flooded rice plots" ///
	-96 "Other" , modify ;
	#delimit cr

	label define yesno_l1 0 "No" 1 "Yes" -98 "NA" , modify

	#delimit ;
	label define plot_type1 ///
	1 "Homestead" ///
	2 "Cultivable/arable land" ///
	3 "Pasture" /// 
	4 "Bush/forest" ///
	5 "Waste/non-arable land" ///
	6 "Land in riverbed" ///
	7 "Other residential/commercial plot" ///
	8 "Cultivable pond" ///
	9 "Derelict pond" ///
	10 "Garden (wood/Fruit)" ///
	11 "Floating plot" ///
	12 "Only for seed bed" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define operational_status1 ///
	1 "Own operated" ///
	2 "Rented/leased in for cash" ///
	3 "Rented/leased out for cash" /// 
	4 "Rented/leased in/crop share" ///
	5 "Rented/leased out/crop share" ///
	6 "Mortgaged in" ///
	7 "Mortgage out" ///
	8 "Group leased in with other farmer" ///
	9 "Leased out to NGO" ///
	10 "Taken from joint owner" ///
	11 "Jointly with other owners" ///
	12 "Rented in for certain amount of crops" ///
	13 "Rented out for certain amount of crops" ///
	14 "Free of cost" , modify ;
	#delimit cr

	#delimit ;
	label define pond_sourcel1 ///
	1 "Rain water" ///
	2 "Surface (river, lake, creek, stream, etc)" ///
	3 "Groundwater (tube well, well, etc.)" /// 
	4 "Irrigation canal" ///
	5 "Dam" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define fingerling_source1 ///
	1 "Own farm" ///
	2 "Neighbor or relative" ///
	3 "Farmers group" /// 
	4 "Government hatchery" ///
	5 "Private hatchery" ///
	6 "Local dealer (commission agent)" ///
	7 "NGO" ///
	8 "Hawker hawking fingerlings" ///
	9 "Nursery" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define tilapia_strain ///
	1 "Chitralada" ///
	2 "GIFT" ///
	3 "GenoMar Supreme Tilapia (GST)" /// 
	4 "GIFT-WF" ///
	5 "GIFU" ///
	6 "FaST" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define Rohu_strain ///
	1 "G0" ///
	2 "G1" ///
	3 "G2" /// 
	4 "G3" ///
	5 "G4" ///
	-96 "Other" , modify ;
	#delimit cr

	* LABEL DEFINE
	label value b1_operation_status operational_status1
	label value e1plot_type plot_type1
	label value b1plot_fishing e1fish_lastyear e1monoculture e1fish_everyyear ///
	e1fingerling_lastyear e1integrated_agri e1integrated_now e1gift_tilapia e1g3_rohu yesno_l1
	label value e1pond_type pond_type
	label value e1pond_source pond_sourcel1
	label value e1source_fingerling_1 e1source_fingerling_2 e1source_fingerling_3 fingerling_source1
	label value e1strain_tilapia tilapia_strain
	label value e1strain_rohu Rohu_strain

	* LABEL VAR 
	label var b1plot_num "Serial of the plot/pond"
	label var e1plot_type "Type of pond/plot"
	label var e1fish_name  "Name of fish"   
	label var e1fish_lastyear "Did you farm the fish in the past 12 months?"
	label var e1fish_startyear "In what year did you start producing the fish for the first time?"
	label var e1monoculture "Are you practicing monoculture?"
	label var e1fish_everyyear "Have you farmed fish every year since start year?"
	label var e1fish_gap "If not, for how many years have you not been involved in fish farming since then?"
	label var e1fingerling_lastyear "Did you purchase fingerlings in the last 12 months?"
	label var e1pond_type "Pond facility Type"
	label var e1pond_type_oth  "Pond facility (Specify other)"
	label var e1pond_size "Size of the facility in decimal?"   
	label var e1pond_depth "Average water depth for this facility (in ft)"
	label var e1pond_source "Source of pond water"
	label var e1pond_source_oth "Source of pond(other)"
	label var e1integrated_agri "Practiced integrated agriculture/aquaculture on this pond"
	label var e1integrated_now "Currently practice the above method"
	label var e1purchase_finger_time "Month/year of purchasing fingerlings?"
	label var e1source_fingerling_1 "Source of fingerlings-1"
	label var e1source_fingerling_2 "Source of fingerlings-2"
	label var e1source_fingerling_3 "Source of fingerlings-3"
	label var e1distance_hatchery "Approx distance from the hatchery(meters)"
	label var e1hatchery_year "Number of years of business from provider"
	label var e1strain_tilapia "Name of the strain of Tilapia purchased"
	label var e1strain_tilapia_oth "Tilapia strain other (specify)"
	label var e1strain_rohu "Name of the strain of Rohu purchased"
	label var e1strain_rohu_oth "Rohu strain other (specify)"
	label var e1g3_rohu "Is this G3 rohu?"
	label var e1gift_tilapia "Is this tilapia GIFT tilapia?" 
	label var e1fish_amount "Fingerlings (fish) stocked [kg]?" 
	label var e1fish_monosex "Fingerlings that are monosex male tilapia?[kg]"
	label var e1totprice_fingerling "Total price paid for these fingerlings"
	label var e1harvest_month "Harvest of the fish [year and month]"
	label var e1fish_sales "To whom did you mainly sell to"
	label var e1fish_sales_oth "Sale(other)"    
	label var e1fish_id "Fish id"
	label var e1purchase_finger_month "Month of purchasing fingerlings(numeric)"
	label var e1know_hatchery "Know the name of the hatchery that sold these fingerlings"
	label var e1hatchery_village "Know the village/town in which this hatchery is located"
	label var e1hatchery_address "Address of the hatchery"
	label var e1know_num "Know the address/phone of the hatchery"
	label var e1hatchery_phone "Phone number of the hatchery"

	* e1strain_tilapia_oth
	replace e1strain_tilapia_oth = "Don't know" if inlist(e1strain_tilapia_oth, "Bolta pare na" , "Bolte pare na", "Bolte parena", "Jana na", "Jana nai")
	replace e1strain_tilapia_oth = "Don't know" if inlist(e1strain_tilapia_oth, "Jane na" , "Jane na name", "Jane naa", "Janena","Jani na" , "Janina")
	replace e1strain_tilapia_oth = "Don't know" if inlist(e1strain_tilapia_oth, "Jater nam jane na" , "Jatier name boltay pari na" , "Nam bolte pare na" , "Nam bolte parena")
	replace e1strain_tilapia_oth = "Don't know" if inlist(e1strain_tilapia_oth, "Nam jane na" , "Nam janena" , "Nam janina" , " Nam shai" , "Nm blte pre na")
	replace e1strain_tilapia_oth = "Don't know" if inlist(e1strain_tilapia_oth, "Sada tilapia" , "Telapia")
	replace e1strain_tilapia_oth = "Monosex" if inlist(e1strain_tilapia_oth, "Momosex" , "Momosux" , "Monosex" , "Monosex,desi telapia" , "Monosix") 
	replace e1strain_tilapia_oth = "Hybrid" if inlist(e1strain_tilapia_oth, "Hay brid" , "Hibright" , "Hibrit" , "Hivrite" , "Huibrid" , "Hybird" , "Hybrid", "Hybrid Telapia")
	replace e1strain_tilapia_oth = "Hybrid" if inlist(e1strain_tilapia_oth, "Hybride" , "Hybried" , "Hybrit")
	replace e1strain_tilapia_oth = "Local Tilapia" if inlist(e1strain_tilapia_oth, "Dasi" , "Dasi taliapia" , "Deshe" , "Deshi" , "Deshi Telapia" ,"Lokal")
	replace e1strain_tilapia_oth = "Local Tilapia" if inlist(e1strain_tilapia_oth, "Dasi" , "Deshi jat" , "Deshi jath" , "Deshi relapiya" , "Deshi telapia" , "Desi")
	replace e1strain_tilapia_oth = "Small Tilapia" if inlist(e1strain_tilapia_oth, "Chipi")
	replace e1strain_tilapia_oth = "Nile Tilapia" if inlist(e1strain_tilapia_oth, "Nailotika" , "Laylon tika")
	replace e1strain_tilapia_oth = "Hybrid" if inlist(e1strain_tilapia_oth, "Cp talapia" , "Cross telapia" , "CV")
	replace e1strain_tilapia_oth = "Local Tilapia" if inlist(e1strain_tilapia_oth, "Khursuno" , "Laikotika","Melitika mach","Mohosin telapia","Nam shai","Kalo telepia" ,"Gipi")

	* e1strain_rohu_oth
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Blota pare na" , "Boltay pary na")
	replace e1strain_rohu_oth = "Local carp" if inlist(e1strain_rohu_oth, "Dasi rohu" , "Deshe" , "Deshi" , "Deshi  Rui" , "Deshi Jat" , "Deshi Rui") 
	replace e1strain_rohu_oth = "Local carp" if inlist(e1strain_rohu_oth, "Deshi jath" , "Deshi pona" , "Deshi rui" , "Deshio" , "Desi") 
	replace e1strain_rohu_oth = "Local carp" if inlist(e1strain_rohu_oth, "Desi rui" , "Desu" , "Dasi","Dasi pona(janana)","Deshi jat" , "Deshi jater" , "Dashi") 
	replace e1strain_rohu_oth = "Hybrid" if inlist(e1strain_rohu_oth, "Hybrid" , "Hybrid jat", "Hivrite","Valo jat er Rui","Cross rohu") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Jane" , "Janen na" , "Jat er name bolte pare nai" , "Jne na" , "Jat name bolta para na" , "Jater name janena") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Nam Janena" , "Nam janen na" , "Nam jani na","Name bolta pare na","Name boltay pari na" , "jane na" , "Jater nam janena") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Name bolte parche na" , "Name jane na" , "Nam jani na","Name bolta pare na","Name boltay pari na") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Jana nai" , "Jane na", "Janena", "Jani na", "Janina", "Jater nam jane na", "Na") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Nam bolte pare na" , "Nam bolte parena", "Nam jane na","Nam janina","Pojatir name janina") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Rui" , "Rui mach" , "Mone nei" , "Onoto jader mas" , "Omace") 
	replace e1strain_rohu_oth = "Common carp" if inlist(e1strain_rohu_oth, "common carp" , "Rui shadharon") 
	replace e1strain_rohu_oth = "Common carp" if inlist(e1strain_rohu_oth, "Valo jat" , "Valo jat rui") 
	replace e1strain_rohu_oth = "Boli carp" if inlist(e1strain_rohu_oth, "Boli Rui") 
	replace e1strain_rohu_oth = "Local carp" if inlist(e1strain_rohu_oth, "Koras") 
	replace e1strain_rohu_oth = "Local carp" if inlist(e1strain_rohu_oth, "Bolte parena, deshi bole") 
	replace e1strain_rohu_oth = "Don't know" if inlist(e1strain_rohu_oth, "Boro dhoron er jat") 

	* fix GIFT 
	replace e1gift_tilapia = 0 if inlist(e1strain_tilapia,1,3,5,6)
	replace e1g3_rohu = 0 if inlist(e1strain_rohu,1,2,3,5)

	* Order 
	order a* b* e*

	* Drop 
	drop module_er_count setofmodule_er fish_list fish_name module_e1_4_count setofmodule_e1_4 parent_key key e1fish_index a1hhid_plotnum resurvey dup PARENT_KEY
		
	* Save
	save "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", replace
	********************************************************************************
	* E5
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_er.csv", varnames(1) clear
	keep e1pond_id e1plot_type e5* parent_key key setofmodule_er parent_key key setofmodule_er
	rename e1pond_id b1plot_num 
	duplicates drop setofmodule_er b1plot_num , force //dropping duplicate values since we are only interested in the plot per year. 
	tempfile er
	save "`er'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	keep a1hhid_combined SETOFmodule_er module_er_count
	rename SETOFmodule_er setofmodule_er
	keep if setofmodule_er != ""
	duplicates drop 
	merge 1:m setofmodule_er using "`er'" , nogenerate keep(3) 
	tempfile er_comb
	save "`er_comb'"

	** keep pond_id of plots that do aquaculture ** 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
	keep KEY b1fishing_count a1hhid_plotnum b1plotsize_decimal ///
	b1plot_fishing b1flood_depth b1_operation_status a1hhid_combined b1plot_num 
	keep if b1plot_fishing == 1 
	duplicates drop 
	merge 1:1 a1hhid_combined b1plot_num using "`er_comb'" , nogenerate keep(2 3) //65 plots from module b1 don't match and 19 plots from er don't match.

	preserve
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear 
	collapse (max) resurvey , by(a1hhid_combined) 
	drop if resurvey == 1 
	tempfile resurvey
	save "`resurvey'"
	restore 
	merge m:1 a1hhid_combined using "`resurvey'" , nogenerate keep(3)
	drop resurvey

	tempfile main_survey_e5
	save "`main_survey_e5'"

	************* append resurveys *************************
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(module_er) clear 
	keep e1pond_id e1plot_type e5* PARENT_KEY KEY SETOFmodule_er SETOFmodule_e1_4 
	rename e1pond_id b1plot_num 
	rename SETOFmodule_er setofmodule_er
	rename SETOFmodule_e1_4 setofmodule_e1_4
	duplicates drop setofmodule_er b1plot_num , force //dropping duplicate values since we are only interested in the plot per year. 
	tempfile er_resurvey
	save "`er_resurvey'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear
	keep a1hhid_combined SETOFmodule_er module_er_count
	rename SETOFmodule_er setofmodule_er
	keep if setofmodule_er != ""
	duplicates drop 
	merge 1:m setofmodule_er using "`er_resurvey'" , nogenerate keep(3) // 3 plots don't match to any household
	tempfile er_comb_resurvey
	save "`er_comb_resurvey'"

	** keep pond_id of plots that do aquaculture ** 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
	keep KEY b1fishing_count a1hhid_plotnum b1plotsize_decimal ///
	b1plot_fishing b1flood_depth b1_operation_status a1hhid_combined b1plot_num 
	keep if b1plot_fishing == 1 
	duplicates drop 
	merge 1:1 a1hhid_combined b1plot_num using "`er_comb_resurvey'" , nogenerate keep(2 3) 

	gen resurvey = 1 
	tempfile resurvey_e5
	save "`resurvey_e5'"

	use "`main_survey_e5'" , clear 
	append using "`resurvey_e5'" , force 

	duplicates tag a1hhid_combined b1plot_num , gen(dup)
	drop if dup > 0 & resurvey != 1 

	******* CLEANING *************
	* keep 
	keep a1hhid_combined b1* e5* 
	* destring
	destring e5farm_startyear , replace

	* Fish species
	rename e5fish_species_oth_s e5fish_oth_s
	rename e5fish_species_oth_l e5fish_oth_l
	drop e5fish_species_* 
	split e5fish_species, p(" ")
	drop e5fish_species
	destring e5fish_species* , replace

	*Alternate uses 
	drop e5fish_alternative_*

	* species
	drop e5reason_lost_* 
	split e5reason_lost, p(" ")
	drop e5reason_lost
	destring e5reason_lost* , replace

	* Value label 
	#delimit ;
	label define fish_breedl1 ///
	1  "Silver carp" ///
	2  "Grass carp" ///
	3  "Mirror carp" /// 
	4  "Common carp" ///
	5  "Karfu" ///
	6   "Rui"  ///
	7   "Katla" ///
	8   "Mrigel" ///
	9   "Kalibaus" ///
	10  "Telapia/Nailotica" ///
	11  "Pona" ///
	12  "Koi" ///
	13  "Magur"  ///
	14  "Shingi" ///
	15  "Khalse"  /// 
	16  "Shol/Gajar/Taki" ///
	17  "Puti/Swarputi" ///
	18  "Prawn (Golda Chingri)" ///
	19  "Shrimp (Bagda Chingri)" ///
	20  "Tengra/Baim" ///
	21  "Mola/Dhela/Kachki/Chapila" ///
	22  "Ilish/hilsha" ///
	23  "Sea fish" ///
	24  "Pangesh" ///
	25  "Other Large fish" ///
	26  "Other Small fish" ///
	-96 "Other (specify)" , modify ;
	#delimit cr
		
	#delimit ;
	label define alternate_source1 ///
	1 "Paddy" ///
	2 "Wheat" ///
	3 "Maize" /// 
	4 "Lentil" ///
	5 "Vegetables" ///
	6 "Always farmed fish" ///
	7 "Farm fish and crops together" ///
	-96 "Other" , modify ;
	#delimit cr
		
	#delimit ;
	label define changing1 ///
	1 "Less profitable due to soil salinity" ///
	2 "Less profitable due to labor cost increase" ///
	3 "High prices of fish/shrimp" /// 
	4 "Less profitable - other reasons" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define produce_lost ///
	1 "Flood" /// 
	2 "Water Toxicity" ///
	3 "Theft" ///
	4 "Due to cold"
	-96 "Other" , modify ;
	#delimit cr

	label define yesno_l1 0 "No" 1 "Yes" -98 "NA" , modify

	label value e5fish_species* fish_breedl1
	label value e5fish_alternative alternate_source1
	label value e5shift_fishing changing1
	label value e5carp_small_fish e5tilapia_clean yesno_l1
	label value e5reason_lost1 e5reason_lost2 e5reason_lost3 e5reason_lost4 produce_lost

	* clean other variables 
	replace e5fish_oth_l = "Bata Fish" if inlist(e5fish_oth_l, "Bata", "Bata mach")
	replace e5fish_oth_l = "Bagrid Catfish" if inlist(e5fish_oth_l, "Biget","Briket")
	replace e5fish_oth_l = "Local(Bridget)" if e5fish_oth_l == "Bridget"
	replace e5fish_oth_l = "Local(Biket)" if e5fish_oth_l == "Biket macha"
	replace e5fish_oth_l = "Local(Butterfish)" if e5fish_oth_l == "Briget"
	replace e5fish_oth_l = "Silver Barbel" if e5fish_oth_l == "Pholi Fish"
	replace e5fish_oth_l = "Puntius/Barbs" if e5fish_oth_l == "Poti"
	replace e5fish_oth_l = "Spotted Snakehead" if inlist(e5fish_oth_l, "Taki", "Taki mach")
	replace e5fish_oth_l = "Barramundi" if e5fish_oth_l == "Vetki mas" 

	replace e5fish_oth_s = "" if inlist(e5fish_oth_s,"0","Are mach chas koreni","Ekhon kono mach chas korle thakena")
	replace e5fish_oth_s = "Bata Fish" if inlist(e5fish_oth_s,"Bata mac","Bata mas","Bata musa")
	replace e5fish_oth_s = "Local Fish" if inlist(e5fish_oth_s,"Dehsi mach","Deshi mach")
	replace e5fish_oth_s = "Catfish" if inlist(e5fish_oth_s,"Godol","Pabda","Singmach kholsha")
	replace e5fish_oth_s = "Local(Hangri)" if e5fish_oth_s == "Hangri"
	replace e5fish_oth_s = "Puntius/Barbs" if inlist(e5fish_oth_s,"Poti","Puti","Puti etc")
	replace e5fish_oth_s = "Hilsa" if e5fish_oth_s == "Shing"
	replace e5fish_oth_s = "Sawbelly" if e5fish_oth_s == "Sor puti"
	replace e5fish_oth_s = "Gourami" if e5fish_oth_s == "Vata"

	*rename variables 
	rename e5fish_oth_s e5fish_species_oth_s
	rename e5fish_oth_l e5fish_species_oth_l 

	* Label Variables
	label var b1plot_fishing "Fisheries/fishing activities done on this plot."
	label var b1_operation_status "Operational status in current round"
	label var e5farm_startyear "Year of starting farming"
	label var e5fish_species1 "Fish cultivated in this body-1"
	label var e5fish_species2 "Fish cultivated in this body-2"
	label var e5fish_species3 "Fish cultivated in this body-3"
	label var e5fish_species4 "Fish cultivated in this body-4"
	label var e5fish_species5 "Fish cultivated in this body-5"
	label var e5fish_species6 "Fish cultivated in this body-6"
	label var e5fish_species7 "Fish cultivated in this body-7"
	label var e5fish_species8 "Fish cultivated in this body-8"
	label var e5fish_species_oth_s "Fish cultivated in this body-other(small)"
	label var e5fish_species_oth_l "Fish cultivated in this body-other(large)"

	label var e5reason_lost1 "Loss of output-reason-1"
	label var e5reason_lost2 "Loss of output-reason-2"
	label var e5reason_lost3 "Loss of output-reason-3"
	label var e5reason_lost4 "Loss of output-reason-4"

	label var e5fish_alternative "Use of the land before fish ponds"
	label var e5shift_fishing "Reason to shift from crop farming to aquaculture"
	label var e5carp_small_fish "Carps and small fishes are cultivated together"
	label var e5tilapia_clean "Use tilapia to clean the pond"
	label var e5fam_lab_days "Family Labor (labor-hours)"
	label var e5_hired_lab_days "Hired Labor (labor-hours)"
	label var e5_daily_wage "Total wage(hired labor and market wage for family labor)"
	label var e5fingerling_cost "Input-fingerlings"
	label var e5fishfeed_cost "Input cost-fishfeed"
	label var e5other_cost "Input cost-other"
	label var e5n_harvest "Number of harvests in last 1 year"
	label var e5tot_harvest "Total collection/ harvest(Kg)"
	label var e5lost_harvest "Total quantity of harvest lost(Kg)"

	* order 
	order a1hhid_combined b1* e5*
	order e5fish_species_oth_l e5fish_species_oth_s , after(e5fish_species8)

	* Save
	save "${final_data}${slash}SPIA_BIHS_2024_module_e5.dta", replace
	********************************************************************************
	* E6-E7

	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-e6fish_species_repeat.csv", varnames(1) clear
	drop if e6tot_production == . & e6totprod_leased == . & e6given_owner == . &  e6consumed == . & e6fish_paid_lab == . 
	tempfile e6
	save "`e6'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	keep a1hhid_combined e6fish_species_repeat_count SETOFe6fish_species_repeat
	rename SETOFe6fish_species_repeat setofe6fish_species_repeat
	keep if setofe6fish_species_repeat != ""
	duplicates drop 
	merge 1:m setofe6fish_species_repeat using "`e6'" , nogenerate keep(3)  // 5 households donot match

	preserve
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear 
	collapse (max) resurvey , by(a1hhid_combined) 
	drop if resurvey == 1 
	tempfile resurvey
	save "`resurvey'"
	restore 
	merge m:1 a1hhid_combined using "`resurvey'" , nogenerate keep(3)
	drop resurvey

	tempfile main_survey_e6
	save "`main_survey_e6'"
	************* append resurveys *************************
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(e6fish_species_repeat) clear 
	drop if e6tot_production == . & e6totprod_leased == . & e6given_owner == . &  e6consumed == . & e6fish_paid_lab == . 
	rename SETOFe6fish_species_repeat setofe6fish_species_repeat
	tempfile e6_resurvey
	save "`e6_resurvey'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear
	keep a1hhid_combined e6fish_species_repeat_count SETOFe6fish_species_repeat
	rename SETOFe6fish_species_repeat setofe6fish_species_repeat
	keep if setofe6fish_species_repeat != ""
	duplicates drop 
	merge 1:m setofe6fish_species_repeat using "`e6_resurvey'" , nogenerate keep(3) // 3 households don't match

	gen resurvey = 1 
	tempfile resurvey_e6
	save "`resurvey_e6'"

	use "`main_survey_e6'" , clear 
	append using "`resurvey_e6'" , force 

	duplicates tag a1hhid_combined e6fish_species_id , gen(dup)
	drop if dup > 0 & resurvey != 1 

	* keep 
	keep a1hhid_combined e6* e7* 

	* fish_id 
	destring e6fish_species_id , replace 

	* Place of sale
	drop e6place_sale_* 
	split e6place_sale, p(" ")
	drop e6place_sale
	destring e6place_sale* , replace

	* Label values 
	#delimit ;
	label define fish_breedl1 ///
	1  "Silver carp" ///
	2  "Grass carp" ///
	3  "Mirror carp" /// 
	4  "Common carp" ///
	5  "Karfu" ///
	6   "Rui"  ///
	7   "Katla" ///
	8   "Mrigel" ///
	9   "Kalibaus" ///
	10  "Telapia/Nailotica" ///
	11  "Pona" ///
	12  "Koi" ///
	13  "Magur"  ///
	14  "Shingi" ///
	15  "Khalse"  /// 
	16  "Shol/Gajar/Taki" ///
	17  "Puti/Swarputi" ///
	18  "Prawn (Golda Chingri)" ///
	19  "Shrimp (Bagda Chingri)" ///
	20  "Tengra/Baim" ///
	21  "Mola/Dhela/Kachki/Chapila" ///
	22  "Ilish/hilsha" ///
	23  "Sea fish" ///
	24  "Pangesh" ///
	25  "Other Large fish" ///
	26  "Other Small fish" ///
	-96 "Other (specify)" , modify ;
	#delimit cr

	#delimit ;
	label define fish_sale1 ///
	1  "Farm gate" ///
	2  "Village market (within own village) " ///
	3  "Village market (outside of own village)" /// 
	4 "Town  market" ///
	-96 "Other (specify)" , modify ;
	#delimit cr

	label value e6fish_species_id fish_breedl1
	label value e6place_sale1 e6place_sale2 fish_sale1

	* drop 
	drop e6fish_species_name e6fish_species_repeat_count

	* Label variables
	label var a1hhid_combined "Household ID"
	label var e6fish_species_id "Name of the fish produced in the past one year"
	label var e6tot_production "Total Production under own/share of plot/pond(Kg)"
	label var e6totprod_leased "Harvest received from the shared out (leased/contract) pond(Kg)"
	label var e6given_owner "Share of harvest given to owner (if shared pond)(%)"
	label var e6consumed "Quantity consumed(Kg)"
	label var e6fish_paid_lab "Quantity paid to the laborers(Kg)"
	label var e6dry_fish "Quantity for dry fish(Kg)"
	label var e6gifted "Quantity gifted to others(Kg)"
	label var e6spoiled "Quantity spoiled(Kg)"
	label var e6quant_sold "Quantity sold(Kg)"
	label var e6place_sale1 "If sold, location of sale (1)"
	label var e6place_sale2 "If sold, location of sale (2)"
	label var e6tot_earning "Total value of sale(Taka)"

	label var e7marketing_size "marketing/consumption size of the fish on average(inch)"
	label var e7cycle_production "Production per cycle (3-4 months)(Kg)"
	label var e7production_decimal "Fish produced per decimal(Kg)"
	label var e7fingerling_size "Size of the fingerlings in your pond(inch)"

	* order 
	order a1hhid_combined e6* e7*

	save "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", replace
	********************************************************************************
	* E8 
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-e8fish_species_repeat.csv", varnames(1) clear
	drop if e8stocking_density_hh == . & e8stocking_density_out == . 
	tempfile e8
	save "`e8'" 

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	keep a1hhid_combined e8hatchery_own e8hatchery_located e8fish_species_repeat_count SETOFe8fish_species_repeat
	rename SETOFe8fish_species_repeat setofe8fish_species_repeat
	keep if setofe8fish_species_repeat != ""
	duplicates drop 
	merge 1:m setofe8fish_species_repeat using "`e8'", nogenerate keep(3)

	preserve
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear 
	collapse (max) resurvey , by(a1hhid_combined) 
	drop if resurvey == 1 
	tempfile resurvey
	save "`resurvey'"
	restore 
	merge m:1 a1hhid_combined using "`resurvey'" , nogenerate keep(3)
	drop resurvey

	tempfile main_survey_e8
	save "`main_survey_e8'"

	***** append survey *******
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(e8fish_species_repeat) clear 
	drop if e8stocking_density_hh == . & e8stocking_density_out == . 
	rename SETOFe8fish_species_repeat setofe8fish_species_repeat
	tempfile e8_resurvey
	save "`e8_resurvey'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear
	keep a1hhid_combined e8hatchery_own e8hatchery_located e8fish_species_repeat_count SETOFe8fish_species_repeat
	rename SETOFe8fish_species_repeat setofe8fish_species_repeat
	keep if setofe8fish_species_repeat != ""
	duplicates drop 
	merge 1:m setofe8fish_species_repeat using "`e8_resurvey'" , nogenerate keep(3) // 3 households don't match

	gen resurvey = 1 
	tempfile resurvey_e8
	save "`resurvey_e8'"

	use "`main_survey_e8'" , clear 
	append using "`resurvey_e8'" , force 

	**** clean ***** 
	keep a1hhid_combined e8hatchery_own e8hatchery_located e8fish_species_id  ///
	e8stocking_density_hh e8stocking_density_out e8male

	* Label values 
	#delimit ;
	label define fish_breedl1 ///
	1  "Silver carp" ///
	2  "Grass carp" ///
	3  "Mirror carp" /// 
	4  "Common carp" ///
	5  "Karfu" ///
	6   "Rui"  ///
	7   "Katla" ///
	8   "Mrigel" ///
	9   "Kalibaus" ///
	10  "Telapia/Nailotica" ///
	11  "Pona" ///
	12  "Koi" ///
	13  "Magur"  ///
	14  "Shingi" ///
	15  "Khalse"  /// 
	16  "Shol/Gajar/Taki" ///
	17  "Puti/Swarputi" ///
	18  "Prawn (Golda Chingri)" ///
	19  "Shrimp (Bagda Chingri)" ///
	20  "Tengra/Baim" ///
	21  "Mola/Dhela/Kachki/Chapila" ///
	22  "Ilish/hilsha" ///
	23  "Sea fish" ///
	24  "Pangesh" ///
	25  "Other Large fish" ///
	26  "Other Small fish" ///
	-96 "Other (specify)" , modify ;
	#delimit cr

	label value e8fish_species_id fish_breedl1

	tostring e8male,replace 
	replace e8male = "1:1" if e8male == "1"

	label var a1hhid_combined "Household ID"
	label var e8fish_species_id "Which fish do you produce in the hatchery"
	label var e8stocking_density_hh "Stocking density [kg/sq meter] for HH"
	label var e8stocking_density_out "Stocking density [kg/decimal] for Hatchery"
	label var e8male "Ratio of Male:Female brood"

	save "${final_data}${slash}SPIA_BIHS_2024_module_e8.dta", replace
	********************************************************************************
	* E9

	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-e9fish_species_repeat.csv", varnames(1) clear
	drop if e9stocking_density_hh == . & e9stocking_density_out == . & e9nursery_culture == . 
	tempfile e9
	save "`e9'" 

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	keep a1hhid_combined e9* SETOFe9fish_species_repeat e9fish_species_repeat_count
	rename SETOFe9fish_species_repeat setofe9fish_species_repeat
	duplicates drop 
	drop e9fish_species e9fish_species_* 
	merge 1:m setofe9fish_species_repeat using "`e9'", nogenerate keep(3)

	preserve
	use "${temp_data}${slash}SPIA_BIHS_2024_module_a2_4_comb_nomig.dta", clear 
	collapse (max) resurvey , by(a1hhid_combined) 
	drop if resurvey == 1 
	tempfile resurvey
	save "`resurvey'"
	restore 
	merge m:1 a1hhid_combined using "`resurvey'" , nogenerate keep(3)
	drop resurvey

	tempfile main_survey_e9
	save "`main_survey_e9'"

	***** append survey *******
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(e9fish_species_repeat) clear 
	drop if e9stocking_density_hh == . & e9stocking_density_out == . & e9nursery_culture == .  
	rename SETOFe9fish_species_repeat setofe9fish_species_repeat
	drop PARENT_KEY KEY
	tempfile e9_resurvey
	save "`e9_resurvey'"

	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear
	keep a1hhid_combined e9* SETOFe9fish_species_repeat
	rename SETOFe9fish_species_repeat setofe9fish_species_repeat
	keep if setofe9fish_species_repeat != ""
	duplicates drop 
	drop e9fish_species e9fish_species_* 
	merge 1:m setofe9fish_species_repeat using "`e9_resurvey'" , nogenerate keep(3) // 3 households don't match

	gen resurvey = 1 
	tempfile resurvey_e9
	save "`resurvey_e9'"

	use "`main_survey_e9'" , clear 
	append using "`resurvey_e9'" , force 

	* drop 
	drop setofe9fish_species_repeat parent_key key resurvey

	* Value label 
	#delimit ;
	label define nursery_location ///
	0 "In the respondent's house" ///
	1 "Separate out of the respondent's house" , modify ;
	#delimit cr

	label define yesno_l1 0 "No" 1 "Yes" -98 "NA" , modify 

	#delimit ;
	label define source_fingerlings ///
	1 "Own farm" ///
	2 "Neighbor or relative" ///
	3 "Farmers group" /// 
	4 "Private hatchery" ///
	5 "Local dealer (commission agent)" ///
	6 "NGO" ///
	7 "Hawker hawking fingerlings" ///
	8 "Nursery" ///
	-96 "Other" , modify ;
	#delimit cr

	label define yesno_l1 0 "No" 1 "Yes" -97 "Don't know" -98 "NA" , modify 

	#delimit ;
	label define growth_stage ///
	1 "Initial growth phase (First 28 days)" ///
	2 "Development phase" , modify ;
	#delimit cr

	#delimit ;
	label define control_disease ///
	1 "Nothing" ///
	2 "Apply salt" ///
	3 "Apply formalin" /// 
	4 "Apply malachite green" ///
	5 "Apply methayl blue" ///
	6 "Antibiotics/Antibioic treated feed" ///
	7 "Applying lime" ///
	8 "Applying Potash" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define control_tech ///
	1 "Aerator" ///
	2 "Automatic fish feeder" ///
	3 "Digital water quality monitoring system" /// 
	4 "Sex separation" ///
	5 "Age separation" ///
	6 "Variation of feed" ///
	7 "An improved stocking method" ///
	-96 "Other" , modify ;
	#delimit cr

	#delimit ;
	label define produce_fish ///
	1 "Raised for food only" ///
	2 "Raised for market only " ///
	3 "Raised for both food and market" , modify ;
	#delimit cr

	* Label variables
	label var a1hhid_combined "HHID"
	label var e9nursery_own "Has a nursery"
	label var e9nursery_located "Location of nursery"
	label var e9fish_removal "Remove predators/non-culture fish from the farming area"
	label var e9shrimp_wssv "white spot syndrome virus (WSSV) negative screened PLs/spawn stocking"
	label var e9fish_species_name "Fish produced in the nursery"
	label var e9fish_species_id "Code of the fish produced in the nursery"
	label var e9fish_species_name "Fish name for sticking density"
	label var e9stocking_density_hh "Stocking density hh nursery in kg/sq. meter"
	label var e9stocking_density_out "Stocking density outside nursery in kg/decimal]"
	label var e9nursery_culture "Culture period" 

	* order 
	order a1* e9* 
	* save 
	save "${final_data}${slash}SPIA_BIHS_2024_module_e9.dta", replace

	********************************************************************************
	* E10

		
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)
	keep a1hhid_combined e10*

	keep if e10fish_lastyear == 1 

	label var e10fish_lastyear "You/family member involved in fish farming in the period"
	label var e10fingerling_weight "How many fish fries/fingerlings in total have you stocked in the recall period"
	label var e10source_fingerling "Main source of fish fingerlings you stocked in the recall period"
	label var e10hatchery_register "Was the hatchery fish fry/fingerling was purchased registered/certified hatchery"
	label var e10supp_feed "Did you give your fish supplemental feed in the last year?"
	label var e10supple_source "Did you make your own feed or did you buy it?"
	label var e10use_hormone "Did you use hormones to raise your fish in the last year?"
	label var e10hormone_stage "When did you apply the hormone to the fish?"
	label var e10hormone_training "Have you been formally trained in the use of hormones for fish farming?"
	label var e10fish_disease "Did you observe any disease among your fish in the last year"
	label var e10disease_control "Did you control disease among your fish in the last one year?"    
	label var e10fishtech_use "What did you do to control disease among your fish?"
	label var e10fish_harvest_freq "Have you used any techniques to improve your production of fish"
	label var e10pastmonth_weight "What was the total weight of fish you harvested in January 2024?(Kg)"
	label var e10pastyear_weight "What was the total weight of fish you harvested in the last one year?(Kg)"
	label var e10reason_fish "Why did you produce fish?"
	label var e10specific_tech_1 "Do you use the following machines/technologies/techniques(Tech 1)"
	label var e10specific_tech_2 "Do you use the following machines/technologies/techniques(Tech 2)"
	label var e10diseasecontrol_step_1 "How did you control diseases?(Method 1)"
	label var e10diseasecontrol_step_2 "How did you control diseases?(Method 2)"
	label var e10diseasecontrol_step_3 "How did you control diseases?(Method 3)"
	label var e10diseasecontrol_step_4 "How did you control diseases?(Method 4)"

	* e10specific_tech
	split e10specific_tech, p(" ")
	drop e10specific_tech
	destring e10specific_tech* , replace

	* e10diseasecontrol_step 
	split e10diseasecontrol_step, p(" ")
	drop e10diseasecontrol_step
	destring e10diseasecontrol_step* , replace

	* order 
	order a1* e10* 
	* save 
	save "${final_data}${slash}SPIA_BIHS_2024_module_e10.dta", replace

	 }
	********************************************************************************
	**# MODULE F1 
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1hhid_combined f1* SETOFf1shock_event_repeat 
	rename SETOFf1shock_event_repeat setoff1shock_event_repeat

	* Drop duplicates 
	duplicates drop
	drop f1shock_event f1shock_event_repeat_count

	* Rename a variable 
	rename f1shock_event__98 f1shock_event_98

	* Reshape
	reshape long f1shock_event_, i(a1hhid_combined) j(f1_shock_event)
	rename f1_shock_event f1shock_event_id
	rename f1shock_event_ f1shock_event_yesno

	* Since we did not collect information on the severity in the repeat group leaving it out/ and we donot know the name of the shock.
	drop if f1shock_event_id == 98 
	 
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_f-f1shock_event_repeat.csv", varnames(1) clear
	keep f1shock_event_id f1shock_severity setoff1shock_event_repeat
	drop if f1shock_severity == . 
	tempfile f1 
	save "`f1'"
	restore 

	merge 1:1 setoff1shock_event_repeat f1shock_event_id using "`f1'"
	drop if _merge == 2 
	drop _merge 

	sort a1hhid_combined f1shock_event_id

	tempfile f1_mainsurvey
	save "`f1_mainsurvey'" , replace

	*** INCORPORATE RE_SURVEYS *****  
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_deidentified_resurvey.dta" , clear 

	keep a1hhid_combined f1* SETOFf1shock_event_repeat
	rename SETOFf1shock_event_repeat setoff1shock_event_repeat

	* Drop duplicates 
	duplicates drop
	drop f1shock_event f1shock_event_repeat_count

	* Rename a variable 
	rename f1shock_event__98 f1shock_event_98

	* Reshape
	reshape long f1shock_event_, i(a1hhid_combined) j(f1_shock_event)
	rename f1_shock_event f1shock_event_id
	rename f1shock_event_ f1shock_event_yesno

	* Since we did not collect information on the severity in the repeat group leaving it out/ and we donot know the name of the shock.
	drop if f1shock_event_id == 98 

	preserve
	import excel "${raw_data}${slash}SPIA_BIHS_Resurvey_2024_deidentified.xlsx" , firstrow sheet(f1shock_event_repeat) clear 
	rename SETOFf1shock_event_repeat setoff1shock_event_repeat
	keep f1shock_event_id f1shock_severity setoff1shock_event_repeat 
	drop if f1shock_severity == . 
	tempfile f1_repeat
	save "`f1_repeat'"
	restore 

	merge 1:1 setoff1shock_event_repeat f1shock_event_id using "`f1_repeat'" 
	drop if _merge == 2 
	drop _merge 

	sort a1hhid_combined f1shock_event_id

	tempfile f1_resurvey
	save "`f1_resurvey'" , replace

	use "`f1_mainsurvey'" , clear 
	merge 1:1 a1hhid_combined f1shock_event_id using "`f1_resurvey'" , update replace  
	gen resurvey = 1 if _merge == 5 
	drop _merge 

	* label values 
	#delimit ;
	label define f1_shock ///
	1 "Major crop loss(flood)" ///
	2 "Major crop loss(drought/storms/pests/disease)" ///
	3 "Loss of livestock due(flood)" /// 
	4 "Loss of livestock due(death)" ///
	5 "Loss of livestock due(theft)" ///
	6 "Loss of aquaculture(flood/storm)" ///
	7 "Loss of productive assets due to floods" ///
	8 "Loss of consumption assets(floods)" ///
	9 "Medical expenses(illness/injury)" ///
	10 "Lost home due to river overflow" ///
	11 "Increase in food prices" ///
	12 "Increase in prices of inputs" ///
	13 "Loss of consumption assets(not floods)" ///
	98 "None of the above" , modify ;
	#delimit cr

	#delimit ;
	label define f1_severity ///
	1 "Not severe" ///
	2 "Somewhat severe" ///
	3 "Severe" /// 
	4 "Extremely Severe" ///
	-99 "Refused" , modify ;
	#delimit cr

	label define yesno_l1 0 "No" 1 "Yes" , modify

	label value f1shock_event_id f1_shock
	label value f1shock_severity f1_severity 
	label value f1shock_event_yesno yesno_l1

	decode f1shock_event_id,gen(f1shock_event_name)
	label val f1shock_event_id

	replace f1shock_event_yesno = 1 if f1shock_severity ! = . 

	* label variables 
	label var a1hhid_combined "HHID"
	label var f1shock_event_id "ID of event"
	label var f1shock_event_yesno "In the past 12 months, did this event occur?"
	label var f1shock_severity "For every event that occurred, how severe was it?"
	label var f1shock_event_name "Name of event"

	* sort 
	sort a1hhid_combined f1shock_event_id

	* keep 
	keep a1hhid_combined ///
	f1shock_event_id f1shock_event_yesno f1shock_severity f1shock_event_name

	* order 
	order a1hhid_combined ///
	f1shock_event_id f1shock_event_name f1shock_event_yesno f1shock_severity

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

		// Recoding shocks and harvests based on enumerator comments
		
		recode f1shock_event_yesno 0 = 1 if a1hhid_combined == "2344" & f1shock_event_id == 2
		
		recode f1shock_event_yesno 0 = 1 if a1hhid_combined == "4646" & f1shock_event_id == 1
		
		recode f1shock_event_yesno 0 = 1 if a1hhid_combined == "4656" & f1shock_event_id == 2
		
		recode f1shock_event_yesno 0 = 1 if a1hhid_combined == "4819" & f1shock_event_id == 2
		
		recode f1shock_event_yesno 0 = 1 if a1hhid_combined == "4973" & f1shock_event_id == 2
		
		recode f1shock_event_yesno 0 = 1 if a1hhid_combined == "5158.1" & f1shock_event_id == 1

	* save 
	save "${final_data}${slash}SPIA_BIHS_2024_module_f1.dta", replace
	 }
	********************************************************************************
	**# MODULE F2 
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1hhid_combined f2* 

	preserve
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	collapse(max) agri_control_household, by(a1hhid_combined)
	tempfile agri_hh
	save `agri_hh', replace
	restore 

	merge m:1 a1hhid_combined using "`agri_hh'" , keep(3) nogenerate

	* drop 
	drop f2crop_insu_source f2live_insu_source f2weather_fore_source f2crop_insu_source__96 f2live_insu_source__96 f2weather_fore_source__96

	* rename 
	rename f2weatherinsu_sour_oth f2weather_fore_source_oth

	* replace non-agri households with missing 
	foreach x of numlist 1 2 3 4 5 6 7 8 9 10 11 {
	replace f2crop_insu_source_`x' = . if agri_control_household == 0 
	replace f2weather_fore_source_`x' = . if agri_control_household == 0 
	}
	replace f2weather_forecast = . if agri_control_household == 0 
	replace f2index_insurance = . if agri_control_household == 0 
	replace f2index_premium = . if agri_control_household == 0 
	replace f2crop_insurance = . if agri_control_household == 0 

	* drop duplicate observations 
	duplicates drop 

	* Others 
	replace f2crop_insu_source_oth = "One house, one farm" if f2crop_insu_source_oth == "Akti bari akti khamar"
	replace f2crop_insu_source_oth = "Heard from the organization Care Bangladesh" if f2crop_insu_source_oth == "Care Bangladesh sogsta teke sunce"
	replace f2crop_insu_source_oth = "Krishi Bank" if f2crop_insu_source_oth == "Krisi bank"
	replace f2crop_insu_source_oth = "From the textbook" if f2crop_insu_source_oth == "Pattho boi theke"
	replace f2crop_insu_source_oth = "Through local meetings" if f2crop_insu_source_oth == "Uthan Boythoker Madhome."
	replace f2live_insu_source_oth = "Care Bangladesh" if f2live_insu_source_oth == "Cear Bangladesh"
	replace f2live_insu_source_oth = "Heard from the veterinary doctors" if f2live_insu_source_oth == "Vatirinari doctor der theke suneche"

	* label values 
	label define yesno_l1 0 "No" 1 "Yes" -98 "NA" , modify
	label value f2life_insurance f2health_insurance f2crop_insurance /// 
	f2livestock_insurance f2index_insurance f2index_premium f2weather_forecast yesno_l1

	* label variables 
	label var a1hhid_combined "Household ID"
	label var agri_control_household "Agricultural HH"       
	label var f2life_insurance "Has life insurance policy"
	label var f2health_insurance "Has health insurance policy"
	label var f2crop_insurance "Has heard of crop insurance"
	label var f2livestock_insurance "Has heard of livestock insurance"
	label var f2index_insurance "Has index-based flood insurance scheme"
	label var f2index_premium "Mention the premium if any (monthly)"
	label var f2weather_forecast "Got any early warning/weather forecast for crop cultivation"

	foreach x in f2crop_insu_source f2live_insu_source f2weather_fore_source {
	label var `x'_1 "DAE(SAAO)"
	label var `x'_2 "Campaign/training"
	label var `x'_3 "Own family" 
	label var `x'_4 "Friend/neighbor" 
	label var `x'_5 "Agricultural inputs dealer" 
	label var `x'_6 "NGO/private company representative" 
	label var `x'_7 "Farmer's School" 
	label var `x'_8 "Radio program" 
	label var `x'_9 "Television"
	label var `x'_10 "Mobile phone messages"
	label var `x'_11 "Internet"
	label var `x'_oth "Other"   
	}

	* Order
	order a* f* 

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	* Save dataset
	save "${final_data}${slash}SPIA_BIHS_2024_module_f2.dta", replace
	 }
	********************************************************************************
	**# MODULE F3
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1hhid_combined f3* 

	gen f3safety_net_yesno = 0 
	replace f3safety_net_yesno = 1 if f3safety_net__98 == 0 

	* Label value 
	label define yesno 0 "No" 1 "Yes" , modify 
	label value  f3safety_net_yesno yesno

	* Drop
	drop f3safety_net f3safety_net__98 f3safety_net__96 //not relevant - all options have been covered

	* Order 
	order f3safety_net_yesno , before(f3safety_net_1)
	order f3safety_net_oth, after(f3safety_net_50)

	tempfile f3safety
	save "`f3safety'"

	* Label var 
	label var a1hhid_combined "Household Identification"
	label var f3safety_net_yesno "Have you/any hh member gotten any assistance from the following?"
	label var f3safety_net_1 "Ananda School"
	label var f3safety_net_2 "Stipend for Primary Students"
	label var f3safety_net_3 "School Feeding Program"
	label var f3safety_net_4 "Stipend for Dropout Students"
	label var f3safety_net_5 "Stipend for Sec/Higher Sec/Female Student"
	label var f3safety_net_6 "Stipend for Poor Boys in secondary school"
	label var f3safety_net_7 "Stipend for Disabled Students"
	label var f3safety_net_8 "Old Age Allowance"
	label var f3safety_net_9 "Allowances for Distressed Cultural Activists"
	label var f3safety_net_10 "Allowances for beneficiaries in Ctg. Hill Tract"
	label var f3safety_net_11 "Allowances for the Widowed, Deserted and Destitute Women"
	label var f3safety_net_12 "Allowances for the Financially Insolvent Disabled"
	label var f3safety_net_13 "Maternity program for Poor Lactating Mothers"
	label var f3safety_net_14 "Maternal Health Voucher Scheme"
	label var f3safety_net_15 "Improving Maternal and Child Nutrition(IMCN)"
	label var f3safety_net_16 "Honorarium for Insolvent Freedom Fighters"
	label var f3safety_net_17 "Honorarium for Injured Freedom Fighters"
	label var f3safety_net_18 "Ration Program for Martyr Family and Wounded Freedom Fighters"
	label var f3safety_net_19 "Gratuitous Relief (Cash)"
	label var f3safety_net_20 "Gratuitous Relief (GR)- Food"
	label var f3safety_net_21 "General Relief Activities"
	label var f3safety_net_22 "Cash For Work"
	label var f3safety_net_23 "Agriculture Rehabilitation"
	label var f3safety_net_24 "Subsidy for Open Market Sales"
	label var f3safety_net_25 "Vulnerable Group Development (VGD)"
	label var f3safety_net_26 "VGD-UP (8 District on Monga Area)"
	label var f3safety_net_27 "Vulnerable Group Feeding (VGF)"
	label var f3safety_net_28 "Test Relief (TR) Food"
	label var f3safety_net_29 "Test Relief (TR) Cash"
	label var f3safety_net_30 "Food Assistance in CTG-Hill tracts Area"
	label var f3safety_net_31 "Food For Work (FFW)"
	label var f3safety_net_32 "Special fund for Employment Generation for Hard-core Poor in SIDR Area"
	label var f3safety_net_33 "Fund for the Welfare of Acid Burnt/Disables"
	label var f3safety_net_34 "100 days Employment Generation Program for the Poorest(EGPP)"
	label var f3safety_net_35 "Rural Employment Opportunities for Protection of Public Property (REOPA)"
	label var f3safety_net_36 "Rural Employment and Rural Maintenance Program (RERMP)"
	label var f3safety_net_37 "Community Nutrition Program"
	label var f3safety_net_38 "Char Livelihood Program (CLP)"
	label var f3safety_net_39 "Shouhardo Program (CARE)"
	label var f3safety_net_40 "Nabajibon Program (Save the Children)"
	label var f3safety_net_41 "Proshar Program (ACDI VOCA)"
	label var f3safety_net_42 "Accommodation (Poverty Alleviation & Rehabilitation)"
	label var f3safety_net_43 "Housing Support"
	label var f3safety_net_44 "TUP (BRAC)"
	label var f3safety_net_45 "One House one farm"
	label var f3safety_net_46 "TMRI"
	label var f3safety_net_47 "Pension program for retired government employees and their families"
	label var f3safety_net_48 "Program for improving the living standards of tea garden workers"
	label var f3safety_net_49 "Climate Rehabilitation Program (Gucchograam)"
	label var f3safety_net_50 "Social Security Policy Support (SSSS) Program"
	label var f3safety_net_oth "Other (please specify)"

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	* Save dataset
	save "${final_data}${slash}SPIA_BIHS_2024_module_f3.dta", replace
	 }
	********************************************************************************
	**# MODULE F4
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1hhid_combined f4* 
	duplicates drop 

	* label variable 
	label var a1hhid_combined "Household Identification"
	label var f4lack_food "In the past year, experienced lack of food due to lack of money?"
	label var f4lack_nutrition "In the past year, unable to eat nutritious food due to lack money?" 
	label var f4lack_diversity "In the past year, only a few kinds of foods due to lack money?"
	label var f4skip_meal "In the past year, skipped a meal due to money"
	label var f4eat_less "In the past year, ate less than required due to money?"
	label var f4food_shortage "In the past year, household ran out of food due to lack of money?"
	label var f4not_eat "In the past year, were you hungry but did not eat?"
	label var f4fast_hunger "In the past 12 months, went without eating for a whole day?"

	* label value 
	label define yesnomissing 0 "No" 1 "Yes" -97 "Don't know" -99 "Refused" , modify 
	label value f4lack_food f4lack_nutrition f4lack_diversity f4skip_meal f4eat_less f4food_shortage f4not_eat f4fast_hunger yesnomissing

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	save "${final_data}${slash}SPIA_BIHS_2024_module_f4.dta", replace
	 }
	********************************************************************************
	**# MODULE G
	********************************************************************************
	 {
	use "${temp_data}${slash}SPIA_BIHS_Main_2024_module_a2hhroster_labelled_deidentified_new.dta", clear
	keep a1hhid_combined g1hh_internet ///
	g1internet_source g1purpose_internet g1purpose_internet_* g1purpose_internet__96 /// 
	g1purpose_inter_oth g1internet_day g1internet_hour ///
	g1smartphone g1heard_apps g1heard_apps_* SETOFg1heard_apps_repeat 
	duplicates drop 
	rename g1purpose_internet__96 g1purpose_internet_96
	rename SETOFg1heard_apps_repeat setofg1heard_apps_repeat

	* clean variables
	replace g1internet_day = 1 if g1internet_day == 0.25
	replace g1internet_hour = 21 if g1internet_hour > 20 & g1internet_hour != . 

	* merge repeat groups
	preserve
	import delimited using "${raw_data}${slash}csv${slash}SPIA_BIHS_Main_2024-module_g-g1heard_apps_repeat.csv", varnames(1) clear
	keep if g1have_apps != . 
	drop parent_key key
	tempfile g_apps
	save "`g_apps'"
	restore 

	merge 1:m setofg1heard_apps_repeat using "`g_apps'"
	drop if _merge == 2 
	drop _merge
	 
	drop g1heard_apps_1 g1heard_apps_2 g1heard_apps_3 g1heard_apps_4 g1heard_apps_5 ///
	g1heard_apps_6 g1heard_apps_7 g1heard_apps_8 g1heard_apps_9 g1heard_apps_10 ///
	g1heard_apps_11 g1heard_apps_12 g1heard_apps_crop g1heard_apps_mb g1heard_apps_oth

	* label value and clean it
	label define g1internet_source 1 "Mobile(Grameen)" 2 "Mobile(Teletalk)" ///
	3 "Mobile(Banglalink)" 4 "Mobile(Robi)" 5 "Mobile net (others)" 6 "Broadband"
	label define yesno 0 "No" 1 "Yes" , modify 

	label value g1internet_source g1internet_source
	label value g1purpose_internet_1 g1purpose_internet_2 g1purpose_internet_3 ///
	g1purpose_internet_4 g1purpose_internet_96 g1have_apps g1impact_apps g1smartphone g1hh_internet yesno

	drop g1purpose_internet g1heard_apps g1check_apps g1presence_apps ///
	g1heard_apps_repeat_count setofg1heard_apps_repeat

	replace g1heard_apps_name = "Others" if g1heard_apps_name == "অন্যান্য (নির্দিষ্ট করুন)"  
	replace g1heard_apps_name = "Other mobile banking apps" if g1heard_apps_name == "অন্যান্য মোবাইল ব্যাংকিং এপ" 
	replace g1heard_apps_name = "Other apps for buying and selling crops besides the ones mentioned" if g1heard_apps_name ==  "উপরে উল্লেখিত এপ ছাড়া ফসল ক্রয় এবং বিক্রয় করার জন্য অন্য এপ"
	replace g1heard_apps_name = "PANI" if g1heard_apps_name == "Program for Advanced Numerical Irrigation ( PANI )"

	* label variable
	label var g1purpose_internet_1 "Purpose of use:Entertainment"
	label var g1purpose_internet_2 "Purpose of use:Education"
	label var g1purpose_internet_3 "Purpose of use:Gig-working"
	label var g1purpose_internet_4 "Purpose of use:Agriculture-related"
	label var g1purpose_internet_96 "Purpose of use:Others"
	label var g1internet_day  "How many days/week does the primary respondent use the internet?"
	label var g1internet_hour "How many hours/day does the primary respondent use the internet?"
	label var g1heard_apps_id  "App_id" 
	label var g1heard_apps_name "App_name"
	label var g1have_apps "Do you have the app on your phone?"
	label var g1impact_apps "Did it have a positive impact on your business?"
	label var a1hhid_combined "Household ID"

	* sort
	sort a1hhid_combined g1heard_apps_id

	* Ensure only relevant HHs are in - merge with a1_hh_roster and drop all HHs which are not merged. 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1hhid_combined)

	* save file 
	save "${final_data}${slash}SPIA_BIHS_2024_module_g.dta", replace
	 }
