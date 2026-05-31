
df <- DBI::dbGetQuery(con, "
    SELECT
        tx.species_taxon_id,
        td.prose_html
    FROM taxon_descriptions td
    JOIN taxa tx
      ON td.taxon_id = tx.taxon_id
") |> arrange(species_taxon_id)

json <- setNames(
  lapply(df$prose_html, function(x) list(prose = x)),
  df$species_taxon_id
)

jsonlite::write_json(
  json, "../website/src/assets/dataset/species_descriptions.json",
  pretty = TRUE,
  auto_unbox = TRUE
  )