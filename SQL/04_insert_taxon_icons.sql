INSERT INTO taxon_icons (taxon_id, icon_id, allow_fallback)
SELECT
    tx.taxon_id,
    ri.icon_id,
    COALESCE(ri.allow_fallback, TRUE)

FROM raw_taxon_icons ri

JOIN genera g
    ON g.genus_name = ri.genus

JOIN taxa tx
    ON tx.genus_id = g.genus_id
    AND tx.is_hybrid IS NOT DISTINCT FROM ri.is_hybrid

   AND (
        (
            tx.taxon_level = 'infraspecies'
            AND tx.species_epithet IS NOT DISTINCT FROM ri.species_epithet
            AND tx.infraspecies_name IS NOT DISTINCT FROM ri.infraspecies_name
            AND tx.infraspecies_type IS NOT DISTINCT FROM ri.infraspecies_type
        )

        OR

        (
            tx.taxon_level = 'species'
            AND tx.species_epithet IS NOT DISTINCT FROM ri.species_epithet
            AND ri.infraspecies_name IS NULL
            AND ri.infraspecies_type IS NULL
        )

        OR

        (
            tx.taxon_level = 'genus'
            AND ri.species_epithet IS NULL
            AND ri.infraspecies_name IS NULL
            AND ri.infraspecies_type IS NULL
        )
   );  