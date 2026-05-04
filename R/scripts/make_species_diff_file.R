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
    
    str_detect(variable, "percentageOf") ~ 
      (rel_diff(old, new) <= 0.1) | (old < 1 & new < 1),
    
    str_detect(variable, "genusRank") ~ 
      (old > 1) == (new > 1),
    
    TRUE ~ FALSE
  )
}

# isolate species with significant changes in the numeric variables
diff_num <- df |> 
  select(all_of(key), where(is.numeric)) |> 
  pivot_longer(-all_of(key), names_to = c("variable", "year"), names_sep = "_") |> 
  pivot_wider(names_from = year, values_from = value) |> 
  filter_out(is_numeric_similar(variable, Y2025, Y2026)) |> 
  rename(
    value_from = Y2025,
    value_to = Y2026
  )

# isolate species with changes in any of the list variables
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
    changed = map2(Y2025, Y2026, ~ {
      full_join(.x, .y, by = "name", suffix = c("_Y2025", "_Y2026")) |> 
      pivot_longer(-name, names_to = c("variable", "year"), names_sep = "_") |> 
      pivot_wider(names_from = year, values_from = value) |> 
      filter_out(is_districts_similar(variable, Y2025, Y2026))
    })
  ) |> 
  filter(map_lgl(changed, ~ nrow(.x) > 0)) |> 
  rename(
    value_from = Y2025,
    value_to = Y2026
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
    changed = map2(Y2025, Y2026, ~ {
      full_join(.x, .y, by = c("type","name"), suffix = c("_Y2025", "_Y2026")) |> 
        select(!starts_with("danish")) |> 
        pivot_longer(-c(type, name), names_to = c("variable", "year"), names_sep = "_") |> 
        pivot_wider(names_from = year, values_from = value) |> 
        filter_out(is_infraspecies_similar(variable, Y2025, Y2026))
    })
  ) |> 
  filter(map_lgl(changed, ~ nrow(.x) > 0)) |> 
  rename(
    value_from = Y2025,
    value_to = Y2026
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
    changed = map2(Y2025, Y2026, ~ {
      
      x <- tibble(
        name = names(.x),
        value = as.integer(.x),
        type = "decade"
      )
      
      y <- tibble(
        name = names(.y),
        value = as.integer(.y),
        type = "decade"
      )
      
      full_join(x, y, by = c("type", "name"), suffix = c("_Y2025", "_Y2026")) |> 
        pivot_longer(-c(type, name), names_to = c("variable", "year"), names_sep = "_") |>  
        select(-type, -variable) |> 
        pivot_wider(names_from = year, values_from = value) |> 
        filter_out(is_decades_similar(variable, Y2025, Y2026))
    })
  ) |>
  filter(map_lgl(changed, ~ nrow(.x) > 0)) |> 
  rename(
    value_from = Y2025,
    value_to = Y2026
  )


  group_by(speciesName) %>%
  summarise(variables = list(unique(variable)),.groups = "drop") %>%
  deframe() |> 
  # select(-species_taxon_id) %>%
  # pmap(function(...) list(...)) %>%   # each row → named list
  # set_names(final$speciesName) |> 
write_json("2025/species_descriptions/species_data_diffs.json", pretty = TRUE, auto_unbox = TRUE)
