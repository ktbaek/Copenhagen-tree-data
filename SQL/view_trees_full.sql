CREATE OR REPLACE VIEW trees_full AS
SELECT
    t.uuid,
    g.genus_name,
    tx.is_hybrid,
    tx.species_epithet,
    tx.infraspecies_name,
    tx.infraspecies_type,
    tdn.scientific_name_long as scientific_name,
    tdn.cultivar,
    tdn.common_name,
    tx.taxon_level,
    t.sex,
    d.district_name,
    t.planting_year,
    t.protected,
    t.special,
    t.iconic,
    t.fruit,
    t.lat,
    t.lon,
    t.is_duplicate_location,
    tx.taxon_id

FROM trees t
LEFT JOIN taxa tx ON t.taxon_id = tx.taxon_id
LEFT JOIN genera g ON tx.genus_id = g.genus_id
LEFT JOIN districts d ON t.district_id = d.district_id
LEFT JOIN taxon_display_names tdn ON tdn.taxon_id = tx.taxon_id;