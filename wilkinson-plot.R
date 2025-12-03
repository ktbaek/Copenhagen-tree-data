df <- read_rds('2025/output/trees.rds')

df |> 
  filter(art == "Acer negundo") |> 
  ggplot() +
  geom_histogram(aes(planteaar, fill = fillcolor), binwidth = 5) +
  scale_fill_identity() +
  facet_wrap(vars(art), scales = "free_y") +
  theme_minimal()

ggsave('app/acerplot.svg', width = 20, height = 10, units = "cm")

df |> 
  filter(art == "Acer platanoides") |> 
  group_by(planteaar) |> 
  summarize(
    n = ceiling((n()/10))) |> 
  ggplot() +
  geom_dotplot(aes(x = planteaar, y = n), binwidth=1, binaxis = "y") +
 # scale_color_identity() +
 # scale_fill_identity() +
  scale_y_continuous(NULL, breaks = NULL) + 
  # Make this as high as the tallest column
  coord_fixed(ratio = 30) +
  theme_minimal()

source('2025/R/wilkinson_dotplot.R')

years |> 
  wilkinson_dotplot(bin = 10)

years <- df |> 
    filter(art == "Acer platanoides", !is.na(planteaar)) |> 
    pull(planteaar)

# Source - https://stackoverflow.com/a
# Posted by tjebo, modified by community. See post 'Timeline' for change history
# Retrieved 2025-11-18, License - CC BY-SA 4.0

library(tidyverse)
library(ggforce)

df <- structure(list(x = c(79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105), y = c(1, 0, 0, 2, 1, 2, 7, 3, 7, 9, 11, 12, 15, 8, 10, 13, 11, 8, 9, 2, 3, 2, 1, 3, 0, 1, 1)), class = "data.frame", row.names = c(NA, -27L))

df <- df |> 
  filter(art == "Acer platanoides", !is.na(planteaar)) |> 
  select(planteaar) |> 
  rename(x = planteaar)


bin_width <- 5
pt_width <- bin_width / 3 # so that they don't touch horizontally
pt_height <- bin_width / 2 # 2 so that they will touch vertically

count_data <- 
  data.frame(x = rep(df$x, df$y)) %>%
  mutate(x = plyr::round_any(x, bin_width)) %>%
  group_by(x) %>%
  mutate(y = seq_along(x))

count_data <- 
  df |> 
  mutate(x = plyr::round_any(x, bin_width)) %>%
  group_by(x) %>%
  mutate(y = seq_along(x)) 

max_count <- max(count_data$y)
max_height <- 20
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

ggplot(count_data) +
  ggforce::geom_ellipse(aes(
    x0 = x,
    y0 = y,
    a = pt_width / bin_width,
    b = pt_height / bin_width,
    angle = 0
  )) +
  coord_equal((1 / pt_height) * pt_width)# to make the dot
