********************************************************************************
* DATASET ANALYSIS *
********************************************************************************
/*		
Project: SPIA_BIHS_2024
Author : Saumya Singla & Tanjim Ul Islam
Date Created : 7th May 2024
Latest Edit : 1 August 2025

Description: This inputs the final .dta modules and outputs all the tables and 
graphs of the Bangladesh Country Report

INPUT: SPIA_BIHS_HH_2024 final modules 
OUTPUT: Report graphs and tables

*/


********************************************************************************
* Installations * 
********************************************************************************
	
	** Install odksplit
	cap which 	odksplit
	if _rc 		net install odksplit, all replace ///
				from("https://raw.githubusercontent.com/ARCED-Foundation/odksplit/master")
	adoupdate odksplit, update
	
	cap which coefplot
	if _rc ssc install coefplot
	
	cap which shp2dta
	if _rc ssc install shp2dta
	
	cap which spmap
	if _rc ssc install spmap
	
	cap which winsor2
	if _rc ssc install winsor2
	
	cap which winsor
	if _rc ssc install winsor

	cap which catplot
	if _rc ssc install catplot
	
	cap which palettes
	if _rc ssc install palettes
	
	cap which colrspace
	if _rc ssc install colrspace
	
	cap which graphfunctions
	if _rc ssc install graphfunctions
	
	cap which unique
	if _rc ssc install unique
	
	
	
	net install grc1leg, from("http://www.stata.com/users/vwiggins") replace
	
	net install gr0073, from("http://www.stata-journal.com/software/sj18-3") replace
	
	net install sankey, from("https://raw.githubusercontent.com/asjadnaqvi/stata-sankey/main/installation/") replace
	
	cap which grc1leg2
	if _rc ssc install grc1leg2
	
	cap which schemepack
	if _rc ssc install schemepack
	
	**# Setting globals
	
	clear all
	set maxvar 32767
	set more off, permanently
	capture log close // capture avoids code interruptions 	
	

	
	 **upazila level admin shape file
        
    cap confirm file "${temp_data}${slash}upazila_admin.dta"
        
    if _rc {
                shp2dta using   ///
                "${raw_data}${slash}bgd_adm_bbs_20201113_shp${slash}bgd_adm_bbs_20201113_SHP${slash}bgd_admbnda_adm3_bbs_20201113.shp", ///
                                                data("${temp_data}${slash}upazila_admin")  ///
												coor("${temp_data}${slash}upazila_coor") ///
												gencentroids (center) genid(new_ID)
        }
		
	
	
	 **district level admin shape file
        
    cap confirm file "${temp_data}${slash}district_admin_new.dta"
        
    if _rc {
                shp2dta using   ///
                "${raw_data}${slash}bgd_adm_bbs_20201113_shp${slash}bgd_adm_bbs_20201113_SHP${slash}bgd_admbnda_adm2_bbs_20201113.shp", ///
                                                data("${temp_data}${slash}district_admin_new")  ///
												coor("${temp_data}${slash}district_coor_new") ///
												gencentroids (center) genid(new_ID)
        }
		
	**division level admin shape file
        
    cap confirm file "${temp_data}${slash}division_admin.dta"
        
    if _rc {
                shp2dta using   ///
                "${raw_data}${slash}bgd_adm_bbs_20201113_shp${slash}bgd_adm_bbs_20201113_SHP${slash}bgd_admbnda_adm1_bbs_20201113.shp", ///
                                                data("${temp_data}${slash}division_admin")  ///
												coor("${temp_data}${slash}division_coor") ///
												gencentroids (center) genid(new_ID)
        }
		
	**# Creating the datasets for analysis
	
	u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
	
	merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen
	
		
	save "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", replace
	
	u "${final_data}${slash}SPIA_BIHS_2024_module_d1_machinery.dta", clear
	
	merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
	
	save  "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_d1_machinery_a1", replace
	
******************************************************************************** 
**# Section 5.3 AQUACULTURE TRENDS *** 
********************************************************************************
{
***** 2024 AQUACULTURE DATASETS *****
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
collapse (first) agri_control_household, by(a1hhid_combined)
tempfile 2024_aquaculture 
save "`2024_aquaculture'"

use "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", clear 
gen tilapia_har = .
gen rohu_har = .
replace tilapia_har = e6tot_production + e6totprod_leased if inlist(e6fish_species_id,1,2,3,4,5)
replace rohu_har = e6tot_production + e6totprod_leased if inlist(e6fish_species_id,6)
collapse (sum) rohu_har tilapia_har , by(a1hhid_combined)
replace rohu_har = . if rohu_har  == 0 
replace tilapia_har = . if tilapia_har == 0 
tempfile 2024_fish_harvest
save "`2024_fish_harvest'"

use "${final_data}${slash}SPIA_BIHS_2024_module_e5.dta", clear 
collapse (count) avg_plots=b1plot_num (mean) pond_size=b1plotsize_decimal pond_depth=b1flood_depth total_daily_wage=e5_daily_wage ///
(mean) total_harvest_n=e5n_harvest (sum) total_harvest=e5tot_harvest (max) fishing_hh=b1plot_fishing , by(a1hhid_combined)
merge 1:1 a1hhid_combined using "`2024_aquaculture'" , nogenerate 
merge 1:1 a1hhid_combined using "`2024_fish_harvest'" , nogenerate 

* To account for extreme values in reporting that might skew the means. 
winsor2 pond_size, suffix(_w) cuts(1 99)
winsor2 pond_depth, suffix(_w) cuts(1 99)
winsor2 avg_plots, suffix(_w) cuts(1 99)
winsor2 total_harvest_n, suffix(_w) cuts(1 99)
winsor2 total_harvest, suffix(_w) cuts(1 99)
winsor2 tilapia_har, suffix(_w) cuts(1 99)
winsor2 rohu_har, suffix(_w) cuts(1 99)

merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keepusing(hhweight_24 a01combined_18 a01combined_15 a01_12)

gen round = 2024

replace fishing_hh = 0 if fishing_hh == . & agri_control_household == 1 

keep if agri_control_household == 1 //note: this variable is both agricultral and aquaculture households

* household level dataset for 2024
tempfile fishing_2024_pre
save `fishing_2024_pre', replace

collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w tilapia_har_w rohu_har_w fishing_hh [pweight=hhweight_24], by(round)

* Summarized dataset for 2024 
tempfile fishing_2024
save `fishing_2024', replace

***** 2018 AQUACULTURE DATASETS *****
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
g agri_control	= cond(h1_sl == 99, 0, 1)
collapse (max) agri_control, by(a01)
tempfile 2018_aquaculture
save `2018_aquaculture', replace

preserve
use "${bihs2018}${slash}052_bihs_r3_male_mod_l2", clear 
gen tilapia_har = 0 
gen rohu_har = 0 
replace tilapia_har = l2_03  if inlist(l2_01,1,2,3,4,5)
replace rohu_har = l2_03 if inlist(l2_01,6)
collapse (sum) rohu_har tilapia_har , by(a01)
replace rohu_har = . if rohu_har  == 0 
replace tilapia_har = . if tilapia_har == 0 
tempfile 2018_fish_harvest
save "`2018_fish_harvest'"
restore	

use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
drop if sl_l1 == 0 | pondid_l1==999
g fishing_hh = 1
collapse(max) fishing_hh, by(a01)
merge 1:1 a01 using `2018_aquaculture', nogen
g agri_control_household = (fishing_hh== 1 | agri_control == 1)
collapse (max)fishing_hh agri_control_household, by(a01)

merge 1:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
keep if agri_control_household == 1 
replace fishing_hh = 0 if fishing_hh == . 

tempfile 2018_aquaculture
save `2018_aquaculture', replace 

use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
merge m:1 a01 using "`2018_aquaculture'" , nogenerate keepusing(fishing_hh)
rename fishing_hh fishing_hh_check

gen fishing_hh = 0 
replace fishing_hh = 1 if l1_02_1 != . & pondid_l1 != 999 // if there is a pond and some aquaculture in one of the ponds. 
replace l1_02b = 0 if l1_02b == 2  // to harmonize all binaries to 0/1
replace pondid_l1 = . if pondid_l1 == 999 //replace 999 with missing pond id for calculations
keep if fishing_hh_check == 1

collapse (max)fishing_hh_check (mean) pond_size=l1_01 total_harvest_n=l1_10 (sum) total_harvest=l1_11 (first) round (count)avg_plots=pondid_l1 , by(a01)

merge 1:1 a01 using "`2018_aquaculture'" , nogenerate keepusing(agri_control_household hhweight)
merge 1:1 a01 using "`2018_fish_harvest'" , nogenerate 
replace fishing_hh_check = 0 if fishing_hh_check == . & agri_control_household == 1

winsor2 pond_size, suffix(_w) cuts(1 99)
winsor2 avg_plots, suffix(_w) cuts(1 99)
winsor2 total_harvest_n, suffix(_w) cuts(1 99)
winsor2 total_harvest, suffix(_w) cuts(1 99)
winsor2 tilapia_har, suffix(_w) cuts(1 99)
winsor2 rohu_har, suffix(_w) cuts(1 99)

replace round = 2018 

tempfile fishing_2018_pre
save `fishing_2018_pre', replace

drop pond_size total_harvest_n total_harvest avg_plots

order a01 agri_control_household fishing_hh_check hhweight round avg_plots_w pond_size_w total_harvest_n_w total_harvest_w

* household level dataset for 2018
tempfile fishing_2018_pre
save `fishing_2018_pre', replace

collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w fishing_hh_check rohu_har_w tilapia_har_w [pweight=hhweight], by(round)
rename fishing_hh_check fishing_hh

*  Summarized dataset for 2018
tempfile fishing_2018
save `fishing_2018', replace

********* 2015 AQUACULTURE DATASETS **********
use "${bihs2015}${slash}015_r2_mod_h1_male", clear
g agri_control	= cond(h1_sl == 99, 0, 1)
collapse (max) agri_control, by(a01)
tempfile bihs2015agri
save `bihs2015agri', replace

u "${bihs2015}${slash}037_r2_mod_l1_male", clear
drop if l1_sl == 99 | pondid == 999
g fishing_hh = 1
collapse(max) fishing_hh, by(a01)
merge 1:1 a01 using `bihs2015agri', nogen
g agri_control_household = (fishing_hh== 1 | agri_control == 1)

preserve 
use "${bihs2015}${slash}038_r2_mod_l2_male", clear 
drop if hh_type == 1 //drop those we we in additional FTF
drop if l2_01 == 99
gen tilapia_har = 0 
gen rohu_har = 0 
replace tilapia_har = l2_03  if inlist(l2_01,1,2,3,4,5)
replace rohu_har = l2_03 if inlist(l2_01,6)
collapse (sum) rohu_har tilapia_har , by(a01)
replace rohu_har = . if rohu_har  == 0 
replace tilapia_har = . if tilapia_har == 0 
tempfile 2015_fishhar
save "`2015_fishhar'"
restore 

merge 1:1 a01 using "${bihs2015}${slash}BIHS FTF 2015 survey sampling weights" , keep(3) nogen keepusing(hhweight hh_type)
drop if hh_type == 1 //drop households in additional FTF
keep if agri_control_household == 1 
tempfile bihs2015boro
save `bihs2015boro', replace

use "${bihs2015}${slash}037_r2_mod_l1_male", clear
merge m:1 a01 using "`bihs2015boro'" , nogenerate keepusing(fishing_hh)
rename fishing_hh fishing_hh_check

drop if hh_type == 1 //drop households in additional FTF
gen fishing_hh = 0 
replace fishing_hh = 1 if l1_02_1 != . & pondid != 999
replace l1_02b = 0 if l1_02b == 2
replace pondid = . if pondid == 999
keep if fishing_hh_check == 1

collapse (max)fishing_hh_check (mean) pond_size=l1_01  total_harvest_n=l1_10 (sum) total_harvest=l1_11 (count) avg_plots=pondid , by(a01)

merge 1:1 a01 using "`bihs2015boro'" , nogenerate keepusing(agri_control_household hhweight)
merge 1:1 a01 using "`2015_fishhar'" , nogenerate 

winsor2 pond_size, suffix(_w) cuts(1 99)
winsor2 avg_plots, suffix(_w) cuts(1 99)
winsor2 total_harvest_n, suffix(_w) cuts(1 99)
winsor2 total_harvest, suffix(_w) cuts(1 99)
winsor2 tilapia_har, suffix(_w) cuts(1 99)
winsor2 rohu_har, suffix(_w) cuts(1 99)

replace fishing_hh_check = 0 if fishing_hh_check == . & agri_control_household == 1

gen round = 2015

tempfile fishing_2015_pre
save `fishing_2015_pre', replace

collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w fishing_hh_check rohu_har_w tilapia_har_w [pweight=hhweight], by(round)
rename fishing_hh_check fishing_hh

tempfile fishing_2015
save `fishing_2015', replace

********** 2012 AQUACULTURE DATASETS ***********
use "${bihs2012}${slash}011_mod_h1_male", clear
gen boro_hh = (inrange(crop_a, 11, 20) | inrange(crop_b, 11, 20))  & ///
((h1_04a==4 & h1_04b==12) | inrange(h1_04b, 1, 2) | inrange(h1_04a, 1, 2) & h1_04b==3)
g maize_hh = (crop_a == 23 | crop_b == 23) & inrange(h1_04b, 10, 11) 
collapse (max) boro_hh maize_hh, by(a01)
g agri_control	= 1
tempfile bihs2012agri
save `bihs2012agri', replace
	
u "${bihs2012}${slash}026_mod_l1_male", clear
drop if pondid == 999
g fishing_hh = 1
collapse(max) fishing_hh, by(a01)
merge 1:1 a01 using `bihs2012agri', nogen
g agri_control_household = (fishing_hh== 1 | agri_control == 1)
tempfile bihs2012boro
save `bihs2012boro', replace

use "${bihs2012}${slash}027_mod_l2_male", clear 
merge m:1 a01 using `bihs2012boro'
drop if sample_type==1
drop if l2_01 == 99
gen tilapia_har = 0 
gen rohu_har = 0 
replace tilapia_har = l2_03  if inlist(l2_01,1,2,3,4,5)
replace rohu_har = l2_03 if inlist(l2_01,6)
collapse (sum) rohu_har tilapia_har , by(a01)
replace rohu_har = . if rohu_har  == 0 
replace tilapia_har = . if tilapia_har == 0 
tempfile 2012_fishhar
save "`2012_fishhar'"

use "${bihs2012}${slash}001_mod_a_male", clear
keep a01 Sample_type
merge 1:1 a01 using `bihs2012boro', nogen
drop if Sample_type==1
drop Sample_type
	
merge 1:1 a01 using "${bihs2012}${slash}BIHS_FTF baseline sampling weights" , keep(3) nogen keepusing(hhweight)
drop agri_control maize_hh boro_hh 

keep if agri_control_household == 1 
tempfile bihs2012boro
save `bihs2012boro', replace

use  "${bihs2012}${slash}026_mod_l1_male", clear
merge m:1 a01 using "`bihs2012boro'" , nogenerate keepusing(fishing_hh)
rename fishing_hh fishing_hh_check
drop if sample_type == 1 
gen fishing_hh = 0 
replace fishing_hh = 1 if l1_02_1 != . & pondid != 999
replace pondid = . if pondid == 999
keep if fishing_hh_check == 1

collapse (max)fishing_hh_check (mean) pond_size=l1_01 total_harvest_n=l1_10 (sum) total_harvest=l1_11 (count) avg_plots=pondid , by(a01)
replace avg_plots = . if fishing_hh == 0

merge 1:1 a01 using "`bihs2012boro'" , nogenerate keepusing(agri_control_household hhweight)
merge 1:1 a01 using "`2012_fishhar'" , nogenerate 

replace fishing_hh_check = 0 if fishing_hh_check == . & agri_control_household == 1 

winsor2 pond_size, suffix(_w) cuts(1 99)
winsor2 avg_plots, suffix(_w) cuts(1 99)
winsor2 total_harvest_n, suffix(_w) cuts(1 99)
winsor2 total_harvest, suffix(_w) cuts(1 99)
winsor2 tilapia_har, suffix(_w) cuts(1 99)
winsor2 rohu_har, suffix(_w) cuts(1 99)

gen round = 2012

tempfile fishing_2012_pre
save `fishing_2012_pre', replace

collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w fishing_hh_check rohu_har_w tilapia_har_w [pweight=hhweight], by(round)
rename fishing_hh_check fishing_hh

tempfile fishing_2012
save `fishing_2012', replace

append using `fishing_2015' //temp data 2015
append using `fishing_2018' //temp data 2018 
append using `fishing_2024' //temp data 2024

gen only_stayed = 0 // Generate a new variable to identify households that stayed in aquaculture in the past decade - this will be used later. 

tempfile fishing_2012_2024_all
save `fishing_2012_2024_all', replace // This temp file has all aquaculture households from 2012 to 2024

*** Dataset identifying households that stayed in aquaculture from 2012 to 2024 **** 

use `fishing_2024_pre' , clear 
keep if fishing_hh == 1 
rename a01combined_18 a01 
destring a01 , replace
keep a1hhid_combined a01 a01combined_15 a01_12 fishing_hh
rename fishing_hh fishing_hh_24

merge m:1 a01 using `fishing_2018_pre' , nogenerate keep(3) keepusing(a01 fishing_hh_check)
rename a01 a01combined_18
rename fishing_hh_check fishing_hh_18
rename a01combined_15 a01
destring a01 , replace

merge m:1 a01 using `fishing_2015_pre' , nogenerate keep(3) keepusing(a01 fishing_hh_check)
rename a01 a01combined_15
rename fishing_hh_check fishing_hh_15
rename a01_12 a01
destring a01 , replace

merge m:1 a01 using `fishing_2012_pre' , nogenerate keep(3) keepusing(a01 fishing_hh_check)
rename a01 a01combined_12
rename fishing_hh_check fishing_hh_12

keep if fishing_hh_24 == 1 & fishing_hh_18 == 1 & fishing_hh_15 ==1 & fishing_hh_12 == 1

gen fishing_hh_allrounds = 1

keep a1hhid_combined a01combined_18 a01combined_15 a01combined_12 fishing_hh_allrounds
tempfile fishing_stayed
save `fishing_stayed', replace // This temp only has aquaculture households that stayed from 2012 to 2024 

*** Combine this with the individual datasets and then only retain those that stayed in all rounds *** 
* 2024
use `fishing_2024_pre', clear
merge m:1 a1hhid_combined using `fishing_stayed' , nogenerate keepusing(fishing_hh_allrounds) 
keep if fishing_hh_allrounds == 1 
duplicates drop 
 
collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w tilapia_har_w rohu_har_w fishing_hh [pweight=hhweight_24], by(round)

tempfile fishing_2024_only_stayed
save `fishing_2024_only_stayed', replace //Those in 2024 that stayed 

* 2018
use  `fishing_stayed' , clear 
keep a01combined_18 fishing_hh_allrounds 
duplicates drop
tempfile fishing_stayed_18
save `fishing_stayed_18', replace

use `fishing_2018_pre', clear
rename a01 a01combined_18
merge m:1 a01combined_18 using `fishing_stayed_18' , nogenerate keepusing(fishing_hh_allrounds) 
keep if fishing_hh_allrounds == 1 
duplicates drop 
collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w fishing_hh_check rohu_har_w tilapia_har_w [pweight=hhweight], by(round)
rename fishing_hh_check fishing_hh

tempfile fishing_2018_only_stayed
save `fishing_2018_only_stayed', replace //Those in 2018 that stayed 

* 2015
use  `fishing_stayed' , clear 
keep a01combined_15 fishing_hh_allrounds 
duplicates drop
tempfile fishing_stayed_15
save `fishing_stayed_15', replace
 
use `fishing_2015_pre', clear
rename a01 a01combined_15
merge m:1 a01combined_15 using `fishing_stayed_15' , nogenerate keepusing(fishing_hh_allrounds) 
keep if fishing_hh_allrounds == 1 
duplicates drop 
collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w fishing_hh_check rohu_har_w tilapia_har_w [pweight=hhweight], by(round)
rename fishing_hh_check fishing_hh

tempfile fishing_2015_only_stayed
save `fishing_2015_only_stayed', replace //Those in 2015 that stayed 

* 2012
use  `fishing_stayed' , clear 
keep a01combined_12 fishing_hh_allrounds 
duplicates drop
tempfile fishing_stayed_12
save `fishing_stayed_12', replace

use `fishing_2012_pre', clear
rename a01 a01combined_12
merge m:1 a01combined_12 using `fishing_stayed_12' , nogenerate keepusing(fishing_hh_allrounds) 
keep if fishing_hh_allrounds == 1 
duplicates drop 
collapse (mean) avg_plots_w pond_size_w total_harvest_n_w total_harvest_w fishing_hh_check rohu_har_w tilapia_har_w [pweight=hhweight], by(round)
rename fishing_hh_check fishing_hh

tempfile fishing_2012_only_stayed
save `fishing_2012_only_stayed', replace //Those in 2012 that stayed 

append using `fishing_2015_only_stayed'
append using `fishing_2018_only_stayed'
append using `fishing_2024_only_stayed'

gen only_stayed = 1

tempfile fishing_2012_2024_stayed
save `fishing_2012_2024_stayed', replace

** Further combining two datasets to prepare for the complete analysis - This gives us all the relevant households. 
use `fishing_2012_2024_all', clear
append using  `fishing_2012_2024_stayed'

gen pct_fishery_hh = (fishing_hh)*100
replace pct_fishery_hh =round(pct_fishery_hh, .01)

foreach x in avg_plots_w pond_size_w total_harvest_n_w total_harvest_w tilapia_har_w rohu_har_w {
replace `x' = round(`x', .01)
}

** Label variables  **
label var pct_fishery_hh "Fishing Household (%)"
label var fishing_hh "Total fishing households"
label var avg_plots_w "Average nunber of ponds"
label var pond_size_w "Average pond size(decimal)"
label var total_harvest_n_w "Average number of harvests"
label var total_harvest_w "Average quantity of harvest(kg/year)"
label var tilapia_har_w "Tilapia: Average quantity of harvest(kg/year)"
label var rohu_har_w "Rohu: Average quantity of harvest(kg/year)"
label var round "BIHS Round"

******************************************************************************** 
** CREATE THE FIGURES **
******************************************************************************** 

* Figure 10: Percentage of aquaculture HH across the panel
preserve 
keep if only_stayed == 0
scatter pct_fishery_hh round, lcolor(dknavy) connect(l) mlabposition(8) mlabel(pct_fishery_hh) ///
	scheme(s1color) msymbol(o) xlabel(, nogrid) ylabel(22(2)32, nogrid) ///
	lcolor(dknavy) mcolor(dknavy) mlabcolor(dknavy) mlabsize(vsmall) ///
	 xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	 ytitle("Percentage of Aquacultural HHs", size(small)) /// 
	 xtitle("Round") ///
	 title("Households Undertaking Aquaculture")
graph export "${final_figure}${slash}figure_10.png", replace as(png)
restore

* Figure 11: Average Number of Ponds per HH (left panel), Average Pond Size per HH (right panel)
preserve 
keep if only_stayed == 0
* Average pond size
scatter pond_size_w round, lcolor(dknavy) connect(l) mlabposition(12) mlabel(pond_size_w) ///
	scheme(s1color) msymbol(o) xlabel(, nogrid) ylabel(15(2)25, nogrid) ///
	lcolor(dknavy) mcolor(dknavy) mlabcolor(dknavy) mlabsize(vsmall) ///
	 xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	 ytitle("decimals", size(small)) /// 
	 xtitle("Round") ///
	 title("Average Pond Size per HH")
	 
graph save "${final_figure}${slash}temporary_graphs${slash}ga.gph", replace

* Average number of ponds 
scatter avg_plots_w round, lcolor(dknavy) connect(l) mlabposition(12) mlabel(avg_plots_w) ///
	scheme(s1color) msymbol(o) xlabel(, nogrid) ylabel(0(.5)2, nogrid) ///
	lcolor(dknavy) mcolor(dknavy) mlabcolor(dknavy) mlabsize(vsmall) ///
	 xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	 ytitle("Number of ponds", size(small)) /// 
	 xtitle("Round") ///
	 title("Average Number of Ponds per HH")
	 
graph save "${final_figure}${slash}temporary_graphs${slash}gb.gph", replace

graph combine "${final_figure}${slash}temporary_graphs${slash}gb.gph" "${final_figure}${slash}temporary_graphs${slash}ga.gph", ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}figure_11.png", replace as(png)

* Figure Note: The variables are windsorized at 1% and 99% to account for extreme values. 
* This includes all fishing households in each round. 
restore 

* Figure 12: Distribution of Ponds per Household in 2024
preserve
use `fishing_2024_pre', clear 
keep if fishing_hh == 1 

histogram avg_plots, width(0.2) frequency ///
    color(dknavy) lcolor(black) ///
    xlabel(, nogrid) ylabel(, nogrid) ///
    title("Distribution of Ponds per Household in 2024") ///
    xtitle("Ponds") ytitle("Number of Households") ///
    scheme(s1color)
graph export "${final_figure}${slash}figure_12.png", replace as(png)
* Figure Note: The variables are windsorized at 1% and 99% to account for extreme values. 
* This includes all fishing households in each round. 
restore


* Figure 13: Average Number of Harvests per HH (left panel), Average Harvest per HH (Kgs) (right panel)
* Average number of harvests
use `fishing_2012_2024_all', clear 
preserve
replace total_harvest_n_w = round(total_harvest_n_w, 0.1)
scatter total_harvest_n_w round, lcolor(dknavy) connect(l) mlabposition(12) mlabel(total_harvest_n_w) ///
	scheme(s1color) msymbol(o) xlabel(, nogrid) ylabel(10(5)30, nogrid) ///
	lcolor(dknavy) mcolor(dknavy) mlabcolor(dknavy) mlabsize(vsmall) ///
	 xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	 ytitle("Number of harvests", size(small)) /// 
	 xtitle("Round") ///
	 title("Average Number of Harvests per HH")
graph save "${final_figure}${slash}temporary_graphs${slash}gc.gph", replace
restore

* Average amount of harvest
preserve
replace total_harvest_w = round(total_harvest_w, 0.1)
scatter total_harvest_w round, lcolor(dknavy) connect(l) mlabposition(12) mlabel(total_harvest_w) ///
	scheme(s1color) msymbol(o) xlabel(, nogrid) ylabel(125(25)250, nogrid) ///
	lcolor(dknavy) mcolor(dknavy) mlabcolor(dknavy) mlabsize(vsmall) ///
	 xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	 ytitle("Kilograms", size(small)) /// 
	 xtitle("Round") ///
	 title("Average Harvest per HH (Kgs)")
graph save "${final_figure}${slash}temporary_graphs${slash}gd.gph", replace
restore

graph combine "${final_figure}${slash}temporary_graphs${slash}gc.gph" "${final_figure}${slash}temporary_graphs${slash}gd.gph", ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}figure_13.png", replace as(png)



* Figure 16: Average Tilapia and Rohu Harvest per HH (Kg/annum) 
preserve
twoway ///
    (scatter tilapia_har_w round if only_stayed == 0, connect(l) ///
        lcolor(dknavy) mcolor(dknavy) msymbol(o) ///
        mlabel(tilapia_har_w) mlabposition(12) mlabcolor(dknavy) mlabsize(vsmall)) ///
    (scatter tilapia_har_w round if only_stayed == 1, connect(l) ///
        lcolor(maroon) mcolor(maroon) msymbol(s) ///
        mlabel(tilapia_har_w) mlabposition(6) mlabcolor(maroon) mlabsize(vsmall)), ///
    legend(label(1 "All households") label(2 "Households that stayed throughout") position(6) size(vsmall) region(lstyle(none))) ///
    scheme(s1color) ///
    xlabel(, nogrid) ///
    ylabel(20(20)120, nogrid) /// 
	xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	ytitle("Kilograms", size(small)) /// 
	xtitle("Round") ///
	title("Average Tilapia Harvests per HH (Kg)")
graph save "${final_figure}${slash}temporary_graphs${slash}ge.gph", replace

twoway ///
    (scatter rohu_har_w round if only_stayed == 0, connect(l) ///
        lcolor(dknavy) mcolor(dknavy) msymbol(o) ///
        mlabel(rohu_har_w) mlabposition(12) mlabcolor(dknavy) mlabsize(vsmall)) ///
    (scatter rohu_har_w round if only_stayed == 1, connect(l) ///
        lcolor(maroon) mcolor(maroon) msymbol(s) ///
        mlabel(rohu_har_w) mlabposition(12) mlabcolor(maroon) mlabsize(vsmall)), ///
    legend(label(1 "All households") label(2 "Households that stayed throughout") position(6) size(vsmall) region(lstyle(none))) ///
    scheme(s1color) ///
    xlabel(, nogrid) ///
    ylabel(30(20)150, nogrid) ///
	xtick(2012 2015 2018 2024) xscale(range(2012 2024)) ///
	ytitle("Kilograms", size(small)) /// 
	xtitle("Round") ///
	title("Average Rohu Harvest per HH (Kg)")
graph save "${final_figure}${slash}temporary_graphs${slash}gf.gph", replace

graph combine "${final_figure}${slash}temporary_graphs${slash}ge.gph" "${final_figure}${slash}temporary_graphs${slash}gf.gph", ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}figure_16.png", replace as(png)
restore 

* Figure 14: Aquaculture Households by Division across the panel
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
collapse (first) agri_control_household , by(a1hhid_combined)
tempfile 2024_ag 
save "`2024_ag'"

use "${final_data}${slash}SPIA_BIHS_2024_module_e5.dta", clear 
keep b1plot_fishing a1hhid_combined
duplicates drop 
merge 1:1 a1hhid_combined using "`2024_ag'" , nogenerate 
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keepusing(divisionname hhweight_24)

keep if agri_control_household == 1 
replace b1plot_fishing = 0 if b1plot_fishing != 1

collapse (mean) fishing_pct=b1plot_fishing agri_control_household [pweight=hhweight_24] , by(divisionname)
replace fishing_pct = 100*(fishing_pct)
replace fishing_pct =round(fishing_pct, .01) 
rename fishing_pct fishing_pct_24
keep fishing_pct_24 divisionname
tempfile 2024_fishpct 
save "`2024_fishpct'"

* Changes from 2012 
use "${bihs2012}${slash}011_mod_h1_male", clear
drop if sample_type==1
gen boro_hh = (inrange(crop_a, 11, 20) | inrange(crop_b, 11, 20))  & ///
((h1_04a==4 & h1_04b==12) | inrange(h1_04b, 1, 2) | inrange(h1_04a, 1, 2) & h1_04b==3)
g maize_hh = (crop_a == 23 | crop_b == 23) & inrange(h1_04b, 10, 11) 
collapse (max) boro_hh maize_hh, by(a01)
g agri_control	= 1
tempfile bihs2012agri
save `bihs2012agri', replace
	
u "${bihs2012}${slash}026_mod_l1_male", clear
drop if sample_type==1
drop if pondid == 999
g fishing_hh = 1
collapse(max) fishing_hh, by(a01)
merge 1:1 a01 using `bihs2012agri', nogen
g agri_control_household = (fishing_hh== 1 | agri_control == 1)
keep a01 fishing_hh agri_control_household

merge 1:1 a01 using "${bihs2012}${slash}001_mod_a_male" , keepusing(div_name) nogenerate keep(3)
merge 1:1 a01 using "${bihs2012}${slash}BIHS_FTF baseline sampling weights" , keep(3) nogen keepusing(hhweight)

replace fishing_hh = 0 if fishing_hh != 1

collapse (mean) fishing_pct=fishing_hh agri_control_household [pweight=hhweight], by(div_name)
replace fishing_pct = 100*(fishing_pct)
replace fishing_pct =round(fishing_pct, .01) 
rename fishing_pct fishing_pct_12 
rename div_name divisionname
keep divisionname fishing_pct_12

* Merge the two division level datasets
merge 1:1 divisionname using "`2024_fishpct'" , nogenerate 

graph bar fishing_pct_12 fishing_pct_24 , over(divisionname , sort(fishing_pct_24)) ///
ytitle("Percent of Agricultural HHs", size(small)) /// 
title("Aquaculture Households by Division") ///
legend(order(1 "2012" 2 "2024") size(vsmall) pos(6) col(2)) ///
ylabel(, noticks nogrid angle(0) labsize(vsmall))  ///
bar(1, color(dknavy)) ///
bar(2, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("Division")  ///
blabel(bar, position(inside) color(white) format(%4.1f) size(vsmall)) 
graph export "${final_figure}${slash}figure_14.png", replace as(png)	

* Figure 15: Household adoption by Fish Breed
use "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", clear 
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate keepusing(hhweight_24)
decode e6fish_species_id , gen(fish)
tab fish , gen(fishname_)
keep a1hhid_combined fishname_* hhweight_24 fish

foreach var of varlist * {
    local label_`var' : variable label `var'
}
collapse (max) fishname_* hhweight_24 , by(a1hhid_combined)
foreach var of varlist * {
    label var `var' "`label_`var''"
}

foreach var of varlist * {
    local label_`var' : variable label `var'
}
collapse (mean) fishname_*  [pweight=hhweight_24]
foreach var of varlist * {
    label var `var' "`label_`var''"
}
 
foreach var of varlist * {
    replace `var' = `var' * 100
}

gen hh = 1 
reshape long fishname_, i(hh) j(fishid)
rename fishname_ pct_hh
sort pct_hh
keep if pct_hh >= 5 
drop hh
sort fishid

gen fishname = ""
replace fishname = "Grass carp" if fishid == 2 
replace fishname = "Karfu" if fishid == 4
replace fishname = "Katla" if fishid == 5
replace fishname = "Koi" if fishid == 7
replace fishname = "Mirror Carp" if fishid == 9
replace fishname = "Small indigenous fish" if fishid == 10
replace fishname = "Mrigel" if fishid == 11
replace fishname = "Small other fish" if fishid == 13
replace fishname = "Pangesh" if fishid == 14
replace fishname = "Puti/Swarputi" if fishid == 17
replace fishname = "Rohu" if fishid == 18
replace fishname = "Shingi" if fishid == 19
replace fishname = "Shol/Gajar" if fishid == 20
replace fishname = "Silver carp" if fishid == 22
replace fishname = "Tilapia" if fishid == 23

graph hbar pct_hh , over(fishname, sort(pct_hh) desc) stack ///
ytitle("Percent of Fishing Households (Total Households:710)", size(small)) /// 
title("Household Adoption by Fish Breed") ///
ylabel(, noticks nogrid angle(0) labsize(vsmall))  ///
bar(1, color(dknavy)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
blabel(bar, position(center) color(white) format(%4.1f) size(small)) 
graph export "${final_figure}${slash}figure_15.png", replace as(png)	

* Table 14: Comparisons between households remaining, entering, and exiting aquaculture within 2018 and 2024
u "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear 
collapse (first) agri_control_household, by(a1hhid_combined)
tempfile 2024_ag 
save "`2024_ag'"

use "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear 
gen tilapia_24 = 1 if e1fish_id == 1 & e1fish_lastyear == 1 
gen rohu_24 = 1 if e1fish_id == 2 & e1fish_lastyear == 1 
collapse (max) tilapia_24 rohu_24 , by(a1hhid_combined)
tempfile e1_2
save "`e1_2'"

use "${final_data}${slash}SPIA_BIHS_2024_module_e5.dta", clear 
collapse (count) avg_plots=b1plot_num (mean) pond_size=b1plotsize_decimal pond_depth=b1flood_depth total_daily_wage=e5_daily_wage ///
total_harvest_n=e5n_harvest total_harvest=e5tot_harvest (max) fishing_hh=b1plot_fishing , by(a1hhid_combined)
merge 1:1 a1hhid_combined using "`2024_ag'" , nogenerate 

winsor2 pond_size, suffix(_w) cuts(1 99)
winsor2 pond_depth, suffix(_w) cuts(1 99)
winsor2 avg_plots, suffix(_w) cuts(1 99)
winsor2 total_harvest_n, suffix(_w) cuts(1 99)
winsor2 total_harvest, suffix(_w) cuts(1 99)

merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keepusing(hhweight_24)

gen round = 2024

replace fishing_hh = 0 if fishing_hh == . & agri_control_household == 1 
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate
rename a01combined_18 a01

merge 1:1 a1hhid_combined using "`e1_2'" , nogenerate

keep a1hhid_combined a1hhid_combined fishing_hh agri_control_household ///
pond_depth_w avg_plots_w total_harvest_n_w total_harvest_w hhweight_24 a1division divisionname a01 pond_size_w pond_size tilapia_24 rohu_24

rename fishing_hh fishing_hh_24

tempfile fishing_2024_pre1
save `fishing_2024_pre1'

** 2018 *** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
g agri_control	= cond(h1_sl == 99, 0, 1)
collapse (max) agri_control, by(a01)
tempfile bihs2018agri
save `bihs2018agri', replace

use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
drop if sl_l1 == 0 | pondid_l1==999

gen tilapia_18 = 1 if inlist(l1_02_1,1,2,3,4,5)
replace tilapia_18 = 1 if inlist(l1_02_2,1,2,3,4,5) & tilapia_18 == . 
replace tilapia_18 = 1 if inlist(l1_02_3,1,2,3,4,5) & tilapia_18 == . 
replace tilapia_18 = 1 if inlist(l1_02_4,1,2,3,4,5) & tilapia_18 == . 
replace tilapia_18 = 1 if inlist(l1_02_5,1,2,3,4,5) & tilapia_18 == . 
replace tilapia_18 = 1 if inlist(l1_02_6,1,2,3,4,5) & tilapia_18 == . 
replace tilapia_18 = 1 if inlist(l1_02_7,1,2,3,4,5) & tilapia_18 == . 
gen rohu_18 = 1 if l1_02_1 == 6 | l1_02_2 == 6 | l1_02_3 == 6 | l1_02_4 == 6 | l1_02_5 == 6 | l1_02_6 == 6 | l1_02_7 == 6 

collapse (max) tilapia_18 rohu_18 , by(a01)
tempfile e1_2_18
save "`e1_2_18'"
	
use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
drop if sl_l1 == 0 | pondid_l1==999
g fishing_hh = 1
collapse(max) fishing_hh, by(a01)
merge 1:1 a01 using `bihs2018agri', nogen
g agri_control_household = (fishing_hh== 1 | agri_control == 1)
collapse (max)fishing_hh agri_control agri_control_household, by(a01)

merge 1:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
replace fishing_hh = 0 if fishing_hh == . & agri_control_household == 1 

tempfile bihs2018agri
save `bihs2018agri', replace 

use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
merge m:1 a01 using "`bihs2018agri'" , nogenerate keepusing(fishing_hh)
rename fishing_hh fishing_hh_check

gen fishing_hh = 0 
replace fishing_hh = 1 if l1_02_1 != . & pondid_l1 != 999
replace l1_02b = 0 if l1_02b == 2 
replace pondid_l1 = . if pondid_l1 == 999
keep if fishing_hh_check == 1

collapse (max)fishing_hh_check (mean) pond_size=l1_01 total_harvest_n=l1_10 total_harvest=l1_11 (first) round (count)avg_plots=pondid_l1 , by(a01)

winsor2 pond_size, suffix(_w) cuts(1 99)
winsor2 avg_plots, suffix(_w) cuts(1 99)
winsor2 total_harvest_n, suffix(_w) cuts(1 99)
winsor2 total_harvest, suffix(_w) cuts(1 99)

merge 1:1 a01 using "`bihs2018agri'" , nogenerate keepusing(agri_control_household agri_control hhweight)
replace fishing_hh_check = 0 if fishing_hh_check == . & agri_control_household == 1

merge 1:1 a01 using "`e1_2_18'" , nogenerate 

replace round = 2018 

foreach var of varlist * {
    rename `var' `var'_18
}
rename a01_18 a01
tostring a01 , replace 
merge 1:m a01 using "`fishing_2024_pre1'"  , nogenerate keep(3) 

rename fishing_hh_check_18 fishing_hh_18

gen left_ag = 0 
replace left_ag = 1 if fishing_hh_18 == 1 & fishing_hh_24 == 0 
replace left_ag = 1 if fishing_hh_18 == 1 & fishing_hh_24 == .

gen enter_ag = 0
replace enter_ag = 1 if fishing_hh_18 == 0 & fishing_hh_24 == 1 
replace enter_ag = 1 if fishing_hh_18 == . & fishing_hh_24 == 1 

gen remained_ag = 0 
replace remained_ag = 1 if fishing_hh_18 == 1 & fishing_hh_24 == 1  

drop if left_ag == 0 & enter_ag == 0 & remained_ag == 0 //never takers

tempfile Ag_24_18_combined
save "`Ag_24_18_combined'"


* Profits/decimal [Taka] 
use "`Ag_24_18_combined'" , clear 
preserve
use "${prior_data}${slash}BIHS_hh_expenditure_r123.dta" , clear 
keep if round == 3 
keep pc_expm pc_foodxm pc_nonfxm hhsize a01 hh_type
tostring a01 , replace
tempfile consumption
save "`consumption'"
restore 

* savings in 2024/consumption in 2018/pond area/harvest 
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a5_6.dta" , keepusing(a6_hh_savings) keep(1 3) nogenerate
merge m:1 a01 using "`consumption'" , nogenerate keep(3)

tempfile fish
save "`fish'"

* cost of labor in 2018/2024 - per total harvest 
use "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", clear 
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate  ///
keepusing(a1district districtname)

preserve 
gen price_sol = e6tot_earning/e6quant_sold
winsor2 price_sol, suffix(_w) cuts(1 99) 
drop price_sol
collapse (mean) price_sol_w  (first) districtname, by(a1district)
summ price_sol_w
replace price_sol_w = 199 if price_sol_w < 10 | price_sol_w == . //10 districts missing
replace price_sol_w = round(price_sol_w,2)
tempfile f_price 
save "`f_price'"
restore 
merge m:1 districtname using "`f_price'" , keepusing(price_sol_w) nogenerate keep(3)

gen total_rev_24 = (e6consumed + e6fish_paid_lab + e6dry_fish + e6gifted + e6quant_sold)*price_sol_w
replace total_rev_24 = . if total_rev_24 == 0  
keep a1hhid_combined a1district districtname price_sol_w total_rev_24
collapse (sum) total_rev_24 , by(a1hhid_combined)
tempfile f_rev
save "`f_rev'" 

use "${final_data}${slash}SPIA_BIHS_2024_module_e5.dta", clear 
replace e5_daily_wage = 0 if e5_daily_wage == . 
gen total_cost_24 = e5_daily_wage + e5fingerling_cost + e5fishfeed_cost + e5other_cost
collapse (sum) total_cost_24 , by(a1hhid_combined)
merge 1:1 a1hhid_combined using "`f_rev'" , nogenerate keep(3)
gen total_profit_24 = total_rev_24-total_cost_24
replace total_profit_24 = . if total_rev_24 == 0 
keep a1hhid_combined total_profit_24
tempfile fish_p24
save "`fish_p24'"

use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
drop if l1_02_1 == . 
drop if sl_l1 == 0 | pondid_l1==999
gen l1_04_day = l1_04/24 
gen laborcost = l1_04_day*l1_05
gen total_cost_18 = l1_09 + laborcost 
collapse (sum) total_cost_18 , by(a01) 
tostring a01 , replace 
tempfile 2018c
save "`2018c'"

use "${bihs2018}${slash}052_bihs_r3_male_mod_l2", clear
drop if l2_01 == 0 
merge m:1 a01 using "${bihs2018}${slash}009_bihs_r3_male_mod_a.dta" , keep(3) nogenerate keepusing(district)
preserve 
gen price_sol = l2_12/l2_10
winsor2 price_sol, suffix(_w) cuts(1 99) 
drop price_sol
collapse (mean) price_sol_w , by(district)
summ price_sol_w
replace price_sol_w = 204 if price_sol_w < 10 | price_sol_w == . //10 districts missing
replace price_sol_w = round(price_sol_w,2)
tempfile f_price 
save "`f_price'"
restore 

merge m:1 district using "`f_price'" , keepusing(price_sol_w) nogenerate keep(3)
gen total_rev_18 = (l2_03+l2_04)*price_sol_w
replace total_rev_18 = . if total_rev_18 == 0  
keep a01 district price_sol_w total_rev_18
collapse (sum) total_rev_18 , by(a01)
tostring a01 , replace 
merge 1:1 a01 using "`2018c'" , nogenerate keep(3)
gen total_profit_18 = total_rev_18-total_cost_18
replace total_profit_18 = . if total_rev_18 == 0 

tempfile fish_p18 
save "`fish_p18'"

use  "`fish'" , clear 
merge 1:1 a1hhid_combined using "`fish_p24'" , nogenerate keep(1 3)
merge m:1 a01 using "`fish_p18'" , nogenerate keep(1 3)

gen total_profit_18_dec = total_profit_18/pond_size_w_18
gen total_profit_24_dec = total_profit_24/pond_size_w

* left 
preserve 
keep if left_ag == 1 
duplicates drop a01 , force
summ total_profit_18_dec total_profit_18
collapse (mean) total_profit_18_dec 
replace total_profit_18_dec = round(total_profit_18_dec,0.1)
rename total_profit_18_dec left_ag_18
gen indicator = "Profits/decimal [Taka]" 

tempfile g
save "`g'"
restore 

* Remained - 2018 
preserve 
keep if remained_ag == 1 
duplicates drop a01 , force
summ total_profit_18_dec total_profit_18
collapse (mean) total_profit_18_dec
replace total_profit_18_dec = round(total_profit_18_dec,0.1)
rename total_profit_18_dec remained_ag_18
gen indicator = "Profits/decimal [Taka]"
tempfile h
save "`h'"
restore

* Remained - 2024
preserve 
keep if remained_ag == 1 
summ total_profit_24_dec total_profit_24 
collapse (mean) total_profit_24_dec
replace total_profit_24_dec = round(total_profit_24_dec,0.1)
rename total_profit_24_dec remained_ag_24
gen indicator = "Profits/decimal [Taka]"
tempfile i
save "`i'"
restore

* Enter
preserve 
keep if enter_ag == 1 
summ total_profit_24_dec total_profit_24
collapse (mean) total_profit_24_dec
replace total_profit_24_dec = round(total_profit_24_dec,0.1)
rename total_profit_24_dec enter_ag_24
gen indicator = "Profits/decimal [Taka]"
tempfile j
save "`j'"
restore 

use "`g'" , clear 

merge 1:1 indicator using "`h'" , nogen 
merge 1:1 indicator using "`i'" , nogen 
merge 1:1 indicator using "`j'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_18 remained_ag_24

tempfile profit
save "`profit'" , replace


* Percentage of HHs that also did agriculture in 2018
use "`fish'" , clear

preserve 
keep fishing_hh_18 a01 agri_control_18 agri_control_household_18 a1hhid_combined fishing_hh_24 left_ag 
keep if left_ag == 1 
duplicates drop a01 , force
collapse (mean) agri_control_18
replace agri_control_18 = round((agri_control_18*100), 0.1)
rename agri_control_18 left_ag_18
gen indicator = "Percentage of HHs that also did agriculture in 2018"

tempfile k
save "`k'"
restore

preserve 
keep fishing_hh_18 a01 agri_control_18 agri_control_household_18 a1hhid_combined fishing_hh_24 remained_ag 
keep if remained_ag == 1 
duplicates drop a01 , force
duplicates drop a01 , force
collapse (mean) agri_control_18
replace agri_control_18 = round((agri_control_18*100), 0.1)
rename agri_control_18 remained_ag_18
gen indicator = "Percentage of HHs that also did agriculture in 2018"

tempfile l
save "`l'"
restore

preserve 
keep fishing_hh_18 a01 agri_control_18 agri_control_household_18 a1hhid_combined fishing_hh_24 enter_ag 
keep if enter_ag == 1 
duplicates drop a01 , force
collapse (mean) agri_control_18
replace agri_control_18 = round((agri_control_18*100), 0.1)
rename agri_control_18 enter_ag_24
gen indicator = "Percentage of HHs that also did agriculture in 2018"
tempfile m
save "`m'"
restore

use "`k'" , clear 

merge 1:1 indicator using "`l'" , nogen 
merge 1:1 indicator using "`m'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_18 

tempfile pct_ag
save "`pct_ag'" , replace

* Amount of Harvest [Kg/year]
use "`fish'" , clear

preserve 
keep if left_ag == 1 
collapse (mean) total_harvest_18 
replace total_harvest_18 = round((total_harvest_18), 0.1)
rename total_harvest_18 left_ag_18
gen indicator = "Amount of Harvest [Kg/year]"

tempfile n1
save "`n1'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) total_harvest_18 
replace total_harvest_18 = round((total_harvest_18), 0.1)
rename total_harvest_18 remained_ag_18
gen indicator = "Amount of Harvest [Kg/year]"

tempfile o1
save "`o1'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) total_harvest_w
replace total_harvest_w = round((total_harvest_w), 0.1)
rename total_harvest_w remained_ag_24
gen indicator = "Amount of Harvest [Kg/year]"

tempfile p1
save "`p1'"
restore

preserve 
keep if enter_ag == 1 
collapse (mean) total_harvest_w
replace total_harvest_w = round((total_harvest_w), 0.1)
rename total_harvest_w enter_ag_24
gen indicator = "Amount of Harvest [Kg/year]"

tempfile q1
save "`q1'"
restore

use "`n1'" , clear 

merge 1:1 indicator using "`o1'" , nogen 
merge 1:1 indicator using "`p1'" , nogen 
merge 1:1 indicator using "`q1'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_18 remained_ag_24

tempfile harvest
save "`harvest'" , replace

* Size of pond [decimal] 
use "`fish'" , clear

preserve 
keep if left_ag == 1 
collapse (mean) pond_size_w_18
replace pond_size_w_18 = round((pond_size_w_18), 0.1)
rename pond_size_w_18 left_ag_18
gen indicator = "Size of pond [decimal]"

tempfile n
save "`n'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) pond_size_w_18
replace pond_size_w_18 = round((pond_size_w_18), 0.1)
rename pond_size_w_18 remained_ag_18
gen indicator = "Size of pond [decimal]"

tempfile o
save "`o'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) pond_size_w
replace pond_size_w = round((pond_size_w), 0.1)
rename pond_size_w remained_ag_24
gen indicator = "Size of pond [decimal]"

tempfile p
save "`p'"
restore

preserve 
keep if enter_ag == 1 
collapse (mean) pond_size_w
replace pond_size_w = round((pond_size_w), 0.1)
rename pond_size_w enter_ag_24
gen indicator = "Size of pond [decimal]"

tempfile q
save "`q'"
restore

use "`n'" , clear 

merge 1:1 indicator using "`o'" , nogen 
merge 1:1 indicator using "`p'" , nogen 
merge 1:1 indicator using "`q'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_18 remained_ag_24

tempfile pond_size
save "`pond_size'" , replace

* Household size 
use "`fish'" , clear
preserve 
keep if left_ag == 1 
collapse (mean) hhsize
replace hhsize = round((hhsize), 0.1)
rename hhsize left_ag_18
gen indicator = "Household size"

tempfile r
save "`r'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) hhsize
replace hhsize = round((hhsize), 0.1)
rename hhsize remained_ag_24
gen indicator = "Household size"

tempfile s
save "`s'"
restore

preserve 
keep if enter_ag == 1 
collapse (mean) hhsize
replace hhsize = round((hhsize), 0.1)
rename hhsize enter_ag_24
gen indicator = "Household size"

tempfile t
save "`t'"
restore

use "`r'" , clear
merge 1:1 indicator using "`s'" , nogen 
merge 1:1 indicator using "`t'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_24

tempfile hh_size
save "`hh_size'" , replace


* Household Savings in 2024 [Taka]
use "`fish'" , clear

preserve 
keep if left_ag == 1 
collapse (mean) a6_hh_savings
replace a6_hh_savings = round((a6_hh_savings), 0.1)
rename a6_hh_savings left_ag_18
gen indicator = "Household Savings in 2024 [Taka]"

tempfile u
save "`u'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) a6_hh_savings
replace a6_hh_savings = round((a6_hh_savings), 0.1)
rename a6_hh_savings remained_ag_24
gen indicator = "Household Savings in 2024 [Taka]"

tempfile v
save "`v'"
restore

preserve 
keep if enter_ag == 1 
collapse (mean) a6_hh_savings
replace a6_hh_savings = round((a6_hh_savings), 0.1)
rename a6_hh_savings enter_ag_24
gen indicator = "Household Savings in 2024 [Taka]"

tempfile w
save "`w'"
restore

use "`u'" , clear
merge 1:1 indicator using "`v'" , nogen 
merge 1:1 indicator using "`w'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_24

tempfile hh_saving
save "`hh_saving'" , replace


* Household Monthly Consumption in 2018 [Taka]
use "`fish'" , clear

preserve 
keep if left_ag == 1 
collapse (mean) pc_expm
replace pc_expm = round((pc_expm), 0.1)
rename pc_expm left_ag_18
gen indicator = "Household Monthly Consumption in 2018 [Taka]"

tempfile x
save "`x'"
restore

preserve 
keep if remained_ag == 1 
collapse (mean) pc_expm
replace pc_expm = round((pc_expm), 0.1)
rename pc_expm remained_ag_24
gen indicator = "Household Monthly Consumption in 2018 [Taka]"

tempfile y4
save "`y4'"
restore

preserve 
keep if enter_ag == 1 
collapse (mean) pc_expm
replace pc_expm = round((pc_expm), 0.1)
rename pc_expm enter_ag_24
gen indicator = "Household Monthly Consumption in 2018 [Taka]"

tempfile z
save "`z'"
restore

use "`x'" , clear
merge 1:1 indicator using "`y4'" , nogen 
merge 1:1 indicator using "`z'" , nogen 

order indicator left_ag_18 enter_ag_24 remained_ag_24

tempfile hh_cons
save "`hh_cons'" , replace


* generate table and export 
use "`hh_cons'" , clear 
append using "`hh_saving'"
append using "`hh_size'"
append using "`pond_size'"
append using "`harvest'"
append using "`pct_ag'"
append using "`profit'"

export excel "${final_table}${slash}table_14.xlsx", replace
}
******************************************************************************** 
**# Section 6.2 AQUACULTURE ANALYSIS *** 
********************************************************************************
{
* Figure 24: Percentage of aquaculture HH raising small indigenous fish (2015-2024) 
	u "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", clear
	keep a1hhid_combined e6fish_species_id
	merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1", nogen keep(3)
	g hh_small = (e6fish_species_id==21)
	collapse (max) hh_small hhweight_24 , by(a1hhid_combined)
	collapse (mean) hh_small [pweight=hhweight_24]
	gen year  = 2024 
	replace hh_small = hh_small*100

	tempfile small_fish
	save `small_fish', replace 

	* 2018 * // 913 HHs
	use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
	drop if sl_l1 == 0 | pondid_l1==999
	g fishing_hh = 1
	collapse(max) fishing_hh, by(a01)
	tempfile 2018fish
	save `2018fish', replace 

	use "${bihs2018}${slash}052_bihs_r3_male_mod_l2", clear 
	keep a01 l2_01 hh_type round
	merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
	merge m:1 a01 using "`2018fish'" , keep(3) nogenerate 

	g hh_small = (l2_01==21)
	collapse (max) hh_small hhweight , by(a01)
	collapse (mean) hh_small [pweight=hhweight]
	gen year  = 2018 
	replace hh_small = hh_small*100

	tempfile small_fish18
	save `small_fish18', replace 

	* 2015 * 
	use "${bihs2015}${slash}037_r2_mod_l1_male", clear 
	drop if hh_type == 1 //drop those we we in additional FTF
	drop if l1_sl == 99 | pondid == 999
	g fishing_hh = 1
	collapse(max) fishing_hh, by(a01)
	tempfile 2015fish
	save `2015fish', replace 

	use "${bihs2015}${slash}038_r2_mod_l2_male", clear 
	drop if hh_type == 1 //drop those we we in additional FTF
	keep a01 l2_01 hh_type 
	merge m:1 a01 using "${bihs2015}${slash}BIHS FTF 2015 survey sampling weights" , keep(3) nogen keepusing(hhweight)
	merge m:1 a01 using "`2015fish'" , keep(3) nogenerate 

	tab l2_01 , gen(fish_)
	keep a01 l2_01 fish_* hhweight

	g hh_small = (l2_01==21)
	collapse (max) hh_small hhweight , by(a01)
	collapse (mean) hh_small [pweight=hhweight]
	gen year  = 2015 
	replace hh_small = hh_small*100

	tempfile small_fish15
	save `small_fish15', replace 

	append using `small_fish18'
	append using `small_fish'
	
	replace hh_small = round(hh_small,0.1)
	
twoway (connected hh_small year, lcolor(dknavy) mcolor(dknavy) mlabel(hh_small) mlabcolor(dknavy) mlabsize(vsmall) mlabposition(12))  ,  ///
       scheme(s1color) xlabel(, nogrid) ylabel(0(3)15, nogrid labsize(small)) xtitle("") ytitle("Percentage of Aquaculture Households" , size(small)) ///
	   legend(off)  ///  
	   title("Raising Small Indigenous Fish (2015-2024)" ,size(small)) 
graph export "${final_figure}${slash}figure_24.png", replace as(png)	


		* Table 22. Reach estimates for improved fish strains in the past one year
		u "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
	
		keep if e1fish_id == 1 & e1fish_lastyear == 1
		
		g fingerling = (e1fingerling_lastyear == 1) 
		
		g adopt_gift = (e1strain_tilapia==2)
		
		g innovation = 1
		
		preserve 
		
		g num_hh = 1
	
		collapse(max) num_hh, by(a1hhid_combined)
	
		g innovation = 1
	
		collapse(count) num_hh, by(innovation)
		
		tempfile tilapia_count_hh
		save `tilapia_count_hh', replace
		
		restore
		
		collapse(max) adopt_gift innovation hhweight_24 (first) a1village, by(a1hhid_combined)
		
		preserve 
		
		collapse(max) adopt_gift innovation, by(a1village)
		
		collapse(mean) pct_vil = adopt_gift, by(innovation)
		
		replace pct_vil = round(pct_vil*100, .01)
		tempfile tilapia_village
		save `tilapia_village', replace
		
		restore
		
		collapse(mean) pct_hh = adopt_gift (sum) total_reach = adopt_gift [pweight=hhweight_24], by(innovation)
		replace pct_hh = round(pct_hh*100, .01)
		
		merge 1:1 innovation using `tilapia_count_hh', nogen // Number of HH that raised tilapia in the past 1 year
		merge 1:1 innovation using `tilapia_village', nogen // % of villages where fishermen raised tilapia  in the past 1 year
		g innovation_label = "GIFT Tilapia"
		
		gen total = 402 
		gen pct_fingerling = round(100*(258/total),2)
		
		tempfile tilapia_innovation
		save `tilapia_innovation', replace
		
		** Small fish 
		
		u "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", clear
		keep a1hhid_combined e6fish_species_id

		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
	
		g adopt_small = (e6fish_species_id==21)
		
		g innovation = 1

		preserve 
		
		g num_hh = 1
	
		collapse(max) num_hh, by(a1hhid_combined)
	
		g innovation = 1
	
		collapse(count) num_hh, by(innovation)
		
		tempfile mola_count_hh
		save `mola_count_hh', replace
		
		restore
		
		collapse(max) adopt_small innovation hhweight_24 (first) a1village, by(a1hhid_combined)
		
		preserve 
		
		collapse(max) adopt_small innovation, by(a1village)
		
		collapse(mean) pct_vil = adopt_small, by(innovation)
		
		replace pct_vil = round(pct_vil*100, .01)
		tempfile mola_village
		save `mola_village', replace
		
		restore
		
		collapse(mean) pct_hh = adopt_small (sum) total_reach = adopt_small [pweight=hhweight_24], by(innovation)
		replace pct_hh = round(pct_hh*100, .01)
		
		merge 1:1 innovation using `mola_count_hh', nogen // Number of HH that purchased the fish fingerlings in the past 1 year
		merge 1:1 innovation using `mola_village', nogen // % of villages where fishermen purchased tilapia fingerling in the past 1 year
		g innovation_label = "Small Indigenous Fish"
		
		tempfile smallfish_innovation
		save `smallfish_innovation', replace
		
	
		** G3 Rohu
		u "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		
		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
		
		keep if e1fish_id == 2 & e1fish_lastyear == 1
		
		g adopt_g3 = (e1strain_rohu==4)
		
		g innovation = 2
		
		preserve 
		
		g num_hh = 1
	
		collapse(max) num_hh, by(a1hhid_combined)
	
		g innovation = 2
	
		collapse(count) num_hh, by(innovation)
		
		tempfile rohu_count_hh
		save `rohu_count_hh', replace
		
		restore
		
		collapse(max) adopt_g3 innovation hhweight_24 (first) a1village, by(a1hhid_combined)
		
		preserve 
		
		collapse(max) adopt_g3 innovation, by(a1village)
		
		collapse(mean) pct_vil = adopt_g3, by(innovation)
		
		replace pct_vil = round(pct_vil*100, .01)
		tempfile rohu_village
		save `rohu_village', replace
		
		restore
		
		collapse(mean) pct_hh = adopt_g3 (sum) total_reach = adopt_g3 [pweight=hhweight_24], by(innovation)
		replace pct_hh = round(pct_hh*100, .01)
		g innovation_label = "G3 Rohu"
		merge 1:1 innovation using `rohu_count_hh', nogen // Number of HH that purchased the fish fingerlings in the past 1 year
		merge 1:1 innovation using `rohu_village', nogen // % of villages where fishermen purchased tilapia fingerling in the past 1 year
		
		append using `tilapia_innovation'
		append using `smallfish_innovation'
		
		preserve
		
		u "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		
		g num_hh = 1
	
		collapse(max) num_hh, by(a1hhid_combined)
	
		g innovation = 1
	
		collapse(count) num_hh, by(innovation)
		
		levelsof num_hh, local(num_fish_hh)
		
		restore
		
		g pct_fish_hh = (num_hh/`num_fish_hh')*100
		
		g tot_reach_k = (total_reach/1000)
		
		g tot_reach_m = (total_reach/1000000)
				
		la var innovation_label "Name of fish strain"
		la var pct_hh "% of HH with strain among fingerling purchasing HH (past 1 year)"
		la var pct_vil "% of villages with strain among fingerling purchasing villages (past 1 year)"
		la var num_hh "Number of HH satisfying the conditions"
		la var pct_fish_hh "% of fishing HH purchasing fingerling in the past 1 year"
		la var tot_reach_k "Estimated number of households (in thousands)"
		
		
		drop innovation total_reach num_hh tot_reach_m
		
		order innovation_label pct_hh pct_vil pct_fish_hh tot_reach_k
		
		export excel "${final_table}${slash}table_22.xlsx", firstrow(varlabels) sh("table_22") sheetmodify

* NOTE ALL INDIVIDUAL REACH NUMBER TABLES CAN BE FOUND IN TABLE (). 

}
******************************************************************************** 
**# Section 6.3 NATURAL RESOURCE MANAGEMENT *** 
********************************************************************************
{
* Figure 26: Percentage of rainfed plots (2015-2024)
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
keep a1hhid_combined a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b5* b2crop_season b2crop

keep if b1cropping_decision == 1 // Agriculturally active HHs
keep if inlist(b2crop_season,1) //only retaining current boro season
keep a1hhid_combined a1hhid_plotnum b5mainwater_source b5ground_source b5pump_type b5power_source b2crop b2crop_season

// Water source 
tabulate b5mainwater_source, generate(water_source)
gen irrigated = 1 if water_source1 == 1 | water_source3 == 1 | water_source4 == 1 | water_source5 == 1 | water_source6 == 1 

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) water_source1 water_source2 water_source3 water_source4 water_source5 ///
water_source6 irrigated (first) a1hhid_combined, by(a1hhid_plotnum)

foreach v of var * {
label var `v' `"`l`v''"'
}

merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) keepusing(hhweight_24) nogenerate

//	 plots 
replace irrigated = 0 if irrigated == . 
collapse (mean) irrigated [pweight=hhweight_24]
replace irrigated = round((irrigated*100), 0.1) 
gen round = 2024 
tempfile irr24
save `irr24', replace

*** 2018 *** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid_h1 crop_a_h1)
keep if agri_control_household == 1 
merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}022_bihs_r3_male_mod_h2"
rename plotid_h2 plotid_h1
rename crop_a_h2 crop_a_h1

merge m:1 a01 plotid_h1 crop_a_h1 using "`bihs2018boro'" , nogenerate keep(3)
order agri_control_household h1_season , after(plotid_h1)
keep if h1_season == 3 //7414 HHs left - 1,041 plots are rainfed in Boro 

// Water source 
tabulate h2_01, generate(water_source)
gen irrigated = 1 if water_source2 == 1 | water_source3 == 1 | water_source4 == 1 | water_source5 == 1 | water_source6 == 1 | ///
water_source7 == 1 | water_source8 == 1 
replace irrigated = 0 if irrigated == . 

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) irrigated hhweight, by(a01 plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}

//7049 unique Boro 2024 plots 
collapse (mean) irrigated [pweight=hhweight]
replace irrigated = round((irrigated*100), 0.1) 
gen round = 2018 

tempfile irr18
save `irr18', replace

*** 2015 *** 
use "${bihs2015}${slash}015_r2_mod_h1_male", clear
g agri_control_household = cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid crop_a)
merge m:1 a01 using "${bihs2015}${slash}BIHS FTF 2015 survey sampling weights" , keep(3) nogen keepusing(hhweight hh_type)
drop if hh_type == 1 //drop those we we in additional FTF
keep if agri_control_household == 1 
tempfile bihs2015agri
save `bihs2015agri', replace

use "${bihs2015}${slash}016_r2_mod_h2_male.dta" , clear 
merge m:1 a01 plotid crop_a using "`bihs2015agri'" , nogenerate keep(3)
order agri_control_household h1_season , after(plotid)
keep if agri_control_household == 1 
keep if h1_season == 3 //7956 HHs left

// Water source 
tabulate h2_01, generate(water_source)
gen irrigated = 1 if water_source2 == 1 | water_source3 == 1 | water_source4 == 1 | water_source5 == 1 | water_source6 == 1 | ///
water_source7 == 1 | water_source8 == 1 
replace irrigated = 0 if irrigated == . 

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) irrigated hhweight, by(a01 plotid)

foreach v of var * {
label var `v' `"`l`v''"'
}

//7049 unique Boro 2024 plots 
collapse (mean) irrigated [pweight=hhweight]
replace irrigated = round((irrigated*100), 0.1) 
gen round = 2015 

tempfile irr15
save `irr15', replace

use "`irr15'" , clear 
append using "`irr18'"
append using "`irr24'"

gen rainfed = 100-irrigated
replace rainfed = round(rainfed, 0.1) 

twoway (connected rainfed round, lcolor(dknavy) mcolor(dknavy) mlabel(rainfed) mlabcolor(dknavy) mlabsize(vsmall) mlabposition(8))  ,  ///
       scheme(s1color) xlabel(, nogrid) ylabel(0(10)30, nogrid labsize(small)) xtitle("") ytitle("Percentage of Plots" , size(small)) ///
	   legend(off)  ///  
	   title("Percentage of Rainfed Plots(2015-2024)" ,size(small)) 
graph export "${final_figure}${slash}figure_26.png", replace as(png)

* Figure 27: Primary water source for percentage of agricultural plots in the dry season

use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid_h1 crop_a_h1)
merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
keep if agri_control_household == 1 
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}022_bihs_r3_male_mod_h2", clear
rename plotid_h2 plotid_h1
rename crop_a_h2 crop_a_h1

merge m:1 a01 plotid_h1 crop_a_h1 using "`bihs2018boro'" , nogenerate keep(3)
order agri_control_household h1_season , after(h2_sl)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if h1_season == 3 //7414 HHs left - 1,041 plots are rainfed in Boro 

keep a01 h2_sl agri_control_household h1_season crop_a_h1 h2_01 h2_02 h2_03 hh_type round hhweight

tabulate h2_01, generate(water_source)
tabulate h2_02, generate(pump_type)
tabulate h2_03, generate(fuel_type)

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first) round agri_control_household crop_a_h1 h1_season hh_type ///
(max) water_source* pump_type* fuel_type* hhweight, by(a01 h2_sl)


foreach v of var * {
label var `v' `"`l`v''"'
}

*drop if water_source1 == 1 //drop rainfed

tempfile 2018_plot
save `2018_plot', replace 

preserve
** HH Level collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first)round hh_type ///
(max) water_source* hhweight, by(a01)

foreach v of var * {
label var `v' `"`l`v''"'
}

tempfile 2018_hh_source
save `2018_hh_source', replace
restore

*** 2nd collapse ********** - get overall estimates

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) water_source* [pweight=hhweight] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 6 7 8 {
    replace water_source`v' = round((water_source`v'*100), 0.1)
}
gen round = 2018

tempfile 2018_ws
save `2018_ws', replace

replace water_source4 = water_source4 + water_source5
replace water_source3 = water_source3 + water_source6
drop water_source6 water_source5

reshape long water_source , i(round) j(source)
rename water_source pct_plots
rename source water_source 
gen year = 2018
drop round

gen water_source_name = ""
replace water_source_name = "Rainfed" if water_source == 1
replace water_source_name = "River" if water_source == 2
replace water_source_name = "Pond/Lake" if water_source == 4 
replace water_source_name = "Canal" if water_source == 3
replace water_source_name = "Groundwater" if water_source == 7 
replace water_source_name = "Other" if water_source == 8 

*drop if water_source == 1

tempfile 2018water
save `2018water', replace 

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) keepusing(a1division a1district a1upazila a1village hhweight_24) nogenerate
 
keep a1division a1district a1upazila a1village a1hhid_combined a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1plot_fishing b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b5* b2crop_season agri_control_household hhweight_24

keep if agri_control_household == 1 
keep if b1_boro23_utilize == 1
keep if inlist(b2crop_season,1) //only retaining current and prior boro season

// Water source 
tabulate b5mainwater_source, generate(water_source)
tabulate b5pump_type, generate(pump_type)
tabulate b5power_source, generate(fuel_type)

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) water_source* pump_type* fuel_type* (first) hhweight_24 a1hhid_combined , by(a1hhid_plotnum)

foreach v of var * {
label var `v' `"`l`v''"'
}

tempfile 2024_plot
save `2024_plot', replace

***** HH level 
preserve
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) water_source* hhweight, by(a1hhid_combined)

foreach v of var * {
label var `v' `"`l`v''"'
}

*drop if water_source2 == 1 //drop rainfed

tempfile 2024_hh_source
save `2024_hh_source', replace
restore

//5767 unique Boro 2024 plots 

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) water_source* [pweight=hhweight_24] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 6 {
    replace water_source`v' = round((water_source`v'*100), 0.1)
}

gen year = 2024
reshape long water_source , i(year) j(source)
rename water_source pct_plots
rename source water_source 

gen water_source_name = "Other" if water_source == 1 
replace water_source_name = "Rainfed" if water_source == 2
replace water_source_name = "River" if water_source == 3
replace water_source_name = "Pond/Lake" if water_source == 4
replace water_source_name = "Canal" if water_source == 5 
replace water_source_name = "Groundwater" if water_source == 6 

append using "`2018water'"

gen pct_plots_24 = pct_plots if year == 2024
gen pct_plots_18 = pct_plots if year == 2018

graph bar pct_plots_18 pct_plots_24,over(water_source_name , sort(pct_plots_24)) ///
ytitle("Percentage of Agricultural Plots", size(small)) /// 
title("Primary Water Source in the Dry Season") ///
ylabel(, noticks nogrid angle(0) labsize(small)) ///
legend(order(1 "2018" 2 "2024") pos(6) cols(2)) ///
bar(1, color(dknavy)) ///
bar(2, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
blabel(bar, format(%4.1f) size(tiny))
graph export "${final_figure}${slash}figure_27.png" , replace 
* note("Note: Total agricultural households operating in boro season(2024) are 2230 and 2574 in 2018. A household can have multiple sources.", size(vsmall))

* Figure 28: Primary fuel source for percentage of irrigated plots in the dry season

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) keepusing(a1division a1district a1upazila a1village hhweight_24) nogenerate
 
keep a1division a1district a1upazila a1village a1hhid_combined a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1plot_fishing b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b5* b2crop_season agri_control_household hhweight_24

keep if agri_control_household == 1 
keep if b1_boro23_utilize == 1
keep if inlist(b2crop_season,1) //only retaining current and prior boro season

drop if b5mainwater_source == 1 //rainwater 
drop if b5pump_type == 1 //rainwater 

// power source 
tabulate b5power_source, generate(fuel_type)

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) fuel_type* (first) hhweight_24 a1hhid_combined , by(a1hhid_plotnum)

foreach v of var * {
label var `v' `"`l`v''"'
}


foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) fuel_type* [pweight=hhweight] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 {
    replace fuel_type`v' = round((fuel_type`v'*100), 0.1)
}
gen round = 2024

reshape long fuel_type , i(round) j(fuel)
gen year = 2024
drop round

gen fuel_name = "Electricity(grid)" if fuel == 1 
replace fuel_name = "Solar panel" if fuel == 2
replace fuel_name = "Petrol/Diesel/Gasoline" if fuel == 3
replace fuel_name = "Natural gas" if fuel == 4
replace fuel_name = "LPG" if fuel == 5

drop fuel 
order year fuel_name fuel_type 
rename fuel_type fuel_pct

graph hbar fuel_pct ,over(fuel_name, sort(fuel_pct)) ///
ytitle("Percent of Irrigated Plots", size(small)) /// 
title("Primary Fuel Source in the Dry Season") ///
ylabel( 0 (20) 80, noticks nogrid angle(0) labsize(vsmall)) ///
bar(1, color(dknavy)) ///
bar(2, color(maroon)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
blabel(bar, position(top) color(black) format(%4.1f) size(vsmall))
graph export "${final_figure}${slash}figure_28.png" , replace 

* Figure 29: Water Management Practices of Plots in the Boro Season in 2024.

use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household18=cond(h1_sl == 99, 0, 1)
collapse (first) hh_type , by(a01)
tempfile bihs2018boro
save `bihs2018boro', replace

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta"
keep a1division divisionname a1district a1upazila a1union a1village a1hhid_combined a01combined_18 a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1plot_fishing b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b2crop b2crop_season b5* hhweight_24 agri_control_household
rename a01combined_18 a01
destring a01 , replace 
merge m:1 a01 using "`bihs2018boro'" , nogenerate keep(3)

gen AWD_base = 1 if agri_control_household == 1 & inlist(b2crop_season,1) & inlist(b2crop,9,10,11) & b5mainwater_source != 1 & b5pump_type != 1 

* Total rural HHs: 5554 
* Total HHs that made an agri decision: 2729 
* Total HHs that are Boro paddy irrigating: 1675  
* 30.16% HHs fall in this cateogry - when applied weights it becomes 29.

keep if agri_control_household == 1 //only households doing agriculture 
keep if b1_boro24_utilize == 1 // in boro 2024
keep if inlist(b2crop_season,1) //only retaining this current boro season
keep if inlist(b2crop,9,10,11) //only retaining boro rice 
drop if b5mainwater_source == 1 // (1,243 observations deleted - drop rain dependent
drop if b5pump_type == 1 // 164 observations deleted
replace b5water_management = 1 if b5water_management == 2 & b5ndry_this_season == 0 // those who said  

gen FTF = 0 if hh_type == 3
replace FTF = 1 if hh_type == 2

gen AWD = 1 if b5water_management == 2 // As of the old definition. 
replace  AWD = 0 if AWD == .

tempfile awd
save "`awd'"

gen AWD_1cycle = 0
replace AWD_1cycle = 1 if b5water_management == 2 & b5ndry_this_season == 1  & b5duration_dry >= 5

gen AWD_1cycle_under5 = 0
replace AWD_1cycle_under5 = 1 if b5water_management == 2 & b5ndry_this_season == 1  & b5duration_dry < 5

gen AWD_2cycles = 0
replace AWD_2cycles = 1 if b5water_management == 2 & b5ndry_this_season >= 2 & b5duration_dry >= 5

gen AWD_2cycles_under5 = 0
replace AWD_2cycles_under5 = 1 if b5water_management == 2 & b5ndry_this_season >= 2 & b5duration_dry < 5

tab b5water_management , gen(water_manage)

keep a1hhid_combined b1plot_num b5water_management hhweight_24 hh_type agri_control_household a1hhid_plotnum AWD ///
AWD_1cycle AWD_1cycle_under5 AWD_2cycles AWD_2cycles_under5 water_manage1 water_manage2 water_manage3

drop water_manage3
rename AWD_1cycle_under5 water_manage3 
rename AWD_1cycle water_manage4 
rename AWD_2cycles water_manage5
rename AWD_2cycles_under5 water_manage6

label var water_manage3 "One drying cycle(under 5)"
label var water_manage4 "One drying cycle"
label var water_manage5 "Atleast 2 drying cycles"
label var water_manage6 "Atleast 2 drying cycles (under 5)"

tempfile awd_updated
save "`awd_updated'"

preserve
collapse (mean) water_manage6 water_manage5 water_manage4 water_manage1 water_manage2 water_manage3 [pweight=hhweight_24]
gen percent = 1 
reshape long water_manage, i(percent) j(type)
replace water_manage = round((water_manage*100),0.1)

drop if type == 6 
replace water_manage = 8.9 if type == 3 

gen management_name = ""
replace management_name = "Water doesn't remain" if type == 1 
replace management_name = "Continuous flooding" if type == 2 
replace management_name = "Drying cycle(s) under 5 days" if type == 3 
replace management_name = "One drying cycle (At least 5 days)" if type == 4 
replace management_name = "Two drying cycles or more (At least 5 days)" if type == 5 

graph hbar (asis) water_manage, over(type, relabel(1 "Water doesn't remain" ///
2 "Continuous flooding" 3 "Drying cycle(s) under 5 days" 4 "One drying cycle (At least 5 days)" ///
5 "Two drying cycles or more (At least 5 days)") label(labsize(vsmall)) gap(30)) ///
	asyvars showyvars ylabel(0(10)50, labsize(small) labcolor (black)) ///
	blabel(bar, format(%4.1f) size(vsmall) color(white) position(inside)) ///
	bar(1, bcolor("dknavy"))bar(2, bcolor("dknavy"))bar(3, bcolor("dknavy")) ///
	bar(4, bcolor("ebblue"))bar(5, bcolor("ebblue")) ///
	ytitle("Percentage of Irrigated Boro Plots", size(small)) /// 
	title("Water Management Practices of Plots in the Boro Season in 2024", size(small)) ///
	ylabel(0(10)80, noticks nogrid angle(0) labsize(vsmall)) ///
	legend(off) ///
	graphregion(color(white)) ///
plotregion(color(white)) 
graph export "${final_figure}${slash}figure_29.png" , replace 
restore

* Figure 30: Duration and frequency of drying cycles on irrigated Boro plots in 2024

use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household18=cond(h1_sl == 99, 0, 1)
collapse (first) hh_type , by(a01)
tempfile bihs2018boro
save `bihs2018boro', replace

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta"
keep a1division divisionname a1district a1upazila a1union a1village a1hhid_combined a01combined_18 a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1plot_fishing b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b2crop b2crop_season b5* hhweight_24 agri_control_household
rename a01combined_18 a01
destring a01 , replace 
merge m:1 a01 using "`bihs2018boro'" , nogenerate keep(3)

gen AWD_base = 1 if agri_control_household == 1 & inlist(b2crop_season,1) & inlist(b2crop,9,10,11) & b5mainwater_source != 1 & b5pump_type != 1 

* Total rural HHs: 5554 
* Total HHs that made an agri decision: 2729 
* Total HHs that are Boro paddy irrigating: 1675  
* 30.16% HHs fall in this cateogry - when applied weights it becomes 29.

keep if agri_control_household == 1 //only households doing agriculture 
keep if b1_boro24_utilize == 1 // in boro 2024
keep if inlist(b2crop_season,1) //only retaining this current boro season
keep if inlist(b2crop,9,10,11) //only retaining boro rice 
drop if b5mainwater_source == 1 // (1,243 observations deleted - drop rain dependent
drop if b5pump_type == 1 // 164 observations deleted
replace b5water_management = 1 if b5water_management == 2 & b5ndry_this_season == 0 // those who said  

gen FTF = 0 if hh_type == 3
replace FTF = 1 if hh_type == 2

gen AWD = 1 if b5water_management == 2 // As of the old definition. 
replace  AWD = 0 if AWD == .

tempfile awd
save "`awd'"

use "`awd'" , clear 
keep if b5water_management == 2 
contract b5duration_dry b5ndry_this_season 
replace b5duration_dry = . if b5duration_dry > 30 //when the files were re-run to make the final dataset there was an errorneous entry of 200 days that skwes the graph

* 2D Scatter Plot with Jittering
twoway scatter b5ndry_this_season b5duration_dry [fw=_freq], msize(small) mcolor(navy) ///
legend(off) ytitle("Duration of Drying (Days)" , size(small)) xtitle("Number of Drying Cycles" , size(small)) ///
ylabel(0(2)16, noticks angle(0) labsize(small)) ///
xlabel(0(2)30, noticks angle(0) labsize(small)) ///
title("Duration and Frequency of Drying Cycles on Irrigated Boro Plots in 2024" , size(small)) ///
graphregion(color(white)) ///
plotregion(color(white)) /// 
yline(5, lcolor(black) lwidth(thin)) ///
xline(1, lcolor(black) lwidth(thin))
graph export "${final_figure}${slash}figure_30.png" , replace 


* Figure 31: Divisional Distribution of AWD Practice and Water Shortage on Boro plots in 2024

use "`awd'", clear 
collapse (max) b5ndry_this_season (max) AWD b5awd_use b5duration_1stdrying b5duration_dry (first) divisionname FTF  hhweight_24, by(a1hhid_plotnum) 

gen AWD_legit = 0 
replace AWD_legit = 1 if AWD == 1 & b5ndry_this_season > = 1 & b5duration_dry > = 5

collapse (mean) AWD_legit [pweight=hhweight_24], by(divisionname)
replace AWD_legit = round(100*(AWD_legit),0.1)

sort divisionname
order divisionname AWD AWD_legit

preserve 
use "`awd'" , clear 

collapse (max) b5p3years_shortage (first) divisionname FTF hhweight_24, by(a1hhid_plotnum)
collapse (mean) b5p3years_shortage [pweight=hhweight_24], by(divisionname)

replace b5p3years_shortage = 100*(b5p3years_shortage)
replace b5p3years_shortage = round(b5p3years_shortage,0.1)
keep divisionname b5p3years_shortage

tempfile AWD_water
save "`AWD_water'"
restore 

merge 1:1 divisionname using "`AWD_water'" , nogenerate keep(3)
replace b5p3years_shortage = round(b5p3years_shortage,0.1)

graph bar AWD_legit b5p3years_shortage, over(divisionname, sort(AWD_legit) label(labsize(vsmall)) gap(30)) ///
ytitle("Percent of Irrigated Boro Rice Plots", size(small)) /// 
title("Divisional Variation in Drying Practice and Water Shortage of Irrigated Boro Rice Plots in 2024" , size(small)) ///
ylabel(, noticks nogrid angle(0) labsize(small)) ///
bar(1, color(dknavy)) ///
bar(2, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
legend(order(1 "Plots Practicing 1 Drying Cycle with 5 Drying Days" 2 "Plots Reporting Water Shortage") col(2) pos(6) size(small)) ///
blabel(bar, position(top) color(black) format(%4.1f) size(vsmall)) 
graph export "${final_figure}${slash}figure_31.png" , replace 

graph bar AWD_legit, over(divisionname, sort(divisionname) label(labsize(vsmall)) gap(30)) ///
ytitle("Percent of Irrigated Boro Rice Plots", size(small)) /// 
title("Divisional Distribution of AWD Practice on Irrigated Boro Rice Plots in 2024" , size(small)) ///
ylabel(0(5)30, noticks nogrid angle(0) labsize(small)) ///
bar(1, color(dknavy)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
legend(off) ///
blabel(bar, position(top) color(black) format(%4.1f) size(vsmall)) 
graph save "${final_figure}${slash}temporary_graphs${slash}gi.gph", replace
* note("Note: Total agricultural households irrigating in 2024 are 2374. These percentages are out of the total irrigating HHs in the division.", size(vsmall))

// water scarcity 
use "`awd'" , clear 

gen AWD_legit = 0 
replace AWD_legit = 1 if AWD == 1 & b5ndry_this_season > = 1 & b5duration_dry > = 5

keep if AWD_legit == 1 

collapse (max) b5p3years_shortage AWD_legit (first) divisionname FTF hhweight_24, by(a1hhid_plotnum)
collapse (mean) b5p3years_shortage AWD_legit [pweight=hhweight_24], by(divisionname)

replace AWD_legit = round(100*(AWD_legit),0.1)
replace b5p3years_shortage = 100*(b5p3years_shortage)
replace b5p3years_shortage = round(b5p3years_shortage,0.1)

graph bar b5p3years_shortage,over(divisionname, sort(divisionname) label(labsize(vsmall))) ///
ytitle("Percentage of plots drying atleast once for 5 days", size(small)) /// 
title("Divisional Distribution of Water Shortage on Plots doing AWD in 2024" , size(small)) ///
ylabel(0(10)60, noticks nogrid angle(0) labsize(small)) ///
bar(1, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
blabel(bar, position(top) color(black) format(%4.1f) size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gj.gph", replace


graph combine "${final_figure}${slash}temporary_graphs${slash}gi.gph" "${final_figure}${slash}temporary_graphs${slash}gj.gph", ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}figure_31.png", replace as(png)
* note("Note: This includes HHs that used AWD as drying mechanism for the boro season in a division.", size(vsmall))

* Figure 32: Usage of CGIAR-Related Mobile Applications in BIHS 2024
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
collapse (first) agri_control_household , by(a1hhid_combined)
keep if agri_control_household == 1 
tempfile agrihh
save `agrihh', replace

use  "${final_data}${slash}SPIA_BIHS_2024_module_g.dta" , clear 
keep if g1smartphone == 1 
keep if g1hh_internet == 1 
merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) keepusing(hhweight_24) nogenerate
merge m:1 a1hhid_combined using "`agrihh'" , keep(3) nogenerate //1588 agricultral HHs with smartphone

collapse (sum) g1have_apps , by(g1heard_apps_name)
replace g1have_apps = round(100*(g1have_apps/1588),0.1)

drop if inlist(g1heard_apps_name,"Other mobile banking apps" ,"Other apps for buying and selling crops besides the ones mentioned" ) 

graph hbar g1have_apps , ///
over(g1heard_apps_name, sort(g1have_apps) descending relabel(1 "Bkash" 2 "DFS" 3 "MacherGari" ///
4 "Nagad" 5 "Others" 6 "PANI" 7 "RCM" 8 "RightHaat" 9 "Rocket" 10 "Upay") label(labsize(small))) ///
ylabel(0 "0" 5 "5" 10 "10%" 15 "15%" 20 "20%"25 "25%" 30 "30%", noticks nogrid angle(0) labsize(small)) ///
ytitle("Percentage of Agricultural Households" , size(small)) ///
graphregion(color(white)) ///
title("Usage of Mobile Applications") ///
blabel(bar, color(black) position(top) format(%4.1f)) /// 
bar(1, fcolor(dknavy) lwidth(none)) bar(2, fcolor(maroon) lwidth(none)) 
graph export "${final_figure}${slash}figure_32.png" , replace 
*note("Note: Total Agri HHs with a smartphone/internet are 1588. RCM = Rice crop manager; DFS = Digital feed supply") 
	
	
* Table 22: Reach estimates for Alternate Wetting and Drying Practice
* NOTE ALL INDIVIDUAL REACH NUMBER TABLES CAN BE FOUND IN TABLE (). 

}
******************************************************************************** 
**# Section 6.4 FARM MECHANIZATION *** 
********************************************************************************
{
* Figure 33: Agricultural Technology Adoption Trends Over Time 2015-2024
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate
keep a1hhid_combined a1hhid_plotnum a01combined_15 a01combined_18 b1plot_num b1repeat_count b1agri_activities ///
b5* b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1plot_status ///
b1_boro23_utilize a1division divisionname a1district a1upazila a1village b1plotsize_decimal hhweight_24

unique(a1hhid_combined) // 5554

gen agri = 1 if b1repeat_count > 0 
keep if agri == 1 
keep if b1agri_activities == 1 

drop if b5mainwater_source == 1 

gen AFP = 0 
replace AFP = 1 if b5pump_type == 8

tab b5mainwater_source , gen(water_source)
tab b5alter_water_source , gen(alter_water_source)
 
rename a01combined_18 a01
rename b1plot_num plotid_h1
destring a01 , replace 
gen surface_water = 0 
replace surface_water = 1 if inlist(b5mainwater_source,2,3,4) | inlist(b5alter_water_source,2,3,4)

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) AFP agri surface_water (first) b1plot_status b1plotsize_decimal ///
b5relative_height a1division divisionname a1district a1upazila a01combined_15  ///
a1village a01 b1repeat_count a1hhid_plotnum b1agri_activities ///
b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1_boro23_utilize water_source* alter_water_source* ///
b5alter_water_source b5pump_type b5pump_owned hhweight_24, by(a1hhid_combined plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}

collapse (max) AFP agri hhweight_24 (first) a1village , by(a1hhid_combined)
preserve 
collapse (mean) AFP [pweight= hhweight_24] 
replace AFP = round(AFP*100,0.1) //12.6
restore 

collapse (max) AFP agri hhweight_24, by(a1village)
collapse (mean) AFP [pweight= hhweight_24] 
replace AFP = round(AFP*100,0.1) //12.6

use "${bihs2018}${slash}021_bihs_r3_male_mod_h1" , clear
keep a01 hh_type
duplicates drop 
tostring a01, replace
tempfile 2018 
save "`2018'"

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate
keep divisionname districtname upazilaname a1hhid_combined a01combined_18 hhweight_24 agri_control_household
rename a01combined_18 a01
duplicates drop 
merge m:1 a01 using "`2018'"
keep if _merge == 3 
drop _merge

tempfile a1
save "`a1'"

use "${final_data}${slash}SPIA_BIHS_2024_module_d1_machinery.dta", replace
merge m:1 a1hhid_combined using "`a1'"
drop if _merge == 2

replace d1cgiartech_name = "Power Tiller" if d1cgiartech_name == "Power Tiller Operated Seeder - 2 wheeler"
replace d1cgiartech_name = "Tractor" if d1cgiartech_name == "Power Tiller Operated Seeder - 4 wheeler"
replace d1cgiartech_name = "Reaper" if d1cgiartech_name == "Two wheeled mechanical Reaper for Rice/Wheat/Jute"
drop if d1cgiartech_name == "Alternate Wetting and Drying "

replace d1cgiartech_usage = 0 if d1cgiartech_usage == . 

gen d1cgiartech_rent = 1 if d1cgiartech_owner == 0 
order d1cgiartech_rent, after(d1cgiartech_owner)

foreach v of var * {
local l`v' : variable label `v'
 if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) d1cgiartech_usage [pweight=hhweight_24], by(d1cgiartech_name)

replace d1cgiartech_usage = round((d1cgiartech_usage*100),0.1)
format  d1cgiartech_usage %3.2f
gen year = 2024

tempfile bihs2024
save `bihs2024', replace

** Usage across years ** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) hh_type, by(a01)
merge 1:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
keep if agri_control_household == 1 
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}037_bihs_r3_male_mod_i5.dta", clear
keep if inlist(i5_01, 26,27,28,32,34,41,33,43,44) 
keep a01 i5_01 i5_17 i5_02 i5_18 hh_type

merge m:1 a01 using "`bihs2018boro'" , keep(3) nogenerate 

rename i5_17 d1cgiartech_know
rename i5_02 d1cgiartech_usage

* make a new variable which is the name of the crop 
decode i5_01 ,generate(d1cgiartech_name)
label var d1cgiartech_name "Technology name"

replace d1cgiartech_name = "Power Tiller" if d1cgiartech_name == "Two wheel tractor (Power tiller)"
replace d1cgiartech_name = "Tractor" if d1cgiartech_name == "Four wheel Tractor"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Combined harvester"
replace d1cgiartech_name = "Reaper" if d1cgiartech_name == "Reapers"
replace d1cgiartech_name = "Axial Flow Pump" if d1cgiartech_name == "Axial flow pump/(jumbo pump)"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Power thresher" 

replace d1cgiartech_usage = 0 if d1cgiartech_usage == 2 

foreach v of var * {
local l`v' : variable label `v'
 if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) d1cgiartech_usage [pweight=hhweight] , by(d1cgiartech_name)
replace d1cgiartech_usage = d1cgiartech_usage*100 
replace d1cgiartech_usage = round(d1cgiartech_usage,.1)

format  d1cgiartech_usage %3.2f
gen year = 2018

drop if inlist(d1cgiartech_name,"Paddle thresher","Closed drum thresher","Open drum thresher") 

tempfile bihs2018
save `bihs2018', replace

* 2015 
use "${bihs2015}${slash}015_r2_mod_h1_male", clear
drop if hh_type == 1
gen agri_control_household = cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household, by(a01)
merge 1:1 a01 using "${bihs2015}${slash}BIHS FTF 2015 survey sampling weights.dta" , keep(3) nogen keepusing(hhweight hh_type)

keep if agri_control_household == 1 
tempfile bihs2015boro
save `bihs2015boro', replace

use "${bihs2015}${slash}030_r2_mod_i5_male.dta", clear
drop if hh_type == 1 
keep if inlist(i5_01, 26,27,28,32,33,34) 
keep a01 i5_01 i5_02 
rename i5_02 d1cgiartech_usage

merge m:1 a01 using "`bihs2015boro'" , keep(3) nogenerate 

* make a new variable which is the name of the technology
decode i5_01 ,generate(d1cgiartech_name)
label var d1cgiartech_name "Technology name"

replace d1cgiartech_name = "Power Tiller" if d1cgiartech_name == "Two wheel tractor (Power tiller)"
replace d1cgiartech_name = "Tractor" if d1cgiartech_name == "Four wheel Tractor"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Combined harvester"
replace d1cgiartech_name = "Reaper" if d1cgiartech_name == "Reapers"
replace d1cgiartech_name = "Axial Flow Pump" if d1cgiartech_name == "Axial flow pump (Jumbo pump)"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Power thresher"
replace d1cgiartech_usage = 0 if d1cgiartech_usage == 2 

collapse (mean) d1cgiartech_usage [pweight=hhweight] , by(d1cgiartech_name)
replace d1cgiartech_usage = d1cgiartech_usage*100 
replace d1cgiartech_usage = round(d1cgiartech_usage,.1)
format  d1cgiartech_usage %3.2f
gen year = 2015

tempfile bihs2015
save `bihs2015', replace

append using `bihs2018' 
append using `bihs2024' 

sort d1cgiartech_name year
order  year d1cgiartech_name d1cgiartech_usage 

gen d1cgiartech_usage_AFP = d1cgiartech_usage if d1cgiartech_name == "Axial Flow Pump"
gen d1cgiartech_usage_CH = d1cgiartech_usage if d1cgiartech_name == "Combine Harvester/Thresher"
gen d1cgiartech_usage_PT2 = d1cgiartech_usage if d1cgiartech_name == "Power Tiller"
gen d1cgiartech_usage_RE = d1cgiartech_usage if d1cgiartech_name == "Reaper"
gen d1cgiartech_usage_PT4 = d1cgiartech_usage if d1cgiartech_name == "Tractor"
replace d1cgiartech_name = "4-wheeled Power Tiller" if d1cgiartech_name == "Tractor"
replace d1cgiartech_name = "2-wheeled Power Tiller" if d1cgiartech_name == "Power Tiller"

foreach x in AFP CH PT2 PT4 RE {
replace d1cgiartech_usage_`x' = round(d1cgiartech_usage_`x', 0.1)
}

replace d1cgiartech_usage_AFP = 12.6 if year == 2024 & d1cgiartech_name == "Axial Flow Pump"
replace d1cgiartech_usage = 12.6 if year == 2024 & d1cgiartech_name == "Axial Flow Pump" //making it consistent with module B5 - since it is a smaller estimate and at the plot level 


twoway (connected d1cgiartech_usage_PT2 year, lcolor(dknavy) mcolor(dknavy) mlabel(d1cgiartech_usage_PT2) mlabcolor(dknavy) mlabsize(vsmall) mlabposition(8)) ///
       (connected d1cgiartech_usage_PT4 year, lcolor(maroon) mcolor(maroon) mlabel(d1cgiartech_usage_PT4) mlabcolor(maroon) mlabsize(vsmall) mlabposition(7)) ///
	   (connected d1cgiartech_usage_AFP year, lcolor(ebblue) mcolor(ebblue) mlabel(d1cgiartech_usage_AFP)  lwidth(mediumthick) mlabcolor(ebblue) mlabsize(vsmall) mlabposition(12)) ///
	   (connected d1cgiartech_usage_RE year, lcolor(brown) mcolor(brown) mlabel(d1cgiartech_usage_RE) mlabcolor(brown) mlabsize(vsmall) mlabposition(8)) , ///
       scheme(s1color) xlabel(, nogrid) ylabel(, nogrid labsize(small)) xtitle("") ytitle("Percentage of Agricultural HHs" , size(small)) ///
	   legend(order(1 "2-wheeled Power Tiller" 2 "4-wheeled Power Tiller" ///
	    3 "Axial Flow Pump" 4 "Mechanical Reaper") region(lcolor(white)) pos(6) col(2) size(vsmall))  ///  
	   title("Technology Adoption Trends Over Time(2015-2024)" ,size(small))  ///
	   note("Note: Agricultral households in 2024 are 2729, 2018 are 2937, and 2015 are 2768. This excludes aquaculture HHs.", size(vsmall))
graph export "${final_figure}${slash}figure_33.png", replace as(png)	

* Figure 35: Axial Flow Pump Usage Over Time (2015-2024), National
preserve
format  d1cgiartech_usage %3.1f
keep if d1cgiartech_name == "Axial Flow Pump"
twoway connected d1cgiartech_usage year , ///
ytitle("Percentage of Agricultural Households", size(small)) /// 
ylabel(0(5)25, noticks nogrid angle(0) labsize(small))  ///
lcolor(dknavy) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
mlabel(d1cgiartech_usage) mlabcolor(dknavy) ms() mcolor(dknavy) mlabposition(11) ///
title("Axial Flow Pump Use Over Time(2015-2024)" ,size(small))
graph export "${final_figure}${slash}figure_35.png", replace as(png)	
* note("Note: Agricultral households in 2024 are 2729, 2018 are 2937, and 2015 are 2768. This excludes aquaculture HHs." , size(vsmall))
restore 

* Figure 36: Axial Flow Pump Usage in Barisal and Chittagong vs Other Divisions in Bangladesh
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate
keep a1hhid_combined a1hhid_plotnum a01combined_15 a01combined_18 b1plot_num b1repeat_count b1agri_activities ///
b5* b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1plot_status ///
b1_boro23_utilize a1division divisionname a1district a1upazila a1village b1plotsize_decimal hhweight_24

unique(a1hhid_combined) // 5554

* agricultural HHs 
gen agri = 1 if b1repeat_count > 0 
keep if agri == 1 
keep if b1agri_activities == 1 

drop if b5mainwater_source == 1 

gen AFP = 0 
replace AFP = 1 if b5pump_type == 8

unique(a1hhid_combined) if AFP == 1 //358

tab b5mainwater_source , gen(water_source)
tab b5alter_water_source , gen(alter_water_source)
tab b5pump_type , gen(pump_type)

rename a01combined_18 a01
rename b1plot_num plotid_h1
destring a01 , replace 
gen surface_water = 1 if water_source3 == 1 | water_source4 == 1 | water_source5 == 1 | ///
alter_water_source5 == 1 | alter_water_source6 == 1 | alter_water_source4 == 1 

gen surface_water_check = 1 if inlist(b5mainwater_source,2,3,4) | inlist(b5alter_water_source,2,3,4)
drop surface_water_check


foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) AFP agri surface_water (first) b1plotsize_decimal b5relative_height a1division divisionname a1district a1upazila ///
a01 b1repeat_count a1hhid_plotnum b1agri_activities  water_source* alter_water_source* pump_type* ///
b5alter_water_source b5pump_type b5pump_owned hhweight_24, by(a1hhid_combined plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}

preserve 
use  "${bihs2018}${slash}021_bihs_r3_male_mod_h1" , clear 
keep a01 hh_type
duplicates drop 
tempfile ftf
save "`ftf'"
restore 

merge m:1 a01 using "`ftf'" , keepusing(hh_type) nogenerate keep(1 3)

gen FTF = 0  
replace  FTF = 1 if hh_type == 2 

tempfile 2024
save `2024', replace

use "`2024'" , clear 

gen Division_dissem = 0
replace Division_dissem = 1 if inlist(divisionname,"Barisal","Chittagong") 

collapse (max) AFP (first) FTF divisionname Division_dissem agri hhweight_24, by(a1hhid_combined)
collapse (mean) AFP [pweight=hhweight_24] , by(Division_dissem)
gen pct_AFP = round(100*(AFP), 0.1)
gen year = 2024
order year Division_dissem AFP pct_AFP

tempfile AFP2024
save `AFP2024', replace

** 2018 ** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid_h1 crop_a_h1)
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}009_bihs_r3_male_mod_a.dta", clear
keep a01 div div_name
tempfile bihs2018a
save `bihs2018a', replace

use "${bihs2018}${slash}022_bihs_r3_male_mod_h2" , clear
rename plotid_h2 plotid_h1
rename crop_a_h2 crop_a_h1

merge m:1 a01 plotid_h1 crop_a_h1 using "`bihs2018boro'" , nogenerate
merge m:1 a01 using "`bihs2018a'" , nogenerate

order agri_control_household h1_season , after(plotid_h1)

tabulate h2_02, generate(pump_type_18_)
tabulate h2_01, generate(water_source_18_)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if agri_control_household == 1
drop if h2_01 == 1 

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
} 
}

collapse (first)div_name div agri_control_household hh_type (max) pump_type_18_* water_source_18_*, by(a01 plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}
 
gen FTF = 0 
replace FTF = 1 if hh_type == 2 

gen AFP = 1 if pump_type_18_12 == 1 

keep a01 plotid_h1 FTF AFP agri_control_household div_name div
rename agri_control_household agri 

merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)

gen Division_dissem = 0
replace Division_dissem = 1 if inlist(div_name,"Barisal","Chittagong") 

collapse (max) AFP (first) FTF agri hhweight Division_dissem  div_name, by(a01)
replace AFP = 0 if AFP == . 
collapse (mean) AFP [pweight=hhweight] , by(Division_dissem)
gen year = 2018
gen pct_AFP = round(100*(AFP), 0.1)
order year Division_dissem AFP pct_AFP

tempfile AFP2018
save `AFP2018', replace 

** 2015 ** 
use "${bihs2015}${slash}015_r2_mod_h1_male", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid crop_a)
tempfile bihs2015
save `bihs2015', replace 

use "${bihs2015}${slash}001_r2_mod_a_male.dta", clear
keep a01 div div_name
tempfile bihs2015a
save `bihs2015a', replace

use "${bihs2015}${slash}016_r2_mod_h2_male.dta" , clear

merge m:1 a01 plotid crop_a using "`bihs2015'" , nogenerate
merge m:1 a01 using "`bihs2015a'" , nogenerate
order agri_control_household h1_season hh_type , after(plotid)

tabulate h2_02, generate(pump_type_15_)
tabulate h2_01, generate(water_source_15_)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if agri_control_household == 1

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

// unique(a01 plotid_h1) if pump_type_15_12 == 1 is 29 (Plots with AFP) and HHs are 15
collapse (first)div_name div  agri_control_household hh_type (max) pump_type_15_* water_source_15_*, by(a01 plotid)

foreach v of var * {
label var `v' `"`l`v''"'
}
 
gen FTF = 0 
replace FTF = 1 if hh_type == 2 

gen AFP = 1 if pump_type_15_12 == 1 

keep a01 plotid FTF AFP agri_control_household div_name div 
rename agri_control_household agri 

merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)

gen Division_dissem = 0
replace Division_dissem = 1 if inlist(div_name,"Barisal","Chittagong") 

collapse (max) AFP (first) FTF agri hhweight div_name Division_dissem div , by(a01)
replace AFP = 0 if AFP == . 
collapse (mean) AFP [pweight=hhweight] , by(Division_dissem)
gen year = 2015
gen pct_AFP = round(100*(AFP), 0.1)
order year Division_dissem AFP pct_AFP

append using "`AFP2018'"
append using "`AFP2024'"

gen pct_AFP_DIV = pct_AFP if Division_dissem == 1 
gen pct_AFP_NO_DIV = pct_AFP if Division_dissem == 0 

gen pct_AFP_DIV_label = string(pct_AFP_DIV, "%9.2f")
gen pct_AFP_NO_DIV_label = string(pct_AFP_NO_DIV, "%9.2f")

twoway (connected pct_AFP_DIV year, lcolor(dknavy) mcolor(dknavy) ///
mlabel(pct_AFP_DIV_label) mlabcolor(dknavy) mlabsize(tiny) mlabposition(6) ) ///
       (connected pct_AFP_NO_DIV year, lcolor(ebblue) mcolor(ebblue) ///
mlabel(pct_AFP_NO_DIV_label) mlabcolor(ebblue) mlabsize(tiny) mlabposition(12)), ///
legend(order(1 "Barisal/Chittagong"  2 "Other divisions") position(6) col(2)) ///
ytitle("Percentage of Agricultural HH with Irrigated Lands", size(small)) /// 
xtitle("Year", size(small)) ///
title("Axial Flow Pump Usage (Barisal/Chittagong vs Other Divisions)")  ///
ylabel(0(5)40, noticks nogrid angle(0) labsize(small)) ///
graphregion(color(white)) ///
plotregion(color(white))
graph export "${final_figure}${slash}figure_36.png", replace as(png)	
* note("Note: Total agricultural households with atleast one irrigated land in 2015 are 3384, 2018 are 2937 and 2024 are 2512" "Other divisions include Rangpur,Sylhet,Khulna,Dhaka,Rajshahi", size(vsmall))

* Figure 37: Axial Flow Pump Adoption by Division (2024 vs 2018)
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate
keep a1hhid_combined a1hhid_plotnum a01combined_15 a01combined_18 b1plot_num b1repeat_count b1agri_activities ///
b5* b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1plot_status ///
b1_boro23_utilize a1division divisionname a1district a1upazila a1village b1plotsize_decimal hhweight_24

unique(a1hhid_combined) // 5554

* agricultural HHs 
gen agri = 1 if b1repeat_count > 0 
keep if agri == 1 
keep if b1agri_activities == 1 

drop if b5mainwater_source == 1 
drop if b5pump_type == 1 

gen AFP = 0 
replace AFP = 1 if b5pump_type == 8

tab b5mainwater_source , gen(water_source)
tab b5alter_water_source , gen(alter_water_source)
 
rename a01combined_18 a01
rename b1plot_num plotid_h1
destring a01 , replace 
gen surface_water = 0 
replace surface_water = 1 if inlist(b5mainwater_source,2,3,4) | inlist(b5alter_water_source,2,3,4)

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) AFP agri surface_water (first) b1plot_status b1plotsize_decimal ///
b5relative_height a1division divisionname a1district a1upazila a01combined_15  ///
a1village a01 b1repeat_count a1hhid_plotnum b1agri_activities ///
b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1_boro23_utilize water_source* alter_water_source* ///
b5alter_water_source b5pump_type b5pump_owned hhweight_24, by(a1hhid_combined plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}


foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) AFP agri surface_water (first) b1plot_status b1plotsize_decimal ///
b5relative_height a1division divisionname a1district a1upazila a01combined_15  ///
a1village a01 b1repeat_count a1hhid_plotnum b1agri_activities ///
b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1_boro23_utilize water_source* alter_water_source* ///
b5alter_water_source b5pump_type b5pump_owned hhweight_24, by(a1hhid_combined)

foreach v of var * {
label var `v' `"`l`v''"'
}

tempfile 2024_B5
save `2024_B5', replace 

**** First process the 2018 dataset for all comparative graphs ***** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid_h1 crop_a_h1)
tempfile bihs2018h1
save `bihs2018h1', replace

use "${bihs2018}${slash}009_bihs_r3_male_mod_a.dta", clear
keep a01 div div_name
tempfile bihs2018a
save `bihs2018a', replace

use "${bihs2018}${slash}022_bihs_r3_male_mod_h2" , clear
rename plotid_h2 plotid_h1
rename crop_a_h2 crop_a_h1

merge m:1 a01 plotid_h1 crop_a_h1 using "`bihs2018h1'" , nogenerate
merge m:1 a01 using "`bihs2018a'" , nogenerate keep(3)

order agri_control_household h1_season div div_name, after(plotid_h1)

tabulate h2_02, generate(pump_type_18_)
tabulate h2_01, generate(water_source_18_)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if agri_control_household == 1 
drop if h2_01 == 1 
drop if h2_02 == 1 

merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first) div div_name agri_control_household hhweight (max) pump_type_18_* water_source_18_* hh_type, by(a01 plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}


foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first) hhweight div div_name agri_control_household (max) pump_type_18_* water_source_18_* hh_type, by(a01)

foreach v of var * {
label var `v' `"`l`v''"'
}


gen pump_type_18_14 = 1 if pump_type_18_2== 1 | pump_type_18_3 == 1 | pump_type_18_4 == 1 | pump_type_18_5 == 1 | /// 
pump_type_18_6 == 1 | pump_type_18_7 == 1 | pump_type_18_13 == 1
label var pump_type_18_14 "Other(Less than 1% individually)"
drop pump_type_18_2 pump_type_18_3 pump_type_18_4 pump_type_18_5 pump_type_18_6 pump_type_18_7 pump_type_18_13

replace water_source_18_4 = 1 if water_source_18_4 == 1 | water_source_18_5 == 1 
replace water_source_18_3 = 1 if water_source_18_3 == 1 | water_source_18_6 == 1 
drop water_source_18_5 water_source_18_6
label var water_source_18_4 "Pond/Lake"
label var water_source_18_3 "Canal"

gen AFP = 0 
replace  AFP = 1 if pump_type_18_12 == 1 

tempfile 2018_B5 // earlier bihs2018boro
save `2018_B5', replace 

collapse (mean) AFP [pweight=hhweight] , by(div_name)
gen AFP_pct = round(AFP*100, 0.1)
rename div_name divisionname
gen year = 2018

tempfile 2018_AFP // earlier bihs2018boro
save `2018_AFP', replace 

use "`2024_B5'" , clear 
collapse (mean) AFP [pweight=hhweight_24] , by(divisionname)
gen AFP_pct = round(AFP*100, 0.1)
gen year = 2024 

append using "`2018_AFP'"
gen AFP_pct_24 = AFP_pct if year == 2024
gen AFP_pct_18 = AFP_pct if year == 2018
keep divisionname AFP_pct_24 AFP_pct_18
duplicates drop 

graph bar AFP_pct_18 AFP_pct_24 ,over(divisionname, sort(AFP_pct_24)) ///
ytitle("Percent of Agriculturally Active Households", size(small)) /// 
title("AFP Adoption by Division (2024 vs 2018)" , size(small)) ///
ylabel(, noticks nogrid angle(0) labsize(small)) ///
bar(1, color(ebblue)) ///
bar(2, color(dknavy)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
legend(order(1 "2018" 2 "2024") region(lcolor(white)) pos(6) col(2)) ///
blabel(bar, position(inside) color(white) format(%4.1f) size(small)) 
graph export "${final_figure}${slash}figure_37.png" , replace 	
* note("Note: Total agricultural households with atleast one irrigated land in 2018 are 2937 and 2024 are 2512", size(vsmall))


* Figure 38: Axial Flow Pump Usage Across Feed the Future and Non-Feed the Future Zones
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate
keep a1hhid_combined a1hhid_plotnum a01combined_15 a01combined_18 b1plot_num b1repeat_count b1agri_activities ///
b5* b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1plot_status ///
b1_boro23_utilize a1division divisionname a1district a1upazila a1village b1plotsize_decimal hhweight_24

unique(a1hhid_combined) // 5554

* agricultural HHs 
gen agri = 1 if b1repeat_count > 0 
keep if agri == 1 
keep if b1agri_activities == 1 

drop if b5mainwater_source == 1 

gen AFP = 0 
replace AFP = 1 if b5pump_type == 8

unique(a1hhid_combined) if AFP == 1 //358

tab b5mainwater_source , gen(water_source)
tab b5alter_water_source , gen(alter_water_source)
tab b5pump_type , gen(pump_type)

rename a01combined_18 a01
rename b1plot_num plotid_h1
destring a01 , replace 
gen surface_water = 1 if water_source3 == 1 | water_source4 == 1 | water_source5 == 1 | ///
alter_water_source5 == 1 | alter_water_source6 == 1 | alter_water_source4 == 1 

gen surface_water_check = 1 if inlist(b5mainwater_source,2,3,4) | inlist(b5alter_water_source,2,3,4)
drop surface_water_check

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) AFP agri surface_water (first) b1plotsize_decimal b5relative_height a1division divisionname a1district a1upazila ///
a01 b1repeat_count a1hhid_plotnum b1agri_activities  water_source* alter_water_source* pump_type* ///
b5alter_water_source b5pump_type b5pump_owned hhweight_24, by(a1hhid_combined plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}

preserve 
use  "${bihs2018}${slash}021_bihs_r3_male_mod_h1" , clear 
keep a01 hh_type
duplicates drop 
tempfile ftf
save "`ftf'"
restore 

merge m:1 a01 using "`ftf'" , keepusing(hh_type) nogenerate keep(1 3)

gen FTF = 0  
replace  FTF = 1 if hh_type == 2 

tempfile 2024
save `2024', replace

collapse (max) AFP (first) FTF agri hhweight_24, by(a1hhid_combined)
collapse (mean) AFP [pweight=hhweight_24] , by(FTF)
gen pct_AFP = round(100*(AFP), 0.1)
gen year = 2024
order year FTF AFP pct_AFP

tempfile AFP2024
save `AFP2024', replace

** 2018 ** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid_h1 crop_a_h1)
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}022_bihs_r3_male_mod_h2" , clear
rename plotid_h2 plotid_h1
rename crop_a_h2 crop_a_h1

merge m:1 a01 plotid_h1 crop_a_h1 using "`bihs2018boro'"
drop _merge
order agri_control_household h1_season , after(plotid_h1)

tabulate h2_02, generate(pump_type_18_)
tabulate h2_01, generate(water_source_18_)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if agri_control_household == 1

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

// unique(a01 plotid_h1) if pump_type_18_12 == 1 is 97 (Plots with AFP) and HHs are 31
collapse (first) agri_control_household hh_type (max) pump_type_18_* water_source_18_*, by(a01 plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}
 
gen FTF = 0 
replace FTF = 1 if hh_type == 2 

gen AFP = 1 if pump_type_18_12 == 1 

keep a01 plotid_h1 FTF AFP agri_control_household
rename agri_control_household agri 

merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)

collapse (max) AFP (first) FTF agri hhweight, by(a01)
replace AFP = 0 if AFP == . 
collapse (mean) AFP [pweight=hhweight] , by(FTF)
gen year = 2018
gen pct_AFP = round(100*(AFP), 0.1)
order year FTF AFP pct_AFP

tempfile AFP2018
save `AFP2018', replace 

** 2015 ** 
use "${bihs2015}${slash}015_r2_mod_h1_male", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid crop_a)
tempfile bihs2015
save `bihs2015', replace

use "${bihs2015}${slash}016_r2_mod_h2_male.dta" , clear

merge m:1 a01 plotid crop_a using "`bihs2015'"
drop _merge
order agri_control_household h1_season hh_type , after(plotid)

tabulate h2_02, generate(pump_type_15_)
tabulate h2_01, generate(water_source_15_)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if agri_control_household == 1

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

// unique(a01 plotid_h1) if pump_type_15_12 == 1 is 29 (Plots with AFP) and HHs are 15
collapse (first) agri_control_household hh_type (max) pump_type_15_* water_source_15_*, by(a01 plotid)

foreach v of var * {
label var `v' `"`l`v''"'
}
 
gen FTF = 0 
replace FTF = 1 if hh_type == 2 

gen AFP = 1 if pump_type_15_12 == 1 

keep a01 plotid FTF AFP agri_control_household
rename agri_control_household agri 

merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)

collapse (max) AFP (first) FTF agri hhweight, by(a01)
replace AFP = 0 if AFP == . 
collapse (mean) AFP [pweight=hhweight] , by(FTF)
gen year = 2015
gen pct_AFP = round(100*(AFP), 0.1)
order year FTF AFP pct_AFP

append using "`AFP2018'"
append using "`AFP2024'"

gen pct_AFP_FTF = pct_AFP if FTF == 1 
gen pct_AFP_NO_FTF = pct_AFP if FTF == 0 

gen AFP_FTF_label = string(pct_AFP_FTF, "%9.2f")
gen AFP_NO_FTF_label = string(pct_AFP_NO_FTF, "%9.2f")

twoway (connected pct_AFP_FTF year, lcolor(dknavy) mcolor(dknavy) ///
mlabel(AFP_FTF_label) mlabcolor(dknavy) mlabsize(tiny) mlabposition(6) ) ///
       (connected pct_AFP_NO_FTF year, lcolor(ebblue) mcolor(ebblue) ///
mlabel(AFP_NO_FTF_label) mlabcolor(ebblue) mlabsize(tiny) mlabposition(12)), ///
legend(order(1 "FTF"  2 "Non-FTF") position(6) col(2)) ///
ytitle("Percentage of Agricultural HH with Irrigated Lands", size(small)) /// 
xtitle("Year", size(small)) ///
title("Axial Flow Pump Usage (FTF vs Non-FTF)")  ///
ylabel(0(5)20, noticks nogrid angle(0) labsize(small)) ///
graphregion(color(white)) ///
plotregion(color(white))
graph export "${final_figure}${slash}figure_38.png", replace as(png)	

* Figure 39: 2-Wheeled Power Tiller Usage Over Time Across Feed the future and Non-Feed the Future Zones (2015-2024)
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1" , clear
keep a01 hh_type
duplicates drop 
tostring a01, replace
tempfile 2018 
save "`2018'"

use "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", replace	
keep a1hhid_combined a01combined_18 hhweight_24
rename a01combined_18 a01
merge m:1 a01 using "`2018'" , keep(3) nogenerate
tempfile a1
save "`a1'"

use "${final_data}${slash}SPIA_BIHS_2024_module_d1_machinery.dta", replace
merge m:1 a1hhid_combined using "`a1'"
drop if _merge == 2 

replace d1cgiartech_name = "Power Tiller" if d1cgiartech_name == "Power Tiller Operated Seeder - 2 wheeler"
replace d1cgiartech_name = "Tractor" if d1cgiartech_name == "Power Tiller Operated Seeder - 4 wheeler"
replace d1cgiartech_name = "Reaper" if d1cgiartech_name == "Two wheeled mechanical Reaper for Rice/Wheat/Jute"
drop if d1cgiartech_name == "Alternate Wetting and Drying "

replace d1cgiartech_usage = 0 if d1cgiartech_usage == . 

gen d1cgiartech_rent = 1 if d1cgiartech_owner == 0 
order d1cgiartech_rent, after(d1cgiartech_owner)

foreach v of var * {
local l`v' : variable label `v'
 if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

gen FTF = 0 
replace  FTF = 1 if hh_type == 2 

collapse (mean) d1cgiartech_usage [pweight=hhweight_24], by(d1cgiartech_name FTF)

replace d1cgiartech_usage = round((d1cgiartech_usage*100),0.1)
format d1cgiartech_usage %3.2f
gen year = 2024
keep d1cgiartech_name FTF d1cgiartech_usage year

tempfile bihs2024
save `bihs2024', replace

** 2018 ** 
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household , by(a01 hh_type)
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}037_bihs_r3_male_mod_i5.dta", clear
keep if inlist(i5_01, 26,27,28,32,34,41) 
keep a01 i5_01 i5_17 i5_02 i5_18 hh_type

rename i5_17 d1cgiartech_know
rename i5_02 d1cgiartech_usage

merge m:1 a01 using `bihs2018boro'
keep if agri_control_household == 1 

* make a new variable which is the name of the crop 
decode i5_01 ,generate(d1cgiartech_name)
label var d1cgiartech_name "Technology name"

replace d1cgiartech_name = "Power Tiller" if d1cgiartech_name == "Two wheel tractor (Power tiller)"
replace d1cgiartech_name = "Tractor" if d1cgiartech_name == "Four wheel Tractor"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Combined harvester"
replace d1cgiartech_name = "Reaper" if d1cgiartech_name == "Reapers"
replace d1cgiartech_name = "Axial Flow Pump" if d1cgiartech_name == "Axial flow pump/(jumbo pump)"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Power thresher"

replace d1cgiartech_usage = 0 if d1cgiartech_usage == 2 
replace d1cgiartech_know = 0 if d1cgiartech_know == 2 

gen d1cgiartech_owner = 0 if d1cgiartech_usage == 1 
replace d1cgiartech_owner = 1 if d1cgiartech_usage == 1  & i5_18 == 2  

gen d1cgiartech_rent = 1 - d1cgiartech_owner
replace d1cgiartech_rent = . if d1cgiartech_usage == 0 
order d1cgiartech_rent, after(d1cgiartech_owner)

merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)

foreach v of var * {
local l`v' : variable label `v'
 if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

gen FTF = 0 
replace  FTF = 1 if hh_type == 2 

keep d1cgiartech_usage hhweight d1cgiartech_name FTF
sort d1cgiartech_name

collapse (mean) d1cgiartech_usage [pweight=hhweight] , by(d1cgiartech_name FTF)
replace d1cgiartech_usage = d1cgiartech_usage*100 
replace d1cgiartech_usage = round(d1cgiartech_usage,.1)
format  d1cgiartech_usage %3.2f
gen year = 2018

drop if inlist(d1cgiartech_name,"Power thresher","Combined harvester") 
keep d1cgiartech_name FTF d1cgiartech_usage year 

tempfile bihs2018
save `bihs2018', replace

* 2015 
use "${bihs2015}${slash}015_r2_mod_h1_male", clear
drop if hh_type == 1
gen agri_control_household = cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household , by(a01 hh_type)
tempfile bihs2015boro
save `bihs2015boro', replace

use "${bihs2015}${slash}030_r2_mod_i5_male.dta", clear
drop if hh_type == 1 
keep if inlist(i5_01, 26,27,28,32,34) 
keep a01 i5_01 i5_02 hh_type 

merge m:1 a01 using `bihs2015boro'
keep if agri_control_household == 1 

rename i5_02 d1cgiartech_usage

* make a new variable which is the name of the crop 
decode i5_01 ,generate(d1cgiartech_name)
label var d1cgiartech_name "Technology name"

replace d1cgiartech_name = "Power Tiller" if d1cgiartech_name == "Two wheel tractor (Power tiller)"
replace d1cgiartech_name = "Tractor" if d1cgiartech_name == "Four wheel Tractor"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Combined harvester"
replace d1cgiartech_name = "Reaper" if d1cgiartech_name == "Reapers"
replace d1cgiartech_name = "Axial Flow Pump" if d1cgiartech_name == "Axial flow pump (Jumbo pump)"
replace d1cgiartech_name = "Combine Harvester/Thresher" if d1cgiartech_name == "Power thresher"

replace d1cgiartech_usage = 0 if d1cgiartech_usage == 2 

foreach v of var * {
local l`v' : variable label `v'
 if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

merge m:1 a01 using "${bihs2015}${slash}BIHS FTF 2015 survey sampling weights" , keep(3) nogen keepusing(hhweight hh_type)

gen FTF = 0 
replace  FTF = 1 if hh_type == 2 

keep d1cgiartech_usage hhweight d1cgiartech_name FTF
sort d1cgiartech_name

collapse (mean) d1cgiartech_usage [pweight=hhweight] , by(d1cgiartech_name FTF)
replace d1cgiartech_usage = d1cgiartech_usage*100 
replace d1cgiartech_usage = round(d1cgiartech_usage,.1)
format  d1cgiartech_usage %3.2f
gen year = 2015

drop if inlist(d1cgiartech_name,"Power thresher","Combined harvester") 
keep d1cgiartech_name FTF d1cgiartech_usage year 

tempfile bihs2015
save `bihs2015', replace

append using `bihs2018' 
append using `bihs2024' 

sort d1cgiartech_name FTF year

gen d1cgiartech_usage_FTF = d1cgiartech_usage if FTF == 1 
gen d1cgiartech_usage_noFTF = d1cgiartech_usage if FTF == 0

keep if d1cgiartech_name == "Power Tiller"
gen d1cgiartech_usage_FTF_label = string(d1cgiartech_usage_FTF, "%9.2f")
gen d1cgiartech_usage_noFTF_label = string(d1cgiartech_usage_noFTF, "%9.2f")

twoway (connected d1cgiartech_usage_FTF year, lcolor(dknavy) mcolor(dknavy) ///
mlabel(d1cgiartech_usage_FTF) mlabcolor(dknavy) mlabsize(vsmall) mlabposition(12 6 12) ) ///
       (connected d1cgiartech_usage_noFTF year, lcolor(ebblue) mcolor(ebblue) ///
mlabel(d1cgiartech_usage_noFTF) mlabcolor(ebblue) mlabsize(vsmall) mlabposition(6)), ///
legend(order(1 "FTF Households"  2 "Non-FTF Households") position(6) col(2) size(small)) ///
ytitle("Percentage of Agricultral Households", size(small)) /// 
title("2-Wheeled Power Tiller Use FTF Zone vs Non-FTF zone(2015-2024)" ,size(small)) ///
ylabel(, noticks nogrid angle(0) labsize(small)) ///
xtitle("") ///
graphregion(color(white)) ///
plotregion(color(white))
graph export "${final_figure}${slash}figure_39.png", replace as(png)
* note("Note: This is the percentage of agricultural households in FTF vs Non-FTF zones that responded yes to using a 2-Wheeled Power Tiller.", size(vsmall))	

* Figure 34: Rented vs Owned Agricultural Technology in 2024
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta"
keep divisionname districtname upazilaname a1hhid_combined a01combined_18 hhweight_24
rename a01combined_18 a01
duplicates drop 
tempfile a1
save "`a1'"

use "${final_data}${slash}SPIA_BIHS_2024_module_d1_machinery.dta", replace
merge m:1 a1hhid_combined using "`a1'"

drop if _merge == 2

replace d1cgiartech_name = "2-wheeled Power Tiller" if d1cgiartech_name == "Power Tiller Operated Seeder - 2 wheeler"
replace d1cgiartech_name = "4-wheeled Power Tiller" if d1cgiartech_name == "Power Tiller Operated Seeder - 4 wheeler"
replace d1cgiartech_name = "Mechanical Reaper" if d1cgiartech_name == "Two wheeled mechanical Reaper for Rice/Wheat/Jute"
drop if d1cgiartech_name == "Alternate Wetting and Drying "

gen d1cgiartech_rent = 1 if d1cgiartech_owner == 0 
order d1cgiartech_rent, after(d1cgiartech_owner)

keep  a1hhid_combined d1cgiartech_id d1cgiartech_name d1cgiartech_know d1cgiartech_usage d1cgiartech_owner d1cgiartech_rent hhweight_24
keep if d1cgiartech_usage == 1 
replace d1cgiartech_rent = 0 if d1cgiartech_rent == . 

foreach v of var * {
local l`v' : variable label `v'
 if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) d1cgiartech_owner d1cgiartech_rent [pweight=hhweight_24], by(d1cgiartech_name)
replace d1cgiartech_owner = (d1cgiartech_owner*100)
replace d1cgiartech_rent = (d1cgiartech_rent*100)

replace d1cgiartech_owner = round(d1cgiartech_owner,0.1)
replace d1cgiartech_rent = round((d1cgiartech_rent),0.1)

format d1cgiartech_owner d1cgiartech_rent %3.2f
drop if d1cgiartech_name == "Combine Harvester/Thresher"

graph hbar d1cgiartech_rent d1cgiartech_owner, over(d1cgiartech_name , sort(d1cgiartech_rent)) stack ///
ytitle("Percentage of Households Adopting Technology", size(vsmall)) /// 
title( "Technology Rented vs Owned" ,size(small)) ///
ylabel(, noticks nogrid angle(0) labsize(small))  ///
bar(1, color(dknavy)) ///
bar(2, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
legend(order(1 "Rented" 2 "Owned") region(lcolor(white)) pos(6) col(2)) ///
blabel(bar, position(center) color(white) format(%4.1f) size(vsmall)) 
graph export "${final_figure}${slash}figure_34.png", replace as(png)

* Table 24: Reach estimates for CGIAR-related mechanization innovations
* NOTE ALL INDIVIDUAL REACH NUMBER TABLES CAN BE FOUND IN TABLE (). 
}	
******************************************************************************** 
**# Section 7. WHO ARE THE ADOPTERS?(COVARIATES) *** 
********************************************************************************
{
** CREATE THE COVARIATE DATASET **  
use "${final_data}${slash}SPIA_BIHS_2024_module_a2_4.dta", clear

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first) a1hhid_combined a1religion a1language a1ethnicity a2literacy a2highest_class a2daily_wage ///
a2secondary_daily_wage a2hhroster_count a2mem_age a2mem_gender a4employment_status ///
a3advice_topic_6 a2primaryres_relation a2migration a2agri_decision_id a2index a2hh_head_id a2mem_id_new a2mem_id , by(a2mem_id_2024)

foreach v of var * {
label var `v' `"`l`v''"'
}

* Merge with b1-6 to get the 2018 id
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" ,  ///
keepusing(a01combined_18 a01combined_15 a01_12) nogenerate keep(3)

* Merge with poverty estimates 
preserve 
use "${prior_data}${slash}BIHS_hh_expenditure_r123.dta" , clear 
keep if round == 3 
keep pc_expm pc_foodxm pc_nonfxm hhsize a01 hh_type
rename a01 a01combined_18
tostring a01combined_18 , replace
tempfile consumption
save "`consumption'"
restore 
merge m:1 a01combined_18 using "`consumption'" , nogenerate keep(3)

tempfile HH_info
save "`HH_info'"

**** HH consumption ****** 
use "`HH_info'" , clear 
collapse (first) pc_expm a1religion (mean) hhsize, by(a1hhid_combined)
xtile con_quintile = pc_expm, nq(5)

gen con_bottom20 = 0 
gen con_bottom40 = 0 
replace con_bottom20 = 1 if con_quintile == 1 
replace con_bottom40 = 1 if inlist(con_quintile,1,2)

gen religion_islam = 0 
replace religion_islam = 1 if a1religion == 1

* HH size 
egen std_hhsize = std(hhsize)

tempfile HH_con
save "`HH_con'"
****** HH head ******** 
* Identify the household head 
use "`HH_info'" , clear 
keep if a2hh_head_id != . 
drop if a2mem_gender == . & a2literacy == . 

gen lit_can_read_write = 0 
replace lit_can_read_write = 1 if a2literacy == 4

gen a4employment_status_d = 0 
replace a4employment_status_d = 1 if inlist(a4employment_status,1,2)

drop a4employment_status 
rename a4employment_status_d a4employment_status

duplicates drop a1hhid_combined , force 

tempfile HH_head
save "`HH_head'"

**** Agricultural head ********
* what is the gender of the person who takes agricultral decisions 
use "`HH_info'" , clear 
gen agri_head = 1 if a2agri_decision_id == a2mem_id_new
replace a2agri_decision_id = . if a2agri_decision_id == -98
keep if agri_head == 1
drop if a2mem_gender == .  
gen a2agri_decision_gender = a2mem_gender

tempfile HH_agri
save "`HH_agri'"

use "`HH_con'" , clear
merge 1:1 a1hhid_combined using "`HH_head'" , nogenerate keep(3)
merge 1:1 a1hhid_combined using "`HH_agri'" , nogenerate keep(1 3)

**** HH assets and savings ********
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a5_6.dta" , ///
nogenerate keep(3) keepusing(a6_hh_savings a5_hh_floor a5_hh_roof a5_hh_toilet a5_hh_drinking_water a6_hh_savings a5_hh_item_1 a5_hh_item_7 a5_hh_item_8 /// 
a5_vehicle_1 a5_vehicle_6 a5_communication_2 a5_agri_equipment_1 a5_agri_equipment_2 a5_hh_item_1 a5_hh_item_2 a5_hh_item_3 a5_hh_item_4 a5_hh_item_5 a5_hh_item_7 ///
a5_hh_item_8 a5_vehicle_1 a5_vehicle_2 a5_vehicle_3 a5_vehicle_4 a5_vehicle_5 a5_vehicle_6 a5_vehicle_7 a5_communication_1 a5_communication_2 a5_communication_3 ///
a5_agri_equipment_* a5_communication_4 a5_communication_5 a5_communication_6 a5_animal_1 a5_animal_2 a5_animal_3 a5_animal_4)

drop a5_agri_equipment_qty* a5_agri_equipment_pc* a5_agri_equipment_yr* a5_agri_equipment__pur_price* a5_agri_equipment__mar_value* a5_agri_equipment__98 a5_agri_equipment_oth

** Process all HH level variables
tab a1religion , gen(a1religion) 
tab a1ethnicity , gen(a1ethnicity)
tab a5_hh_floor , gen(a5_hh_floor)
tab a5_hh_toilet , gen(a5_hh_toilet)
tab a5_hh_roof , gen(a5_hh_roof) 
tab a5_hh_drinking_water , gen(a5_hh_drinking_water) 

gen a5_hh_floor_good = 1 if a5_hh_floor3 == 1 | a5_hh_floor4 == 1

foreach x in ///
a5_hh_toilet1 a5_hh_toilet2 a5_hh_toilet3 a5_hh_toilet4 a5_hh_toilet5 ///
a5_hh_roof1 a5_hh_roof2 a5_hh_roof3 a5_hh_roof4 a5_hh_roof5 a5_hh_roof6 ///
a5_hh_drinking_water1 a5_hh_drinking_water2 a5_hh_drinking_water3 a5_hh_drinking_water4 ///
a5_hh_drinking_water5 a5_hh_drinking_water6 a5_hh_drinking_water7 a5_hh_drinking_water8 ///
a5_hh_floor1 a5_hh_floor2 a5_hh_floor3 a5_hh_floor4 a5_hh_floor5 a5_hh_floor6 ///
a5_hh_item_1 a5_hh_item_2 a5_hh_item_3 a5_hh_item_4 a5_hh_item_5 a5_hh_item_7 a5_hh_item_8 /// 
a5_vehicle_1 a5_vehicle_2 a5_vehicle_3 a5_vehicle_4 a5_vehicle_5 a5_vehicle_6 a5_vehicle_7 /// 
a5_communication_1 a5_communication_2 a5_communication_3 a5_communication_4 a5_communication_5 a5_communication_6 ///
a5_animal_1 a5_animal_2 a5_animal_3 a5_animal_4 {
replace `x' = 0 if `x' == . 	
}

** note for the 4 cateogrical variables - deleted the base category/ or a5_hh_toilet1/a5_hh_roof1/a5_hh_drinking_water1/a5_hh_floor1
pca a5_hh_toilet2 a5_hh_toilet3 a5_hh_toilet4 a5_hh_toilet5 ///
a5_hh_roof2 a5_hh_roof3 a5_hh_roof4 a5_hh_roof5 a5_hh_roof6 ///
a5_hh_drinking_water2 a5_hh_drinking_water3 a5_hh_drinking_water4 ///
a5_hh_drinking_water5 a5_hh_drinking_water6 a5_hh_drinking_water7 a5_hh_drinking_water8 ///
a5_hh_floor2 a5_hh_floor3 a5_hh_floor4 a5_hh_floor5 a5_hh_floor6 ///
a5_hh_item_1 a5_hh_item_2 a5_hh_item_3 a5_hh_item_4 a5_hh_item_5 a5_hh_item_7 a5_hh_item_8 /// 
a5_vehicle_1 a5_vehicle_2 a5_vehicle_3 a5_vehicle_4 a5_vehicle_5 a5_vehicle_6 a5_vehicle_7 /// 
a5_communication_1 a5_communication_2 a5_communication_3 a5_communication_4 a5_communication_5 a5_communication_6 ///
a5_animal_1 a5_animal_2 a5_animal_3 a5_animal_4

predict hh_asset_index
egen std_hh_asset_index = std(hh_asset_index)

* Keep the final variables 
keep std_hh_asset_index religion_islam lit_can_read_write ///
a4employment_status a6_hh_savings a2hhroster_count ///
a2mem_age a2mem_gender a1hhid_combined a2agri_decision_gender ///
pc_expm con_bottom20 con_bottom40 con_quintile

**** CLEAN AND FINALISE VARIABLES ******
* Name the variables 
label var a2hhroster_count "HH size"
label var a2mem_age "HH Head:Age"
label var a2mem_gender "HH Head:Male"
label var a4employment_status "HH Head:Employed"
label var a6_hh_savings "Annual HH Savings"
label var std_hh_asset_index "HH Asset Index(PCA)"
label var a2agri_decision_gender "Agricultural Head:Male"
label var religion_islam "HH Religion:Islam" 
label var lit_can_read_write "HH Head:Can Read/Write"
label var pc_expm "Monthly average consumption expenditure"
label var con_bottom20 "HH in bottom 20% by consumption"

tempfile HH_Level
save "`HH_Level'"

*********** Merge in the HH-level Agricultral Characteristics *******
use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta" , clear 
keep if agri_control_household == 1 
keep b2area_hectare b1plot_distance b1plot_num a1hhid_combined  a1hhid_plotnum agri_control_household
duplicates drop

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (sum) total_b2area=b2area_hectare ///
(mean) b1plot_distance ///
(count) num_lands=b1plot_num ///
(max) agri_control_household , by(a1hhid_combined)

foreach v of var * {
label var `v' `"`l`v''"'
}

label var num_lands "Total number of lands" 
label var b1plot_distance "Average distance of HH to plot[mts]"
label var total_b2area "Total area owned[hectare]"

tempfile HH_plot
save "`HH_plot'"

merge 1:1 a1hhid_combined using "`HH_Level'" , nogenerate keep(2 3)

save "${final_data}${slash}analysis_datasets/HH_covariates.dta" , replace 

******* PLOT LEVEL DATASET *******
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
keep if agri_control_household == 1 
*keep if inlist(b2crop_season,1) //only retaining this current boro season

keep b1soil_type b1plot_distance b2area ///
b5additional_pipe b5distance_pump ///
b4machine_type_1 b4machine_type_2 b4machine_type_3 b4machine_type_4 ///
b5relative_height a1hhid_combined a1hhid_plotnum 
duplicates drop 

tab b1soil_type , gen(b1soil_type)
tab b5relative_height , gen(b5relative_height)

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first) a1hhid_combined b1soil_type* b1plot_distance b2area ///
b5additional_pipe b5relative_height* b4machine_type_*  ///
(mean) b5distance_pump, by(a1hhid_plotnum)

foreach v of var * {
label var `v' `"`l`v''"'
}

label var b1soil_type1 "Soil type:Clay"
label var b1soil_type2 "Soil type:Loam"
label var b1soil_type3 "Soil type:Sandy"
label var b1soil_type4 "Soil type:Clay-loam"
label var b1soil_type5 "Soil type:Sandy-loam"
label var b1plot_distance "Distance from the HH[mts]"
label var b2area "Area of the plot[hectare]"
label var b5additional_pipe "Plot has addtional main/lateral pipe"
label var b5relative_height1 "Relative Height:Upper"
label var b5relative_height2 "Relative Height:Middle"
label var b5relative_height3 "Relative Height:Lower"
label var b5distance_pump "Distance from the pump/canal[mts]"
label var b1plot_distance "Distance from the HH[mts]"

order a1hhid_plotnum a1hhid_combined b1plot_distance b2area b5additional_pipe ///
b5relative_height1 b5relative_height2 b5relative_height3 b5distance_pump ///
b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 b1soil_type5 b4machine_type_* 

tempfile Plot_level
save "`Plot_level'"

** merge the files *** 
merge m:1 a1hhid_combined using "${final_data}${slash}analysis_datasets${slash}HH_covariates.dta" , keep(3) nogenerate

order a1hhid_plotnum a1hhid_combined b1plot_distance b2area b5distance_pump b5additional_pipe b5relative_height1 b5relative_height2 b5relative_height3 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 b1soil_type5 total_b2area num_lands a2hhroster_count a2mem_age a2mem_gender a4employment_status a2agri_decision_gender a6_hh_savings std_hh_asset_index pc_expm con_bottom20 religion_islam lit_can_read_write

drop b1soil_type b5relative_height con_quintile con_bottom40

** merge village id *** 
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , nogenerate keep(3) keepusing(a1village)

save "${final_data}${slash}analysis_datasets${slash}All_covariates.dta", replace // Final dataset

* information on 2958 unique HHs. These households have made an agricultural or aquacultural decision on atleast one plot. 
* 19268 unique plots. 

************************* CREATE FIGURES ***************************************

*** Figure 42: Covariates of adoption of AWD ***

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 

keep if agri_control_household == 1 //only households doing agriculture 
keep if b1_boro24_utilize == 1 // in boro 2024
keep if inlist(b2crop_season,1) //only retaining this current boro season
keep if inlist(b2crop,9,10,11) //only retaining boro rice 

tab b5mainwater_source , gen(b5mainwater_source)
tab b5pump_type , gen(b5pump_type)
drop if b5mainwater_source == 1 // (1,243 observations deleted) rainfed plots 
drop if b5pump_type2 == 1 // 164 observations deleted rainfed plots 

replace b5water_management = 1 if b5water_management == 2 & b5ndry_this_season == 0 // those who said  

keep a1hhid_plotnum b5mainwater_source* b5pump_type* b5water_management b5ndry_this_season b5duration_dry
duplicates drop a1hhid_plotnum , force 
tempfile awd
save "`awd'"

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`awd'",  nogenerate keep(3)

gen AWD = 1 if b5water_management == 2
replace  AWD = 0 if AWD == . 
label var AWD "AWD"

gen AWD_legit = 0 
replace AWD_legit = 1 if AWD == 1 & b5ndry_this_season >= 1 & b5duration_dry >= 5
label var AWD_legit "AWD"

missings dropvars , force

/*
local i = 1
foreach var of varlist _all {
rename `var' v`i'
local i = `i' + 1
}
*/  

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep AWD AWD_legit $cont_vars $cat_vars a1village

eststo multivariate: regress AWD_legit $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress AWD_legit `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("Alternate Wetting and Drying [adoption rate:19.57%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 3722" , size(vsmall))
graph export "${final_figure}${slash}figure_42.png", replace as(png)

* N = 3765 

*** Figure 43: Covariates of adoption of AFPs ***

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
keep if agri_control_household == 1 
keep if inlist(b2crop_season,1) 
keep if inlist(b2crop,1,2,3,4,5,6,7,8,9,10,11)
//only retaining current boro season paddy plots

tab b5mainwater_source , gen(b5mainwater_source)
tab b5pump_type , gen(b5pump_type)

drop if b5mainwater_source == 1 // (1,243 observations deleted) rainfed plots 
drop if b5pump_type2 == 1 // 164 observations deleted rainfed plots 

keep a1hhid_plotnum b5mainwater_source* b5pump_type* b5water_management
duplicates drop a1hhid_plotnum , force 
tempfile afp 
save "`afp'"

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`afp'",  nogenerate keep(3)

missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep b5pump_type6 $cont_vars $cat_vars a1village

eststo multivariate: regress b5pump_type6 $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress b5pump_type6 `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("Axial Flow Pump [adoption rate:11%]", size(small)) /// 
ciopts(recast(rcap)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(6) cols(2) size(vsmall)) ///
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 3765" , size(vsmall))
graph export "${final_figure}${slash}figure_43.png", replace as(png)
* N= 3765 

* N: 19268  - plots

*** Figure 41: Covariates of adoption of G3 Rohu strain (left panel) and GIFT (right panel) ***
* G3 Rohu
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
collapse (first) b1plot_num , by(a1hhid_plotnum)
tempfile b1
save "`b1'" , replace 

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta" , clear
merge 1:1 a1hhid_plotnum using "`b1'" , nogenerate keep(3)

save "${final_data}${slash}analysis_datasets${slash}All_covariates_b1inc.dta" , replace 

****** prepare e1_2 - ROHU ********
use "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta" , clear 
keep if e1fish_id == 2 
keep b1fishing_count b1plot_num b1plotsize_decimal e1fish_id e1fish_name e1fish_lastyear a1hhid_combined e1g3_rohu

merge 1:1 a1hhid_combined b1plot_num using "${final_data}${slash}analysis_datasets${slash}All_covariates_b1inc.dta" , nogenerate 
keep if b1plotsize_decimal != . 

keep if e1g3_rohu != . //Only Rohu with fingerling bought 

missings dropvars , force

foreach var of varlist b1plot_distance b1plotsize_decimal total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

*drop b1plot_distance b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b1plotsize_decimal z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write 

keep e1g3_rohu $cont_vars $cat_vars a1village

eststo multivariate: regress e1g3_rohu $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress e1g3_rohu `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance= "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("G-3 Rohu [adoption rate:8%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 395" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gm.gph", replace

* N 395 - only Rohu households that bought fingerlings

** GIFT - Tilapia 
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
collapse (first) b1plot_num , by(a1hhid_plotnum)
tempfile b1
save "`b1'" , replace 

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta" , clear
merge 1:1 a1hhid_plotnum using "`b1'" , nogenerate keep(3)

save "${final_data}${slash}analysis_datasets${slash}All_covariates_b1inc.dta" , replace 

****** prepare e1_2 - Tilapia ********
use "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta" , clear 
keep if e1fish_id == 1 
keep b1fishing_count b1plot_num b1plotsize_decimal e1fish_id e1fish_name e1fish_lastyear a1hhid_combined e1gift_tilapia

merge 1:1 a1hhid_combined b1plot_num using "${final_data}${slash}analysis_datasets${slash}All_covariates_b1inc.dta" , nogenerate 
keep if b1plotsize_decimal != . 

keep if e1gift_tilapia != . //Only Tilapia with fingerling bought  

// N: 281 - ponds
missings dropvars , force

foreach var of varlist b1plot_distance b1plotsize_decimal total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

*drop b1plot_distance b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b1plotsize_decimal z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write 

keep e1gift_tilapia $cont_vars $cat_vars a1village

eststo multivariate: regress e1gift_tilapia $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress e1gift_tilapia `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance= "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("GIFT-Tilapia [adoption rate: 16.6%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 281" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gn.gph", replace

grc1leg "${final_figure}${slash}temporary_graphs${slash}gm.gph" "${final_figure}${slash}temporary_graphs${slash}gn.gph", legendfrom("${final_figure}${slash}temporary_graphs${slash}gn.gph") pos(3) cols(2) ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}figure_41.png", replace as(png)

* N: 281

** Figure 40: Covariates for CGIAR-related Boro varieties (left panel) and CGIAR-related varieties for all non-rice crops (right panel)

* DNA FINGERPRINTED BORO RICE
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5" , clear  // Identify which plots these are before running the regression
keep a1hhid_combined a1hhid_plotnum b1plot_num 
duplicates drop 
tempfile land_id
save "`land_id'" , replace 

use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear  // Identify which plots these are before running the regression
keep a1hhid_combined c2land_select c2variety_num c2variety_clean
rename c2land_select b1plot_num 
merge m:1 a1hhid_combined b1plot_num using "`land_id'" , nogenerate keep(3)

gen cg_variety = 0 
replace cg_variety = 1 if inlist(c2variety_num,1,3,4,5,9,11,12,13,14,15,16,17,18,20,24,25,26)

collapse (max) cg_variety (first) a1hhid_combined , by(a1hhid_plotnum)

tempfile cg_paddy
save "`cg_paddy'" , replace 

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`cg_paddy'" , nogenerate keep(3)

** Run the correlates regression
missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep cg_variety $cont_vars $cat_vars a1village

eststo multivariate: regress cg_variety $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress cg_variety `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("CGIAR-Varieties Boro Paddy [adoption rate:59%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) /// 
note("N: 1657" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gr.gph", replace

* 1657 - HHs 

**** ALL OTHER CROPS ****
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
keep if agri_control_household == 1 
keep if !mi(b2area) 
keep if b2crop_season != 4
keep if b2maize_variety != . | b2wheat_variety != . | b2lentil_variety != . | b2peanut_variety != .  | b2potato_variety != . 

** Identify CG varieties 
gen cg_variety = 0 
replace cg_variety = 1 if inrange(b2maize_variety, 4, 18) | inlist(b2lentil_variety,1,5,7,15) | ///
inlist(b2potato_variety,1,2,3,5,20,22) | inlist(b2peanut_variety,1,3,4) | inlist(b2wheat_variety,4,9,11,12,13,16,17)

keep a1hhid_plotnum a1hhid_combined agri_control_household cg_variety
collapse (max) cg_variety (first) a1hhid_combined agri_control_household , by(a1hhid_plotnum)

tempfile cg_non_paddy
save "`cg_non_paddy'" , replace 

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`cg_non_paddy'" , nogenerate keep(3)
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1", nogen keep(3)

** Run the correlates regression
missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep cg_variety $cont_vars $cat_vars a1village

eststo multivariate: regress cg_variety $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress cg_variety `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("CGIAR-Varieties Non-Paddy Crops[adoption rate:19%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 825" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gs.gph", replace

grc1leg "${final_figure}${slash}temporary_graphs${slash}gr.gph" "${final_figure}${slash}temporary_graphs${slash}gs.gph", legendfrom("${final_figure}${slash}temporary_graphs${slash}gr.gph") pos(3) cols(2) ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}figure_40.png", replace as(png)

* 825 plots 
}
******************************************************************************** 
**# Section 8. WHERE ARE THE ADOPTERS?  *** 
********************************************************************************
{
* Figure 44: District-wise share of CGIAR-related Boro rice varieties

		import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear
		
		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24 a1village a1division a1district divisionname districtname) keep(3) nogen

		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(1 3)
		
		drop c2paddy_mainvariety
		
		ren c2paddy_sample c2paddy_mainvariety
		
		collapse(first) c2paddy_mainvariety c2land_select hhweight_24 a1village ///
		a1division a1district divisionname districtname, by(a1hhid_combined)
		
		local paddy_up "1 2 3 4 6 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 34 35 39 40 42 43 45 46 47 48 49 50 51 52 54 55 56 57 58 61 62 63 65 66 67 68 69 70 71 73 74 75 76 77 78 80 84 86 87 88 90 91 94 95 96 97 98 99 100 101 101 133 134 135 137 139 140 141 144 145 146 149 152 155 156 157 158 160 161 178"
	
		local paddy_27_28 "27 28"
		
		local paddy_lo "1 2 3 4 6 8 10 11 12 13 14 15 16 17 18 19 21 22 23 24 25 27 28 29 30 31 34 35 39 40 42 43 45 46 47 48 49 50 51 52 54 55 56 57 61 62 63 65 66 67 68 69 70 71 73 74 75 76 77 78 80 84 86 87 88 90 91 95 96 98 99 100 101 101 133 134 135 137 139 140 141 144 145 146 149 152 155 156 157 158 160 161 178"
		
		local paddy_post05 "46 47 48 49 50 51 52 54 55 56 57 61 62 63 65 66 67 68 69 70 71 73 74 75 76 77 78 80 84 86 87 88 90 91 95 96 98 99 100 101 101 133 134 135 137 139 140 141 144 145 146 149 152 155 156 157 158 160 161 178"
		
		local paddy_post05_89 "46 47 48 49 50 51 52 54 55 56 57 61 62 63 65 66 67 68 69 70 71 73 74 75 76 77 78 80 84 86 87 88 90 91 95 96 98 99 100 101 101 133 134 135 137 139 140 141 144 145 146 149 152 155 156 157 158 160 161 178 88"
		
		*** DNA Fingerprinted - lower all ***
		preserve 
		g cg_paddy = 0
		
		foreach i of local paddy_lo {
		    recode cg_paddy 0 = 1 if c2paddy_mainvariety == `i'
		}
		
		collapse(mean) cg_paddy [pweight=hhweight_24], by(districtname)
		
		tempfile dna_map
		save `dna_map', replace
		
		use "${temp_data}${slash}district_admin_new", clear
		cap ren (ADM2_EN ADM1_EN new_ID) (districtname divisionname _ID)
		replace districtname = "Brahmanbaria" if districtname == "Brahamanbaria"
		replace districtname = "Chapai Nawabganj" if districtname == "Nawabganj"
		replace districtname = "Jhenaidah Zila T" if districtname == "Jhenaidah"
		
		tempfile district_shape
		save `district_shape', replace
		
		merge 1:1 districtname using `dna_map', nogen keep(3)
				
		replace cg_paddy = round(cg_paddy*100, .01)
		
		spmap cg_paddy using "${temp_data}${slash}district_coor_new", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color(cyan) size(small)) ///
		fcolor(Blues2) clnumber(4)  title("District-wise Proportion of CGIAR Paddy Varieties", size(vsmall)) ///
		note("DNA fingerprinting Boro HH:1,665.""These varieties are BR-28,BR-29,BR-49,BR-57,BR-67,BR-74,BR-75,BR-89,BR-100,BINA-10,BINA-17.",size(vsmall)) name(heat2, replace)
		
		graph export "${final_figure}${slash}figure_44.png", replace as(png)
		restore
		
		
	* Figure 45: District-wise share of BR-28 and 29 (left panel) and more recent CGIAR-related releases (post 2005, right panel)
	
		*** DNA Fingerprinted - only BR-29 and BR-28 ***
		preserve 
		g cg_paddy = 0
		
		foreach i in 27 28  {
		    recode cg_paddy 0 = 1 if c2paddy_mainvariety == `i'
		}
		
		collapse(mean) cg_paddy [pweight=hhweight_24], by(districtname)
		
		tempfile dna_map
		save `dna_map', replace
		
		use "${temp_data}${slash}district_admin_new", clear
		cap ren (ADM2_EN ADM1_EN new_ID) (districtname divisionname _ID)
		replace districtname = "Brahmanbaria" if districtname == "Brahamanbaria"
		replace districtname = "Chapai Nawabganj" if districtname == "Nawabganj"
		replace districtname = "Jhenaidah Zila T" if districtname == "Jhenaidah"
		
		tempfile district_shape
		save `district_shape', replace
		
		merge 1:1 districtname using `dna_map', nogen keep(3)
				
		replace cg_paddy = round(cg_paddy*100, .01)
		
		spmap cg_paddy using "${temp_data}${slash}district_coor_new", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color(cyan) size(small)) ///
		fcolor(Blues2) clnumber(4) ///
		note("DNA fingerprinting Boro HH:1,665.",size(vsmall)) 
		
		graph save "${final_figure}${slash}temporary_graphs${slash}gv.png", replace
		restore
		
		*** DNA Fingerprinted - post 2005 ***
		preserve
		g cg_paddy = 0
		
		foreach i of local paddy_post05 {
		    recode cg_paddy 0 = 1 if c2paddy_mainvariety == `i'
		}
		
		collapse(mean) cg_paddy [pweight=hhweight_24], by(districtname)
		
		tempfile dna_map
		save `dna_map', replace
		
		use "${temp_data}${slash}district_admin_new", clear
		cap ren (ADM2_EN ADM1_EN new_ID) (districtname divisionname _ID)
		replace districtname = "Brahmanbaria" if districtname == "Brahamanbaria"
		replace districtname = "Chapai Nawabganj" if districtname == "Nawabganj"
		replace districtname = "Jhenaidah Zila T" if districtname == "Jhenaidah"
		
		tempfile district_shape
		save `district_shape', replace
		
		merge 1:1 districtname using `dna_map', nogen keep(3)
				
		replace cg_paddy = round(cg_paddy*100, .01)
		
		spmap cg_paddy using "${temp_data}${slash}district_coor_new", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color(cyan) size(small)) ///
		fcolor(Blues2) clnumber(6)  title("") ///
		note("DNA fingerprinting Boro HH:1,665.""These varieties include BR-49,BR-67,BR-74,BR-75,BR-100,BINA-10,BINA-17",size(vsmall)) 
		
		graph save "${final_figure}${slash}temporary_graphs${slash}gx.png", replace
		restore

	   graph combine  "${final_figure}${slash}temporary_graphs${slash}gv.png" "${final_figure}${slash}temporary_graphs${slash}gx.png" , row(1)
	   graph export "${final_figure}${slash}figure_45.png", replace 
	   
	   * Figure 46. Self-reported Boro rice variety in 2018-19 at the plot level (%)
	   
	   	import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear
		
		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24 a1village a01combined_18) keep(3) nogen

		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(3)
		
		ren c2paddy_sample c2paddy_dna
		
		order c2paddy_dna c2paddy_mainvariety
		
		keep if inrange(c2paddy_dna, 47, 146) 
		
		keep a1hhid_combined c2paddy_dna variety_name a01combined_18
				
		ren variety_name dna_name
		
		duplicates tag a1hhid_combined , gen(dup)
		
		duplicates tag a01combined_18 , gen(dup2)
		
		collapse(first) c2paddy_dna dna_name, by(a01combined_18)
		
		preserve
		
		use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
		drop if h1_sl == 99
	
		gen boro_hh = (inrange(crop_a_h1, 10, 20) | inrange(crop_b_h1, 10, 20))  & h1_season==3
		
		keep if boro_hh == 1
		
		ren a01 a01combined_18
		
		tostring a01combined_18, replace
		
		tempfile boro_18
		save `boro_18', replace
		
		restore
		
		merge 1:m a01combined_18 using `boro_18', nogen keep(3) //61 non agri HHs, 46 non boro HHs in 2018 did boro in 2024, 412 HHs did varieties released post 2005. 
		
		g paddy_18 = "BRRI varieties pre-2005" if inrange(h1_01, 2, 22) | inrange(h1_01, 30, 32)
		replace paddy_18 = "BRRI Dhan 28 (1994)" if h1_01 == 28
		replace paddy_18 = "BRRI Dhan 29 (1994)" if h1_01 == 29
		replace paddy_18 = "BRRI varieties post-2005" if inrange(h1_01, 47, 49) | inrange(h1_01, 74, 108)
		replace paddy_18 = "BRRI Dhan 58 (2012)" if h1_01 == 58
		replace paddy_18 = "BRRI Dhan 62 (2013)" if h1_01 == 62
		replace paddy_18 = "Other non BRRI varieties" if inrange(h1_01, 136, 999)
		
		g pct_plot = 0
		
		encode paddy_18, g(paddy_en)
		
		tempfile paddy_18
		save `paddy_18', replace

		
		forvalues i = 1/7 {
			
			u `paddy_18', clear
			
		recode pct_plot 0 = 1 if paddy_en == `i'
		
		drop paddy_en
		
		g paddy_en = `i'
		
	
	
	collapse(mean) pct_plot, by(paddy_en)
				
		tempfile paddy_18_`i'
		save "`paddy_18_`i''", replace
		
		}
		
		clear
		tempfile paddy_18_all
		save `paddy_18_all', emptyok
		
		forvalues i = 1/7 {
			
			append using "`paddy_18_`i''"
			save `paddy_18_all', replace
			
		}
		
		g paddy_18 = "BRRI varieties pre-2005" if paddy_en == 6
		replace paddy_18 = "BRRI Dhan 28 (1994)" if paddy_en == 1
		replace paddy_18 = "BRRI Dhan 29 (1994)" if paddy_en == 2
		replace paddy_18 = "BRRI varieties post-2005" if paddy_en == 5
		replace paddy_18 = "BRRI Dhan 58 (2012)" if paddy_en == 3
		replace paddy_18 = "BRRI Dhan 62 (2013)" if paddy_en == 4
		replace paddy_18 = "Other non BRRI varieties" if paddy_en == 7
		
		replace pct_plot=round(pct_plot*100, .01)
		
		graph hbar (asis) pct_plot, over(paddy_18, sort(pct_plot) descending gap(20) label(labcolor(black)labsize(medium))) ///
	asyvars showyvars ylabel(0(10)50, labsize(small) noticks nogrid labcolor (black)) ///
	blabel(bar, format(%4.1f) size(small)color (black) position(outside)) ///
	bar(1, bcolor("dknavy"))bar(2, bcolor("dknavy"))bar(3, bcolor("dknavy")) ///
	bar(4, bcolor("dknavy"))bar(5, bcolor("dknavy"))bar(6, bcolor("dknavy")) ///
	bar(7, bcolor("dknavy")) ///
	title("", ///
	justification(middle) margin(b+1 t-1 l-1) bexpand size(small) color (black)) ///
	ytitle("", size(small)) legend(off)
	
	graph export "${final_figure}${slash}figure_46.png", replace as(png)

						
* Figure 47: Division-wise proportion of aquaculture households (left panel) amongst all agricultural households; households reporting purchasing GIFT tilapia fingerlings (of all tilapia aquaculture households purchasing fingerlings, middle panel); and households reporting purchasing G3 Rohu fingerlings (of all Rohu aquaculture households purchasing fingerlings, right panel)

		use "${temp_data}${slash}division_admin", clear
		cap ren (ADM1_EN new_ID) (divisionname _ID)
		tempfile division_shape
		save `division_shape', replace
		
		use "${temp_data}${slash}district_admin_new", clear
		cap ren (ADM2_EN ADM1_EN new_ID) (districtname divisionname _ID)
		replace districtname = "Brahmanbaria" if districtname == "Brahamanbaria"
		replace districtname = "Chapai Nawabganj" if districtname == "Nawabganj"
		replace districtname = "Jhenaidah Zila T" if districtname == "Jhenaidah"
		rename divisionname divisionname_map
		keep districtname divisionname_map
		tempfile district_shape
		save `district_shape', replace
	
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1", clear
		g fishing_hh = (b1fishing_count > 0)
		keep if agri_control_household == 1 
		collapse(max) fishing_hh hhweight_24 (first) districtname divisionname, by(a1hhid_combined)
		merge m:1 districtname using "`district_shape'"
		
		replace divisionname = divisionname_map if divisionname == "Dhaka"
		collapse(mean) fishing_hh [pweight=hhweight_24], by(divisionname)
		
		merge 1:1 divisionname using `division_shape'  
		
		replace fishing_hh = round(fishing_hh*100, .01)
		
		spmap fishing_hh using "${temp_data}${slash}division_coor", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color(cyan) size(small)) ///
		fcolor(Blues2) clnumber(4)  title() ///
		note("2972 Agriculturally Active HHs in the past year",size(vsmall)) 
		
		graph save "${final_figure}${slash}temporary_graphs${slash}gg.png", replace 
		
		
		**# heat map GIFT
		
		u "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1", nogen keep(3)
		
		keep if e1fish_id == 1 & e1fish_lastyear == 1 & e1fingerling_lastyear == 1
			
		g adopt_gift = (e1strain_tilapia==2)
		
		collapse(max) adopt_gift hhweight_24 (first) districtname divisionname, by(a1hhid_combined)
		
		merge m:1 districtname using "`district_shape'"
		replace divisionname = divisionname_map if divisionname == "Dhaka"
		
		collapse(mean) adopt_gift [pweight=hhweight_24], by(divisionname)
		
		merge 1:1 divisionname using `division_shape'  
		
		replace adopt_gift = round(adopt_gift*100, .01)
		
		spmap adopt_gift using "${temp_data}${slash}division_coor", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color("${teal") size(small)) ///
		fcolor(Oranges) clnumber(5)  title() ///
		note("258 Tilapia fingerling purchasing HHs in the past year",size(vsmall)) 
		graph save "${final_figure}${slash}temporary_graphs${slash}gh.png", replace 
	
		**# heat map rohu
		
		u "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1", nogen keep(3)
		
		keep if e1fish_id == 2 & e1fish_lastyear == 1 & e1fingerling_lastyear == 1
		
		g adopt_g3 = (e1strain_rohu==4)
		
		collapse(max) adopt_g3 hhweight_24 (first) districtname divisionname, by(a1hhid_combined)
		
		merge m:1 districtname using "`district_shape'"
		replace divisionname = divisionname_map if divisionname  == "Dhaka"
		
		collapse(mean) adopt_g3 [pweight=hhweight_24], by(divisionname)
		
		merge 1:1 divisionname using `division_shape'  
		
		replace adopt_g3 = round(adopt_g3*100, .01)
		
		spmap adopt_g3 using "${temp_data}${slash}division_coor", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color("${teal") size(small)) ///
		fcolor(Greens2) clnumber(4) clbreaks(0 20 40 50) title() ///
		note("352 Rohu fingerling purchasing HHs in the past year",size(vsmall)) name(fish3, replace)
		graph save "${final_figure}${slash}temporary_graphs${slash}gq.png", replace
		
		gr combine "${final_figure}${slash}temporary_graphs${slash}gg.png" "${final_figure}${slash}temporary_graphs${slash}gh.png" "${final_figure}${slash}temporary_graphs${slash}gq.png" , row(1)
		
		graph export "${final_figure}${slash}figure_47.png", replace 
		
		
* Figure 48: Proportion of households using AFPs at division level (as share of all households that apply irrigation in 2024) 
use "${temp_data}${slash}division_admin", clear
		cap ren (ADM1_EN new_ID) (divisionname _ID)
		tempfile division_shape
		save `division_shape', replace
		
		use "${temp_data}${slash}district_admin_new", clear
		cap ren (ADM2_EN ADM1_EN new_ID) (districtname divisionname _ID)
		replace districtname = "Brahmanbaria" if districtname == "Brahamanbaria"
		replace districtname = "Chapai Nawabganj" if districtname == "Nawabganj"
		replace districtname = "Jhenaidah Zila T" if districtname == "Jhenaidah"
		rename divisionname divisionname_map
		keep districtname divisionname_map
		tempfile district_shape
		save `district_shape', replace

use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) keepusing(a1division a1district divisionname districtname hhweight_24) nogenerate
 
keep a1division a1district divisionname districtname a1hhid_combined a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1plot_fishing b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b5* b2crop_season agri_control_household hhweight_24

keep if agri_control_household == 1 
keep if b1_boro24_utilize == 1 | b1_boro23_utilize == 1
drop if inlist(b2crop_season,5) 

// Water source 
tabulate b5mainwater_source, generate(water_source)
tabulate b5pump_type, generate(pump_type)
tabulate b5power_source, generate(fuel_type)

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) water_source* pump_type* fuel_type* (first) hhweight_24 a1division a1district divisionname districtname, by(a1hhid_combined)

foreach v of var * {
label var `v' `"`l`v''"'
}

// drop rainfed plots 
drop if water_source2 == 1
drop if pump_type2 == 1

// Boro agricultural plots which irrigate and are not rainfed (4927) - all crops 
keep pump_type9 hhweight_24 a1hhid_combined a1division a1district divisionname districtname
order a1division divisionname a1district districtname hhweight_24 a1hhid_combined pump_type9
sort a1district

merge m:1 districtname using "`district_shape'"
replace divisionname = divisionname_map if divisionname == "Dhaka" 
  
// Division-level 
collapse (mean) pump_type9 [pweight=hhweight_24] , by(divisionname)
replace pump_type9 = round((pump_type9*100),0.1)
merge 1:1 divisionname using `division_shape' 

spmap pump_type9 using "${temp_data}${slash}division_coor", id(_ID) ///
		label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
		label(ADM1_EN) pos(0 0) color(cyan) size(vsmall)) ///
		fcolor(Blues2) clnumber(4)  clbreaks(.16 .24 .26 .29 .34) title("Axial Flow Pumps", size(small)) ///
		note("Number of Households Irrigating in BIHS 2024 are 1,160",size(vsmall)) name(mech1, replace)
		graph export "${final_figure}${slash}figure_48.png", replace as(png)

}
******************************************************************************** 
**# REACH ESTIMATES *** 
******************************************************************************** 
{
	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	gen potato_variety = .
	
	g pct_hh = 0

	recode b2potato_variety -96 = 96
	
	keep if b2crop_season != 4
	keep if !mi(b2area) & !mi(b2potato_variety) 
		
	tempfile potato_all
	save `potato_all', replace
	
	levelsof b2potato_variety, local(levels)
	
	foreach j of local levels {
		
		u `potato_all', clear
		
	recode potato_variety . = `j'
	
	recode pct_hh 0 = 1 if b2potato_variety==`j'
	
	collapse(max) pct_hh potato_variety (first) hhweight_24, by(a1hhid_combined)
		
		tempfile p`j'
		save "`p`j''", replace	
	}
		
	clear
	tempfile potato_variety1
	save `potato_variety1', emptyok
	
	foreach j of local levels  {
	
	append using "`p`j''"
	save `potato_variety1', replace	
	}
	
	
	keep if potato_variety == 1 | potato_variety == 2 | potato_variety == 5 | ///
	potato_variety == 20 | potato_variety ==  3 | potato_variety == 22
	
	reshape wide pct_hh, i(a1hhid_combined) j(potato_variety)
	
	gen cg_potato = 0 
	replace cg_potato = 1 if pct_hh1 == 1 | pct_hh2  == 1 | pct_hh3  == 1 | pct_hh5  == 1 | ///
	pct_hh20  == 1 | pct_hh22  == 1 
	
	keep a1hhid_combined hhweight_24 cg_potato
	
	*collapse (sum) cg_potato [pweight=hhweight_24]
	
	save `potato_variety1', replace

**#  paddy - lower bound aman **************

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86 = 193
		
		
		keep if b2crop_season == 2
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
				
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)

		rename pct_vil pct_hh 
			
		tempfile paddy_hh_`i'
		save "`paddy_hh_`i''"
		
		}
		
		clear
		tempfile paddy_cg_hh
		save `paddy_cg_hh', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_hh_`i''"
			save `paddy_cg_hh', replace
			
		}

	reshape wide pct_hh, i(a1hhid_combined) j(paddy_variety)
	
	gen cg_paddy = 0 
	replace cg_paddy = 1 if ///
	pct_hh24 == 1 | /// 
	pct_hh25  == 1 | /// 
	pct_hh27  == 1 | /// 
	pct_hh39  == 1 | ///
	pct_hh46  == 1 | /// 
	pct_hh50  == 1 | ///
	pct_hh51  == 1 | ///
	pct_hh54  == 1 | ///
	pct_hh55  == 1 | ///
	pct_hh56  == 1 | ///
	pct_hh61  == 1 | ///
	pct_hh63  == 1 | ///
	pct_hh65  == 1 | ///
	pct_hh66  == 1 | ///
	pct_hh70  == 1 | /// 
	pct_hh71  == 1 | ///
	pct_hh73  == 1 | ///
	pct_hh74  == 1 | ///
	pct_hh75  == 1 | ///
	pct_hh76  == 1 | /// 
	pct_hh77  == 1 | ///
	pct_hh78  == 1 | ///
	pct_hh84  == 1 | ///
	pct_hh86  == 1 | ///
	pct_hh99  == 1 | ///
	pct_hh101  == 1 | ///
	pct_hh137  == 1 | ///
	pct_hh139  == 1 | ///
	pct_hh140  == 1 | ///
	pct_hh145  == 1 | ///
	pct_hh146  == 1 | ///
	pct_hh149  == 1 | ///
	pct_hh152  == 1 | ///
	pct_hh155  == 1 | ///
	pct_hh156  == 1 | ///
	pct_hh157  == 1 | ///
	pct_hh158  == 1 | ///
	pct_hh160  == 1 | ///
	pct_hh161  == 1 | ///
	pct_hh178  == 1 | ///
	pct_hh3  == 1 | ///
	pct_hh4  == 1 | ///
	pct_hh8  == 1 | ///
	pct_hh10  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh19  == 1 | ///
	pct_hh30  == 1 | ///
	pct_hh48  == 1 | ///
	pct_hh69  == 1 | ///   
	pct_hh1  == 1 | ///
	pct_hh2  == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh98  == 1 | ///
	pct_hh88  == 1 | ///
	pct_hh28  == 1 | ///
	pct_hh68  == 1 | ///
	pct_hh45  == 1 | ///
	pct_hh67  == 1 | ///
	pct_hh95  == 1 | ///
	pct_hh14  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh17  == 1 | ///
	pct_hh18  == 1 | ///
	pct_hh22  == 1 | ///
	pct_hh31  == 1 | ///
	pct_hh40  == 1 | ///
	pct_hh42  == 1 | ///
	pct_hh43  == 1 | ///
	pct_hh52  == 1 | ///
	pct_hh57  == 1 | ///
	pct_hh62  == 1 | ///
	pct_hh80  == 1 | ///
	pct_hh87  == 1 | ///
	pct_hh90  == 1 | ///
	pct_hh91  == 1 | ///
	pct_hh100  == 1 | ///
	pct_hh133  == 1 | ///
	pct_hh134  == 1 | ///
	pct_hh135  == 1 | ///
	pct_hh144  == 1 | ///
	pct_hh21  == 1 | ///
	pct_hh23  == 1 | ///
	pct_hh29  == 1 | ///
	pct_hh34  == 1 | ///
	pct_hh35  == 1 | ///
	pct_hh47  == 1 | ///
	pct_hh49  == 1 | ///
	pct_hh96  == 1 | ///
	pct_hh141  == 1
	
	merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3)
	
keep a1hhid_combined hhweight_24 cg_paddy
rename cg_paddy cg_paddy_lb 
*collapse (sum) cg_paddy_lb [pweight=hhweight_24]

tempfile paddy_variety1
save `paddy_variety1', replace

**# paddy - aman upper bound **************

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86 = 193
		
		
		keep if b2crop_season == 2
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
				
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
				
		foreach i of local paddy_up {
			
		u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)

		rename pct_vil pct_hh 
			
		tempfile paddy_hh_`i'
		save "`paddy_hh_`i''"
		
		}
		
		clear
		tempfile paddy_cg_hh_up
		save `paddy_cg_hh_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_hh_`i''"
			save `paddy_cg_hh_up', replace
			
		}

	reshape wide pct_hh, i(a1hhid_combined) j(paddy_variety)
		
	gen cg_paddy_up = 0 
	replace cg_paddy_up = 1 if ///
	pct_hh24 == 1 | /// 
	pct_hh25  == 1 | /// 
	pct_hh27  == 1 | /// 
	pct_hh39  == 1 | ///
	pct_hh46  == 1 | /// 
	pct_hh50  == 1 | ///
	pct_hh51  == 1 | ///
	pct_hh54  == 1 | ///
	pct_hh55  == 1 | ///
	pct_hh56  == 1 | ///
	pct_hh61  == 1 | ///
	pct_hh63  == 1 | ///
	pct_hh65  == 1 | ///
	pct_hh66  == 1 | ///
	pct_hh70  == 1 | /// 
	pct_hh71  == 1 | ///
	pct_hh73  == 1 | ///
	pct_hh74  == 1 | ///
	pct_hh75  == 1 | ///
	pct_hh76  == 1 | /// 
	pct_hh77  == 1 | ///
	pct_hh78  == 1 | ///
	pct_hh84  == 1 | ///
	pct_hh86  == 1 | ///
	pct_hh99  == 1 | ///
	pct_hh101  == 1 | ///
	pct_hh137  == 1 | ///
	pct_hh139  == 1 | ///
	pct_hh140  == 1 | ///
	pct_hh145  == 1 | ///
	pct_hh146  == 1 | ///
	pct_hh149  == 1 | ///
	pct_hh152  == 1 | ///
	pct_hh155  == 1 | ///
	pct_hh156  == 1 | ///
	pct_hh157  == 1 | ///
	pct_hh158  == 1 | ///
	pct_hh160  == 1 | ///
	pct_hh161  == 1 | ///
	pct_hh178  == 1 | ///
	pct_hh3  == 1 | ///
	pct_hh4  == 1 | ///
	pct_hh8  == 1 | ///
	pct_hh10  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh19  == 1 | ///
	pct_hh30  == 1 | ///
	pct_hh48  == 1 | ///
	pct_hh69  == 1 | ///   
	pct_hh1  == 1 | ///
	pct_hh2  == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh98  == 1 | ///
	pct_hh88  == 1 | ///
	pct_hh28  == 1 | ///
	pct_hh68  == 1 | ///
	pct_hh45  == 1 | ///
	pct_hh67  == 1 | ///
	pct_hh95  == 1 | ///
	pct_hh14  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh17  == 1 | ///
	pct_hh18  == 1 | ///
	pct_hh22  == 1 | ///
	pct_hh31  == 1 | ///
	pct_hh40  == 1 | ///
	pct_hh42  == 1 | ///
	pct_hh43  == 1 | ///
	pct_hh52  == 1 | ///
	pct_hh57  == 1 | ///
	pct_hh62  == 1 | ///
	pct_hh80  == 1 | ///
	pct_hh87  == 1 | ///
	pct_hh90  == 1 | ///
	pct_hh91  == 1 | ///
	pct_hh100  == 1 | ///
	pct_hh133  == 1 | ///
	pct_hh134  == 1 | ///
	pct_hh135  == 1 | ///
	pct_hh144  == 1 | ///
	pct_hh21  == 1 | ///
	pct_hh23  == 1 | ///
	pct_hh29  == 1 | ///
	pct_hh34  == 1 | ///
	pct_hh35  == 1 | ///
	pct_hh47  == 1 | ///
	pct_hh49  == 1 | ///
	pct_hh96  == 1 | ///
	pct_hh141  == 1 | /// 
	pct_hh20  == 1 | ///
	pct_hh26  == 1 | ///
	pct_hh32  == 1 | ///
	pct_hh58  == 1 | ///
	pct_hh94  == 1 | ///
	pct_hh97  == 1
	
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3)
	
keep a1hhid_combined hhweight_24 cg_paddy_up
*/
*collapse (sum) cg_paddy_up [pweight=hhweight_24]

tempfile paddy_variety2
save `paddy_variety2', replace

	**#  paddy - lower bound aus **************

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86 = 193
		
		
		keep if b2crop_season == 3
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
				
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)

		rename pct_vil pct_hh 
			
		tempfile paddy_hh_`i'
		save "`paddy_hh_`i''"
		
		}
		
		clear
		tempfile paddy_cg_hh
		save `paddy_cg_hh', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_hh_`i''"
			save `paddy_cg_hh', replace
			
		}

	reshape wide pct_hh, i(a1hhid_combined) j(paddy_variety)
	
	gen cg_aus = 0 
	replace cg_aus = 1 if ///
	pct_hh24 == 1 | /// 
	pct_hh25  == 1 | /// 
	pct_hh27  == 1 | /// 
	pct_hh39  == 1 | ///
	pct_hh46  == 1 | /// 
	pct_hh50  == 1 | ///
	pct_hh51  == 1 | ///
	pct_hh54  == 1 | ///
	pct_hh55  == 1 | ///
	pct_hh56  == 1 | ///
	pct_hh61  == 1 | ///
	pct_hh63  == 1 | ///
	pct_hh65  == 1 | ///
	pct_hh66  == 1 | ///
	pct_hh70  == 1 | /// 
	pct_hh71  == 1 | ///
	pct_hh73  == 1 | ///
	pct_hh74  == 1 | ///
	pct_hh75  == 1 | ///
	pct_hh76  == 1 | /// 
	pct_hh77  == 1 | ///
	pct_hh78  == 1 | ///
	pct_hh84  == 1 | ///
	pct_hh86  == 1 | ///
	pct_hh99  == 1 | ///
	pct_hh101  == 1 | ///
	pct_hh137  == 1 | ///
	pct_hh139  == 1 | ///
	pct_hh140  == 1 | ///
	pct_hh145  == 1 | ///
	pct_hh146  == 1 | ///
	pct_hh149  == 1 | ///
	pct_hh152  == 1 | ///
	pct_hh155  == 1 | ///
	pct_hh156  == 1 | ///
	pct_hh157  == 1 | ///
	pct_hh158  == 1 | ///
	pct_hh160  == 1 | ///
	pct_hh161  == 1 | ///
	pct_hh178  == 1 | ///
	pct_hh3  == 1 | ///
	pct_hh4  == 1 | ///
	pct_hh8  == 1 | ///
	pct_hh10  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh19  == 1 | ///
	pct_hh30  == 1 | ///
	pct_hh48  == 1 | ///
	pct_hh69  == 1 | ///   
	pct_hh1  == 1 | ///
	pct_hh2  == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh98  == 1 | ///
	pct_hh88  == 1 | ///
	pct_hh28  == 1 | ///
	pct_hh68  == 1 | ///
	pct_hh45  == 1 | ///
	pct_hh67  == 1 | ///
	pct_hh95  == 1 | ///
	pct_hh14  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh17  == 1 | ///
	pct_hh18  == 1 | ///
	pct_hh22  == 1 | ///
	pct_hh31  == 1 | ///
	pct_hh40  == 1 | ///
	pct_hh42  == 1 | ///
	pct_hh43  == 1 | ///
	pct_hh52  == 1 | ///
	pct_hh57  == 1 | ///
	pct_hh62  == 1 | ///
	pct_hh80  == 1 | ///
	pct_hh87  == 1 | ///
	pct_hh90  == 1 | ///
	pct_hh91  == 1 | ///
	pct_hh100  == 1 | ///
	pct_hh133  == 1 | ///
	pct_hh134  == 1 | ///
	pct_hh135  == 1 | ///
	pct_hh144  == 1 | ///
	pct_hh21  == 1 | ///
	pct_hh23  == 1 | ///
	pct_hh29  == 1 | ///
	pct_hh34  == 1 | ///
	pct_hh35  == 1 | ///
	pct_hh47  == 1 | ///
	pct_hh49  == 1 | ///
	pct_hh96  == 1 | ///
	pct_hh141  == 1

	
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3)
	
keep a1hhid_combined hhweight_24 cg_aus
rename cg_aus cg_aus_lb 
*collapse (sum) cg_paddy_lb [pweight=hhweight_24]

tempfile paddy_aus1
save `paddy_aus1', replace

**# paddy - aus upper bound **************

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86 = 193
		
		
		keep if b2crop_season == 3
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
				
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
		
		foreach i of local paddy_up {
			
		u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)

		rename pct_vil pct_hh 
			
		tempfile paddy_hh_`i'
		save "`paddy_hh_`i''"
		
		}
		
		clear
		tempfile paddy_cg_hh_up
		save `paddy_cg_hh_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_hh_`i''"
			save `paddy_cg_hh_up', replace
			
		}

	reshape wide pct_hh, i(a1hhid_combined) j(paddy_variety)
		
	gen cg_aus_up = 0 
	replace cg_aus_up = 1 if ///
	pct_hh24 == 1 | /// 
	pct_hh25  == 1 | /// 
	pct_hh27  == 1 | /// 
	pct_hh39  == 1 | ///
	pct_hh46  == 1 | /// 
	pct_hh50  == 1 | ///
	pct_hh51  == 1 | ///
	pct_hh54  == 1 | ///
	pct_hh55  == 1 | ///
	pct_hh56  == 1 | ///
	pct_hh61  == 1 | ///
	pct_hh63  == 1 | ///
	pct_hh65  == 1 | ///
	pct_hh66  == 1 | ///
	pct_hh70  == 1 | /// 
	pct_hh71  == 1 | ///
	pct_hh73  == 1 | ///
	pct_hh74  == 1 | ///
	pct_hh75  == 1 | ///
	pct_hh76  == 1 | /// 
	pct_hh77  == 1 | ///
	pct_hh78  == 1 | ///
	pct_hh84  == 1 | ///
	pct_hh86  == 1 | ///
	pct_hh99  == 1 | ///
	pct_hh101  == 1 | ///
	pct_hh137  == 1 | ///
	pct_hh139  == 1 | ///
	pct_hh140  == 1 | ///
	pct_hh145  == 1 | ///
	pct_hh146  == 1 | ///
	pct_hh149  == 1 | ///
	pct_hh152  == 1 | ///
	pct_hh155  == 1 | ///
	pct_hh156  == 1 | ///
	pct_hh157  == 1 | ///
	pct_hh158  == 1 | ///
	pct_hh160  == 1 | ///
	pct_hh161  == 1 | ///
	pct_hh178  == 1 | ///
	pct_hh3  == 1 | ///
	pct_hh4  == 1 | ///
	pct_hh8  == 1 | ///
	pct_hh10  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh19  == 1 | ///
	pct_hh30  == 1 | ///
	pct_hh48  == 1 | ///
	pct_hh69  == 1 | ///   
	pct_hh1  == 1 | ///
	pct_hh2  == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh98  == 1 | ///
	pct_hh88  == 1 | ///
	pct_hh28  == 1 | ///
	pct_hh68  == 1 | ///
	pct_hh45  == 1 | ///
	pct_hh67  == 1 | ///
	pct_hh95  == 1 | ///
	pct_hh14  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh17  == 1 | ///
	pct_hh18  == 1 | ///
	pct_hh22  == 1 | ///
	pct_hh31  == 1 | ///
	pct_hh40  == 1 | ///
	pct_hh42  == 1 | ///
	pct_hh43  == 1 | ///
	pct_hh52  == 1 | ///
	pct_hh57  == 1 | ///
	pct_hh62  == 1 | ///
	pct_hh80  == 1 | ///
	pct_hh87  == 1 | ///
	pct_hh90  == 1 | ///
	pct_hh91  == 1 | ///
	pct_hh100  == 1 | ///
	pct_hh133  == 1 | ///
	pct_hh134  == 1 | ///
	pct_hh135  == 1 | ///
	pct_hh144  == 1 | ///
	pct_hh21  == 1 | ///
	pct_hh23  == 1 | ///
	pct_hh29  == 1 | ///
	pct_hh34  == 1 | ///
	pct_hh35  == 1 | ///
	pct_hh47  == 1 | ///
	pct_hh49  == 1 | ///
	pct_hh96  == 1 | ///
	pct_hh141  == 1 | /// 
	pct_hh20  == 1 | ///
	pct_hh26  == 1 | ///
	pct_hh32  == 1 | ///
	pct_hh58  == 1 | ///
	pct_hh94  == 1 | ///
	pct_hh97  == 1
	
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3)
	
keep a1hhid_combined hhweight_24 cg_aus_up
*/
*collapse (sum) cg_paddy_up [pweight=hhweight_24]

tempfile paddy_aus2
save `paddy_aus2', replace

		**# Adoption in boro DNA+self reports
		import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear 
	

		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(1 3)
		
		drop c2paddy_mainvariety
		
		ren (c2paddy_sample c2land_select) (b2paddy_variety b1plot_num)
		
		collapse(first) b2paddy_variety b1plot_num, by(a1hhid_combined)
		
		tempfile dna_plot
		save `dna_plot', replace
		
	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
		
		recode b2paddy_variety -86/-79 = 193
		
		
		keep if b2crop_season == 1
		keep if !mi(b2area) & !mi(b2paddy_variety)
		
		collapse(first) a1hhid_combined b1plot_num b2paddy_variety, by(a1hhid_plotnum)
		
		preserve
		drop b2paddy_variety

		merge 1:1 a1hhid_combined b1plot_num using `dna_plot', keep(2 3)
		
		tempfile b1dna_plot
		save `b1dna_plot', replace
		
		restore
		
		
		
		append using `b1dna_plot'
		
		
		
		duplicates tag a1hhid_combined b1plot_num, gen(dup)
		
		drop if dup == 1 & _merge == .
		
		drop _merge dup
		
		g paddy_variety = .
		g pct_hh = 0
		
		
		tempfile paddy_dna
		save `paddy_dna', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		foreach i of local paddy {
			
			u `paddy_dna', clear
			
		recode paddy_variety . = `i'
		
		recode pct_hh 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_hh (first) paddy_variety, by(a1hhid_combined)


		tempfile paddy_hh_`i'
		save "`paddy_hh_`i''"
		
		}
		
		clear
		tempfile paddy_cg_hh
		save `paddy_cg_hh', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_hh_`i''"
			save `paddy_cg_hh', replace
			
		}

	reshape wide pct_hh, i(a1hhid_combined) j(paddy_variety)
	
	gen dna_paddy = 0 
	replace dna_paddy = 1 if ///
		pct_hh24 == 1 | /// 
		pct_hh25  == 1 | /// 
		pct_hh27  == 1 | /// 
		pct_hh39  == 1 | ///
		pct_hh46  == 1 | /// 
		pct_hh50  == 1 | ///
		pct_hh51  == 1 | ///
		pct_hh54  == 1 | ///
		pct_hh55  == 1 | ///
		pct_hh56  == 1 | ///
		pct_hh61  == 1 | ///
		pct_hh63  == 1 | ///
		pct_hh65  == 1 | ///
		pct_hh66  == 1 | ///
		pct_hh70  == 1 | /// 
		pct_hh71  == 1 | ///
		pct_hh73  == 1 | ///
		pct_hh74  == 1 | ///
		pct_hh75  == 1 | ///
		pct_hh76  == 1 | /// 
		pct_hh77  == 1 | ///
		pct_hh78  == 1 | ///
		pct_hh84  == 1 | ///
		pct_hh86  == 1 | ///
		pct_hh99  == 1 | ///
		pct_hh101  == 1 | ///
		pct_hh137  == 1 | ///
		pct_hh139  == 1 | ///
		pct_hh140  == 1 | ///
		pct_hh145  == 1 | ///
		pct_hh146  == 1 | ///
		pct_hh149  == 1 | ///
		pct_hh152  == 1 | ///
		pct_hh155  == 1 | ///
		pct_hh156  == 1 | ///
		pct_hh157  == 1 | ///
		pct_hh158  == 1 | ///
		pct_hh160  == 1 | ///
		pct_hh161  == 1 | ///
		pct_hh178  == 1 | ///
		pct_hh3  == 1 | ///
		pct_hh4  == 1 | ///
		pct_hh8  == 1 | ///
		pct_hh10  == 1 | ///
		pct_hh11  == 1 | ///
		pct_hh12  == 1 | ///
		pct_hh13  == 1 | ///
		pct_hh19  == 1 | ///
		pct_hh30  == 1 | ///
		pct_hh48  == 1 | ///
		pct_hh69  == 1 | ///   
		pct_hh1  == 1 | ///
		pct_hh2  == 1 | ///
		pct_hh6  == 1 | ///
		pct_hh15  == 1 | ///
		pct_hh98  == 1 | ///
		pct_hh88  == 1 | ///
		pct_hh28  == 1 | ///
		pct_hh68  == 1 | ///
		pct_hh45  == 1 | ///
		pct_hh67  == 1 | ///
		pct_hh95  == 1 | ///
		pct_hh14  == 1 | ///
		pct_hh16  == 1 | ///
		pct_hh17  == 1 | ///
		pct_hh18  == 1 | ///
		pct_hh22  == 1 | ///
		pct_hh31  == 1 | ///
		pct_hh40  == 1 | ///
		pct_hh42  == 1 | ///
		pct_hh43  == 1 | ///
		pct_hh52  == 1 | ///
		pct_hh57  == 1 | ///
		pct_hh62  == 1 | ///
		pct_hh80  == 1 | ///
		pct_hh87  == 1 | ///
		pct_hh90  == 1 | ///
		pct_hh91  == 1 | ///
		pct_hh100  == 1 | ///
		pct_hh133  == 1 | ///
		pct_hh134  == 1 | ///
		pct_hh135  == 1 | ///
		pct_hh144  == 1 | ///
		pct_hh21  == 1 | ///
		pct_hh23  == 1 | ///
		pct_hh29  == 1 | ///
		pct_hh34  == 1 | ///
		pct_hh35  == 1 | ///
		pct_hh47  == 1 | ///
		pct_hh49  == 1 | ///
		pct_hh96  == 1 | ///
		pct_hh141  == 1
		
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3)
	
keep a1hhid_combined hhweight_24 dna_paddy
rename dna_paddy dna_paddy_lb 

tempfile dna_variety1
save `dna_variety1', replace
	
	u `paddy_dna', clear

	local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
	
	foreach i of local paddy_up {
			
			u `paddy_dna', clear
			
		recode paddy_variety . = `i'
		
		recode pct_hh 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_hh (first) paddy_variety, by(a1hhid_combined)


		tempfile paddy_hh_`i'
		save "`paddy_hh_`i''"
		
		}
		
		clear
		tempfile paddy_cg_hh
		save `paddy_cg_hh', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_hh_`i''"
			save `paddy_cg_hh', replace
			
		}

	reshape wide pct_hh, i(a1hhid_combined) j(paddy_variety)
	
	gen dna_paddy_up = 0 
	replace dna_paddy_up = 1 if ///
	pct_hh24 == 1 | /// 
	pct_hh25  == 1 | /// 
	pct_hh27  == 1 | /// 
	pct_hh39  == 1 | ///
	pct_hh46  == 1 | /// 
	pct_hh50  == 1 | ///
	pct_hh51  == 1 | ///
	pct_hh54  == 1 | ///
	pct_hh55  == 1 | ///
	pct_hh56  == 1 | ///
	pct_hh61  == 1 | ///
	pct_hh63  == 1 | ///
	pct_hh65  == 1 | ///
	pct_hh66  == 1 | ///
	pct_hh70  == 1 | /// 
	pct_hh71  == 1 | ///
	pct_hh73  == 1 | ///
	pct_hh74  == 1 | ///
	pct_hh75  == 1 | ///
	pct_hh76  == 1 | /// 
	pct_hh77  == 1 | ///
	pct_hh78  == 1 | ///
	pct_hh84  == 1 | ///
	pct_hh86  == 1 | ///
	pct_hh99  == 1 | ///
	pct_hh101  == 1 | ///
	pct_hh137  == 1 | ///
	pct_hh139  == 1 | ///
	pct_hh140  == 1 | ///
	pct_hh145  == 1 | ///
	pct_hh146  == 1 | ///
	pct_hh149  == 1 | ///
	pct_hh152  == 1 | ///
	pct_hh155  == 1 | ///
	pct_hh156  == 1 | ///
	pct_hh157  == 1 | ///
	pct_hh158  == 1 | ///
	pct_hh160  == 1 | ///
	pct_hh161  == 1 | ///
	pct_hh178  == 1 | ///
	pct_hh3  == 1 | ///
	pct_hh4  == 1 | ///
	pct_hh8  == 1 | ///
	pct_hh10  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh19  == 1 | ///
	pct_hh30  == 1 | ///
	pct_hh48  == 1 | ///
	pct_hh69  == 1 | ///   
	pct_hh1  == 1 | ///
	pct_hh2  == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh98  == 1 | ///
	pct_hh88  == 1 | ///
	pct_hh28  == 1 | ///
	pct_hh68  == 1 | ///
	pct_hh45  == 1 | ///
	pct_hh67  == 1 | ///
	pct_hh95  == 1 | ///
	pct_hh14  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh17  == 1 | ///
	pct_hh18  == 1 | ///
	pct_hh22  == 1 | ///
	pct_hh31  == 1 | ///
	pct_hh40  == 1 | ///
	pct_hh42  == 1 | ///
	pct_hh43  == 1 | ///
	pct_hh52  == 1 | ///
	pct_hh57  == 1 | ///
	pct_hh62  == 1 | ///
	pct_hh80  == 1 | ///
	pct_hh87  == 1 | ///
	pct_hh90  == 1 | ///
	pct_hh91  == 1 | ///
	pct_hh100  == 1 | ///
	pct_hh133  == 1 | ///
	pct_hh134  == 1 | ///
	pct_hh135  == 1 | ///
	pct_hh144  == 1 | ///
	pct_hh21  == 1 | ///
	pct_hh23  == 1 | ///
	pct_hh29  == 1 | ///
	pct_hh34  == 1 | ///
	pct_hh35  == 1 | ///
	pct_hh47  == 1 | ///
	pct_hh49  == 1 | ///
	pct_hh96  == 1 | ///
	pct_hh141  == 1 | /// 
	pct_hh20  == 1 | ///
	pct_hh26  == 1 | ///
	pct_hh32  == 1 | ///
	pct_hh58  == 1 | ///
	pct_hh94  == 1 | ///
	pct_hh97  == 1
	
merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3)
	
keep a1hhid_combined hhweight_24 dna_paddy_up

tempfile dna_variety2
save `dna_variety2', replace
	

**# maize varieties per season	
	
	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g maize_variety = .
	
	g pct_hh = 0
		
	recode b2maize_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile maize_village
	save `maize_village', replace
	
	keep if !mi(b2area) & !mi(b2maize_variety)
	
	tempfile maize_all
	save `maize_all', replace
	
	levelsof b2maize_variety, local(maize_levels)
	
	foreach i of local maize_levels {
	
	u `maize_all', clear
		
	recode maize_variety . = `i'
	
	recode pct_hh 0 = 1 if b2maize_variety==`i'
	
	collapse(max) pct_hh maize_variety (first) hhweight_24, by(a1hhid_combined)
				
		tempfile m`i'
		save "`m`i''", replace
		}
		
	clear
	tempfile maize_variety1
	save `maize_variety1', emptyok
		
	foreach i of local maize_levels  {
			
	append using "`m`i''"
	save `maize_variety1', replace
		
	}
		
	keep if inrange(maize_variety, 4, 18)
	
	reshape wide pct_hh, i(a1hhid_combined) j(maize_variety)
	
	gen cg_maize = 0 
	replace cg_maize = 1 if /// 
	pct_hh4 == 1 | ///
	pct_hh5  == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh7  == 1 | ///
	pct_hh8  == 1 | ///
	pct_hh9  == 1 | ///
	pct_hh10  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh18  == 1 
	
	keep a1hhid_combined hhweight_24 cg_maize
	
	*collapse (sum) cg_maize [pweight=hhweight_24]
	
	save `maize_variety1', replace


* CGIAR wheat varieties (self-report)

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g wheat_variety = .
	
	g pct_hh = 0
	
	recode b2wheat_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile wheat_fin
	save `wheat_fin', replace

	local wheat "1 4 6 9 11 12 13 15 16 17 19 23"
		
	levelsof b2wheat_variety, local(wheat_levels)
	
	foreach i of local wheat_levels {		
	u `wheat_fin', clear
	recode wheat_variety . = `i'
	
	recode pct_hh 0 = 1 if b2wheat_variety== `i'
	
	collapse(max) pct_hh wheat_variety (first) hhweight_24, by(a1hhid_combined)
	
	tempfile wheat_vil_`i'
	save "`wheat_vil_`i''"
	
	}
	
	clear
	tempfile wheat_cg_vil1
	save `wheat_cg_vil1', emptyok
	
	foreach i of local wheat {
		
		append using "`wheat_vil_`i''"
		save `wheat_cg_vil1', replace
	}

			
	reshape wide pct_hh, i(a1hhid_combined) j(wheat_variety)
	
	gen cg_wheat = 0 
	replace cg_wheat = 1 if /// 
	pct_hh4 == 1 | ///
	pct_hh6  == 1 | ///
	pct_hh9  == 1 | ///
	pct_hh11  == 1 | ///
	pct_hh12  == 1 | ///
	pct_hh13  == 1 | ///
	pct_hh15  == 1 | ///
	pct_hh16  == 1 | ///
	pct_hh17  == 1 | ///
	pct_hh19  == 1 | ///
	pct_hh23  == 1
	
	keep a1hhid_combined hhweight_24 cg_wheat
	
	*collapse (sum) cg_wheat [pweight=hhweight_24]
	
	tempfile wheat_variety1
	save `wheat_variety1', replace


* CGIAR peanut varieties (self-report)

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g peanut_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2peanut_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile peanut_village
	save `peanut_village', replace
	
	keep if !mi(b2area) & !mi(b2peanut_variety)
	
	g innovation_year = .
	recode innovation_year . = 2016 if b2peanut_variety == 1
	recode innovation_year . = 1998 if b2peanut_variety == 3
	recode innovation_year . = 2004 if b2peanut_variety == 4

	
	tempfile peanut_all
	save `peanut_all', replace
	
	levelsof b2peanut_variety, local(peanut_levels)
	
	u `peanut_all', clear
	
	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1
	
	collapse(count) num_hh, by(merge_id)

	
	tempfile peanut_hh_count
	save `peanut_hh_count', replace
	
	
	foreach i of local peanut_levels {
		
		u `peanut_all', clear
		
	recode peanut_variety . = `i'
	
	recode pct_hh 0 = 1 if b2peanut_variety==`i'
	
	collapse(max) pct_hh peanut_variety (first) hhweight_24 b2crop_season, by(a1hhid_combined)

	tempfile p`i'
	save "`p`i''", replace
	
	}
	
	clear
	tempfile peanut_variety1
	save `peanut_variety1', emptyok
	
		
	foreach i of local peanut_levels  {
			
	append using "`p`i''"
	save `peanut_variety1', replace
		
	}
	
reshape wide pct_hh, i(a1hhid_combined) j(peanut_variety)
	
	gen cg_peanut = 0 
	replace cg_peanut = 1 if /// 
	pct_hh1 == 1 | ///
	pct_hh3  == 1 | ///
	pct_hh4  == 1 

	keep a1hhid_combined hhweight_24 cg_peanut
	
	*collapse (sum) cg_peanut [pweight=hhweight_24]
	
	tempfile peanut_variety1
	save `peanut_variety1', replace
	
	
* CGIAR lentil varieties (self-report) 

	use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g lentil_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2lentil_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile lentil_village
	save `lentil_village', replace
	
	keep if !mi(b2area) & !mi(b2lentil_variety)
	
	/*
	1	BARI Masur 1
	5	BARI Masur 6
	7	BARI Masur 8
	15	BINA Masur 7

	*/
	
	g innovation_year = .
	recode innovation_year . = 1991 if b2lentil_variety == 1
	recode innovation_year . = 2006 if b2lentil_variety == 5
	recode innovation_year . = 2015 if b2lentil_variety == 7
	recode innovation_year . = 2013 if b2lentil_variety == 15
	
	tempfile lentil_all
	save `lentil_all', replace
	
	levelsof b2lentil_variety, local(lentil_levels)
	
	
	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1
	
	collapse(count) num_hh, by(merge_id)

	
	tempfile lentil_hh_count
	save `lentil_hh_count', replace
	
	
	foreach i of local lentil_levels {
		
		u `lentil_all', clear
		
	recode lentil_variety . = `i'
	
	recode pct_hh 0 = 1 if b2lentil_variety==`i'
	
	collapse(max) pct_hh lentil_variety (first) hhweight_24, by(a1hhid_combined)
	
	tempfile l`i'
	save "`l`i''", replace
		
	}
		
	clear
	tempfile lentil_variety1
	save `lentil_variety1', emptyok
		
	foreach i of local lentil_levels  {
			
	append using "`l`i''"
	save `lentil_variety1', replace
		
	}

	keep if inlist(lentil_variety,1,5,7,15)
reshape wide pct_hh, i(a1hhid_combined) j(lentil_variety)
	
	gen cg_lentil = 0 
	replace cg_lentil = 1 if /// 
	pct_hh1 == 1 | ///
	pct_hh5  == 1 | ///
	pct_hh7  == 1 | /// 
	pct_hh15  == 1 

	keep a1hhid_combined hhweight_24 cg_lentil
	
	*collapse (sum) cg_lentil [pweight=hhweight_24]
	
	save `lentil_variety1', replace
	
merge 1:1 a1hhid_combined using `potato_variety1' , nogenerate 
merge 1:1 a1hhid_combined using `peanut_variety1' , nogenerate 
merge 1:1 a1hhid_combined using `wheat_variety1' , nogenerate 
merge 1:1 a1hhid_combined using `maize_variety1' , nogenerate 
merge 1:1 a1hhid_combined using `paddy_variety1' , nogenerate 
merge 1:1 a1hhid_combined using `paddy_variety2' , nogenerate 
merge 1:1 a1hhid_combined using `dna_variety1' , nogenerate
merge 1:1 a1hhid_combined using `dna_variety2' , nogenerate  
merge 1:1 a1hhid_combined using `paddy_aus1' , nogenerate
merge 1:1 a1hhid_combined using `paddy_aus2' , nogenerate


tempfile germplasm 
save `germplasm' , replace
		
		
*# AWD 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta"

keep if agri_control_household == 1 //only households doing agriculture 
keep if inlist(b2crop_season,1) //only retaining this current boro season
keep if inlist(b2crop,9,10,11) //only retaining boro rice 
drop if b5mainwater_source == 1 // (1,243 observations deleted - drop rain dependent
drop if b5pump_type == 1 // 164 observations deleted
replace b5water_management = 1 if b5water_management == 2 & b5ndry_this_season == 0 // those who said  

keep b5water_management b5ndry_this_season b5duration_dry hhweight_24 a1hhid_combined

gen AWD_def = 0
replace AWD_def= 1 if b5water_management == 2 & b5ndry_this_season >= 1  & b5duration_dry >= 5

foreach var of varlist * {
    local label_`var' : variable label `var'
}

collapse (first) hhweight_24 (max) adopt_AWD=AWD , by(a1hhid_combined) //1675 Households

foreach var of varlist * {
    label var `var' "`label_`var''"
}

tempfile awd_innovation
save `awd_innovation', replace

*# AFP 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta"
			
		keep if b2crop_season != 4
		
		keep if !mi(b2area) 
		keep if b5pump_type != 1 
		
		g adopt_afp = (b5pump_type == 8)
				
		collapse(max) adopt_afp (first) hhweight_24, by(a1hhid_combined)
		*collapse (sum) adopt_afp [pweight=hhweight_24]
		
		tempfile afp_innovation1
		save `afp_innovation1', replace

*# Reapers 
	use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta"
		
		keep if inrange(b2crop, 1, 13) | b2crop == 23
		
		g num_hh = 1
	
		collapse(max) num_hh, by(a1hhid_combined)
		
		tempfile reaper_hh
		save `reaper_hh', replace
	
		g innovation = 6
	
		collapse(count) num_hh, by(innovation) // Number of paddy, wheat, jute cultivating HH
		
		tempfile reaper_num_hh
		save `reaper_num_hh', replace
		
		use "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_d1_machinery_a1" , clear

		
		keep if d1cgiartech_id == 6
		
		duplicates drop 
		
		merge m:1 a1hhid_combined using `reaper_hh', nogen keep(3)
		
		g adopt_reaper = (d1cgiartech_usage == 1 | inrange(d1cgiartech_stopyear, 2023, 2024))
					
		collapse(max) adopt_reaper (first) hhweight_24, by(a1hhid_combined)
		
		*collapse (sum) adopt_reaper [pweight=hhweight_24]

		tempfile reaper_innovation1
		save `reaper_innovation1', replace
		
*# GIFT / ROHU 
use "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
		
		keep if e1fish_id == 1 & e1fish_lastyear == 1 //& e1fingerling_lastyear == 1
		
		g adopt_gift = (e1strain_tilapia==2)
		
		g innovation = 1
		
		collapse(max) adopt_gift (first) hhweight_24, by(a1hhid_combined)
		
		*collapse (sum) adopt_gift [pweight=hhweight_24]
		
		tempfile tilapia_innovation1
		save `tilapia_innovation1', replace
		
		
use "${final_data}${slash}SPIA_BIHS_2024_module_e1_2.dta", clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
		
		keep if e1fish_id == 2 & e1fish_lastyear == 1 //& e1fingerling_lastyear == 1
		
		g adopt_g3 = (e1strain_rohu==4)
		
		g innovation = 2

		collapse(max) adopt_g3 (first) hhweight_24 , by(a1hhid_combined)
		
		*collapse (sum) adopt_g3 [pweight=hhweight_24]
		
		tempfile rohu_innovation1
		save `rohu_innovation1', replace		

*# Small indigenous fish 

		use "${final_data}${slash}SPIA_BIHS_2024_module_e6_7.dta", clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
		
		g adopt_small = (e6fish_species_id == 21)

		collapse(max) adopt_small (first) hhweight_24, by(a1hhid_combined)
		
		*collapse (sum) adopt_small [pweight=hhweight_24]
		
		tempfile small_innovation1
		save `small_innovation1', replace	

		
merge 1:1 a1hhid_combined using `rohu_innovation1' , nogenerate 
merge 1:1 a1hhid_combined using `tilapia_innovation1' , nogenerate 
merge 1:1 a1hhid_combined using `reaper_innovation1' , nogenerate 
merge 1:1 a1hhid_combined using `afp_innovation1' , nogenerate 
merge 1:1 a1hhid_combined using `awd_innovation' , nogenerate 
merge 1:1 a1hhid_combined using `germplasm' , nogenerate 

order hhweight_24 a1hhid_combined adopt_g3 adopt_gift adopt_small cg_lentil cg_potato cg_peanut cg_wheat cg_maize cg_paddy* adopt_AWD ///
adopt_reaper adopt_afp

save "${final_data}${slash}analysis_datasets${slash}aggregate_reach.dta" , replace  

*********** MAKE THE FINAL ESTIMATE ***************
use "${final_data}${slash}analysis_datasets${slash}aggregate_reach.dta", clear 
*# lower bound aggregate  & DNA paddy 
gen cg_lower = 1 if adopt_g3 == 1 | adopt_gift == 1 | /// 
cg_maize  == 1 | cg_potato == 1 | cg_wheat == 1 | cg_peanut == 1 | cg_lentil == 1 | cg_paddy_lb == 1 | ///
dna_paddy_lb == 1 | cg_aus_lb == 1

* upper bound aggregate - boro AWD & DNA paddy 
gen cg_upper = 1 if adopt_g3 == 1 | adopt_gift == 1 | adopt_small == 1 | ///
cg_maize  == 1 | cg_potato == 1 | cg_wheat == 1 | cg_peanut == 1 | cg_lentil == 1 | cg_paddy_lb == 1 | ///
dna_paddy_lb == 1 | cg_aus_lb == 1 | adopt_AWD == 1 | adopt_afp == 1 | adopt_reaper == 1 | cg_paddy_up == 1 | ///
dna_paddy_up == 1 | cg_aus_up == 1


collapse (sum) adopt_g3 adopt_gift adopt_small cg_lentil cg_potato cg_peanut ///
cg_wheat cg_maize cg_paddy_lb cg_paddy_up adopt_AWD adopt_reaper ///
adopt_afp cg_upper dna_paddy_lb dna_paddy_up cg_aus_lb cg_aus_up cg_lower [pweight=hhweight_24]

 foreach var of varlist adopt_g3 adopt_gift adopt_small cg_lentil cg_potato cg_peanut ///
 cg_wheat cg_maize cg_paddy_lb cg_paddy_up adopt_AWD adopt_reaper adopt_afp ///
 cg_upper dna_paddy_lb dna_paddy_up cg_aus_lb cg_aus_up cg_lower {
 	
 	replace `var' = ( `var'/1000000)
 }

order adopt_g3 adopt_gift adopt_small cg_lentil cg_potato cg_peanut cg_wheat ///
cg_maize dna_paddy* cg_paddy* cg_aus* adopt_reaper ///
adopt_afp adopt_AWD cg_upper 

label var adopt_g3 "G3-Rohu (lower) (millions)"
label var adopt_gift "GIFT-Tilapia (lower)  (millions)"
label var adopt_small "Small indigenous fish (upper) (millions)"
label var cg_lentil "Lentils(lower) (millions)"
label var cg_potato  "Potato(lower) (millions)"
label var cg_peanut "Peanut(lower) (millions)"
label var cg_wheat "Wheat(lower) (millions)"
label var cg_maize "Maize(lower) (millions)"
label var cg_paddy_lb "Aman-Self Report(lower) (millions)"
label var cg_paddy_up "Aman-Self Report(upper)  (millions)"
label var cg_aus_lb "Aus-Self Report(lower) (millions)"
label var cg_aus_up "Aus-Self Report(upper) (millions)"
label var dna_paddy_lb "Boro-DNA Report(lower) (millions)"
label var dna_paddy_up "Boro-DNA Report(upper) (millions)"
label var adopt_reaper "Mechanical Reapers(upper) (millions)"
label var adopt_afp "Axial Flow Pump(upper) (millions)"
label var adopt_AWD "AWD method on boro plots(upper) (millions)"
label var cg_lower "Total CG(lower (millions))"
label var cg_upper "Total CG(upper) (millions)"

save "${final_data}${slash}analysis_datasets${slash}aggregate_reach_collapsed.dta" , replace

*** Make the reach estimate graph *** 
use "${final_data}${slash}analysis_datasets${slash}aggregate_reach_collapsed.dta" , clear

rename adopt_g3 cg_g3
rename adopt_gift cg_gift
rename dna_paddy_lb cg_dna_lb
rename dna_paddy_up cg_dna_up 
rename adopt_reaper cg_reaper
rename adopt_afp cg_afp
rename adopt_AWD cg_awd
rename adopt_small cg_sis

gen i = 1 
reshape long cg_  , i(i) j(technology) string

drop if inlist(technology, "lower","upper", "aus_up", "paddy_up", "dna_up") 

replace technology = "GIFT Tilapia" if technology == "gift"
replace technology = "G3-Rohu" if technology == "g3"
replace technology = "Rice varieties: Boro season" if technology == "dna_lb"
replace technology = "Rice varieties: Aman season" if technology == "paddy_lb"
replace technology = "Rice varieties: Aus season" if technology == "aus_lb"
replace technology = "Small Indigenous Species" if technology == "sis"
replace technology = "Axial Flow Pump" if technology == "afp"
replace technology = "Alternate Wetting and Drying" if technology == "awd"
replace technology = "Two-wheeled mechanical reaper" if technology == "reaper"
replace technology = "Potato varieties" if technology == "potato"
replace technology = "Wheat varieties" if technology == "wheat"
replace technology = "Lentil varieties" if technology == "lentil"
replace technology = "Maize varieties" if technology == "maize"
replace technology = "Peanut varieties" if technology == "peanut"


	graph hbar cg_, over(technology, sort(cg_) desc label(labsize(vsmall)) gap(30)) ///
	asyvars showyvars ylabel(0(1)6, labsize(small) noticks nogrid labcolor (black)) ///
	blabel(bar, format(%4.1f) size(vsmall)color (black) position(top)) ///
	bar(1, color("ebblue")) bar(2, color("ebblue")) ///
	bar(3, color("dknavy")) bar(4, color("dknavy ")) bar(5, color("dknavy")) ///
	bar(6, color("dknavy")) bar(7, color("dknavy")) bar(8, color("dknavy"))  ///
	bar(9, color("dknavy")) bar(10, color("dknavy")) bar(11, color("dknavy")) ///
	bar(12, color("ebblue")) bar(13, color("ebblue")) bar(14, color("dknavy")) ///
	title("", ///
	justification(middle) margin(b+1 t-1 l-1) bexpand size(small) color (black)) ///
	ytitle("Million", size(small)) legend(off) ///
	note("", size(vsmall))
graph export "${final_figure}${slash}figure_1.png" , replace 

}

	

******************************************************************************** 
**# APPENDIX ***
********************************************************************************
{
* Appendix M: Further Information on Irrigation Sources
* Figure 51. Primary pump type (%) of agricultural households irrigating in the Boro season
use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
gen agri_control_household=cond(h1_sl == 99, 0, 1)
collapse (max) agri_control_household (first) h1_season hh_type , by(a01 plotid_h1 crop_a_h1)
merge m:1 a01 using "${bihs2018}${slash}158_BIHS sampling weights_r3" , keep(3) nogen keepusing(hhweight)
keep if agri_control_household == 1 
tempfile bihs2018boro
save `bihs2018boro', replace

use "${bihs2018}${slash}022_bihs_r3_male_mod_h2", clear
rename plotid_h2 plotid_h1
rename crop_a_h2 crop_a_h1

merge m:1 a01 plotid_h1 crop_a_h1 using "`bihs2018boro'" , nogenerate keep(3)
order agri_control_household h1_season , after(h2_sl)

label define season 1 "Aman" 2 "Aus" 3 "Boro" 4 "Annual"
label value h1_season season

keep if h1_season == 3 
keep a01 h2_sl agri_control_household h1_season crop_a_h1 h2_01 h2_02 h2_03 hh_type round hhweight

tabulate h2_01, generate(water_source)
tabulate h2_02, generate(pump_type)
tabulate h2_03, generate(fuel_type)

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first) round agri_control_household crop_a_h1 h1_season hh_type ///
(max) water_source* pump_type* fuel_type* hhweight, by(a01 h2_sl)


foreach v of var * {
label var `v' `"`l`v''"'
}

tempfile 2018_plot
save `2018_plot', replace 

preserve
** HH Level collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (first)round hh_type ///
(max) water_source* hhweight, by(a01)

foreach v of var * {
label var `v' `"`l`v''"'
}

tempfile 2018_hh_source
save `2018_hh_source', replace
restore

*** 2nd collapse ********** - get overall estimates

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) water_source* [pweight=hhweight] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 6 7 8 {
    replace water_source`v' = round((water_source`v'*100), 0.1)
}
gen round = 2018

tempfile 2018_ws
save `2018_ws', replace

replace water_source4 = water_source4 + water_source5
replace water_source3 = water_source3 + water_source6
drop water_source6 water_source5

reshape long water_source , i(round) j(source)
rename water_source pct_plots
rename source water_source 
gen year = 2018
drop round

gen water_source_name = ""
replace water_source_name = "Rainfed" if water_source == 1
replace water_source_name = "River" if water_source == 2
replace water_source_name = "Pond/Lake" if water_source == 4 
replace water_source_name = "Canal" if water_source == 3
replace water_source_name = "Groundwater" if water_source == 7 
replace water_source_name = "Other" if water_source == 8 

tempfile 2018water
save `2018water', replace 

****** 2024 ********
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) keepusing(a1division a1district a1upazila a1village hhweight_24) nogenerate
 
keep a1division a1district a1upazila a1village a1hhid_combined a1hhid_plotnum b1plot_num ///
b1agri_activities b1cropping_decision b1plot_fishing b1_operation_status b1repeat_count b1_boro24_utilize ///
b1_aman_utilize b1_aus_utilize b1_boro23_utilize b5* b2crop_season agri_control_household hhweight_24

keep if agri_control_household == 1 
keep if b1_boro23_utilize == 1
keep if inlist(b2crop_season,1) //only retaining current and prior boro season

// Water source 
tabulate b5mainwater_source, generate(water_source)
tabulate b5pump_type, generate(pump_type)
tabulate b5power_source, generate(fuel_type)

** 1st collapse
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) water_source* pump_type* fuel_type* (first) hhweight_24 a1hhid_combined , by(a1hhid_plotnum)

foreach v of var * {
label var `v' `"`l`v''"'
}

tempfile 2024_plot
save `2024_plot', replace

***** HH level 
preserve
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) water_source* hhweight, by(a1hhid_combined)

foreach v of var * {
label var `v' `"`l`v''"'
}


tempfile 2024_hh_source
save `2024_hh_source', replace
restore

//5767 unique Boro 2024 plots 
foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) water_source* [pweight=hhweight_24] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 6 {
    replace water_source`v' = round((water_source`v'*100), 0.1)
}

gen year = 2024
reshape long water_source , i(year) j(source)
rename water_source pct_plots
rename source water_source 

gen water_source_name = "Other" if water_source == 1 
replace water_source_name = "Rainfed" if water_source == 2
replace water_source_name = "River" if water_source == 3
replace water_source_name = "Pond/Lake" if water_source == 4
replace water_source_name = "Canal" if water_source == 5 
replace water_source_name = "Groundwater" if water_source == 6 
 
use `2018_plot', clear
drop if water_source1 == 1 
drop if pump_type1 == 1

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) pump_type* [pweight=hhweight] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 6 7 8 9 10 11 12 13 {
    replace pump_type`v' = round((pump_type`v'*100), 0.1)
}
gen round = 2018

replace pump_type13 = pump_type2 + pump_type3 + pump_type4 + pump_type5 + pump_type6 + pump_type7 +  pump_type13
drop pump_type1 pump_type2 pump_type3 pump_type4 pump_type5 pump_type6 pump_type7 

reshape long pump_type , i(round) j(pump)
gen year = 2018
drop round

gen pump_type_name = ""
replace pump_type_name = "STW" if pump == 8
replace pump_type_name = "DTW" if pump == 9
replace pump_type_name = "LLP" if pump == 10
replace pump_type_name = "Canal" if pump == 11
replace pump_type_name = "AFP" if pump == 12
replace pump_type_name = "Other" if pump == 13

tempfile 2018pump
save `2018pump', replace 


use `2024_plot', clear
drop if water_source2 == 1
drop if pump_type2 == 1

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (mean) pump_type* [pweight=hhweight] 

foreach v of var * {
label var `v' `"`l`v''"'
}

foreach v in 1 2 3 4 5 6 7 8 9 10 11 12 {
    replace pump_type`v' = round((pump_type`v'*100), 0.1)
}
gen round = 2024

replace pump_type1 = pump_type1 + pump_type3 + pump_type4 + pump_type5 + pump_type11 + pump_type12
drop pump_type2 pump_type3 pump_type4 pump_type5 pump_type11 pump_type12 

reshape long pump_type , i(round) j(pump)
gen year = 2024
drop round

gen pump_type_name = "Other" if pump == 1 
replace pump_type_name = "LLP" if pump == 6
replace pump_type_name = "Canal" if pump == 7
replace pump_type_name = "AFP" if pump == 8
replace pump_type_name = "STW" if pump == 9
replace pump_type_name = "DTW" if pump == 10

append using "`2018pump'"
drop pump

gen pump_24 = pump_type if year == 2024 
gen pump_18 = pump_type if year == 2018

graph bar pump_18 pump_24 ,over(pump_type_name, sort(pump_24)) ///
ytitle("Percent of Irrigated Plots", size(small)) /// 
title("Primary Pump Type in Dry Season") ///
ylabel(, noticks nogrid angle(0) labsize(small)) ///
legend(order(1 "2018" 2 "2024") pos(6) cols(2)) ///
bar(1, color(dknavy)) ///
bar(2, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
blabel(bar, position(top) color(black) format(%4.1f) size(vsmall))
graph export "${final_figure}${slash}appendix_figure_51.png" , replace 
*note("Note: Total agricultural households irrigating in boro season(2023/24) ///
* are 1729 and 1995 in 2018. A household can have multiple sources.", size(vsmall))

* Figure 52. Histogram of plots using an axial flow pump in 2024 
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keep(3) nogenerate
keep a1hhid_combined a1hhid_plotnum a01combined_15 a01combined_18 b1plot_num b1repeat_count b1agri_activities ///
b5* b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1plot_status ///
b1_boro23_utilize a1division divisionname a1district a1upazila a1village b1plotsize_decimal hhweight_24

unique(a1hhid_combined)

* agricultural HHs 
gen agri = 1 if b1repeat_count > 0 
keep if agri == 1 
keep if b1agri_activities == 1 

drop if b5mainwater_source == 1 
drop if b5pump_type == 1 

gen AFP = 0 
replace AFP = 1 if b5pump_type == 8

tab b5mainwater_source , gen(water_source)
tab b5alter_water_source , gen(alter_water_source)
 
rename a01combined_18 a01
rename b1plot_num plotid_h1
destring a01 , replace 
gen surface_water = 0 
replace surface_water = 1 if inlist(b5mainwater_source,2,3,4) | inlist(b5alter_water_source,2,3,4)

foreach v of var * {
local l`v' : variable label `v'
if `"`l`v''"' == "" {
local l`v' "`v'"
}
}

collapse (max) AFP agri surface_water (first) b1plot_status b1plotsize_decimal ///
b5relative_height a1division divisionname a1district a1upazila a01combined_15  ///
a1village a01 b1repeat_count a1hhid_plotnum b1agri_activities ///
b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1_boro23_utilize water_source* alter_water_source* ///
b5alter_water_source b5pump_type b5pump_owned hhweight_24, by(a1hhid_combined plotid_h1)

foreach v of var * {
label var `v' `"`l`v''"'
}

collapse (mean) AFP [pweight=hhweight_24] , by(a1village)
gen pct_AFP = round(100*AFP,0.1)

histogram pct_AFP , percent ///
ytitle("Percentage of villages", size(small)) /// 
xtitle("Percentage of AFP plots in villages", size(small)) /// 
title("Histogram of plots that use AFP") ///
ylabel(0(15)60, noticks nogrid angle(0) labsize(small)) ///
xlabel(0(10) 90, noticks nogrid angle(0) labsize(small)) ///
color(dknavy) ///
graphregion(color(white)) ///
plotregion(color(white))
graph export "${final_figure}${slash}appendix_figure_52.png" , replace 
*note("Note: This covers 270 villages in 2024 BIHS.", size(vsmall))


* Figure 53. Division-wise distribution of households using both axial flow pump and tubewells in 2024
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta", clear
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta" , keep(3) nogenerate
keep a1hhid_combined a1hhid_plotnum a01combined_15 a01combined_18 b1plot_num b1repeat_count b1agri_activities ///
b5* b1_boro24_utilize b1_aman_utilize b1_aus_utilize b1plot_status ///
b1_boro23_utilize a1division divisionname a1district a1upazila a1village b1plotsize_decimal hhweight_24

unique(a1hhid_combined) // 5554

gen agri = 1 if b1repeat_count > 0 
keep if agri == 1 
keep if b1agri_activities == 1 

drop if b5mainwater_source == 1 
drop if b5pump_type == 1 

gen AFP = 0 
replace AFP = 1 if b5pump_type == 8

unique(a1hhid_combined) if AFP == 1 //358

tab b5mainwater_source , gen(water_source)
tab b5alter_water_source , gen(alter_water_source)
tab b5pump_type , gen(pump_type)

rename a01combined_18 a01
rename b1plot_num plotid_h1
destring a01 , replace 
gen surface_water = 1 if water_source3 == 1 | water_source4 == 1 | water_source5 == 1 | ///
alter_water_source5 == 1 | alter_water_source6 == 1 | alter_water_source4 == 1 

gen surface_water_check = 1 if inlist(b5mainwater_source,2,3,4) | inlist(b5alter_water_source,2,3,4)
drop surface_water_check
**  2,232 plots with surface water ** 

unique(a1hhid_combined plotid_h1) if AFP == 1 & surface_water == 1 //461
unique(a1hhid_combined plotid_h1) if AFP == 1 // 684

** Look at AFP HHs that have STW/DTW on some other plot/other season
gen TW = 1 if pump_type10 == 1 | pump_type11 == 1 
collapse (max) AFP TW (first) divisionname, by(a1hhid_combined)
gen AFP_TW = 1 if AFP == 1 & TW == 1 
collapse (sum) AFP_TW AFP , by(divisionname) 
gen pct = 100*(AFP_TW/AFP)

graph bar pct ,over(divisionname, sort(pct)) ///
ytitle("Percentage of Households using AFP", size(small)) /// 
title("Division-wise distribution of HHs which use both AFPs and Tubewells") ///
ylabel(, noticks nogrid angle(0) labsize(small)) ///
bar(1, color(dknavy)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
b1title("") ///
blabel(bar, position(top) color(black) format(%4.1f) size(small)) ///
note("Note: Total households using AFPs in 2024 are 358.", size(vsmall))
graph export "${final_figure}${slash}appendix_figure_53.png" , replace 


** Appendix O: Covariates of adoption for additional mechanization innovations: 2-wheel and 4-wheel tractors and shallow tubewells
*** SHALLOW TUBEWELL 
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5.dta" , clear 
keep if agri_control_household == 1 
keep if inlist(b2crop_season,1) 
keep if inlist(b2crop,1,2,3,4,5,6,7,8,9,10,11)
//only retaining current boro season paddy plots

tab b5mainwater_source , gen(b5mainwater_source)
tab b5pump_type , gen(b5pump_type)

drop if b5mainwater_source == 1 // (1,243 observations deleted) rainfed plots 
drop if b5pump_type2 == 1 // 164 observations deleted rainfed plots 

keep a1hhid_plotnum b5mainwater_source* b5pump_type* b5water_management
duplicates drop a1hhid_plotnum , force 
tempfile stw 
save "`stw'"

use "${final_data}${slash}analysis_datasets/All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`stw'",  nogenerate keep(3)

missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep b5pump_type7 $cont_vars $cat_vars a1village

eststo multivariate: regress b5pump_type7 $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress b5pump_type7 `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("Shallow Tubewell [adoption rate:52%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) /// 
note("N: 3765" , size(vsmall))
graph export  "${final_figure}${slash}appendix_figure_55.png", replace as(png)

* 3765 plots

** 4-WHEELED POWER TILLER 
use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta" , clear
missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep b4machine_type_2 $cont_vars $cat_vars a1village

eststo multivariate: regress b4machine_type_2 $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress b4machine_type_2 `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("4-Wheeled Power Tiller [adoption rate:32%]", size(small)) ///
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 19268" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}go.gph", replace

* 19268 - plots 

*** 2-WHEELED POWER TILLER 
use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta", clear 

missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep b4machine_type_1 $cont_vars $cat_vars a1village

eststo multivariate: regress b4machine_type_1 $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress b4machine_type_1 `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("2-Wheeled Power Tiller [adoption rate:67%]", size(small)) /// 
legend(off) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 19268" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gp.gph", replace

grc1leg "${final_figure}${slash}temporary_graphs${slash}go.gph" "${final_figure}${slash}temporary_graphs${slash}gp.gph" , legendfrom("${final_figure}${slash}temporary_graphs${slash}go.gph") pos(3) cols(2) ///
graphregion(color(white)) /// 
ysize(10) ///
xsize(6) ///
l1title("", size(small))
graph export "${final_figure}${slash}appendix_figure_54.png", replace as(png)


** Appendix P: Covariates of adoption for additional CGIAR variety innovations: Boro and Aman Paddy Self -Reports

** AMAN SELF REPORTS ** 
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5" , clear  // Identify which plots these are before running the regression
keep if b2crop_season == 2   

gen cg_variety = 0
replace cg_variety = 1 if inlist(b2paddy_variety, 24, 25, 27, 39, 46, 50, 51, 54, 55, 56, 61, 63, 65, 66, 70, 71, 73, 74, 75, 76, 77, 78, 84, 86, 99, 101, 137, 139, 140, 145, 146, 149, 152, 155, 156, 157, 158, 160, 161, 178, 3, 4, 8, 10, 11, 12, 13, 19, 30, 48, 69, 1, 2, 6, 15, 98, 88, 28, 68, 45, 67, 95, 14, 16, 17, 18, 22, 31, 40, 42, 43, 52, 57, 62, 80, 87, 90, 91, 100, 101, 133, 134, 135, 144, 21, 23, 29, 34, 35, 47, 49, 96, 141)

collapse (max) cg_variety (first) a1hhid_combined , by(a1hhid_plotnum)

tempfile cg_paddy
save "`cg_paddy'" , replace 

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`cg_paddy'" , nogenerate keep(3)

** Run the correlates regression
missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep cg_variety $cont_vars $cat_vars a1village

eststo multivariate: regress cg_variety $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress cg_variety `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("CGIAR-Variety Aman Paddy Self-Report[adoption rate:38.7%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 4141" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gt.gph", replace

* any work on aman plots: 4141

** BORO SELF REPORTS *** 
use "${final_data}${slash}SPIA_BIHS_2024_module_b1_5" , clear  // Identify which plots these are before running the regression
keep if b2crop_season == 1 

gen cg_variety = 0
replace cg_variety = 1 if inlist(b2paddy_variety, 24, 25, 27, 39, 46, 50, 51, 54, 55, 56, 61, 63, 65, 66, 70, 71, 73, 74, 75, 76, 77, 78, 84, 86, 99, 101, 137, 139, 140, 145, 146, 149, 152, 155, 156, 157, 158, 160, 161, 178, 3, 4, 8, 10, 11, 12, 13, 19,30, 48, 69, 1, 2, 6, 15, 98, 88, 28, 68, 45, 67, 95, 14, 16, 17, 18, 22, 31, 40, 42, 43, 52, 57, 62, 80, 87, 90, 91, 100, 101, 133, 134, 135, 144, 21, 23, 29, 34, 35, 47, 49, 96, 141)

collapse (max) cg_variety (first) a1hhid_combined , by(a1hhid_plotnum)

tempfile cg_paddy
save "`cg_paddy'" , replace 

use "${final_data}${slash}analysis_datasets${slash}All_covariates.dta"  , clear 
merge 1:1 a1hhid_plotnum using "`cg_paddy'" , nogenerate keep(3)

** Run the correlates regression
missings dropvars , force

foreach var of varlist b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings {
egen z_`var' = std(`var')
local label : var label `var'
label variable z_`var' "`label'"
}

drop b1plot_distance b2area b5distance_pump total_b2area a2hhroster_count a2mem_age a6_hh_savings num_lands pc_expm
rename std_hh_asset_index z_hh_asset_index
order b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2 b1soil_type3 b1soil_type4 , after(lit_can_read_write)
order z_hh_asset_index , after(z_a6_hh_savings)
order z_* , after(b1soil_type4)

* Create the global 
global cont_vars z_b1plot_distance z_b2area z_b5distance_pump z_total_b2area z_a2hhroster_count z_a2mem_age z_a6_hh_savings z_hh_asset_index

global cat_vars a2agri_decision_gender a4employment_status con_bottom20 religion_islam lit_can_read_write ///
b5additional_pipe b5relative_height1 b5relative_height2 b1soil_type1 b1soil_type2  ///
b1soil_type3 b1soil_type4

global dum_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write b5additional_pipe

keep cg_variety $cont_vars $cat_vars a1village

eststo multivariate: regress cg_variety $cont_vars $cat_vars , cluster(a1village)

foreach var in $cont_vars $dum_vars  {
quietly eststo `var': regress cg_variety `var'
}

coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
ylabel(, labsize(vsmall) nogrid) ///
xlabel(, nogrid) ///
headings(z_b1plot_distance = "{bf:Continuous Variables:Plot}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
b5additional_pipe = "{bf:Categorical Variables:Plot}" a4employment_status = "{bf:Categorical Variables:HH}", labcolor(black) labsize(vsmall))  ///
graphregion(color(white)) plotregion(color(white)) ///
title("CGIAR-Variety Boro Paddy Self-Report[adoption rate:56%]", size(small)) /// 
legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
ciopts(recast(rcap)) /// 
p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy))) ///
note("N: 5776" , size(vsmall))
graph save "${final_figure}${slash}temporary_graphs${slash}gu.gph", replace

grc1leg "${final_figure}${slash}temporary_graphs${slash}gu.gph" "${final_figure}${slash}temporary_graphs${slash}gt.gph", legendfrom("${final_figure}${slash}temporary_graphs${slash}gt.gph") pos(3) cols(2)  ///
graphregion(color(white)) /// 
l1title("", size(small))
graph export "${final_figure}${slash}appendix_figure_56.png", replace as(png)

}
********************************************************************************

	**# Graph details
	
	set scheme s1mono
	 graph set window fontface "Calibri"
	
	
	grstyle init
	grstyle color background white
	
	global skyblue "86 180 233"
	global blue "0 114 178"
	global teal "17 222 245"
	global orange "213 94 0"
	global green "0 158 115"
	global yellow "230 159 0"
	global purple "204 121 167"
	global lavendar "154 121 204"
	global cherry "200 0 0"
    global tangerine "255 86 29"

	
	**sequential color
	global blue1 "158 202 225"
	global blue2 "66 146 198"
	global blue3 "8 81 156"
	
	global purple1 "188 189 220"
	global purple2 "128 125 186"
	global purple3 "84 39 143"
	
		**# 5.1	Crop Agriculture Trends
	* Figure 6. Incidence of cultivation of major crops in Bangladesh (2011-2024)
	
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	
	collapse(max) agri_control_household (first) hhweight_24 a01*, by(a1hhid_combined)
	
	tempfile bihs2024
	save `bihs2024', replace
	
	g agri_id = 1
	
	collapse(sum) agri_control_household, by(agri_id)
	
	

	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	
		
	keep if agri_control_household > 0
	
	gen boro_hh = (b2paddy_variety !=. | b2paddy_intercrop_variety != .) & b2crop_season == 1
	
	gen aman_hh = (b2paddy_variety !=. | b2paddy_intercrop_variety != .) & b2crop_season == 2
	
	g maize_hh = (b2maize_variety !=. | b2maize_intervariety != .) & b2crop_season == 1
	
	g potato_hh = (b2potato_variety !=. | b2potato_intervariety != "") & b2crop_season == 1
	
	g wheat_hh = (b2wheat_variety !=. | b2wheat_intervariety != .) & b2crop_season == 1
	
	g peanut_hh = (b2peanut_variety !=. | b2peanut_intervariety != .) & b2crop_season == 1
	
	g lentil_hh = (b2lentil_variety !=. | b2lentil_intervariety != .) & b2crop_season == 1
	
	collapse(max) *_hh, by(a1hhid_combined)
	
	merge 1:1 a1hhid_combined using `bihs2024'
	
	
	
	g round = 2024
	
	collapse(mean) agri_control_household_ratio = agri_control_household boro_hh_ratio ///
	= boro_hh aman_hh_ratio = aman_hh maize_hh_ratio = maize_hh potato_hh_ratio = potato_hh wheat_hh_ratio ///
	= wheat_hh peanut_hh_ratio = peanut_hh lentil_hh_ratio = lentil_hh ///
	[pweight=hhweight_24], by(round)
	
	tempfile bihs2024boro
	save `bihs2024boro', replace
	
	u "${final_data}${slash}SPIA_BIHS_2024_module_a1", clear
	
	collapse(max) a1division hhweight*, by(divisionname)
	
	tempfile div_weight
	save `div_weight', replace
	
	use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
	

	g agri_control	= cond(h1_sl == 99, 0, 1)
	
	collapse (max) agri_control, by(a01)
	
	tempfile bihs2018agri
	save `bihs2018agri', replace
	
	use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
	
	drop if sl_l1 == 0 | pondid_l1==999
	
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs2018agri', nogen
	
	g agri_control_household = (fishing_hh== 1 | agri_control == 1)

	collapse (max) agri_control_household, by(a01)
	
		
	tempfile bihs2018boro
	save `bihs2018boro', replace
	
	use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
	drop if h1_sl == 99
	
	gen aman_hh = (inrange(crop_a_h1, 10, 20) | inrange(crop_b_h1, 10, 20))  & h1_season==1
	
	gen boro_hh = (inrange(crop_a_h1, 10, 20) | inrange(crop_b_h1, 10, 20))  & h1_season==3
	
	g maize_hh = (crop_a_h1 == 23 | crop_b_h1 == 23) & h1_season==3 
	
	g potato_hh = (crop_a_h1 == 411 | crop_b_h1 == 411) & h1_season==3 
	
	gen wheat_hh = (inrange(crop_a_h1, 21, 22) | inrange(crop_b_h1, 21, 22))  & h1_season==3
		
	g peanut_hh = (crop_a_h1 == 64 | crop_b_h1 == 64) & h1_season==3
	
	g lentil_hh = (crop_a_h1 == 51 | crop_b_h1 == 51) & h1_season==3
		
	collapse (max) *_hh, by(a01)
	
	
	merge 1:1 a01 using `bihs2018boro', nogen
	recode aman_hh . = 0 if agri_control_household == 1
	recode boro_hh . = 0 if agri_control_household == 1
	recode maize_hh . = 0 if agri_control_household == 1
	recode potato_hh . = 0 if agri_control_household == 1
	recode wheat_hh . = 0 if agri_control_household == 1
	recode peanut_hh . = 0 if agri_control_household == 1
	recode lentil_hh . = 0 if agri_control_household == 1
	
	merge 1:1 a01 using "${bihs2018}${slash}009_bihs_r3_male_mod_a", keepusing(dvcode div_name) nogen keep(3)
	ren (dvcode div_name) (a1division divisionname)
	
	merge m:1 divisionname using `div_weight', nogen 
	
	g round = 2018
	
	collapse(mean) agri_control_household_ratio = agri_control_household boro_hh_ratio ///
	= boro_hh aman_hh_ratio = aman_hh maize_hh_ratio = maize_hh potato_hh_ratio = potato_hh wheat_hh_ratio ///
	= wheat_hh peanut_hh_ratio = peanut_hh lentil_hh_ratio = lentil_hh ///
	[pweight=hhweight_18], by(round)
	
	tempfile bihs2018
	save `bihs2018', replace
	
	use "${bihs2015}${slash}015_r2_mod_h1_male", clear
	drop if hh_type == 1
	g agri_control	= cond(h1_sl == 99, 0, 1)
	
	collapse (max) agri_control, by(a01)
	
	tempfile bihs2015agri
	save `bihs2015agri', replace
	
	u "${bihs2015}${slash}037_r2_mod_l1_male", clear
	drop if l1_sl == 99 | pondid == 999
	drop if hh_type == 1
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs2015agri', nogen
	
	g agri_control_household = (fishing_hh== 1 | agri_control == 1)
		
	tempfile bihs2015boro
	save `bihs2015boro', replace
	
	use "${bihs2015}${slash}015_r2_mod_h1_male", clear
	drop if h1_sl == 99
	drop if hh_type == 1
	gen aman_hh = (inrange(crop_a, 10, 20) | inrange(crop_b, 10, 20))  & h1_season==1
	gen boro_hh = (inrange(crop_a, 10, 20) | inrange(crop_b, 10, 20))  & h1_season==3
	g maize_hh = (crop_a == 23 | crop_b == 23) & h1_season==3 
	g potato_hh = (crop_a == 411 | crop_b == 411) & h1_season==3 
	gen wheat_hh = (inrange(crop_a, 21, 22) | inrange(crop_b, 21, 22))  & h1_season==3
	g peanut_hh = (crop_a == 64 | crop_b == 64) & h1_season==3
	g lentil_hh = (crop_a == 51 | crop_b == 51) & h1_season==3
		
	collapse (max) *_hh, by(a01)
	
	merge 1:1 a01 using `bihs2015boro', nogen
	recode aman_hh . = 0 if agri_control_household == 1
	recode boro_hh . = 0 if agri_control_household == 1
	recode maize_hh . = 0 if agri_control_household == 1
	recode potato_hh . = 0 if agri_control_household == 1
	recode wheat_hh . = 0 if agri_control_household == 1
	recode peanut_hh . = 0 if agri_control_household == 1
	recode lentil_hh . = 0 if agri_control_household == 1
	
	merge 1:1 a01 using "${bihs2015}${slash}001_r2_mod_a_male", keepusing(dvcode div_name) nogen keep(3)
	ren (dvcode div_name) (a1division divisionname)
	
	merge m:1 divisionname using `div_weight', nogen 
	
	g round = 2015
	
	collapse(mean) agri_control_household_ratio = agri_control_household boro_hh_ratio ///
	= boro_hh aman_hh_ratio = aman_hh maize_hh_ratio = maize_hh potato_hh_ratio = potato_hh wheat_hh_ratio ///
	= wheat_hh peanut_hh_ratio = peanut_hh lentil_hh_ratio = lentil_hh ///
	[pweight=hhweight_15], by(round)
	
	tempfile bihs2015
	save `bihs2015', replace
	
	
	use "${bihs2012}${slash}011_mod_h1_male", clear
	
	gen boro_hh = (inrange(crop_a, 11, 20) | inrange(crop_b, 11, 20))  & ///
	(inrange(h1_04b, 11, 12) | inrange(h1_04b, 1, 2))
	gen aman_hh = (inrange(crop_a, 11, 20) | inrange(crop_b, 11, 20))  & ///
	inrange(h1_04b, 6, 9)
	g maize_hh = (crop_a == 23 | crop_b == 23) & inrange(h1_04b, 10, 12) 
	g potato_hh = (crop_a == 411 | crop_b == 411) & inrange(h1_04b, 10, 12)
	gen wheat_hh = (inrange(crop_a, 21, 22) | inrange(crop_b, 21, 22))  & inrange(h1_04b, 10, 12)
	g peanut_hh = (crop_a == 64 | crop_b == 64) & inrange(h1_04b, 10, 12)
	g lentil_hh = (crop_a == 51 | crop_b == 51) & inrange(h1_04b, 10, 12)
	
	collapse (max) *_hh, by(a01)
	
	g agri_control	= 1
	
	tempfile bihs2012agri
	save `bihs2012agri', replace
	
	u "${bihs2012}${slash}026_mod_l1_male", clear
	drop if pondid == 999
	
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs2012agri', nogen
	
	g agri_control_household = (fishing_hh== 1 | agri_control == 1)
			
	tempfile bihs2012boro
	save `bihs2012boro', replace
		
	use "${bihs2012}${slash}001_mod_a_male", clear
	keep a01 Sample_type dcode div_name
			
	merge 1:1 a01 using `bihs2012boro', nogen
	
	drop if Sample_type==1
	
	drop Sample_type
	recode aman_hh . = 0 if agri_control_household == 1
	recode boro_hh . = 0 if agri_control_household == 1
	recode maize_hh . = 0 if agri_control_household == 1
	recode potato_hh . = 0 if agri_control_household == 1
	recode wheat_hh . = 0 if agri_control_household == 1
	recode peanut_hh . = 0 if agri_control_household == 1
	recode lentil_hh . = 0 if agri_control_household == 1

	ren (dcode div_name) (a1division divisionname)
	
	merge m:1 divisionname using `div_weight', nogen
	
	g round = 2012
	
	recode agri_control_household . = 0
	
	collapse(mean) agri_control_household_ratio = agri_control_household boro_hh_ratio ///
	= boro_hh aman_hh_ratio = aman_hh maize_hh_ratio = maize_hh potato_hh_ratio = potato_hh wheat_hh_ratio ///
	= wheat_hh peanut_hh_ratio = peanut_hh lentil_hh_ratio = lentil_hh ///
	[pweight=hhweight_12], by(round)
	
	tempfile bihs2012
	save `bihs2012', replace
	
	append using `bihs2015'
	
	append using `bihs2018'
	
	append using `bihs2024boro'
	
	tempfile agri_control_final
	save `agri_control_final', replace
	
	g agri_control_pct = round(agri_control_household_ratio*100, .01)
	g aman_hh_pct = round(aman_hh_ratio*100, .01)
	g boro_hh_pct = round(boro_hh_ratio*100, .01)
	g maize_hh_pct = round(maize_hh_ratio*100, .01)
	g potato_hh_pct = round(potato_hh_ratio*100, .01)
	g wheat_hh_pct = round(wheat_hh_ratio*100, .01)
	g lentil_hh_pct = round(lentil_hh_ratio*100, .01)
	g peanut_hh_pct = round(peanut_hh_ratio*100, .01)
	
	la var agri_control_pct "Agricultural Household (%)"
	la var aman_hh_pct "Aman Household/Agri HH (%)"
	la var boro_hh_pct "Boro Household/Agri HH (%)"
	la var maize_hh_pct "Maize HH/Agri HH in Rabi (%)"
	la var potato_hh_pct "Potato HH/Agri HH in Rabi (%)"
	la var wheat_hh_pct "Wheat HH/Agri HH in Rabi (%)"
	la var lentil_hh_pct "Lentil HH/Agri HH in Rabi (%)"
	la var peanut_hh_pct "Peanut HH/Agri HH in Rabi (%)"
		
	scatter boro_hh_pct round, color("${blue") connect(l) mlabposition(9) mlabel() ///
	msymbol(T) xlabel(, nogrid) ylabel(, nogrid) || ///
	scatter aman_hh_pct round, color("${lavendar") connect(l) mlabposition(9) mlabel() ///
	msymbol(S) xlabel(, nogrid) ylabel(, nogrid) || ///
	scatter maize_hh_pct round, ///
	color("${purple") connect(l) mlabposition(10) mlabel() mlabsize(vsmall) ///
	msymbol(O) xlabel(, nogrid) ylabel(, nogrid) || scatter potato_hh_pct round, ///
	color("${orange") connect(l) mlabposition(2) mlabel() mlabsize(vsmall) ///
	msymbol(S) xlabel(, nogrid) ylabel(, nogrid) || scatter wheat_hh_pct round, ///
	color("${teal") connect(l) mlabposition(9) mlabel() mlabsize(vsmall) ///
	msymbol(D) xlabel(, nogrid) ylabel(, nogrid) ///
	plotregion(fcolor(white)) legend(position(6) cols(2) size(tiny))
	
	graph export "${final_figure}${slash}figure_6.png", replace as(png)
		
	**# 5.2	Agricultural Entries and Exits
	* Figure 7. Time trend in households participating in agriculture in Bangladesh (2011- 2024)
	* Figure 8. Proportion of agricultural households in 2018-19 (left panel), proportion of net agricultural exits in 2024 (right panel)
	* Figure 9. Foreign remittances as a main earning source by division (%)
	* Table 12. Comparison of wealth measures for households remaining in vs exiting agriculture using t-test
	* Table 13. Comparison of wealth measures for households outside agriculture vs entering agriculture using t-test
		
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	collapse(max) agri_control_household (first) hhweight* a01* a1split_hh_serial a1split_hh a1district a1division districtname divisionname, by(a1hhid_combined)
	
	tempfile exit2024
	save `exit2024', replace
	
	collapse(max) agri_control_household (first) hhweight* a1split_hh_serial a1split_hh a1district a1division districtname divisionname, by(a01combined_18)
	
	tempfile agri_18
	save `agri_18', replace
	

	use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
	

	g agri_control	= cond(h1_sl == 99, 0, 1)
	
	collapse (max) agri_control, by(a01)
	
	tempfile bihs18agri
	save `bihs18agri', replace
	
	use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
	
	drop if sl_l1 == 0 | pondid_l1==999
	
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs18agri', nogen
	
	g agri_control_household_18 = (fishing_hh== 1 | agri_control == 1)

	collapse (max) agri_control_household_18, by(a01)
	
	tempfile bihs18exit
	save `bihs18exit', replace
	
	tostring a01, replace
	ren a01 a01combined_18
	
	merge 1:m a01combined_18 using `exit2024', nogen keep(3)
		
	g agri_exit =  (agri_control_household == 0 & agri_control_household_18 == 1)
	
	g agri_entry = agri_control_household if agri_control_household_18 == 0
	recode agri_entry . = 0

	tempfile bihs24_18exit
	save `bihs24_18exit', replace
	
	preserve
	
	collapse(max) agri_control_household_18, by(a01combined_15)
	
	tempfile bihs18id
	save `bihs18id', replace
	
	restore
	
	g round = 2024
	
	collapse(mean) agri_exit_ratio = agri_exit agri_entry_ratio = agri_entry [pweight=hhweight_24], by(round)
	
	tempfile bihs24_18coll
	save `bihs24_18coll', replace
	
	
	use "${bihs2015}${slash}015_r2_mod_h1_male", clear
	drop if hh_type == 1
	g agri_control	= cond(h1_sl == 99, 0, 1)
	
	collapse (max) agri_control, by(a01)
	
	tempfile bihs2015agri
	save `bihs2015agri', replace
	
	u "${bihs2015}${slash}037_r2_mod_l1_male", clear
	drop if l1_sl == 99 | pondid == 999
	drop if hh_type == 1
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs2015agri', nogen
	
	g agri_control_household_15 = (fishing_hh== 1 | agri_control == 1)
		
	
	merge 1:1 a01 using "${bihs2015}${slash}001_r2_mod_a_male", keepusing(dvcode div_name) nogen keep(3)
	
	tempfile bihs15split
	save `bihs15split', replace
	
		
	merge 1:1 a01 using `bihs18exit', keep(2 3)
	
	preserve
	drop agri_control_household_15 dvcode div_name
	keep if _merge == 2
	
	tostring a01, replace
	split a01, p(.) g(a01new)
	drop _merge
	ren (a01new1 a01) (a01 a01combined_18)
	
	
	destring a01, replace
	merge m:1 a01 using `bihs15split'
	
	
	
	tempfile two_split
	save `two_split', replace
	drop agri_control_household_15 dvcode div_name
	keep if _merge == 1
	
	
	
	g split_sl = substr(a01new2, 1, 1)
	drop a01combined_18 
	ren a01 a01temp
	
	egen: a01 = concat(a01temp split_sl), p(.)
	destring a01, replace
	merge m:1 a01 using `bihs15split', nogen keep(3)
	
	tempfile two_split_1
	save `two_split_1', replace
	
	u `two_split', clear
	
	keep if _merge == 3
	
	append using `two_split_1'
	
	keep a01 fishing_hh agri_control agri_control_household_15 dvcode div_name agri_control_household_18 
	
	tempfile two_split_fin
	save `two_split_fin', replace
	
	
	restore
	
	keep if _merge == 3
	
	drop _merge
	
	append using `two_split_fin'
	
	ren div_name divisionname
	
	merge m:1 divisionname using `div_weight', nogen 
		
	
	g agri_exit =  (agri_control_household_18 == 0 & agri_control_household_15 == 1)
	
	
	g agri_entry = agri_control_household_18 if agri_control_household_15 == 0
	recode agri_entry . = 0
	
	
	g round = 2018
	
	collapse(mean) agri_exit_ratio = agri_exit agri_entry_ratio = agri_entry ///
	[pweight=hhweight_18], by(round)
	
	tempfile bihs18_15exit
	save `bihs18_15exit', replace
	
	
	use "${bihs2012}${slash}011_mod_h1_male", clear
	
	g agri_control	= 1
	
	collapse (max) agri_control, by(a01)
	
	tempfile bihs2012agri
	save `bihs2012agri', replace
	
	u "${bihs2012}${slash}026_mod_l1_male", clear
	drop if pondid == 999
	
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs2012agri', nogen
				
	tempfile bihs2012boro
	save `bihs2012boro', replace
		
	use "${bihs2012}${slash}001_mod_a_male", clear
	keep a01 Sample_type
	
			
	merge 1:1 a01 using `bihs2012boro', nogen
	
	drop if Sample_type==1
	
	drop Sample_type
	
	g agri_control_household_12 = (fishing_hh== 1 | agri_control == 1)
		
	preserve
	u `bihs15split', clear
	ren div_name divisionname
	
	drop fishing_hh agri_control
	tostring a01, replace
	split a01, p(.) g(a01new)
	
	ren (a01new1 a01) (a01 a01combined_15)
	destring a01*, replace
	tempfile a15p_g
	save `a15p_g', replace
	
	restore
	
	merge 1:m a01 using `a15p_g', nogen keep(3)

	merge m:1 divisionname using `div_weight', nogen 
	
	g agri_exit =  (agri_control_household_15 == 0 & agri_control_household_12 == 1)

	g agri_entry = agri_control_household_15 if agri_control_household_12 == 0
	recode agri_entry . = 0

	g round = 2015

	collapse(mean) agri_exit_ratio = agri_exit agri_entry_ratio = agri_entry ///
	[pweight=hhweight_15], by(round)
	
	append using `bihs24_18coll'
	
	append using `bihs18_15exit'

	merge 1:1 round using `agri_control_final'
	
	g agri_control_pct = round(agri_control_household_ratio*100, .01)
	g agri_exit_pct = round(agri_exit_ratio*100, .01)
	g agri_entry_pct = round(agri_entry_ratio*100, .01)
	
	la var agri_control_pct "Agricultural Household/All HH (%)"	
	la var agri_exit_pct "Agri Exit HH/All HH (%)"
	la var agri_entry_pct "Agri Entry HH/All HH (%)"

	sort round
	scatter agri_control_pct round, color("${blue") connect(l) mlabposition(9) mlabel(agri_control_pct) ///
	msymbol(T) xlabel(, nogrid) ylabel(, nogrid) || scatter agri_exit_pct round, ///
	color("${purple") connect(l) mlabposition(12) mlabel(agri_exit_pct) mlabsize(vsmall) ///
	msymbol(O) xlabel(, nogrid) ylabel(, nogrid) || scatter agri_entry_pct round, ///
	color("${orange") connect(l) mlabposition(4) mlabel(agri_entry_pct) mlabsize(vsmall) ///
	msymbol(S) xlabel(, nogrid) ylabel(, nogrid) ///
	plotregion(fcolor(white)) legend(position(6) cols(2) size(tiny))
	
	graph export "${final_figure}${slash}figure_7.png", replace as(png)
		
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	
	collapse(max) agri_control_household (first) hhweight* a01* a1split_hh_serial a1split_hh a1district a1division districtname divisionname, by(a1hhid_combined)
	
	tempfile exit2024
	save `exit2024', replace
	
	collapse (first) hhweight* a1split_hh_serial a1split_hh a1district a1division districtname divisionname, by(a01combined_18)
	
	tempfile agri_18
	save `agri_18', replace
	

	use "${bihs2018}${slash}021_bihs_r3_male_mod_h1", clear
	

	g agri_control	= cond(h1_sl == 99, 0, 1)
	
	collapse (max) agri_control, by(a01)
	
	tempfile bihs18agri
	save `bihs18agri', replace
	
	use "${bihs2018}${slash}051_bihs_r3_male_mod_l1", clear
	
	drop if sl_l1 == 0 | pondid_l1==999
	
	g fishing_hh = 1
	
	collapse(max) fishing_hh, by(a01)
	
	merge 1:1 a01 using `bihs18agri', nogen
	
	g agri_control_household_18 = (fishing_hh== 1 | agri_control == 1)

	collapse (max) agri_control_household_18, by(a01)
	
	tostring a01, replace
	ren a01 a01combined_18
	
	preserve 
	merge 1:1 a01combined_18 using `agri_18', nogen keep(1 3)
	
	replace districtname = "Brahamanbaria"  if districtname ==  "Brahmanbaria"
	replace districtname = "Nawabganj"  if districtname == "Chapai Nawabganj"
	replace districtname = "Jhenaidah"  if districtname == "Jhenaidah Zila T"
	
	ren districtname ADM2_EN
	
	merge m:1 ADM2_EN using "${temp_data}${slash}district_admin_new", nogen keep(3)
	
	
	collapse(mean) agri_control_household_18 [pweight=hhweight_18], by(ADM1_EN)
		
	replace agri_control_household_18 = round(agri_control_household_18, 0.01)
	
	tempfile exit2018_control
	save `exit2018_control', replace
	
	restore
	
	merge 1:m a01combined_18 using `exit2024', nogen keep(3)
	
	tempfile ttest_exit
	save `ttest_exit', replace
	
	
	g agri_exit =  (agri_control_household == 0 & agri_control_household_18 == 1)
	g agri_entry = agri_control_household if agri_control_household_18 == 0
	recode agri_entry . = 0

	tempfile exit_nonexit_hh
	save `exit_nonexit_hh', replace
	
	preserve 
		
	u "${final_data}${slash}SPIA_BIHS_2024_module_a2_4.dta", clear
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen
	
	collapse (first) a4earning_source* districtname divisionname hhweight_24, by(a1hhid_combined)
	
	replace districtname = "Brahamanbaria"  if districtname ==  "Brahmanbaria"
	replace districtname = "Nawabganj"  if districtname == "Chapai Nawabganj"
	replace districtname = "Jhenaidah"  if districtname == "Jhenaidah Zila T"
	
	ren districtname ADM2_EN
	
	merge m:1 ADM2_EN using "${temp_data}${slash}district_admin_new", nogen keep(3)
		
	tempfile exit_nonexit_saving
	save `exit_nonexit_saving', replace
	
	restore
	
	
	preserve
	
	keep if agri_entry == 1 
	
	tempfile entry_hh
	save `entry_hh', replace
	
	u `exit_nonexit_saving', clear
		
	merge 1:1 a1hhid_combined using `entry_hh', nogen keep(3)
	
	tempfile entry_earning
	save `entry_earning', replace
	
	restore
	
	
	preserve
	
	keep if agri_exit == 1 
	
	tempfile exit_hh
	save `exit_hh', replace
	
	u `exit_nonexit_saving', clear
		
	merge 1:1 a1hhid_combined using `exit_hh', nogen keep(3)
	
	tempfile exit_earning
	save `exit_earning', replace
	
	restore 
	
	preserve
	
	replace districtname = "Brahamanbaria"  if districtname ==  "Brahmanbaria"
	replace districtname = "Nawabganj"  if districtname == "Chapai Nawabganj"
	replace districtname = "Jhenaidah"  if districtname == "Jhenaidah Zila T"
	
	ren districtname ADM2_EN
	
	merge m:1 ADM2_EN using "${temp_data}${slash}district_admin_new", nogen keep(3)
	
	
	collapse(mean) agri_exit [pweight=hhweight_24], by(ADM1_EN)
		
	replace agri_exit = round(agri_exit, 0.01)
	
	tempfile exit2018_division
	save `exit2018_division', replace
	
	
	restore
		
	u "${temp_data}${slash}division_admin", clear
	ren (new_ID) (_ID)
		
	merge 1:m ADM1_EN using `exit2018_division', nogen keep(3)
			
	preserve
			
	merge 1:m _ID using "${temp_data}${slash}division_coor", nogen keep(3)
			
	save "${temp_data}${slash}division_admin_coor", replace
			
	restore
			
			
	u "${temp_data}${slash}division_admin", clear
	ren (new_ID) (_ID)
	merge 1:m ADM1_EN using `exit2018_control', nogen keep(3)
			
	spmap agri_control_household_18 using "${temp_data}${slash}division_coor", id(_ID) ///
	label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
	label(ADM1_EN) pos(0 0) color(white) size(vsmall)) ///
	fcolor(Blues2) clnumber(4)  clbreaks(.16 .24 .26 .29 .34) title("", size(small)) ///
	name(heat0, replace)
	
	u `exit_nonexit_hh', clear
		
	replace districtname = "Brahamanbaria"  if districtname ==  "Brahmanbaria"
	replace districtname = "Nawabganj"  if districtname == "Chapai Nawabganj"
	replace districtname = "Jhenaidah"  if districtname == "Jhenaidah Zila T"
	
	ren districtname ADM2_EN
	
	merge m:1 ADM2_EN using "${temp_data}${slash}district_admin_new", nogen keep(3)
		
	collapse(mean) agri_entry [pweight=hhweight_24], by(ADM1_EN)
		
	replace agri_entry = round(agri_entry, 0.01)
	
	tempfile entry2018_division
	save `entry2018_division', replace
	
	merge 1:1 ADM1_EN using `exit2018_division'
	
	g net_agri_exit = agri_exit - agri_entry
	
	tempfile exit_entry_division
	save `exit_entry_division', replace
	
	
	u "${temp_data}${slash}division_admin", clear
		
		
	ren (new_ID) (_ID)
			
		
	merge 1:m ADM1_EN using `exit_entry_division', nogen keep(3)
		
	replace net_agri_exit = round(net_agri_exit, 0.01)
		
	spmap net_agri_exit using "${temp_data}${slash}division_coor", id(_ID) ///
	label(data("${temp_data}${slash}division_admin_coor") xcoor(x_center) ycoor(y_center) ///
	label(ADM1_EN) pos(0 0) color(white) size(vsmall)) ///
	fcolor(Blues2) clnumber(3)  clbreaks(-0.03 0.05 0.1) title("", size(small)) ///
	 name(heat4, replace)

	gr combine heat0 heat4, row(1)
		
	graph export "${final_figure}${slash}figure_8.png", replace as(png)
	
	u `exit_earning', clear
		
	g freq = (a4earning_source1 == 68) | (a4earning_source2 == 68)
	
    
    collapse (mean) freq [pweight=hhweight_24], by(ADM1_EN)
	
	encode ADM1_EN, g(adm1en)
	
	g order = .
	recode order . = 1.3 if ADM1_EN == "Chittagong"
	recode order . = 2.3 if ADM1_EN == "Dhaka"
	recode order . = 3.3 if ADM1_EN == "Sylhet"
	recode order . = 4.3 if ADM1_EN == "Khulna"
	recode order . = 5.3 if ADM1_EN == "Barisal"
	recode order . = 6.3 if ADM1_EN == "Rajshahi"
	recode order . = 7.3 if ADM1_EN == "Mymensingh"
	recode order . = 8.3 if ADM1_EN == "Rangpur"
	
	replace ADM1_EN = "Exit" if ADM1_EN == "Chittagong"
	replace ADM1_EN = " Exit" if ADM1_EN == "Dhaka"
	replace ADM1_EN = "Exit " if ADM1_EN == "Sylhet"
	replace ADM1_EN = "Exit  " if ADM1_EN == "Khulna"
	replace ADM1_EN = "  Exit" if ADM1_EN == "Barisal"
	replace ADM1_EN = "   Exit"  if ADM1_EN == "Rajshahi"
	replace ADM1_EN = "    Exit" if ADM1_EN == "Mymensingh"
	replace ADM1_EN = "Exit   " if ADM1_EN == "Rangpur"
	
	
	g pct_hh = round(freq*100, 0.01)
	
	tempfile exit_earning_div
	save `exit_earning_div', replace
	
	
	u `entry_earning', clear
		
	g freq = (a4earning_source1 == 68) | (a4earning_source2 == 68)
	
    
    collapse (mean) freq [pweight=hhweight_24], by(ADM1_EN)
	encode ADM1_EN, g(adm1en)
	
	g order = .
	recode order . = 1.2 if ADM1_EN == "Chittagong"
	recode order . = 2.2 if ADM1_EN == "Dhaka"
	recode order . = 3.2 if ADM1_EN == "Sylhet"
	recode order . = 4.2 if ADM1_EN == "Khulna"
	recode order . = 5.2 if ADM1_EN == "Barisal"
	recode order . = 6.2 if ADM1_EN == "Rajshahi"
	recode order . = 7.2 if ADM1_EN == "Mymensingh"
	recode order . = 8.2 if ADM1_EN == "Rangpur"
	
	
	replace ADM1_EN = ADM1_EN + "             Entry"
	
	g pct_hh = round(freq*100, 0.01)
	
	tempfile entry_earning_div
	save `entry_earning_div', replace

 	u `exit_nonexit_saving', clear
		
	g freq = (a4earning_source1 == 68) | (a4earning_source2 == 68)
    
    collapse (mean) freq [pweight=hhweight_24], by(ADM1_EN)
	
	g order = .
	recode order . = 1.1 if ADM1_EN == "Chittagong"
	recode order . = 2.1 if ADM1_EN == "Dhaka"
	recode order . = 3.1 if ADM1_EN == "Sylhet"
	recode order . = 4.1 if ADM1_EN == "Khulna"
	recode order . = 5.1 if ADM1_EN == "Barisal"
	recode order . = 6.1 if ADM1_EN == "Rajshahi"
	recode order . = 7.1 if ADM1_EN == "Mymensingh"
	recode order . = 8.1 if ADM1_EN == "Rangpur"
	
//	encode ADM1_EN, g(adm1en)
	replace ADM1_EN = "All" if ADM1_EN == "Chittagong"
	replace ADM1_EN = " All" if ADM1_EN == "Dhaka"
	replace ADM1_EN = "All " if ADM1_EN == "Sylhet"
	replace ADM1_EN = "All  " if ADM1_EN == "Khulna"
	replace ADM1_EN = "  All" if ADM1_EN == "Barisal"
	replace ADM1_EN = "   All"  if ADM1_EN == "Rajshahi"
	replace ADM1_EN = "    All" if ADM1_EN == "Mymensingh"
	replace ADM1_EN = "All   " if ADM1_EN == "Rangpur"
	
	
	g pct_hh = round(freq*100, 0.01)
	
	append using `exit_earning_div'
	
	append using `entry_earning_div'
	
    //set scheme plottigblind

	graph hbar (asis) pct_hh, over(ADM1_EN, sort(order) gap(20) label(labcolor(black)labsize(medium))) ///
	asyvars showyvars ylabel(0(10)50, labsize(small) noticks nogrid labcolor (black)) ///
	blabel(bar, format(%4.1f) size(vsmall)color (white) position(inside)) ///
	bar(1, bcolor("dknavy"))bar(2, bcolor("ltblue"))bar(3, bcolor("dknavy")) ///
	bar(4, bcolor("ltblue"))bar(5, bcolor("dknavy"))bar(6, bcolor("ltblue")) ///
	bar(7, bcolor("dknavy"))bar(8, bcolor("ltblue"))bar(9, bcolor("dknavy")) ///
	bar(10, bcolor("dknavy"))bar(11, bcolor("dknavy"))bar(12, bcolor("dknavy")) ///
	bar(13, bcolor("ebblue"))bar(14, bcolor("ebblue"))bar(15, bcolor("ebblue")) ///
	bar(16, bcolor("ltblue"))bar(17, bcolor("ltblue"))bar(18, bcolor("ltblue")) ///
	bar(19, bcolor("ltblue"))bar(20, bcolor("ebblue"))bar(21, bcolor("ebblue")) ///
	bar(22, bcolor("ebblue"))bar(23, bcolor("ebblue"))bar(24, bcolor("ebblue")) ///
	title("", ///
	justification(middle) margin(b+1 t-1 l-1) bexpand size(small) color (black)) ///
	ytitle("", size(small)) legend(off)
	
	graph export "${final_figure}${slash}figure_9.png", replace as(png)
	
	
	u `ttest_exit', clear
	
	g agri_exit = 1 if agri_control_household == 0 & agri_control_household_18 == 1
	recode agri_exit . = 0 if agri_control_household == 1 & agri_control_household_18 == 1
	
	g agri_entry = agri_control_household if agri_control_household_18 == 0
	
	tempfile ttest_exit_fin
	save `ttest_exit_fin', replace 
		
	merge 1:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a5_6.dta", keepusing(a6_hh_savings) nogen
	
	la def agri_exit 0 "Remains in agriculture" 1 "Exited agriculture in 2024"
	
	la val agri_exit agri_exit
	
	winsor a6_hh_savings, gen(a6_hh_savings_winsorized) p(0.01) highonly
	
	ttest a6_hh_savings_winsorized, by(agri_exit)
	ttest a6_hh_savings_winsorized, by(agri_entry)

	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	merge m:1 a1hhid_combined using `ttest_exit_fin', nogen keep(3)

	preserve
	
	keep if b1plotsize_decimal > 0 & b1plot_type == 1
	
	ttest b1plotsize_decimal, by(agri_exit)
	ttest b1plotsize_decimal, by(agri_entry)	
	
	restore
	
	
	**# 6.1	Crop Germplasm Improvement
	/* Figures and tables in the sub-chapter (they are put above the starting point of
	the code for the table/figure as well): */
	
	
	* Figure 17. Crop cultivation of agricultural households in the past three seasons (%)
	* Table 21. Self-reported reach of crop germplasm innovation
	* Figure 18. Adoption of major Boro varieties for DNA fingerprinting plot in 2023-24 (%)
	
	* Figure 19. Mixing of Varieties on DNA Fingerprinting Plot
	* Figure 20 unpacking miniket sample DNA fingerprinting analysis
	* Figure 20. Variety-wise division of `local' and `improved' self-reports with corresponding self-reported variety names
	* Figure 21. DNA vs. self-report comparison for major Boro varieties
	* Figure 22. Misclassification of DNA fingerprinting samples
	* Figure 23. Correlates of misclassification of DNA fingerprinted rice 
	* Figure 49. Self-reports for 'Not-Assigned' samples (in reference list )
	* Figure 50. Self-Reports for `not assigned' samples (not in reference list) (%)
	
	* Table 15. DNA fingerprinting results reach estimates for rice in Boro 2023-24 for the PPS sampling selected plot
	* Table 16. Comparison of reach estimates between DNA fingerprinting and self-reported varieties in Boro 2023-24 for the PPS sampling plot
	* Table 17. Combined DNA fingerprinting plot and self-reported other plots' reach estimates for Boro rice
	* Table 18. Comparison of major Aman variety adoption between the SPIA-BIHS survey and Kretzschmar et al. (2018)
	* Table 19. Self-reported reach estimates for rice for Aman season across all plots
	* Table 20. Self-reported reach estimates for rice for Aus season across all plots
	
	
	
	
	
	* Figure 17. Crop cultivation of agricultural households in the past three seasons (%)
	* Table 21. Self-reported reach of crop germplasm innovation
	* Figure 18. Adoption of major Boro varieties for DNA fingerprinting plot in 2023-24 (%)
		
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g peanut_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2peanut_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile peanut_village
	save `peanut_village', replace
	
	keep if !mi(b2area) & !mi(b2peanut_variety)
	
	g innovation_year = .
	recode innovation_year . = 2016 if b2peanut_variety == 1
	recode innovation_year . = 1998 if b2peanut_variety == 3
	recode innovation_year . = 2004 if b2peanut_variety == 4
	
	tempfile peanut_all
	save `peanut_all', replace
	
	levelsof b2peanut_variety, local(peanut_levels)
	
	u `peanut_all', clear
	
	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1
	
	collapse(count) num_hh, by(merge_id)

	
	tempfile peanut_hh_count
	save `peanut_hh_count', replace
	
	
	foreach i of local peanut_levels {
		
		u `peanut_all', clear
		
	recode peanut_variety . = `i'
	
	recode pct_hh 0 = 1 if b2peanut_variety==`i'
	
	collapse(max) pct_hh peanut_variety (first) hhweight_24 b2crop_season, by(a1hhid_combined)
	
	collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(peanut_variety)
	
	g merge_id = 1
	
	merge 1:1 merge_id using `peanut_hh_count', nogen
	
	ren peanut_variety b2peanut_variety
	merge 1:m b2peanut_variety using `peanut_all', nogen keep(3) keepusing(innovation_year)
	
	ren innovation_year year
	ren b2peanut_variety peanut_variety
	
	collapse(first) pct_hh tot_reach num_hh year, by(peanut_variety)
	
	replace pct_hh = round(pct_hh*100, 0.01)
	
		tempfile p`i'
		save "`p`i''", replace
	
	}
	
	clear
	tempfile peanut_variety
	save `peanut_variety', emptyok
	
		
	foreach i of local peanut_levels  {
			
	append using "`p`i''"
	save `peanut_variety', replace
		
	}
	
	u `peanut_variety', clear 
		
	keep if peanut_variety == 1 | inrange(peanut_variety, 3, 4) 

					
	g innovation = 1 if peanut_variety == 1 | peanut_variety == 3
	recode innovation . = 2 if peanut_variety == 4	
	
	preserve 
	
	keep if !mi(year)
	g inno = 0
	collapse(mean) median_year = year [pweight=pct_hh], by(inno)
	
	ren inno innovation
	replace median_year = round(median_year)
	
	tempfile peanut_cg_med
	save `peanut_cg_med', replace
	
	restore
	
	preserve
	collapse(mean) median_year = year [pweight=pct_hh], by(innovation)
	
	
	replace median_year = round(median_year)
	
	append using `peanut_cg_med'
	
	tempfile med_peanut_variety
	save `med_peanut_variety', replace
	
	restore
	
	g innovation_label = "Short-duration Peanut" if innovation == 1 
	replace innovation_label = "High-yielding Peanut" if innovation == 2
	
	collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
	
	
		preserve
		
		g type_cg = 1
		
		collapse (sum) pct_hh tot_reach (first) num_hh, by(type_cg)
		
		
		g innovation = 0
		
		drop type_cg
		
		g innovation_label = "CG peanut varieties"
		
		tempfile peanut_hh_sum
		save `peanut_hh_sum', replace 
		
		restore
		
		append using `peanut_hh_sum'
		
		merge 1:1 innovation using `med_peanut_variety', nogen
		
	tempfile peanut_innovation_hh
	save `peanut_innovation_hh', replace
		
			

	foreach i of local peanut_levels {
		
		u `peanut_village', clear
		
	recode peanut_variety . = `i'
	
	recode pct_vil 0 = 1 if b2peanut_variety==`i'
	
	collapse(max) pct_vil peanut_variety (first) a1village, by(a1hhid_combined)
	
	collapse(max) pct_vil peanut_variety, by(a1village)
	
	collapse(mean) pct_vil, by(peanut_variety)
	
	replace pct_vil = round(pct_vil*100, 0.01)
		
		tempfile p`i'
		save "`p`i''", replace	
	}
	
	
	
	clear
	tempfile peanut_variety_vil
	save `peanut_variety_vil', emptyok
	

	foreach i of local peanut_levels  {
			
	append using "`p`i''"
	save `peanut_variety_vil', replace
		
	}
	
	keep if peanut_variety == 1 | inrange(peanut_variety, 3, 4) 

					
	g innovation = 1 if peanut_variety == 1 | peanut_variety == 3
	recode innovation . = 2 if peanut_variety == 4	
		
		
		collapse (sum) pct_vil, by(innovation)
		
		preserve
		
		g type_cg = 1
		
		collapse (sum) pct_vil, by(type_cg)
		
		g innovation = 0
		
		drop type_cg
		
		tempfile peanut_vil_sum
		save `peanut_vil_sum', replace 
		
		restore
		
		append using `peanut_vil_sum'
		
		merge 1:1 innovation using `peanut_innovation_hh', nogen
		

		g crop = "Peanut"
		
		drop if innovation == 2
		
		tempfile peanut_innovation
		save `peanut_innovation', replace
	
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g lentil_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2lentil_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile lentil_village
	save `lentil_village', replace
	
	keep if !mi(b2area) & !mi(b2lentil_variety)
			
	g innovation_year = .
	recode innovation_year . = 1991 if b2lentil_variety == 1
	recode innovation_year . = 2006 if b2lentil_variety == 5
	recode innovation_year . = 2011 if b2lentil_variety == 6
	recode innovation_year . = 2015 if b2lentil_variety == 7
	recode innovation_year . = 2013 if b2lentil_variety == 15
	
	tempfile lentil_all
	save `lentil_all', replace
	
	levelsof b2lentil_variety, local(lentil_levels)

	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1
	
	collapse(count) num_hh, by(merge_id)

	
	tempfile lentil_hh_count
	save `lentil_hh_count', replace
	
	
	foreach i of local lentil_levels {
		
		u `lentil_all', clear
		
	recode lentil_variety . = `i'
	
	recode pct_hh 0 = 1 if b2lentil_variety==`i'
	
	collapse(max) pct_hh lentil_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(lentil_variety)
	
	g merge_id = 1
	
	merge 1:1 merge_id using `lentil_hh_count', nogen
	
	ren lentil_variety b2lentil_variety
	merge 1:m b2lentil_variety using `lentil_all', nogen keep(3) keepusing(innovation_year)
	
	ren innovation_year year
	ren b2lentil_variety lentil_variety
	
	collapse(first) pct_hh tot_reach num_hh year, by(lentil_variety)
	
	replace pct_hh = round(pct_hh*100, 0.01)
	
	tempfile l`i'
	save "`l`i''", replace
		
	}
		
	clear
	tempfile lentil_variety
	save `lentil_variety', emptyok
		
	foreach i of local lentil_levels  {
			
	append using "`l`i''"
	save `lentil_variety', replace
		
	}
	

	
	u `lentil_variety', clear 
	
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6

		g innovation = .		
		recode innovation . = 1 if lentil_variety == 1 | lentil_variety == 15
		recode innovation . = 2 if lentil_variety == 5 | lentil_variety == 6
		recode innovation . = 3 if lentil_variety == 7
		
		preserve 
	
		keep if !mi(year)
		g inno = 0
		collapse(mean) median_year = year [pweight=pct_hh], by(inno)
		
		ren inno innovation
		replace median_year = round(median_year)
		
		tempfile lentil_cg_med
		save `lentil_cg_med', replace
	
		restore
	
		preserve 
	
		keep if !mi(year)
		g inno = 1
		collapse(mean) median_year = year [pweight=pct_hh], by(inno)
		
		ren inno innovation
		replace median_year = round(median_year)
		
		tempfile med_lentil_variety_1
		save `med_lentil_variety_1', replace
	
		restore
		
		preserve 
	
		keep if !mi(year)
		g inno = 3
		collapse(mean) median_year = year [pweight=pct_hh], by(inno)
		
		ren inno innovation
		replace median_year = round(median_year)
		
		tempfile med_lentil_variety_3
		save `med_lentil_variety_3', replace
	
		restore
		
		
		g innovation_label = "Disease resistant lentil" if innovation == 1 
		replace innovation_label = "Iron lentil with resistance to Stemphylium blight (SB)" if innovation == 2
		replace innovation_label = "High yield lentil" if innovation == 3
		replace innovation_label = "Micronutrient (Zinc and/or iron) enriched lentil" if innovation == 4
	

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile lentil_inno_hh
		save `lentil_inno_hh', replace
	
	u `lentil_variety', clear 
	
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6


		g innovation = .		
		recode innovation . = 1 if lentil_variety == 5 | lentil_variety == 7 | lentil_variety == 6
		recode innovation . = 2 if lentil_variety == 15	
		recode innovation . = 3 if lentil_variety == 1
			
		
		g innovation_label = "Rust, foot and root rot resistant lentil varierty" if innovation == 1 
		replace innovation_label = "Iron lentil with resistance to Stemphylium blight (SB)" if innovation == 2
		replace innovation_label = "High yield lentil" if innovation == 3
		replace innovation_label = "Lentil high in zinc" if innovation == 4
	

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile lentil_inno_hh_2
		save `lentil_inno_hh_2', replace
	
	u `lentil_variety', clear 
	
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6


		g innovation = .		
		recode innovation . = 2 if lentil_variety == 7
		recode innovation . = 3 if lentil_variety == 5 | lentil_variety == 15 | lentil_variety == 6
		
	
		
		g innovation_label = "Disease resistant lentil varierty" if innovation == 1 
		replace innovation_label = "Iron lentil with resistance to Stemphylium blight (SB)" if innovation == 2
		replace innovation_label = "High yield lentil" if innovation == 3
		replace innovation_label = "Lentil high in zinc" if innovation == 4
	

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile lentil_inno_hh_3
		save `lentil_inno_hh_3', replace
		
		u `lentil_variety', clear 
	
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6


		g innovation = .		
		recode innovation . = 4 if lentil_variety == 5 | lentil_variety == 7 | lentil_variety == 6
		
		
		g innovation_label = "Rust, foot and root rot resistant lentil varierty" if innovation == 1 
		replace innovation_label = "Iron lentil with resistance to Stemphylium blight (SB)" if innovation == 2
		replace innovation_label = "High yield lentil" if innovation == 3
		replace innovation_label = "Lentil high in zinc" if innovation == 4
	

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile lentil_inno_hh_4
		save `lentil_inno_hh_4', replace

		append using `lentil_inno_hh'
		append using `lentil_inno_hh_2'
		append using `lentil_inno_hh_3'
	
		preserve
		u `lentil_variety', clear 
	
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6
		
		g type_cg = 1
		
		collapse (sum) pct_hh tot_reach (first) num_hh, by(type_cg)
		
		g innovation_label = "CGIAR lentil varieties"
		
		g innovation = 0
		
		tempfile lentil_cg_var
		save `lentil_cg_var', replace
		
		restore 
		
		append using `lentil_cg_var'
		
		sort innovation
		
		drop if mi(innovation)
		
		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		preserve
		u `lentil_variety', clear 
		
		keep if lentil_variety == 5 | lentil_variety == 7 | lentil_variety == 15 | lentil_variety == 6
		
		g innovation = 2
		
		collapse(mean) median_year = year [pweight=pct_hh], by(innovation)
			
		replace median_year = round(median_year)
			
		tempfile med_lentil_variety_2
		save `med_lentil_variety_2', replace
		
		restore
		
		preserve
		u `lentil_variety', clear 
		keep if lentil_variety == 5 | lentil_variety == 7 | lentil_variety == 6
		
		g innovation = 4
		
		collapse(mean) median_year = year [pweight=pct_hh], by(innovation)
			
		replace median_year = round(median_year)
		
		append using `med_lentil_variety_1'
		append using `med_lentil_variety_2'
		append using `med_lentil_variety_3'
		append using `lentil_cg_med'
		
		tempfile med_lentil_variety_4
		save `med_lentil_variety_4', replace
		
		restore
		
		merge 1:1 innovation using `med_lentil_variety_4', nogen
			
		tempfile lentil_innovation_hh
		save `lentil_innovation_hh', replace
		
			
	
	foreach i of local lentil_levels {
		
		u `lentil_village', clear
		
	recode lentil_variety . = `i'
	
	recode pct_vil 0 = 1 if b2lentil_variety==`i'
	
	collapse(max) pct_vil (first) lentil_variety a1village, by(a1hhid_combined)
	
	collapse(max) pct_vil (first) lentil_variety, by(a1village)
	
	collapse(mean) pct_vil, by(lentil_variety)
	
	replace pct_vil = round(pct_vil*100, 0.01)
	
		tempfile l`i'
		save "`l`i''", replace
		
	}
	
	clear
	tempfile lentil_variety_vil
	save `lentil_variety_vil', emptyok
	
	foreach i of local lentil_levels  {
			
	append using "`l`i''"
	save `lentil_variety_vil', replace
		
	}
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6

	g innovation = .		
	recode innovation . = 1 if lentil_variety == 1 | lentil_variety == 15
	recode innovation . = 2 if lentil_variety == 5 | lentil_variety == 6
	recode innovation . = 3 if lentil_variety == 7
		
		collapse (sum) pct_vil, by(innovation)
		
		tempfile lentil_inno_vil
		save `lentil_inno_vil', replace
	
	u `lentil_variety_vil', clear
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6

		g innovation = .		
		recode innovation . = 1 if lentil_variety == 5 | lentil_variety == 7 | lentil_variety == 6
		recode innovation . = 2 if lentil_variety == 15	
		recode innovation . = 3 if lentil_variety == 1

	
		collapse (sum) pct_vil, by(innovation)
		
		tempfile lentil_inno_vil_2
		save `lentil_inno_vil_2', replace
		
	u `lentil_variety_vil', clear
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6

	g innovation = .		
	recode innovation . = 2 if lentil_variety == 7
	recode innovation . = 3 if lentil_variety == 5 | lentil_variety == 15 | lentil_variety == 6
	
	collapse (sum) pct_vil, by(innovation)
	
	tempfile lentil_inno_vil_3
	save `lentil_inno_vil_3', replace
		
	
	u `lentil_variety_vil', clear
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6

	g innovation = .		
	recode innovation . = 4 if lentil_variety == 5 | lentil_variety == 7 | lentil_variety == 6
	
	collapse (sum) pct_vil, by(innovation)
	
	tempfile lentil_inno_vil_4
	save `lentil_inno_vil_4', replace
	
	append using `lentil_inno_vil'
	append using `lentil_inno_vil_2'
	append using `lentil_inno_vil_3'
	
	tempfile lentil_vil_cg
	save `lentil_vil_cg', replace
	
	u `lentil_variety_vil', clear
	
	keep if lentil_variety == 1 | lentil_variety == 5 | lentil_variety == 7 | ///
	lentil_variety == 15 | lentil_variety == 6
	
	g type_cg = 1
	
	collapse (sum) pct_vil, by(type_cg)
	
	g innovation = 0
	
	tempfile lentil_sum_cg
	save `lentil_sum_cg', replace
		
	append using `lentil_vil_cg'
		
	drop if mi(innovation)
	
	collapse (sum) pct_vil, by(innovation)	
		
	merge 1:1 innovation using `lentil_innovation_hh', nogen
	sort innovation
	g crop = "Lentil"	
	
	drop innovation_label
	
	drop if inrange(innovation, 2, 3)
	
	
	
	g innovation_label = "Disease resistant lentil" if innovation == 1 
	replace innovation_label = "CGIAR lentil varieties" if innovation == 0
	replace innovation_label = "Micronutrient (Zinc and/or iron) enriched lentil" if innovation == 4
	
	tempfile lentil_innovation
	save `lentil_innovation', replace
	
	
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	forvalues i = 1/7 	{ 
		g innovation`i' = 0
		
	}
	
	g wheat_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2wheat_variety -96 = 96
	
	keep if b2crop_season != 4
	
	
	local innovalue "4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 1
	
	}
	
	local innovalue "4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 4
	
	}
	
	local innovalue "4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 6
	
	}
	
	local innovalue "2 4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 9

	}
	
	local innovalue "4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 11

	}
	
	local innovalue "2 4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 12

	}
	
	local innovalue "2 4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 13

	}
	
	local innovalue "2 4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 15

	}
	
	local innovalue "2 4 7"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 16

	}
	
	local innovalue "2 4"
	
	foreach i of local innovalue {
	
	recode innovation`i' 0 = 1 if b2wheat_variety == 17

	}
	
	tempfile wheat_village
	save `wheat_village', replace
	
	local wheat "1 4 6 9 11 12 13 15 16 17 19 23"
	
	foreach i of local wheat {
		
		u `wheat_village', clear
		
	recode wheat_variety . = `i'
	
	recode pct_vil 0 = 1 if b2wheat_variety == `i'
	
	collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
	
	collapse(max) pct_vil, by(a1village)
	
	tempfile wheat_vil_`i'
	save "`wheat_vil_`i''"
	
	}
	
	clear
	tempfile wheat_cg_vil
	save `wheat_cg_vil', emptyok
	
	foreach i of local wheat {
		
		append using "`wheat_vil_`i''"
		save `wheat_cg_vil', replace
	}
	
	collapse(max) pct_vil, by(a1village)
	
	g innovation = 0
	collapse(mean) pct_vil, by(innovation)
	
	replace pct_vil = round(pct_vil*100, 0.01)	
	
	save `wheat_cg_vil', replace

	u `wheat_village', clear
	
	keep if !mi(b2area) & !mi(b2wheat_variety)
		
	preserve 
	
	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1

	
	collapse(count) num_hh, by(merge_id)
	
	
	tempfile wheat_hh_count
	save `wheat_hh_count', replace
	
	restore
	
	g innovation_year = .
	recode innovation_year . = 1987 if b2wheat_variety == 1
	recode innovation_year . = 2000 if b2wheat_variety == 4
	recode innovation_year . = 2005 if b2wheat_variety == 6
	recode innovation_year . = 2010 if b2wheat_variety == 9
	recode innovation_year . = 2012 if b2wheat_variety == 11
	recode innovation_year . = 2014 if b2wheat_variety == 12
	recode innovation_year . = 2014 if b2wheat_variety == 13
	recode innovation_year . = 2017 if b2wheat_variety == 15
	recode innovation_year . = 2017 if b2wheat_variety == 16
	recode innovation_year . = 2005 if b2wheat_variety == 17
	recode innovation_year . = 1974 if b2wheat_variety == 19
	recode innovation_year . = 1974 if b2wheat_variety == 23
	
	preserve 
	
	recode pct_hh 0 = 1 if innovation_year !=.
	
	collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
	g innovation =  0
	
	collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
	
	replace pct_hh = round(pct_hh*100, 0.01)
	
	tempfile wheat_cg
	save `wheat_cg', replace
		
	restore
	
	tempfile wheat_fin
	save `wheat_fin', replace
		
	levelsof b2wheat_variety, local(wheat_levels)
	

	foreach i of local wheat_levels {		
	u `wheat_fin', clear
	recode wheat_variety . = `i'
	
	recode pct_hh 0 = 1 if b2wheat_variety== `i'
	
	collapse(max) pct_hh wheat_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(wheat_variety)
	
	ren wheat_variety b2wheat_variety
	merge 1:m b2wheat_variety using `wheat_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2wheat_variety wheat_variety
	
	collapse(first) mean_hh year innovation*, by(wheat_variety)
	
	tempfile w_m_`i'
	save "`w_m_`i''", replace
	
	}
	
	clear
	tempfile med_wheat_variety
	save `med_wheat_variety', emptyok
	
	foreach i of local wheat_levels {		
	append using "`w_m_`i''"
	save `med_wheat_variety', replace
	
	}
	
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile wheat_cg_med
	save `wheat_cg_med', replace
	
	local wheat_inno "2 4 7"
	
	

	
	foreach i of local wheat_inno {
		
		u `med_wheat_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_wheat
	save `med_year_wheat', emptyok
	
	foreach i of local wheat_inno {
		append using "`med_year`i''"
		save `med_year_wheat', replace
	}
	
	append using `wheat_cg_med'
	save `med_year_wheat', replace
			
	foreach i of local wheat_inno {
		
	u `wheat_fin', clear
	
	recode pct_hh 0 = 1 if innovation`i'== 1
		
	collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
	
	g innovation = `i'
	
	collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
	
	g merge_id = 1
	
	merge 1:1 merge_id using `wheat_hh_count', nogen
		
	replace pct_hh = round(pct_hh*100, 0.01)
			
		tempfile w`i'
		save "`w`i''", replace
	}
	
		
	clear
	tempfile wheat_innovation_fin
	save `wheat_innovation_fin', emptyok

	
	foreach i of local wheat_inno  {
			
	append using "`w`i''"
	save `wheat_innovation_fin', replace
		
	}
	
	append using `wheat_cg'
	
	save `wheat_innovation_fin', replace
	
	
	foreach i of local wheat_inno {
		
		u `wheat_village', clear
		
	
	recode pct_vil 0 = 1 if innovation`i'== 1
	
	collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
		
	collapse(max) pct_vil, by(a1village)
	
	g innovation = `i'
	
	collapse(mean) pct_vil, by(innovation)
		
	replace pct_vil = round(pct_vil*100, 0.01)
		
		tempfile w`i'
		save "`w`i''", replace
		
	}
	
	clear
	tempfile wheat_variety_vil
	save `wheat_variety_vil', emptyok
		
	 foreach i of local wheat_inno  {
	
	append using "`w`i''"
	save `wheat_variety_vil', replace
		
	}
	
	append using `wheat_cg_vil'
	
	merge 1:1 innovation using `wheat_innovation_fin', nogen
	
	merge 1:1 innovation using `med_year_wheat', nogen
	
	g innovation_label = "CG wheat varieties" if innovation == 0
	replace innovation_label = "Stress tolerant wheat" if innovation == 2
	replace innovation_label = "Disease tolerant wheat" if innovation == 4
	replace innovation_label = "Zinc enriched wheat" if innovation == 7

	g crop = "Wheat"

	tempfile wheat_innovation
	save `wheat_innovation', replace
	
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g maize_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2maize_variety -96 = 96
	
	keep if b2crop_season != 4
		
	tempfile maize_village
	save `maize_village', replace
	
	keep if !mi(b2area) & !mi(b2maize_variety)
	
	g innovation_year = .
	recode innovation_year . = 2016 if b2maize_variety == 4
	recode innovation_year . = 2016 if b2maize_variety == 5
	recode innovation_year . = 2017 if b2maize_variety == 6
	recode innovation_year . = 2017 if b2maize_variety == 7
	recode innovation_year . = 2018 if b2maize_variety == 8
	recode innovation_year . = 2019 if b2maize_variety == 9
	recode innovation_year . = 2002 if b2maize_variety == 10
	recode innovation_year . = 2004 if b2maize_variety == 11
	recode innovation_year . = 2006 if b2maize_variety == 12
	recode innovation_year . = 2006 if b2maize_variety == 13
	recode innovation_year . = 2007 if b2maize_variety == 14
	recode innovation_year . = 2007 if b2maize_variety == 15
	recode innovation_year . = 2002 if b2maize_variety == 18
		
	
	tempfile maize_all
	save `maize_all', replace
	
	levelsof b2maize_variety, local(maize_levels)

	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1
	
	collapse(count) num_hh, by(merge_id)
		
	tempfile maize_hh_count
	save `maize_hh_count', replace
		
	foreach i of local maize_levels {
	
	u `maize_all', clear
		
	recode maize_variety . = `i'
	
	recode pct_hh 0 = 1 if b2maize_variety==`i'
	
	collapse(max) pct_hh maize_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(maize_variety)
	
	g merge_id = 1
	
	merge 1:1 merge_id using `maize_hh_count', nogen
	
	ren maize_variety b2maize_variety
	merge 1:m b2maize_variety using `maize_all', nogen keep(3) keepusing(innovation_year)
	
	ren innovation_year year
	ren b2maize_variety maize_variety
	
	collapse(first) pct_hh tot_reach num_hh year, by(maize_variety)
	
	replace pct_hh = round(pct_hh*100, 0.01)
				
		tempfile m`i'
		save "`m`i''", replace
		}
		
	clear
	tempfile maize_variety
	save `maize_variety', emptyok
		
	foreach i of local maize_levels  {
			
	append using "`m`i''"
	save `maize_variety', replace
		
	}
		
	
	keep if inrange(maize_variety, 4, 18)
	
	save `maize_variety', replace 
							
		g innovation = 1 if maize_variety == 6 | maize_variety == 7 | maize_variety == 9 | ///
		maize_variety == 4 | maize_variety == 5 | maize_variety == 8
		recode innovation . = 4 if maize_variety == 10 | maize_variety == 11
		recode innovation . = 5 if maize_variety == 18 
		recode innovation . = 6 if inrange(maize_variety, 12, 15)
	
		
		g innovation_label = "Stress tolerant maize variety" if innovation == 1 
		replace innovation_label = "Protein enrich maize variety" if innovation == 4
		replace innovation_label = "Other improved maize variety" if innovation == 6
		
		drop if mi(innovation)
		
		tempfile maize_med_year_1
		save `maize_med_year_1', replace
	

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile maize_inno_hh_1
		save `maize_inno_hh_1', replace
	
	
	g type_cg = 1
		
	collapse (sum) pct_hh tot_reach (first) num_hh, by(type_cg)
		
	g innovation_label = "CGIAR maize varieties"
	
	g innovation = 0
		
	drop type_cg
		
	tempfile maize_sum_cg
	save `maize_sum_cg', replace
	
	u `maize_variety', clear 
		
	keep if inrange(maize_variety, 4, 18)
		 
	preserve
	
	append using `maize_med_year_1'
	
	tempfile maize_med_year
	save `maize_med_year', replace
	
	drop if mi(innovation)
	
	duplicates drop maize_variety, force
	
	g inno = 0
	collapse(mean) median_year = year [pweight=pct_hh], by(inno)
	
	ren inno innovation
	replace median_year = round(median_year)
	tempfile maize_med_cg
	save `maize_med_cg', replace
	
	local maize_inno "1 4 6"
	
	foreach i of local maize_inno {
		
		u `maize_med_year', clear
		keep if innovation == `i'
		collapse(mean) median_year = year [pweight=pct_hh], by(innovation)
		
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_maize 
	save `med_year_maize', emptyok
	
	foreach i of local maize_inno {
		append using "`med_year`i''"
		save `med_year_maize', replace
	}
	
	append using `maize_med_cg'
	save `med_year_maize', replace

	restore
				
	u `maize_inno_hh_1', clear

	drop if mi(innovation)	
	
	collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
	
	append using `maize_sum_cg'
	
	tempfile maize_innovation_hh
	save `maize_innovation_hh', replace
				
	foreach i of local maize_levels {
		
	u `maize_village', clear
		
	recode maize_variety . = `i'
	
	recode pct_vil 0 = 1 if b2maize_variety==`i'
	
	collapse(max) pct_vil maize_variety (first) a1village, by(a1hhid_combined)
	
	collapse(max) pct_vil maize_variety, by(a1village)
	
	collapse(mean) pct_vil, by(maize_variety)
	
	replace pct_vil = round(pct_vil*100, 0.01)
			
		tempfile m`i'
		save "`m`i''", replace
	
	}
	
	clear
	tempfile maize_variety_vil
	save `maize_variety_vil', emptyok

	foreach i of local maize_levels  {
			
	append using "`m`i''"
	save `maize_variety_vil', replace
		
	}
	
	
	keep if inrange(maize_variety, 4, 18)
		
		
		g innovation = 1 if maize_variety == 6 | maize_variety == 7 | maize_variety == 9 | ///
		maize_variety == 4 | maize_variety == 5 | maize_variety == 8
		recode innovation . = 4 if maize_variety == 10 | maize_variety == 11
		recode innovation . = 5 if maize_variety == 18 
		recode innovation . = 6 if inrange(maize_variety, 12, 15)
			
		drop if mi(innovation)
		
		collapse (sum) pct_vil, by(innovation)
		
		tempfile maize_variety_vil_1
		save `maize_variety_vil_1', replace
	
		g type_cg = 1
		
		drop if mi(innovation)
		
		collapse (sum) pct_vil, by(type_cg)
		
		g innovation_label = "CGIAR maize varieties"
	
		g innovation = 0
		
		drop type_cg
		
		tempfile maize_vil_cg
		save `maize_vil_cg', replace
	
				
		append using `maize_variety_vil_1'
		
		drop if mi(innovation)
		
		collapse (sum) pct_vil, by(innovation)
		
		merge 1:1 innovation using `maize_innovation_hh', nogen
		
		merge 1:1 innovation using `med_year_maize', nogen
		drop if innovation == 5
		g crop = "Maize"
		tempfile maize_innovation
		save `maize_innovation', replace
	
	
	u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
	g potato_variety = .
	
	g pct_hh = 0
	
	g pct_vil = 0
	
	recode b2potato_variety -96 = 96
	
	keep if b2crop_season != 4
	
	tempfile potato_village
	save `potato_village', replace
	
	keep if !mi(b2area) & !mi(b2potato_variety) 
		
	tempfile potato_all
	save `potato_all', replace
	
	levelsof b2potato_variety, local(levels)
	
	g num_hh = 1
	
	collapse(max) num_hh (first) b2crop_season, by(a1hhid_combined)
	
	g merge_id = 1 
		
	collapse(count) num_hh, by(merge_id)
	
	
	tempfile potato_hh_count
	save `potato_hh_count', replace
	
	
	foreach j of local levels {
		
		u `potato_all', clear
		
	recode potato_variety . = `j'
	
	recode pct_hh 0 = 1 if b2potato_variety==`j'
	
	collapse(max) pct_hh potato_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(potato_variety)
	
	g merge_id = 1
	
	merge 1:1 merge_id using `potato_hh_count', nogen
	
	replace pct_hh = round(pct_hh*100, 0.01)
				
		tempfile p`j'
		save "`p`j''", replace
		
	}
		
	clear
	tempfile potato_variety
	save `potato_variety', emptyok
	
	foreach j of local levels  {
	
	append using "`p`j''"
	save `potato_variety', replace	
	}
	
	
	
	g innovation_year = .
	recode innovation_year . = 1990 if potato_variety == 1
	recode innovation_year . = 1993 if potato_variety == 2
	recode innovation_year . = 2004 if potato_variety == 3
	recode innovation_year . = 2014 if potato_variety == 5
	recode innovation_year . = 2019 if potato_variety == 20
	recode innovation_year . = 1997 if potato_variety == 22
	

	save `potato_variety', replace
	
	
	
	keep if potato_variety == 1 | potato_variety == 2 | potato_variety == 5 | ///
	potato_variety == 20 | potato_variety ==  3 | potato_variety == 22
	

	
		g innovation = .
		recode innovation . = 1 if inrange(potato_variety, 1, 3)
				
		g innovation_label = "Stress tolerant potato" if innovation == 1 
		replace innovation_label = "Virus and disease resistant potato" if innovation == 4
		
		tempfile potato_med_year_1
		save `potato_med_year_1', replace

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile potato_inno_hh
		save `potato_inno_hh', replace
			
		g type_cg = 1
		
		collapse (sum) pct_hh tot_reach (first) num_hh, by(type_cg)
		
		g innovation_label = "CGIAR potato varieties"
		
		g innovation = 0
		
		drop type_cg
		
		tempfile potato_sum_cg
		save `potato_sum_cg', replace
	
		
		u `potato_variety', clear 
	
	
		keep if potato_variety == 1 | potato_variety == 2 | potato_variety == 5 | ///
		potato_variety == 20 | potato_variety ==  3 | potato_variety == 22
		
		g innovation = .
		recode innovation . = 4 if inrange(potato_variety, 2, 5)
			
		g innovation_label = "Early bulker potato" if innovation == 1 
		replace innovation_label = "Heat tolerant potato" if innovation == 2
		replace innovation_label = "Salinity tolerant potato" if innovation == 3
		replace innovation_label = "Virus and disease resistant potato" if innovation == 4
		replace innovation_label = "Potato suitable for processing and export" if innovation == 5
		replace innovation_label = "High yield potato" if innovation == 6
		
		tempfile potato_med_year_2
		save `potato_med_year_2', replace
	

		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		tempfile potato_inno_hh_2
		save `potato_inno_hh_2', replace
		
		
		
		preserve
		append using `potato_med_year_1'
		append using `potato_med_year_2'
		
		tempfile potato_med_year
		save `potato_med_year', replace
		
		duplicates drop potato_variety, force
	
		g inno = 0
		collapse(mean) median_year = innovation_year [pweight=pct_hh], by(inno)
	
		ren inno innovation
		replace median_year = round(median_year)
		tempfile potato_med_cg
		save `potato_med_cg', replace
		
	local potato_inno "1 4"
		
	foreach i of local potato_inno {
		u `potato_med_year', clear
		keep if innovation == `i'
		collapse(mean) median_year = innovation_year [pweight=pct_hh], by(innovation)
		
		replace median_year = round(median_year)
	
		tempfile med_year`i'
		save "`med_year`i''", replace
		}
	
	clear
	tempfile med_year_potato 
	save `med_year_potato', emptyok
	
	foreach i of local potato_inno {
		append using "`med_year`i''"
		save `med_year_potato', replace
	}
	
	append using `potato_med_cg'
	save `med_year_potato', replace
		
	restore

		append using `potato_inno_hh'
		append using `potato_sum_cg'
		
		drop if mi(innovation)
		
		collapse (sum) pct_hh tot_reach (first) innovation_label num_hh, by(innovation)
		
		sort innovation
		
		tempfile potato_innovation_hh
		save `potato_innovation_hh', replace
		
		
	foreach j of local levels {
		
		u `potato_village', clear
		
	recode potato_variety . = `j'
	
	recode pct_vil 0 = 1 if b2potato_variety==`j'
	
	collapse(max) pct_vil potato_variety (first) hhweight_24 a1village b2crop_season, by(a1hhid_combined)
	
	collapse(max) pct_vil potato_variety (first) hhweight_24, by(a1village)
	
	collapse(mean) pct_vil, by(potato_variety)
	
	replace pct_vil = round(pct_vil*100, 0.01)
		
		tempfile p`j'
		save "`p`j''", replace
	}
		
	clear
	tempfile potato_variety_vil
	save `potato_variety_vil', emptyok
	
	foreach j of local levels  {
			
	append using "`p`j''"
	save `potato_variety_vil', replace
		
	}
		
	tempfile potato_vil
	save `potato_vil', replace
	
	keep if potato_variety == 1 | potato_variety == 2 | potato_variety == 5 | ///
	potato_variety == 20 | potato_variety ==  3 | potato_variety == 22
		
		g innovation = .
		recode innovation . = 1 if inrange(potato_variety, 1, 3)
	
		collapse (sum) pct_vil, by(innovation)
		
		tempfile potato_inno_vil
		save `potato_inno_vil', replace
		
		g type_cg = 1
		
		collapse (sum) pct_vil, by(type_cg)
		
		g innovation_label = "CGIAR potato varieties"
		
		g innovation = 0
				
		tempfile potato_vil_cg
		save `potato_vil_cg', replace
				
		u `potato_vil', clear
		
		keep if potato_variety == 1 | potato_variety == 2 | potato_variety == 5 | ///
	potato_variety == 20 | potato_variety ==  3 | potato_variety == 22
	
		g innovation = .
		recode innovation . = 4 if inrange(potato_variety, 2, 5)
		

		collapse (sum) pct_vil, by(innovation)
		
		tempfile potato_inno_vil_2
		save `potato_inno_vil_2', replace
		
		append using `potato_inno_vil'
		append using `potato_vil_cg'
		
		drop if mi(innovation)
		
		collapse (sum) pct_vil, by(innovation)
		
		merge 1:1 innovation using `potato_innovation_hh', nogen
		merge 1:1 innovation using `med_year_potato', nogen
		
		drop innovation_label
		
		g innovation_label = "Stress tolerant potato" if innovation == 1 
		replace innovation_label = "CGIAR potato varieties" if innovation == 0
		replace innovation_label = "Virus and disease resistant potato" if innovation == 4
		
		drop innovation
		
		g crop = "Potato"
		tempfile potato_innovation
		save `potato_innovation', replace
	
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	
		forvalues i = 1/12 	{ 
			g innovation`i' = 0
			
		}
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86/-79 = 193
		
		
		keep if b2crop_season != 4
		keep if !mi(b2area) & !mi(b2paddy_variety) 
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 24
		
		}
		
		local innovalue "2 3 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 25

		}
		
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 27

		}
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 39

		}
		
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 46

		}
		
		local innovalue "6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 50

		}
		
		local innovalue "6 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 51

		}
		
		local innovalue "1 3 4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 54

		}
		
		local innovalue "4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 55

		}
		
		
		
		local innovalue "1 4 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 61

		}
		
		local innovalue "1 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 63

		}
		
		local innovalue "1 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 65

		}
		
		local innovalue "1 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 66

		}
		
		local innovalue "1 4 8 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 70

		}
		
		local innovalue "1 4 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 71

		}
		
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 73

		}
		
		
		local innovalue "1 7 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 74

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 75

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 76

		}
		
		
		local innovalue "1 5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 77

		}
		
		
		
		local innovalue "1 6 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 84

		}
		
		local innovalue "11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 86

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 99

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

		}
		
		local innovalue "1 2 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 137

		}
		
		local innovalue "5 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 139

		}
		
		local innovalue "6 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 140

		}
		
		local innovalue "9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 145

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 146

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 149

		}
		
		
		local innovalue "5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 152

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 155

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 156

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 157

		}
		
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 158

		}
		
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 160

		}
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 161

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 178

	}
	
	  // new cg varieties from 31 october
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 3

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 4

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 8

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 10

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 11

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 12

	}
	
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 13

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 19

	}
	
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 30

	}
	
		local innovalue "3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 48

	}
	
	
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 69

	}
	
	
	
	
	
		
	
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 61 63 65 66 70 71 73 74 75 76 77 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69"
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_`i'
		save "`paddy_vil_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil
		save `paddy_cg_vil', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_vil_`i''"
			save `paddy_cg_vil', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil', replace

		
		u `paddy_village', clear
		
	
		
		preserve
		
		g num_hh = 1
		
		collapse(max) num_hh, by(a1hhid_combined)
		
		g merge_id = 1
		
		collapse(count) num_hh, by(merge_id)
		
		tempfile paddy_hh_count
		save `paddy_hh_count', replace
		
		restore 
		
		
		g innovation_year = .
		recode innovation_year . = 1992 if b2paddy_variety == 24
		recode innovation_year . = 1993 if b2paddy_variety == 25
		recode innovation_year . = 1994 if b2paddy_variety == 27
		recode innovation_year . = 2003 if b2paddy_variety == 39
		recode innovation_year . = 2007 if b2paddy_variety == 46
		recode innovation_year . = 2010 if b2paddy_variety == 50
		recode innovation_year . = 2010 if b2paddy_variety == 51
		recode innovation_year . = 2011 if b2paddy_variety == 54
		recode innovation_year . = 2011 if b2paddy_variety == 55
	
		recode innovation_year . = 2013 if b2paddy_variety == 61
		recode innovation_year . = 2014 if b2paddy_variety == 63
		recode innovation_year . = 2014 if b2paddy_variety == 65
		recode innovation_year . = 2014 if b2paddy_variety == 66
		recode innovation_year . = 2015 if b2paddy_variety == 70
		recode innovation_year . = 2015 if b2paddy_variety == 71
		recode innovation_year . = 2015 if b2paddy_variety == 73
		recode innovation_year . = 2016 if b2paddy_variety == 74
		recode innovation_year . = 2016 if b2paddy_variety == 75
		recode innovation_year . = 2016 if b2paddy_variety == 76
		recode innovation_year . = 2016 if b2paddy_variety == 77
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2017 if b2paddy_variety == 84
		recode innovation_year . = 2018 if b2paddy_variety == 86
		recode innovation_year . = 2021 if b2paddy_variety == 99
		recode innovation_year . = 2022 if b2paddy_variety == 101
		
		recode innovation_year . = 2010 if b2paddy_variety == 137
		recode innovation_year . = 2012 if b2paddy_variety == 139
		recode innovation_year . = 2013 if b2paddy_variety == 140
		recode innovation_year . = 2014 if b2paddy_variety == 145
		recode innovation_year . = 2015 if b2paddy_variety == 146
		recode innovation_year . = 2017 if b2paddy_variety == 149
		recode innovation_year . = 2020 if b2paddy_variety == 152
		
		recode innovation_year . = 2001 if b2paddy_variety == 155
		recode innovation_year . = 2008 if b2paddy_variety == 156
		recode innovation_year . = 2009 if b2paddy_variety == 157
		recode innovation_year . = 2010 if b2paddy_variety == 158
		recode innovation_year . = 2017 if b2paddy_variety == 160
		recode innovation_year . = 2020 if b2paddy_variety == 161
		
		recode innovation_year . = 2017 if b2paddy_variety == 178
		
		recode innovation_year . = 1973 if b2paddy_variety == 3
		recode innovation_year . = 1975 if b2paddy_variety == 4
		recode innovation_year . = 1978 if b2paddy_variety == 8
		recode innovation_year . = 1980 if b2paddy_variety == 10
		recode innovation_year . = 1980 if b2paddy_variety == 11
		recode innovation_year . = 1983 if b2paddy_variety == 12
		recode innovation_year . = 1983 if b2paddy_variety == 13
		recode innovation_year . = 1986 if b2paddy_variety == 19
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 1994 if b2paddy_variety == 30
		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 48
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2015 if b2paddy_variety == 69
		recode innovation_year . = 1997 if b2paddy_variety == 32
		recode innovation_year . = 2013 if b2paddy_variety == 58
		recode innovation_year . = 2020 if b2paddy_variety == 98
		recode innovation_year . = 2018 if b2paddy_variety == 88
		
		
		preserve 
		
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg
		save `paddy_cg', replace
			
		restore
		
		tempfile paddy_fin
		save `paddy_fin', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_`i'
	save "`w_p_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety
	save `med_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_`i''"
	save `med_paddy_variety', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med
	save `paddy_cg_med', replace

	
	forvalues i = 1/12 {
		
		u `med_paddy_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy
	save `med_year_paddy', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year`i''"
		save `med_year_paddy', replace
	}
	
	append using `paddy_cg_med'
	save `med_year_paddy', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)

		
		g merge_id = 1
		
		merge 1:1 merge_id using `paddy_hh_count', nogen
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d`i'
			save "`d`i''", replace		
		}
		
		
		
		clear
		tempfile paddy_innovation_fin
		save `paddy_innovation_fin', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_innovation_fin', replace
			
		}
		
		append using `paddy_cg'
		
		save `paddy_innovation_fin', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d`i'
			save "`d`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil
		save `paddy_variety_vil', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_variety_vil', replace
			
		}
		
		append using `paddy_cg_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin', nogen
		
		merge 1:1 innovation using `med_year_paddy', nogen
		
		g innovation_label = "CG Paddy varieties" if innovation == 0
		replace innovation_label = "High yield paddy" if innovation == 1
		replace innovation_label = "Insect and disease resistant paddy" if innovation == 2
		replace innovation_label = "Early paddy variety" if innovation == 3 
		replace innovation_label = "Protein enriched paddy" if innovation == 4
		replace innovation_label = "Salt tolerant paddy" if innovation == 5
		replace innovation_label = "Flood tolerant paddy" if innovation == 6
		replace innovation_label = "Lodging tolerant paddy" if innovation == 7
		replace innovation_label = "Drought tolerant paddy" if innovation == 8
		replace innovation_label = "Short duration paddy" if innovation == 9
		replace innovation_label = "Zinc enriched paddy" if innovation == 10
		replace innovation_label = "Fertilizer- and water-saving paddy" if innovation == 11
		replace innovation_label = "Amylose enriched paddy" if innovation == 12
		
		tempfile paddy_lower_est
		save `paddy_lower_est', replace
		
		
		
		g crop = "Paddy"		
		
		append using `maize_innovation'
		
		append using `potato_innovation'
			
		append using `wheat_innovation'

		append using `peanut_innovation'
		
		append using `lentil_innovation'
		

		
		preserve
		
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
			
		keep if b2crop_season != 4
		
		collapse(max) agri_control_household, by(a1hhid_combined)
		
		g agri_id = 1
		
		collapse(sum) agri_control_household, by(agri_id)
		
		levelsof agri_control_household, local(num_agri_hh)
		
		restore

			
		g pct_agri_hh = (num_hh/`num_agri_hh')*100
		
		g total_reach = (tot_reach/1000000)
		
		g tot_reach_k = (tot_reach/1000)
		
		
		la var innovation_label "Name of crop innovation"
		la var pct_hh "% of HH with innovation among the crop cultivating HHs"
		la var pct_vil "% of villages with innovation"
		la var num_hh "Number of HH cultivating the crop in the past three seasons"
		la var pct_agri_hh "% of agriultural HH cultivating the crop in the past three seasons"
		la var total_reach "Estimated number of households (in millions)"
		la var tot_reach_k "Estimated number of households (in thousands)"
		la var median_year "Variety adoption percentage weighted release year of crop innovation"
		
		
		preserve 
		recode pct_agri_hh . = 0
		collapse(max) pct_agri_hh, by(crop)
		gsort -pct_agri_hh
		
			
	graph hbar (asis) pct_agri_hh, over(crop, sort(pct_agri_hh) descending gap(80) label(labcolor(black)labsize(medium))) ///
	asyvars showyvars ylabel(0(20)90, noticks nogrid angle(0) labsize(medium) labcolor (black)) ///
	blabel(bar, format(%4.2f) size(medium)color (black) position(outside)) ///
	bar(1, bcolor("dknavy"))bar(2, bcolor("dknavy"))bar(3, bcolor("dknavy")) ///
	bar(4, bcolor("dknavy"))bar(5, bcolor("dknavy")) ///
	bar(6, bcolor("dknavy")) ///
	title("", ///
	justification(left) margin(b+1 t-1 l-1) bexpand size(medium) color (black)) ///
	ytitle("", size(small)) ///
	note("",size(vsmall)) plotregion(fcolor(white)) ///
	legend(off) 

	graph export "${final_figure}${slash}figure_17.png", replace as(png)

		
		restore
		
		drop if crop == "Paddy"
				
		drop innovation tot_reach num_hh total_reach merge_id crop
		
		order innovation_label pct_hh pct_vil pct_agri_hh tot_reach_k median_year

		
		export excel "${final_table}${slash}table_21.xlsx", firstrow(varlabels) sh("table_21") sheetmodify
		
		* Table 19. Self-reported reach estimates for rice for Aman season across all plots
	
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	
		forvalues i = 1/12 	{ 
			g innovation`i' = 0
			
		}
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86/-79 = 193

		keep if b2crop_season == 2
		keep if !mi(b2area) & !mi(b2paddy_variety) 
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 24
		
		}
		
		local innovalue "2 3 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 25

		}
		
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 27

		}
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 39

		}
		
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 46

		}
		
		local innovalue "6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 50

		}
		
		local innovalue "6 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 51

		}
		
		local innovalue "1 3 4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 54

		}
		
		local innovalue "4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 55

		}
		
		
		
		local innovalue "1 4 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 61

		}
		
		local innovalue "1 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 63

		}
		
		local innovalue "1 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 65

		}
		
		local innovalue "1 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 66

		}
		
		local innovalue "1 4 8 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 70

		}
		
		local innovalue "1 4 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 71

		}
		
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 73

		}
		
		
		local innovalue "1 7 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 74

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 75

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 76

		}
		
		
		local innovalue "1 5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 77

		}
		
		
		
		local innovalue "1 6 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 84

		}
		
		local innovalue "11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 86

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 99

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

		}
		
		local innovalue "1 2 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 137

		}
		
		local innovalue "5 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 139

		}
		
		local innovalue "6 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 140

		}
		
		local innovalue "9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 145

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 146

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 149

		}
		
		
		local innovalue "5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 152

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 155

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 156

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 157

		}
		
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 158

		}
		
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 160

		}
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 161

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 178

	}
	
	  // new cg varieties from 31 october
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 3

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 4

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 8

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 10

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 11

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 12

	}
	
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 13

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 19

	}
	
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 30

	}
	
		local innovalue "3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 48

	}
	
	
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 69

	}
	
	
	//17 dec
	
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 68

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 98

	}
	
	
	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 56

		}
	
		//coding BR-89 as CG promoted from ashraf habib's document for now
	
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 88

	}
	
	// 17 dec new low bound
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 22

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 40

	}
	
	local innovalue "8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 42

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 43

	}
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 52

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 80

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 87

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 90

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 91

	}
	
	
	local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

	}
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_`i'
		save "`paddy_vil_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil
		save `paddy_cg_vil', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_vil_`i''"
			save `paddy_cg_vil', replace
			
		}
		
	
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil', replace

		
		u `paddy_village', clear
		
		
		
		preserve
		
		g num_hh = 1
		
		collapse(max) num_hh, by(a1hhid_combined)
		
		g merge_id = 1
		
		collapse(count) num_hh, by(merge_id)
		
		tempfile paddy_hh_count
		save `paddy_hh_count', replace
		
		restore 
		
		
		g innovation_year = .
		recode innovation_year . = 1992 if b2paddy_variety == 24
		recode innovation_year . = 1993 if b2paddy_variety == 25
		recode innovation_year . = 1994 if b2paddy_variety == 27
		recode innovation_year . = 2003 if b2paddy_variety == 39
		recode innovation_year . = 2007 if b2paddy_variety == 46
		recode innovation_year . = 2010 if b2paddy_variety == 50
		recode innovation_year . = 2010 if b2paddy_variety == 51
		recode innovation_year . = 2011 if b2paddy_variety == 54
		recode innovation_year . = 2011 if b2paddy_variety == 55
	
		recode innovation_year . = 2013 if b2paddy_variety == 61
		recode innovation_year . = 2014 if b2paddy_variety == 63
		recode innovation_year . = 2014 if b2paddy_variety == 65
		recode innovation_year . = 2014 if b2paddy_variety == 66
		recode innovation_year . = 2015 if b2paddy_variety == 70
		recode innovation_year . = 2015 if b2paddy_variety == 71
		recode innovation_year . = 2015 if b2paddy_variety == 73
		recode innovation_year . = 2016 if b2paddy_variety == 74
		recode innovation_year . = 2016 if b2paddy_variety == 75
		recode innovation_year . = 2016 if b2paddy_variety == 76
		recode innovation_year . = 2016 if b2paddy_variety == 77
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2017 if b2paddy_variety == 84
		recode innovation_year . = 2018 if b2paddy_variety == 86
		recode innovation_year . = 2021 if b2paddy_variety == 99
		recode innovation_year . = 2022 if b2paddy_variety == 101
		
		recode innovation_year . = 2010 if b2paddy_variety == 137
		recode innovation_year . = 2012 if b2paddy_variety == 139
		recode innovation_year . = 2013 if b2paddy_variety == 140
		recode innovation_year . = 2014 if b2paddy_variety == 145
		recode innovation_year . = 2015 if b2paddy_variety == 146
		recode innovation_year . = 2017 if b2paddy_variety == 149
		recode innovation_year . = 2020 if b2paddy_variety == 152
		
		recode innovation_year . = 2001 if b2paddy_variety == 155
		recode innovation_year . = 2008 if b2paddy_variety == 156
		recode innovation_year . = 2009 if b2paddy_variety == 157
		recode innovation_year . = 2010 if b2paddy_variety == 158
		recode innovation_year . = 2017 if b2paddy_variety == 160
		recode innovation_year . = 2020 if b2paddy_variety == 161
		
		recode innovation_year . = 2017 if b2paddy_variety == 178
			
		recode innovation_year . = 1973 if b2paddy_variety == 3
		recode innovation_year . = 1975 if b2paddy_variety == 4
		recode innovation_year . = 1978 if b2paddy_variety == 8
		recode innovation_year . = 1980 if b2paddy_variety == 10
		recode innovation_year . = 1980 if b2paddy_variety == 11
		recode innovation_year . = 1983 if b2paddy_variety == 12
		recode innovation_year . = 1983 if b2paddy_variety == 13
		recode innovation_year . = 1986 if b2paddy_variety == 19
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 1994 if b2paddy_variety == 30
		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 48
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2015 if b2paddy_variety == 69
		

		recode innovation_year . = 2020 if b2paddy_variety == 98
	
		recode innovation_year . = 2018 if b2paddy_variety == 88
	
		recode innovation_year . = 1970 if b2paddy_variety == 1
		recode innovation_year . = 1971 if b2paddy_variety == 2
		recode innovation_year . = 1977 if b2paddy_variety == 6
		recode innovation_year . = 1983 if b2paddy_variety == 15
		
		recode innovation_year . = 1994 if b2paddy_variety == 28
		recode innovation_year . = 2014 if b2paddy_variety == 68
		recode innovation_year . = 2020 if b2paddy_variety == 98

		recode innovation_year . = 2018 if b2paddy_variety == 88
		recode innovation_year . = 2011 if b2paddy_variety == 56
		recode innovation_year . = 2017 if b2paddy_variety == 78

		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2014 if b2paddy_variety == 67
		recode innovation_year . = 2020 if b2paddy_variety == 95
		
		recode innovation_year . = 1983 if b2paddy_variety == 14
		recode innovation_year . = 1985 if b2paddy_variety == 16
		recode innovation_year . = 1985 if b2paddy_variety == 17
		recode innovation_year . = 1985 if b2paddy_variety == 18
		recode innovation_year . = 1988 if b2paddy_variety == 22
		recode innovation_year . = 1994 if b2paddy_variety == 31
		recode innovation_year . = 2003 if b2paddy_variety == 40
		recode innovation_year . = 2004 if b2paddy_variety == 42
		recode innovation_year . = 2005 if b2paddy_variety == 43
		recode innovation_year . = 2010 if b2paddy_variety == 52
		recode innovation_year . = 2012 if b2paddy_variety == 57
		recode innovation_year . = 2014 if b2paddy_variety == 62
		recode innovation_year . = 2017 if b2paddy_variety == 80
		recode innovation_year . = 2018 if b2paddy_variety == 87
		recode innovation_year . = 2019 if b2paddy_variety == 90
		recode innovation_year . = 2019 if b2paddy_variety == 91
		recode innovation_year . = 2022 if b2paddy_variety == 100
		recode innovation_year . = 2022 if b2paddy_variety == 101
		recode innovation_year . = 1998 if b2paddy_variety == 133
		recode innovation_year . = 1998 if b2paddy_variety == 134
		recode innovation_year . = 1998 if b2paddy_variety == 135
		recode innovation_year . = 2014 if b2paddy_variety == 144
	
		recode innovation_year . = 1988 if b2paddy_variety == 21
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2020 if b2paddy_variety == 96
		
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		preserve 
		
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg
		save `paddy_cg', replace
			
		restore
		
		
		preserve 

		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin
		save `paddy_fin', replace
				
		foreach i of local paddy_levels {		
	u `paddy_fin', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_`i'
	save "`w_p_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety
	save `med_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_`i''"
	save `med_paddy_variety', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med
	save `paddy_cg_med', replace
	
	u `med_paddy_variety', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	
	forvalues i = 1/12 {
		
		u `med_paddy_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy
	save `med_year_paddy', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year`i''"
		save `med_year_paddy', replace
	}
	
	append using `paddy_cg_med'
	append using `paddy_tc_med'
	save `med_year_paddy', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)

		
		g merge_id = 1
		
		merge 1:1 merge_id using `paddy_hh_count', nogen
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d`i'
			save "`d`i''", replace		
		}
		
		
		
		clear
		tempfile paddy_innovation_fin
		save `paddy_innovation_fin', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_innovation_fin', replace
			
		}
		
		append using `paddy_cg'
		append using `paddy_tc'
		
		save `paddy_innovation_fin', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d`i'
			save "`d`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil
		save `paddy_variety_vil', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_variety_vil', replace
			
		}
		
		append using `paddy_cg_vil'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin', nogen
		
		merge 1:1 innovation using `med_year_paddy', nogen
		
		g innovation_label = "CG Paddy varieties" if innovation == 0
		replace innovation_label = "High yield paddy" if innovation == 1
		replace innovation_label = "Insect and disease resistant paddy" if innovation == 2
		replace innovation_label = "Early paddy variety" if innovation == 3 
		replace innovation_label = "Protein enriched paddy" if innovation == 4
		replace innovation_label = "Salt tolerant paddy" if innovation == 5
		replace innovation_label = "Flood tolerant paddy" if innovation == 6
		replace innovation_label = "Lodging tolerant paddy" if innovation == 7
		replace innovation_label = "Drought tolerant paddy" if innovation == 8
		replace innovation_label = "Short duration paddy" if innovation == 9
		replace innovation_label = "Zinc enriched paddy" if innovation == 10
		replace innovation_label = "Fertilizer- and water-saving paddy" if innovation == 11
		replace innovation_label = "Amylose enriched paddy" if innovation == 12
		replace innovation_label = "CG varieties (year 2000 and onwards)" if innovation == 13
		
		tempfile paddy_lower_est
		save `paddy_lower_est', replace
		
		u `paddy_village', clear
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 97

	}
		
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
	
	
	
		tempfile paddy_village_up
		save `paddy_village_up', replace
	
	local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
	
		foreach i of local paddy_up {
			
			u `paddy_village_up', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_up_`i'
		save "`paddy_vil_up_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil_up
		save `paddy_cg_vil_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_vil_up_`i''"
			save `paddy_cg_vil_up', replace
			
		}
			
		
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil_up', replace
		
		u `paddy_fin', clear
		

	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 97

	}
	

		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}	
		
		recode innovation_year . = 2019 if b2paddy_variety == 94
		recode innovation_year . = 2020 if b2paddy_variety == 97
		
		recode innovation_year . = 1997 if b2paddy_variety == 32
		recode innovation_year . = 2013 if b2paddy_variety == 58
		
		recode innovation_year . = 1986 if b2paddy_variety == 20
		recode innovation_year . = 1994 if b2paddy_variety == 26
		
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		
		preserve 
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg_up
		save `paddy_cg_up', replace
			
		restore
		
		preserve 
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin_up
		save `paddy_fin_up', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin_up', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin_up', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_up_`i'
	save "`w_p_up_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety_up
	save `med_paddy_variety_up', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_up_`i''"
	save `med_paddy_variety_up', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med_up
	save `paddy_cg_med_up', replace
	
	u `med_paddy_variety_up', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace
	

	forvalues i = 1/12 {
		
		u `med_paddy_variety_up', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year_up_`i'
		save "`med_year_up_`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy_up
	save `med_year_paddy_up', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year_up_`i''"
		save `med_year_paddy_up', replace
	}
	
	append using `paddy_cg_med_up'
	append using `paddy_tc_med'
	save `med_year_paddy_up', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin_up', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d_up_`i'
			save "`d_up_`i''", replace		
		}
		
		clear
		tempfile paddy_innovation_fin_up
		save `paddy_innovation_fin_up', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_innovation_fin_up', replace
			
		}
		
		append using `paddy_cg_up'
		append using `paddy_tc'
		
		save `paddy_innovation_fin_up', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village_up', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d_up_`i'
			save "`d_up_`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil_up
		save `paddy_variety_vil_up', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_variety_vil_up', replace
			
		}
		
		append using `paddy_cg_vil_up'
		append using `paddy_tc_vil'
		merge 1:1 innovation using `paddy_innovation_fin_up', nogen
		
		merge 1:1 innovation using `med_year_paddy_up', nogen
		ren (pct_vil pct_hh tot_reach median_year) (pct_vil_up pct_hh_up tot_reach_up median_year_up)
		
		merge 1:1 innovation using `paddy_lower_est', nogen // 2
		
		
		
		g total_reach = round((tot_reach/1000000), .01)
		
		g total_reach_up = round((tot_reach_up/1000000), .01)
		
				
		la var innovation_label "Name of crop innovation"
		la var pct_hh "% of HH with innovation among the crop cultivating HHs (lower bound)"
		la var pct_vil "% of villages with innovation (lower bound)"
		la var num_hh "Number of HH cultivating the crop in the Aman season (lower bound)"		
		la var total_reach "Estimated number of households (in millions) (lower bound)"
		la var median_year "Variety adoption percentage weighted release year of crop innovation (lower bound)"		
		la var pct_hh_up "% of HH with innovation among the crop cultivating HHs (upper bound)"
		la var pct_vil_up "% of villages with innovation (upper bound)"
		la var total_reach_up "Estimated number of households (in millions) (upper bound)"
		la var median_year_up "Variety adoption percentage weighted release year of crop innovation (upper bound)"
		
		drop tot_reach tot_reach_up num_hh merge_id
		
		order innovation_label pct_hh pct_vil total_reach median_year ///
		pct_hh_up pct_vil_up total_reach_up median_year_up

		preserve
		
		keep if innovation == 3 | innovation ==  10 | innovation == 11 | ///
		innovation == 5 | innovation ==  6 
		
		g blank_var = ""		
		egen pct_hh_new = concat(pct_hh blank_var), p("")
		egen pct_vil_new = concat(pct_vil blank_var), p("")
		egen total_reach_new = concat(total_reach blank_var), p("")
		egen median_year_new = concat(median_year blank_var), p("")
		
		
		tempfile lower_variety
		save `lower_variety', replace
		
		restore 
		
		
		drop if innovation == 3 | innovation ==  10 | innovation == 11 | ///
		innovation == 5 | innovation ==  6 
		
		egen pct_hh_new = concat(pct_hh pct_hh_up), p(/)
		egen pct_vil_new = concat(pct_vil pct_vil_up), p(/)
		egen total_reach_new = concat(total_reach total_reach_up), p(/)
		egen median_year_new = concat(median_year median_year_up), p(/)
		
		append using `lower_variety'
		
		drop pct_hh pct_hh_up pct_vil pct_vil_up total_reach total_reach_up ///
		median_year median_year_up blank_var

		replace median_year_new = "2001" if innovation == 0
		
		la var pct_hh_new "% of HH with innovation among the crop cultivating HHs (lower/upper bound)"
		la var pct_vil_new "% of villages with innovation (lower/upper bound)"
		la var total_reach_new "Estimated number of households (in millions) (lower/upper bound)"
		la var median_year_new "Variety adoption percentage weighted release year of crop innovation (lower/upper bound)"
		
		keep if inrange(innovation, 5, 7) | innovation == 10 | innovation == 0 | innovation == 13
		
		sort innovation
		
		drop innovation
		
		export excel "${final_table}${slash}table_19.xlsx", firstrow(varlabels) sh("table_19") sheetmodify
		
		* Table 20. Self-reported reach estimates for rice for Aus season across all plots
		
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
	
		forvalues i = 1/12 	{ 
			g innovation`i' = 0
			
		}
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86/-79 = 193
		
		
		keep if b2crop_season == 3
		keep if !mi(b2area) & !mi(b2paddy_variety) 
		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 24
		
		}
		
		local innovalue "2 3 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 25

		}
		
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 27

		}
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 39

		}
		
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 46

		}
		
		local innovalue "6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 50

		}
		
		local innovalue "6 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 51

		}
		
		local innovalue "1 3 4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 54

		}
		
		local innovalue "4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 55

		}
		
		
		
		local innovalue "1 4 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 61

		}
		
		local innovalue "1 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 63

		}
		
		local innovalue "1 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 65

		}
		
		local innovalue "1 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 66

		}
		
		local innovalue "1 4 8 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 70

		}
		
		local innovalue "1 4 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 71

		}
		
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 73

		}
		
		
		local innovalue "1 7 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 74

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 75

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 76

		}
		
		
		local innovalue "1 5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 77

		}
		
		
		
		local innovalue "1 6 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 84

		}
		
		local innovalue "11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 86

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 99

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

		}
		
		local innovalue "1 2 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 137

		}
		
		local innovalue "5 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 139

		}
		
		local innovalue "6 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 140

		}
		
		local innovalue "9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 145

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 146

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 149

		}
		
		
		local innovalue "5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 152

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 155

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 156

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 157

		}
		
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 158

		}
		
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 160

		}
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 161

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 178

	}
	
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 3

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 4

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 8

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 10

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 11

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 12

	}
	
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 13

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 19

	}
	
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 30

	}
	
		local innovalue "3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 48

	}
	
	
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 69

	}
		
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 68

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 98

	}
	
	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 56

		}
		
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 88

	}
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 22

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 40

	}
	
	local innovalue "8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 42

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 43

	}
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 52

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 80

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 87

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 90

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 91

	}
	
	
	local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

	}
	
	
	
		
	
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_`i'
		save "`paddy_vil_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil
		save `paddy_cg_vil', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_vil_`i''"
			save `paddy_cg_vil', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil', replace

		
		u `paddy_village', clear
		
	
		
		preserve
		
		g num_hh = 1
		
		collapse(max) num_hh, by(a1hhid_combined)
		
		g merge_id = 1
		
		collapse(count) num_hh, by(merge_id)
		
		tempfile paddy_hh_count
		save `paddy_hh_count', replace
		
		restore 
		
		
		g innovation_year = .
		recode innovation_year . = 1992 if b2paddy_variety == 24
		recode innovation_year . = 1993 if b2paddy_variety == 25
		recode innovation_year . = 1994 if b2paddy_variety == 27
		recode innovation_year . = 2003 if b2paddy_variety == 39
		recode innovation_year . = 2007 if b2paddy_variety == 46
		recode innovation_year . = 2010 if b2paddy_variety == 50
		recode innovation_year . = 2010 if b2paddy_variety == 51
		recode innovation_year . = 2011 if b2paddy_variety == 54
		recode innovation_year . = 2011 if b2paddy_variety == 55
	
		recode innovation_year . = 2013 if b2paddy_variety == 61
		recode innovation_year . = 2014 if b2paddy_variety == 63
		recode innovation_year . = 2014 if b2paddy_variety == 65
		recode innovation_year . = 2014 if b2paddy_variety == 66
		recode innovation_year . = 2015 if b2paddy_variety == 70
		recode innovation_year . = 2015 if b2paddy_variety == 71
		recode innovation_year . = 2015 if b2paddy_variety == 73
		recode innovation_year . = 2016 if b2paddy_variety == 74
		recode innovation_year . = 2016 if b2paddy_variety == 75
		recode innovation_year . = 2016 if b2paddy_variety == 76
		recode innovation_year . = 2016 if b2paddy_variety == 77
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2017 if b2paddy_variety == 84
		recode innovation_year . = 2018 if b2paddy_variety == 86
		recode innovation_year . = 2021 if b2paddy_variety == 99
		recode innovation_year . = 2022 if b2paddy_variety == 101
		
		recode innovation_year . = 2010 if b2paddy_variety == 137
		recode innovation_year . = 2012 if b2paddy_variety == 139
		recode innovation_year . = 2013 if b2paddy_variety == 140
		recode innovation_year . = 2014 if b2paddy_variety == 145
		recode innovation_year . = 2015 if b2paddy_variety == 146
		recode innovation_year . = 2017 if b2paddy_variety == 149
		recode innovation_year . = 2020 if b2paddy_variety == 152
		
		recode innovation_year . = 2001 if b2paddy_variety == 155
		recode innovation_year . = 2008 if b2paddy_variety == 156
		recode innovation_year . = 2009 if b2paddy_variety == 157
		recode innovation_year . = 2010 if b2paddy_variety == 158
		recode innovation_year . = 2017 if b2paddy_variety == 160
		recode innovation_year . = 2020 if b2paddy_variety == 161
		
		recode innovation_year . = 2017 if b2paddy_variety == 178
		
	
		
		recode innovation_year . = 1973 if b2paddy_variety == 3
		recode innovation_year . = 1975 if b2paddy_variety == 4
		recode innovation_year . = 1978 if b2paddy_variety == 8
		recode innovation_year . = 1980 if b2paddy_variety == 10
		recode innovation_year . = 1980 if b2paddy_variety == 11
		recode innovation_year . = 1983 if b2paddy_variety == 12
		recode innovation_year . = 1983 if b2paddy_variety == 13
		recode innovation_year . = 1986 if b2paddy_variety == 19
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 1994 if b2paddy_variety == 30
		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 48
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2015 if b2paddy_variety == 69
		
		recode innovation_year . = 1997 if b2paddy_variety == 32
		recode innovation_year . = 2013 if b2paddy_variety == 58
		recode innovation_year . = 2020 if b2paddy_variety == 98
		
		recode innovation_year . = 2018 if b2paddy_variety == 88

		recode innovation_year . = 1970 if b2paddy_variety == 1
		recode innovation_year . = 1971 if b2paddy_variety == 2
		recode innovation_year . = 1977 if b2paddy_variety == 6
		recode innovation_year . = 1983 if b2paddy_variety == 15
		
		recode innovation_year . = 1994 if b2paddy_variety == 28
		recode innovation_year . = 2014 if b2paddy_variety == 68
		recode innovation_year . = 2020 if b2paddy_variety == 98
		recode innovation_year . = 2018 if b2paddy_variety == 88
		recode innovation_year . = 2011 if b2paddy_variety == 56
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2014 if b2paddy_variety == 67
		recode innovation_year . = 2020 if b2paddy_variety == 95
		
		recode innovation_year . = 1983 if b2paddy_variety == 14
		recode innovation_year . = 1985 if b2paddy_variety == 16
		recode innovation_year . = 1985 if b2paddy_variety == 17
		recode innovation_year . = 1985 if b2paddy_variety == 18
		recode innovation_year . = 1988 if b2paddy_variety == 22
		recode innovation_year . = 1994 if b2paddy_variety == 31
		recode innovation_year . = 2003 if b2paddy_variety == 40
		recode innovation_year . = 2004 if b2paddy_variety == 42
		recode innovation_year . = 2005 if b2paddy_variety == 43
		recode innovation_year . = 2010 if b2paddy_variety == 52
		recode innovation_year . = 2012 if b2paddy_variety == 57
		recode innovation_year . = 2014 if b2paddy_variety == 62
		recode innovation_year . = 2017 if b2paddy_variety == 80
		recode innovation_year . = 2018 if b2paddy_variety == 87
		recode innovation_year . = 2019 if b2paddy_variety == 90
		recode innovation_year . = 2019 if b2paddy_variety == 91
		recode innovation_year . = 2022 if b2paddy_variety == 100
		recode innovation_year . = 2022 if b2paddy_variety == 101
		recode innovation_year . = 1998 if b2paddy_variety == 133
		recode innovation_year . = 1998 if b2paddy_variety == 134
		recode innovation_year . = 1998 if b2paddy_variety == 135
		recode innovation_year . = 2014 if b2paddy_variety == 144
	
		recode innovation_year . = 1988 if b2paddy_variety == 21
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2020 if b2paddy_variety == 96
		
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		preserve 
		
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg
		save `paddy_cg', replace
			
		restore
		
		preserve 
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin
		save `paddy_fin', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_`i'
	save "`w_p_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety
	save `med_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_`i''"
	save `med_paddy_variety', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med
	save `paddy_cg_med', replace
	
	u `med_paddy_variety', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	local inno_aus "1 2 3 4 5 6 7 9 10 11 12"
	
	foreach i of local inno_aus {
		
		u `med_paddy_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy
	save `med_year_paddy', emptyok
	
	foreach i of local inno_aus {
		append using "`med_year`i''"
		save `med_year_paddy', replace
	}
	
	append using `paddy_cg_med'
	append using `paddy_tc_med'
	save `med_year_paddy', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)

		
		g merge_id = 1
		
		merge 1:1 merge_id using `paddy_hh_count', nogen
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d`i'
			save "`d`i''", replace		
		}
		
		
		
		clear
		tempfile paddy_innovation_fin
		save `paddy_innovation_fin', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_innovation_fin', replace
			
		}
		
		append using `paddy_cg'
		append using `paddy_tc'
		
		save `paddy_innovation_fin', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d`i'
			save "`d`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil
		save `paddy_variety_vil', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_variety_vil', replace
			
		}
		
		append using `paddy_cg_vil'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin', nogen
		
		merge 1:1 innovation using `med_year_paddy', nogen
		
		g innovation_label = "CG Paddy varieties" if innovation == 0
		replace innovation_label = "High yield paddy" if innovation == 1
		replace innovation_label = "Insect and disease resistant paddy" if innovation == 2
		replace innovation_label = "Early paddy variety" if innovation == 3 
		replace innovation_label = "Protein enriched paddy" if innovation == 4
		replace innovation_label = "Salt tolerant paddy" if innovation == 5
		replace innovation_label = "Flood tolerant paddy" if innovation == 6
		replace innovation_label = "Lodging tolerant paddy" if innovation == 7
		replace innovation_label = "Drought tolerant paddy" if innovation == 8
		replace innovation_label = "Short duration paddy" if innovation == 9
		replace innovation_label = "Zinc enriched paddy" if innovation == 10
		replace innovation_label = "Fertilizer- and water-saving paddy" if innovation == 11
		replace innovation_label = "Amylose enriched paddy" if innovation == 12
		replace innovation_label = "CG varieties (year 2000 and onwards)" if innovation == 13
		
		tempfile paddy_lower_est
		save `paddy_lower_est', replace
		
		
		
		
		u `paddy_village', clear	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 97

	}
	
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
		tempfile paddy_village_up
		save `paddy_village_up', replace
	
	local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
	
	
	
		foreach i of local paddy_up {
			
			u `paddy_village_up', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_up_`i'
		save "`paddy_vil_up_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil_up
		save `paddy_cg_vil_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_vil_up_`i''"
			save `paddy_cg_vil_up', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil_up', replace

		u `paddy_fin', clear
		
			local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 68

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 97

	}
	
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 98

	}

		local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 56

		}
	
		
		local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 88

	}
		
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
		
		recode innovation_year . = 2019 if b2paddy_variety == 94
		recode innovation_year . = 2020 if b2paddy_variety == 97
		recode innovation_year . = 1997 if b2paddy_variety == 32
		recode innovation_year . = 2013 if b2paddy_variety == 58
		recode innovation_year . = 1986 if b2paddy_variety == 20
		recode innovation_year . = 1994 if b2paddy_variety == 26
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		
		preserve 
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg_up
		save `paddy_cg_up', replace
			
		restore
		
		
		preserve 
 
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		
		tempfile paddy_fin_up
		save `paddy_fin_up', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin_up', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin_up', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_up_`i'
	save "`w_p_up_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety_up
	save `med_paddy_variety_up', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_up_`i''"
	save `med_paddy_variety_up', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med_up
	save `paddy_cg_med_up', replace
	
	u `med_paddy_variety_up', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	foreach i of local inno_aus {
		
		u `med_paddy_variety_up', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year_up_`i'
		save "`med_year_up_`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy_up
	save `med_year_paddy_up', emptyok
	
	foreach i of local inno_aus {
		append using "`med_year_up_`i''"
		save `med_year_paddy_up', replace
	}
	
	append using `paddy_cg_med_up'
	append using `paddy_tc_med'
	save `med_year_paddy_up', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin_up', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d_up_`i'
			save "`d_up_`i''", replace		
		}
		
		clear
		tempfile paddy_innovation_fin_up
		save `paddy_innovation_fin_up', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_innovation_fin_up', replace
			
		}
		
		append using `paddy_cg_up'
		append using `paddy_tc'
		
		save `paddy_innovation_fin_up', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village_up', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d_up_`i'
			save "`d_up_`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil_up
		save `paddy_variety_vil_up', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_variety_vil_up', replace
			
		}
		
		append using `paddy_cg_vil_up'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin_up', nogen
		
		merge 1:1 innovation using `med_year_paddy_up', nogen
		ren (pct_vil pct_hh tot_reach median_year) (pct_vil_up pct_hh_up tot_reach_up median_year_up)
		
		merge 1:1 innovation using `paddy_lower_est', nogen 
				
		g total_reach = round((tot_reach/1000000), .001)
		
		g total_reach_up = round((tot_reach_up/1000000), .001)
		
		la var innovation_label "Name of crop innovation"
		la var pct_hh "% of HH with innovation among the crop cultivating HHs (lower bound)"
		la var pct_vil "% of villages with innovation (lower bound)"
		la var num_hh "Number of HH cultivating the crop in the Aman season (lower bound)"
		la var total_reach "Estimated number of households (in millions) (lower bound)"
		la var median_year "Variety adoption percentage weighted release year of crop innovation (lower bound)"
		la var pct_hh_up "% of HH with innovation among the crop cultivating HHs (upper bound)"
		la var pct_vil_up "% of villages with innovation (upper bound)"
		la var total_reach_up "Estimated number of households (in millions) (upper bound)"
		la var median_year_up "Variety adoption percentage weighted release year of crop innovation (upper bound)"
		
		drop tot_reach tot_reach_up num_hh merge_id
		
		order innovation_label pct_hh pct_vil total_reach median_year ///
		pct_hh_up pct_vil_up total_reach_up median_year_up
			
		preserve
		
		keep if innovation == 3 | innovation ==  10 | innovation == 11 | ///
		innovation == 5 | innovation ==  6 | innovation == 7
		
		g blank_var = ""		
		egen pct_hh_new = concat(pct_hh blank_var), p("")
		egen pct_vil_new = concat(pct_vil blank_var), p("")
		egen total_reach_new = concat(total_reach blank_var), p("")
		egen median_year_new = concat(median_year blank_var), p("")
		
		
		tempfile lower_variety
		save `lower_variety', replace
		
		restore 
		
		
		drop if innovation == 3 | innovation ==  10 | innovation == 11 | ///
		innovation == 5 | innovation ==  6 | innovation == 7
		
		egen pct_hh_new = concat(pct_hh pct_hh_up), p(/)
		egen pct_vil_new = concat(pct_vil pct_vil_up), p(/)
		egen total_reach_new = concat(total_reach total_reach_up), p(/)
		egen median_year_new = concat(median_year median_year_up), p(/)
		
		append using `lower_variety'
				
		drop pct_hh pct_hh_up pct_vil pct_vil_up total_reach total_reach_up ///
		median_year median_year_up blank_var
		
		//Replacing median years where they are the same for upper and lower bound
		replace median_year_new = "2000" if innovation == 0
				
		la var pct_hh_new "% of HH with innovation among the crop cultivating HHs (lower/upper bound)"
		la var pct_vil_new "% of villages with innovation (lower/upper bound)"
		la var total_reach_new "Estimated number of households (in millions) (lower/upper bound)"
		la var median_year_new "Variety adoption percentage weighted release year of crop innovation (lower/upper bound)"
		
		keep if inrange(innovation, 5, 7) | innovation == 10 | innovation == 0 | innovation == 13
		
		sort innovation
		
		drop innovation
		
		export excel "${final_table}${slash}table_20.xlsx", firstrow(varlabels) sh("table_20") sheetmodify
				
	
		* Table 18. Comparison of major Aman variety adoption between the SPIA-BIHS survey and Kretzschmar et al. (2018).
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86/-79 = 193
		
		
		keep if b2crop_season == 2
		keep if !mi(b2area) & !mi(b2paddy_variety)
		levelsof b2paddy_variety, local(paddy_levels)
		
		g innovation_year = .
		recode innovation_year . = 1992 if b2paddy_variety == 24
		recode innovation_year . = 1993 if b2paddy_variety == 25
		recode innovation_year . = 1994 if b2paddy_variety == 27
		recode innovation_year . = 2003 if b2paddy_variety == 39
		recode innovation_year . = 2007 if b2paddy_variety == 46
		recode innovation_year . = 2010 if b2paddy_variety == 50
		recode innovation_year . = 2010 if b2paddy_variety == 51
		recode innovation_year . = 2011 if b2paddy_variety == 54
		recode innovation_year . = 2011 if b2paddy_variety == 55
		recode innovation_year . = 2011 if b2paddy_variety == 56
		recode innovation_year . = 2013 if b2paddy_variety == 61
		recode innovation_year . = 2014 if b2paddy_variety == 63
		recode innovation_year . = 2014 if b2paddy_variety == 65
		recode innovation_year . = 2014 if b2paddy_variety == 66
		recode innovation_year . = 2015 if b2paddy_variety == 70
		recode innovation_year . = 2015 if b2paddy_variety == 71
		recode innovation_year . = 2015 if b2paddy_variety == 73
		recode innovation_year . = 2016 if b2paddy_variety == 74
		recode innovation_year . = 2016 if b2paddy_variety == 75
		recode innovation_year . = 2016 if b2paddy_variety == 76
		recode innovation_year . = 2016 if b2paddy_variety == 77
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2017 if b2paddy_variety == 84
		recode innovation_year . = 2018 if b2paddy_variety == 86
		recode innovation_year . = 2021 if b2paddy_variety == 99
		recode innovation_year . = 2022 if b2paddy_variety == 101
		
		recode innovation_year . = 2010 if b2paddy_variety == 137
		recode innovation_year . = 2012 if b2paddy_variety == 139
		recode innovation_year . = 2013 if b2paddy_variety == 140
		recode innovation_year . = 2014 if b2paddy_variety == 145
		recode innovation_year . = 2015 if b2paddy_variety == 146
		recode innovation_year . = 2017 if b2paddy_variety == 149
		recode innovation_year . = 2020 if b2paddy_variety == 152
		
		recode innovation_year . = 2001 if b2paddy_variety == 155
		recode innovation_year . = 2008 if b2paddy_variety == 156
		recode innovation_year . = 2009 if b2paddy_variety == 157
		recode innovation_year . = 2010 if b2paddy_variety == 158
		recode innovation_year . = 2017 if b2paddy_variety == 160
		recode innovation_year . = 2020 if b2paddy_variety == 161
		
		recode innovation_year . = 2017 if b2paddy_variety == 178
		
		tempfile paddy_fin
		save `paddy_fin', replace
				
		foreach i of local paddy_levels {
			u `paddy_fin', clear
	
	recode paddy_variety . = `i'
	 
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin', nogen keep(3) keepusing(innovation_year)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year, by(paddy_variety)
	
	replace mean_hh = round(mean_hh*100, .01)
	
	tempfile w_v_`i'
	save "`w_v_`i''", replace
	
	}
	
	
	clear
	tempfile aman_paddy_variety
	save `aman_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_v_`i''"
	save `aman_paddy_variety', replace
	
	}
	
	
	u `aman_paddy_variety', clear
	
	keep if mean_hh >= 1
	gsort -mean_hh
	drop if paddy_variety == 193
	ren paddy_variety b2paddy_variety
	
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
                          27  "Bri Dhan BR-28" ///
                          28  "Bri Dhan BR-29" ///
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
						193 "Others", modify
						
						la val b2paddy_variety b2paddy_variety
		
		drop year

		export excel "${final_table}${slash}table_18.xlsx", firstrow(varlabels) sh("table_18") sheetmodify
	
		* Table 16. Comparison of reach estimates between DNA fingerprinting and self-reported varieties in Boro 2023-24 for the PPS sampling plot		
		u "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta", clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen keep(3)
	
		forvalues i = 1/12 	{ 
			g innovation`i' = 0
			
		}
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode c2paddy_mainvariety -86 = 210
		
		
		levelsof c2paddy_mainvariety, local(paddy_levels)
		
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 24
		
		}
		
		local innovalue "2 3 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 25

		}
		
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 27

		}
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 39

		}
		
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 46

		}
		
		local innovalue "6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 50

		}
		
		local innovalue "6 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 51

		}
		
		local innovalue "1 3 4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 54

		}
		
		local innovalue "4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 55

		}
		
		
		
		local innovalue "1 4 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 61

		}
		
		local innovalue "1 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 63

		}
		
		local innovalue "1 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 65

		}
		
		local innovalue "1 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 66

		}
		
		local innovalue "1 4 8 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 70

		}
		
		local innovalue "1 4 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 71

		}
		
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 73

		}
		
		
		local innovalue "1 7 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 74

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 75

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 76

		}
		
		
		local innovalue "1 5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 77

		}
		
		
		local innovalue "1 6 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 84

		}
		
		local innovalue "11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 86

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 99

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 101

		}
		
		local innovalue "1 2 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 137

		}
		
		local innovalue "5 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 139

		}
		
		local innovalue "6 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 140

		}
		
		local innovalue "9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 145

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 146

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 149

		}
		
		
		local innovalue "5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 152

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 155

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 156

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 157

		}
		
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 158

		}
		
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 160

		}
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 161

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 178

	}
	
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 3

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 4

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 8

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 10

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 11

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 12

	}
	
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 13

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 19

	}
	
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 30

	}
	
		local innovalue "3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 48

	}
	
	
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 69

	}
		
		local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 98

	}

	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 56

		}
	
	
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 88

	}
		
		
		
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 68

	}
	
	
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 22

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 40

	}
	
	local innovalue "8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 42

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 43

	}
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 52

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 80

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 87

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 90

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 91

	}
	
	
	local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 101

	}
	
	
	
	
		tempfile paddy_village
		save `paddy_village', replace
		
		
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if c2paddy_mainvariety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_`i'
		save "`paddy_vil_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil
		save `paddy_cg_vil', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_vil_`i''"
			save `paddy_cg_vil', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil', replace

		
		u `paddy_village', clear
		
		
		preserve
		
		g num_hh = 1
		
		collapse(max) num_hh, by(a1hhid_combined)
		
		g merge_id = 1
		
		collapse(count) num_hh, by(merge_id)
		
		tempfile paddy_hh_count
		save `paddy_hh_count', replace
		
		restore 
		
		
		g innovation_year = .
		recode innovation_year . = 1992 if c2paddy_mainvariety == 24
		recode innovation_year . = 1993 if c2paddy_mainvariety == 25
		recode innovation_year . = 1994 if c2paddy_mainvariety == 27
		recode innovation_year . = 2003 if c2paddy_mainvariety == 39
		recode innovation_year . = 2007 if c2paddy_mainvariety == 46
		recode innovation_year . = 2010 if c2paddy_mainvariety == 50
		recode innovation_year . = 2010 if c2paddy_mainvariety == 51
		recode innovation_year . = 2011 if c2paddy_mainvariety == 54
		recode innovation_year . = 2011 if c2paddy_mainvariety == 55
		recode innovation_year . = 2013 if c2paddy_mainvariety == 61
		recode innovation_year . = 2014 if c2paddy_mainvariety == 63
		recode innovation_year . = 2014 if c2paddy_mainvariety == 65
		recode innovation_year . = 2014 if c2paddy_mainvariety == 66
		recode innovation_year . = 2015 if c2paddy_mainvariety == 70
		recode innovation_year . = 2015 if c2paddy_mainvariety == 71
		recode innovation_year . = 2015 if c2paddy_mainvariety == 73
		recode innovation_year . = 2016 if c2paddy_mainvariety == 74
		recode innovation_year . = 2016 if c2paddy_mainvariety == 75
		recode innovation_year . = 2016 if c2paddy_mainvariety == 76
		recode innovation_year . = 2016 if c2paddy_mainvariety == 77
		
		recode innovation_year . = 2017 if c2paddy_mainvariety == 84
		recode innovation_year . = 2018 if c2paddy_mainvariety == 86
		recode innovation_year . = 2021 if c2paddy_mainvariety == 99
		recode innovation_year . = 2022 if c2paddy_mainvariety == 101
		
		recode innovation_year . = 2010 if c2paddy_mainvariety == 137
		recode innovation_year . = 2012 if c2paddy_mainvariety == 139
		recode innovation_year . = 2013 if c2paddy_mainvariety == 140
		recode innovation_year . = 2014 if c2paddy_mainvariety == 145
		recode innovation_year . = 2015 if c2paddy_mainvariety == 146
		recode innovation_year . = 2017 if c2paddy_mainvariety == 149
		recode innovation_year . = 2020 if c2paddy_mainvariety == 152
		
		recode innovation_year . = 2001 if c2paddy_mainvariety == 155
		recode innovation_year . = 2008 if c2paddy_mainvariety == 156
		recode innovation_year . = 2009 if c2paddy_mainvariety == 157
		recode innovation_year . = 2010 if c2paddy_mainvariety == 158
		recode innovation_year . = 2017 if c2paddy_mainvariety == 160
		recode innovation_year . = 2020 if c2paddy_mainvariety == 161
		
		recode innovation_year . = 2017 if c2paddy_mainvariety == 178
		
		recode innovation_year . = 1973 if c2paddy_mainvariety == 3
		recode innovation_year . = 1975 if c2paddy_mainvariety == 4
		recode innovation_year . = 1978 if c2paddy_mainvariety == 8
		recode innovation_year . = 1980 if c2paddy_mainvariety == 10
		recode innovation_year . = 1980 if c2paddy_mainvariety == 11
		recode innovation_year . = 1983 if c2paddy_mainvariety == 12
		recode innovation_year . = 1983 if c2paddy_mainvariety == 13
		recode innovation_year . = 1986 if c2paddy_mainvariety == 19
		recode innovation_year . = 1994 if c2paddy_mainvariety == 29
		recode innovation_year . = 1994 if c2paddy_mainvariety == 30
		recode innovation_year . = 2007 if c2paddy_mainvariety == 45
		recode innovation_year . = 2008 if c2paddy_mainvariety == 47
		recode innovation_year . = 2008 if c2paddy_mainvariety == 48
		recode innovation_year . = 2008 if c2paddy_mainvariety == 49
		recode innovation_year . = 2015 if c2paddy_mainvariety == 69
		
		recode innovation_year . = 1983 if c2paddy_mainvariety == 15
		
	
		recode innovation_year . = 1994 if c2paddy_mainvariety == 28
		recode innovation_year . = 2014 if c2paddy_mainvariety == 68
		recode innovation_year . = 2020 if c2paddy_mainvariety == 98
		recode innovation_year . = 2018 if c2paddy_mainvariety == 88
		recode innovation_year . = 2011 if c2paddy_mainvariety == 56
		recode innovation_year . = 2017 if c2paddy_mainvariety == 78

		recode innovation_year . = 2007 if c2paddy_mainvariety == 45
		recode innovation_year . = 2014 if c2paddy_mainvariety == 67
		recode innovation_year . = 2020 if c2paddy_mainvariety == 95
				
		recode innovation_year . = 1983 if c2paddy_mainvariety == 14
		recode innovation_year . = 1985 if c2paddy_mainvariety == 16
		recode innovation_year . = 1985 if c2paddy_mainvariety == 17
		recode innovation_year . = 1985 if c2paddy_mainvariety == 18
		recode innovation_year . = 1988 if c2paddy_mainvariety == 22
		recode innovation_year . = 1994 if c2paddy_mainvariety == 31
		recode innovation_year . = 2003 if c2paddy_mainvariety == 40
		recode innovation_year . = 2004 if c2paddy_mainvariety == 42
		recode innovation_year . = 2005 if c2paddy_mainvariety == 43
		recode innovation_year . = 2010 if c2paddy_mainvariety == 52
		recode innovation_year . = 2012 if c2paddy_mainvariety == 57
		recode innovation_year . = 2014 if c2paddy_mainvariety == 62
		recode innovation_year . = 2017 if c2paddy_mainvariety == 80
		recode innovation_year . = 2018 if c2paddy_mainvariety == 87
		recode innovation_year . = 2019 if c2paddy_mainvariety == 90
		recode innovation_year . = 2019 if c2paddy_mainvariety == 91
		recode innovation_year . = 2022 if c2paddy_mainvariety == 100
		recode innovation_year . = 2022 if c2paddy_mainvariety == 101
		recode innovation_year . = 1998 if c2paddy_mainvariety == 133
		recode innovation_year . = 1998 if c2paddy_mainvariety == 134
		recode innovation_year . = 1998 if c2paddy_mainvariety == 135
		recode innovation_year . = 2014 if c2paddy_mainvariety == 144
		
		recode innovation_year . = 1988 if c2paddy_mainvariety == 21
		recode innovation_year . = 1994 if c2paddy_mainvariety == 29
		recode innovation_year . = 2008 if c2paddy_mainvariety == 47
		recode innovation_year . = 2008 if c2paddy_mainvariety == 49
		recode innovation_year . = 2020 if c2paddy_mainvariety == 96

		preserve 
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg
		save `paddy_cg', replace
			
		restore
		
		tempfile paddy_fin
		save `paddy_fin', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if c2paddy_mainvariety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety c2paddy_mainvariety
	merge 1:m c2paddy_mainvariety using `paddy_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren c2paddy_mainvariety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_`i'
	save "`w_p_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety
	save `med_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_`i''"
	save `med_paddy_variety', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med
	save `paddy_cg_med', replace

	
	forvalues i = 1/12 {
		
		u `med_paddy_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy
	save `med_year_paddy', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year`i''"
		save `med_year_paddy', replace
	}
	
	append using `paddy_cg_med'
	save `med_year_paddy', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)

		
		g merge_id = 1
		
		merge 1:1 merge_id using `paddy_hh_count', nogen
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d`i'
			save "`d`i''", replace		
		}
		
		
		
		clear
		tempfile paddy_innovation_fin
		save `paddy_innovation_fin', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_innovation_fin', replace
			
		}
		
		append using `paddy_cg'
		
		save `paddy_innovation_fin', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d`i'
			save "`d`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil
		save `paddy_variety_vil', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_variety_vil', replace
			
		}
		
		append using `paddy_cg_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin', nogen
		
		merge 1:1 innovation using `med_year_paddy', nogen
		
		g innovation_label = "CG Paddy varieties" if innovation == 0
		replace innovation_label = "High yield paddy" if innovation == 1
		replace innovation_label = "Insect and disease resistant paddy" if innovation == 2
		replace innovation_label = "Early paddy variety" if innovation == 3 
		replace innovation_label = "Protein enriched paddy" if innovation == 4
		replace innovation_label = "Salt tolerant paddy" if innovation == 5
		replace innovation_label = "Flood tolerant paddy" if innovation == 6
		replace innovation_label = "Lodging tolerant paddy" if innovation == 7
		replace innovation_label = "Drought tolerant paddy" if innovation == 8
		replace innovation_label = "Short duration paddy" if innovation == 9
		replace innovation_label = "Zinc enriched paddy" if innovation == 10
		replace innovation_label = "Fertilizer- and water-saving paddy" if innovation == 11
		replace innovation_label = "Amylose enriched paddy" if innovation == 12
		replace innovation_label = "CG varieties (year 2000 and onwards)" if innovation == 13
		
		tempfile paddy_lower_est
		save `paddy_lower_est', replace
		
			
		u `paddy_village', clear

	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 97

	}
	
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}
	

		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}

	
	
	
		tempfile paddy_village_up
		save `paddy_village_up', replace
	
	local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
	
	
	
		foreach i of local paddy_up {
			
			u `paddy_village_up', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if c2paddy_mainvariety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_up_`i'
		save "`paddy_vil_up_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil_up
		save `paddy_cg_vil_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_vil_up_`i''"
			save `paddy_cg_vil_up', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil_up', replace

		u `paddy_fin', clear
		
			local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 68

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 97

	}
		
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 98

	}
	
	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 56

		}
	
		local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 88

	}

		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}
		recode innovation_year . = 2019 if c2paddy_mainvariety == 94
		recode innovation_year . = 2020 if c2paddy_mainvariety == 97

		recode innovation_year . = 1997 if c2paddy_mainvariety == 32
		recode innovation_year . = 2013 if c2paddy_mainvariety == 58
		recode innovation_year . = 1986 if c2paddy_mainvariety == 20
		recode innovation_year . = 1994 if c2paddy_mainvariety == 26
		
		preserve 
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg_up
		save `paddy_cg_up', replace
			
		restore
		
		tempfile paddy_fin_up
		save `paddy_fin_up', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin_up', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if c2paddy_mainvariety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety c2paddy_mainvariety
	merge 1:m c2paddy_mainvariety using `paddy_fin_up', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren c2paddy_mainvariety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_up_`i'
	save "`w_p_up_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety_up
	save `med_paddy_variety_up', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_up_`i''"
	save `med_paddy_variety_up', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med_up
	save `paddy_cg_med_up', replace

	forvalues i = 1/12 {
		
		u `med_paddy_variety_up', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year_up_`i'
		save "`med_year_up_`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy_up
	save `med_year_paddy_up', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year_up_`i''"
		save `med_year_paddy_up', replace
	}
	
	append using `paddy_cg_med_up'
	save `med_year_paddy_up', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin_up', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d_up_`i'
			save "`d_up_`i''", replace		
		}
		
		clear
		tempfile paddy_innovation_fin_up
		save `paddy_innovation_fin_up', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_innovation_fin_up', replace
			
		}
		
		append using `paddy_cg_up'
		
		save `paddy_innovation_fin_up', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village_up', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d_up_`i'
			save "`d_up_`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil_up
		save `paddy_variety_vil_up', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_variety_vil_up', replace
			
		}
		
		append using `paddy_cg_vil_up'
		
		merge 1:1 innovation using `paddy_innovation_fin_up', nogen
		
		merge 1:1 innovation using `med_year_paddy_up', nogen
		ren (pct_vil pct_hh tot_reach median_year) (pct_vil_up pct_hh_up tot_reach_up median_year_up)
		
		merge 1:1 innovation using `paddy_lower_est', nogen 	
				

		
		g total_reach = round((tot_reach/1000000), .01)
		
		g total_reach_up = round((tot_reach_up/1000000), .01)
			
		la var innovation_label "Name of crop innovation"
		la var pct_hh "% of HH with innovation among the crop cultivating HHs (lower bound)"
		la var pct_vil "% of villages with innovation (lower bound)"
		la var num_hh "Number of HH cultivating the crop in the past three seasons (lower bound)"
		la var total_reach "Estimated number of households (in millions) (lower bound)"
		la var median_year "Variety adoption percentage weighted release year of crop innovation (lower bound)"
		
		la var pct_hh_up "% of HH with innovation among the crop cultivating HHs (upper bound)"
		la var pct_vil_up "% of villages with innovation (upper bound)"
		la var total_reach_up "Estimated number of households (in millions) (upper bound)"
		la var median_year_up "Variety adoption percentage weighted release year of crop innovation (upper bound)"
		
		
		
		drop tot_reach tot_reach_up num_hh merge_id
		
		order innovation_label pct_hh pct_vil total_reach median_year ///
		pct_hh_up pct_vil_up total_reach_up median_year_up
	
		preserve
		
		keep if innovation == 3 | innovation ==  10 | innovation == 11 | innovation == 8 | ///
		innovation == 5 | innovation ==  6
		
		g blank_var = ""		
		egen pct_hh_new = concat(pct_hh blank_var), p("")
		egen pct_vil_new = concat(pct_vil blank_var), p("")
		egen total_reach_new = concat(total_reach blank_var), p("")
		egen median_year_new = concat(median_year blank_var), p("")
		
		
		tempfile lower_variety
		save `lower_variety', replace
		
		restore 
		
		
		drop if innovation == 3 | innovation ==  10 | innovation == 11 | innovation == 8 | ///
		innovation == 5 | innovation ==  6
		
		egen pct_hh_new = concat(pct_hh pct_hh_up), p(/)
		egen pct_vil_new = concat(pct_vil pct_vil_up), p(/)
		egen total_reach_new = concat(total_reach total_reach_up), p(/)
		egen median_year_new = concat(median_year median_year_up), p(/)
		
		append using `lower_variety'
		
		
		drop pct_hh pct_hh_up pct_vil pct_vil_up total_reach total_reach_up ///
		median_year median_year_up blank_var
		
		la var pct_hh_new "% of HH with innovation among the crop cultivating HHs (lower/upper bound)"
		la var pct_vil_new "% of villages with innovation (lower/upper bound)"
		la var total_reach_new "Estimated number of households (in millions) (lower/upper bound)"
		la var median_year_new "Variety adoption percentage weighted release year of crop innovation (lower/upper bound)"
		
		//Replacing median years where they are the same for upper and lower bound
		replace median_year_new = "2001" if innovation == 0 
		replace median_year_new = "2017" if innovation == 7
		
		sort innovation
		keep if inrange(innovation, 5, 7) | innovation == 10 | innovation == 0
		drop innovation


		export excel "${final_table}${slash}table_16.xlsx", firstrow(varlabels) sh("table_16") sheetmodify
		
		* Table 15. DNA fingerprinting results reach estimates for rice in Boro 2023-24 for the PPS sampling selected plot
		
		import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear

		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24 a1village) keep(3) nogen

		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(1 3)
		
		drop c2paddy_mainvariety
		
		ren c2paddy_sample c2paddy_mainvariety
		
		forvalues i = 1/12 	{ 
			g innovation`i' = 0
			
		}
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode c2paddy_mainvariety -86 = 210
		
		
		levelsof c2paddy_mainvariety, local(paddy_levels)
		
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 24
		
		}
		
		local innovalue "2 3 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 25

		}
		
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 27

		}
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 39

		}
		
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 46

		}
		
		local innovalue "6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 50

		}
		
		local innovalue "6 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 51

		}
		
		local innovalue "1 3 4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 54

		}
		
		local innovalue "4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 55

		}
		
		
		
		local innovalue "1 4 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 61

		}
		
		local innovalue "1 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 63

		}
		
		local innovalue "1 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 65

		}
		
		local innovalue "1 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 66

		}
		
		local innovalue "1 4 8 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 70

		}
		
		local innovalue "1 4 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 71

		}
		
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 73

		}
		
		
		local innovalue "1 7 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 74

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 75

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 76

		}
		
		
		local innovalue "1 5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 77

		}
		
		
		local innovalue "1 6 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 84

		}
		
		local innovalue "11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 86

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 99

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 101

		}
		
		local innovalue "1 2 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 137

		}
		
		local innovalue "5 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 139

		}
		
		local innovalue "6 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 140

		}
		
		local innovalue "9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 145

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 146

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 149

		}
		
		
		local innovalue "5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 152

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 155

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 156

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 157

		}
		
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 158

		}
		
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 160

		}
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 161

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 178

	}
	

		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 3

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 4

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 8

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 10

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 11

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 12

	}
	
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 13

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 19

	}
	
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 30

	}
	
		local innovalue "3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 48

	}
	
	
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 69

	}
	
	
	local innovalue "5"
	
	foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 96

	}
			
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 68

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 98

	}
	
	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 56

		}
	
	
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 88

	}
	

	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 22

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 40

	}
	
	local innovalue "8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 42

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 43

	}
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 52

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 80

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 87

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 90

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 91

	}
	
	
	local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 101

	}
	
	
	
	
		tempfile paddy_village
		save `paddy_village', replace
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if c2paddy_mainvariety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_`i'
		save "`paddy_vil_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil
		save `paddy_cg_vil', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_vil_`i''"
			save `paddy_cg_vil', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil', replace

		
		u `paddy_village', clear
		
		
		preserve
		
		g num_hh = 1
		
		collapse(max) num_hh, by(a1hhid_combined)
		
		g merge_id = 1
		
		collapse(count) num_hh, by(merge_id)
		
		tempfile paddy_hh_count
		save `paddy_hh_count', replace
		
		restore 
		
		
		g innovation_year = .
		recode innovation_year . = 1992 if c2paddy_mainvariety == 24
		recode innovation_year . = 1993 if c2paddy_mainvariety == 25
		recode innovation_year . = 1994 if c2paddy_mainvariety == 27
		recode innovation_year . = 2003 if c2paddy_mainvariety == 39
		recode innovation_year . = 2007 if c2paddy_mainvariety == 46
		recode innovation_year . = 2010 if c2paddy_mainvariety == 50
		recode innovation_year . = 2010 if c2paddy_mainvariety == 51
		recode innovation_year . = 2011 if c2paddy_mainvariety == 54
		recode innovation_year . = 2011 if c2paddy_mainvariety == 55
		recode innovation_year . = 2013 if c2paddy_mainvariety == 61
		recode innovation_year . = 2014 if c2paddy_mainvariety == 63
		recode innovation_year . = 2014 if c2paddy_mainvariety == 65
		recode innovation_year . = 2014 if c2paddy_mainvariety == 66
		recode innovation_year . = 2015 if c2paddy_mainvariety == 70
		recode innovation_year . = 2015 if c2paddy_mainvariety == 71
		recode innovation_year . = 2015 if c2paddy_mainvariety == 73
		recode innovation_year . = 2016 if c2paddy_mainvariety == 74
		recode innovation_year . = 2016 if c2paddy_mainvariety == 75
		recode innovation_year . = 2016 if c2paddy_mainvariety == 76
		recode innovation_year . = 2016 if c2paddy_mainvariety == 77
		
		recode innovation_year . = 2017 if c2paddy_mainvariety == 84
		recode innovation_year . = 2018 if c2paddy_mainvariety == 86
		recode innovation_year . = 2021 if c2paddy_mainvariety == 99
		recode innovation_year . = 2022 if c2paddy_mainvariety == 101
		
		recode innovation_year . = 2010 if c2paddy_mainvariety == 137
		recode innovation_year . = 2012 if c2paddy_mainvariety == 139
		recode innovation_year . = 2013 if c2paddy_mainvariety == 140
		recode innovation_year . = 2014 if c2paddy_mainvariety == 145
		recode innovation_year . = 2015 if c2paddy_mainvariety == 146
		recode innovation_year . = 2017 if c2paddy_mainvariety == 149
		recode innovation_year . = 2020 if c2paddy_mainvariety == 152
		
		recode innovation_year . = 2001 if c2paddy_mainvariety == 155
		recode innovation_year . = 2008 if c2paddy_mainvariety == 156
		recode innovation_year . = 2009 if c2paddy_mainvariety == 157
		recode innovation_year . = 2010 if c2paddy_mainvariety == 158
		recode innovation_year . = 2017 if c2paddy_mainvariety == 160
		recode innovation_year . = 2020 if c2paddy_mainvariety == 161
		
		recode innovation_year . = 2017 if c2paddy_mainvariety == 178
		
		recode innovation_year . = 1973 if c2paddy_mainvariety == 3
		recode innovation_year . = 1975 if c2paddy_mainvariety == 4
		recode innovation_year . = 1978 if c2paddy_mainvariety == 8
		recode innovation_year . = 1980 if c2paddy_mainvariety == 10
		recode innovation_year . = 1980 if c2paddy_mainvariety == 11
		recode innovation_year . = 1983 if c2paddy_mainvariety == 12
		recode innovation_year . = 1983 if c2paddy_mainvariety == 13
		recode innovation_year . = 1986 if c2paddy_mainvariety == 19
		recode innovation_year . = 1994 if c2paddy_mainvariety == 29
		recode innovation_year . = 1994 if c2paddy_mainvariety == 30
		recode innovation_year . = 2007 if c2paddy_mainvariety == 45
		recode innovation_year . = 2008 if c2paddy_mainvariety == 47
		recode innovation_year . = 2008 if c2paddy_mainvariety == 48
		recode innovation_year . = 2008 if c2paddy_mainvariety == 49
		recode innovation_year . = 2015 if c2paddy_mainvariety == 69
		
		recode innovation_year . = 2020 if c2paddy_mainvariety == 96
		recode innovation_year . = 1983 if c2paddy_mainvariety == 15
		
		recode innovation_year . = 1994 if c2paddy_mainvariety == 28
		recode innovation_year . = 2014 if c2paddy_mainvariety == 68
		recode innovation_year . = 2020 if c2paddy_mainvariety == 98
		recode innovation_year . = 2018 if c2paddy_mainvariety == 88
		recode innovation_year . = 2011 if c2paddy_mainvariety == 56
		recode innovation_year . = 2017 if c2paddy_mainvariety == 78

		recode innovation_year . = 2007 if c2paddy_mainvariety == 45
		recode innovation_year . = 2014 if c2paddy_mainvariety == 67
		recode innovation_year . = 2020 if c2paddy_mainvariety == 95
		
		recode innovation_year . = 1983 if c2paddy_mainvariety == 14
		recode innovation_year . = 1985 if c2paddy_mainvariety == 16
		recode innovation_year . = 1985 if c2paddy_mainvariety == 17
		recode innovation_year . = 1985 if c2paddy_mainvariety == 18
		recode innovation_year . = 1988 if c2paddy_mainvariety == 22
		recode innovation_year . = 1994 if c2paddy_mainvariety == 31
		recode innovation_year . = 2003 if c2paddy_mainvariety == 40
		recode innovation_year . = 2004 if c2paddy_mainvariety == 42
		recode innovation_year . = 2005 if c2paddy_mainvariety == 43
		recode innovation_year . = 2010 if c2paddy_mainvariety == 52
		recode innovation_year . = 2012 if c2paddy_mainvariety == 57
		recode innovation_year . = 2014 if c2paddy_mainvariety == 62
		recode innovation_year . = 2017 if c2paddy_mainvariety == 80
		recode innovation_year . = 2018 if c2paddy_mainvariety == 87
		recode innovation_year . = 2019 if c2paddy_mainvariety == 90
		recode innovation_year . = 2019 if c2paddy_mainvariety == 91
		recode innovation_year . = 2022 if c2paddy_mainvariety == 100
		recode innovation_year . = 2022 if c2paddy_mainvariety == 101
		recode innovation_year . = 1998 if c2paddy_mainvariety == 133
		recode innovation_year . = 1998 if c2paddy_mainvariety == 134
		recode innovation_year . = 1998 if c2paddy_mainvariety == 135
		recode innovation_year . = 2014 if c2paddy_mainvariety == 144
		
		recode innovation_year . = 1988 if c2paddy_mainvariety == 21
		recode innovation_year . = 1994 if c2paddy_mainvariety == 29
		recode innovation_year . = 2008 if c2paddy_mainvariety == 47
		recode innovation_year . = 2008 if c2paddy_mainvariety == 49
		recode innovation_year . = 2020 if c2paddy_mainvariety == 96
		
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore	
	
	
		
		preserve 
		
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg
		save `paddy_cg', replace
			
		restore
		
		preserve 
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin
		save `paddy_fin', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if c2paddy_mainvariety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety c2paddy_mainvariety
	merge 1:m c2paddy_mainvariety using `paddy_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren c2paddy_mainvariety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_`i'
	save "`w_p_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety
	save `med_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_`i''"
	save `med_paddy_variety', replace
	
	}
	
	
	preserve
	
	keep if paddy_variety == 27 | paddy_variety == 28 | paddy_variety == 56 | ///
	paddy_variety == 57 | paddy_variety == 73 | paddy_variety == 87 | ///
	paddy_variety == 88 | paddy_variety == 91 | paddy_variety == 99
	
	ren paddy_variety b2paddy_variety
	
	g paddy_label = "BRRI Dhan 28 (1994)" if b2paddy_variety == 27
	replace paddy_label = "BRRI Dhan 29 (1994)" if b2paddy_variety == 28
	replace paddy_label = "BRRI Dhan 57 (2011)" if b2paddy_variety == 56
	replace paddy_label = "BRRI Dhan 58 (2012)" if b2paddy_variety == 57
	replace paddy_label = "BRRI Dhan 74 (2015)" if b2paddy_variety == 73
	replace paddy_label = "BRRI Dhan 88 (2018)" if b2paddy_variety == 87
	replace paddy_label = "BRRI Dhan 89 (2018)" if b2paddy_variety == 88
	replace paddy_label = "BRRI Dhan 92 (2019)" if b2paddy_variety == 91
	replace paddy_label = "BRRI Dhan-100 (2021)" if b2paddy_variety == 99
	
	
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
								11 "Mukta BR-11" ///
								12 "Moyna BR-12 (Boro/Aus)" ///
								13 "Gazi BR-14 (Boro/Aus)" ///
								14 "Mohini BR-15 (Boro/aus)" ///
								15 "Shahi Balam BR-16(Boro/Aus)" ///
								16 "Hasi BR-17 (Boro)" ///
								17 "Shahjalal BR-18 (Boro)" ///
								18 "Mongal BR-19 (Boro)" ///
								19 "Nizami BR-20 (Aus)"  ///
								20 "Niamat BR-21 (Aus)"  ///
								21 "Kiron BR-22"  ///
								22 "Dyshary BR-23)"  ///
								23 "Rahmat BR-24 (Aus)" ///
                          24  "Noya Pajam BR-25 (Aman)" ///
                          25  "Sraboni BR-26 (Aus)" ///
                          26  "Bri Dhan BR-27 (Aus)" ///
                          27  "Bri Dhan-28 (1994)" ///
                          28  "Bri Dhan-29 (1994)" ///
                          29  "Bri Dhan BR-30 (Aman)" ///
                          30  "Bri Dhan BR-31 (Aman)" ///
                          31  "Bri Dhan 32" ///
                          32  "Bri Dhan BR-33 (Aman)" ///
                          33  "Bri Dhan BR-34 (Aman)" ///
                          34  "Bri Dhan BR-35 (Boro)" ///
                          35  "Bri Dhan BR-36 (Boro)" ///
                          36  "Bri Dhan BR-37 (Aman)" ///
                          37  "Bri Dhan BR-38 (Aman)" ///
                          38  "Bri Dhan 39" ///
                          39  "Bri Dhan BR-40 (Aman)" ///
                          40  "Bri Dhan BR-41 (Aman)" ///
                          41  "Bri Dhan BR-42 (Aus)" ///
                          42  "Bri Dhan BR-43 (Aus)" ///
                          43  "Bri Dhan BR-44 (Aman)" ///
                          44  "Bri Dhan BR-45 (Boro)" ///
                          45  "Bri Dhan BR-46 (Aman)" ///
                          46  "Bri Dhan BR-47 (Boro)" ///
                          47  "Bri Dhan BR-48 (Aus)" ///
                          48  "Bri Dhan 49" ///
                          49  "Bri Dhan BR-50 (Banglamoti) (Boro)" ///
                          50  "Bri Dhan 51" ///
                          51  "Bri Dhan 52" ///
                          52  "Bri Dhan BR-53 (Aman)" ///
                          53  "Bri Dhan BR-54 (Aman)" ///
                          54  "Bri Dhan BR-55 (Boro/Aus)" ///
                          55  "Bri Dhan BR-56 (Aman)" ///
                          56  "Bri Dhan BR-57 (Aman)" ///
                          57  "Bri Dhan 58 (2012)" ///
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
                          73  "Bri Dhan 74 (2015)" ///
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
                         87  "Bri Dhan 88 (2018)" ///
                         88  "Bri Dhan 89 (2018)" ///
                         89  "Bri Dhan 90" ///
                         90  "Bri Dhan 91" ///
                         91  "Bri Dhan 92 (2019)" ///
                         92  "Bri Dhan 93" ///
                         93  "Bri Dhan 94" ///
                         94  "Bri Dhan 95" ///
                         95  "Bri Dhan 96" ///
                         96  "Bri Dhan 97" ///
                         97  "Bri Dhan 98" ///
                         98  "Bri Dhan 99" ///
                         99  "Bri Dhan 100 (2021)" ///
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
						193 "Others", modify
						
						la val b2paddy_variety b2paddy_variety
						

	graph hbar (asis) mean_hh, over(paddy_label,  gap(30) label(labcolor(black)labsize(vsmall))) ///
	asyvars showyvars ylabel(0(10)25, nogrid labsize(small) labcolor (black)) ///
	blabel(bar, format(%4.2f) size(vsmall)color (black) position(outside)) ///
	bar(1, bcolor("${blue3"))bar(2, bcolor("${blue3"))bar(3, bcolor("${blue3")) ///
	bar(4, bcolor("${blue3"))bar(5, bcolor("${blue3")) bar(6, bcolor("${blue3")) ///
	bar(7, bcolor("${blue3")) bar(8, bcolor("${blue3")) bar(9, bcolor("${blue3")) ///
	bar(10, bcolor("${blue3")) bar(11, bcolor("${blue1")) bar(12, bcolor("${blue3")) ///
	bar(13, bcolor("${blue1")) bar(14, bcolor("${blue3")) bar(15, bcolor("${blue1")) ///
	bar(16, bcolor("${blue3")) bar(17, bcolor("${blue1")) ///
	title("", ///
	justification(left) margin(b+1 t-1 l-1) bexpand size(small) color (black)) ///
	ytitle("", size(small)) ///
	note("",size(vsmall)) plotregion(fcolor(white)) ///
	legend(off) name(paddy2, replace)
	
	graph export "${final_figure}${slash}figure_18.png", replace as(png)
	
	
	restore 
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med
	save `paddy_cg_med', replace
	
	u `med_paddy_variety', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	local med "1 2 3 4 5 7 9 10 11 12"
	foreach i of local med {
		
		u `med_paddy_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy
	save `med_year_paddy', emptyok
	
	foreach i of local med {
		append using "`med_year`i''"
		save `med_year_paddy', replace
	}
	
	append using `paddy_cg_med'
	append using `paddy_tc_med'
	save `med_year_paddy', replace
				
		
		foreach i of local med {
			
			u `paddy_fin', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)

		
		g merge_id = 1
		
		merge 1:1 merge_id using `paddy_hh_count', nogen
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d`i'
			save "`d`i''", replace		
		}
		
		
		
		clear
		tempfile paddy_innovation_fin
		save `paddy_innovation_fin', emptyok

		
		foreach i of local med  {
				
		append using "`d`i''"
		save `paddy_innovation_fin', replace
			
		}
		
		append using `paddy_cg'
		append using `paddy_tc'
				
		save `paddy_innovation_fin', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d`i'
			save "`d`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil
		save `paddy_variety_vil', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_variety_vil', replace
			
		}
		
		append using `paddy_cg_vil'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin', nogen
		
		merge 1:1 innovation using `med_year_paddy', nogen
		
		g innovation_label = "CG Paddy varieties" if innovation == 0
		replace innovation_label = "High yield paddy" if innovation == 1
		replace innovation_label = "Insect and disease resistant paddy" if innovation == 2
		replace innovation_label = "Early paddy variety" if innovation == 3 
		replace innovation_label = "Protein enriched paddy" if innovation == 4
		replace innovation_label = "Salt tolerant paddy" if innovation == 5
		replace innovation_label = "Flood tolerant paddy" if innovation == 6
		replace innovation_label = "Lodging tolerant paddy" if innovation == 7
		replace innovation_label = "Drought tolerant paddy" if innovation == 8
		replace innovation_label = "Short duration paddy" if innovation == 9
		replace innovation_label = "Zinc enriched paddy" if innovation == 10
		replace innovation_label = "Fertilizer- and water-saving paddy" if innovation == 11
		replace innovation_label = "Amylose enriched paddy" if innovation == 12
		replace innovation_label = "CG varieties (year 2000 and onwards)" if innovation == 13
		
		tempfile paddy_lower_est
		save `paddy_lower_est', replace
		
			
		u `paddy_village', clear
			
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 97

	}
	
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}

	
	
	
		tempfile paddy_village_up
		save `paddy_village_up', replace
	
	local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
		
		foreach i of local paddy_up {
			
			u `paddy_village_up', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if c2paddy_mainvariety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_up_`i'
		save "`paddy_vil_up_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil_up
		save `paddy_cg_vil_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_vil_up_`i''"
			save `paddy_cg_vil_up', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil_up', replace
		
		u `paddy_fin', clear
		
			local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 68

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 97

	}
	
			
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 98

	}
	
	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 56

		}
	
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 88

	}
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 32

	}
	
	
		local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if c2paddy_mainvariety == 58

	}
	
		recode innovation_year . = 2019 if c2paddy_mainvariety == 94
		recode innovation_year . = 2020 if c2paddy_mainvariety == 97
	
		recode innovation_year . = 1997 if c2paddy_mainvariety == 32
		recode innovation_year . = 2013 if c2paddy_mainvariety == 58

		recode innovation_year . = 1986 if c2paddy_mainvariety == 20
		recode innovation_year . = 1994 if c2paddy_mainvariety == 26
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		
		preserve 
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg_up
		save `paddy_cg_up', replace
			
		restore
		
		preserve 
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin_up
		save `paddy_fin_up', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin_up', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if c2paddy_mainvariety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety c2paddy_mainvariety
	merge 1:m c2paddy_mainvariety using `paddy_fin_up', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren c2paddy_mainvariety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_up_`i'
	save "`w_p_up_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety_up
	save `med_paddy_variety_up', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_up_`i''"
	save `med_paddy_variety_up', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med_up
	save `paddy_cg_med_up', replace
	
	u `med_paddy_variety_up', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	local med_up "1 2 3 4 5 7 8 9 10 11 12"
	foreach i of local med_up {
		
		u `med_paddy_variety_up', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year_up_`i'
		save "`med_year_up_`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy_up
	save `med_year_paddy_up', emptyok
	
	foreach i of local med_up {
		append using "`med_year_up_`i''"
		save `med_year_paddy_up', replace
	}
	
	append using `paddy_cg_med_up'
	append using `paddy_tc_med'
	save `med_year_paddy_up', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin_up', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d_up_`i'
			save "`d_up_`i''", replace		
		}
		
		clear
		tempfile paddy_innovation_fin_up
		save `paddy_innovation_fin_up', emptyok

		

	foreach i of local med_up  {
				
		append using "`d_up_`i''"
		save `paddy_innovation_fin_up', replace
			
		}
		
		append using `paddy_cg_up'
		append using `paddy_tc'
		
		save `paddy_innovation_fin_up', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village_up', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d_up_`i'
			save "`d_up_`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil_up
		save `paddy_variety_vil_up', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_variety_vil_up', replace
			
		}
		
		append using `paddy_cg_vil_up'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin_up', nogen
		
		merge 1:1 innovation using `med_year_paddy_up', nogen
		ren (pct_vil pct_hh tot_reach median_year) (pct_vil_up pct_hh_up tot_reach_up median_year_up)
		
		merge 1:1 innovation using `paddy_lower_est', nogen 
		
		
		g total_reach = round((tot_reach/1000000), .01)
		
		g total_reach_up = round((tot_reach_up/1000000), .01)
				
		
		la var innovation_label "Name of crop innovation"
		la var pct_hh "% of HH with innovation among the crop cultivating HHs (lower bound)"
		la var pct_vil "% of villages with innovation (lower bound)"
		la var num_hh "Number of HH cultivating the crop in the past three seasons (lower bound)"
		la var total_reach "Estimated number of households (in millions) (lower bound)"
		la var median_year "Variety adoption percentage weighted release year of crop innovation (lower bound)"
		
		la var pct_hh_up "% of HH with innovation among the crop cultivating HHs (upper bound)"
		la var pct_vil_up "% of villages with innovation (upper bound)"
		la var total_reach_up "Estimated number of households (in millions) (upper bound)"
		la var median_year_up "Variety adoption percentage weighted release year of crop innovation (upper bound)"
		
		drop if innovation == 6
		
		
		drop tot_reach tot_reach_up num_hh merge_id
		
		order innovation_label pct_hh pct_vil total_reach median_year ///
		pct_hh_up pct_vil_up total_reach_up median_year_up
	
		preserve
		
		drop if innovation == 0 | innovation == 13
		
		g blank_var = ""		
		egen pct_hh_new = concat(pct_hh blank_var), p("")
		egen pct_vil_new = concat(pct_vil blank_var), p("")
		egen total_reach_new = concat(total_reach blank_var), p("")
		egen median_year_new = concat(median_year blank_var), p("")
		
		
		tempfile lower_variety
		save `lower_variety', replace
		
		restore 
		
		
		keep if innovation == 0 | innovation == 13
		
		egen pct_hh_new = concat(pct_hh pct_hh_up), p(/)
		egen pct_vil_new = concat(pct_vil pct_vil_up), p(/)
		egen total_reach_new = concat(total_reach total_reach_up), p(/)
		egen median_year_new = concat(median_year median_year_up), p(/)
		
		append using `lower_variety'
	
		drop pct_hh pct_hh_up pct_vil pct_vil_up total_reach total_reach_up ///
		median_year median_year_up blank_var
		
		la var pct_hh_new "% of HH with innovation among the crop cultivating HHs (lower/upper bound)"
		la var pct_vil_new "% of villages with innovation (lower/upper bound)"
		la var total_reach_new "Estimated number of households (in millions) (lower/upper bound)"
		la var median_year_new "Variety adoption percentage weighted release year of crop innovation (lower/upper bound)"
		
		
		//Replacing median years where they are the same for upper and lower bound
		replace median_year_new = "2004" if innovation == 0 
		
		
		sort innovation
		
		keep if inrange(innovation, 5, 7) | innovation == 10 | innovation == 0 | innovation == 13
		
		drop innovation
		
		export excel "${final_table}${slash}table_15.xlsx", firstrow(varlabels) sh("table_15") sheetmodify
		
		* Table 17. Combined DNA fingerprinting plot and self-reported other plots' reach estimates for Boro rice
		
		import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear
		
		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(1 3)
		
		drop c2paddy_mainvariety
		
		ren (c2paddy_sample c2land_select) (b2paddy_variety b1plot_num)
		
		collapse(first) b2paddy_variety b1plot_num, by(a1hhid_combined)
		
		tempfile dna_plot
		save `dna_plot', replace
		
		u "${final_data}${slash}analysis_datasets${slash}SPIA_BIHS_2024_module_b1_5_a1.dta", clear
		
		
		recode b2paddy_variety -86/-79 = 193
		
		
		keep if b2crop_season == 1
		keep if !mi(b2area) & !mi(b2paddy_variety)
		
		collapse(first) a1hhid_combined b1plot_num b2paddy_variety, by(a1hhid_plotnum)
		
		preserve
		drop b2paddy_variety

		merge 1:1 a1hhid_combined b1plot_num using `dna_plot', keep(2 3)
		
		tempfile b1dna_plot
		save `b1dna_plot', replace
		
		restore

		append using `b1dna_plot'
		
		duplicates tag a1hhid_combined b1plot_num, gen(dup)
		
		drop if dup == 1 & _merge == .
		
		drop _merge dup
		
		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24 a1village) keep(3) nogen
		
		forvalues i = 1/12 	{ 
			g innovation`i' = 0
			
		}
			
		g paddy_variety = .
		g pct_hh = 0
		g pct_vil = 0
		recode b2paddy_variety -86/-79 = 210

		levelsof b2paddy_variety, local(paddy_levels)
		
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 24
		
		}
		
		local innovalue "2 3 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 25

		}
		
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 27

		}
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 39

		}
		
		
		local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 46

		}
		
		local innovalue "6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 50

		}
		
		local innovalue "6 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 51

		}
		
		local innovalue "1 3 4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 54

		}
		
		local innovalue "4 5 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 55

		}
		
		
		
		local innovalue "1 4 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 61

		}
		
		local innovalue "1 9 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 63

		}
		
		local innovalue "1 8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 65

		}
		
		local innovalue "1 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 66

		}
		
		local innovalue "1 4 8 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 70

		}
		
		local innovalue "1 4 10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 71

		}
		
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 73

		}
		
		
		local innovalue "1 7 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 74

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 75

		}
		
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 76

		}
		
		
		local innovalue "1 5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 77

		}
		
		
		
		local innovalue "1 6 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 84

		}
		
		local innovalue "11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 86

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 99

		}
		
		local innovalue "1 4 10 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

		}
		
		local innovalue "1 2 5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 137

		}
		
		local innovalue "5 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 139

		}
		
		local innovalue "6 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 140

		}
		
		local innovalue "9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 145

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 146

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 149

		}
		
		
		local innovalue "5 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 152

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 155

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 156

		}
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 157

		}
		
		
		local innovalue "1 11"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 158

		}
		
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 160

		}
		
		local innovalue "1 4 7 11 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 161

		}
		
		local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 178

	}
	
		local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 3

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 4

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 8

	}
	
			local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 10

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 11

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 12

	}
	
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 13

	}
	
		local innovalue "2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 19

	}
	
		local innovalue "2 3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 30

	}
	
		local innovalue "3"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 48

	}
	
	
		local innovalue "1"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 69

	}
	
	
		
		local innovalue "5"
	
	foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 96

	}
	
	local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 68

	}
	
		
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 98

	}
	
	local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 56

		}
	
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 88

	}

	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 22

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 40

	}
	
	local innovalue "8"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 42

	}
	
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 43

	}
	
	local innovalue "5"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 52

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 80

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 87

	}
	
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 90

	}
	
	local innovalue "7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 91

	}
	
	
	local innovalue "10"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 101

	}
	
		tempfile paddy_village
		save `paddy_village', replace
	
		
		local paddy "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141"
		
		foreach i of local paddy {
			
			u `paddy_village', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_`i'
		save "`paddy_vil_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil
		save `paddy_cg_vil', emptyok
		
		foreach i of local paddy {
			
			append using "`paddy_vil_`i''"
			save `paddy_cg_vil', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil', replace

		
		u `paddy_village', clear
		
		preserve
		
		g num_hh = 1
		
		collapse(max) num_hh, by(a1hhid_combined)
		
		g merge_id = 1
		
		collapse(count) num_hh, by(merge_id)
		
		tempfile paddy_hh_count
		save `paddy_hh_count', replace
		
		restore 
		
		
		g innovation_year = .
		recode innovation_year . = 1992 if b2paddy_variety == 24
		recode innovation_year . = 1993 if b2paddy_variety == 25
		recode innovation_year . = 1994 if b2paddy_variety == 27
		recode innovation_year . = 2003 if b2paddy_variety == 39
		recode innovation_year . = 2007 if b2paddy_variety == 46
		recode innovation_year . = 2010 if b2paddy_variety == 50
		recode innovation_year . = 2010 if b2paddy_variety == 51
		recode innovation_year . = 2011 if b2paddy_variety == 54
		recode innovation_year . = 2011 if b2paddy_variety == 55
	
		recode innovation_year . = 2013 if b2paddy_variety == 61
		recode innovation_year . = 2014 if b2paddy_variety == 63
		recode innovation_year . = 2014 if b2paddy_variety == 65
		recode innovation_year . = 2014 if b2paddy_variety == 66
		recode innovation_year . = 2015 if b2paddy_variety == 70
		recode innovation_year . = 2015 if b2paddy_variety == 71
		recode innovation_year . = 2015 if b2paddy_variety == 73
		recode innovation_year . = 2016 if b2paddy_variety == 74
		recode innovation_year . = 2016 if b2paddy_variety == 75
		recode innovation_year . = 2016 if b2paddy_variety == 76
		recode innovation_year . = 2016 if b2paddy_variety == 77
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2017 if b2paddy_variety == 84
		recode innovation_year . = 2018 if b2paddy_variety == 86
		recode innovation_year . = 2021 if b2paddy_variety == 99
		recode innovation_year . = 2022 if b2paddy_variety == 101
		
		recode innovation_year . = 2010 if b2paddy_variety == 137
		recode innovation_year . = 2012 if b2paddy_variety == 139
		recode innovation_year . = 2013 if b2paddy_variety == 140
		recode innovation_year . = 2014 if b2paddy_variety == 145
		recode innovation_year . = 2015 if b2paddy_variety == 146
		recode innovation_year . = 2017 if b2paddy_variety == 149
		recode innovation_year . = 2020 if b2paddy_variety == 152
		
		recode innovation_year . = 2001 if b2paddy_variety == 155
		recode innovation_year . = 2008 if b2paddy_variety == 156
		recode innovation_year . = 2009 if b2paddy_variety == 157
		recode innovation_year . = 2010 if b2paddy_variety == 158
		recode innovation_year . = 2017 if b2paddy_variety == 160
		recode innovation_year . = 2020 if b2paddy_variety == 161
		
		recode innovation_year . = 2017 if b2paddy_variety == 178
		
		recode innovation_year . = 1973 if b2paddy_variety == 3
		recode innovation_year . = 1975 if b2paddy_variety == 4
		recode innovation_year . = 1978 if b2paddy_variety == 8
		recode innovation_year . = 1980 if b2paddy_variety == 10
		recode innovation_year . = 1980 if b2paddy_variety == 11
		recode innovation_year . = 1983 if b2paddy_variety == 12
		recode innovation_year . = 1983 if b2paddy_variety == 13
		recode innovation_year . = 1986 if b2paddy_variety == 19
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 1994 if b2paddy_variety == 30
		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 48
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2015 if b2paddy_variety == 69
	
		recode innovation_year . = 2020 if b2paddy_variety == 98
		recode innovation_year . = 2018 if b2paddy_variety == 88
		
		recode innovation_year . = 2020 if b2paddy_variety == 96
		recode innovation_year . = 1970 if b2paddy_variety == 1
		recode innovation_year . = 1971 if b2paddy_variety == 2
		recode innovation_year . = 1977 if b2paddy_variety == 6
		recode innovation_year . = 1983 if b2paddy_variety == 15
		
		recode innovation_year . = 1994 if b2paddy_variety == 28
		recode innovation_year . = 2014 if b2paddy_variety == 68
		recode innovation_year . = 2020 if b2paddy_variety == 98
		recode innovation_year . = 2018 if b2paddy_variety == 88
		recode innovation_year . = 2011 if b2paddy_variety == 56
		recode innovation_year . = 2017 if b2paddy_variety == 78
		recode innovation_year . = 2007 if b2paddy_variety == 45
		recode innovation_year . = 2014 if b2paddy_variety == 67
		recode innovation_year . = 2020 if b2paddy_variety == 95
		
		recode innovation_year . = 1983 if b2paddy_variety == 14
		recode innovation_year . = 1985 if b2paddy_variety == 16
		recode innovation_year . = 1985 if b2paddy_variety == 17
		recode innovation_year . = 1985 if b2paddy_variety == 18
		recode innovation_year . = 1988 if b2paddy_variety == 22
		recode innovation_year . = 1994 if b2paddy_variety == 31
		recode innovation_year . = 2003 if b2paddy_variety == 40
		recode innovation_year . = 2004 if b2paddy_variety == 42
		recode innovation_year . = 2005 if b2paddy_variety == 43
		recode innovation_year . = 2010 if b2paddy_variety == 52
		recode innovation_year . = 2012 if b2paddy_variety == 57
		recode innovation_year . = 2014 if b2paddy_variety == 62
		recode innovation_year . = 2017 if b2paddy_variety == 80
		recode innovation_year . = 2018 if b2paddy_variety == 87
		recode innovation_year . = 2019 if b2paddy_variety == 90
		recode innovation_year . = 2019 if b2paddy_variety == 91
		recode innovation_year . = 2022 if b2paddy_variety == 100
		recode innovation_year . = 2022 if b2paddy_variety == 101
		recode innovation_year . = 1998 if b2paddy_variety == 133
		recode innovation_year . = 1998 if b2paddy_variety == 134
		recode innovation_year . = 1998 if b2paddy_variety == 135
		recode innovation_year . = 2014 if b2paddy_variety == 144
	
		recode innovation_year . = 1988 if b2paddy_variety == 21
		recode innovation_year . = 1994 if b2paddy_variety == 29
		recode innovation_year . = 2008 if b2paddy_variety == 47
		recode innovation_year . = 2008 if b2paddy_variety == 49
		recode innovation_year . = 2020 if b2paddy_variety == 96
		
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		
		preserve 
		
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg
		save `paddy_cg', replace
			
		restore
		
		
		preserve 
		
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin
		save `paddy_fin', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_`i'
	save "`w_p_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety
	save `med_paddy_variety', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_`i''"
	save `med_paddy_variety', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med
	save `paddy_cg_med', replace
	
	u `med_paddy_variety', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	
	forvalues i = 1/12 {
		
		u `med_paddy_variety', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year`i'
		save "`med_year`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy
	save `med_year_paddy', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year`i''"
		save `med_year_paddy', replace
	}
	
	append using `paddy_cg_med'
	append using `paddy_tc_med'
	save `med_year_paddy', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)

		
		g merge_id = 1
		
		merge 1:1 merge_id using `paddy_hh_count', nogen
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d`i'
			save "`d`i''", replace		
		}
		
		
		
		clear
		tempfile paddy_innovation_fin
		save `paddy_innovation_fin', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_innovation_fin', replace
			
		}
		
		append using `paddy_cg'
		append using `paddy_tc'
		
		save `paddy_innovation_fin', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d`i'
			save "`d`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil
		save `paddy_variety_vil', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d`i''"
		save `paddy_variety_vil', replace
			
		}
		
		append using `paddy_cg_vil'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin', nogen
		
		merge 1:1 innovation using `med_year_paddy', nogen
		
		g innovation_label = "CG Paddy varieties" if innovation == 0
		replace innovation_label = "High yield paddy" if innovation == 1
		replace innovation_label = "Insect and disease resistant paddy" if innovation == 2
		replace innovation_label = "Early paddy variety" if innovation == 3 
		replace innovation_label = "Protein enriched paddy" if innovation == 4
		replace innovation_label = "Salt tolerant paddy" if innovation == 5
		replace innovation_label = "Flood tolerant paddy" if innovation == 6
		replace innovation_label = "Lodging tolerant paddy" if innovation == 7
		replace innovation_label = "Drought tolerant paddy" if innovation == 8
		replace innovation_label = "Short duration paddy" if innovation == 9
		replace innovation_label = "Zinc enriched paddy" if innovation == 10
		replace innovation_label = "Fertilizer- and water-saving paddy" if innovation == 11
		replace innovation_label = "Amylose enriched paddy" if innovation == 12
		replace innovation_label = "CG varieties (year 2000 and onwards)" if innovation == 13
		
		tempfile paddy_lower_est
		save `paddy_lower_est', replace
		
		
			u `paddy_village', clear
				
		local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 97

	}
		
		local innovalue "1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
		tempfile paddy_village_up
		save `paddy_village_up', replace
	
	local paddy_up "24 25 27 39 46 50 51 54 55 56 61 63 65 66 70 71 73 74 75 76 77 78 84 86 99 101 137 139 140 145 146 149 152 155 156 157 158 160 161 178 3 4 8 10 11 12 13 19 30 48 69 1 2 6 15 98 88 28 68 45 67 95 14 16 17 18 22 31 40 42 43 52 57 62 80 87 90 91 100 101 133 134 135 144 21 23 29 34 35 47 49 96 141 20 26 32 58 94 97"
	
	
		foreach i of local paddy_up {
			
			u `paddy_village_up', clear
			
		recode paddy_variety . = `i'
		
		recode pct_vil 0 = 1 if b2paddy_variety == `i'
		
		collapse(max) pct_vil (first) paddy_variety a1village, by(a1hhid_combined)
		
		collapse(max) pct_vil (first) paddy_variety, by(a1village)
			
		tempfile paddy_vil_up_`i'
		save "`paddy_vil_up_`i''"
		
		}
		
		clear
		tempfile paddy_cg_vil_up
		save `paddy_cg_vil_up', emptyok
		
		foreach i of local paddy_up {
			
			append using "`paddy_vil_up_`i''"
			save `paddy_cg_vil_up', replace
			
		}
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 0
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		
		save `paddy_cg_vil_up', replace
	
		u `paddy_fin', clear
		
			local innovalue "1 2"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 28

	}
	
		local innovalue "1 4"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 68

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 94

	}
	
	local innovalue "1 4 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 97

	}
	
		local innovalue " 1 2 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 32

	}
	
		local innovalue "1 4 7 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 58

	}
	
	local innovalue "5 7"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 98

	}

		local innovalue "1 6"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 78

		}
		
		local innovalue "8 9"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 56

		}
	
	
	local innovalue "1 9 12"
		
		foreach i of local innovalue {
		
		recode innovation`i' 0 = 1 if b2paddy_variety == 88

	}
		recode innovation_year . = 2019 if b2paddy_variety == 94
		recode innovation_year . = 2020 if b2paddy_variety == 97
		
		recode innovation_year . = 1997 if b2paddy_variety == 32
		recode innovation_year . = 2013 if b2paddy_variety == 58

		recode innovation_year . = 1986 if b2paddy_variety == 20
		recode innovation_year . = 1994 if b2paddy_variety == 26
		
		preserve
		 
		recode pct_vil 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_vil, by(a1village)
		
		g innovation = 13
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)	
		
		tempfile paddy_tc_vil
		save `paddy_tc_vil', replace
		
		restore
		
		preserve 
		
		recode pct_hh 0 = 1 if innovation_year !=.
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  0
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_cg_up
		save `paddy_cg_up', replace
			
		restore
		
		preserve 
		recode pct_hh 0 = 1 if innovation_year >= 2000 & !mi(innovation_year)
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		g innovation =  13
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
		
		replace pct_hh = round(pct_hh*100, 0.01)
		
		tempfile paddy_tc
		save `paddy_tc', replace
			
		restore
		
		tempfile paddy_fin_up
		save `paddy_fin_up', replace
		
	 
		foreach i of local paddy_levels {		
	u `paddy_fin_up', clear
	recode paddy_variety . = `i'
	
	recode pct_hh 0 = 1 if b2paddy_variety== `i'
	
	collapse(max) pct_hh paddy_variety (first) hhweight_24, by(a1hhid_combined)
	
	collapse(mean) mean_hh = pct_hh [pweight=hhweight_24], by(paddy_variety)
	
	ren paddy_variety b2paddy_variety
	merge 1:m b2paddy_variety using `paddy_fin_up', nogen keep(3) keepusing(innovation_year innovation*)
	
	ren innovation_year year
	ren b2paddy_variety paddy_variety
	
	collapse(first) mean_hh year innovation*, by(paddy_variety)
	replace mean_hh = round(mean_hh*100, .01)
	tempfile w_p_up_`i'
	save "`w_p_up_`i''", replace
	
	}
	
	clear
	tempfile med_paddy_variety_up
	save `med_paddy_variety_up', emptyok
	
	foreach i of local paddy_levels {		
	append using "`w_p_up_`i''"
	save `med_paddy_variety_up', replace
	
	}
	
		
	keep if !mi(year)
	g innovation = 0
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_cg_med_up
	save `paddy_cg_med_up', replace
	
	u `med_paddy_variety_up', clear
	keep if !mi(year)
	keep if year >= 2000
	
	g innovation = 13
	collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
	replace median_year = round(median_year)
	
	tempfile paddy_tc_med
	save `paddy_tc_med', replace

	forvalues i = 1/12 {
		
		u `med_paddy_variety_up', clear
		keep if innovation`i' == 1	
		g innovation = `i'
		collapse(mean) median_year = year [pweight=mean_hh], by(innovation)
	
		replace median_year = round(median_year)
		
		tempfile med_year_up_`i'
		save "`med_year_up_`i''", replace
		
	}
	
	clear
	tempfile med_year_paddy_up
	save `med_year_paddy_up', emptyok
	
	forvalues i = 1/12 {
		append using "`med_year_up_`i''"
		save `med_year_paddy_up', replace
	}
	
	append using `paddy_cg_med_up'
	append using `paddy_tc_med'
	save `med_year_paddy_up', replace
				
		
		forvalues i = 1/12 {
			
			u `paddy_fin_up', clear
			
			
		recode pct_hh 0 = 1 if innovation`i'== 1
			
		
		collapse(max) pct_hh (first) hhweight_24, by(a1hhid_combined)
		
		g innovation = `i'
		
		collapse(mean) pct_hh (sum) tot_reach = pct_hh [pweight=hhweight_24], by(innovation)
			
		replace pct_hh = round(pct_hh*100, 0.01)
		
			tempfile d_up_`i'
			save "`d_up_`i''", replace		
		}
		
		clear
		tempfile paddy_innovation_fin_up
		save `paddy_innovation_fin_up', emptyok

		
		forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_innovation_fin_up', replace
			
		}
		
		append using `paddy_cg_up'
		append using `paddy_tc'
		
		save `paddy_innovation_fin_up', replace
		
		
		forvalues i = 1/12 {
			
			u `paddy_village_up', clear
			
		
		recode pct_vil 0 = 1 if innovation`i'== 1
		
		collapse(max) pct_vil (first) a1village, by(a1hhid_combined)
			
		collapse(max) pct_vil, by(a1village)
		
		g innovation = `i'
		
		collapse(mean) pct_vil, by(innovation)
		
		replace pct_vil = round(pct_vil*100, 0.01)
				
			tempfile d_up_`i'
			save "`d_up_`i''", replace	
		}
		
		
		
		clear
		tempfile paddy_variety_vil_up
		save `paddy_variety_vil_up', emptyok
		
		
		 forvalues i = 1/12  {
				
		append using "`d_up_`i''"
		save `paddy_variety_vil_up', replace
			
		}
		
		append using `paddy_cg_vil_up'
		append using `paddy_tc_vil'
		
		merge 1:1 innovation using `paddy_innovation_fin_up', nogen
		
		merge 1:1 innovation using `med_year_paddy_up', nogen
		ren (pct_vil pct_hh tot_reach median_year) (pct_vil_up pct_hh_up tot_reach_up median_year_up)
		
		merge 1:1 innovation using `paddy_lower_est', nogen
		
		g total_reach = round((tot_reach/1000000), .01)
		
		g total_reach_up = round((tot_reach_up/1000000), .01)	
		
		la var innovation_label "Name of crop innovation"
		la var pct_hh "% of HH with innovation among the crop cultivating HHs (lower bound)"
		la var pct_vil "% of villages with innovation (lower bound)"
		la var num_hh "Number of HH cultivating the crop in the past three seasons (lower bound)"
		la var total_reach "Estimated number of households (in millions) (lower bound)"
		la var median_year "Variety adoption percentage weighted release year of crop innovation (lower bound)"
		
		la var pct_hh_up "% of HH with innovation among the crop cultivating HHs (upper bound)"
		la var pct_vil_up "% of villages with innovation (upper bound)"
		la var total_reach_up "Estimated number of households (in millions) (upper bound)"
		la var median_year_up "Variety adoption percentage weighted release year of crop innovation (upper bound)"
		
		drop tot_reach tot_reach_up num_hh merge_id
		
		order innovation_label pct_hh pct_vil total_reach median_year ///
		pct_hh_up pct_vil_up total_reach_up median_year_up
		
		preserve
		
		keep if innovation == 3 | innovation == 6 | innovation ==  10 | innovation == 11 | ///
		innovation == 5 | innovation == 7
		
		g blank_var = ""		
		egen pct_hh_new = concat(pct_hh blank_var), p("")
		egen pct_vil_new = concat(pct_vil blank_var), p("")
		egen total_reach_new = concat(total_reach blank_var), p("")
		egen median_year_new = concat(median_year blank_var), p("")
		
		
		tempfile lower_variety
		save `lower_variety', replace
		
		restore 
				
		drop if innovation == 3 | innovation == 6 | innovation ==  10 | innovation == 11 | innovation == 5 | innovation == 7
		
		egen pct_hh_new = concat(pct_hh pct_hh_up), p(/)
		egen pct_vil_new = concat(pct_vil pct_vil_up), p(/)
		egen total_reach_new = concat(total_reach total_reach_up), p(/)
		egen median_year_new = concat(median_year median_year_up), p(/)
		
		append using `lower_variety'
				
		drop pct_hh pct_hh_up pct_vil pct_vil_up total_reach total_reach_up ///
		median_year median_year_up blank_var
		
		la var pct_hh_new "% of HH with innovation among the crop cultivating HHs (lower/upper bound)"
		la var pct_vil_new "% of villages with innovation (lower/upper bound)"
		la var total_reach_new "Estimated number of households (in millions) (lower/upper bound)"
		la var median_year_new "Variety adoption percentage weighted release year of crop innovation (lower/upper bound)"
		
		replace median_year_new = "2003" if innovation == 0
	
		sort innovation
		keep if inrange(innovation, 5, 7) | innovation == 10 | innovation == 0 | innovation == 13
		
		drop innovation
		
		export excel "${final_table}${slash}table_17.xlsx", firstrow(varlabels) sh("table_17") sheetmodify	
		

	
 
		
		* Figure 20 unpacking miniket sample DNA fingerprinting analysis
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear
		
		merge m:1 a1hhid_combined using  "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", nogen
		
		ren c2scan_barcode barcodeid
		
		tempfile miniket
		save `miniket', replace
		
		import delimited "${dna_data}${slash}ref_clusters_no_hybrids_with_HH_Ids", clear
		
		merge 1:m barcodeid using `miniket', nogen keep(3)
		
		* Figure 19. Mixing of Varieties on DNA Fingerprinting Plot
		* Figure 20. Variety-wise division of `local' and `improved' self-reports with corresponding self-reported variety names
		* Figure 49. Self-reports for 'Not-Assigned' samples (in reference list )
		* Figure 50. Self-Reports for `not assigned' samples (not in reference list) (%)
	
		import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", firstrow clear 

	gen variety_name_reference = subinstr(variety_name, "BD-", " BRRI Dhan-", .)
	drop comment scan_barcode variety_name
	rename c2paddy_sample c2paddy_mainvariety
	tempfile reference 
	save "`reference'" , replace

	use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear
	duplicates tag a1hhid_combined , gen(dup)
	duplicates drop a1hhid_combined c2paddy_mainvariety c2variety_clean c2variety_num , force 
	merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3) nogenerate 

	keep if c2variety_num == 27 
	keep a1hhid_combined c2paddy_mainvariety c2variety_clean c2variety_num hhweight_24 ///
	c2paddy_mainvariety c2paddy_mainvarietytype c2primary_main_trait c2primary_main_trait_oth
	merge m:1 c2paddy_mainvariety using "`reference'" , keep(1 3)
	
	preserve 
	keep if _merge == 3 
	gen hh = 1 
	collapse (sum) hh , by(variety_name_reference) 
	replace hh = 100*(hh/154) 
	replace variety_name_reference = "Other References" if hh < 1 
	collapse (sum) hh ,by(variety_name_reference)
	
	 graph hbar (asis) hh, over(variety_name_reference, sort(hh) descending gap(30) label(labcolor(black)labsize(vsmall))) ///
	asyvars showyvars ylabel(0(10)30, noticks nogrid angle(0) labsize(small) labcolor (black)) ///
	blabel(bar, format(%4.2f) size(vsmall)color (black) position(outside)) ///
	bar(1, bcolor("dknavy"))bar(2, bcolor("dknavy"))bar(3, bcolor("dknavy")) ///
	bar(4, bcolor("dknavy"))bar(5, bcolor("dknavy")) ///
	bar(6, bcolor("dknavy")) bar(7, bcolor("dknavy")) ///
	bar(8, bcolor("dknavy")) bar(9, bcolor("dknavy")) bar(10, bcolor("dknavy")) ///
	bar(11, bcolor("dknavy")) bar(12, bcolor("dknavy"))  bar(13, bcolor("dknavy")) /// 
	bar(14, bcolor("dknavy")) bar(15, bcolor("dknavy"))  bar(16, bcolor("ltblue")) /// 
	title("", ///
	size(small) color (black)) ///
	ytitle("", size(small)) ///
	legend(off) name(paddy2, replace) ///
	graphregion(color(white)) ///
     plotregion(color(white)) 
	 
	graph export "${final_figure}${slash}figure_49.png", replace as(png)


 restore 



keep if _merge == 1
gen hh = 1 

 recode c2paddy_mainvariety 95/193 = 215 if c2paddy_mainvariety == 95 | inrange(c2paddy_mainvariety, 135, 154) | c2paddy_mainvariety == 193 //bri/bina improved varieties
 
 recode c2paddy_mainvariety 155/161 = 216 if inrange(c2paddy_mainvariety, 155, 161) //bri hybrid
 
 recode c2paddy_mainvariety 109 = -86 // Kajallata
 recode c2paddy_mainvariety 112/115 = -86 // Paijam bashmati jamaibabu
 recode c2paddy_mainvariety 118 = -86 // Binni dhan
 recode c2paddy_mainvariety 121/122 = 212 //  Sonar bangla, jagoron
 recode c2paddy_mainvariety 124 = 123 // Shakti2 -> Shakti 1
 recode c2paddy_mainvariety 125 = -86 // Aloron 1
 recode c2paddy_mainvariety 128/176 = 212
 recode c2paddy_mainvariety 183 = -86 // Mamun
 recode c2paddy_mainvariety 187/189 = 212
 recode c2paddy_mainvariety 195 = 212
 recode c2paddy_mainvariety 203 = 212
 recode c2paddy_mainvariety 208 = 212
 recode c2paddy_mainvariety 211 = -86 // Sathi
 recode c2paddy_mainvariety 199 = -86 // AZ
 recode c2paddy_mainvariety 206 = -86 // Kathali
 recode c2paddy_mainvariety 202 = -86 // Babylon
 
 recode c2paddy_mainvariety 192 = -86 // Mota(round, bold seed)
 
 label define c2paddy_mainvariety 123 "Shakti 1/2" 215 "BRRI/BINA improved varieties" ///
 216 "BRRI hybrids", modify
 
 la val c2paddy_mainvariety c2paddy_mainvariety
 
 preserve  



collapse (sum) hh , by(c2paddy_mainvariety) 

replace hh = 100*(hh/612)

graph hbar hh, over(c2paddy_mainvariety, sort(hh) gap(20) descending label(labcolor(black) labsize(vsmall))) ///
asyvars showyvars ylabel(0(10)20, labsize(small) labcolor (black)) ///
	blabel(bar, format(%4.2f) size(vsmall)color (black) position(outside)) ///
title("" , size(small)) ///
 ytitle("", size(vsmall)) ///
ylabel(, noticks nogrid angle(0) labsize(vsmall)) ///
bar(1, color("ltblue")) bar(2, color("ltblue")) bar(3, color("ltblue")) ///
bar(4, color("ltblue")) bar(5, color("ltblue")) bar(6, color("ebblue")) ///
bar(7, color("ltblue")) bar(8, color("ebblue")) bar(9, color("ltblue")) ///
bar(10, color("ebblue")) bar(11, color("ebblue")) bar(12, color("ltblue")) ///
bar(13, color("ebblue")) bar(14, color("ebblue")) bar(15, color("ltblue")) ///
bar(16, color("ltblue")) bar(17, color("ebblue")) bar(18, color("ltblue")) ///
bar(19, color("ebblue")) bar(20, color("ebblue")) bar(21, color("ltblue")) ///
bar(22, color("ltblue")) bar(23, color("dknavy")) bar(24, color("dknavy")) ///
legend(off) graphregion(color(white)) ///
plotregion(color(white)) 

graph export "${final_figure}${slash}figure_50.png", replace as(png)

restore



drop if c2paddy_mainvariety == 212 | inrange(c2paddy_mainvariety, 215, 216) | ///
		c2paddy_mainvariety == 127 | c2paddy_mainvariety == 182 ///
		| c2paddy_mainvariety == 186 | c2paddy_mainvariety == 190 ///
		| inrange(c2paddy_mainvariety, 197, 198) | c2paddy_mainvariety == 205 ///
		| c2paddy_mainvariety == 209


drop if c2paddy_mainvarietytype == 4
drop if c2paddy_mainvariety == 204

gen local1 = 0 
replace local1 = 1 if inlist(c2paddy_mainvarietytype,3)


catplot , over(local1) over(c2paddy_mainvariety) ///
    stack asyvars percent ///
    bar(1, bcolor(ltblue)) ///
    bar(2, bcolor(dknavy)) ///
    legend(order(1 "Local" 2 "Improved") position(6) col(2) size(small)) ///
    title("", size(medium)) ///
	ytitle("Percentage of non-hybrid unassigned samples (N = 252)") ///
    ylabel(, nogrid angle(0)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "${final_figure}${slash}figure_20.png", replace as(png)


import excel "${dna_data}${slash}bangladesh_rice_assignment_results.xlsx" , firstrow clear
drop M

 
duplicates drop SPIA_sample_ID Reference_name SPIA_ref_ID Variety , force
duplicates tag SPIA_sample_ID , gen(dup)
rename SPIA_sample_ID c2scan_barcode_1 
drop if Sample_name == "SPIA_BIHS_2072" & Reference_name == "NA"

tempfile DNA
save "`DNA'"

use "${temp_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear 
keep if c2scan_barcode_2 != "" 
drop c2scan_barcode_1
rename c2scan_barcode_2 c2scan_barcode_1
gen barcode_2 = 1 
tempfile duplicate
save "`duplicate'"

use "${temp_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear 
drop c2scan_barcode_2
append using "`duplicate'"
sort a1hhid_combined c2scan_barcode_1 
drop if c2scan_barcode_1 == ""

merge 1:m c2scan_barcode_1 using "`DNA'" , keep(3) nogenerate 
drop dup

rename c2scan_barcode_1 c2scan_barcode

duplicates tag a1hhid_combined , gen(dup)

keep if dup > 0 
gen Variety_clean = subinstr(Variety, "BD-", " Bri Dhan BR-", .)
ren Variety_clean c2variety_clean
encode c2variety_clean, gen(c2variety_num) label(c2variety_clean)

egen tag = tag(c2variety_num a1hhid_combined)
egen ndistinct = total(tag), by(a1hhid_combined) 

keep a1hhid_combined c2variety_clean c2variety_num ndistinct
gen has_na = (c2variety_clean == "Not assigned")
egen sum_na = total(has_na), by(a1hhid_combined)
gen NA = (ndistinct > 1 & sum_na > 0)
bysort a1hhid_combined (NA): replace NA = NA[_n-1] if missing(NA)

gen Var_2 = 1 if ndistinct == 2 & NA != 1 
keep a1hhid_combined ndistinct NA Var_2
duplicates drop 

gen Var_1 = 1 if ndistinct == 1 
replace Var_1 = 0 if Var_1 == . 
replace Var_2 = 0 if Var_2 == . 

collapse (mean) Var_1 Var_2 NA
foreach x in Var_1 Var_2 NA { 
replace `x' = 100*(`x')
}
gen pct = 1 
rename NA Var_0

reshape long Var_, i(pct) j(type)

graph hbar Var_ , over(type, sort(Var_) desc relabel( 1 "One is not assigned" 2 "Both are Same" 3 "Both are different")) ///
ytitle("Percent of DNA Fingerprinting HHs with 2 Samples(Total:342)", size(vsmall)) /// 
title("" , size(small)) ///
ylabel(, noticks nogrid angle(0) labsize(vsmall))  ///
bar(1, color(dknavy)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
blabel(bar, position(center) color(white) format(%4.1f) size(vsmall)) 

graph export "${final_figure}${slash}figure_19.png", replace as(png)

 * Figure 22. Misclassification of DNA fingerprinting samples

use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear 
duplicates drop a1hhid_combined c2paddy_mainvariety c2variety_clean c2variety_num , force 
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3) nogenerate 
keep a1hhid_combined c2paddy_mainvariety c2variety_clean c2variety_num hhweight_24 
drop if c2variety_num == 27 

keep if inlist(c2variety_num,1,4,5,10,11,14,17,18,20)

gen incorrect_classify = 0 
replace incorrect_classify = 1 if c2paddy_mainvariety != 99 & c2variety_num == 1
replace incorrect_classify = 1 if c2paddy_mainvariety != 27 & c2variety_num == 4
replace incorrect_classify = 1 if c2paddy_mainvariety != 28 & c2variety_num == 5
replace incorrect_classify = 1 if c2paddy_mainvariety != 56 & c2variety_num == 10
replace incorrect_classify = 1 if c2paddy_mainvariety != 57 & c2variety_num == 11
replace incorrect_classify = 1 if c2paddy_mainvariety != 73 & c2variety_num == 14
replace incorrect_classify = 1 if c2paddy_mainvariety != 87 & c2variety_num == 17
replace incorrect_classify = 1 if c2paddy_mainvariety != 88 & c2variety_num == 18
replace incorrect_classify = 1 if c2paddy_mainvariety != 91 & c2variety_num == 20 

collapse (mean) incorrect_classify_over=incorrect_classify 
gen c2variety_clean = "Overall Rate"
replace incorrect_classify_over = round(100*(incorrect_classify),0.1)

tempfile misclass
save "`misclass'"

use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear 
duplicates drop a1hhid_combined c2paddy_mainvariety c2variety_clean c2variety_num , force 
merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24) keep(3) nogenerate 
keep a1hhid_combined c2paddy_mainvariety c2variety_clean c2variety_num hhweight_24 
drop if c2variety_num == 27 

keep if inlist(c2variety_num,1,4,5,10,11,14,17,18,20)

gen incorrect_classify = 0 
replace incorrect_classify = 1 if c2paddy_mainvariety != 99 & c2variety_num == 1
replace incorrect_classify = 1 if c2paddy_mainvariety != 27 & c2variety_num == 4
replace incorrect_classify = 1 if c2paddy_mainvariety != 28 & c2variety_num == 5
replace incorrect_classify = 1 if c2paddy_mainvariety != 56 & c2variety_num == 10
replace incorrect_classify = 1 if c2paddy_mainvariety != 57 & c2variety_num == 11
replace incorrect_classify = 1 if c2paddy_mainvariety != 73 & c2variety_num == 14
replace incorrect_classify = 1 if c2paddy_mainvariety != 87 & c2variety_num == 17
replace incorrect_classify = 1 if c2paddy_mainvariety != 88 & c2variety_num == 18
replace incorrect_classify = 1 if c2paddy_mainvariety != 91 & c2variety_num == 20 

gen c2variety_clean_new = subinstr(c2variety_clean, " Bri Dhan BR-", "BRRI Dhan-", .)

drop c2variety_clean

ren c2variety_clean_new c2variety_clean

collapse (mean) incorrect_classify (count) number=incorrect_classify, by(c2variety_clean)
replace incorrect_classify = round(100*(incorrect_classify),0.1)

gen c2variety_clean_short = substr(c2variety_clean, 11,.)

gen release_year = . 
replace release_year = 2020 if c2variety_clean == "BRRI Dhan-100"
replace release_year = 1994 if c2variety_clean == "BRRI Dhan-28"
replace release_year = 1994 if c2variety_clean == "BRRI Dhan-29"
replace release_year = 2011 if c2variety_clean == "BRRI Dhan-57"
replace release_year = 2012 if c2variety_clean == "BRRI Dhan-58"
replace release_year = 2015 if c2variety_clean == "BRRI Dhan-74"
replace release_year = 2018 if c2variety_clean == "BRRI Dhan-88"
replace release_year = 2018 if c2variety_clean == "BRRI Dhan-89"
replace release_year = 2019 if c2variety_clean == "BRRI Dhan-92"

gen marker_size = incorrect_classify/100 

scatter incorrect_classify release_year [w=number], ///
   xlabel(1992(5)2024, labsize(medium) labcolor (black) nogrid) ///
   ylabel(0(20)110, labsize(medium) labcolor (black) nogrid) ///
    mcolor(ebblue) /// 
    mlab(c2variety_clean_short) ///
	mlabsize(vsmall) /// 
    mlabposition(12) /// 
    title("Misclassification vs. Release Year Scatterplot", size(medium) color(black)) ///
    xtitle("Release Year", size(medium) color(black)) ///
    ytitle("False Negatives", size(medium)) ///
    graphregion(color(white)) ///
    legend(off) ///
    xsize(6) ///
    ysize(4) name(mis1, replace)


append using "`misclass'" 

graph hbar incorrect_classify incorrect_classify_over , ///
over(c2variety_clean, sort(incorrect_classify) descending label(labcolor(black) labsize(medium))) ///
ytitle("", size(small)) legend(off) ///
title("Mis-classification of DNA Fingerprinting (%) (False Neg)", size(medium) color(black)) ///
ylabel(0(10)100, labsize(medium) labcolor(black) nogrid) ///
bar(1, color(dknavy)) ///
bar(2, color(ebblue)) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
blabel(bar, position(top) color(black) format(%4.1f) size(medium)) ///
note("Samples = 869 (Only retained those with over 5% adoption)", size(small)) name(mis2, replace)

gr combine mis1 mis2, altshrink
graph export "${final_figure}${slash}figure_22.png", replace as(png)





	* Figure 21. DNA vs. self-report comparison for major Boro varieties
	import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4.dta" , clear
		
		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24 a1village) keep(3) nogen

		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(3)
		
		ren c2paddy_sample c2paddy_dna
		
		order c2paddy_dna c2paddy_mainvariety
		
		keep if inlist(c2paddy_dna, 27, 28, 56, 57, 73, 87, 88, 91, 99) 
		
		keep a1hhid_combined c2paddy_mainvariety c2paddy_dna variety_name
		
		
		ren variety_name dna_name
		
		recode c2paddy_mainvariety -86 = 220
		
		recode c2paddy_mainvariety 8/25 = 220
		recode c2paddy_mainvariety 100/215 = 220
		recode c2paddy_mainvariety 48/55 = 220
		recode c2paddy_mainvariety 58/72 = 220
		recode c2paddy_mainvariety 74/86 = 220
		recode c2paddy_mainvariety 89/90 = 220
		recode c2paddy_mainvariety 92/98 = 220
		
		levelsof c2paddy_dna, local(paddy_dna)
		levelsof c2paddy_mainvariety, local(paddy_self)
		
		tempfile main_dna
		save `main_dna', replace
		
		foreach i of local paddy_dna		{
			u `main_dna', replace
			
			keep if c2paddy_dna == `i'
		
		g num = 1
		
		
		collapse(sum) num (first) dna_name, by(c2paddy_mainvariety)
		
		tempfile dna`i'
		save "`dna`i''", replace
		}

		
		clear
		tempfile dna_var
		save `dna_var', emptyok
	
		
	foreach i of local paddy_dna  {
		
	append using "`dna`i''"
	
	save `dna_var', replace
		
	}
	
						decode c2paddy_mainvariety, gen(self_name)
						
						
					set scheme white_tableau  
					graph set window fontface "Arial Narrow"
					
					g dna_name_new = subinstr(dna_name, " Bri Dhan BR-", "BR ", .)
					
					replace dna_name_new = "BR-100" if dna_name_new == "BR 100"
					
					replace self_name = "BR 28" if self_name == "Bri Dhan BR-28 (Boro)"
					replace self_name = "BR 29" if self_name == "Bri Dhan BR-29 (Boro)"
					replace self_name = "BR 58" if self_name == "Bri Dhan BR-58 (Boro)"
					
					g self_name_new = subinstr(self_name, "Bri Dhan", "BR", .)
					
					replace self_name_new = "BR-100" if self_name_new == "BR 100"
					replace self_name_new = "Other varieties" if self_name == ""


				sankey num, from(dna_name_new) to(self_name_new) gap(0) smooth(8) ///
				sort1(name) novalue palette(CET C7) ctitles("DNA" "Self-Reports") ///
				ctsize(2) ctpos(top) ctg(20) recenter(top) laba(0) labs(1.5)  xsize(1) ysize(1) ///
				title("", size(3))
				
				graph export "${final_figure}${slash}figure_21.png", replace as(png)
						
			
		* Figure 23. Correlates of misclassification of DNA fingerprinted rice 
		import excel using "${dna_data}${slash}Barcode_reference_2024.xlsx", sheet("data") firstrow clear
		gen variety_name_new = subinstr(variety_name, "BD-", " Bri Dhan BR-", .)
		
		drop variety_name 
		ren variety_name_new variety_name
		
		tempfile barcode_var
		save `barcode_var', replace
		
		use "${final_data}${slash}SPIA_BIHS_2024_module_c2_4" , clear
		
		merge m:1 a1hhid_combined using "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", keepusing(hhweight_24 a1village) keep(3) nogen

		egen tag = tag(c2variety_num a1hhid_combined)
		egen ndistinct = total(tag), by(a1hhid_combined) 
		drop if ndistinct == 2 & c2variety_num == 27
		
		ren c2variety_clean variety_name
		
		merge m:1 variety_name using `barcode_var', nogen keep(3)
		
		ren c2paddy_sample c2paddy_dna
		
		order c2paddy_dna c2paddy_mainvariety
		
		ren variety_name dna_name
		
		recode c2paddy_mainvariety -86 = 220
		
		g mis_rep = (c2paddy_dna != c2paddy_mainvariety)
		
		label var mis_rep "Misclassified self-reported variety"
		
		g innovation_year = .
		recode innovation_year . = 2014 if c2paddy_dna == 66
		recode innovation_year . = 2015 if c2paddy_dna == 73
		recode innovation_year . = 2016 if c2paddy_dna == 74
		recode innovation_year . = 2021 if c2paddy_dna == 99
		recode innovation_year . = 2012 if c2paddy_dna == 139
		recode innovation_year . = 2015 if c2paddy_dna == 146

		
		recode innovation_year . = 2008 if c2paddy_dna == 47
		recode innovation_year . = 2008 if c2paddy_dna == 48
		recode innovation_year . = 2008 if c2paddy_dna == 49
		
		recode innovation_year . = 2020 if c2paddy_dna == 96
		recode innovation_year . = 1983 if c2paddy_dna == 15
		
		
		recode innovation_year . = 1994 if c2paddy_dna == 28
		recode innovation_year . = 2020 if c2paddy_dna == 98
		recode innovation_year . = 2018 if c2paddy_dna == 88
		recode innovation_year . = 2011 if c2paddy_dna == 56

		recode innovation_year . = 2012 if c2paddy_dna == 57
		recode innovation_year . = 2014 if c2paddy_dna == 62
		recode innovation_year . = 2017 if c2paddy_dna == 80
		recode innovation_year . = 2018 if c2paddy_dna == 87

		recode innovation_year . = 2019 if c2paddy_dna == 91
		recode innovation_year . = 2022 if c2paddy_dna == 100

		
		recode innovation_year . = 2008 if c2paddy_dna == 47
		recode innovation_year . = 2008 if c2paddy_dna == 49
		recode innovation_year . = 2020 if c2paddy_dna == 96
	
		
		keep c2paddy_dna c2paddy_mainvariety a1hhid_combined c2paddy_mainvarietytype ///
		c4belief_mainvariety c4main_seed_quality c4main_seed_source c4reliablemainvar_source ///
		c4corr_var_prediction c4farmer_rank a1village mis_rep innovation_year
		
		
		tempfile dna_mis
		save "`dna_mis'"

		use "${final_data}${slash}analysis_datasets${slash}HH_covariates.dta"  , clear 
		merge 1:m a1hhid_combined using "`dna_mis'",  nogenerate keep(3)
		
		rename std_hh_asset_index z_hh_asset_index
		recode c2paddy_mainvarietytype (-97 = .) (2=1)
		recode c4main_seed_source 5 = 6		
		recode c4belief_mainvariety (5=0) (4=0) (3=0) (2=0)
		recode c4main_seed_quality (5=0) (4=0) (3=0) (2=0)
		recode c4reliablemainvar_source  (5=0) (4=0) (3=0) (2=0)
		recode c4main_seed_source (1=9) (2=6) (3=9) (4=8)
		
		tab c2paddy_mainvarietytype , gen(c2paddy_mainvarietytype)
		tab c4main_seed_source , gen(c4main_seed_source)
		
		la var c2paddy_mainvarietytype1 "Self-reported variety type: Local"
		la var c2paddy_mainvarietytype2 "Self-reported variety type: Improved"
		la var c2paddy_mainvarietytype3 "Self-reported variety type: Hybrid"
		la var c4belief_mainvariety "Self-reported variety accuracy: Absolutely certain"
		la var c4main_seed_quality "Self-reported seed quality: Very high"
		la var c4main_seed_source1 "Seed source: Extension services/nursery"
		la var c4main_seed_source2 "Seed source: Store/dealer/seed company"
		la var c4main_seed_source3 "Seed source: informal"
		la var innovation_year "DNA fingerprinted variety release year"

		foreach var of varlist total_b2area a2hhroster_count a2mem_age a6_hh_savings c4farmer_rank ///
		innovation_year {
		egen z_`var' = std(`var')
		local label : var label `var'
		label variable z_`var' "`label'"
		}
		

		* Create the global 
		global cont_vars z_innovation_year z_c4farmer_rank z_total_b2area z_hh_asset_index ///
		z_a2hhroster_count z_a2mem_age z_a6_hh_savings 

		global cat_vars a4employment_status a2agri_decision_gender con_bottom20 religion_islam lit_can_read_write ///
		c2paddy_mainvarietytype2 c2paddy_mainvarietytype3 ///
		c4belief_mainvariety ///
		c4main_seed_quality c4reliablemainvar_source ///
		c4main_seed_source2 c4main_seed_source1
			
		global dum_vars a4employment_status a2agri_decision_gender con_bottom20 ///
		religion_islam lit_can_read_write c4belief_mainvariety ///
		c4main_seed_quality c4reliablemainvar_source

		eststo multivariate: regress mis_rep $cont_vars $cat_vars , cluster(a1village)
		
		foreach var in $cont_vars $dum_vars  {
		quietly eststo `var': regress mis_rep `var'
		}

		coefplot($cont_vars $dum_vars, label(bivariate)) (multivariate), drop(_cons) xline(0) omitted baselevels ///
		ylabel(, labsize(vsmall) nogrid) ///
		xlabel(-0.3 (0.1) .3, nogrid labsize(small)) ///
		headings(z_innovation_year = "{bf:Continuous Variables:Paddy characteristics}" z_total_b2area ="{bf:Continuous Variables:HH}" ///
		a4employment_status = "{bf:Binary Variables:HH}" c4belief_mainvariety = "{bf: Binary Variables: Paddy characteristics}" c2paddy_mainvarietytype2 = "{bf:Categorical Variables:Paddy characteristics}" , labcolor(black) labsize(vsmall))  ///
		graphregion(color(white)) plotregion(color(white)) ///
		title("Misclassification of DNA fingerprinted paddy [34%]", size(small)) /// 
		legend(order(1 "Bivariate" 3 "Multivariate") pos(3) cols(1) size(vsmall)) ///
		ciopts(recast(rcap)) /// 
		p1(label("Bivariate Coefficient") msymbol(O) mcolor(ebblue) noci) /// 
		p2(label("Multivariate Coefficient") msymbol(D) mcolor(dknavy) ciopts(recast(rcap) lcolor(dknavy)))

		graph export "${final_figure}${slash}figure_23.png", replace as(png)

		**# 3.4 Data analysis
		* Figure 4. Distribution of BIHS upazilas (sub-districts) 
		
		u "${final_data}${slash}SPIA_BIHS_2024_module_a1.dta", clear
		
		replace districtname = "Brahamanbaria" if districtname == "Brahmanbaria"
		replace upazilaname ="Baghai Chhari" if upazilaname == "Baghaichhari"
		replace upazilaname = "Barisal Sadar (Kotwali)" if upazilaname == "Barisal Sadar"
		replace upazilaname = "Daulatkhan" if upazilaname == "Daulat Khan"
		replace upazilaname = "Brahmanbaria Sadar" if upazilaname =="Brahmanbaria Sad"
		replace upazilaname = "Matlab Uttar" if upazilaname == "Matlab"
		replace districtname = "Nawabganj" if districtname == "Chapai Nawabganj"
		replace upazilaname = "Comilla Adarsha Sadar" if upazilaname == "Comilla Adarsha"
		replace upazilaname = "Chakaria" if upazilaname == "Chakoria"
		replace upazilaname = "Cox's Bazar Sadar" if upazilaname == "Cox's Bazar Sada"
		replace upazilaname = "Kotali Para" if upazilaname == "Kotalipara"
		replace districtname = "Jhenaidah" if districtname == "Jhenaidah Zila T"
		replace upazilaname = "Harinakunda" if upazilaname == "Harinakundu Upaz"
		replace upazilaname = "Kaliganj" if upazilaname == "Kaliganj Upazila"
		replace upazilaname = "Maheshpur" if upazilaname == "Maheshpur Upazil"
		replace upazilaname = "Kaliganj" if upazilaname == "Kaligang"
		replace upazilaname = "Maulvi Bazar Sadar" if upazilaname == "Maulvibazar Sada"
		replace upazilaname = "Noakhali Sadar (Sudharam)" if upazilaname == "Noakhali Sadar"
		replace upazilaname = "Mitha Pukur" if upazilaname == "Mithapukur"
		replace upazilaname = "Golabganj" if upazilaname == "Golapganj"
		
		collapse(first) districtname divisionname, by(upazilaname)
		
		ren (upazilaname districtname) (ADM3_EN ADM2_EN)
		g upazila = 1
		merge 1:1 ADM3_EN ADM2_EN using "${temp_data}${slash}upazila_admin", nogen keep(2 3)
		
		ren new_ID _ID
		
		preserve
		
		merge 1:m _ID using "${temp_data}${slash}upazila_coor", nogen keep(3)
		
		save "${temp_data}${slash}upazila_admin_coor", replace
		
		restore
		
		recode upazila . = 0
		
		la def upazila 0 "Non BIHS Upazilas" 1 "BIHS Upazilas"
		la val upazila upazila
		
		spmap upazila using "${temp_data}${slash}upazila_coor", id(_ID) ///
		fcolor(Blues2) clmethod(unique) title("", size(medium)) ///
		leglabel(0 "Non BIHS Upazilas" 1 "BIHS Upazilas")

		graph export "${final_figure}${slash}figure_4.png", replace as(png)