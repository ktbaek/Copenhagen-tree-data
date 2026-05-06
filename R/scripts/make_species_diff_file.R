

key <- c("species_taxon_id", "speciesName", "genusName")

df_25 <- read_rds("2025/species_descriptions/species_data_2025.rds") |> select(-speciesDanishName, -genusDanishName)
df_26 <- read_rds("2025/species_descriptions/species_data_2026.rds") |> select(-speciesDanishName, -genusDanishName)

df <- df_25 %>%
  full_join(df_26, by = key, suffix = c("_Y2025", "_Y2026"))

rel_diff <- function(a, b) {
  ifelse(a == 0, abs(b) > 0, abs(a - b) / abs(a))
}

is_numeric_similar <- function(variable, old, new) {
  case_when(
    
    old == new ~ TRUE,
    is.na(old) & is.na(new) ~ TRUE,
    
    str_detect(variable, "newestYear") ~ 
      old > 2022 & new > 2022,
    
    str_detect(variable, "GenusUnknown") ~ 
      (old >= 30) == (new >= 30),
    
    str_detect(variable, "^percentageOfGenus$") ~ 
      round(abs(old - new), 0) < 1 | (old < 1 & new < 1),
    
    str_detect(variable, "percentageOfTotal") ~ 
      (old < 1 & new < 1),
    
    str_detect(variable, "totalRank") ~ 
      old > 50 & new > 50,
    
    str_detect(variable, "genusRank") ~ 
      old > 10 & new > 10,
    
    TRUE ~ FALSE
  )
}

# isolate species with significant changes in the numeric variables = tier_1 changes
diff_num <- df |> 
  select(all_of(key), where(is.numeric)) |> 
  pivot_longer(-all_of(key), names_to = c("variable", "year"), names_sep = "_") |> 
  pivot_wider(names_from = year, values_from = value) |> 
  filter_out(is_numeric_similar(variable, Y2025, Y2026)) |> 
  rename(
    value_from = Y2025,
    value_to = Y2026
  )


# isolate species with changes in any of the list variables = tier_2 changes
diff_list <- df |> select(all_of(key), where(is.list)) |> 
  pivot_longer(-all_of(key), names_to = c("variable", "year"), names_sep = "_") |> 
  pivot_wider(names_from = year, values_from = value) |> 
  filter(map2_lgl(Y2025, Y2026, ~ !isTRUE(all.equal(.x, .y)))) 

# isolate species with significant changes in districts
is_districts_similar <- function(variable, old, new) {
  case_when(
    old == new ~ TRUE,
    
    str_detect(variable, "count") ~ 
      rel_diff(old, new) <= 0.2,
    
    str_detect(variable, "enrichment") ~ 
      rel_diff(old, new) <= 0.2 & (old > 2) == (new > 2),
    
    str_detect(variable, "percentageOfTrees") ~ 
      old < 5 & new < 5,
    
    TRUE ~ FALSE
  )
}

diff_districts <- diff_list |> 
  filter(variable == "districtStats", !(map_lgl(Y2025, is.null) | map_lgl(Y2026, is.null))) |> 
  mutate(
    meaningful_changes = map2(Y2025, Y2026, ~ {
      full_join(.x, .y, by = "name", suffix = c("_Y2025", "_Y2026")) |> 
      pivot_longer(-name, names_to = c("variable", "year"), names_sep = "_") |> 
      pivot_wider(names_from = year, values_from = value) |> 
      filter_out(is_districts_similar(variable, Y2025, Y2026)) |> 
      rename(
        value_from = Y2025,
        value_to = Y2026
      ) 
    })
  ) |> 
  filter(map_lgl(meaningful_changes, ~ nrow(.x) > 0)) |> 
  rename(
    data_from = Y2025,
    data_to = Y2026
  )

# isolate species with significant changes in infraspecies
is_infraspecies_similar <- function(variable, old, new) {
  case_when(
    old == new ~ TRUE,
    
    str_detect(variable, "count") ~ TRUE, 
    
    str_detect(variable, "percentageOfSpecies") ~ 
      rel_diff(old, new) <= 0.5 | (old < 10 & new < 10),
    
    TRUE ~ FALSE
  )
}

diff_infraspecies <- diff_list |> 
  filter(variable == "infraspecies", !(map_lgl(Y2025, is.null) | map_lgl(Y2026, is.null))) |>
  mutate(
    meaningful_changes = map2(Y2025, Y2026, ~ {
      full_join(.x, .y, by = c("type","name"), suffix = c("_Y2025", "_Y2026")) |> 
        select(!starts_with("danish")) |> 
        pivot_longer(-c(type, name), names_to = c("variable", "year"), names_sep = "_") |> 
        pivot_wider(names_from = year, values_from = value) |> 
        filter_out(is_infraspecies_similar(variable, Y2025, Y2026)) |> 
        rename(
          value_from = Y2025,
          value_to = Y2026
        ) 
    })
  ) |> 
  filter(map_lgl(meaningful_changes, ~ nrow(.x) > 0)) |> 
  rename(
    data_from = Y2025,
    data_to = Y2026
  )

# isolate species with significant changes in decades
is_decades_similar <- function(variable, old, new) {
  case_when(
    rel_diff(old, new) <= 0.5 ~ TRUE,
    TRUE ~ FALSE
  )
}

diff_decades <- diff_list |> 
  filter(variable == "decade", !(map_lgl(Y2025, is.null) | map_lgl(Y2026, is.null))) |> 
  mutate(
    across(starts_with("Y20"),
           ~ map(.x, ~ pivot_longer(as_tibble(.x), cols = everything(), names_to = "decade", values_to = "n"))
    ),
    meaningful_changes = map2(Y2025, Y2026, ~ {
      full_join(.x, .y, by = "decade", suffix = c("_Y2025", "_Y2026")) |> 
        pivot_longer(-decade, names_to = c("variable", "year"), names_sep = "_") |> 
        pivot_wider(names_from = year, values_from = value) |> 
        filter_out(is_decades_similar(variable, Y2025, Y2026)) |> 
        rename(
          value_from = Y2025,
          value_to = Y2026
        ) 
    })
  ) |>
  filter(map_lgl(meaningful_changes, ~ nrow(.x) > 0)) |> 
  rename(
    data_from = Y2025,
    data_to = Y2026
  )

new_species <- df_26 %>%
  anti_join(df_25, by = "species_taxon_id") %>%
  mutate(update_tier = "new")

tier1 <- diff_num  |> 
  arrange(speciesName) |> 
  mutate(update_tier = "tier1") |> 
  filter(!species_taxon_id %in% new_species$species_taxon_id) 

tier2 <- bind_rows(diff_districts, diff_decades, diff_infraspecies) |> 
  arrange(speciesName) |> 
  mutate(update_tier = "tier2") |> 
  filter(!species_taxon_id %in% new_species$species_taxon_id) 

all_species <- union(
  unique(tier1$speciesName),
  unique(tier2$speciesName)
)

tier1_only <- setdiff(
  unique(tier1$speciesName),
  unique(tier2$speciesName)
)

tier2_only <- setdiff(
    unique(tier2$speciesName),
    unique(tier1$speciesName)
  )

both_tiers <- intersect(
    unique(tier1$speciesName),
    unique(tier2$speciesName)
  )

cli::cli_alert_success(paste0("Total species changed: ", length(all_species)))
cli::cli_alert_success(paste0("Only tier_1: ", length(tier1_only)))
cli::cli_alert_success(paste0("Only tier_2: ", length(tier2_only)))
cli::cli_alert_success(paste0("Both tiers: ", length(both_tiers)))
cli::cli_alert_success(paste0("Total new species: ", length(unique(new_species$species_taxon_id))))

tier1_json_list <- tier1 |>
  group_by(speciesName) |>
  summarise(
    species_taxon_id = first(species_taxon_id),
    update_tier = first(update_tier),
    tier1_changes = list(transmute(pick(everything()), variable, value_from, value_to)),
    .groups = "drop"
  ) |>
  mutate(
    data = pmap(
      list(species_taxon_id, update_tier, tier1_changes),
      \(id, tier, changes) list(
        species_taxon_id = id,
        update_tier = tier,
        tier1_changes = changes
      )
    )
  ) |>
  select(speciesName, data) |>
  deframe() 
  
tier2_json_list <- tier2 |>
  group_by(speciesName) |>
  summarise(
    species_taxon_id = first(species_taxon_id),
    update_tier      = first(update_tier),
    # Each variable becomes a named element with data_from/data_to/changed
    # Round-trip through JSON to strip tibble classes from nested data
    tier2_changes = list(
      setNames(
        pmap(
          list(data_from, data_to, meaningful_changes),
          \(from, to, ch) list(
            data_from = fromJSON(toJSON(from, auto_unbox = TRUE)),
            data_to   = fromJSON(toJSON(to,   auto_unbox = TRUE)),
            meaningful_changes   = fromJSON(toJSON(ch,   auto_unbox = TRUE))
          )
        ),
        variable
      )
    ),
    .groups = "drop"
  ) |>
  mutate(
    data = pmap(
      list(species_taxon_id, update_tier, tier2_changes),
      \(id, tier, changes) list(
        species_taxon_id = id,
        update_tier      = tier,
        tier2_changes    = changes
      )
    )
  ) |>
  select(speciesName, data) |>
  deframe()
  
# ── Combine ───────────────────────────────────────────────────────────────────
# tier1 species may also have tier2 changes — merge those in

combined <- tier1_json_list

# Add tier1_changes to any species that appear in both
for (sp in both_tiers) {
    combined[[sp]]$update_tier <- tier2_json_list[[sp]]$update_tier
    combined[[sp]]$tier2_changes <- tier2_json_list[[sp]]$tier2_changes
}

# Add tier2 only species (not in tier1)
for (sp in tier2_only) {
  combined[[sp]] <- tier2_json_list[[sp]]
}

write(
  toJSON(combined, pretty = TRUE, auto_unbox = TRUE, na = "null"),
  "2025/species_descriptions/diff_changes.json"
)

