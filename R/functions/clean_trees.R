clean_trees <- function(df, rep = NULL, dataset_year) {
  
  df |>
  drop_dup_uuid(report = rep) |>
  normalize_year(upper_bound = dataset_year, report = rep) |>
  
  # Spelling, casing and normalization of scientific names
  deaccent(col = "traeart", report = rep) |>
  apply_regex_rules(rules = rules$markers, report = rep) |> # normalize hybrid markers, cultivar markers
  normalize_case_latin(report = rep) |> 
  apply_regex_rules(rules = rules$latin_regex, report = rep) |> 
  apply_regex_rules(rules = rules$latin_regex_malus, report = rep) |> 
  
  # whitespace QC
  mutate(across(where(is.character), str_squish)) |> 
  
  # flag trees with duplicate location
  flag_dupl_locations(report = rep) |> 
  arrange(id)
  
}