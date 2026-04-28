CREATE MATERIALIZED VIEW resolved_icons AS
SELECT
    tx.taxon_id,

    -- icon resolution (core logic)
    COALESCE(
        ti_infra.icon_id,

        CASE
            WHEN ti_infra.allow_fallback IS FALSE THEN NULL
            ELSE ti_species.icon_id
        END,

        ti_genus.icon_id
    ) AS icon_id

FROM taxa tx

LEFT JOIN genera g 
    ON tx.genus_id = g.genus_id

-- infraspecies icon (direct match)
LEFT JOIN taxon_icons ti_infra
    ON ti_infra.taxon_id = tx.taxon_id

-- species fallback
LEFT JOIN taxa tx_species
    ON tx_species.genus_id = tx.genus_id
   AND tx_species.taxon_level = 'species'
   AND tx_species.species_epithet IS NOT DISTINCT FROM tx.species_epithet

LEFT JOIN taxon_icons ti_species
    ON ti_species.taxon_id = tx_species.taxon_id

-- genus fallback
LEFT JOIN taxa tx_genus
    ON tx_genus.genus_id = tx.genus_id
   AND tx_genus.taxon_level = 'genus'

LEFT JOIN taxon_icons ti_genus
    ON ti_genus.taxon_id = tx_genus.taxon_id;