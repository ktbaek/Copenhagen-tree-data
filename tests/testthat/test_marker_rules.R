test_that("markers csv works", {
  
  rules <- readr::read_delim(
    root_path("rules", "markers.csv"),
    trim_ws = FALSE, show_col_types = FALSE
  )

  df <- tibble::tibble(
    uuid = c("a", "b", "c", "d", "e", "f"),
    traeart = c(
      "Carpinus betulus \"Frans Fontaine\"",
      "Magnolia x Soulangiana",
      "Catalpa X erubescens",
      "Prunus X",
      "Phoenix normalis",
      NA
    )
  )

  truth <- c(
    "Carpinus betulus 'Frans Fontaine'",
    "Magnolia hybr. Soulangiana",
    "Catalpa hybr. erubescens",
    "Prunus X",
    "Phoenix normalis",
    NA
  )
  out <- apply_regex_rules(df, rules = rules, report = NULL)
  expect_equal(out$traeart, truth)
})
