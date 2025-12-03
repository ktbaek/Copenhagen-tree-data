source('2025/R/calc_radius.R')
source('2025/R/theme_pub.R')

# formula from map.js
rescale <- function(basezoom = 15, c = 0.35, zoom, radius) {
  s = 2^(c * (zoom - basezoom))
  radius * s
}

label_both_eq <- function(labels, multi_line = TRUE, sep = " = ") {
  value <- label_value(labels, multi_line = multi_line)
  
  if (isTRUE(multi_line)) {
    row <- as.list(names(labels))
  } else {
    row <- list(paste(names(labels), collapse = ", "))
  }
  variable <- lapply(row, rep, nrow(labels) %||% length(labels[[1]]))
  
  if (multi_line) {
    out <- vector("list", length(value))
    for (i in seq_along(out)) {
      out[[i]] <- paste(variable[[i]], value[[i]], sep = sep)
    }
  } else {
    value <- inject(paste(!!!value, sep = ", "))
    variable <- inject(paste(!!!variable, sep = ", "))
    out <- Map(paste, variable, value, sep = sep)
    out <- list(unname(unlist(out)))
  }
  
  out
}

# ---New formula---
radii <- tibble(year = c(1750L:2025L))

zoom <- c(12L:19L)
k <- seq(0, 1, by = 0.5)
c <- seq(0, 0.5, by = 0.25)
r0 <- seq(1, 5, by = 0.4)

rdf <- expand_grid(radii, zoom) %>% 
  expand_grid(r0) %>% 
  expand_grid(k) %>% 
  expand_grid(c) %>% 
  mutate(
    radius = calc_radius(year = year, current_year = 2025, r0 = r0, k = k),
    rescaled = rescale(c = c, zoom = zoom, radius = radius)) 

rdf %>% 
  filter(near(r0, 3)) %>% # fixed r0
  ggplot() +
  geom_line(aes(year, rescaled, col = factor(zoom)), linewidth = 0.4) +
  scale_y_continuous(limits = c(0, NA)) +
  scale_x_continuous(breaks = c(1800, 1900, 2000)) +
  facet_grid(rows = vars(c), cols = vars(k), scales = "free_y", labeller = label_both_eq) +
  labs(x = "Plant year", y = "Rescaled (pt)", title = "Radii") +
  guides(color = guide_legend(title = "Zoom level")) +
  theme_pub() +
  theme(
    #axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
    #strip.text.y = element_text(angle = 0),
    legend.position = "bottom")


ggsave("app/radii-k-c-small.png", width = 10, height = 12.5, unit = "cm")


rdf %>% 
  filter(near(c, 0.3)) %>% # fixed c
  ggplot() +
  geom_line(aes(year, rescaled, col = factor(zoom))) +
  scale_y_continuous(limits = c(0, NA)) +
  facet_grid(rows = vars(r0), cols = vars(k), scales = "fixed", labeller = label_both_eq) +
  labs(x = "Year", y = "Rescaled (pt)", title = "Radii") +
  guides(color = guide_legend(title = "Zoom level")) +
  theme_pub() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave("app/radii-k-r0.png", width = 30, height = 34, unit = "cm")

rdf %>% 
  filter(near(k, 0.7)) %>% # fixed k
  ggplot() +
  geom_line(aes(year, rescaled, col = factor(zoom))) +
  scale_y_continuous(limits = c(0, NA)) +
  facet_grid(rows = vars(r0), cols = vars(c), scales = "fixed", labeller = label_both) +
  labs(x = "Year", y = "Rescaled (pt)", title = "Radii") +
  guides(color = guide_legend(title = "Zoom level")) +
  theme_pub() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave("app/radii-c-r0.png", width = 30, height = 34, unit = "cm")


