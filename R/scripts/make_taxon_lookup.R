# source functions
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# taxon level lookup
taxon_df <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM taxon_lookup_for_map ORDER BY taxon_id")) |> 
mutate(treetype = ifelse(treetype == 1, NA_integer_, treetype))

rows_to_named_list <- function(df) {
  row <- as.list(df[1, setdiff(names(df), "taxon_id")])
  # Convert any NA to NULL so jsonlite writes null not "NA"
  lapply(row, \(x) if (length(x) == 1 && is.na(x)) NULL else x)
}

split(taxon_df, taxon_df$taxon_id) |> 
  lapply(rows_to_named_list) |> 
  write_json(
    "../website/src/assets/dataset/taxon_lookup.json",
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )

# species level lookup
taxon_df |> 
  filter(species_taxon_id == taxon_id) |> 
  select(species_taxon_id, scientific_name, species_common_name) |> 
  rename(
    id = species_taxon_id,
    common_name = species_common_name
  ) |> 
  write_json(
    "../website/src/assets/dataset/species_lookup.json",
    pretty = TRUE,
    auto_unbox = TRUE
  )
