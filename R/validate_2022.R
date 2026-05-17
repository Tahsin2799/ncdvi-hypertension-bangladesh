# External validation on BDHS 2022: build the 6-input sensitivity NCDVI on
# women age 18+ in the biomarker subsample, project onto the 2017-18 MCA dim-1
# axis, apply 2017-18 quintile thresholds, and report tier-level HTN prevalence
# and adjusted ORs.
#
# Joins: PR <- HR_long on (hv001, hv002, hvidx == ha0_k);
#        PR <- IR     on (hv001=v001, hv002=v002, hvidx=v003).
# Outcome: SBP (wbp9/13/22 mean) >= 140, DBP (wbp10/14/23 mean) >= 90, or
# wbp19 == 1 (currently taking BP medication).

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(FactoMineR)
  library(survey)
})

art <- readRDS("outputs/sens_mca_artifacts.rds")

# BDPR81 (person recode) — restrict to women age 18+ selected for biomarker module
pr <- read_dta(
  "Datasets/BDPR81DT/BDPR81FL.DTA",
  col_select = c(hv001, hv002, hvidx, hv005, hv021, hv022, hv023, hv024, hv025,
                 hv104, hv105, hv106, hv115, hv270,
                 hv009, hv216, hv201, hv205, hv226,
                 shbpbg,
                 wbp9, wbp10, wbp13, wbp14, wbp22, wbp23, wbp19)
) %>%
  filter(hv104 == 2, hv105 >= 18, shbpbg == 1)

# BDHR81 (household, wide _k blocks for biomarker slots) -> long
hr_slots <- 1:8
hr_cols  <- c("hv001", "hv002",
              paste0("ha0_",    hr_slots),
              paste0("ha40_",   hr_slots),
              paste0("sb340_",  hr_slots),
              paste0("sb367g_", hr_slots))
hr <- read_dta("Datasets/BDHR81DT/BDHR81FL.DTA", col_select = all_of(hr_cols))

hr_long <- hr %>%
  pivot_longer(
    cols          = -c(hv001, hv002),
    names_to      = c(".value", "slot"),
    names_pattern = "^(ha0|ha40|sb340|sb367g)_(\\d+)$"
  ) %>%
  rename(line_no  = ha0,
         bmi_x100 = ha40,
         diab_med = sb340,
         glucose_x10 = sb367g) %>%
  filter(!is.na(line_no)) %>%
  mutate(slot = as.integer(slot),
         hvidx = as.integer(line_no))

# BDIR81 (women's IR) for occupation (v716 in 2022 == sb308 numeric coding in 2017-18)
ir <- read_dta(
  "Datasets/BDIR81DT/BDIR81FL.DTA",
  col_select = c(v001, v002, v003, v716)
) %>%
  rename(hv001 = v001, hv002 = v002, hvidx = v003)

dat_22 <- pr %>%
  inner_join(hr_long %>%
               select(hv001, hv002, hvidx, bmi_x100, diab_med, glucose_x10),
             by = c("hv001", "hv002", "hvidx")) %>%
  left_join(ir, by = c("hv001", "hv002", "hvidx")) %>%
  filter(!is.na(v716))

# NCDVI inputs (match 2017-18 conventions)
dat_22 <- dat_22 %>%
  mutate(occupation = case_when(
            v716 %in% c(12,13,14,15,16,21,22,23,31) ~ 0,
            v716 %in% c(11,41,51,52)                ~ 1,
            v716 %in% c(0,61,62)                    ~ 2,
            v716 %in% c(96,98,99)                   ~ NA_real_),
         occupation = factor(occupation,
                             levels = c(0, 1, 2),
                             labels = c("Labor Taxing Job",
                                        "Not a Labor Taxing Job",
                                        "Not Working")))

# ha40_k is BMI * 100; sentinel >= 6000 means not measured.
dat_22 <- dat_22 %>%
  mutate(BMI = ifelse(!is.na(bmi_x100) & bmi_x100 < 6000, bmi_x100 / 100, NA_real_),
         BMI_cat = case_when(
            BMI <= 18.5                ~ 0,
            BMI > 18.5 & BMI <= 24.9   ~ 1,
            BMI > 24.9 & BMI <= 29.9   ~ 2,
            BMI > 29.9 & BMI <= 34.9   ~ 3,
            BMI > 34.9 & BMI <= 39.9   ~ 4,
            BMI > 39.9                 ~ 5),
         BMI_cat = factor(BMI_cat,
                          levels = c(0, 1, 2, 3, 4, 5),
                          labels = c("Underweight", "Normal weight",
                                     "Pre-obesity", "Obesity class I",
                                     "Obesity class II", "Obesity class III")))

dat_22 <- dat_22 %>%
  mutate(cook_fuel = case_when(
            hv226 %in% c(1, 2, 3, 4)              ~ 0,
            hv226 %in% c(5, 6, 7, 8, 9, 10, 11)   ~ 1,
            TRUE                                  ~ 0),
         cook_fuel = factor(cook_fuel,
                            levels = c(0, 1),
                            labels = c("Clean Fuel", "Solid/Polluting Fuel")),
         water_source = case_when(
            hv201 %in% c(11, 12, 13, 14, 51)      ~ 0,
            hv201 %in% c(21, 31, 41, 43)          ~ 1,
            hv201 %in% c(32, 42, 61, 62, 71, 96)  ~ 2,
            TRUE                                  ~ 0),
         water_source = factor(water_source,
                               levels = c(0, 1, 2),
                               labels = c("Piped/Treated",
                                          "Tubewell/Protected",
                                          "Unimproved/Surface")),
         toilet_type = case_when(
            hv205 %in% c(11, 12, 13, 21, 22, 31, 41) ~ 0,
            hv205 %in% c(14, 15, 23, 42, 43, 51, 96) ~ 1,
            TRUE                                     ~ 0),
         toilet_type = factor(toilet_type,
                              levels = c(0, 1),
                              labels = c("Improved", "Unimproved")),
         crowding = case_when(
            hv216 == 0 ~ 1,
            !is.na(hv009) & !is.na(hv216) & hv216 > 0 & (hv009 / hv216) > 3 ~ 1,
            TRUE ~ 0),
         crowding = factor(crowding,
                           levels = c(0, 1),
                           labels = c("Not Crowded", "Crowded")))

dat_22 <- dat_22 %>%
  filter(if_all(all_of(art$inputs), ~ !is.na(.)))

# Outcome: SBP/DBP averaged across 3 readings, with sentinel-code clipping.
clean_bp <- function(x, kind) {
  cap <- if (kind == "sbp") 300 else 200
  ifelse(!is.na(x) & x > 0 & x < cap, x, NA_real_)
}
dat_22 <- dat_22 %>%
  mutate(sbp1 = clean_bp(wbp9,  "sbp"),
         sbp2 = clean_bp(wbp13, "sbp"),
         sbp3 = clean_bp(wbp22, "sbp"),
         dbp1 = clean_bp(wbp10, "dbp"),
         dbp2 = clean_bp(wbp14, "dbp"),
         dbp3 = clean_bp(wbp23, "dbp"))

dat_22$sbp <- rowMeans(dat_22[, c("sbp1","sbp2","sbp3")], na.rm = TRUE)
dat_22$dbp <- rowMeans(dat_22[, c("dbp1","dbp2","dbp3")], na.rm = TRUE)
dat_22$sbp[is.nan(dat_22$sbp)] <- NA
dat_22$dbp[is.nan(dat_22$dbp)] <- NA

dat_22 <- dat_22 %>%
  mutate(pres_med = case_when(wbp19 == 1 ~ 1,
                              wbp19 == 0 | is.na(wbp19) ~ 0),
         hyper = if_else(sbp >= 140 | dbp >= 90 | pres_med == 1, 1, 0)) %>%
  filter(!is.na(sbp) | !is.na(dbp) | pres_med == 1) %>%
  filter(!is.na(hyper)) %>%
  mutate(hyper = factor(hyper, levels = c(0, 1), labels = c("No", "Yes")))

# Confounders
dat_22 <- dat_22 %>%
  mutate(glucose = ifelse(!is.na(glucose_x10) & glucose_x10 < 600,
                          glucose_x10 / 10, NA_real_),
         med_diab = case_when(diab_med == 1 ~ 1,
                              diab_med == 0 | is.na(diab_med) ~ 0),
         diabetic = if_else(!is.na(glucose) & (glucose >= 7 | med_diab == 1), 1,
                            if_else(med_diab == 1, 1, 0)),
         diabetic = factor(diabetic, levels = c(0, 1), labels = c("No", "Yes")),
         age = hv105,
         age_cat = case_when(
            hv105 <= 25 ~ 0, hv105 > 25 & hv105 <= 35 ~ 1,
            hv105 > 35 & hv105 <= 50 ~ 2, hv105 > 50 & hv105 <= 65 ~ 3,
            hv105 > 65 & hv105 <= 75 ~ 4, hv105 > 75 ~ 5),
         age_cat = factor(age_cat,
                          levels = 0:5,
                          labels = c("18-25","25-35","35-50","50-65","65-75","75+")),
         educ = factor(hv106,
                       levels = c(0, 1, 2, 3),
                       labels = c("No Education, Preschool", "Primary",
                                  "Secondary", "Higher")),
         marital_status = factor(case_when(
            hv115 == 1 ~ 0,
            hv115 %in% c(0, 3, 4) ~ 1),
            levels = c(0, 1),
            labels = c("Married", "Single")),
         wealth_index = factor(case_when(
            hv270 == 1 ~ 0, hv270 == 2 ~ 1, hv270 == 3 ~ 2,
            hv270 == 4 ~ 3, hv270 == 5 ~ 4),
            levels = 0:4,
            labels = c("Poorest","Poorer","Middle","Richer","Richest")),
         division = factor(case_when(
            hv024 == 1 ~ 0, hv024 == 2 ~ 1, hv024 == 3 ~ 2, hv024 == 4 ~ 3,
            hv024 == 5 ~ 4, hv024 == 6 ~ 5, hv024 == 7 ~ 6, hv024 == 8 ~ 7),
            levels = 0:7,
            labels = c("Barisal","Chittagong","Dhaka","Khulna",
                       "Mymensingh","Rajshahi","Rangpur","Sylhet")),
         area_res = factor(case_when(hv025 == 2 ~ 0, hv025 == 1 ~ 1),
                           levels = c(0, 1),
                           labels = c("Rural", "Urban")))

# Project onto 2017-18 sensitivity MCA dim-1: reapply 2017-18 factor levels so
# predict.MCA's indicator matrix matches.
for (v in art$inputs) {
  lv <- art$factor_levels[[v]]
  dat_22[[v]] <- factor(as.character(dat_22[[v]]), levels = lv)
}

new_in <- dat_22[, art$inputs]
stopifnot(all(complete.cases(new_in)))

proj <- predict(art$mca_se, newdata = new_in)
dat_22$scores_se <- as.numeric(proj$coord[, 1])

# Min-max scale using 2017-18 bounds; clip to [0, 1] for the few 2022 obs
# whose projection sits outside the 2017-18 range.
dat_22 <- dat_22 %>%
  mutate(scores_se_std = (scores_se - art$score_min) /
                         (art$score_max - art$score_min),
         scores_se_std = pmin(pmax(scores_se_std, 0), 1))

if (art$flip) {
  dat_22 <- dat_22 %>% mutate(scores_se_std = 1 - scores_se_std)
}

cuts <- art$quintile_cuts
cuts[1] <- -Inf; cuts[length(cuts)] <- Inf
dat_22 <- dat_22 %>%
  mutate(ncdvi_se = cut(scores_se_std, breaks = cuts, include.lowest = TRUE,
                        labels = c("Tier 1","Tier 2","Tier 3","Tier 4","Tier 5")))

dat_22 <- dat_22 %>% mutate(sampling_wgt = hv005 / 1e6)
prev_tier <- dat_22 %>%
  group_by(ncdvi_se) %>%
  summarise(n = n(),
            htn_n = sum(hyper == "Yes"),
            prev_unwt = mean(hyper == "Yes"),
            prev_wt   = weighted.mean(hyper == "Yes", w = sampling_wgt),
            .groups = "drop")

des <- svydesign(id = ~hv021, strata = ~hv023,
                 weights = ~sampling_wgt, data = dat_22, nest = TRUE)
fit_unadj <- svyglm(hyper ~ ncdvi_se, design = des, family = quasibinomial())

# Drop `sex` since the sample is women-only; everything else mirrors 2017-18.
confounders_22 <- c("diabetic", "age_cat", "educ", "marital_status",
                    "wealth_index", "division", "area_res")
rhs <- paste(confounders_22, collapse = " + ")
fit_adj <- svyglm(as.formula(paste("hyper ~ ncdvi_se +", rhs)),
                  design = des, family = quasibinomial())

extract_tier_or <- function(fit, idx = "ncdvi_se") {
  cf <- summary(fit)$coef
  rows <- grep(paste0("^", idx, "Tier"), rownames(cf))
  data.frame(tier = sub(paste0("^", idx), "", rownames(cf)[rows]),
             OR   = round(exp(cf[rows, 1]), 2),
             lo95 = round(exp(cf[rows, 1] - 1.96 * cf[rows, 2]), 2),
             hi95 = round(exp(cf[rows, 1] + 1.96 * cf[rows, 2]), 2),
             p    = signif(cf[rows, 4], 3))
}
or_unadj <- extract_tier_or(fit_unadj)
or_adj   <- extract_tier_or(fit_adj)

saveRDS(list(run_at         = Sys.time(),
             sample_n       = nrow(dat_22),
             htn_n          = sum(dat_22$hyper == "Yes"),
             htn_prev       = mean(dat_22$hyper == "Yes"),
             tier_n         = table(dat_22$ncdvi_se),
             prev_by_tier   = prev_tier,
             or_unadjusted  = or_unadj,
             or_adjusted    = or_adj,
             score_summary  = summary(dat_22$scores_se_std),
             projection_artifact = art),
        "outputs/phase8c_validation.rds")

saveRDS(dat_22, "outputs/phase8c_dat_2022.rds")
