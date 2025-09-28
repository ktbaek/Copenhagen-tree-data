apply_dict_rules_triple <- function(df, rules, target_col = "dansk_navn", report = NULL) {
  stopifnot(all(c("art","variant","sort","replacement") %in% names(rules)))
  
  ruleset <- attr(rules, "ruleset")
  # Keep only the mapping we need; enforce one-to-one to avoid row explosions
  map <- rules %>%
    select(art, variant, sort, replacement, note = any_of("note"), priority = any_of("priority")) %>%
    #mutate(replacement = na_if(replacement, "NA")) %>% 
    arrange(desc(priority %||% 0)) %>%
    distinct(art, variant, sort, .keep_all = TRUE)
  
  # Snapshot 'before' and do a many-to-one multi-key join
  before <- df[[target_col]]
  out <- df %>%
    left_join(
      map,
      by = c("art","variant","sort"),
      relationship = "many-to-one",
      na_matches = "na"  # "na" makes NA==NA match
    ) %>%
    mutate("{target_col}" := coalesce(replacement, .data[[target_col]])) %>%
    select(-replacement)
  
  if (!is.null(report)) {
    after <- out[[target_col]]
    changed <- which(tidyr::replace_na(before, "") != tidyr::replace_na(after, ""))
    if (length(changed)) {
      msg <- if ("note" %in% names(out)) out$note[changed] else NA_character_
      report$add("APPLIED_DICT_RULE", out$uuid[changed], target_col,
                 before[changed], after[changed], ruleset = ruleset, msg)
    }
  }
  out %>% select(-note, -priority)
}