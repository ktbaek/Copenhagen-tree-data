CREATE OR REPLACE VIEW trees_for_map AS

-- to allow for deduplication
WITH ranked AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (
            PARTITION BY t.lon, t.lat
            ORDER BY
                (t.taxon_id IS NOT NULL) DESC, 
                (t.planting_year IS NOT NULL) DESC,
                t.uuid -- fallback
        ) AS rn
    FROM trees t
)

SELECT
    t.uuid,
    tdn.scientific_name_short as scientific_name,
    tdn.scientific_name_medium as display_name,
    tdn.cultivar,

    CASE
        WHEN tdn.display_common_name IS NOT NULL THEN
        tdn.display_common_name ||
            CASE
                WHEN t.sex IN ('male', 'han') THEN ' (han)'
                WHEN t.sex IN ('female', 'hun') THEN ' (hun)'
                ELSE ''
            END
        WHEN tx.taxon_id IS NOT NULL AND gen.common_name IS NOT NULL
        THEN gen.common_name || ' (ukendt dansk artsnavn)'
        ELSE NULL
    END AS common_name,

    g.genus_name,
    gen.common_name AS genus_common_name,
    sp.common_name AS species_common_name,
    f.family_name,
    o.order_name,
    t.lat,
    t.lon,
    t.planting_year,

    COALESCE(t.protected, '') AS protected,

    CASE WHEN t.special THEN 'Særligt træ' ELSE '' END AS special,
    CASE WHEN t.iconic THEN 'Ikonisk træ' ELSE '' END AS iconic,

    COALESCE(t.fruit, FALSE) AS fruit,
    
    ri.icon_id,
    ri.icon_id IS NOT NULL AS icon_present

FROM ranked t

LEFT JOIN taxa tx ON t.taxon_id = tx.taxon_id
LEFT JOIN genera g ON tx.genus_id = g.genus_id
LEFT JOIN taxon_primary_common_names gen ON gen.taxon_id = g.taxon_id
LEFT JOIN taxon_primary_common_names sp ON sp.taxon_id = tx.species_taxon_id
LEFT JOIN families f ON g.family_id = f.family_id
LEFT JOIN orders o ON f.order_id = o.order_id
LEFT JOIN taxon_display_names tdn ON tdn.taxon_id = tx.taxon_id
LEFT JOIN resolved_icons ri ON ri.taxon_id = tx.taxon_id

WHERE t.is_duplicate_location = FALSE OR t.rn = 1;