# Wilkinson Dot Plot Function
# Creates a dot plot where each dot represents a certain number of observations
# Automatically bins years and counts to keep the plot manageable

#' Create a Wilkinson Dot Plot
#' 
#' @param data Either a vector of years, or a data frame
#' @param year_col If data is a data frame, the name of the year column (unquoted)
#' @param count_col If data is a data frame with counts, the name of the count column (unquoted)
#' @param year_bin Number of years to group together (e.g., 5 for 5-year bins)
#' @param max_height Maximum number of dots in a stack (default 10)
#' @param dot_size Size of the dots (default 3)
#' @param dot_color Color of the dots (default "steelblue")
#' @param title Plot title
#' @param xlab X-axis label
#' @param ylab Y-axis label
#' @return A ggplot object
#' 
#' @examples
#' # Simple vector of years
#' years <- sample(2000:2023, 150, replace = TRUE)
#' wilkinson_dotplot(years, year_bin = 5)
#' 
#' # Data frame with one row per tree
#' trees <- data.frame(species = rep("Oak", 100), 
#'                     plant_year = sample(2010:2023, 100, replace = TRUE))
#' wilkinson_dotplot(trees, year_col = plant_year, year_bin = 5)
#' 
#' # Data frame with counts already summarized
#' tree_summary <- data.frame(year = 2010:2023, 
#'                            count = sample(10:50, 14, replace = TRUE))
#' wilkinson_dotplot(tree_summary, year_col = year, count_col = count, year_bin = 5)

wilkinson_dotplot <- function(data, 
                             bin = 5,
                             max_height = 10,
                             dot_size = 3,
                             dot_color = "steelblue",
                             title = NULL,
                             xlab = NULL,
                             ylab = NULL) {
  
  require(ggplot2)
  require(dplyr)
  
    # Input is a vector
  df <- data.frame(x = as.numeric(data))
  df <- df %>%
    group_by(x) %>%
    summarise(count = n(), .groups = "drop")
  
  # Create year bins
  min_x <- min(df$x)
  max_x <- max(df$x)
  
  # Create bin breaks
  bin_breaks <- seq(floor(min_x / bin) * bin, 
                   ceiling(max_x / bin) * bin, 
                   by = bin)
  
  # Assign each year to a bin and sum counts
  df_binned <- df %>%
    mutate(bin = cut(x, 
                         breaks = bin_breaks, 
                         include.lowest = TRUE,
                         right = FALSE)) %>%
    group_by(bin) %>%
    summarise(total_count = sum(count), .groups = "drop") %>%
    filter(!is.na(bin))
  
  # Extract bin centers for plotting
  df_binned <- df_binned %>%
    mutate(
      bin_start = as.numeric(sub("\\[([0-9]+),.*", "\\1", bin)),
      bin_end = as.numeric(sub(".*,([0-9]+)\\)", "\\1", bin)),
      bin_center = (bin_start + bin_end) / 2
    )
  
  # Determine instances per dot based on max_height
  max_count <- max(df_binned$total_count)
  instances_per_dot <- ceiling(max_count / max_height)
  
  # Round trees_per_dot to a nice number
  if (instances_per_dot > 1) {
    nice_numbers <- c(2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000)
    instances_per_dot <- nice_numbers[which(nice_numbers >= instances_per_dot)[1]]
    if (is.na(instances_per_dot)) {
      # If larger than our nice numbers, round to nearest power of 10
      instances_per_dot <- 10^ceiling(log10(max_count / max_height))
    }
  }
  
  # Calculate number of dots for each bin (rounded down, no partial dots)
  df_binned <- df_binned %>%
    mutate(n_dots = floor(total_count / instances_per_dot))
  
  # Create dot positions
  dot_data <- df_binned %>%
    filter(n_dots > 0) %>%
    rowwise() %>%
    do({
      data.frame(
        bin_center = .$bin_center,
        bin_start = .$bin_start,
        bin_end = .$bin_end,
        dot_height = 1:.$n_dots,
        total_count = .$total_count
      )
    }) %>%
    ungroup()
  
  # Set y-axis label
  if (is.null(ylab)) {
    if (instances_per_dot == 1) {
      ylab <- "Count"
    } else {
      ylab <- paste0("Count (each dot = ", instances_per_dot, " trees)")
    }
  }
  
  # Create the plot
  p <- ggplot(dot_data, aes(x = bin_center, y = dot_height)) +
    geom_point(size = dot_size, color = dot_color, shape = 16) +
    scale_x_continuous(breaks = bin_breaks, 
                      limits = c(min(bin_breaks), max(bin_breaks))) +
    scale_y_continuous(breaks = seq(0, max(dot_data$dot_height), by = 2),
                      expand = expansion(mult = c(0.02, 0.1))) +
    labs(title = title, x = xlab, y = ylab) +
    theme_minimal() +
    theme(
      panel.grid.major.x = element_line(color = "gray80", linewidth = 0.5),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 11, face = "bold"),
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5)
    )
  
  # Add annotation about binning if applicable
  if (instances_per_dot > 1) {
    cat(paste0("Note: Each dot represents ", instances_per_dot, " trees\n"))
    cat(paste0("Year bins: ", bin, " years each\n"))
  }
  
  return(p)
}