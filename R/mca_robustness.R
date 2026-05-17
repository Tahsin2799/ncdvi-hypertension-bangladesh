# MCA design robustness:
# S1 adjusted inertia (Benzécri/Greenacre); S2 drop cook_location; S3 ncp 1/2/3;
# S4 alternative cut methods; S5 tier counts 4-7; S6 PCAmix cross-check.
# Each variant rebuilds the index, refits a glm, and reports top-tier OR + CV AUC.

source("R/mca_index.R")
library(FactoMineR)
library(PCAmixdata)
library(ca)
library(statar)
library(pROC)
library(dplyr)
library(classInt)
library(cluster)

set.seed(20260516)
dat_18$sampling_wgt <- dat_18$hv005 / 1e6

confounders <- c("diabetic", "age_cat", "sex", "educ", "marital_status",
                 "wealth_index", "division", "area_res")
ncdvi_inputs <- c("occupation", "BMI_cat", "salt_intake", "stop_smok",
                  "lose_wgt", "exer_more", "cook_fuel", "water_source",
                  "toilet_type", "cook_location", "crowding")

d_base <- as.data.frame(dat_18)
d_base$hyper_n <- as.numeric(d_base$hyper == "Yes")

cut_quintile <- function(x, n = 5) factor(xtile(x, n = n))
cut_kmeans   <- function(x, n = 5) {
  km <- kmeans(matrix(x, ncol = 1), centers = n, nstart = 25, iter.max = 50)
  ord <- order(km$centers[, 1])
  labs <- match(km$cluster, ord)
  factor(labs)
}
cut_jenks <- function(x, n = 5) {
  brks <- classIntervals(x, n = n, style = "jenks")$brks
  factor(as.integer(cut(x, brks, include.lowest = TRUE)))
}
cut_equal <- function(x, n = 5) factor(as.integer(cut(x, n)))

K_FOLDS <- 10
fit_eval <- function(df, idx_col, label) {
  rhs <- paste(c(idx_col, confounders), collapse = " + ")
  f   <- as.formula(paste("hyper_n ~", rhs))
  fit <- suppressWarnings(
    glm(f, data = df, weights = sampling_wgt, family = binomial(link = "logit"))
  )
  cf <- summary(fit)$coef
  rows  <- grep(paste0("^", idx_col), rownames(cf))
  ors   <- exp(cf[rows, 1])
  los   <- exp(cf[rows, 1] - 1.96 * cf[rows, 2])
  his   <- exp(cf[rows, 1] + 1.96 * cf[rows, 2])
  top_or <- tail(ors, 1)
  top_lo <- tail(los, 1)
  top_hi <- tail(his, 1)

  pr <- df %>%
    group_by(.data[[idx_col]]) %>%
    summarise(prev = mean(hyper_n), .groups = "drop") %>%
    arrange(.data[[idx_col]])
  mono <- all(diff(pr$prev) >= 0)

  df$fold <- {
    pos <- which(df$hyper_n == 1); neg <- which(df$hyper_n == 0)
    f2 <- integer(nrow(df))
    f2[pos] <- sample(rep(seq_len(K_FOLDS), length.out = length(pos)))
    f2[neg] <- sample(rep(seq_len(K_FOLDS), length.out = length(neg)))
    f2
  }
  oof <- numeric(nrow(df))
  for (k in seq_len(K_FOLDS)) {
    tr <- df[df$fold != k, ]
    te <- df[df$fold == k, ]
    fit_k <- suppressWarnings(
      glm(f, data = tr, weights = sampling_wgt,
          family = binomial(link = "logit"))
    )
    oof[df$fold == k] <- predict(fit_k, newdata = te, type = "response")
  }
  auc_val <- as.numeric(auc(roc(df$hyper_n, oof, quiet = TRUE)))

  list(label = label,
       top_OR = round(top_or, 2),
       top_lo = round(top_lo, 2),
       top_hi = round(top_hi, 2),
       cv_AUC = round(auc_val, 4),
       monotonic = mono,
       n_tiers = length(ors) + 1)
}

# S1 adjusted inertia (Greenacre)
mca_base <- MCA(d_base[, ncdvi_inputs], ncp = 5, graph = FALSE)
eig_raw  <- mca_base$eig[, "eigenvalue"]
Q <- length(ncdvi_inputs)
keep <- eig_raw > 1 / Q
eig_adj <- ifelse(keep,
                  (Q / (Q - 1))^2 * (eig_raw - 1 / Q)^2, 0)
inertia_greenacre <- eig_adj / sum(eig_adj) * 100
inertia_raw       <- mca_base$eig[, "percentage of variance"]

# S2 drop cook_location
inputs_no_cl <- setdiff(ncdvi_inputs, "cook_location")
mca_no_cl <- MCA(d_base[, inputs_no_cl], ncp = 1, graph = FALSE)
sc_no_cl  <- as.numeric(mca_no_cl$ind$coord[, 1])
sc_no_cl  <- (sc_no_cl - min(sc_no_cl)) / (max(sc_no_cl) - min(sc_no_cl))
d_base$ncdvi_no_cl <- cut_quintile(sc_no_cl, n = 5)
prev_by_tier <- tapply(d_base$hyper_n, d_base$ncdvi_no_cl, mean)
if (which.max(prev_by_tier) == 1) {
  d_base$ncdvi_no_cl <- factor(6 - as.integer(d_base$ncdvi_no_cl))
}

# S3 ncp = 2, 3 (eigenvalue-weighted combined score)
sc1 <- as.numeric(mca_base$ind$coord[, 1])
sc2 <- as.numeric(mca_base$ind$coord[, 2])
sc3 <- as.numeric(mca_base$ind$coord[, 3])

combine_score <- function(scores, eigs) {
  combo <- as.numeric(scores %*% eigs[seq_len(ncol(scores))])
  (combo - min(combo)) / (max(combo) - min(combo))
}
sc_ncp2 <- combine_score(cbind(sc1, sc2),       eig_raw[1:2])
sc_ncp3 <- combine_score(cbind(sc1, sc2, sc3),  eig_raw[1:3])
d_base$ncdvi_ncp2 <- cut_quintile(sc_ncp2, n = 5)
d_base$ncdvi_ncp3 <- cut_quintile(sc_ncp3, n = 5)
for (col in c("ncdvi_ncp2", "ncdvi_ncp3")) {
  prev_by_tier <- tapply(d_base$hyper_n, d_base[[col]], mean)
  if (which.max(prev_by_tier) == 1) {
    d_base[[col]] <- factor(6 - as.integer(d_base[[col]]))
  }
}

# S4 cut methods
d_base$ncdvi_quint   <- cut_quintile(d_base$scores_std, n = 5)
d_base$ncdvi_kmeans  <- cut_kmeans(d_base$scores_std,   n = 5)
d_base$ncdvi_jenks   <- cut_jenks(d_base$scores_std,    n = 5)
d_base$ncdvi_equal   <- cut_equal(d_base$scores_std,    n = 5)
for (col in c("ncdvi_quint","ncdvi_kmeans","ncdvi_jenks","ncdvi_equal")) {
  prev_by_tier <- tapply(d_base$hyper_n, d_base[[col]], mean)
  if (which.max(prev_by_tier) == 1) {
    d_base[[col]] <- factor((length(prev_by_tier) + 1) - as.integer(d_base[[col]]))
  }
}

# S5 tier counts
for (n in c(4, 5, 6, 7)) {
  col <- paste0("ncdvi_t", n)
  d_base[[col]] <- cut_quintile(d_base$scores_std, n = n)
  prev_by_tier <- tapply(d_base$hyper_n, d_base[[col]], mean)
  if (which.max(prev_by_tier) == 1) {
    d_base[[col]] <- factor((n + 1) - as.integer(d_base[[col]]))
  }
}

# S6 PCAmix
quali_df <- d_base[, ncdvi_inputs]
quali_df[] <- lapply(quali_df, factor)
pcamix_fit <- PCAmix(X.quanti = NULL, X.quali = quali_df, ndim = 2,
                     graph = FALSE, rename.level = TRUE)
sc_pcamix <- as.numeric(pcamix_fit$ind$coord[, 1])
sc_pcamix <- (sc_pcamix - min(sc_pcamix)) / (max(sc_pcamix) - min(sc_pcamix))
d_base$ncdvi_pcamix <- cut_quintile(sc_pcamix, n = 5)
prev_by_tier <- tapply(d_base$hyper_n, d_base$ncdvi_pcamix, mean)
if (which.max(prev_by_tier) == 1) {
  d_base$ncdvi_pcamix <- factor(6 - as.integer(d_base$ncdvi_pcamix))
}

variants <- list(
  baseline           = "ncdvi",
  drop_cook_location = "ncdvi_no_cl",
  ncp_2              = "ncdvi_ncp2",
  ncp_3              = "ncdvi_ncp3",
  cut_quintile       = "ncdvi_quint",
  cut_kmeans         = "ncdvi_kmeans",
  cut_jenks          = "ncdvi_jenks",
  cut_equal_width    = "ncdvi_equal",
  tiers_4            = "ncdvi_t4",
  tiers_5            = "ncdvi_t5",
  tiers_6            = "ncdvi_t6",
  tiers_7            = "ncdvi_t7",
  pcamix             = "ncdvi_pcamix"
)

all_results <- list()
for (nm in names(variants)) {
  all_results[[nm]] <- fit_eval(d_base, variants[[nm]], nm)
}

summary_df <- do.call(rbind, lapply(all_results, function(r) {
  data.frame(variant = r$label,
             top_OR = r$top_OR, top_lo = r$top_lo, top_hi = r$top_hi,
             cv_AUC = r$cv_AUC, n_tiers = r$n_tiers,
             monotonic = r$monotonic)
}))
rownames(summary_df) <- NULL

saveRDS(list(summary = summary_df,
             inertia = data.frame(dim = 1:5,
                                  eig = eig_raw[1:5],
                                  raw_pct = inertia_raw[1:5],
                                  greenacre_pct = inertia_greenacre[1:5]),
             all_results = all_results),
        "outputs/phase5_mca_robustness.rds")
