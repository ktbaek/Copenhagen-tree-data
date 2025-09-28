apply_dict_rules <- function(df, rules, target_col, report = NULL) {
  stopifnot(all(c("if_column","pattern","replacement") %in% names(rules)))
  if (!nrow(rules)) return(df)
  
  ruleset <- attr(rules, "ruleset")
  
  # work on a single vector
  target <- df[[target_col]]
  
  for (i in seq_len(nrow(rules))) {
    src   <- rules$if_column[[i]]
    pat   <- rules$pattern[[i]]
    repl  <- rules$replacement[[i]]
    
    if (!src %in% names(df)) next
    vec <- df[[src]]
    
    cond <- !is.na(vec) & vec == pat & target != repl # is the pattern found in source column and is the target value wrong? TRUE/FALSE vector
    hits <- which(cond) # where is the source pattern found with a wrong target value? integer vector
    
    if (!length(hits)) next
    before <- target[hits]
    target[hits] <- repl
    after  <- target[hits]
    
    if (!is.null(report)) {
      msg <- rules$note[[i]]
      report$add("APPLIED_DICT_RULE", df$uuid[hits], target_col, before, after, ruleset = ruleset,  msg)
    }
  }
  
  df[[target_col]] <- target
  df
}