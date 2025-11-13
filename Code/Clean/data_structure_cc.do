********************************************************************************
* SPIA BIHS COMMUNITY SURVEY DATA CLEANING *
********************************************************************************
/*		
Project: SPIA_BIHS_2024
Author : Tanjim Ul Islam
Date Created : 8 May 2024
Latest Edit : 31 July 2025
Last edit by: Tanjim

Description: This merges and cleans all the community survey modules for SPIA BIHS 2024 

INPUT: SPIA_BIHS_CC_2024_deidentified and its subsidiaries
OUTPUT: Final community survey datasets

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
	
	
	u "${bihs2018}${slash}r3_male_mod_a_001_BIHS.dta", clear
	
		
	collapse(first) vcode, by(community_id)
	
	ren vcode a1village
	
	la var community_id "Community ID"
	
	tempfile community_id
	save `community_id', replace
	
	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("c_machine") firstrow clear
	
	keep c_machine_id c_machine_name c_rent_cost_mach c_fuel_cost_mach SETOFc_machine
	
	reshape wide c_machine_name c_rent_cost_mach c_fuel_cost_mach, i(SETOFc_machine) j(c_machine_id)
	
	tempfile c_machine
	save `c_machine', replace
	
		
	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("data") firstrow clear
	duplicates tag a1village, gen(dup)
	drop if dup == 1 & a1village_pop == 25000
	
	destring a1village, replace
	
	merge 1:1 a1village using `community_id', nogen keep(3)
	
	preserve
	
	keep community_id e_*
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_e.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_e.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_e.dta")

	la var e_fisher_served "Fishermen to which areas do you sell your product"
	
	la var e_fish_species_9 "Kalibaus"
		
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_e", replace
	
	restore
	
	preserve
	
	keep community_id f_*
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_f", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_f") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_f")

	la var f_sanctuary_dist "Distance to nearest fish sanctuary affected by fishing ban (meters)"
	
	la var f_ban_aware "Are the villagers aware of bans on fishing?"
	
	la var f_fish_ban__96 "Others (specify)"
	
	la var f_part_iga "Any villagers received incentives to do alt. Income Generating Activities"
	la var f_ban_compensate "Any villagers received monetary/in-kind compensation for fishing bans"
	
	order community_id f_*
	
	sort community
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_f", replace
	
	restore
	
	preserve
	
	keep community_id g1* g2*
	
	order community_id g1* g2*
	
	sort community_id
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_g", replace
		
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_g") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_g")

	la var g1use_salttol "have you or anyone you know used salt tolerant rice varieties?"
	
	la var g1change_awd "how has the yield changed due to this new innovation?"
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_g", replace
	
	restore 
	
	
	
	preserve
		
	keep a1division divisionname a1district districtname a1upazila upazilaname /// 
	a1union a1mouza monitorid superid enumid a1village a1village_pop a1num_hh ///
	community_id num_respondent
	
	
	sort community_id
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_a1.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_a1.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_a1.dta")

	la var monitorid "Monitor ID"
	la var superid "Supervisor ID"
	la var enumid	"Enumerator ID"
	la var a1division "Division code"
	la var a1district "District code"
	la var a1upazila  "Upazila code"
	la var upazilaname "Upazila name"
	la var a1union "Union code"
	la var a1mouza "Mouza code"
	la var a1village "Village code" 

	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_a1.dta", replace
	
	restore
	
	preserve 
	
	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("d1typeseed_repeat") firstrow clear
	
	drop d1typeseed_index PARENT_KEY KEY d1typeseed_name
	
	drop if d1typeseed_id == .
	
	recode d1typeseed_id -96 = 5
	
	
	reshape wide d1all_variety d1seed_quality, i(SETOFd1typeseed_repeat) j(d1typeseed_id)
	
	tempfile d1typeseed_repeat
	save `d1typeseed_repeat', replace
	
	
	restore 
	
	
	preserve
	
	merge m:1 SETOFd1typeseed_repeat using `d1typeseed_repeat', nogen keep(1 3)
	
	keep community_id d_* d1*
	
	sort community_id
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_d.dta", replace
	
		
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_d.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_d.dta")

	
	la var d1badc_distance "Distance of BADC outlet from your location [meters]"
	la var d_pres_dealer "Does this village have any seed dealer?"
	la var d1fail_freq "farmers wanted to buy certain type of rice seed and you failed to supply"
	la var d1type_seed__96 "Others (specify)"
	ren d1fail_paddy_oth d1fail_paddyoth
	
	drop d1paddy_variety* d1fail_paddy_* d1typeseed_repeat_count ///
	d1paddy_var_repeat_count d1paddyvariety_oth
	
	ren (d1fail_paddyoth d1type_seed__96) (d1fail_paddy_oth d1type_seed_5)
	
	order community_id, before(d_pres_dealer)
	
	forvalues i = 1/5 {
	
	order d1seed_quality`i' d1all_variety`i', after(d1type_seed_`i')
	
	la var d1all_variety`i' "Did you get all the types of seed variety for this crop that you wanted to buy?"
	la var d1seed_quality`i' "How was the quality of the seeds you purchased?"
	
	}
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_d", replace
	
	restore 
		
	preserve
	
	drop if SETOFd1paddy_var_repeat == ""
	
	keep community_id SETOFd1paddy_var_repeat d1paddy_variety*
	
	tempfile d1paddy_var_repeat
	save `d1paddy_var_repeat', replace
		
	restore 
		
	keep community_id c_* b_* SETOF*
	
	tempfile main_data
	save `main_data', replace
	
	keep c_* community_id SETOF*
	order c_*, after(community_id)
	
	recode c_n_stw 2008 = .
	recode c_n_llp 2020 = .
	
	merge 1:m SETOFc_machine using `c_machine', nogen keep(3)
	
	drop c_pc_awd c_machine_count SETOF* c_name_list c_season_repeat_count
	
	sort community_id
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_c.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_c.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_c.dta")

	la var c_use_color_chart "Do you use a color chart in this regard?"
	la var c_rent_cost_mach1 "What is the rental cost per acre?"
	la var c_rent_cost_mach2 "What is the rental cost per acre?"
	la var c_fuel_cost_mach1 "What is the fuel cost per acre?"
	la var c_fuel_cost_mach2 "What is the fuel cost per acre?"
	la var c_check_leaf_color "Villagers check the color of the leaf of paddy  to apply fertilizer"
	la var c_price_level "In past 12 months, price of seed stable, decreased, or increased"
	la var c_price_level_fish "In past 12 months, price of fish stable, decreased, or increased"
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_c.dta", replace
	
	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("module_a2") firstrow clear
		
	merge m:1 SETOFmodule_a2 using `main_data', nogen keep(3)
	
	keep community_id a2*
	order a2*, after(community_id)
	
	sort community_id
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_a2.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_a2.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_a2.dta")
	
	la var a2occupation "Occupation of the Respondent"
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_a2.dta", replace

	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("b_service_repeat") firstrow clear
		
	merge m:1 SETOFb_service_repeat using `main_data', nogen keep(3)
	
	order b_*, after(community_id)
	
	drop SETOF* *KEY c_*
		
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_b", replace
	

	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_b.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_b.dta")

		la def b_service_id	1 "Bazaar" ///
			2 "Internet café" ///
			3 "Fertilizer depot" ///
			4 "Local supply depot (LSD)" ///
			5 "Cold storage" ///
			6 "Rental grain storage godown /warehouse" ///
			7 "Cold storage (solar electricity)" ///
			8 "Milk chilling plant (specify, for example BRAC/MilkVita etc)" ///
			9 "Livestock/poultry/fish feed shop" ///
			10 "Veterinary clinic" ///
			11 "Seed dealer" ///
			12 "Fertilizer dealer" ///
			13 "Ration dealer for rice" ///
			14 "Ration dealer for wheat" ///
			15 "Rice mill" ///
			16 "Wheat mill" ///
			17 "Rental services providers (power tiller)" ///
			18 "Rental services providers (tractor)" ///
			19 "Rental services providers (harvester)" ///
			20 "Barind Multipurpose Development Authority (BMDA) local office" ///
			21 "Farmer Field School from 2018 onwards" ///
			22 "Fish fry seller" ///
			23 "Fish fingerling seller"
			
	la val b_service_id b_service_id
	
	la var b_service_id "Name of the service"
	
	drop b_service_index b_service_name b_service_repeat_count
	
	order b_service, before(b_service_id)
	
	sort community_id b_service_id
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_b", replace
		
	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("c_season_repeat") firstrow clear
		
	merge m:1 SETOFc_season_repeat using `main_data', nogen keep(3)
	
	keep c_season_id c_season_name c_lab_avail_sow c_lab_hours_sow c_lab_wage_sow ///
	c_lab_food_sow c_contract_sow c_lab_avail_weed c_lab_hours_weed ///
	c_lab_wage_weed c_lab_food_weed c_contract_weed c_lab_avail_harv ///
	c_lab_hours_harv c_lab_wage_harv c_lab_food_harv c_contract_harv community_id
	
	order c_*, after(community_id)
	
	sort community_id
		
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_c_season_agri_labour.dta", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_c_season_agri_labour.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_c_season_agri_labour.dta")

	la var c_lab_avail_weed "Availability of labourers compared to demand"

		
	
	
	
	import excel using "${raw_data}${slash}csv${slash}SPIA_BIHS_CC_2024_deidentified.xlsx", sheet("d1paddy_var_repeat") firstrow clear
	
	merge m:1 SETOFd1paddy_var_repeat using `d1paddy_var_repeat', nogen keep(3)
	
	drop d1paddy_variety_* *KEY SETOFd1paddy_var_repeat
	
	sort community_id d1paddy_var_index
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_d_paddy_var_repeat", replace
	
	odksplit, survey("${dir}${slash}Data${slash}codebook${slash}SPIA_BIHS_CC_Varnames.xlsx") ///
data("${cc_data}${slash}SPIA_BIHS_2024_CC_module_d_paddy_var_repeat.dta") label(English) dateformat(MDY) clear save("${cc_data}${slash}SPIA_BIHS_2024_CC_module_d_paddy_var_repeat.dta")
	
	la var d1paddy_var_id "Paddy variety number"
	la var d1paddy_variety "most popular varieties of rice seeds sold in the last 12 months"
	la var d1trait_boro__96 "Others (specify)"
	la var d1sell_boro "Did you sell this variety in the boro 2023 season?"
	
	order community_id d1paddy_variety, before(d1paddy_var_index) 
	
	save "${cc_data}${slash}SPIA_BIHS_2024_CC_module_d_paddy_var_repeat", replace
	
	
	
	
	

	
