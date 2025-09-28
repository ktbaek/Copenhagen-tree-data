flag_dupl_locations <- function(df, report = NULL) {
  
  df <- df %>%
    group_by(lon, lat) %>%
    arrange(desc(art != "Ikke registreret"), desc(id)) %>%
    mutate(
      dup_n = n(),
      dup_loc = dup_n > 1,
      dup_keep =  ifelse(id == head(id, 1), TRUE, FALSE)) %>% 
    ungroup()
  
  if (!is.null(report)) {
    hits <- which(df$dup_loc & !df$dup_keep)
    if (length(hits)) report$add("DUPLICATE_LOCATION", df$uuid[hits], "lon/lat", paste(df$lon[hits], df$lat[hits]),  message = "flagged for deletion")
  }
  df
}