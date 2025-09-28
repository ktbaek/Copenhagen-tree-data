# tests/testthat/helper-setup.R
# Find the project root (by .Rproj or .git); works even though WD is tests/testthat
root <- rprojroot::find_root(
  rprojroot::has_file_pattern("*.Rproj") | rprojroot::is_git_root
)

root_path <- function(...) file.path(root, ...)

# Source all R/ files so tests can see your functions
r_files <- list.files(root_path("R"), pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source, local = TRUE))
