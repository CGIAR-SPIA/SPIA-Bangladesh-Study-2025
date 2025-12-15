Welcome to this repository, which contains the replication files for SPIA Bangladesh Study 2025: Updating the Green Revolution by Saumya Singla, Tanjim Ul Islam, Fuad Hassan, Isabella Monteiro, James Stevenson, Kyle Emerick.

This repository provides the code, data and supporting documentation needed to reproduce the tables and figures in the report.


The repo is structured as follows:

# 1. Data
Contains six folders: Raw, Temporary, Final, DNA fingerprinting, Prior Waves, and Codebook.

-	The **Raw** folder includes all non-PII datasets for the household main survey, the household resurvey, and the community survey in .csv and .xlsx format.
-	The **Temporary** folder stores intermediate datasets used during merging and cleaning.
-	The **Final** folder contains cleaned household datasets, a sub-folder titled CC which includes the cleaned community survey datasets, and a sub-folder titled Analysis Datasets which includes datasets generated specifically for certain figures and tables.
-	 The **DNA fingerprinting** folder contains data related to the DNA fingerprinting exercise
-	The **Prior Waves** folder contains data from the previous three rounds of BIHS conducted by IFPRI which are necessary for conducting our analysis. These datasets have been collected from the publicly available Harvard Dataverse repository
-	The **Codebook** folder contains the surveyCTO codebook in xlsx format used for the main survey, resurvey, and the community survey.

# 2. Code
Includes three main Stata scripts:

| Script | Purpose |
|--------|---------|
| `data_structure.do` | Processes raw household data into final datasets |
| `data_structure_cc.do` | Processes raw community survey data |
| `analysis.do` | Generates all figures and tables for the report |
     
- A master script `master.do` has been provided that execute the full workflow generating 43 datasets that support 52 figures and 12 tables in the report </span>.

# 3. Output
Comprises two subfolders: **Figures and Tables**. Each figure and table created within the analysis do file identifies the table or figure it creates (e.g., figure_49, table_6) and should be easy to correlate with the manuscript.

-	Figures contains a subfolder, Temporary Graphs, which includes intermediate .gph and .png files used to assemble final visuals.
-	Final figures are in .png format; all tables are in .xlsx format.

# 4. Documentation
Includes the BIHS household and community survey questionnaires, resurvey CAPI instructions that details which questions were asked in the resurvey and resurvey specific instructions, and a data cleaning dictionary file detailing all corrections made during the cleaning process.

# Prerequisites/Instructions to Replicators

-	The entire codebase is written in Stata (code was last run with version 17). Users will need;
      -	Stata 17 or higher
      - Storage: 2 GB minimum
      - Runtime: ~2 hours for full workflow
-	Edit the directory of the global “dir” in the master do files prior to running. `global dir "C:/your/path/to/repository" `

 # Citation
Singla, S., Ul Islam, T., Hassan, F., Monteiro, I., Stevenson, J.,Emerick, K. (2025). SPIA 
Bangladesh Study 2025: Updating the Green Revolution. Rome. Standing Panel on Impact 
Assessment (SPIA)

# Acknowledgements
We thank the contributors acknowledged in the report, please see the report linked above.

# Contact & Support
Primary Contact: SPIA (spia@cgiar.org)


# License

Appropriate permission are documented in the **[LICENSE.txt](https://osf.io/v9jtu)** file.
