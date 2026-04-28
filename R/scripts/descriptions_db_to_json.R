# connect to db
cfg <- yaml::read_yaml("2025/config/db.yml")$default

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = cfg$host,
  port = cfg$port,
  dbname = cfg$dbname,
  user = cfg$user
)


df <- DBI::dbGetQuery(con, "
    SELECT
        tdn.scientific_name_short,
        td.prose_html
    FROM taxon_descriptions td
    JOIN taxon_display_names tdn
      ON tdn.taxon_id = td.taxon_id
")

json <- setNames(
  lapply(df$prose_html, function(x) list(prose = x)),
  df$scientific_name_short
)

jsonlite::write_json(json, "../website/src/assets/dataset/species_descriptions.json", pretty = TRUE, auto_unbox = TRUE)