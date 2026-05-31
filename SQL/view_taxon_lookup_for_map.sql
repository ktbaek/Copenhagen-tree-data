CREATE OR REPLACE VIEW taxon_lookup_for_map AS
SELECT DISTINCT
  tx.taxon_id,
  tx.genus_id as genus_taxon_id,
  tx.species_taxon_id,
  tdn.scientific_name_short as scientific_name,
  tdn.scientific_name_medium as display_name,
  tdn.cultivar,
  tdn.common_name,
  g.genus_name
  gen_cn.common_name as genus_common_name,
  sp_cn.common_name as species_common_name,
  CASE 
    WHEN f.taxon_id IS NOT NULL THEN TRUE
    ELSE FALSE
  END AS fruit, 
  rt.rarity,
  ri.icon_id,
  c.fillcolor
  

FROM taxa r

LEFT JOIN genera g 
  ON tx.genus_id = g.genus_id
  
LEFT JOIN taxon_display_names tdn 
  ON tx.taxon_id = tdn.taxon_id

LEFT JOIN taxon_primary_common_names gen
  ON gen.taxon_id = g.taxon_id

LEFT JOIN taxon_primary_common_names sp 
  ON sp.taxon_id = tx.species_taxon_id

LEFT JOIN fruit f 
  ON f.taxon_id = tx.taxon_id

LEFT JOIN rarity rt
  ON tx.taxon_id = rt.taxon_id;

LEFT JOIN resolved_icons ri 
  ON tx.taxon_id = ri.taxon_id

LEFT JOIN species_colors c 
  ON tx.taxon_id = c.taxon_id




