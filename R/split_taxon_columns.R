split_taxon_columns <- function(df) {
  
  df <- df %>% separate(traeart, c("art", "sort"), sep = "([\\'\\\"])", remove = FALSE, fill = "right")
  
  df <- df %>% separate(art, c("art", "variant"), sep = "(?=\\s+var\\.\\s+|\\s+f\\.\\s+|\\s+fk\\s+|\\s+sel\\.\\s+|\\s+ssp\\.\\s+)", remove = TRUE, fill = "right")  
  
  df <- df %>% separate(art, into = "genus", sep = " ", remove = FALSE) %>% 
    mutate(genus = ifelse(genus == "Ikke", NA, genus))
  
  df$art <- str_squish(df$art)
  df$variant <- str_squish(df$variant)
  df$sort <- str_squish(df$sort)
  df$genus <- str_squish(df$genus)
  
  df
  }