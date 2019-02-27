# Toxicity Reference Database (ToxRefDB) 2.0

 README

* February 22, 2019
* Contact: paul-friedman.katie@epa.gov

This repository contains documentation, code, and examples 
for [Toxicity Reference Database (ToxRefDB)][1]. 
Some of the files in this repo
 are part of the supplemental materials for the linked publication and are labeled here 
accordingly.


Summary data files can be found on the ftp site [here][2] 


MySQL database dump and schema can be found on the ftp site [here][3]



Below are all the files available in this repo along with a brief description:


* current directory
    
* **README.md**: this file 
    
* **ToxRefDB_UserGuide.pdf**: a user guide that provides in-depth documentation on 
ToxRefDB with example use cases.
    
* **toxref_mysql_connect.py.example**: a generic method used by scripts in this repo to 
connect to a MySQL server.  



* bmd_pipeline: This directory contains code that implements the 
bmd pipeline using the [python-bmds][4] package.
    
* **part1_preparing_data.ipynb** (Supplemental File 8 ): load and prepare all 
bmd-amenable datasets from ToxRefDB
    
* **part2_running_bmds_models.ipynb** (Supplemental File 9): run BMDS models on 
bmd-amenable datasets from part1 
    
* **part3_uploading_results.ipynb** (Supplemental File 10): upload BMDS outputs 
to the database



* summary_files:
    
* **bmd_tables.ipynb**: generates the spreadsheet with all bmd values, which 
is available on the ftp site [here][2].

* ** ***toxrefdb_bmd.xlsx: (generated with bmd_tables.ipynb) the BMD-related tables from toxrefdb_2_0.	
* **BMDvsPOD.Rmd**: R markdown file to generate the BMD and POD comparisons.
    
* **cancer_effects.xlsx** (Supplemental File 11): subset of effects that were 
linked to the previous "endpoint_category" "carcinogenic".

* **effect_groups.ipynb**: generates Supplemental File 7, which are the effect
 and endpoint groupings to generate PODs and associated effect levels.
    
* ** ***effect_groups.xlsx: (generated with effect_groups.ipynb) effect groups used fo effect profiles in toxrefdb_2_0
* **endpoint_effect_mapping.xlsx** (Supplemental File 3): the endpoint and effect
 mapping from ToxRefDB v1 to ToxRefDB v2.
    
* **endpoints_and_effect.ipynb**: generates Supplemental File 2, which is the 
ToxRefDB v2 endpoint and effect terminology along with the UMLS cross-references.

* **generate_umls_file.sql**: the query used to generate, in part, 
Supplemental File 2.
    
* **guideline_profiles.ipynb**: generates Supplemental File 6, which are all of the guideline profiles that correspond to OCSPP 870 series health effects testing
 guidelines or NTP specifications.
    
* ** ***guideline_profiles.xlsx: (generated with guideline_profiles.ipynb) the guideline profiles developed based on toxrefdb_2_0 to infer negatives and differentiate these observations from untested
* **pod_tables.ipynb**: generates chemical- and study-level PODs and associated
 effect levels for a given effect grouping, which are available on the ftp site
 [here][2]
   

* ** ***chemical_level_pods_profile1.xlsx: (generated with pod_tables.ipynb) Point of departure (POD) values by chemical entity using effect profile 1 as described in Watford et al. (submitted 2019)
* ** ***chemical_level_pods_profile2.xlsx: (generated with pod_tables.ipynb) Point of departure (POD) values by chemical entity using effect profile 2 as described in Watford et al. (submitted 2019)
* ** ***study_level_pods_profile1.xlsx: (generated with pod_tables.ipynb) Point of departure (POD) values by study ID using effect profile 1 as described in Watford et al. (submitted 2019)
* ** ***study_level_pods_profile2.xlsx: (generated with pod_tables.ipynb) Point of departure (POD) values by study ID using effect profile 1 as described in Watford et al. (submitted 2019)

* **toxrefdb_2_0_data_dictionary.csv: defines all tables and fields in the database, and can be used as a reference to explain column headers in summary_files and study_flat_files. 
* **ToxRef2_0_figures.ipynb**: generates Figure 1 in the [ToxRefDB publication][1]
    
* **toxref_citations.ipynb**: generates Supplemental File 1, which are all the
 PubMed articles that cite the seminal 2009 ToxRefDB publications.
    
* **calculate_pods.ipynb**: systematically calculate chemical- and study-level 
PODs and associated effect levels for a given effect grouping. Also includes code
 to upload the values to a local database. 
    
* **unit_standardization.xlsx** (Supplemental File 5): export of the 
    "unit_standardization" table, which includes the original unit extracted from
    the document and the corresponding corrected, standardized unit.
    



* study_flat_files:
    
* **study_files.ipynb**: generates study-level flat files that contain all 
information for a given study. These flat files are available on the ftp site
    [here][5]


* **The study_flat_files folder contains a .xlsx file for each study unit extracted in toxrefdb_2_0. Within each .xlsx file, separate worksheets are included for:
* ** ***study: study meta information
* ** ***dosedTreatmentGroup: the treatment groups in the study
* ** ***dosedTreatmentGroupEffect: the effects by treatment group and lifestage; only populated if effects were observed
* ** ***negativeEndpoint: Negative endpoints for the study (based on logic to interpret the guideline profile for the study); only populated if a guideline profile was available for the study type/guideline
* ** ***negativeEffect: Negative effects for the study (based on logic to interpret the guideline profile for the study); only populated if a guideline profile was available for the study type/guideline
* ** ***pointOfDeparture: Using effect profile 2 (endpoints grouped according to endpoint category, endpoint type, or endpoint target), POD values (NEL, LEL, NOAEL, LOAEL) are reported; only populated if effects were observed
* ** ***BMDContinuousInput: Input from the study for continuous BMDS version 2.7 modeling using Python-BMDS
* ** ***BMDSDichotomousInput: Input from the study for dichotomous BMDS version 2.7 modeling using Python-BMDS
* ** ***BMDSModels: the BMDS version 2.7 output for the input data provided from the study. Note, all models are listed, and are not filtered for whether they are recommended or not. Use with caution.



[1]: toxref_doi_or_link_to_publication

[2]: ftp://newftp.epa.gov/comptox/High_Throughput_Screening_Data/Animal_Tox_Data/current/summary_files

[3]: ftp://newftp.epa.gov/comptox/High_Throughput_Screening_Data/Animal_Tox_Data/current/MySQL

[4]: https://github.com/shapiromatron/bmds

[5]: ftp://newftp.epa.gov/comptox/High_Throughput_Screening_Data/Animal_Tox_Data/current/study_flat_files