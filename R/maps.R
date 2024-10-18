source("R/complex_survey.R")
library(bangladesh)
library(gridExtra)

# bd shapefile
div_map <- get_map(level = "division")

# map for prevalence of hyper
div_hyper_prop <- dat_18 %>% 
  group_by(division) %>% 
  count(hyper, name = "freq") %>% 
  mutate(prop = freq/sum(freq)) %>%
  filter(hyper == "Yes") %>% 
  select(division, prop) 

map1 <- ggplot(data = div_map) +
  geom_sf(aes(fill = div_hyper_prop$prop)) +
  scale_fill_gradient(low = "yellow",
                      high = "red",
                      aesthetics = "fill") +
  labs(title = "Prevalence of Hypertension") +
  #guides(fill = guide_legend(title=)) +
  theme(legend.title = element_blank(),
        # panel.grid = element_blank(),
        # panel.background = element_blank(),
        axis.ticks.x = element_blank(),
        axis.ticks.y = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank())

# ggsave("Figures/hyper_by_div.jpg",
#        limitsize = FALSE,
#        width = 8.9,
#        height = 5.425)

# map for mean ncdvi
div_ncdvi <- dat_18 %>% 
  group_by(division) %>% 
  summarise(avg_ncdvi = mean(scores_std)) 

map2 <- ggplot(data = div_map) +
  geom_sf(aes(fill = div_ncdvi$avg_ncdvi)) +
  scale_fill_gradient(low = "yellow",
                      high = "red",
                      aesthetics = "fill") +
  labs(title = "Average NCDVI Score") +
  #guides(fill = guide_legend(title=)) +
  theme(legend.title = element_blank(),
    # panel.grid = element_blank(),
    # panel.background = element_blank(),
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    axis.ticks = element_blank(),
    axis.text = element_blank())

ggsave("Figures/maps_by_div.jpg",
       arrangeGrob(map1, map2, ncol = 2),
       limitsize = FALSE,
       width = 8.9,
       height = 5.425)
