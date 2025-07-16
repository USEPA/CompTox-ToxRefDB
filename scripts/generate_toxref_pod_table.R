# Generate PODs for ToxRefDB v3.0
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
# LOAD all effect data
#-----------------------------------------------------------------------------------#
con <- dbConnect(drv = "PostgreSQL", user="",
                 password = "pass",
                 host = "", db="res_toxref")

effects <- dbGetQuery(con, "SELECT chemical.*,
                          study.study_id,
                          study.processed,
                          study.study_type,
                          study.study_year,
                          study.study_source,
                          study.species,
                          study.strain,
                          study.strain_group,
                          study.admin_route,
                          study.admin_method,
                          study.dose_start,
                          study.dose_start_unit,
                          study.dose_end,
                          study.dose_end_unit,
                          study.study_citation,
                          endpoint.endpoint_category,
                          endpoint.endpoint_type,
                          endpoint.endpoint_target,
                          endpoint.endpoint_id,
                          tg_effect.life_stage,
                          effect.effect_id,
                          effect.effect_desc,
                          effect.cancer_related,
                          tg.sex,
                           tg.n,
                          tg.generation,
                          dose.dose_level,
                          dose.conc,
                          dose.conc_unit,
                          dose.vehicle,
                          dtg.dose_adjusted,
                          dtg.dose_adjusted_unit,
                          dtg.mg_kg_day_value,
                          dtg_effect.*
                          FROM 
                          ((((((((prod_toxrefdb_3_0.chemical 
                          LEFT JOIN prod_toxrefdb_3_0.study ON chemical.chemical_id=study.chemical_id)
                          LEFT JOIN prod_toxrefdb_3_0.dose ON dose.study_id=study.study_id)
                          LEFT JOIN prod_toxrefdb_3_0.tg ON tg.study_id=study.study_id)
                          LEFT JOIN prod_toxrefdb_3_0.dtg ON tg.tg_id=dtg.tg_id AND dose.dose_id=dtg.dose_id)
                          LEFT JOIN prod_toxrefdb_3_0.tg_effect ON tg.tg_id=tg_effect.tg_id)
                          LEFT JOIN prod_toxrefdb_3_0.dtg_effect ON tg_effect.tg_effect_id=dtg_effect.tg_effect_id AND dtg.dtg_id=dtg_effect.dtg_id)
                          LEFT JOIN prod_toxrefdb_3_0.effect ON effect.effect_id=tg_effect.effect_id)
                          LEFT JOIN prod_toxrefdb_3_0.endpoint ON endpoint.endpoint_id=effect.endpoint_id)
                          where study.processed=TRUE ;") %>% 
  data.table()

#-----------------------------------------------------------------------------------#
# Calculate PODs
#-----------------------------------------------------------------------------------#
pod.calc <- function(effects) {
  
  #LIST dose levels by study id (3871 study ids)
  dose.levels <- effects[, list(
    min.dose.level = min(dose_level),
    max.dose.level = max(dose_level),
    min.dose = min(mg_kg_day_value),
    max.dose = max(mg_kg_day_value),
    doses.tested = length(unique(mg_kg_day_value))
  ), by = list(study_id, preferred_name)]
  
  effects[,toxval_study_source_id := ifelse(is.na(life_stage), 
         paste0("studyid", study_id, "_", study_type),
         paste0("studyid", study_id,"_", life_stage, "_", generation, "_", sex, "_", endpoint_category))]
  effects[,toxval_effect := paste0(endpoint_type, '-', endpoint_target, '-', effect_desc)]  

  #inspect NA values: Set dtg with no treatment related or critical effects = 0, to be used to set MAX dose level PODs
  effects[is.na(effects$treatment_related), treatment_related:=0]
  effects[is.na(effects$critical_effect), critical_effect:=0]
  
  #drop if no mg_kg/day value available
  effects <- effects[!is.na(effects$mg_kg_day_value),]
  
  #By study_id, calculate the min(mg_kg_day_value) where treatment_related=1 for LEL
  TR.effects <- effects[effects$treatment_related == 1,]
  LEL <- TR.effects %>% 
    group_by(toxval_study_source_id) %>%
    arrange(study_id, dose_adjusted) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect, dose_level, mg_kg_day_value) %>%
    mutate(toxval_effect_list = paste0(unique(toxval_effect), collapse = "|")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, mg_kg_day_value) %>%
    slice(which.min(mg_kg_day_value))
  setDT(LEL)
  LEL[, calc_pod_type:= "LEL"]
  LEL[, qualifier:= "="]
  
  #By study_id, calculate the min(mg_kg_day_value) where critical_effect=1 for LOAEL
  C.effects <- effects[effects$critical_effect == 1,]
  LOAEL <- C.effects %>% 
    group_by(toxval_study_source_id) %>%
    arrange(study_id, mg_kg_day_value) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect, dose_level, mg_kg_day_value) %>%
    mutate(toxval_effect_list = paste0(unique(toxval_effect), collapse = "|")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, mg_kg_day_value) %>%
    slice(which.min(mg_kg_day_value))
  setDT(LOAEL)
  LOAEL[, calc_pod_type:= "LOAEL"]
  LOAEL[, qualifier:= "="]
  
  #By study_id, determine the dose_level (0,1,2,3,4) that was the LOAEL
  NOAEL <- select(LOAEL, study_id, preferred_name, toxval_study_source_id, dose_level)
  #Then ask, what is the next lowest dose_level, and that is the NOAEL dose_level 
  NOAEL <- NOAEL[,dose_level := dose_level -1] 
  NOAEL.1 <- semi_join(effects, NOAEL)
  #Then what is the max dose_adjusted for that dose_level in that study_id
  NOAEL.2 <- NOAEL.1 %>% 
    group_by(toxval_study_source_id) %>%
    arrange(study_id, desc(mg_kg_day_value)) %>%
    select(study_id, preferred_name,  toxval_study_source_id, toxval_effect, dose_level, mg_kg_day_value) %>%
    mutate(toxval_effect_list = paste0(unique(toxval_effect), collapse = "|")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, mg_kg_day_value) %>%
    slice(which.max(mg_kg_day_value))
  setDT(NOAEL.2)
  NOAEL.2[, calc_pod_type:= "NOAEL"]
  NOAEL.2[, qualifier:= "="]
  #If LOAEL is the lowest non-vehicle dose tested (dose_level=1) Then there is no NOAEL (NOAEL > 0)
  NOAEL.2[calc_pod_type =="NOAEL" & dose_level == "0", qualifier := ">"] 
  
  #By study_id, determine NEL as next lowest dose level from LEL
  NEL <- select(LEL, study_id, preferred_name, toxval_study_source_id, dose_level)
  NEL <- NEL[,dose_level := dose_level -1]
  NEL.1 <- semi_join(effects, NEL)
  NEL.2 <- NEL.1 %>%                     
    group_by(toxval_study_source_id) %>%
    arrange(study_id, desc(mg_kg_day_value)) %>%
    select(study_id, preferred_name,  toxval_study_source_id, toxval_effect, dose_level, mg_kg_day_value) %>%
    mutate(toxval_effect_list = paste0(unique(toxval_effect), collapse = "|")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, mg_kg_day_value) %>%
    slice(which.max(mg_kg_day_value))
  setDT(NEL.2)
  NEL.2[, calc_pod_type:= "NEL"]
  NEL.2[, qualifier:= "="]
  #If LEL is the lowest non-vehicle dose tested (dose_level=1) Then there is no NEL (NEL > 0)
  NEL.2[calc_pod_type =="NEL" & dose_level == "0", qualifier := ">"] 
  
  # Add SPECIAL QUALIFIERS if no effect: 
  #  LOAEL > value: No effect observed in the study, LOAEL > highest dose tested
  #  NOAEL => highest dose tested
  #  SAME LOGIC FOR LEL and NEL?
  No.effects <- effects[is.na(endpoint_category),]
  #find max dose level by study
  MAX <- select(dose.levels, study_id, preferred_name, max.dose.level)
  setnames(MAX, "max.dose.level", "dose_level")
  # #subset no effect table by max dose levels ()
  No.effect.MAX <-inner_join(No.effects, MAX)
  No.effect.MAX2 <- No.effect.MAX %>%
    group_by(toxval_study_source_id) %>%
    arrange(study_id, desc(mg_kg_day_value)) %>%
    select(study_id, preferred_name,  toxval_study_source_id, toxval_effect, dose_level, mg_kg_day_value) %>%
    mutate(toxval_effect_list = paste0(unique(toxval_effect), collapse = "|")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, mg_kg_day_value) %>%
    slice(which.max(mg_kg_day_value))
  
  #identify NEL/NOAELs at max doses with no effects
  No.effect.MAX2 <- as.data.table(No.effect.MAX2)
  list_column <- c("NEL", "NOAEL", "LEL", "LOAEL")
  NO.effects.all <- No.effect.MAX2 %>%
    group_by(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, mg_kg_day_value) %>%
    expand(calc_pod_type = list_column)
  setDT(NO.effects.all)
  NO.effects.all <- NO.effects.all[,toxval_effect_list := "NA"]
  NO.effects.all <- NO.effects.all[calc_pod_type %in% c("NEL","NOAEL"), qualifier := ">="]
  NO.effects.all <- NO.effects.all[calc_pod_type %in% c("LEL","LOAEL"), qualifier := ">"]
  
  #update required lifestages per study type
  #DEV
  NO.effects.DEV <-  NO.effects.all[grepl("DEV", toxval_study_source_id),]
  DEV_list_column <- c("Adult_F0_F", "Fetal_Fetal_MF")
  NO.effects.DEV <- NO.effects.DEV %>%
    group_by(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, calc_pod_type, qualifier, mg_kg_day_value) %>%
    expand(study_type_lifestage = DEV_list_column) %>%
    mutate(toxval_study_source_id = paste0(toxval_study_source_id,"_", study_type_lifestage, "_NA")) %>%
    mutate(toxval_study_source_id = str_remove(toxval_study_source_id, "_DEV"))  %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, calc_pod_type, qualifier, mg_kg_day_value)
  #MGR
  NO.effects.MGR <-  NO.effects.all[grepl("MGR", toxval_study_source_id),]
  MGR_list_column <- c("Adult_F0_F", "Adult_F0_F", "Juvenile_F1_F", "Juvenile_F1_F", 
                       "Adult_F1_F", "Adult_F1_M")
  NO.effects.MGR<- NO.effects.MGR %>%
    group_by(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, calc_pod_type, qualifier, mg_kg_day_value) %>%
    expand(study_type_lifestage = MGR_list_column) %>%
    mutate(toxval_study_source_id = paste0(toxval_study_source_id,"_", study_type_lifestage, "_NA")) %>%
    mutate(toxval_study_source_id = str_remove(toxval_study_source_id, "_MGR")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, calc_pod_type, qualifier, mg_kg_day_value)
  #SUB or CHR
  NO.effects.SUB.CHR <-  NO.effects.all[grepl("SUB", toxval_study_source_id) | grepl("CHR", toxval_study_source_id),]
  SUB.CHR_list_column <- c("Adult_F0_F", "Adult_F0_M")
  NO.effects.SUB.CHR<- NO.effects.SUB.CHR %>%
    group_by(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, calc_pod_type, qualifier, mg_kg_day_value) %>%
    expand(study_type_lifestage = SUB.CHR_list_column ) %>%
    mutate(toxval_study_source_id = paste0(toxval_study_source_id,"_", study_type_lifestage, "_NA")) %>%
    mutate(toxval_study_source_id = str_remove(toxval_study_source_id, "_SUB")) %>%
    mutate(toxval_study_source_id = str_remove(toxval_study_source_id, "_CHR")) %>%
    select(study_id, preferred_name, toxval_study_source_id, toxval_effect_list, dose_level, calc_pod_type, qualifier, mg_kg_day_value)

    #combine PODs of effect data with PODs at MAX doses/lifestages per study type 
  #remove if study id/lifestage is already represented with effect data
  combined <- rbind(LEL, LOAEL, NEL.2, NOAEL.2, NO.effects.DEV, NO.effects.MGR, NO.effects.SUB.CHR)
  #select minimum value as POD
  combined <- combined %>%
    mutate(toxval_study_source_id2 = sub("^(([^_]*_){3}[^_]*).*", "\\1", toxval_study_source_id)) %>%
    group_by(toxval_study_source_id2, calc_pod_type) %>%
    slice(which.min(mg_kg_day_value))
  
  #add metadata fields
  pod<- distinct(merge(x = combined, y = effects[,c("study_id", "dsstox_substance_id", "study_type", "study_citation", "study_year", "vehicle", "admin_route", "admin_method",
                                               "species",  "strain_group", "strain",  "dose_start", "dose_start_unit", "dose_end", "dose_end_unit")], 
                       by.x = "study_id", by.y="study_id"))
  
  pod <- pod %>%
    group_by(study_id, preferred_name, toxval_study_source_id, calc_pod_type) %>%
    distinct() %>%
    select( study_id, study_type, preferred_name, dsstox_substance_id, toxval_study_source_id, toxval_effect_list,
            dose_level,calc_pod_type, qualifier, mg_kg_day_value,             
            admin_route, admin_method, vehicle, species, strain_group, strain, dose_start, dose_start_unit, dose_end, dose_end_unit, study_year, study_citation)

}
pod <- pod.calc(effects)