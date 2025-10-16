# formula from map.js
rescale <- function(basezoom = 15, c = 0.35, zoom, radius) {
  s = 2^(c * (zoom - basezoom))
  radius * s
}

# ---Old radius formula---
calc_radius_old <- function(year, offset = 3.96, default_age = 25, factor = 0.3) {
  yr  <- coalesce(year, current_year - default_age)
  age <- pmax((current_year + 1) - yr, 1)
  offset + log(age) * factor             # factor 0.5 is to offset if zoom rescaling is on
}

radii <- tibble(year = c(1750L:2025L))

zoom <- c(12L:19L)
factor <- 0.3
c = 0.3

expand_grid(radii, zoom) %>% 
  expand_grid(factor) %>% 
  expand_grid(c) %>% 
  mutate(
    radius = calc_radius_old(year = year, factor = factor),
    rescaled = rescale(c = c, zoom = zoom, radius = radius)) %>% 
  ggplot() +
  geom_line(aes(year, rescaled, col = factor(zoom))) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(x = "Year", y = "Rescaled (pt)", title = "Current (old) radii") +
  guides(color = guide_legend(title = "Zoom level")) +
  theme_pub()

ggsave("app/radii.png", width = 10, height = 10, unit = "cm")

# ---New formula---
radii <- tibble(year = c(1750L:2025L))

zoom <- c(12L:19L)
k <- seq(0, 1, by = 0.1)
c <- seq(0, 0.5, by = 0.05)
r0 <- seq(1, 5, by = 0.4)

rdf <- expand_grid(radii, zoom) %>% 
  expand_grid(r0) %>% 
  expand_grid(k) %>% 
  expand_grid(c) %>% 
  mutate(
    radius = calc_radius(year = year, r0 = r0, k = k),
    rescaled = rescale(c = c, zoom = zoom, radius = radius)) 

rdf %>% 
  filter(near(r0, 3)) %>% # fixed r0
  ggplot() +
  geom_line(aes(year, rescaled, col = factor(zoom))) +
  scale_y_continuous(limits = c(0, NA)) +
  facet_grid(rows = vars(c), cols = vars(k), scales = "free_y", labeller = label_both) +
  labs(x = "Year", y = "Rescaled (pt)", title = "Radii") +
  guides(color = guide_legend(title = "Zoom level")) +
  theme_pub() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave("app/radii-k-c.png", width = 30, height = 30, unit = "cm")


rdf %>% 
  filter(near(c, 0.3)) %>% # fixed c
  ggplot() +
  geom_line(aes(year, rescaled, col = factor(zoom))) +
  scale_y_continuous(limits = c(0, NA)) +
  facet_grid(rows = vars(r0), cols = vars(k), scales = "fixed", labeller = label_both) +
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


