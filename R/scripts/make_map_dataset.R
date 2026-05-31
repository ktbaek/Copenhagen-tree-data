# Making map-ready version of the dataset ---------------------------------

# source functions
r_files <- list.files("2025/R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))
  
map_df <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM trees_for_map"))

# calculate radii
this_year <- as.integer(format(Sys.Date(), "%Y"))

radius_df <- map_df |> 
  select(planting_year) |> 
  filter(!is.na(planting_year)) |> 
  distinct() |> 
  arrange(planting_year) |> 
  mutate(radius = round(calc_radius(year = planting_year, current_year = this_year, r0 = 2.2, a0 = 25, k = 0.7), 2)) 

radius_lookup <- as.list(
  setNames(
  radius_df$radius,
  radius_df$planting_year
))

radius_lookup |> 
  write_json(
    "../website/src/assets/dataset/radius_lookup.json",
    pretty = TRUE,
    auto_unbox = TRUE
  )

# add truncated uuid as id
trees_df <- map_df |> mutate(id = str_sub(uuid, start = -8, end = -1))
if (length(unique(map_df$uuid)) != length(unique(trees_df$id))) cli::cli_alert_warning("IDs not unique")
trees_df$uuid <- NULL

trees_df <- trees_df |> 
  arrange(desc(is.na(taxon_id)), planting_year, id) |> 
  rename(pyr = planting_year, tid = taxon_id) |> 
  mutate(lon = round(lon, 6), lat = round(lat, 6))

# save file
trees_sf <- sf::st_as_sf(trees_df, coords = c("lon", "lat"), crs = 4326)
st_write(trees_sf, "../website/src/assets/dataset/trees.geojson", driver = "GeoJSON", delete_dsn = TRUE)


source("2025/R/scripts/calculate_counts.R")

# prepare for PMTiles
taxon_df <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM taxon_lookup_for_map ORDER BY taxon_id")) 

trees_for_tiles <- trees_df |>
  left_join(taxon_df, by = join_by("tid" == "taxon_id")) |>
  left_join(radius_df, by = join_by("pyr" == "planting_year")) |> 
  select(-c(scientific_name, display_name, cultivar, common_name, genus_name, genus_common_name, species_common_name, icon_id)) |> 
  mutate(
    fillcolor = coalesce(fillcolor, "#56C667"),
    radius = coalesce(radius, 5.5),
    isOld = this_year - 100 >= pyr,
    isYoung = this_year - 5 <= pyr
  ) |> 
  mutate(draw_order = runif(n()))


trees_for_tiles_sf <- sf::st_as_sf(trees_for_tiles, coords = c("lon", "lat"), crs = 4326)
st_write(trees_for_tiles_sf, "../website/src/assets/dataset/trees_resolved.geojson", driver = "GeoJSON", delete_dsn = TRUE)

