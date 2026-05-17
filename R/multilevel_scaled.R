# WeMix with PSU-scaled level-1 weights (RH&S 2006).
#   Method A (size scaling):  wt1_A = wt1 * n_j / sum(wt1)         -> sums to n_j
#   Method B (effective n):   wt1_B = wt1 * sum(wt1) / sum(wt1^2)  -> sums to eff_n
# wt2 unchanged. In DHS the within-PSU weights are nearly uniform so A == B.

source("R/sensitivity_ncdvi.R")
library(WeMix)
library(dplyr)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
strip_labels <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(x)
  attr(x, "labels") <- NULL
  attr(x, "label") <- NULL
  attr(x, "format.stata") <- NULL
  x
}
model_vars <- c("hyper", "ncdvi", "ncdvi_se", "hv021", "wt1", "wt2", confounders)
dat_mlm <- as.data.frame(dat_18)[, model_vars]
dat_mlm$hyper <- as.numeric(dat_mlm$hyper == "Yes")
for (v in names(dat_mlm)) dat_mlm[[v]] <- strip_labels(dat_mlm[[v]])

dat_mlm <- dat_mlm %>%
  group_by(hv021) %>%
  mutate(n_j        = dplyr::n(),
         sum_w1     = sum(wt1),
         sum_w1_sq  = sum(wt1^2),
         wt1_A      = wt1 * n_j / sum_w1,
         wt1_B      = wt1 * sum_w1 / sum_w1_sq) %>%
  ungroup() %>%
  as.data.frame()

rhs <- paste(c(confounders, "(1|hv021)"), collapse = " + ")
form_p <- as.formula(paste("hyper ~ ncdvi +",    rhs))
form_s <- as.formula(paste("hyper ~ ncdvi_se +", rhs))

fit_wemix <- function(form, w1col) {
  d <- dat_mlm
  d$wt1_use <- d[[w1col]]
  mix(form, data = d, weights = c("wt1_use", "wt2"),
      family = binomial(link = "logit"), verbose = FALSE)
}

extract_summary <- function(fit, idx) {
  cf <- fit$coef; se <- fit$SE
  rows <- grep(paste0("^", idx, "Tier"), names(cf))
  ors <- data.frame(
    tier = sub(paste0("^", idx), "", names(cf)[rows]),
    OR   = round(exp(cf[rows]), 2),
    lo95 = round(exp(cf[rows] - 1.96 * se[rows]), 2),
    hi95 = round(exp(cf[rows] + 1.96 * se[rows]), 2))
  sigma2 <- as.numeric(fit$vars[1])
  icc    <- sigma2 / (sigma2 + pi^2 / 3)
  list(sigma2 = sigma2, icc = icc, ors = ors)
}

fit_A_p <- fit_wemix(form_p, "wt1_A")
fit_A_s <- fit_wemix(form_s, "wt1_A")
fit_B_p <- fit_wemix(form_p, "wt1_B")
fit_B_s <- fit_wemix(form_s, "wt1_B")

s_A_p <- extract_summary(fit_A_p, "ncdvi")
s_A_s <- extract_summary(fit_A_s, "ncdvi_se")
s_B_p <- extract_summary(fit_B_p, "ncdvi")
s_B_s <- extract_summary(fit_B_s, "ncdvi_se")

phase3   <- readRDS("outputs/phase3_multilevel.rds")
glmer_cc <- readRDS("outputs/phase3b_glmer_crosscheck.rds")

baseline_p <- list(sigma2 = phase3$icc_primary$sigma2_u,
                   icc    = phase3$icc_primary$icc,
                   tier5  = with(phase3$or_wemix_primary,
                                 paste0(OR[tier=="Tier 5"], " (",
                                        lo95[tier=="Tier 5"], "-",
                                        hi95[tier=="Tier 5"], ")")))
baseline_s <- list(sigma2 = phase3$icc_sensitivity$sigma2_u,
                   icc    = phase3$icc_sensitivity$icc,
                   tier5  = with(phase3$or_wemix_sensitivity,
                                 paste0(OR[tier=="Tier 5"], " (",
                                        lo95[tier=="Tier 5"], "-",
                                        hi95[tier=="Tier 5"], ")")))
tier5_str <- function(s) {
  t5 <- s$ors[s$ors$tier == "Tier 5", ]
  if (nrow(t5) == 0) return(NA_character_)
  paste0(t5$OR, " (", t5$lo95, "-", t5$hi95, ")")
}

comparison <- data.frame(
  fit = c("WeMix baseline (unscaled)", "WeMix Method A (size)",
          "WeMix Method B (eff n)", "glmer (freq weights, ref)"),
  sigma2_primary   = round(c(baseline_p$sigma2, s_A_p$sigma2, s_B_p$sigma2,
                             glmer_cc$glmer_sigma2), 3),
  ICC_primary      = round(c(baseline_p$icc,    s_A_p$icc,    s_B_p$icc,
                             glmer_cc$glmer_icc), 3),
  Tier5_OR_primary = c(baseline_p$tier5,    tier5_str(s_A_p), tier5_str(s_B_p),
                       NA_character_),
  sigma2_sens      = round(c(baseline_s$sigma2, s_A_s$sigma2, s_B_s$sigma2,
                             NA_real_), 3),
  ICC_sens         = round(c(baseline_s$icc,    s_A_s$icc,    s_B_s$icc,
                             NA_real_), 3),
  Tier5_OR_sens    = c(baseline_s$tier5,    tier5_str(s_A_s), tier5_str(s_B_s),
                       NA_character_)
)

saveRDS(list(comparison = comparison,
             method_A_primary     = s_A_p,
             method_A_sensitivity = s_A_s,
             method_B_primary     = s_B_p,
             method_B_sensitivity = s_B_s,
             fit_A_p_coef = fit_A_p$coef, fit_A_p_se = fit_A_p$SE,
             fit_A_s_coef = fit_A_s$coef, fit_A_s_se = fit_A_s$SE,
             fit_B_p_coef = fit_B_p$coef, fit_B_p_se = fit_B_p$SE,
             fit_B_s_coef = fit_B_s$coef, fit_B_s_se = fit_B_s$SE),
        "outputs/phase3c_scaled_weights.rds")
