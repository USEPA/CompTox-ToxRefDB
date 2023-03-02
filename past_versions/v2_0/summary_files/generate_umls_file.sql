SELECT 
	endpoint.endpoint_id,
    endpoint.endpoint_category,
    endpoint.endpoint_type,
    endpoint.endpoint_target,
    NULL AS effect_id,
    NULL AS effect_desc,
    GROUP_CONCAT(DISTINCT ontology_name,";",uid,";",uid_type,";",label separator "|") AS umls_xref
FROM 
	dev_toxrefdb_2_0.ontology INNER JOIN dev_toxrefdb_2_0.ontology_toxrefdb ON ontology.ontology_id=ontology_toxrefdb.ontology_id
		INNER JOIN dev_toxrefdb_2_0.endpoint ON endpoint.endpoint_id=ontology_toxrefdb.toxrefdb_id
WHERE ontology_toxrefdb.toxrefdb_table="endpoint"
GROUP BY 
	endpoint.endpoint_id,
    endpoint.endpoint_category,
    endpoint.endpoint_type,
    endpoint.endpoint_target
    
UNION

SELECT 
	tbl2.endpoint_id,
	tbl2.endpoint_category,
	tbl2.endpoint_type,
	tbl2.endpoint_target,
	tbl2.effect_id,
	tbl2.effect_desc,
	CONCAT(tbl1.endpoint_mapping,"|",tbl2.effect_mapping) AS umls_xref
FROM
(SELECT 
	endpoint.endpoint_id,
    endpoint.endpoint_category,
    endpoint.endpoint_type,
    endpoint.endpoint_target,
    GROUP_CONCAT(DISTINCT ontology_name,";",uid,";",uid_type,";",label separator "|") AS endpoint_mapping,
    NULL AS effect_id,
    NULL AS effect_desc
FROM 
	dev_toxrefdb_2_0.ontology INNER JOIN dev_toxrefdb_2_0.ontology_toxrefdb ON ontology.ontology_id=ontology_toxrefdb.ontology_id
		INNER JOIN dev_toxrefdb_2_0.endpoint ON endpoint.endpoint_id=ontology_toxrefdb.toxrefdb_id
WHERE ontology_toxrefdb.toxrefdb_table="endpoint"
GROUP BY 
	endpoint_id,
    endpoint_category,
    endpoint_type,
    endpoint_target) AS tbl1

LEFT JOIN

(SELECT 
	endpoint.endpoint_id,
    endpoint.endpoint_category,
    endpoint.endpoint_type,
    endpoint.endpoint_target,
    effect.effect_id,
    effect.effect_desc,
    GROUP_CONCAT(DISTINCT ontology_name,";",uid,";",uid_type,";",label separator "|") AS effect_mapping
FROM 
	dev_toxrefdb_2_0.ontology INNER JOIN dev_toxrefdb_2_0.ontology_toxrefdb ON ontology.ontology_id=ontology_toxrefdb.ontology_id
		INNER JOIN dev_toxrefdb_2_0.effect ON effect.effect_id=ontology_toxrefdb.toxrefdb_id
			INNER JOIN dev_toxrefdb_2_0.endpoint ON endpoint.endpoint_id=effect.endpoint_id
WHERE ontology_toxrefdb.toxrefdb_table="effect"
GROUP BY 
	endpoint_id,
    endpoint_category,
    endpoint_type,
    endpoint_target,
    effect_id,
    effect_desc) AS tbl2
ON tbl1.endpoint_id=tbl2.endpoint_id;