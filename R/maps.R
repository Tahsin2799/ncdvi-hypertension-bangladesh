source("R/complex_survey.R")
suppressPackageStartupMessages({
  library(bangladesh)
  library(gridExtra)
  library(scales)
  library(ggplot2)
  library(dplyr)
  library(sf)
})

# Division shapefile: alphabetical (Barisal, Chittagong, Dhaka, Khulna,
# Mymensingh, Rajshahi, Rangpur, Sylhet). Join summaries by name, NOT row order.
div_map <- get_map(level = "division")

# Direct age-standardisation of HTN prevalence to the overall age-category
# distribution. Raw division-level prevalence is dominated by age composition
# (older divisions like Barisal/Rangpur look hypertensive; Dhaka has high Tier 5
# share but young population looks low).
age_ref <- prop.table(table(dat_18$age_cat))

div_htn <- dat_18 %>%
  group_by(division, age_cat) %>%
  summarise(prev = mean(hyper == "Yes"), .groups = "drop") %>%
  group_by(division) %>%
  summarise(age_adj_prev = sum(prev * age_ref[as.character(age_cat)]),
            .groups = "drop") %>%
  mutate(division = as.character(division))

div_ncdvi <- dat_18 %>%
  group_by(division) %>%
  summarise(avg_ncdvi = mean(scores_std), .groups = "drop") %>%
  mutate(division = as.character(division))

div_map <- div_map %>%
  left_join(div_htn,   by = c("Division" = "division")) %>%
  left_join(div_ncdvi, by = c("Division" = "division"))

make_div_map <- function(fill_var, title, fmt = label_percent(accuracy = 1)) {
  ggplot(div_map) +
    geom_sf(aes(fill = .data[[fill_var]]),
            color = "white", linewidth = 0.3) +
    scale_fill_viridis_c(option = "magma", direction = -1, labels = fmt) +
    labs(title = title, fill = NULL) +
    theme_void(base_size = 11) +
    theme(plot.title    = element_text(hjust = 0.5, face = "bold", size = 11),
          legend.key.height = unit(0.9, "cm"),
          legend.text   = element_text(size = 9))
}

map1 <- make_div_map("age_adj_prev", "Age-adjusted hypertension prevalence")
map2 <- make_div_map("avg_ncdvi", "Mean NCDVI score",
                     fmt = label_number(accuracy = 0.01))

ggsave("Figures/maps_by_div.jpg",
       arrangeGrob(map1, map2, ncol = 2),
       limitsize = FALSE,
       width = 8.9,
       height = 5.425)
