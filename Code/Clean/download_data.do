* Download BIHS data hosted on GitHub

clear all

* Define URL based on the repository's GitHub releases
local github_repo "CGIAR-SPIA/SPIA-Bangladesh-Study-2025"
local release_version "v1.0"
local filename "SPIA_BIHS_Main_2024_deidentified.xlsx"

local url "https://github.com/`github_repo'/releases/download/`release_version'/`filename'"
local destfile "${raw_data}${slash}`filename'"

* Check if file already exists
capture confirm file "`destfile'"
if _rc != 0 {
    display as text "Downloading raw data (142 MB)..."
    display as text "This may take several minutes..."
    
    capture copy "`url'" "`destfile'", replace
    
    if _rc == 0 {
        display as result "Download complete!"
    }
    else {
        display as error "Download failed. Error code: " _rc
        exit _rc
    }
}
else {
    display as text "Data file already exists."
}
