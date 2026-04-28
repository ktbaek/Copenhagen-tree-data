# Making map-ready version of the dataset ---------------------------------
# Make sure you're using clean version!
suppressWarnings({
  
# read dataset from db
cfg <- yaml::read_yaml("2025/config/db.yml")$default

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = cfg$host,
  port = cfg$port,
  dbname = cfg$dbname,
  user = cfg$user
)

map_view <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM trees_for_map"))

# calculate color scheme and add colors
set_color_df <- map_view
source('2025/R/scripts/set_color_scale.R', local = TRUE)
map_df <- map_view |> 
  left_join(species_colors_df, by = "scientific_name", relationship = "many-to-one") |> 
  mutate(
    nofill = is.na(scientific_name),
    fillcolor = if_else(nofill, NA_character_, fillcolor)
  )

# calculate radii
this_year <- as.integer(format(Sys.Date(), "%Y"))

map_df <- map_df |>
  mutate(radius = calc_radius(year = planting_year, current_year = this_year, r0 = 2.2, a0 = 25, k = 0.7))

cli::cli_alert_success("Marker radii calculated")

# add rarity classes 
class <- function(df, low, high) {
  x <- df |> 
    group_by(scientific_name) |> 
    mutate(.n = n()) |> 
    filter(.n >= low, .n <= high, !str_detect(scientific_name, "sp.")) |> 
    ungroup() |> 
    pull(uuid)
  
  y <- df |> 
    group_by(genus_name) |> 
    mutate(.n = n()) |> 
    filter(.n >= low, .n <= high, str_detect(scientific_name, "sp.")) |> 
    ungroup() |> 
    pull(uuid)
  
  c(x, y)
}

class_1 <- class(map_df, 1, 1)
class_2 <- class(map_df, 2, 5)
class_3 <- class(map_df, 6, 10)

map_df <- map_df |> 
  mutate(rarity = case_when(
    uuid %in% class_3 ~ as.integer(3),
    uuid %in% class_2 ~ as.integer(2),
    uuid %in% class_1 ~ as.integer(1),
    TRUE ~ NA_integer_ 
    ))

cli::cli_alert_success("Rarity classes calculated")

# experimental: add flowering class for japanske kirsebær-arter
# map_df <- map_df |> mutate(flower = art %in% c("Prunus hybr. yedoensis", "Prunus sargentii", "Prunus serrulata", "Prunus subhirtella"))
# 
# cli::cli_alert_success("Flowering column added")

# remove extra whitespace just in case
map_df <- map_df |> mutate(across(where(is.character), str_squish))

# remove unrequired columns
map_df <- map_df |> select(-family_name, -order_name)

cli::cli_alert_success("Columns selected")

# make loading order on the map: trees with unknown species loads first, then by uuid (i.e more or less random) so no one species dominate the map, and then by planting year so large markers are loaded first
map_df <- arrange(map_df, !nofill, planting_year)

# save file
write_csv(map_df, "2025/output/datasets/trees.csv")
write_rds(map_df, "2025/output/datasets/trees.rds")
trees_sf <- sf::st_as_sf(map_df, coords = c("lon", "lat"), crs = 4326)
st_write(trees_sf, "2025/output/datasets/trees.geojson", driver = "GeoJSON", delete_dsn = TRUE)
st_write(trees_sf, "../website/src/assets/dataset/trees.geojson", driver = "GeoJSON", delete_dsn = TRUE)
})