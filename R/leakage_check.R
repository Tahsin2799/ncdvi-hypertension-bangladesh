# Fold-internal MCA leakage check.
# The headline internal CV (R/validation.R) fits the MCA + quintile cutpoints once
# on the full sample, then cross-validates the model that uses those tiers. The
# tier assignment for a held-out fold therefore "saw" that fold during MCA fitting.
# Here we rebuild the index inside each fold (MCA on train only, project test via
# predict.MCA, scale + cut + orient by train), so no test information leaks. We
# compare the pooled cross-validated AUC under identical folds. A small gap means
# the fit-once pipeline was not meaningfully optimistic.

suppressPackageStartupMessages({
  library(FactoMineR); library(pROC); library(dplyr)
})
source("R/sensitivity_ncdvi.R")   # dat_18 with ncdvi (fit-once), inputs, sampling_wgt
set.seed(20260516)

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
cf <- paste(confounders, collapse = " + ")
d <- as.data.frame(dat_18)
d$.y <- as.numeric(d$hyper == "Yes")

K <- 10
pos <- which(d$.y == 1); neg <- which(d$.y == 0)
fold <- integer(nrow(d))
fold[pos] <- sample(rep(seq_len(K), length.out = length(pos)))
fold[neg] <- sample(rep(seq_len(K), length.out = length(neg)))

# Rebuild a 5-tier index from a set of MCA inputs, fit on `train`, applied to `test`.
fold_internal_tiers <- function(train, test, inputs) {
  # predict.MCA matches supplementary individuals by category *label*; the four
  # advice variables share "Otherwise"/"Yes", so prefix every level with its
  # variable name to keep category names unique and unambiguous.
  for (v in inputs) {
    levels(train[[v]]) <- paste0(v, "::", levels(train[[v]]))
    levels(test[[v]])  <- paste0(v, "::", levels(test[[v]]))
  }
  mca_k <- MCA(train[, inputs], ncp = 1, graph = FALSE)
  s_tr  <- as.numeric(mca_k$ind$coord[, 1])
  s_te  <- as.numeric(predict(mca_k, newdata = test[, inputs])$coord[, 1])
  smin <- min(s_tr); smax <- max(s_tr)
  std_tr <- (s_tr - smin) / (smax - smin)
  std_te <- pmin(pmax((s_te - smin) / (smax - smin), 0), 1)
  cuts <- quantile(std_tr, probs = seq(0, 1, 0.2), names = FALSE)
  cuts[1] <- -Inf; cuts[length(cuts)] <- Inf
  t_tr <- as.integer(cut(std_tr, breaks = cuts, include.lowest = TRUE, labels = 1:5))
  t_te <- as.integer(cut(std_te, breaks = cuts, include.lowest = TRUE, labels = 1:5))
  # orient on train: Tier 5 = highest HTN prevalence
  pv <- tapply(train$.y, t_tr, mean)
  if (!is.na(pv["5"]) && !is.na(pv["1"]) && pv["5"] < pv["1"]) {
    t_tr <- 6 - t_tr; t_te <- 6 - t_te
  }
  lvl <- c("Tier 1","Tier 2","Tier 3","Tier 4","Tier 5")
  list(train = factor(lvl[t_tr], levels = lvl),
       test  = factor(lvl[t_te], levels = lvl))
}

cv_auc <- function(inputs, tiervar, fit_once = TRUE) {
  oof <- numeric(nrow(d))
  for (k in seq_len(K)) {
    tr <- d[fold != k, ]; te <- d[fold == k, ]
    if (fit_once) {
      tr$tier <- tr[[tiervar]]; te$tier <- te[[tiervar]]
    } else {
      ti <- fold_internal_tiers(tr, te, inputs)
      tr$tier <- ti$train; te$tier <- ti$test
    }
    m <- suppressWarnings(glm(as.formula(paste(".y ~ tier +", cf)),
                              data = tr, weights = sampling_wgt,
                              family = binomial(link = "logit")))
    oof[fold == k] <- predict(m, newdata = te, type = "response")
  }
  as.numeric(ci.auc(roc(d$.y, oof, quiet = TRUE), method = "delong"))
}

inp10 <- c("occupation","BMI_cat","salt_intake","stop_smok","lose_wgt",
           "exer_more","cook_fuel","water_source","toilet_type","crowding")
inp6  <- c("occupation","BMI_cat","cook_fuel","water_source","toilet_type","crowding")

cat("Computing fit-once vs fold-internal CV AUC (same folds)...\n")
p_once <- cv_auc(inp10, "ncdvi",    fit_once = TRUE)
p_fold <- cv_auc(inp10, "ncdvi",    fit_once = FALSE)
s_once <- cv_auc(inp6,  "ncdvi_se", fit_once = TRUE)
s_fold <- cv_auc(inp6,  "ncdvi_se", fit_once = FALSE)

fmt <- function(a) sprintf("%.4f (%.4f-%.4f)", a[2], a[1], a[3])
cat("\n================ MCA LEAKAGE CHECK ================\n")
cat(sprintf("Primary 10-input:  fit-once CV AUC %s | fold-internal %s | optimism %+.4f\n",
            fmt(p_once), fmt(p_fold), p_once[2] - p_fold[2]))
cat(sprintf("Sensitivity 6-input: fit-once CV AUC %s | fold-internal %s | optimism %+.4f\n",
            fmt(s_once), fmt(s_fold), s_once[2] - s_fold[2]))

saveRDS(list(primary = list(fit_once = p_once, fold_internal = p_fold,
                            optimism = p_once[2] - p_fold[2]),
             sensitivity = list(fit_once = s_once, fold_internal = s_fold,
                                optimism = s_once[2] - s_fold[2]),
             run_at = Sys.time()),
        "outputs/phase10_leakage.rds")
cat("\nSaved outputs/phase10_leakage.rds\n")
