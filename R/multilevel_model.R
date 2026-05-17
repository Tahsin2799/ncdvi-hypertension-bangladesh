# Multilevel logistic regression: NCDVI -> hypertension.
# Primary spec: lme4::glmer with DHS sample weights as frequency weights
# (matches BDHS HTN literature, ICC in the published 0.05-0.15 range).
# Sensitivity spec: WeMix::mix PML with PSU-scaled level-1 weights and raw
# level-2 weights (Rabe-Hesketh & Skrondal 2006), reported as Supplementary.

source("R/sensitivity_ncdvi.R")
library(lme4)
library(WeMix)
library(broom.helpers)
library(dplyr)

stopifnot(all(c("wt1", "wt2") %in% names(dat_18)),
          !anyNA(dat_18$wt1), !anyNA(dat_18$wt2))

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
rhs <- paste(c(confounders, "(1|hv021)"), collapse = " + ")

# WeMix fails with "no rows to aggregate" when haven_labelled attributes are
# attached to any column in the data frame, even columns not in the formula.
# Strip labels and subset to model variables.
strip_labels <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(x)
  attr(x, "labels") <- NULL
  attr(x, "label") <- NULL
  attr(x, "format.stata") <- NULL
  x
}
model_vars <- c("hyper", "ncdvi", "ncdvi_se", "hv021", "wt1", "wt2",
                "sampling_wgt", confounders)
dat_mlm <- as.data.frame(dat_18)[, model_vars]
dat_mlm$hyper <- as.numeric(dat_mlm$hyper == "Yes")
for (v in names(dat_mlm)) dat_mlm[[v]] <- strip_labels(dat_mlm[[v]])

# PSU-scaled level-1 weight for the WeMix sensitivity (Method A).
dat_mlm <- dat_mlm %>%
  group_by(hv021) %>%
  mutate(n_j  = dplyr::n(),
         wt1s = wt1 * n_j / sum(wt1)) %>%
  ungroup() %>%
  as.data.frame()

form_p <- as.formula(paste("hyper ~ ncdvi +",    rhs))
form_s <- as.formula(paste("hyper ~ ncdvi_se +", rhs))

# primary: glmer
fit_glmer_primary <- glmer(form_p, data = dat_mlm, weights = sampling_wgt,
                           family = binomial(link = "logit"))
fit_glmer_sens <- glmer(form_s, data = dat_mlm, weights = sampling_wgt,
                        family = binomial(link = "logit"))

# sensitivity: WeMix PML, scaled wt1
fit_wemix_primary <- mix(form_p, data = dat_mlm,
                         weights = c("wt1s", "wt2"),
                         family = binomial(link = "logit"), verbose = FALSE)
fit_wemix_sens <- mix(form_s, data = dat_mlm,
                      weights = c("wt1s", "wt2"),
                      family = binomial(link = "logit"), verbose = FALSE)

extract_icc_glmer <- function(fit) {
  vc <- VarCorr(fit)
  sigma2 <- as.numeric(vc$hv021[1])
  list(sigma2_u = sigma2, icc = sigma2 / (sigma2 + pi^2 / 3))
}

extract_icc_wemix <- function(fit) {
  vc <- fit$vars
  sigma2 <- as.numeric(vc[1])
  se_var <- as.numeric(fit$varVC[[1]])
  if (!is.null(se_var) && !is.na(se_var) && se_var > 0) {
    lo <- max(sigma2 - 1.96 * se_var, 1e-6)
    hi <- sigma2 + 1.96 * se_var
    icc_lo <- lo / (lo + pi^2 / 3)
    icc_hi <- hi / (hi + pi^2 / 3)
  } else {
    icc_lo <- icc_hi <- NA_real_
  }
  list(sigma2_u = sigma2,
       icc = sigma2 / (sigma2 + pi^2 / 3),
       icc_lo = icc_lo, icc_hi = icc_hi)
}

tier_ors_glmer <- function(fit, idx) {
  cf <- summary(fit)$coef
  rows <- grep(paste0("^", idx, "Tier"), rownames(cf))
  data.frame(
    tier = sub(paste0("^", idx), "", rownames(cf)[rows]),
    OR   = round(exp(cf[rows, 1]), 2),
    lo95 = round(exp(cf[rows, 1] - 1.96 * cf[rows, 2]), 2),
    hi95 = round(exp(cf[rows, 1] + 1.96 * cf[rows, 2]), 2))
}

tier_ors_wemix <- function(fit, idx) {
  cf <- fit$coef; se <- fit$SE
  rows <- grep(paste0("^", idx, "Tier"), names(cf))
  data.frame(
    tier = sub(paste0("^", idx), "", names(cf)[rows]),
    OR   = round(exp(cf[rows]), 2),
    lo95 = round(exp(cf[rows] - 1.96 * se[rows]), 2),
    hi95 = round(exp(cf[rows] + 1.96 * se[rows]), 2))
}

icc_glmer_p <- extract_icc_glmer(fit_glmer_primary)
icc_glmer_s <- extract_icc_glmer(fit_glmer_sens)
icc_wemix_p <- extract_icc_wemix(fit_wemix_primary)
icc_wemix_s <- extract_icc_wemix(fit_wemix_sens)

or_glmer_p <- tier_ors_glmer(fit_glmer_primary, "ncdvi")
or_glmer_s <- tier_ors_glmer(fit_glmer_sens,    "ncdvi_se")
or_wemix_p <- tier_ors_wemix(fit_wemix_primary, "ncdvi")
or_wemix_s <- tier_ors_wemix(fit_wemix_sens,    "ncdvi_se")

saveRDS(list(
  primary_glmer_11      = list(icc = icc_glmer_p, ors = or_glmer_p,
                               coef = summary(fit_glmer_primary)$coef),
  primary_glmer_7       = list(icc = icc_glmer_s, ors = or_glmer_s,
                               coef = summary(fit_glmer_sens)$coef),
  sensitivity_wemix_11  = list(icc = icc_wemix_p, ors = or_wemix_p,
                               coef = fit_wemix_primary$coef,
                               se   = fit_wemix_primary$SE),
  sensitivity_wemix_7   = list(icc = icc_wemix_s, ors = or_wemix_s,
                               coef = fit_wemix_sens$coef,
                               se   = fit_wemix_sens$SE)),
  "outputs/phase3_multilevel.rds")

multimod_tab <- tbl_regression(fit_glmer_primary, exponentiate = TRUE) %>%
  bold_labels() %>%
  bold_p() %>%
  modify_footnote(... = list(everything() ~ NA), abbreviation = TRUE)

multimod <- fit_glmer_primary
multimod_glmer <- fit_glmer_primary
