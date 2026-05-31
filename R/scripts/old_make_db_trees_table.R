# source functions
r_files <- list.files("2025/R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# read dataset
clean_df <- read_rds('2025/output/datasets/kk_trees_clean.rds')

# harmonize cleaned dataset
clean_harmonized_df <- clean_df |> 
  split_taxon_columns() |> 
  rename(
    raw_dansk_navn = dansk_navn,
    raw_slaegtsnavn = slaegtsnavn,
    planting_year = planteaar,
    district_name = bydelsnavn,
    protected = fredet_beskyttet_trae,
    special = saerligt_trae,
    iconic = ikonisk_trae,
    fruit = spiselige_frugter
  ) |> 
  select(-traeart)

# generate trees table
trees_df <- clean_harmonized_df |>
  select(uuid, species, genus, variety, cultivar, planting_year, district_name, protected, special, iconic, fruit, wkb_geometry, dup_loc, raw_dansk_navn, raw_slaegtsnavn) |> 
  mutate(
    updated_at = today(),
    coords = str_match(wkb_geometry, "POINT \\(([^ ]+) ([^ ]+)\\)"),
    lon = as.numeric(coords[,2]),
    lat = as.numeric(coords[,3])
  )  |> 
  select(-coords, -wkb_geometry) |> 
  harmonize_infraspecies_cols() |> 
  mutate(
    is_hybrid = str_detect(species, " hybr\\."),
    sex = case_when(
      str_detect(species, "\\s*\\(han\\)") ~ "male",
      str_detect(species, "\\s*\\(hun\\)") ~ "female",
      TRUE ~ NA_character_
    ),
    species_clean = species |> 
      str_replace_all("hybr\\.", "")  |> 
      str_remove("\\s*\\((han|hun)\\)") |> 
      str_squish(),
    genus = word(species_clean, 1),
    species_epithet = word(species_clean, 2),
    species_epithet = if_else(str_detect(species_clean, " sp\\.?$"), NA_character_, species_epithet),
  ) |> 
  mutate(
    protected = as.character(ifelse("Ikke registreret", NA_character_, protected)),
    special = special == "ja",
    iconic = !is.na(iconic) & iconic > 0,
    fruit = fruit == "ja"
  ) |> 
  rename(is_duplicate_location = dup_loc) |> 
  select(updated_at, uuid, genus, species_epithet, is_hybrid, sex, infraspecies_type, infraspecies_name, planting_year, district_name, protected, special, iconic, fruit, lon, lat, is_duplicate_location, raw_dansk_navn, raw_slaegtsnavn)

trees_df |> write_csv('2025/output/tables/trees_2026.csv', na = "")