normalize_case_danish <- function(df, report = NULL) {
  
  before <- df$dansk_navn
  df <- df %>% mutate(
    dansk_navn = ifelse(is.na(dansk_navn), NA, 
                        ifelse(str_detect(dansk_navn, "'"), 
                               dansk_navn, str_to_sentence(dansk_navn))))
  after <- df$dansk_navn
  hits <- which(before != after)
  before <- before[hits]
  after <- after[hits]
  
  if (!is.null(report)) report$add("WRONG_CASE_DANISH", df$uuid[hits], "dansk_navn", before, after, message = "to sentence case")
  
  df
  }