parse_geometry_wkt <- function(df, col = "geometry") {
  if (!col %in% names(df)) return(df)
  
  x <- df[[col]]
  x <- gsub("[()]", "", x)
  # Expect tokens: "POINT lon lat" → drop first token
  parts <- tidyr::separate_wider_delim(tibble(val = x), cols = val, delim = " ", names = c("token", "lon", "lat"), too_few = "align_start")
  df$lon <- suppressWarnings(as.double(parts$lon))
  df$lat <- suppressWarnings(as.double(parts$lat))
  
  df
  }