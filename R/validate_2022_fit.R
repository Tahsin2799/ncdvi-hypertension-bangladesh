# External multilevel fit on the BDHS 2022 frame produced by validate_2022.R.
# Two specs: 5-tier (as projected) and 4-tier (Tier 4 + Tier 5 collapsed; the
# top tier has N=55 which destabilises the 5-tier random-effects fit).
# sex dropped (women-only sample).

suppressPackageStartupMessages({
  library(dplyr)
  library(lme4)
  library(pROC)
  library(ggplot2)
})

set.seed(20260516)

dat <- as.data.frame(readRDS("outputs/phase8c_dat_2022.rds"))
dat$y <- as.numeric(dat$hyper == "Yes")

# Drop the 2 rows with NA in educ so glmer's analysis frame and the data frame
# stay aligned (otherwise predict() returns the wrong nrow).
mvars <- c("y", "ncdvi_se", "diabetic", "age_cat", "educ", "marital_status",
           "wealth_index", "division", "area_res", "hv021", "sampling_wgt")
dat <- dat[complete.cases(dat[, mvars]), ]

dat$ncdvi_se4 <- forcats::fct_collapse(
  dat$ncdvi_se,
  "Tier 4-5" = c("Tier 4", "Tier 5")
)

confounders_22 <- c("diabetic", "age_cat", "educ", "marital_status",
                    "wealth_index", "division", "area_res")
rhs <- paste(c(confounders_22, "(1|hv021)"), collapse = " + ")

form5 <- as.formula(paste("y ~ ncdvi_se +",  rhs))
form4 <- as.formula(paste("y ~ ncdvi_se4 +", rhs))

fit5 <- glmer(form5, data = dat, weights = sampling_wgt,
              family = binomial(link = "logit"),
              control = glmerControl(optimizer = "bobyqa",
                                     optCtrl = list(maxfun = 2e5)))
fit4 <- glmer(form4, data = dat, weights = sampling_wgt,
              family = binomial(link = "logit"),
              control = glmerControl(optimizer = "bobyqa",
                                     optCtrl = list(maxfun = 2e5)))

extract_icc <- function(fit) {
  vc <- VarCorr(fit)
  s2 <- as.numeric(vc$hv021[1])
  list(sigma2_u = s2, icc = s2 / (s2 + pi^2 / 3))
}

tier_ors <- function(fit, idx) {
  cf <- summary(fit)$coef
  rows <- grep(paste0("^", idx, "Tier"), rownames(cf))
  data.frame(
    tier = sub(paste0("^", idx), "", rownames(cf)[rows]),
    OR   = round(exp(cf[rows, 1]), 2),
    lo95 = round(exp(cf[rows, 1] - 1.96 * cf[rows, 2]), 2),
    hi95 = round(exp(cf[rows, 1] + 1.96 * cf[rows, 2]), 2),
    p    = signif(cf[rows, 4], 3)
  )
}

icc5 <- extract_icc(fit5)
icc4 <- extract_icc(fit4)
or5  <- tier_ors(fit5, "ncdvi_se")
or4  <- tier_ors(fit4, "ncdvi_se4")

# Apparent AUC; fixed-effects-only prediction (re.form = NA) per Phase 4.
# Use in-sample predict (no newdata) to avoid a known lme4 newdata-dimension
# quirk on this frame; source rows are identical either way.
dat$prob5_app <- predict(fit5, type = "response", re.form = NA)
dat$prob4_app <- predict(fit4, type = "response", re.form = NA)

form_conf <- as.formula(paste("y ~", paste(confounders_22, collapse = " + ")))
fit_conf <- glm(form_conf, data = dat,
                weights = sampling_wgt, family = binomial(link = "logit"))
dat$prob_conf_app <- predict(fit_conf, newdata = dat, type = "response")

roc5    <- roc(dat$y, dat$prob5_app, quiet = TRUE)
roc4    <- roc(dat$y, dat$prob4_app, quiet = TRUE)
rocC    <- roc(dat$y, dat$prob_conf_app, quiet = TRUE)

auc5_app <- ci.auc(roc5, method = "delong")
auc4_app <- ci.auc(roc4, method = "delong")
aucC_app <- ci.auc(rocC, method = "delong")

delong5 <- roc.test(roc5, rocC, method = "delong", paired = TRUE)
delong4 <- roc.test(roc4, rocC, method = "delong", paired = TRUE)

# 10-fold CV (glm; matches Phase 4 protocol).
K <- 10
pos <- which(dat$y == 1); neg <- which(dat$y == 0)
fold <- integer(nrow(dat))
fold[pos] <- sample(rep(seq_len(K), length.out = length(pos)))
fold[neg] <- sample(rep(seq_len(K), length.out = length(neg)))

form5_glm <- as.formula(paste("y ~ ncdvi_se +",
                              paste(confounders_22, collapse = " + ")))
form4_glm <- as.formula(paste("y ~ ncdvi_se4 +",
                              paste(confounders_22, collapse = " + ")))

cv_predict <- function(form) {
  pred_oof <- numeric(nrow(dat))
  fold_aucs <- numeric(K)
  for (k in seq_len(K)) {
    train <- dat[fold != k, ]
    test  <- dat[fold == k, ]
    fit_k <- suppressWarnings(
      glm(form, data = train, weights = sampling_wgt,
          family = binomial(link = "logit"))
    )
    p_k <- predict(fit_k, newdata = test, type = "response")
    pred_oof[fold == k] <- p_k
    fold_aucs[k] <- as.numeric(auc(roc(test$y, p_k, quiet = TRUE)))
  }
  list(pred = pred_oof, fold_aucs = fold_aucs)
}

cv5  <- cv_predict(form5_glm)
cv4  <- cv_predict(form4_glm)
cvC  <- cv_predict(form_conf)

cv5_auc <- ci.auc(roc(dat$y, cv5$pred, quiet = TRUE), method = "delong")
cv4_auc <- ci.auc(roc(dat$y, cv4$pred, quiet = TRUE), method = "delong")
cvC_auc <- ci.auc(roc(dat$y, cvC$pred, quiet = TRUE), method = "delong")

# Calibration: logit recalibration regression (perfect = intercept 0, slope 1).
calib_lm <- function(prob, y) {
  prob <- pmin(pmax(prob, 1e-6), 1 - 1e-6)
  lp <- log(prob / (1 - prob))
  m <- glm(y ~ lp, family = binomial)
  list(intercept = unname(coef(m)[1]), slope = unname(coef(m)[2]))
}
cs5_app <- calib_lm(dat$prob5_app, dat$y)
cs5_cv  <- calib_lm(cv5$pred,      dat$y)
cs4_app <- calib_lm(dat$prob4_app, dat$y)
cs4_cv  <- calib_lm(cv4$pred,      dat$y)

calib_decile <- function(prob, y, lbl) {
  d <- data.frame(prob = prob, y = y)
  d$decile <- ntile(d$prob, 10)
  d %>% group_by(decile) %>%
    summarise(n = dplyr::n(),
              pred = mean(prob),
              obs  = mean(y),
              se   = sqrt(mean(y) * (1 - mean(y)) / dplyr::n()),
              .groups = "drop") %>%
    mutate(model = lbl)
}
calib_apparent5 <- calib_decile(dat$prob5_app, dat$y, "Apparent (5-tier)")
calib_cv5       <- calib_decile(cv5$pred,      dat$y, "10-fold CV (5-tier)")

p_calib <- ggplot(bind_rows(calib_apparent5, calib_cv5),
                  aes(x = pred, y = obs, color = model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = pmax(obs - 1.96 * se, 0),
                    ymax = pmin(obs + 1.96 * se, 1)),
                width = 0.01, alpha = 0.6) +
  geom_point(size = 2) +
  geom_line(alpha = 0.5) +
  scale_x_continuous(limits = c(0, 0.6)) +
  scale_y_continuous(limits = c(0, 0.6)) +
  labs(x = "Mean predicted probability (decile)",
       y = "Observed hypertension prevalence (decile)",
       title = "NCDVI external calibration on BDHS 2022 (women age 18+)",
       subtitle = "Sensitivity 6-input NCDVI, projected onto 2017-18 MCA axis",
       color = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("Figures/phase8d_calibration.png", p_calib,
       width = 6.5, height = 5, dpi = 200)

saveRDS(list(
  run_at         = Sys.time(),
  sample_n       = nrow(dat),
  htn_n          = sum(dat$y),
  htn_prev       = mean(dat$y),
  fit5 = list(icc = icc5, ors = or5,
              coef = summary(fit5)$coef,
              convergence = fit5@optinfo$conv$lme4$messages),
  fit4 = list(icc = icc4, ors = or4,
              coef = summary(fit4)$coef,
              convergence = fit4@optinfo$conv$lme4$messages),
  apparent = list(auc_conf = aucC_app,
                  auc5 = auc5_app, auc4 = auc4_app,
                  delong5_vs_conf = delong5,
                  delong4_vs_conf = delong4),
  cv10 = list(auc_conf = cvC_auc, auc5 = cv5_auc, auc4 = cv4_auc,
              fold_aucs_conf = cvC$fold_aucs,
              fold_aucs_5    = cv5$fold_aucs,
              fold_aucs_4    = cv4$fold_aucs,
              oof_conf = cvC$pred, oof_5 = cv5$pred, oof_4 = cv4$pred),
  calibration = list(deciles_apparent5 = calib_apparent5,
                     deciles_cv5       = calib_cv5,
                     intercept_slope = list(
                       apparent5 = cs5_app, cv5 = cs5_cv,
                       apparent4 = cs4_app, cv4 = cs4_cv))),
  "outputs/phase8d_validation.rds")
