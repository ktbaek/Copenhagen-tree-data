split_taxon_columns <- function(df) {
  
  df <- df %>% mutate(
    species  = str_match(traeart, "^(.+?)(?:\\s+['\"].+['\"])?$")[, 2],
    cultivar = str_match(traeart, "['\"](.+)['\"]")[, 2]
  )
  
  df <- df %>% separate(
    species, c("species", "variety"), 
    sep = "\\s+(?=var\\.|f\\.|fk\\s|sel\\.|ssp\\.)", 
    remove = TRUE, fill = "right")  
  
  df <- df %>% separate(species, into = "genus", sep = " ", remove = FALSE, extra = "drop") %>% 
    mutate(genus = ifelse(genus == "Ikke", NA, genus))
  
  cli::cli_alert_success("Taxon columns were split")
  
  df
}