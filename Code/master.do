clear all
set more off

global base_dir "C:/Country Studies - Bangladesh/Replication package"
global code_clean "${base_dir}/Code/Clean"
global code_analysis "${base_dir}/Code/Analysis"

/*------------------------------------------------------------------------------
    STEP 1: Process Household Survey Data
------------------------------------------------------------------------------*/
do "${code_clean}/data_structure.do"

/*------------------------------------------------------------------------------
    STEP 2: Process Community Survey Data
------------------------------------------------------------------------------*/
do "${code_clean}/data_structure_cc.do"

/*------------------------------------------------------------------------------
    STEP 3: Run Analysis and Generate Output
------------------------------------------------------------------------------*/
do "${code_analysis}/analysis.do"