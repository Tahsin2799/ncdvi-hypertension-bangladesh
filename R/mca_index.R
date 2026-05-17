source("R/analysis_main.R")
library(statar)

# NCDVI input set: 6 original (clinical-advice + occupation + BMI) plus 4
# structural (cook fuel, water, toilet, crowding). cook_location dropped after
# Phase 5 robustness — 97% in one category, no MCA signal.
ncdvi_inputs <- c("occupation",
                  "BMI_cat",
                  "salt_intake",
                  "stop_smok",
                  "lose_wgt",
                  "exer_more",
                  "cook_fuel",
                  "water_source",
                  "toilet_type",
                  "crowding")

mca <- MCA(dat_18 %>% select(all_of(ncdvi_inputs)), ncp = 1)

dat_18 <- dat_18 %>%
  mutate(scores = mca$ind$coord) %>%
  mutate(scores_std = (scores - min(scores))/(max(scores) - min(scores))) %>%
  arrange(scores_std) %>%
  mutate(ncdvi_raw = xtile(scores_std, n = 5))

# MCA dim-1 sign is arbitrary; auto-orient so Tier 5 = highest HTN prevalence.
# Without this, adding or dropping any MCA input can silently flip tier order.
prev_by_raw <- dat_18 %>%
  group_by(ncdvi_raw) %>%
  summarise(prev = mean(hyper == "Yes"), .groups = "drop") %>%
  arrange(ncdvi_raw)
flip_primary <- prev_by_raw$prev[5] < prev_by_raw$prev[1]

dat_18 <- dat_18 %>%
  mutate(ncdvi = if (flip_primary) 6 - ncdvi_raw else ncdvi_raw) %>%
  mutate(ncdvi = factor(ncdvi - 1,
                        levels = c(0, 1, 2, 3, 4),
                        labels = c("Tier 1", "Tier 2", "Tier 3",
                                   "Tier 4", "Tier 5")))

# Keep scores_std aligned with tier orientation for downstream continuous use.
if (flip_primary) {
  dat_18 <- dat_18 %>% mutate(scores_std = 1 - scores_std)
}

labelled::var_label(dat_18$ncdvi) <- "NCD Vulnerability Index"
