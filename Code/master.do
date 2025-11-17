/*==============================================================================
    MASTER SCRIPT - Bangladesh Country Study Replication Package
    
    Purpose: Centralized directory management and script execution
    Author: Milcah Kirinyet
    Date: November 13, 2025
    
==============================================================================*/

clear all
set more off

/*------------------------------------------------------------------------------
    DIRECTORY CONFIGURATION
    
    ** MODIFY THIS PATH TO MATCH YOUR LOCAL SETUP **
    Change the path below to wherever you cloned the repository
------------------------------------------------------------------------------*/

global dir "C:/Country Studies - Bangladesh/Replication package"

* Alternative examples for different users:
* global dir "C:/Users/YourName/Documents/GitHub/repo-name"
* global dir "/Users/YourName/Documents/GitHub/repo-name"

/*------------------------------------------------------------------------------
    AUTOMATED DIRECTORY STRUCTURE
    (No need to modify below this line)
------------------------------------------------------------------------------*/

* Set working directory
cd "$dir"

* Define slash for cross-platform compatibility
if c(os) == "Windows" {
    global slash "\"
}
else {
    global slash "/"
}

* Code directories
global code_clean "${dir}${slash}Code${slash}Clean"
global code_analysis "${dir}${slash}Code${slash}Analysis"

* Data directories - Main
global raw_data "${dir}${slash}Data${slash}Raw"
global final_data "${dir}${slash}Data${slash}Final"
global temp_data "${dir}${slash}Data${slash}Temp"
global dna_data "${dir}${slash}Data${slash}DNA fingerprinting"
global prior_data "${dir}${slash}Data${slash}Prior Waves"

* Data directories - Prior waves
global bihs2018 "${prior_data}${slash}Third Round (2018-2019)"
global bihs2015 "${prior_data}${slash}Second Round (2015-2016)"
global bihs2012 "${prior_data}${slash}First Round (2011-2012)"

* Data directories - Special
global cc_data "${final_data}${slash}CC"

* Output directories
global final_figure "${dir}${slash}Output${slash}Figures"
global final_table "${dir}${slash}Output${slash}Tables"
global dna_table "${final_table}${slash}DNA_Tables"

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

do "${code_analysis}/analysis.do"

