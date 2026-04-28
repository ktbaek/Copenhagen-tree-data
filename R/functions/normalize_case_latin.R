normalize_case_latin <- function(df, report = NULL) {
  
  before <- df$traeart
  df <- df %>% mutate(
    traeart = sub("(')(\\w)", "\\1\\U\\2", traeart, perl = TRUE),
    traeart = sub("^([A-Za-z])", "\\U\\1", traeart, perl = TRUE)
  )
  after <- df$traeart
  hits <- which(before != after)
  before <- before[hits]
  after <- after[hits]
  
  if (!is.null(report)) report$add("WRONG_CASE_LATIN", df$uuid[hits], "dansk_navn", before, after, message = "fix casing latin name")
  
  cli::cli_alert_success(paste0("WRONG_CASE_LATIN made ", length(hits), " changes."))
  
  df
  }