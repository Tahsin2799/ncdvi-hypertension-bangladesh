# Decision curve analysis (net benefit) for the NCDVI hypertension models.
# Addresses the decision-utility gap: AUC + calibration alone do not show whether
# tier-based screening yields clinical/policy utility. Net benefit is computed with
# survey weights (population-representative) and from cross-validated out-of-fold
# predictions (optimism-corrected), per the method note in outputs/dca_method_note.md.
# Mirrors the CV protocol in R/validation.R and R/validate_2022_fit.R.

suppressPackageStartupMessages({
  library(dplyr)
  library(pROC)
  library(ggplot2)
})

set.seed(20260516)

## ---- weighted net benefit helpers -----------------------------------------
# Weights normalised to mean 1 so sum(w) = n (per-sampled-person scale).
nb_model <- function(p, y, w, thr) {
  w <- w / mean(w); sw <- sum(w)
  vapply(thr, function(t) {
    pos <- p >= t
    tp <- sum(w[pos & y == 1]); fp <- sum(w[pos & y == 0])
    tp / sw - fp / sw * (t / (1 - t))
  }, numeric(1))
}
nb_all <- function(y, w, thr) {
  w <- w / mean(w); sw <- sum(w)
  ev <- sum(w[y == 1]); ne <- sum(w[y == 0])
  ev / sw - ne / sw * (thr / (1 - thr))
}

thr <- seq(0.02, 0.50, by = 0.005)

# Stratified K-fold OOF predictions from a weighted glm (matches validation.R).
cv_oof <- function(form, dat, K = 10) {
  y <- dat$.y
  pos <- which(y == 1); neg <- which(y == 0)
  fold <- integer(nrow(dat))
  fold[pos] <- sample(rep(seq_len(K), length.out = length(pos)))
  fold[neg] <- sample(rep(seq_len(K), length.out = length(neg)))
  oof <- numeric(nrow(dat))
  for (k in seq_len(K)) {
    fit_k <- suppressWarnings(glm(form, data = dat[fold != k, ],
                                  weights = sampling_wgt,
                                  family = binomial(link = "logit")))
    oof[fold == k] <- predict(fit_k, newdata = dat[fold == k, ],
                              type = "response")
  }
  oof
}

# Range of thresholds over which a model's NB beats both reference strategies.
useful_range <- function(nb, nb_all_vec, thr) {
  better <- nb > pmax(nb_all_vec, 0) + 1e-9
  if (!any(better)) return(c(NA, NA))
  range(thr[better])
}

## ---- INTERNAL: BDHS 2017-18 ------------------------------------------------
source("R/sensitivity_ncdvi.R")   # -> dat_18 with ncdvi (10-input) + ncdvi_se (6-input)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
strip_labels <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(x)
  attr(x, "labels") <- attr(x, "label") <- attr(x, "format.stata") <- NULL
  x
}
mv <- c("hyper", "ncdvi", "ncdvi_se", "hv021", "sampling_wgt", confounders)
d18 <- as.data.frame(dat_18)[, mv]
d18$.y <- as.numeric(d18$hyper == "Yes")
for (v in names(d18)) d18[[v]] <- strip_labels(d18[[v]])

cf <- paste(confounders, collapse = " + ")
oof_p    <- cv_oof(as.formula(paste(".y ~ ncdvi +",    cf)), d18)
oof_s    <- cv_oof(as.formula(paste(".y ~ ncdvi_se +", cf)), d18)
oof_conf <- cv_oof(as.formula(paste(".y ~",            cf)), d18)

nb18 <- data.frame(
  threshold = thr,
  primary     = nb_model(oof_p,    d18$.y, d18$sampling_wgt, thr),
  sensitivity = nb_model(oof_s,    d18$.y, d18$sampling_wgt, thr),
  confounders = nb_model(oof_conf, d18$.y, d18$sampling_wgt, thr),
  treat_all   = nb_all(d18$.y, d18$sampling_wgt, thr),
  treat_none  = 0
)

## ---- EXTERNAL: BDHS 2022 ---------------------------------------------------
d22 <- as.data.frame(readRDS("outputs/phase8c_dat_2022.rds"))
d22$.y <- as.numeric(d22$hyper == "Yes")
conf22 <- c("diabetic", "age_cat", "educ", "marital_status",
            "wealth_index", "division", "area_res")
mv22 <- c(".y", "ncdvi_se", conf22, "hv021", "sampling_wgt")
d22 <- d22[complete.cases(d22[, mv22]), ]

cf22 <- paste(conf22, collapse = " + ")
oof_s22   <- cv_oof(as.formula(paste(".y ~ ncdvi_se +", cf22)), d22)
oof_c22   <- cv_oof(as.formula(paste(".y ~",            cf22)), d22)

nb22 <- data.frame(
  threshold = thr,
  sensitivity = nb_model(oof_s22, d22$.y, d22$sampling_wgt, thr),
  confounders = nb_model(oof_c22, d22$.y, d22$sampling_wgt, thr),
  treat_all   = nb_all(d22$.y, d22$sampling_wgt, thr),
  treat_none  = 0
)

## ---- figures ---------------------------------------------------------------
mk_plot <- function(df, cols, labs, title, sub) {
  long <- do.call(rbind, lapply(names(cols), function(k)
    data.frame(threshold = df$threshold, nb = df[[k]], strategy = cols[[k]])))
  long$strategy <- factor(long$strategy, levels = unname(unlist(cols)))
  ggplot(long, aes(threshold, nb, color = strategy, linetype = strategy)) +
    geom_line(linewidth = 0.8) +
    coord_cartesian(ylim = c(-0.02, max(df$treat_all, df$primary %||% 0,
                                        df$sensitivity) * 1.05)) +
    labs(x = "Threshold probability", y = "Net benefit",
         title = title, subtitle = sub, color = NULL, linetype = NULL) +
    theme_minimal(base_size = 11) + theme(legend.position = "bottom")
}
`%||%` <- function(a, b) if (is.null(a)) b else a

p18 <- mk_plot(nb18,
  list(primary = "Primary 10-input NCDVI", sensitivity = "Sensitivity 6-input NCDVI",
       confounders = "Confounders only", treat_all = "Treat all", treat_none = "Treat none"),
  NULL,
  "Decision curve analysis: NCDVI hypertension models (BDHS 2017-18)",
  "Survey-weighted net benefit from 10-fold cross-validated predictions")
ggsave("Figures/phase9_dca_internal.png", p18, width = 6.5, height = 5, dpi = 200)

p22 <- mk_plot(nb22,
  list(sensitivity = "Sensitivity 6-input NCDVI", confounders = "Confounders only",
       treat_all = "Treat all", treat_none = "Treat none"),
  NULL,
  "Decision curve analysis: external validation (BDHS 2022, women 18+)",
  "Survey-weighted net benefit from 10-fold cross-validated predictions")
ggsave("Figures/phase9_dca_external.png", p22, width = 6.5, height = 5, dpi = 200)

## ---- summary numbers -------------------------------------------------------
rep_thr <- c(0.10, 0.20, 0.30)
at <- function(df, col, t) df[[col]][which.min(abs(df$threshold - t))]

ur_p   <- useful_range(nb18$primary,     pmax(nb18$treat_all, 0), thr)
ur_s   <- useful_range(nb18$sensitivity, pmax(nb18$treat_all, 0), thr)
ur_s22 <- useful_range(nb22$sensitivity, pmax(nb22$treat_all, 0), thr)

cat("\n================ DECISION CURVE ANALYSIS ================\n")
cat(sprintf("Internal N=%d  prev=%.3f | External N=%d prev=%.3f\n",
            nrow(d18), mean(d18$.y), nrow(d22), mean(d22$.y)))
cat("\n-- Net benefit at representative thresholds (internal) --\n")
for (t in rep_thr) cat(sprintf(
  "  t=%.2f: primary=%.4f  sensitivity=%.4f  confounders=%.4f  treat-all=%.4f\n",
  t, at(nb18,"primary",t), at(nb18,"sensitivity",t),
  at(nb18,"confounders",t), at(nb18,"treat_all",t)))
cat("\n-- Net benefit at representative thresholds (external 6-input) --\n")
for (t in rep_thr) cat(sprintf(
  "  t=%.2f: sensitivity=%.4f  confounders=%.4f  treat-all=%.4f\n",
  t, at(nb22,"sensitivity",t), at(nb22,"confounders",t), at(nb22,"treat_all",t)))
cat(sprintf("\nThreshold range where model beats treat-all & treat-none:\n"))
cat(sprintf("  internal primary:     %.3f to %.3f\n", ur_p[1], ur_p[2]))
cat(sprintf("  internal sensitivity: %.3f to %.3f\n", ur_s[1], ur_s[2]))
cat(sprintf("  external sensitivity: %.3f to %.3f\n", ur_s22[1], ur_s22[2]))

saveRDS(list(thr = thr, internal = nb18, external = nb22,
             useful_range = list(primary = ur_p, sensitivity = ur_s,
                                 external_sensitivity = ur_s22),
             run_at = Sys.time()),
        "outputs/phase9_dca.rds")
cat("\nSaved outputs/phase9_dca.rds, Figures/phase9_dca_internal.png, Figures/phase9_dca_external.png\n")
