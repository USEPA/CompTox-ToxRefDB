# Generate negative endpoint and effect tables for ToxRefDB v3.0
# Madison Feshuk
# August 2025
#-----------------------------------------------------------------------------------#
# LOAD libraries
#-----------------------------------------------------------------------------------#
rm(list=ls())
library(openxlsx)
library(data.table)
library(RPostgreSQL)
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

#-----------------------------------------------------------------------------------#
# Derive negative effects 
#-----------------------------------------------------------------------------------#
con <- dbConnect(drv = "PostgreSQL", user="",
                 password = "pass",
                 host = "", db="res_toxref")

# adapt logic from v2.1 stored procedures
negative_effects <- dbGetQuery(con, "SELECT tmp1.study_id, tmp1.endpoint_id,tmp1.effect_id
FROM (SELECT obs.endpoint_id, study_id, tested_status, reported_status, effect_id 
            FROM prod_toxrefdb_3_0.obs INNER JOIN effect ON effect.endpoint_id=obs.endpoint_id 
            WHERE tested_status is TRUE AND study_id IN(SELECT study_id FROM prod_toxrefdb_3_0.study WHERE processed is TRUE)) AS tmp1 
  LEFT JOIN (SELECT * FROM(SELECT study.study_id, endpoint.endpoint_id, effect.effect_id, tg_effect.tg_effect_id,
      SUM(CASE WHEN treatment_related IS TRUE THEN 1 ELSE 0 END) AS tr
        FROM prod_toxrefdb_3_0.study
      INNER JOIN prod_toxrefdb_3_0.dose ON dose.study_id=study.study_id
      INNER JOIN prod_toxrefdb_3_0.tg ON tg.study_id=study.study_id
      INNER JOIN prod_toxrefdb_3_0.dtg ON tg.tg_id=dtg.tg_id AND dose.dose_id=dtg.dose_id
      INNER JOIN prod_toxrefdb_3_0.tg_effect ON tg.tg_id=tg_effect.tg_id
      INNER JOIN prod_toxrefdb_3_0.dtg_effect ON tg_effect.tg_effect_id=dtg_effect.tg_effect_id AND dtg.dtg_id=dtg_effect.dtg_id
      INNER JOIN prod_toxrefdb_3_0.effect ON effect.effect_id=tg_effect.effect_id
      INNER JOIN prod_toxrefdb_3_0.endpoint ON endpoint.endpoint_id=effect.endpoint_id 
  GROUP BY study.study_id, endpoint.endpoint_id, effect.effect_id,tg_effect.tg_effect_id) AS tmp0 WHERE tr>0) AS tmp2  
    ON tmp1.study_id=tmp2.study_id AND tmp1.endpoint_id=tmp2.endpoint_id AND tmp1.effect_id=tmp2.effect_id
WHERE tmp2.tg_effect_id IS null;") %>% 
  data.table()

negative_effect <- negative_effects[,negative_effect_id := rownames(negative_effects)]
negative_effect$negative_effect_id <- as.numeric(negative_effect$negative_effect_id)

#-----------------------------------------------------------------------------------#
# Derive negative endpoints
#-----------------------------------------------------------------------------------#
# adapt logic from v2.1 stored procedures
negative_endpoints <- dbGetQuery(con, "SELECT	tmp1.study_id,tmp2.endpoint_id 
	FROM 
		(SELECT 
			study_id,
			endpoint_id,
			COUNT(effect_id) AS effect_ct 
		FROM  prod_toxrefdb_3_0.negative_effect
		GROUP BY study_id,negative_effect.endpoint_id) AS tmp1 INNER JOIN 
		(SELECT 
			endpoint.endpoint_id,
			COUNT(effect_id) AS effect_ct
		FROM prod_toxrefdb_3_0.endpoint INNER JOIN prod_toxrefdb_3_0.effect ON effect.endpoint_id=endpoint.endpoint_id GROUP BY endpoint.endpoint_id) AS tmp2
		ON tmp1.endpoint_id=tmp2.endpoint_id WHERE tmp1.effect_ct=tmp2.effect_ct; ") %>% 
  data.table()

negative_endpoint <- negative_endpoints[,negative_endpoint_id := rownames(negative_endpoints)]
negative_endpoint$negative_endpoint_id <- as.numeric(negative_endpoint$negative_endpoint_id)
