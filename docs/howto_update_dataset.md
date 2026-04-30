## Updating tree dataset

1. **Run cleaning script** `make_clean_dataset.R` in R. Make sure `dataset_year` has been updated. This will also reveal if the new dataset has the same structure as the old.
2. **Build database-ready table** with `make_db_trees_table.R`. Include year or version in the filename, e.g. `trees_2026.csv`.
3. **Import data** into a staging table e.g. `raw_trees_2026`.
4. **Validation step (important)** to catch genuinely new taxa and broken / misspelled taxa.

    If any of the following queries return rows, inspect to distinguish between genuinely new taxa and misspelled taxa. If misspelled, go back to the cleaning pipeline and fix. Then run this step again to ensure there are only genuinely new taxa, no misspellings etc.

    Make note of the new taxa for updating common names manually later!

    ``` SQL
    SELECT DISTINCT r.genus
    FROM raw_trees r -- edit name
    LEFT JOIN genera g ON g.genus_name = r.genus
    WHERE g.genus_id IS NULL;
    ```

```SQL
SELECT DISTINCT
    r.genus,
    r.species_epithet
FROM raw_trees r -- edit name
JOIN genera g ON g.genus_name = r.genus

LEFT JOIN taxa tx
  ON tx.genus_id = g.genus_id
 AND tx.taxon_level = 'species'
 AND tx.species_epithet IS NOT DISTINCT FROM r.species_epithet
 AND tx.is_hybrid IS NOT DISTINCT FROM r.is_hybrid

WHERE r.species_epithet IS NOT NULL
  AND tx.taxon_id IS NULL;
```

```SQL
SELECT DISTINCT
    r.genus,
    r.species_epithet,
    r.infraspecies_type,
    r.infraspecies_name
FROM raw_trees rn -- edit name
JOIN genera g ON g.genus_name = r.genus

LEFT JOIN taxa tx
  ON tx.genus_id = g.genus_id
 AND tx.taxon_level = 'infraspecies'
 AND tx.species_epithet IS NOT DISTINCT FROM r.species_epithet
 AND tx.infraspecies_name IS NOT DISTINCT FROM r.infraspecies_name
 AND tx.infraspecies_type IS NOT DISTINCT FROM r.infraspecies_type
 AND tx.is_hybrid IS NOT DISTINCT FROM r.is_hybrid

WHERE r.infraspecies_name IS NOT NULL
  AND tx.taxon_id IS NULL;
```

5. **Insert genuinely new taxa** into table `taxa` once all typos etc are fixed.

Insert where `taxon_id` doesn't exist yet, first on species level (to insert possible new species):

```SQL
INSERT INTO taxa (
    genus_id,
    species_epithet,
    is_hybrid,
    taxon_level
)
SELECT DISTINCT
    g.genus_id,
    r.species_epithet,
    r.is_hybrid,
    'species' AS taxon_level

FROM raw_trees_2026 r
JOIN genera g ON g.genus_name = r.genus

LEFT JOIN taxa tx
  ON tx.genus_id = g.genus_id
 AND tx.taxon_level = 'species'
 AND tx.species_epithet IS NOT DISTINCT FROM r.species_epithet
 AND tx.is_hybrid IS NOT DISTINCT FROM r.is_hybrid

WHERE
    (r.species_epithet IS NOT NULL OR r.is_hybrid)
    AND tx.taxon_id IS NULL;
```

Then on infraspecies level:

```SQL
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
    r.species_epithet,
    r.infraspecies_name,
    r.infraspecies_type,
    r.is_hybrid,
    'infraspecies' AS taxon_level

FROM raw_trees_2026 r
JOIN genera g ON g.genus_name = r.genus

LEFT JOIN taxa tx
  ON tx.genus_id = g.genus_id
 AND tx.taxon_level = 'infraspecies'
 AND tx.species_epithet IS NOT DISTINCT FROM r.species_epithet
 AND tx.infraspecies_name IS NOT DISTINCT FROM r.infraspecies_name
 AND tx.infraspecies_type IS NOT DISTINCT FROM r.infraspecies_type
 AND tx.is_hybrid IS NOT DISTINCT FROM r.is_hybrid

WHERE
    r.infraspecies_name IS NOT NULL
    AND r.infraspecies_type IS NOT NULL
    AND (r.species_epithet IS NOT NULL OR r.is_hybrid)
    AND tx.taxon_id IS NULL;
```

Update `species_taxon_id`:

```SQL
UPDATE taxa tx
SET species_taxon_id = sp.taxon_id
FROM taxa sp
WHERE sp.taxon_level = 'species'
  AND sp.genus_id = tx.genus_id
  AND sp.is_hybrid IS NOT DISTINCT FROM tx.is_hybrid
  AND sp.species_epithet IS NOT DISTINCT FROM tx.species_epithet;
```

Sanity check (should return 0 rows):

```SQL
SELECT *
FROM taxa tx
WHERE tx.taxon_level = 'infraspecies'
  AND tx.species_taxon_id IS NULL;
```

6. **Insert new common names**. Do this manually into table `taxon_common_names`. Insert new common names at genus, species and infraspecies levels, for those levels that are relevant.  

Example:

```SQL
insert into taxon_common_names (taxon_id, common_name)
values
(671, 'Shantung-løn'),
(670, 'Skørpil')
```

7. **Refresh materialized views** that depends on the updated tables.

Example:

```SQL
REFRESH MATERIALIZED VIEW taxon_primary_common_names;
REFRESH MATERIALIZED VIEW taxon_display_names;
REFRESH MATERIALIZED VIEW resolved_icons;
```

8. **Insert tree data** from staging table to table.

9. **Update common name changelog**. Run script `export_common_name_changelog.R`.