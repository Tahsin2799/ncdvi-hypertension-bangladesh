# outputs/ — persisted analysis results

Artifacts from the revamp phases, used by Phase 6 (manuscript packaging) and Phase 7 (Zenodo deposit). Each file is an `.rds` written by one of the R scripts in `R/`; structure is documented below.

## phase2_sensitivity.rds
**Produced by:** `R/sensitivity_ncdvi.R`
**Run on:** 2026-05-15

```
List of 5
 $ prev_by_tier         tbl 5 × 3   — HTN prevalence by tier for primary vs sensitivity
 $ or_primary           df  4 × 5   — svyglm Tier 2–5 OR + 95% CI + p for 11-input NCDVI
 $ or_sensitivity       df  4 × 5   — svyglm Tier 2–5 OR + 95% CI + p for 7-input NCDVI
 $ mca_eig_primary      mat 5 × 3   — MCA eigenvalues / variance, 11-input
 $ mca_eig_sensitivity  mat 5 × 3   — MCA eigenvalues / variance, 7-input
```

Headline: Tier-5 svyglm OR collapses 15.89 → 2.67 when advice variables (`sb318b–e`) removed.

## phase3_multilevel.rds
**Produced by:** `R/multilevel_model.R`
**Run on:** 2026-05-15

```
List of 7
 $ or_wemix_primary      df  4 × 4   — WeMix multilevel Tier 2–5 OR + 95% CI, 11-input
 $ or_wemix_sensitivity  df  4 × 4   — WeMix multilevel Tier 2–5 OR + 95% CI, 7-input
 $ or_glmer              df  4 × 4   — legacy glmer comparison ORs, 11-input
 $ icc_primary           list of 4   — sigma2_u, ICC, CI bounds (primary)
 $ icc_sensitivity       list of 4   — sigma2_u, ICC, CI bounds (sensitivity)
 $ multimod_wemix_fixef  num 28      — full fixed-effect coef vector (primary)
 $ multimod_wemix_se     num 28      — corresponding SEs
```

Headline: WeMix Tier-5 OR primary = 31.34 (24.33–40.37); sensitivity = 4.02 (3.10–5.22); ICC = 0.43 with wide CI (0.0–0.69).

## manuscript render cache
**Produced by:** `R/build_manuscript_render_cache.R`
**Run on:** 2026-05-16

These files let `manuscript.Rmd` render quickly without re-running the data pipeline or refitting the multilevel models:

```
outputs/manuscript_bi_tab_short.rds       — small data frame for the bivariate NCDVI table
outputs/manuscript_multilevel_table.rds   — small data frame for the primary glmer regression table
```

Re-run `R/build_manuscript_render_cache.R` only after changing the underlying analysis results. The manuscript render then loads these cached tables directly.
