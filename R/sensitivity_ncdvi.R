# Endogeneity-sensitivity NCDVI: parallel index on non-endogenous inputs only
# (drops the four clinician-advice variables). Used to test whether the
# dose-response survives without the diagnosis-proxy inputs.

source("R/mca_index.R")
library(survey)

ncdvi_inputs_se <- c("occupation",
                     "BMI_cat",
                     "cook_fuel",
                     "water_source",
                     "toilet_type",
                     "crowding")

mca_se <- MCA(dat_18 %>% select(all_of(ncdvi_inputs_se)),
              ncp = 1, graph = FALSE)

dat_18 <- dat_18 %>%
  mutate(scores_se = as.numeric(mca_se$ind$coord),
         scores_se_std = (scores_se - min(scores_se)) /
                         (max(scores_se) - min(scores_se))) %>%
  arrange(scores_se_std) %>%
  mutate(ncdvi_se_raw = xtile(scores_se_std, n = 5))

# Auto-orient: Tier 5 = highest HTN prevalence.
prev_by_raw <- dat_18 %>%
  group_by(ncdvi_se_raw) %>%
  summarise(prev = mean(hyper == "Yes"), .groups = "drop") %>%
  arrange(ncdvi_se_raw)
flip <- prev_by_raw$prev[5] < prev_by_raw$prev[1]

dat_18 <- dat_18 %>%
  mutate(ncdvi_se = if (flip) 6 - ncdvi_se_raw else ncdvi_se_raw) %>%
  mutate(ncdvi_se = factor(ncdvi_se - 1,
                           levels = c(0, 1, 2, 3, 4),
                           labels = c("Tier 1", "Tier 2", "Tier 3",
                                      "Tier 4", "Tier 5")))

labelled::var_label(dat_18$ncdvi_se) <-
  "NCD Vulnerability Index (Non-Endogenous Inputs)"

# Side-by-side comparison
prev_tab <- bind_rows(
  dat_18 %>%
    group_by(tier = ncdvi) %>%
    summarise(prev = mean(hyper == "Yes"), .groups = "drop") %>%
    mutate(index = "Primary (10-input)"),
  dat_18 %>%
    group_by(tier = ncdvi_se) %>%
    summarise(prev = mean(hyper == "Yes"), .groups = "drop") %>%
    mutate(index = "Sensitivity (6-input)")
) %>% tidyr::pivot_wider(names_from = index, values_from = prev)

# Adjusted-OR comparison via svyglm
dat_18 <- dat_18 %>% mutate(sampling_wgt = hv005 / 1e6)
dat_dhs <- svydesign(id = ~hv021, strata = ~hv023,
                     weights = ~sampling_wgt, data = dat_18, nest = TRUE)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
rhs <- paste(confounders, collapse = " + ")

fit_primary <- svyglm(as.formula(paste("hyper ~ ncdvi +", rhs)),
                      design = dat_dhs, family = quasibinomial())
fit_se      <- svyglm(as.formula(paste("hyper ~ ncdvi_se +", rhs)),
                      design = dat_dhs, family = quasibinomial())

extract_tier_or <- function(fit, idx) {
  cf <- summary(fit)$coef
  rows <- grep(paste0("^", idx, "Tier"), rownames(cf))
  data.frame(tier = sub(paste0("^", idx), "", rownames(cf)[rows]),
             OR   = round(exp(cf[rows, 1]), 2),
             lo95 = round(exp(cf[rows, 1] - 1.96 * cf[rows, 2]), 2),
             hi95 = round(exp(cf[rows, 1] + 1.96 * cf[rows, 2]), 2),
             p    = signif(cf[rows, 4], 3))
}

or_primary <- extract_tier_or(fit_primary, "ncdvi")
or_se      <- extract_tier_or(fit_se,      "ncdvi_se")

saveRDS(list(prev_by_tier   = prev_tab,
             or_primary     = or_primary,
             or_sensitivity = or_se,
             mca_eig_primary     = head(mca$eig, 5),
             mca_eig_sensitivity = head(mca_se$eig, 5)),
        "outputs/phase2_sensitivity.rds")

# Persist 2017-18 sensitivity-MCA fit + score scaling + quintile thresholds
# so validate_2022.R can project the 2022 indicator matrix onto the same axis.
scores_se_raw <- as.numeric(mca_se$ind$coord)
sens_artifacts <- list(
  mca_se          = mca_se,
  inputs          = ncdvi_inputs_se,
  factor_levels   = lapply(dat_18[ncdvi_inputs_se], levels),
  score_min       = min(scores_se_raw),
  score_max       = max(scores_se_raw),
  flip            = flip,
  quintile_cuts   = quantile(dat_18$scores_se_std,
                             probs = seq(0, 1, 0.2), names = FALSE)
)
saveRDS(sens_artifacts, "outputs/sens_mca_artifacts.rds")
