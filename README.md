# Toxicity Reference Database (ToxRefDB) v2.1

 README

* Updated: March 1, 2023
* Contact: feshuk.madison@epa.gov, watford.sean@epa.gov

This repository contains files to support the Toxicity Reference Database (ToxRefDB) v2.1 release as well as legacy information. The Toxicity Reference Database (ToxRefDB) contains in vivo study data from over 5900 guideline or guideline-like studies. ToxRefDB allows scientists and the interested public to access thousands of curated animal toxicity testing results, which is a great resource for many retrospective and predictive toxicology applications. 

The first version of ToxRefDB (ToxRefDB 1.0) was initially released as a series of spreadsheets, which are still available on EPA’s FTP site and referenced in FigShare at (https://doi.org/10.23645/epacomptox.6062545.v1). ToxRefDB underwent significant updates that are described in the recent publication (Watford et al., 2019) and was released as ToxRefDB v2.0. ToxRefDB v2.1 is a rebuild of ToxRefDB v2.0 to correct issues discovered with the compilation script that resulted in failure to import some effects. Visit [Clowder](https://clowder.edap-cluster.com/datasets/61147fefe4b0856fdc65639b#folderId=62c5cfebe4b01d27e3b2d851&page=0) to download the complete database package, including the referenced files below:


1.	[601B22001_ToxRefDB_v2.1_UserGuide.pdf](https://nepis.epa.gov/Exe/ZyPDF.cgi/P1015KWT.PDF?Dockey=P1015KWT.PDF): 
This file provides information about the database development, database contents, data dictionary for all tables and fields, and sample queries to extract information from the MySQL database.

2.	ToxRefDB_2_1_release_note.html:
This interactive .html report provides information regarding what has changed between ToxRefDB v2.0 and this new release, v2.1. Largely, v2.1 includes some minor updates and bug fixes to enhance the quality of the database.

3.	Toxrefdb_2_1_study_chemical_summary.xlsx:
This summary flat file provides study and chemical metadata for all curated information in ToxRefDB v2.1. This file can be useful for understanding the chemical and study coverage of the current database.

4.	Toxrefdb_2_1_erd.png:
This .png file visualizes the entity relation diagram (ERD) for the ToxRefDB v2.1 MySQL database schema. Users may find this file helpful for understanding joins and foreign key constraints to extract information from ToxRefDB v2.1.

5.	ToxRefDB v2.1 .SQL database:
The entire v2.1 database is available as a MySQL (.sql) downloadable for mounting to a MySQL server on [Clowder](https://clowder.edap-cluster.com/datasets/61147fefe4b0856fdc65639b#folderId=62c5cfebe4b01d27e3b2d851.) Stored procedures were exported in a separate .sql file.

6.	Toxrefdb_2_0_recalc_pod.csv:
This is a helper file used in the ToxRefDB_2_1_release_note.html. In the original release of ToxRefDB v2.0, points of departure (PODs) were pre-calculated as a convenience for groups of data, and within these calculations, sexes were grouped. In ToxRefDB v2.1, PODs were calculated for each sex provided. Thus, to make comparisons of PODs calculated from multiple studies between ToxRefDB v2.0 and v2.1, PODs were re-calculated for ToxRefDB v2.0 using the same approach as in v2.1; these re-calculated PODs are stored in this file.
