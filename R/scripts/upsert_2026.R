

trees_26 <- df_26 |> 
  select(-id) |> 
  mutate(across(everything(), as.character)) |> 
  pivot_longer(-uuid, values_to = "value_26")

trees_25 <- df_25 |> 
  select(-id) |> 
  mutate(across(everything(), as.character)) |> 
  pivot_longer(-uuid, values_to = "value_25")

trees_25 |> 
  full_join(trees_26, by = c("uuid", "name")) |> 
  dplyr::filter_out(
    value_25 == value_26
    ) 

sci_names <- as_tibble(DBI::dbGetQuery(con, "
SELECT 
taxon_id,
scientific_name_long

FROM taxon_display_names
"
))

# check for no new scientific names -> should give zero rows
trees_25 |> 
  full_join(trees_26, by = c("uuid", "name")) |> 
  filter(
    name == "traeart",
    value_25 != value_26
  ) |> 
  select(-uuid, -value_25) |> 
  distinct() |> 
  left_join(sci_names, by = join_by("value_26" == "scientific_name_long")) |> 
  filter(is.na(taxon_id))