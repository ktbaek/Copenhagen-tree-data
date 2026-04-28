tt_read_csv <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  
  # Harmonize names
  df <- df %>%
    dplyr::select(
      uuid, id, traeart, dansk_navn, slaegtsnavn, planteaar, bydelsnavn,
      fredet_beskyttet_trae, saerligt_trae, ikonisk_trae, spiselige_frugter, wkb_geometry
    ) %>%
    dplyr::mutate(
      id = suppressWarnings(as.integer(id)),
      planteaar = suppressWarnings(as.integer(planteaar)),
      ikonisk_trae = suppressWarnings(as.integer(ikonisk_trae)),
      saerligt_trae = stringr::str_to_lower(saerligt_trae),
      spiselige_frugter = stringr::str_to_lower(spiselige_frugter)
    )
  df
}