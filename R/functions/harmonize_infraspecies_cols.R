harmonize_infraspecies_cols <- function(df) {

  df |> 
   tidyr::separate_wider_delim(variety, " ", names = c("var_type", "var_name")) |> 
     dplyr::mutate(
       infraspecies_type = dplyr::case_when(
         !is.na(cultivar) ~ "cultivar",
         !is.na(var_type)  ~ var_type,
         TRUE             ~ NA_character_
         ),
      infraspecies_name = dplyr::case_when(
        !is.na(cultivar) ~ cultivar,
        !is.na(var_name)  ~ var_name,
        TRUE             ~ NA_character_
        )
      ) |> 
    dplyr::select(-cultivar, -var_type, -var_name)
}