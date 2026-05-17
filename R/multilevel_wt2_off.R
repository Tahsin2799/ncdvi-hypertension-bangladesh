# WeMix variance attribution: refit primary with wt2 == 1 to isolate the
# level-2 weight's contribution to the ICC inflation observed under raw PML.

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
model_vars <- c("hyper", "ncdvi", "hv021", "wt1", "wt2", confounders)
dat_mlm <- as.data.frame(dat_18)[, model_vars]
dat_mlm$hyper <- as.numeric(dat_mlm$hyper == "Yes")
for (v in names(dat_mlm)) dat_mlm[[v]] <- strip_labels(dat_mlm[[v]])

dat_mlm <- dat_mlm %>%
  group_by(hv021) %>%
  mutate(n_j     = dplyr::n(),
         wt1_A   = wt1 * n_j / sum(wt1)) %>%
  ungroup() %>%
  mutate(wt2_one = 1) %>%
  as.data.frame()

rhs <- paste(c(confounders, "(1|hv021)"), collapse = " + ")
form_p <- as.formula(paste("hyper ~ ncdvi +", rhs))

fit_wemix <- function(form, w1col, w2col) {
  d <- dat_mlm
  d$wt1_use <- d[[w1col]]
  d$wt2_use <- d[[w2col]]
  mix(form, data = d, weights = c("wt1_use", "wt2_use"),
      family = binomial(link = "logit"), verbose = FALSE)
}

extract_summary <- function(fit, idx = "ncdvi") {
  cf <- fit$coef; se <- fit$SE
  rows <- grep(paste0("^", idx, "Tier"), names(cf))
  ors <- data.frame(
    tier = sub(paste0("^", idx), "", names(cf)[rows]),
    OR   = round(exp(cf[rows]), 2),
    lo95 = round(exp(cf[rows] - 1.96 * se[rows]), 2),
    hi95 = round(exp(cf[rows] + 1.96 * se[rows]), 2))
  sigma2 <- as.numeric(fit$vars[1])
  list(sigma2 = sigma2, icc = sigma2 / (sigma2 + pi^2/3), ors = ors)
}

fit_c <- fit_wemix(form_p, "wt1",   "wt2_one")
fit_d <- fit_wemix(form_p, "wt1_A", "wt2_one")

s_c <- extract_summary(fit_c)
s_d <- extract_summary(fit_d)

phase3   <- readRDS("outputs/phase3_multilevel.rds")
phase3c  <- readRDS("outputs/phase3c_scaled_weights.rds")
glmer_cc <- readRDS("outputs/phase3b_glmer_crosscheck.rds")

t5 <- function(s) {
  r <- s$ors[s$ors$tier == "Tier 5", ]
  if (nrow(r) == 0) return(NA_character_)
  paste0(r$OR, " (", r$lo95, "-", r$hi95, ")")
}

cmp <- data.frame(
  fit = c("(a) baseline:   raw wt1, raw wt2",
          "(b) Phase 3c:   scaled wt1, raw wt2",
          "(c) Phase 3d.1: raw wt1, wt2 = 1",
          "(d) Phase 3d.2: scaled wt1, wt2 = 1",
          "(e) glmer (freq weights, reference)"),
  sigma2 = round(c(phase3$icc_primary$sigma2_u,
                   phase3c$method_A_primary$sigma2,
                   s_c$sigma2, s_d$sigma2,
                   glmer_cc$glmer_sigma2), 3),
  ICC    = round(c(phase3$icc_primary$icc,
                   phase3c$method_A_primary$icc,
                   s_c$icc, s_d$icc,
                   glmer_cc$glmer_icc), 3),
  Tier5_OR = c(with(phase3$or_wemix_primary,
                    paste0(OR[tier=="Tier 5"]," (",
                           lo95[tier=="Tier 5"],"-",hi95[tier=="Tier 5"],")")),
               with(phase3c$method_A_primary$ors,
                    paste0(OR[tier=="Tier 5"]," (",
                           lo95[tier=="Tier 5"],"-",hi95[tier=="Tier 5"],")")),
               t5(s_c), t5(s_d), NA_character_))

saveRDS(list(comparison = cmp,
             fit_c_summary = s_c, fit_d_summary = s_d,
             fit_c_coef = fit_c$coef, fit_c_se = fit_c$SE,
             fit_d_coef = fit_d$coef, fit_d_se = fit_d$SE),
        "outputs/phase3d_wt2_off.rds")
