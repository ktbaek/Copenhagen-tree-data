# source functions
r_files <- list.files("2025/R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# load rules
dir <- "2025/rules"
paths <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
rules <- set_names(paths, tools::file_path_sans_ext(basename(paths))) |>
  map(read_rules)

# read dataset
clean_df <- read_rds('2025/output/datasets/kk_trees_clean.rds')

# read icon lists
icons_sp <- read_csv('app/icon_list_sp.csv')
icons_var <- read_csv('app/icon_list_var.csv')

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
  select(uuid, genus, species_epithet, is_hybrid, sex, infraspecies_type, infraspecies_name, planting_year, district_name, protected, special, iconic, fruit, lon, lat, is_duplicate_location, raw_dansk_navn, raw_slaegtsnavn)

# generate genera table
genera_df <- rules$taxonomy |> 
  select(genus, family) |> 
  rename(
    genus_name = genus,
    family_name = family
  ) 

# generate family table
family_df <- rules$taxonomy |> 
  select(family, order) |> 
  rename(
    family_name = family,
    order_name = order
  ) |> 
  distinct() |> 
  arrange(family_name)

# generate order table
order_df <- rules$taxonomy |> 
  select(order) |> 
  rename(
    order_name = order
  ) |> 
  distinct() |> 
  arrange(order_name)

# generate dataframes for binding later
genera_insert <- genera_df |> 
  rename(genus = genus_name) |> 
  mutate(
    species_epithet = NA_character_,
    is_hybrid = FALSE,
    infraspecies_type = NA_character_,
    infraspecies_name = NA_character_,
    taxon_level = "genus"
  ) |> 
  select(-family_name)

species_insert <- trees_df |> 
  select(genus, species_epithet, is_hybrid) |> 
  distinct() |> 
  filter(!(!is_hybrid & is.na(species_epithet))) |> # not genus
  arrange(genus, species_epithet) |>
  mutate(
    infraspecies_type = NA_character_,
    infraspecies_name = NA_character_,
    taxon_level = "species"
  ) 
  

# generate taxa table
taxon_key_cols <- c("genus", "species_epithet", "is_hybrid", "infraspecies_name", "infraspecies_type")

taxa_df <- clean_harmonized_df |> 
  filter(!is.na(species)) |> 
  select(species, variety, cultivar) |> 
  arrange(species, variety, cultivar) |> 
  distinct() |> 
  harmonize_infraspecies_cols() |>
  mutate(
    is_hybrid = str_detect(species, " hybr\\."),
    species_clean = species  |> 
      str_replace_all("hybr\\.", "")  |> 
      str_squish(),
    genus = word(species_clean, 1),
    species_epithet = word(species_clean, 2),
    species_epithet = if_else(str_detect(species_clean, " sp\\.?$"), NA_character_, species_epithet),
    taxon_level = case_when(
      !is.na(infraspecies_name) ~ "infraspecies",
      is.na(species_epithet) ~ if_else(is_hybrid, "species", "genus"),
      TRUE ~ "species"
    ),
  ) |> 
  filter(taxon_level %in% c("infraspecies")) |> 
  select(genus, species_epithet, is_hybrid, infraspecies_type, infraspecies_name, taxon_level) |> 
  bind_rows(genera_insert, species_insert) |> 
  distinct() |> 
  arrange(genus, species_epithet, infraspecies_name) 

# generate taxon common name table
genus_common_names <- rules$genus |> 
  mutate(
    species_epithet = NA_character_,
    is_hybrid = FALSE,
    infraspecies_type = NA_character_,
    infraspecies_name = NA_character_
  ) |> 
  rename(
    genus = genus_name,
    common_name = genus_common_name
    ) |> 
  select(all_of(taxon_key_cols), common_name)
  
species_common_names <- rules$species |> 
  mutate(
    is_hybrid = str_detect(species, " hybr\\."),
    species_clean = species  |> 
      str_replace_all("hybr\\.", "")  |> 
      str_squish(),
    genus = word(species_clean, 1),
    species_epithet = word(species_clean, 2),
    infraspecies_type = NA_character_,
    infraspecies_name = NA_character_
    ) |> 
  rename(common_name = species_common_name) |> 
  select(all_of(taxon_key_cols), common_name)

infraspecies_common_names <- rules$infraspecies |> 
  harmonize_infraspecies_cols() |> 
  mutate(
    is_hybrid = str_detect(species, " hybr\\."),
    species_clean = species  |> 
      str_replace_all("hybr\\.", "")  |> 
      str_squish(),
    genus = word(species_clean, 1),
    species_epithet = word(species_clean, 2)
  ) |> 
  rename(common_name = infraspecies_common_name) |> 
  select(all_of(taxon_key_cols), common_name)

taxon_common_names_df <- 
  bind_rows(genus_common_names, species_common_names, infraspecies_common_names) |> 
  filter(!is.na(common_name))
  
# generate districts table
districts_df <- trees_df |> 
  select(district_name) |> 
  distinct() |> 
  filter(!is.na(district_name)) |> 
  arrange(district_name)

# generate icon table
icons_sp_df <- icons_sp |> 
  rename(scientific_name = Species) |> 
  mutate(
    genus = word(scientific_name, 1),
    is_hybrid = str_detect(scientific_name, " hybr\\."),
    scientific_name = str_remove(scientific_name, "\\s*\\((han|hun)\\)"),
    species_epithet = word(scientific_name, -1)
    ) |> 
  select(icon_id, genus, species_epithet, is_hybrid)

icons_var_df <- icons_var |> 
  rename(
    scientific_name = Species,
    infraspecies_name = Variant) |>
  mutate(
    genus = word(scientific_name, 1),
    is_hybrid = str_detect(scientific_name, " hybr\\."),
    species_epithet = NA_character_,
    infraspecies_type = "cultivar"
  ) |> 
  select(icon_id, genus, species_epithet, is_hybrid, infraspecies_type, infraspecies_name)

# handle icon exceptions
icons_df <- icons_sp_df |> 
  full_join(icons_var_df, by = c("genus", "species_epithet", "is_hybrid")) |> 
  mutate(icon_id = coalesce(icon_id.x, icon_id.y), .keep = "unused") |>
  mutate(allow_fallback = TRUE) |> 
  add_row(
    genus = 'Fagus', 
    species_epithet = 'sylvatica', is_hybrid = FALSE, 
    infraspecies_type = "cultivar", infraspecies_name = "Asplenifolia", 
    allow_fallback = FALSE) |> 
  add_row(
    genus = 'Fraxinus', 
    species_epithet = 'excelsior', is_hybrid = FALSE, 
    infraspecies_type = "cultivar", infraspecies_name = "Diversifolia", 
    allow_fallback = FALSE) |>
  mutate(allow_fallback = if_else(genus == 'Ulmus' & is_hybrid & !is.na(infraspecies_type), FALSE, allow_fallback)) |> 
  distinct()

# export
order_df |> write_csv('2025/output/tables/orders.csv', na = "")
family_df |> write_csv('2025/output/tables/families.csv', na = "")
genera_df |> write_csv('2025/output/tables/genera.csv', na = "")
districts_df |> write_csv('2025/output/tables/districts.csv', na = "")
taxa_df |> write_csv('2025/output/tables/taxa.csv', na = "")
taxon_common_names_df  |> write_csv('2025/output/tables/taxon_common_names.csv', na = "")
trees_df |> write_csv('2025/output/tables/trees.csv', na = "")
icons_df |> write_csv('2025/output/tables/icons.csv', na = "")
