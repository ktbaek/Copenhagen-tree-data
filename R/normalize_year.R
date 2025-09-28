normalize_year <- function(df, lower_bound = 1700L, report = NULL) {
  
  # find issue
  hits <- which(!is.na(df$planteaar) & !df$planteaar %in% c(lower_bound:as.integer(format(Sys.time(), "%Y"))))
  if (!length(hits)) return(df) # if no issues, end function and return df
  
  # correct issue
  before <- df$planteaar[hits]
  df$planteaar[hits] <- NA_integer_
  after  <- df$planteaar[hits]  # now NA
  
  # report issue
  if (!is.null(report)) report$add("YEAR_RANGE", df$uuid[hits], "planteaar", before, after, message = "year outside allowed range")
  
  df
}