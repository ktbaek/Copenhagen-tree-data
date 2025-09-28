deaccent <- function(df, col, report = NULL) {
  
  cultivar_present <- stringr::str_detect(df[[col]], "['\"]")
  left <- stringr::str_replace_all(df[[col]], "(.*)(['\"][^']+['\"])", "\\1")
  right <- stringr::str_replace_all(df[[col]], "(.*)(['\"][^']+['\"])", "\\2")
  deaccented_left <- stringi::stri_trans_general(left, "NFD; [:Nonspacing Mark:] Remove; NFC")
  
  # correct issues
  before <- df[[col]]
  df[[col]] <- dplyr::if_else(cultivar_present, paste0(deaccented_left, right), deaccented_left)
  after <- df[[col]]
  
  # report issues
  if (!is.null(report)) {
    hits <- which(!is.na(before) & before != after)
    if (length(hits)) report$add("ILLEGAL_CHAR_LATIN", df$uuid[hits], col, before[hits], after[hits],
                                 message = "remove accents")
  }
  df
  }