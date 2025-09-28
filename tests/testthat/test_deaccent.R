test_that("deaccent removes diacritics, leaves everything else", {
  df  <- tibble::tibble(
    uuid=c("a","b","c","d","e","f","g"), 
    traeart=c("Ácer gríseum", 
              "Mórus álba", 
              "Fagus sylvatica", 
              "Málus dómesticà 'Åland Øland'",
              "Málus dómesticà \"Åland Øland\"",
              NA, 
              ""))
  out <- deaccent(df, "traeart")
  expect_equal(out$traeart, c("Acer griseum", 
                              "Morus alba", 
                              "Fagus sylvatica", 
                              "Malus domestica 'Åland Øland'", 
                              "Malus domestica \"Åland Øland\"",
                              NA, 
                              ""))
})