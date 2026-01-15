normalize_year <- function(df, lower_bound = 1700L, upper_bound, report = NULL) {
  
  hits <- which(!is.na(df$planteaar) & !df$planteaar %in% c(lower_bound:upper_bound))
  if (!length(hits)) return(df)
  
  before <- df$planteaar[hits]
  df$planteaar[hits] <- NA_integer_
  after  <- df$planteaar[hits]  # now NA
  
  if (!is.null(report)) report$add("YEAR_RANGE", df$uuid[hits], "planteaar", before, after, message = "year outside allowed range")
  
  cli::cli_alert_success(paste0("YEAR_RANGE made ", length(hits), " changes."))
  
  df
}