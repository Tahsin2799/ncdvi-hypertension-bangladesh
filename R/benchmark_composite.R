# Benchmark the MCA tier index against simpler composite constructions, to answer
# the reviewer question "does MCA add value over simpler approaches?". Three
# constructions of the same 10 inputs are compared on identical CV folds:
#   (1) MCA first dimension -> quintile tiers (the manuscript's index)
#   (2) PCA first component of the indicator (dummy) matrix -> quintile tiers
#       (the DHS wealth-index construction, applied to these inputs)
#   (3) the raw 10 items entered directly into the logistic model (no composite)
# All add the same confounders. We report cross-validated AUC for each.

suppressPackageStartupMessages({library(statar); library(pROC); library(dplyr)})
source("R/sensitivity_ncdvi.R")   # dat_18 with ncdvi (fit-once MCA tiers)
set.seed(20260516)

confounders <- c("diabetic","age_cat","sex","educ","marital_status",
                 "wealth_index","division","area_res")
cf <- paste(confounders, collapse = " + ")
inp10 <- c("occupation","BMI_cat","salt_intake","stop_smok","lose_wgt",
           "exer_more","cook_fuel","water_source","toilet_type","crowding")

d <- as.data.frame(dat_18)
d$.y <- as.numeric(d$hyper == "Yes")

# (2) PCA on the indicator matrix -> PC1 -> quintile tiers, oriented by prevalence.
X <- model.matrix(~ ., data = d[, inp10])[, -1]
pc1 <- prcomp(X, scale. = TRUE)$x[, 1]
pc_std <- (pc1 - min(pc1)) / (max(pc1) - min(pc1))
praw <- xtile(pc_std, n = 5)
pv <- tapply(d$.y, praw, mean)
if (pv[5] < pv[1]) praw <- 6 - praw
d$pca_tier <- factor(praw, levels = 1:5,
                     labels = c("Tier 1","Tier 2","Tier 3","Tier 4","Tier 5"))

# common stratified folds
K <- 10; pos <- which(d$.y == 1); neg <- which(d$.y == 0)
fold <- integer(nrow(d))
fold[pos] <- sample(rep(1:K, length.out = length(pos)))
fold[neg] <- sample(rep(1:K, length.out = length(neg)))

cv_auc <- function(form) {
  oof <- numeric(nrow(d))
  for (k in 1:K) {
    m <- suppressWarnings(glm(form, data = d[fold != k, ],
                              weights = sampling_wgt, family = binomial()))
    oof[fold == k] <- predict(m, newdata = d[fold == k, ], type = "response")
  }
  as.numeric(ci.auc(roc(d$.y, oof, quiet = TRUE), method = "delong"))
}

a_mca <- cv_auc(as.formula(paste(".y ~ ncdvi +",    cf)))
a_pca <- cv_auc(as.formula(paste(".y ~ pca_tier +", cf)))
a_raw <- cv_auc(as.formula(paste(".y ~", paste(inp10, collapse = " + "), "+", cf)))
a_conf<- cv_auc(as.formula(paste(".y ~", cf)))

fmt <- function(a) sprintf("%.4f (%.4f-%.4f)", a[2], a[1], a[3])
cat("\n================ COMPOSITE BENCHMARK (CV AUC) ================\n")
cat(sprintf("Confounders only              : %s\n", fmt(a_conf)))
cat(sprintf("MCA first-dim tiers (paper)   : %s\n", fmt(a_mca)))
cat(sprintf("PCA wealth-index tiers        : %s\n", fmt(a_pca)))
cat(sprintf("Raw 10 items (no composite)   : %s\n", fmt(a_raw)))

saveRDS(list(confounders = a_conf, mca = a_mca, pca = a_pca, raw = a_raw,
             run_at = Sys.time()),
        "outputs/phase11_benchmark.rds")
cat("\nSaved outputs/phase11_benchmark.rds\n")
