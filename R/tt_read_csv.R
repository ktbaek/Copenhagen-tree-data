tt_read_csv <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  
  # Harmonize names
  df <- df %>%
    dplyr::rename(geometry = wkb_geometry, fredet = fredet_beskyttet_trae) %>%
    dplyr::select(
      uuid, id, traeart, dansk_navn, slaegtsnavn, planteaar, bydelsnavn,
      fredet, saerligt_trae, geometry
    ) %>%
    dplyr::mutate(
      fredet = dplyr::if_else(fredet == "Ikke registreret", "", fredet, missing = fredet),
      saerligt_trae = dplyr::if_else(saerligt_trae == "nej", "", "Særligt træ", missing = saerligt_trae),
      id = suppressWarnings(as.integer(id)),
      planteaar = suppressWarnings(as.integer(planteaar))
    )
  df
}