# Discrimination enhancement build-up M0->M6 (continuous NCDVI, splines,
# interactions) plus XGBoost ceiling on identical features. Uses glm for
# the logit models (ICC 0.045 means glmer would give near-identical AUC).

source("R/mca_index.R")
library(pROC)
library(splines)
library(dplyr)

set.seed(20260516)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")

# mca_index.R alone doesn't produce sampling_wgt; derive from hv005.
dat_18$sampling_wgt <- dat_18$hv005 / 1e6

d <- as.data.frame(dat_18)
d$hyper       <- as.numeric(d$hyper == "Yes")
d$diabetic_n  <- as.numeric(d$diabetic == "Yes")
d$sex_n       <- as.numeric(d$sex == "Male" | d$sex == 1)
d$ncdvi_cont  <- as.numeric(d$scores_std)
d$age_c       <- as.numeric(d$age)
d$bmi_c       <- as.numeric(d$BMI)
d$gluc_c      <- as.numeric(d$glucose)

stopifnot(!anyNA(d$ncdvi_cont), !anyNA(d$age_c),
          !anyNA(d$bmi_c),     !anyNA(d$gluc_c))

forms <- list(
  M0 = paste("hyper ~ ncdvi +",      paste(confounders, collapse = " + ")),
  M1 = paste("hyper ~ ncdvi_cont +", paste(confounders, collapse = " + ")),
  M2 = paste("hyper ~ ncdvi_cont + age_c +",
             paste(setdiff(confounders, "age_cat"), collapse = " + ")),
  M3 = paste("hyper ~ ncdvi_cont + age_c + bmi_c +",
             paste(setdiff(confounders, "age_cat"), collapse = " + ")),
  M4 = paste("hyper ~ ncdvi_cont + age_c + bmi_c + gluc_c +",
             paste(setdiff(confounders, c("age_cat", "diabetic")), collapse = " + ")),
  M5 = paste("hyper ~ ncdvi_cont + age_c + bmi_c + gluc_c + age_c:sex + age_c:bmi_c + age_c:gluc_c + sex:bmi_c +",
             paste(setdiff(confounders, c("age_cat", "diabetic")), collapse = " + ")),
  M6 = paste("hyper ~ ncdvi_cont + ns(age_c, 4) + ns(bmi_c, 4) + gluc_c + age_c:sex + age_c:bmi_c + age_c:gluc_c + sex:bmi_c +",
             paste(setdiff(confounders, c("age_cat", "diabetic")), collapse = " + "))
)

fit_one <- function(f) {
  suppressWarnings(
    glm(as.formula(f), data = d, weights = sampling_wgt,
        family = binomial(link = "logit"))
  )
}

apparent_auc <- function(fit) {
  p <- predict(fit, type = "response")
  r <- roc(d$hyper, p, quiet = TRUE)
  ci <- ci.auc(r, method = "delong")
  c(auc = as.numeric(ci[2]), lo = as.numeric(ci[1]), hi = as.numeric(ci[3]))
}

K <- 10
d$fold <- {
  pos <- which(d$hyper == 1); neg <- which(d$hyper == 0)
  f <- integer(nrow(d))
  f[pos] <- sample(rep(seq_len(K), length.out = length(pos)))
  f[neg] <- sample(rep(seq_len(K), length.out = length(neg)))
  f
}

cv_auc <- function(form) {
  oof <- numeric(nrow(d))
  for (k in seq_len(K)) {
    train <- d[d$fold != k, ]
    test  <- d[d$fold == k, ]
    fit_k <- suppressWarnings(
      glm(as.formula(form), data = train, weights = sampling_wgt,
          family = binomial(link = "logit"))
    )
    oof[d$fold == k] <- predict(fit_k, newdata = test, type = "response")
  }
  ci <- ci.auc(roc(d$hyper, oof, quiet = TRUE), method = "delong")
  list(auc = as.numeric(ci[2]), lo = as.numeric(ci[1]), hi = as.numeric(ci[3]),
       oof = oof)
}

results <- list()
for (m in names(forms)) {
  fit <- fit_one(forms[[m]])
  app <- apparent_auc(fit)
  cv  <- cv_auc(forms[[m]])
  results[[m]] <- list(form = forms[[m]],
                       apparent = app,
                       cv = c(auc = cv$auc, lo = cv$lo, hi = cv$hi),
                       oof = cv$oof)
}

# single-interaction probe vs M4 baseline
inter_terms <- c("age_c:sex", "age_c:bmi_c", "age_c:gluc_c", "age_c:diabetic_n",
                 "sex:bmi_c", "sex:gluc_c", "bmi_c:gluc_c", "ncdvi_cont:age_c",
                 "ncdvi_cont:sex")
base_rhs <- paste("ncdvi_cont + age_c + bmi_c + gluc_c +",
                  paste(setdiff(confounders, c("age_cat","diabetic")),
                        collapse = " + "))

probe <- data.frame()
for (it in inter_terms) {
  f  <- paste("hyper ~", base_rhs, "+", it)
  fi <- fit_one(f)
  app <- apparent_auc(fi)
  cv  <- cv_auc(f)
  probe <- rbind(probe, data.frame(
    interaction = it,
    apparent_AUC = round(app["auc"], 4),
    delta_apparent = round(app["auc"] - results$M4$apparent["auc"], 4),
    cv_AUC = round(cv$auc, 4),
    delta_cv = round(cv$auc - results$M4$cv["auc"], 4)))
}

# XGBoost ceiling
library(xgboost)
X_all <- model.matrix(~ ncdvi_cont + age_c + bmi_c + gluc_c + sex + educ +
                        marital_status + wealth_index + division + area_res,
                      data = d)[, -1]
y <- d$hyper
wt <- d$sampling_wgt

oof_xgb <- numeric(nrow(d))
for (k in seq_len(K)) {
  tr <- d$fold != k
  dtr <- xgb.DMatrix(X_all[tr,  , drop = FALSE], label = y[tr],  weight = wt[tr])
  dte <- xgb.DMatrix(X_all[!tr, , drop = FALSE], label = y[!tr], weight = wt[!tr])
  fit_xgb <- xgb.train(
    params = list(objective = "binary:logistic", eval_metric = "auc",
                  max_depth = 6, eta = 0.05,
                  subsample = 0.8, colsample_bytree = 0.8),
    data = dtr,
    nrounds = 400,
    watchlist = list(val = dte),
    early_stopping_rounds = 30,
    verbose = 0)
  oof_xgb[!tr] <- predict(fit_xgb, dte)
}
ci_xgb <- ci.auc(roc(y, oof_xgb, quiet = TRUE), method = "delong")
xgb_auc <- as.numeric(ci_xgb[2])

summary_tab <- do.call(rbind, lapply(names(results), function(m) {
  data.frame(model = m,
             apparent_AUC = round(results[[m]]$apparent["auc"], 4),
             cv_AUC       = round(results[[m]]$cv["auc"],       4),
             cv_lo        = round(results[[m]]$cv["lo"],        4),
             cv_hi        = round(results[[m]]$cv["hi"],        4))
}))
summary_tab <- rbind(summary_tab,
                     data.frame(model = "XGBoost (CV only)",
                                apparent_AUC = NA_real_,
                                cv_AUC = round(xgb_auc, 4),
                                cv_lo  = round(as.numeric(ci_xgb[1]), 4),
                                cv_hi  = round(as.numeric(ci_xgb[3]), 4)))

saveRDS(list(buildup = results, interaction_probe = probe,
             summary = summary_tab,
             xgb_auc = xgb_auc),
        "outputs/phase4c_discrimination_enhance.rds")
