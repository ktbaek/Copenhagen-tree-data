test_that("normalize_year turns years out of range into NA, leaves others", {
  df  <- tibble::tibble(uuid=c("a","b","c"), planteaar=c(0L, 1999L, NA))
  out <- normalize_year(df)
  expect_equal(out$planteaar, c(NA_integer_, 1999L, NA_integer_))
})