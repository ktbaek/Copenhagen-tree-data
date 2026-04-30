CREATE OR REPLACE VIEW common_name_diffs AS
SELECT
    t.uuid,
    g.genus_name,
    tx.is_hybrid,
    tx.species_epithet,
    tx.infraspecies_name,
    tx.infraspecies_type,
    tdn.scientific_name_medium as scientific_name,
    tdn.cultivar,
    tx.taxon_level,
    t.sex,
    tdn.display_common_name as common_name,
    t.raw_dansk_navn,
    t.raw_slaegtsnavn
    

FROM trees t
LEFT JOIN taxa tx ON t.taxon_id = tx.taxon_id
LEFT JOIN genera g ON tx.genus_id = g.genus_id
LEFT JOIN districts d ON t.district_id = d.district_id
LEFT JOIN taxon_display_names tdn ON tdn.taxon_id = tx.taxon_id;