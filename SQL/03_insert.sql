-- insert orders
INSERT INTO orders (order_name)
SELECT DISTINCT ro.order_name
FROM raw_orders ro;

-- insert families
INSERT INTO families (family_name, order_id)
SELECT DISTINCT
    rf.family_name,
    o.order_id
FROM raw_families rf
JOIN orders o
    ON o.order_name = rf.order_name
WHERE rf.family_name <> '' AND rf.order_name <> '';

-- insert genera
INSERT INTO genera (genus_name, family_id)
SELECT DISTINCT
    rg.genus_name,
    f.family_id
FROM raw_genera rg
JOIN families f
    ON f.family_name = rg.family_name
WHERE rg.genus_name <> '' AND rg.family_name <> '';

-- insert districts
INSERT INTO districts (district_name)
SELECT DISTINCT rd.district_name
FROM raw_districts rd;

-- insert taxa
-- check give zero rows
SELECT *
FROM raw_taxa
WHERE genus = '' OR genus IS NULL;

-- insert
INSERT INTO taxa (
    genus_id,
    species_epithet,
    infraspecies_name,
    infraspecies_type,
    is_hybrid,
    taxon_level
)
SELECT DISTINCT
    g.genus_id,
    NULLIF(rt.species_epithet, '') AS species_epithet,
    NULLIF(rt.infraspecies_name, '') AS infraspecies_name,
    NULLIF(rt.infraspecies_type, '') AS infraspecies_type,
    COALESCE(rt.is_hybrid, FALSE),
    rt.taxon_level

FROM raw_taxa rt
JOIN genera g
    ON g.genus_name = NULLIF(rt.genus, '')

WHERE NULLIF(rt.genus, '') IS NOT NULL;

-- insert common names
INSERT INTO taxon_common_names (taxon_id, common_name)
SELECT DISTINCT
    tx.taxon_id,
    rn.common_name

FROM raw_taxon_common_names rn

JOIN genera g
    ON g.genus_name = NULLIF(rn.genus, '')

JOIN taxa tx
    ON tx.genus_id = g.genus_id
    AND tx.species_epithet IS NOT DISTINCT FROM NULLIF(rn.species_epithet, '')
    AND tx.infraspecies_name IS NOT DISTINCT FROM NULLIF(rn.infraspecies_name, '')
    AND tx.infraspecies_type IS NOT DISTINCT FROM NULLIF(rn.infraspecies_type, '')
    AND tx.is_hybrid = COALESCE(rn.is_hybrid, FALSE)

WHERE rn.common_name IS NOT NULL 
AND rn.common_name <> '';

