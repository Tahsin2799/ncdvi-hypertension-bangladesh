# Bootstrap optimism correction (Harrell). B=200, primary NCDVI only.
# Uses glm (single-level) — at ICC ~0.045 the cluster intercept barely shifts
# fixed-effects predictions, and population-averaged-on-zero-random-effect
# predictions are numerically very close to a same-fixed-effects glm.

source("R/sensitivity_ncdvi.R")
library(pROC)

set.seed(20260516)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
strip_labels <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(x)
  attr(x, "labels") <- NULL; attr(x, "label") <- NULL
  attr(x, "format.stata") <- NULL; x
}
mv <- c("hyper", "ncdvi", "sampling_wgt", confounders)
d <- as.data.frame(dat_18)[, mv]
d$hyper <- as.numeric(d$hyper == "Yes")
for (v in names(d)) d[[v]] <- strip_labels(d[[v]])

form <- as.formula(paste("hyper ~ ncdvi +",
                         paste(confounders, collapse = " + ")))

fit_app <- glm(form, data = d, weights = sampling_wgt,
               family = binomial(link = "logit"))
prob_app <- predict(fit_app, type = "response")
auc_app  <- as.numeric(auc(roc(d$hyper, prob_app, quiet = TRUE)))

calib_lm <- function(prob, y) {
  prob <- pmin(pmax(prob, 1e-6), 1 - 1e-6)
  lp <- log(prob / (1 - prob))
  m <- glm(y ~ lp, family = binomial)
  c(intercept = unname(coef(m)[1]), slope = unname(coef(m)[2]))
}
calib_app <- calib_lm(prob_app, d$hyper)

B <- 200
opt_auc <- numeric(B)
opt_int <- numeric(B)
opt_slp <- numeric(B)

for (b in seq_len(B)) {
  idx   <- sample(seq_len(nrow(d)), replace = TRUE)
  d_b   <- d[idx, ]
  fit_b <- suppressWarnings(
    glm(form, data = d_b, weights = sampling_wgt,
        family = binomial(link = "logit"))
  )
  p_boot <- predict(fit_b, newdata = d_b, type = "response")
  p_orig <- predict(fit_b, newdata = d,   type = "response")

  auc_boot <- as.numeric(auc(roc(d_b$hyper, p_boot, quiet = TRUE)))
  auc_orig <- as.numeric(auc(roc(d$hyper,   p_orig, quiet = TRUE)))
  opt_auc[b] <- auc_boot - auc_orig

  cb <- calib_lm(p_boot, d_b$hyper)
  co <- calib_lm(p_orig, d$hyper)
  opt_int[b] <- cb["intercept"] - co["intercept"]
  opt_slp[b] <- cb["slope"]     - co["slope"]
}

mean_opt_auc <- mean(opt_auc)
mean_opt_int <- mean(opt_int)
mean_opt_slp <- mean(opt_slp)

auc_corr       <- auc_app - mean_opt_auc
calib_int_corr <- calib_app["intercept"] - mean_opt_int
calib_slp_corr <- calib_app["slope"]     - mean_opt_slp

saveRDS(list(
  auc_apparent    = auc_app,
  auc_corrected   = auc_corr,
  optimism_auc    = mean_opt_auc,
  optimism_auc_sd = sd(opt_auc),
  calib_apparent  = calib_app,
  calib_corrected = c(intercept = calib_int_corr, slope = calib_slp_corr),
  optimism_calib  = c(intercept = mean_opt_int, slope = mean_opt_slp),
  B = B,
  opt_auc_raw = opt_auc),
  "outputs/phase4b_bootstrap.rds")
