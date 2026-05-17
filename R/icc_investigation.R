# ICC investigation: Mundlak (PSU-mean covariates), higher nQuad, and
# svylme::svy2relmer cross-check against the WeMix variance estimate.

source("R/sensitivity_ncdvi.R")
library(WeMix)
library(svylme)
library(survey)
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
model_vars <- c("hyper", "ncdvi", "hv021", "wt1", "wt2", confounders)
dat_mlm <- as.data.frame(dat_18)[, model_vars]
dat_mlm$hyper <- as.numeric(dat_mlm$hyper == "Yes")
for (v in names(dat_mlm)) dat_mlm[[v]] <- strip_labels(dat_mlm[[v]])

rhs <- paste(c(confounders, "(1|hv021)"), collapse = " + ")
form_base <- as.formula(paste("hyper ~ ncdvi +", rhs))

phase3 <- readRDS("outputs/phase3_multilevel.rds")
sigma2_baseline <- phase3$icc_primary$sigma2_u
icc_baseline    <- phase3$icc_primary$icc

# Mundlak: PSU-means of the most plausible between-PSU confounders.
dat_mlm <- dat_mlm %>%
  mutate(ncdvi_num    = as.numeric(ncdvi),
         diabetic_num = as.numeric(diabetic == "Yes"),
         wealth_num   = as.numeric(wealth_index)) %>%
  group_by(hv021) %>%
  mutate(psu_mean_ncdvi    = mean(ncdvi_num,    na.rm = TRUE),
         psu_mean_diabetic = mean(diabetic_num, na.rm = TRUE),
         psu_mean_wealth   = mean(wealth_num,   na.rm = TRUE)) %>%
  ungroup() %>%
  as.data.frame()

rhs_mundlak <- paste(c(confounders,
                       "psu_mean_ncdvi", "psu_mean_diabetic", "psu_mean_wealth",
                       "(1|hv021)"), collapse = " + ")
form_mundlak <- as.formula(paste("hyper ~ ncdvi +", rhs_mundlak))

fit_mundlak <- mix(form_mundlak,
                   data    = dat_mlm,
                   weights = c("wt1", "wt2"),
                   family  = binomial(link = "logit"),
                   verbose = FALSE)
sigma2_mundlak <- as.numeric(fit_mundlak$vars[1])
icc_mundlak    <- sigma2_mundlak / (sigma2_mundlak + pi^2 / 3)

# higher nQuad
fit_nq21 <- mix(form_base,
                data    = dat_mlm,
                weights = c("wt1", "wt2"),
                family  = binomial(link = "logit"),
                nQuad   = 21,
                verbose = FALSE)
sigma2_nq21 <- as.numeric(fit_nq21$vars[1])
icc_nq21    <- sigma2_nq21 / (sigma2_nq21 + pi^2 / 3)

# svylme cross-check (single-stage design with wt1)
des_svy <- svydesign(ids = ~hv021, weights = ~wt1, data = dat_mlm, nest = TRUE)
fit_svy <- tryCatch(
  svy2relmer(form_base, design = des_svy, sterr = FALSE),
  error = function(e) NULL)

if (!is.null(fit_svy)) {
  vc_svy <- tryCatch({
    vc <- fit_svy$opt$par   # theta in lme4 param = sd(u) / sigma
    (vc[1]^2) * (pi^2 / 3)  # logit residual is pi^2/3
  }, error = function(e) NA_real_)
  sigma2_svy <- vc_svy
  icc_svy    <- if (is.na(sigma2_svy)) NA_real_ else sigma2_svy / (sigma2_svy + pi^2 / 3)
} else {
  sigma2_svy <- NA_real_
  icc_svy    <- NA_real_
}

extract_tier5_or <- function(fit) {
  cf <- fit$coef; se <- fit$SE
  i  <- grep("^ncdviTier 5", names(cf))
  if (length(i) == 0) return(c(NA, NA, NA))
  c(OR   = exp(cf[i]),
    lo95 = exp(cf[i] - 1.96 * se[i]),
    hi95 = exp(cf[i] + 1.96 * se[i]))
}
or5_baseline <- with(phase3$or_wemix_primary,
                     setNames(c(OR[tier == "Tier 5"], lo95[tier == "Tier 5"], hi95[tier == "Tier 5"]),
                              c("OR", "lo95", "hi95")))
or5_mundlak  <- extract_tier5_or(fit_mundlak)
or5_nq21     <- extract_tier5_or(fit_nq21)

summary_tab <- data.frame(
  model = c("baseline (Phase 3)", "Mundlak (PSU means)", "nQuad=21", "svylme::svy2relmer"),
  sigma2_u = round(c(sigma2_baseline, sigma2_mundlak, sigma2_nq21, sigma2_svy), 3),
  ICC      = round(c(icc_baseline,    icc_mundlak,    icc_nq21,    icc_svy), 3),
  Tier5_OR = c(unname(or5_baseline["OR"]),
               unname(or5_mundlak["OR"]),
               unname(or5_nq21["OR"]),
               NA_real_),
  Tier5_lo = c(unname(or5_baseline["lo95"]),
               unname(or5_mundlak["lo95"]),
               unname(or5_nq21["lo95"]),
               NA_real_),
  Tier5_hi = c(unname(or5_baseline["hi95"]),
               unname(or5_mundlak["hi95"]),
               unname(or5_nq21["hi95"]),
               NA_real_)
)

saveRDS(list(summary       = summary_tab,
             fit_mundlak   = fit_mundlak,
             fit_nq21      = fit_nq21,
             fit_svy       = fit_svy),
        "outputs/phase3b_icc_investigation.rds")
