json <- fromJSON("2025/species_descriptions/species_descriptions.json")

df <- enframe(json, name = "scientific_name", value = "content") |>
  rowwise() |> 
  mutate(prose_html = content$prose) |>
  select(scientific_name, prose_html)

# connect to db
cfg <- yaml::read_yaml("2025/config/db.yml")$default

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = cfg$host,
  port = cfg$port,
  dbname = cfg$dbname,
  user = cfg$user
)

# import data
taxa_db <- as_tibble(DBI::dbGetQuery(con, 
"
    SELECT
        tx.taxon_id,
        tdn.scientific_name_short as scientific_name
    FROM taxon_display_names tdn
    JOIN taxa tx ON tx.taxon_id = tdn.taxon_id
    WHERE tx.taxon_level = 'species'
"
))

# join json -> df with taxon data from db
mapped_df <- df |>
  full_join(taxa_db, by = "scientific_name")

# check unmatched records
mapped_df |>
  filter(is.na(taxon_id) | is.na(prose_html))

# check duplicates - should give zero rows
duplicates <- mapped_df |>
  count(scientific_name) |>
  filter(n > 1)

# prepare df for inserting into raw db table
to_insert <- mapped_df |> 
  filter(!is.na(prose_html), !is.na(taxon_id)) |> 
  select(taxon_id, prose_html) |> 
  mutate(created_at = as_date("2026-01-14"))

# create staging table with data
DBI::dbWriteTable(con, "raw_descriptions", to_insert, overwrite = TRUE)

# upsert
DBI::dbExecute(con, "
INSERT INTO taxon_descriptions (taxon_id, prose_html, created_at)
SELECT taxon_id, prose_html, created_at
FROM raw_descriptions
ON CONFLICT (taxon_id)
DO UPDATE 
SET 
  prose_html = EXCLUDED.prose_html,
  updated_at = now();
")

