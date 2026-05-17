# Internal validation (TRIPOD): AUC + CV + calibration on glmer primary and
# sensitivity NCDVI. Fixed-effects-only prediction (re.form = NA) for glmer —
# ICC 0.045 means the divergence from the proper marginalisation is negligible.

source("R/sensitivity_ncdvi.R")
library(lme4)
library(pROC)
library(dplyr)
library(ggplot2)

set.seed(20260516)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
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

rhs <- paste(c(confounders, "(1|hv021)"), collapse = " + ")
fit_glmer_primary <- glmer(as.formula(paste("hyper ~ ncdvi +",    rhs)),
                           data = dat_mlm, weights = sampling_wgt,
                           family = binomial(link = "logit"))
fit_glmer_sens    <- glmer(as.formula(paste("hyper ~ ncdvi_se +", rhs)),
                           data = dat_mlm, weights = sampling_wgt,
                           family = binomial(link = "logit"))

pred_df <- dat_mlm
pred_df$prob_p <- predict(fit_glmer_primary, newdata = pred_df,
                          type = "response", re.form = NA)
pred_df$prob_s <- predict(fit_glmer_sens,    newdata = pred_df,
                          type = "response", re.form = NA)

form_conf <- as.formula(paste("hyper ~",
                              paste(confounders, collapse = " + ")))
fit_conf <- glm(form_conf, data = pred_df,
                weights = sampling_wgt, family = binomial(link = "logit"))
pred_df$prob_conf <- predict(fit_conf, newdata = pred_df, type = "response")

# apparent AUC
roc_p    <- roc(pred_df$hyper, pred_df$prob_p,    quiet = TRUE)
roc_s    <- roc(pred_df$hyper, pred_df$prob_s,    quiet = TRUE)
roc_conf <- roc(pred_df$hyper, pred_df$prob_conf, quiet = TRUE)

auc_p    <- ci.auc(roc_p,    method = "delong")
auc_s    <- ci.auc(roc_s,    method = "delong")
auc_conf <- ci.auc(roc_conf, method = "delong")

delong_p_vs_conf <- roc.test(roc_p, roc_conf, method = "delong", paired = TRUE)
delong_s_vs_conf <- roc.test(roc_s, roc_conf, method = "delong", paired = TRUE)

# 10-fold CV (glm for tractability; stratified by outcome)
K <- 10
pred_df$fold <- {
  pos <- which(pred_df$hyper == 1)
  neg <- which(pred_df$hyper == 0)
  f <- integer(nrow(pred_df))
  f[pos] <- sample(rep(seq_len(K), length.out = length(pos)))
  f[neg] <- sample(rep(seq_len(K), length.out = length(neg)))
  f
}

form_p_glm <- as.formula(paste("hyper ~ ncdvi +",
                               paste(confounders, collapse = " + ")))
form_s_glm <- as.formula(paste("hyper ~ ncdvi_se +",
                               paste(confounders, collapse = " + ")))

cv_predict <- function(form) {
  pred_oof <- numeric(nrow(pred_df))
  fold_aucs <- numeric(K)
  for (k in seq_len(K)) {
    train <- pred_df[pred_df$fold != k, ]
    test  <- pred_df[pred_df$fold == k, ]
    fit_k <- glm(form, data = train, weights = sampling_wgt,
                 family = binomial(link = "logit"))
    p_k <- predict(fit_k, newdata = test, type = "response")
    pred_oof[pred_df$fold == k] <- p_k
    fold_aucs[k] <- as.numeric(auc(roc(test$hyper, p_k, quiet = TRUE)))
  }
  list(pred = pred_oof, fold_aucs = fold_aucs)
}

cv_p    <- cv_predict(form_p_glm)
cv_s    <- cv_predict(form_s_glm)
cv_conf <- cv_predict(form_conf)

cv_auc_p    <- ci.auc(roc(pred_df$hyper, cv_p$pred,    quiet = TRUE), method = "delong")
cv_auc_s    <- ci.auc(roc(pred_df$hyper, cv_s$pred,    quiet = TRUE), method = "delong")
cv_auc_conf <- ci.auc(roc(pred_df$hyper, cv_conf$pred, quiet = TRUE), method = "delong")

# calibration by decile
calib_decile <- function(prob, y, model_label) {
  d <- data.frame(prob = prob, y = y)
  d$decile <- ntile(d$prob, 10)
  d %>% group_by(decile) %>%
    summarise(n = dplyr::n(),
              pred = mean(prob),
              obs  = mean(y),
              se   = sqrt(mean(y) * (1 - mean(y)) / dplyr::n()),
              .groups = "drop") %>%
    mutate(model = model_label)
}

calib_p_apparent <- calib_decile(pred_df$prob_p, pred_df$hyper, "Apparent (full-sample)")
calib_p_cv       <- calib_decile(cv_p$pred,      pred_df$hyper, "10-fold CV")

calib_plot <- ggplot(bind_rows(calib_p_apparent, calib_p_cv),
                     aes(x = pred, y = obs, color = model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = obs - 1.96 * se, ymax = obs + 1.96 * se),
                width = 0.01, alpha = 0.6) +
  geom_point(size = 2) +
  geom_line(alpha = 0.5) +
  scale_x_continuous(limits = c(0, 1)) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Mean predicted probability (decile)",
       y = "Observed hypertension prevalence (decile)",
       title = "NCDVI calibration: primary 10-input model",
       color = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("Figures/phase4_calibration.png", calib_plot,
       width = 6.5, height = 5, dpi = 200)

# calibration intercept and slope (logit recalibration)
calib_lm <- function(prob, y) {
  prob <- pmin(pmax(prob, 1e-6), 1 - 1e-6)
  lp <- log(prob / (1 - prob))
  m <- glm(y ~ lp, family = binomial)
  list(intercept = unname(coef(m)[1]), slope = unname(coef(m)[2]))
}
cs_apparent <- calib_lm(pred_df$prob_p, pred_df$hyper)
cs_cv       <- calib_lm(cv_p$pred,      pred_df$hyper)

saveRDS(list(
  apparent = list(auc_conf = auc_conf,
                  auc_primary = auc_p, auc_sensitivity = auc_s,
                  delong_p_vs_conf = delong_p_vs_conf,
                  delong_s_vs_conf = delong_s_vs_conf),
  cv10 = list(auc_conf = cv_auc_conf,
              auc_primary = cv_auc_p, auc_sensitivity = cv_auc_s,
              fold_aucs_conf = cv_conf$fold_aucs,
              fold_aucs_primary = cv_p$fold_aucs,
              fold_aucs_sensitivity = cv_s$fold_aucs,
              oof_primary = cv_p$pred, oof_sensitivity = cv_s$pred,
              oof_conf = cv_conf$pred),
  calibration = list(deciles_apparent = calib_p_apparent,
                     deciles_cv       = calib_p_cv,
                     intercept_slope_apparent = cs_apparent,
                     intercept_slope_cv       = cs_cv)),
  "outputs/phase4_validation.rds")
