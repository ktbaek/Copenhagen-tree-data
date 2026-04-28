CREATE MATERIALIZED VIEW taxon_display_names AS

WITH base AS (
    SELECT
        tx.taxon_id,
        tx.genus_id,
        tx.taxon_level,
        tx.species_epithet,
        tx.infraspecies_type,
        tx.infraspecies_name,
        tx.is_hybrid,
        tx.show_cultivar_in_display,
        g.genus_name,

        COALESCE(
            tpn.common_name,
            tpn_species.common_name
        ) AS base_common_name

    FROM taxa tx 
    LEFT JOIN genera g ON g.genus_id = tx.genus_id
    LEFT JOIN taxon_primary_common_names tpn on tpn.taxon_id = tx.taxon_id
    LEFT JOIN taxon_primary_common_names tpn_species on tpn_species.taxon_id = tx.species_taxon_id
)

SELECT
    b.taxon_id,

    -- Scientific names
    TRIM(
        COALESCE(b.genus_name, '') ||

        CASE
            WHEN b.is_hybrid THEN ' hybr.'
            WHEN b.taxon_level = 'genus' THEN ' sp.'
            ELSE ''
        END ||

        CASE
            WHEN b.species_epithet IS NOT NULL
            THEN ' ' || b.species_epithet
            ELSE ''
        END
    ) AS scientific_name_short,

    TRIM(
        COALESCE(b.genus_name, '') ||

        CASE
            WHEN b.is_hybrid THEN ' hybr.'
            WHEN b.taxon_level = 'genus' THEN ' sp.'
            ELSE ''
        END ||

        CASE
            WHEN b.species_epithet IS NOT NULL
            THEN ' ' || b.species_epithet
            ELSE ''
        END ||

        CASE
            WHEN b.taxon_level = 'infraspecies'
                 AND b.infraspecies_type IS DISTINCT FROM 'cultivar'
            THEN ' ' || b.infraspecies_type || ' ' || b.infraspecies_name
            ELSE ''
        END
    ) AS scientific_name_long,

    -- Cultivar
    CASE
        WHEN b.taxon_level = 'infraspecies'
             AND b.infraspecies_type = 'cultivar'
        THEN b.infraspecies_name
        ELSE NULL
    END AS cultivar,

    -- Raw common name
    b.base_common_name AS common_name,

    -- Display name (cultivar logic)
    CASE
    WHEN b.base_common_name IS NOT NULL
        AND b.taxon_level = 'infraspecies'
        AND b.infraspecies_type = 'cultivar'
        AND b.show_cultivar_in_display
    THEN b.base_common_name || ' ''' || b.infraspecies_name || ''''
    ELSE b.base_common_name
    END AS display_common_name

FROM base b;