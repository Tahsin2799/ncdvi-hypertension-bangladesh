# Perplexity Research Findings — Methodological Best Practices and Reviewer Expectations

Topic: A 2024–2026 epidemiology manuscript building an NCD Vulnerability Index (NCDVI) for hypertension from Bangladesh DHS (BDHS) data via Multiple Correspondence Analysis (MCA) into quintile tiers, validated with weighted multilevel logistic regression (random intercept on PSU), internal validation (AUC, k-fold CV, bootstrap optimism, calibration), and external validation on BDHS 2022.

Source: Perplexity (web + scholar), retrieved 2026-06-08.

## 1. TRIPOD / TRIPOD+AI reporting expectations
- Clearly define the prediction target: outcome definition and measurement (measured BP vs self-report vs medication), population (ages, inclusion/exclusion), and the index's intended use (screening triage vs risk stratification vs policy targeting).
- Specify the model-building strategy reproducibly: MCA inputs and coding, missing-data handling, how MCA scores map to quintiles/tiers (cutpoints data-driven vs prespecified; whether cutpoints are recomputed in each resample), and whether a statistical model is fit using the index as predictor or the index alone is the score.
- Report internal validation methods (resampling approach, what optimism correction was applied) and external validation protocol (which later wave, whether any parts were refit).
- Common desk-rejection triggers: treating a composite index as "predictive" without clarifying risk prediction vs descriptive scoring; omitting calibration and reporting only AUC; not describing weight/clustering handling in both development and validation; not presenting decision/utility measures when the claim is triage/screening.

## 2. Complex survey weights in multilevel models
- Justify how weights enter estimation and what they represent (DHS weights = unequal selection probability + post-stratification).
- Accepted approaches: weighted likelihood multilevel logistic regression with DHS weights as observation weights; or pseudo-likelihood / design-based weighting with robust SEs, preserving PSU clustering via random effects.
- Reviewer criticisms to pre-empt:
  1. Double-counting clustering — applying both robust sandwich SEs AND a PSU random intercept can over-correct uncertainty; clarify the variance-estimation approach.
  2. Weights + resampling mismatch — state whether bootstrap/k-fold resamples individuals or PSU clusters, and how weights are preserved; mismatch distorts optimism estimates.
  3. Weight scaling — if weights are rescaled for stability, say so.
- Explicitly report: the exact DHS weight variable used; any normalization/scaling; that development and validation used the same scheme; missingness handling under weights (complete-case vs MI, and MI compatibility with weights).

## 3. External validation metrics reviewers expect
- Discrimination: AUC / c-statistic with uncertainty.
- Calibration (weighted more heavily than AUC): calibration intercept (calibration-in-the-large), calibration slope (ideal ~1), and a calibration plot (LOESS or grouped by predicted risk).
- O:E ratio (observed:expected) across the sample or calibration groups.
- Net benefit / decision curve analysis (DCA): increasingly expected when "tiers" are intended for triage/screening; show net benefit across threshold probabilities vs treat-all / treat-none. Net benefit is a decision-theoretic standard now widely treated as a component of modern external-validation utility reporting.
- For bootstrap optimism: state which metrics were optimism-corrected (AUC, calibration slope, or both), how optimism was computed, and whether MCA quintile cutpoints were regenerated in each bootstrap replicate when cutpoints are data-driven.

## 4. Is MCA-based composite indexing robust (vs IRT / factor analysis / PCA)?
- MCA is reasonable when predictors are categorical (typical for DHS items) and yields a low-dimensional structured composite.
- Reviewer criticisms:
  1. Construct validity — MCA components may capture a socioeconomic/household gradient rather than latent hypertension risk.
  2. Predictive validity — reviewers may ask whether MCA adds value beyond simpler approaches (regularized logistic regression on raw items; PCA/wealth-index first component; factor analysis / IRT-like latent trait modeling).
  3. Stability/reproducibility — MCA scores can be sensitive to variable selection, coding, and sample; reviewers ask whether MCA was repeated across bootstrap folds and whether the score is stable out-of-sample.
- Defense: present a sensitivity analysis comparing MCA-tier performance against at least one alternative composite construction; keep dimension-reduction/scoring (MCA) separate from prediction/calibration (the multilevel model).

## 5. Endogeneity / reverse-causation with clinician-advice variables
- People with elevated BP, symptoms, prior diagnosis, or routine healthcare contact are more likely to receive counseling — creating reverse causation / confounding by indication. Cross-sectional outcome measurement compounds this.
- Reviewers expect: pre-specifying whether advice variables are markers of healthcare contact rather than causal predictors; a sensitivity analysis excluding them; interpreting results as associations, not causal effects.
- Reviewer-friendly strategy: Model A (with advice variables) vs Model B (without), comparing calibration/discrimination and tier ordering.

## 6. What recent BDHS 2017–18 / 2022 hypertension papers do
- Frequently use logistic regression or ML (random forest, double machine learning) on DHS variables; often include wealth/urban/risk factors; discrimination (AUC) reported, calibration often weakly reported in lower-quality work; some adopt cautious causal framing.
- Example signal: a BDHS-based study using logistic regression, random forest, and double machine learning within a causal framework (excess body weight → hypertension, BDHS 2011–2022).
- Reviewers will benchmark this manuscript by asking: why MCA-based tiers are preferable to / validated against standard regression/ML predictors; whether validation includes calibration and decision utility (not only discrimination); whether external validation keeps the pipeline fixed or explains refitting.

## Cross-cutting reviewer-criticism checklist
- Outcome-definition consistency across waves (measurement and BP-medication handling).
- Preprocessing transparency (categorical recoding, missingness, MCA assumptions).
- Overfitting via data-driven tiers (whether cutpoints are recomputed on validation; whether quantile mapping leaks information).
- Calibration neglected (AUC-only papers routinely criticized).
- Survey-weight handling unclear or inconsistent across development/validation.
- Multilevel-specification mismatch (PSU random intercept in one stage but not the other).
- Index not truly "predictive" (descriptive unless calibration and utility are demonstrated).
- Interpretation creep (implying causal effects from clinician-advice variables without sensitivity analyses).

## Selected sources surfaced
- Fitting multilevel models in complex survey data with design weights — PMC2717116.
- Multilevel Modelling of Complex Survey Data — JRSS-A 169(4):805.
- Bayesian sample size calculations for external validation of risk prediction models — arXiv 2504.15923 (O:E ratio, calibration slope/intercept mapping).
- Expected value of sample information for external validation — arXiv 2401.01849 (net benefit / decision-theoretic utility).
- Insights from BDHS (2011–2022): logistic regression, Random Forest, Double Machine Learning causal framing — PLOS Comp Biol 1013211.
- On the use of PCA in index construction — isitc-europe.
