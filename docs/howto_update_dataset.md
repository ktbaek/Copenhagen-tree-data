# Updating tree dataset

1. Run cleaning script `make_clean_dataset.R`in R. Make sure `dataset_year` has been updated. This will also reveal if the new dataset has the same structure as the old.
2. Build database-ready table with `make_db_trees_table.R`. Include year or version in the filename, e.g. `trees_2026.csv`.
3. Import data into staging table e.g. `raw_trees_2026`.
4. Validation step (important) to catch genuinely new taxa and broken / misspelled taxa.

    If any of the following queries return rows, inspect to distinguish between genuinely new taxa and misspelled taxa. If misspelled, go back to the cleaning pipeline and fix. Then run this step again.

    ``` SQL
    SELECT DISTINCT r.genus
    FROM raw_trees_2026 r
    LEFT JOIN genera g ON g.genus_name = r.genus
    WHERE g.genus_id IS NULL;
    ```

```SQL
SELECT DISTINCT
    r.genus,
    r.species_epithet
FROM raw_trees_2026 r
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
FROM raw_trees_2026 r
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

5. When typos etc are fixed, insert genuinely new taxa into table `taxa`.


