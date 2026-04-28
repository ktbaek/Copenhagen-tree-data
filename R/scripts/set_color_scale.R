if(exists("set_color_df")) {

# Create the base color data
color_scheme <- viridisLite::viridis(373, direction = -1, begin = 0.27, end = 0.95) 

okhex_df <- as_tibble(farver::decode_colour(color_scheme, to = "oklch")) |> 
  mutate(
    hex = color_scheme,
    number = row_number()
  )

# Define sorting order
sorting_cols <- c("order_name", "family_name", "genus_name", "sp_last", "scientific_name")

custom_orders_first <- list(
  order_name = c("Sapindales", "Fagales"),
  genus_name = c("Fagus")
)

custom_orders_last <- list(
  order_name = c("Fabales", 
            "Malvales", 
            "Aquifoliales", 
            "Arecales", 
            "Buxales", 
            "Ericales", 
            "Trochodendrales", 
            "Araucariales",
            "Cupressales", 
            "Pinales"),
  genus_name = c("Quercus")
)

taxo_df <- set_color_df |> 
  filter(!is.na(genus_name)) |> 
  select(order_name, family_name, genus_name, scientific_name) |> 
  group_by(scientific_name) |> 
  mutate(n = n()) |> 
  ungroup() |> 
  distinct() |> 
  mutate(
    across(all_of(names(custom_orders_first)),
    ~forcats::fct_relevel(.x, custom_orders_first[[cur_column()]], after = 0)),
    across(all_of(names(custom_orders_last)),
           ~forcats::fct_relevel(.x, custom_orders_last[[cur_column()]], after = Inf)),
    sp_last = grepl("\\bsp\\.", scientific_name)
    ) |>
  arrange(across(all_of(sorting_cols))) |>
  select(-sp_last) |> 
  mutate(seq = row_number())

# add colors to sorted species dataframe
taxo_color_df <- taxo_df |> 
  left_join(okhex_df, by = c("seq" = "number"), relationship = "one-to-one") |> 
  arrange(seq) |> 
  mutate(
    xmax = cumsum(n),
    xmin = lag(xmax, default = 0)
  )

# # generate analytic output - plots and mean oklch values
# map_color_df <- set_color_df|> 
#   filter(!is.na(genus_name)) |> 
#   left_join(taxo_color_df, 
#             by = c("scientific_name", "genus_name", "family_name", "order_name"), 
#             relationship = "many-to-one") |> 
#   select(uuid, scientific_name, genus_name, family_name, order_name, n, seq, l, c, h, hex, xmax, xmin)
# 
# mean_l <- round(mean(map_color_df$l, na.rm = TRUE), 3)
# mean_c <- round(mean(map_color_df$c, na.rm = TRUE), 3)
# mean_h <- round(mean(map_color_df$h, na.rm = TRUE), 1)
# 
# mean_hex <- farver::encode_colour(matrix(c(mean_l, mean_c, mean_h), nrow = 1), from = "oklch")
# mean_oklch <- paste0("oklch(", mean_l, " ", mean_c, " ", mean_h, ")")
# 
# cli::cli_alert_info(paste0("Average marker color: ", cli::make_ansi_style(mean_hex)(paste(mean_hex, mean_oklch))))
# 
# # cumulative plot of color scale steps
# map_color_df |> 
#   select(art, seq) |> 
#   arrange(seq) |> 
#   mutate(
#     test = row_number(),
#     control = nrow(filter(set_color_df, !is.na(genus))) / nrow(taxo_color_df) * (seq - 1)
#     ) |> 
#   pivot_longer(c(test, control)) |> 
#   ggplot() +
#   geom_line(aes(seq, value, color = name), linewidth = 1) +
#   scale_color_grey() +
#   theme_minimal() +
#   theme(panel.background = element_rect(fill = mean_hex))
#   
# # color scale plot with genus labels
# genus_boundaries <- taxo_color_df |>
#   group_by(genus) |>
#   summarise(
#     xmin = min(xmin),
#     xmax = max(xmax),
#     xmid = (min(xmin) + max(xmax)) / 2,
#     .groups = 'drop'
#   ) |>
#   mutate(width = xmax - xmin) |>
#   filter(width > 100)  # Adjust threshold as needed
# 
# ggplot() +
#   geom_rect(data = taxo_color_df, 
#             aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = 1, fill = hex)) +
#   geom_vline(data = genus_boundaries, 
#              aes(xintercept = xmax), 
#              color = "white", linewidth = 0.3, alpha = 0.5) +
#   scale_fill_identity() +
#   scale_x_continuous(
#     breaks = genus_boundaries$xmid,
#     labels = genus_boundaries$genus,
#     expand = c(0, 0)
#   ) +
#   theme_void() +
#   theme(
#     axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 6),
#     plot.margin = margin(b = 40)
#   )

# join color codes back into set_color_df

species_colors_df <- taxo_color_df |> 
  select(scientific_name, hex) |> 
  rename(fillcolor = hex)

cli::cli_alert_success("Color scales calculated")

# Convert color-taxonomy dataframe to tree
taxo_tree_df <- taxo_color_df |>
  rename(species = scientific_name,
         value = hex) |>
  rename_with(str_remove, pattern = "_name") |> 
  select(order, family, genus, species, value)

taxo_tree_df$pathString <- paste("trees",
                                 taxo_tree_df$order,
                                 taxo_tree_df$family,
                                 taxo_tree_df$genus,
                                 taxo_tree_df$species,
                                sep = "/")

taxo_tree <- taxo_tree_df |>
  select(pathString, value) |>
  data.tree::as.Node()

# Convert to list format
taxo_tree_list <- data.tree::ToListExplicit(taxo_tree, unname = TRUE,
                            nameName = "name",
                            childrenName = "children")

# Write JSON
write(toJSON(taxo_tree_list, pretty = TRUE, auto_unbox = TRUE), '../website/src/assets/dataset/taxonomy.json')

cli::cli_alert_success("Taxonomy JSON generated")
 }