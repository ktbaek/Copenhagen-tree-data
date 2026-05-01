CREATE OR REPLACE VIEW for_species_stats_2025 AS

select 
    tfm.uuid,
    tx.taxon_id,
    tx.genus_id,
    tx.species_taxon_id,
    t.planting_year,
    (t.protected is not null) as protected,
    t.iconic,
    d.district_name,
    tx.infraspecies_type,
    tx.infraspecies_name

from trees_for_map_2025 tfm

left join trees_2025 t on tfm.uuid = t.uuid
LEFT JOIN taxa tx ON t.taxon_id = tx.taxon_id
LEFT JOIN districts d ON t.district_id = d.district_id