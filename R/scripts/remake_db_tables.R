# source functions
r_files <- list.files("2025/R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# load rules
dir <- "2025/rules"
paths <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
rules <- set_names(paths, tools::file_path_sans_ext(basename(paths))) |>
  map(read_rules)

taxon_key = c("genus", "species", "is_hybrid", "subsp", "var", "form", "selection", "fk", "cultivar")

# read dataset
clean_df <- read_csv('2025/output/datasets/kk_trees_clean.csv')

parsed_df <- clean_df |> 
  mutate(
    geom = sf::st_as_sfc(wkb_geometry, crs = 4326),
    lon = sf::st_coordinates(geom)[,1],
    lat = sf::st_coordinates(geom)[,2]
    )  |> 
  select(-geom)
  
# harmonize cleaned dataset
split_taxon_df <- parsed_df |> 
  mutate(
    sex = case_when(
      str_detect(traeart, "\\s*\\(han\\)") ~ "male",
      str_detect(traeart, "\\s*\\(hun\\)") ~ "female",
      TRUE ~ NA_character_
    )) |> 
  split_taxon_columns() |> 
  mutate(
    is_hybrid = case_when(
      !is.na(genus) & is.na(species) & !is_hybrid ~ NA,
      TRUE ~ is_hybrid
    )
  )

harmonized_df <- split_taxon_df |> 
  rename(
    planting_year = planteaar,
    district_name = bydelsnavn,
    place_name = stednavn,
    space_type =byrumstype,
    protected = fredet_beskyttet_trae,
    special = saerligt_trae,
    iconic = ikonisk_trae,
    fruit = spiselige_frugter,
    is_duplicate_location = dup_loc
  ) 

# generate trees table
trees_df <- harmonized_df |>
  mutate(updated_at = today(),
    protected = as.character(ifelse("Ikke registreret", NA_character_, protected)),
    special = special == "ja",
    iconic = !is.na(iconic) & iconic > 0,
    fruit = fruit == "ja"
  ) |> 
  select(
    updated_at,
    uuid, 
    genus, 
    species, 
    is_hybrid, 
    subsp,
    var,
    form, 
    selection, 
    fk,
    cultivar, 
    planting_year, 
    place_name,
    space_type,
    district_name,
    protected,
    special,
    iconic,
    fruit,
    lon,
    lat,
    is_duplicate_location, 
    dansk_navn, 
    slaegtsnavn
    ) 
  
trees_df |> write_csv('2025/output/tables/trees_2026.csv', na = "")

# remake taxa table
taxa_table <- as_tibble(DBI::dbGetQuery(con, 
"
SELECT 
tx.*,
g.genus_name
FROM taxa tx
JOIN genera g on tx.genus_id = g.genus_id
"))

taxa_df <- taxa_table |> 
  select(
    taxon_id,
    genus = genus_name,
    species = species_epithet,
    is_hybrid,
    taxon_level,
    show_cultivar_in_display,
    infraspecies_type,
    infraspecies_name
  ) 

taxa_rearranged <- taxa_df |> 
  pivot_wider(names_from = infraspecies_type, values_from = infraspecies_name) |> 
  left_join(rules$taxonomy, by = "genus") |> 
  select(
    taxon_id,
    family,
    genus,
    species,
    is_hybrid,
    subsp = ssp.,
    var = var.,
    form = f.,
    selection = sel.,
    fk,
    cultivar,
    taxon_level,
    show_cultivar_in_display
    ) |> 
  mutate(
    taxon_level = case_when(
      !is.na(selection) ~ "sel.",
      !is.na(fk) ~ "fk",
      !is.na(cultivar) ~ "cultivar",
      !is.na(form) ~ "f.",
      !is.na(var) ~ "var.",
      !is.na(subsp) ~ "subsp.",
      TRUE ~ taxon_level
    )
  ) 

taxa_rearranged |> 
  select(-taxon_id) |> 
  write_csv('2025/output/tables/taxa.csv', na = "")

common_names <- as_tibble(DBI::dbGetQuery(con, 
"
SELECT 
c.*
FROM taxon_common_names c
"))

common_names |> 
  left_join(taxa_rearranged, by = "taxon_id") |> 
  select(all_of(taxon_key), common_name)


# generate districts table
districts_df <- harmonized_df |> 
  select(district_name) |> 
  distinct() |> 
  filter(!is.na(district_name)) |> 
  arrange(district_name)

districts_df |> write_csv('2025/output/tables/districts.csv', na = "")

# remake icons table
icons_df <- read_csv('2025/output/tables/old_icons.csv')

icons_df |> 
  rename(species = species_epithet) |> 
  pivot_wider(names_from = infraspecies_type, values_from = infraspecies_name) |> 
  select(-(`NA`)) |>
  mutate(
    subsp = NA_character_,
    var = NA_character_,
    form = NA_character_,
    selection = NA_character_,
    fk = NA_character_
  ) |> 
  select(genus, species, is_hybrid, subsp, var, form, selection, fk, cultivar, icon_id, allow_fallback) |> 
  write_csv('2025/output/tables/icons.csv', na = "")

# make fruit table
trees_df |> 
  select(all_of(taxon_key), fruit) |> 
  filter(fruit) |> 
  distinct()






  