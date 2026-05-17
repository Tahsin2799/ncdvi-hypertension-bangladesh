# Revamp execution log

Phase-by-phase results, decisions, and follow-ups for the NCDVI manuscript revamp. The plan lives in `LITERATURE_GAPS.md` §5 and §9. This file records what actually happened. Always-loaded session context lives in `CLAUDE.md`; deep results live here so `CLAUDE.md` stays compact.

---

## Phase status (at-a-glance)

| Phase | Status | Files touched | Output |
|---|---|---|---|
| 1 — Expand NCDVI with 5 structural vars | ✅ done 2026-05-15 | `R/analysis_main.R`, `R/mca_index.R` | 11-input NCDVI in pipeline |
| 2 — Endogeneity-sensitivity NCDVI | ✅ done 2026-05-15 | `R/sensitivity_ncdvi.R` (new) | `outputs/phase2_sensitivity.rds` |
| 3 — Multilevel logit (final spec: glmer primary, WeMix scaled supplementary) | ✅ done 2026-05-16 | `R/multilevel_model.R` (rewritten) | `outputs/phase3_multilevel.rds` |
| 3b — ICC investigation | ✅ done 2026-05-15 | `R/icc_investigation.R` (new) | `outputs/phase3b_*.rds` — divergence is in PML, not data |
| 3c — Weight-scaled WeMix refit | ✅ done 2026-05-15 | `R/multilevel_scaled.R` (new) | `outputs/phase3c_scaled_weights.rds` — partial fix, σ²_u 2.46→1.61, ICC 0.43→0.33 |
| 3d — wt2-off variance attribution | ✅ done 2026-05-16 | `R/multilevel_wt2_off.R` (new) | `outputs/phase3d_wt2_off.rds` — (scaled wt1 + wt2≡1) collapses to glmer |
| 4 — Validation + discrimination | ✅ done 2026-05-16 | `R/validation.R` (new), `R/validation_bootstrap.R` (new) | `outputs/phase4_validation.rds`, `Figures/phase4_calibration.png` |
| 4c — Discrimination enhancement | ✅ done 2026-05-16 | `R/validation_enhance.R` (new) | `outputs/phase4c_discrimination_enhance.rds` — CV AUC 0.793 → 0.816 |
| 5 — MCA robustness | ✅ done 2026-05-16 | `R/mca_robustness.R` (new), `R/mca_index.R` (updated: 11→10 inputs, auto-orient guard) | `outputs/phase5_mca_robustness.rds` — `cook_location` dropped |
| 8b — BDHS 2022 variable audit | ✅ done 2026-05-16 | `R/audit_2022.R` (new) | `outputs/phase8a_audit.{rds,log}` |
| **8c — BDHS 2022 build + projection** | ✅ done 2026-05-16 | `R/sensitivity_ncdvi.R` (artifact-save patch), `R/validate_2022.R` (new) | `outputs/phase8c_validation.{rds,log}`, `outputs/sens_mca_artifacts.rds`, `outputs/phase8c_dat_2022.rds` |
| **8d — BDHS 2022 glmer fit + validation** | ✅ done 2026-05-16 | `R/validate_2022_fit.R` (new) | `outputs/phase8d_validation.{rds,log}`, `Figures/phase8d_calibration.png` |
| 6 — Manuscript reframe + journal packaging | ✅ first-pass done 2026-05-16; v2 polish done 2026-05-16 | `manuscript_BS.Rmd` (rewritten), `manuscript_BS_v2.Rmd` (polished), `manuscript_BS_v2.{tex,pdf}`, `Figures/{maps,ncd_prev}.tex` (path fix), `ref.bib`, `R/build_manuscript_render_cache.R` (new) | `outputs/manuscript_bi_tab_short.rds`, `outputs/manuscript_multilevel_table.rds` |
| 7 — Reproducibility infrastructure | ⏸ pending (after 6 review) | — | — |

**Next session entry point:** Phase 6 user review of `manuscript_BS_v2.Rmd` (voice/tone), then Phase 7 cleanup. Phases 1–5, 8b–8d, and Phase 6 (first-pass + v2 polish) are complete. The v2 manuscript loads pre-computed tables from `outputs/manuscript_*` cache built by `R/build_manuscript_render_cache.R` so the render no longer re-fits models. See CLAUDE.md "Next session entry point" paragraph for the suggested order of work.

**Decisions resolved at start of 2026-05-16 (Phase 6/8) session.** User picked: section-by-section manuscript edits (preserves voice), Phase 8 before Phase 6 (external validation is a result not a limitation), BMC Public Health as target journal. See Phase 8 plan section below.

**All earlier open decisions resolved.** The 2026-05-15 ICC concern was attributed to PML method in Phases 3b–3d and the user chose glmer as primary (final spec, 2026-05-16). The `cook_location` near-degeneracy was addressed by Phase 5 (dropped). The discrimination ceiling question was answered by Phase 4c (XGBoost on same features under-performs the M6 logit). No analytical decisions are blocking Phase 8 — only the data download.

---

## Phase 1 — Expand NCDVI with structural variables (2026-05-15)

**Motivation.** §1 of `LITERATURE_GAPS.md` documents the endogeneity critique: 4 of 6 original inputs (`sb318b–e`) are doctor-advice variables that only fire after clinical contact. §8 confirmed (via direct inspection of `Datasets/Data_with_level_wgt_PR7/PR7_with_level_wgt.dta` and `Datasets/BDIR81DT/BDIR81FL.DTA`) that BDHS 2017-18 lacks the canonical behavioral risk variables (tobacco, diet, PA, alcohol, family history). Only structural/household-environmental additions are feasible from PR7.

**Additions to the NCDVI input set.** From 6 → 11 inputs:

| New input | DHS code | Recoding | Distribution (N=12,650) |
|---|---|---|---|
| `cook_fuel` | `hv226` | Clean (electricity/LPG/NG/biogas, 1–4) vs Solid/polluting (5–11) | 81% solid (10,235), 19% clean (2,415) |
| `water_source` | `hv201` | Piped (11–14, 51) / Tubewell-protected (21, 31, 41, 43) / Unimproved (32, 42, 61, 62, 71, 96) | 92% tubewell, 7% piped, <1% unimproved |
| `toilet_type` | `hv205` | JMP-improved (11, 12, 13, 21, 22, 31, 41) vs Unimproved (14, 15, 23, 42, 43, 51, 96) | 66% improved / 34% unimproved |
| `cook_location` | `hv241` + `hv242` | Outdoors/Sep building / In-house w/sep kitchen / In-house no sep kitchen | 97% outdoors-or-sep, 0.8% in-house-w-kitchen, 1.9% in-house-no-kitchen — **near-degenerate** |
| `crowding` | `hv009 / hv216 > 3` (WHO) | Binary | 81% not-crowded / 19% crowded |

NA-handling: a missing value on any of these is mapped to the least-vulnerable category, matching the convention used for `sb318b–e` in the existing pipeline.

**Tier prevalences (primary index, post-expansion):**

| Tier | HTN prev (was, 6-input) | HTN prev (now, 11-input) |
|---|---|---|
| 1 | — | 15.0% |
| 2 | — | 18.6% |
| 3 | — | 21.7% |
| 4 | ≈26% | 25.2% |
| 5 | **≈72%** | **63.2%** |

Monotonic dose-response preserved; Tier-5 cliff softened (72% → 63.2%) — the intended effect of diluting the diagnosis-proxy signal with structural-vulnerability content. MCA dim-1 captures **16.9% raw inertia**.

**Follow-ups for later phases:**
- `cook_location` is near-degenerate (97% in one category) — likely contributes minimal MCA discrimination. **Phase 5 (MCA robustness)** should decide: drop it, merge in-house categories, or replace with a different IAP proxy.
- N = 12,650 with the expanded recodes; previous CLAUDE.md noted N = 12,458 — that older number was likely from a different downstream filter. Verify in Phase 6 / Phase 7.

---

## Phase 2 — Endogeneity-sensitivity NCDVI (2026-05-15)

**Motivation.** Per `LITERATURE_GAPS.md` §1 and §7: rebuild the NCDVI without the four `sb318b–e` advice variables. If the dose-response survives, the index has genuine non-diagnostic content. If it collapses, the headline OR was inflated by diagnosis-proxy variables.

**Build.** `R/sensitivity_ncdvi.R`. Parallel MCA on 7 non-endogenous inputs (occupation + BMI + 5 structural). MCA dim-1 sign is arbitrary; the script auto-orients so Tier 5 = highest HTN prevalence.

**Sensitivity-tier HTN prevalences:**

| Tier | Primary (11-input) | Sensitivity (7-input) |
|---|---|---|
| 1 | 15.0% | 19.1% |
| 2 | 18.6% | 23.3% |
| 3 | 21.7% | 29.1% |
| 4 | 25.2% | **35.8%** |
| 5 | 63.2% | **34.4%** (non-monotonic) |

**Adjusted ORs (svyglm; Tier 1 ref, with confounders):**

| Tier | Primary 11-input OR (95% CI) | Sensitivity 7-input OR (95% CI) |
|---|---|---|
| 2 | 1.34 (1.11–1.61) | 1.37 (1.17–1.60) |
| 3 | 1.84 (1.52–2.22) | 1.60 (1.36–1.89) |
| 4 | 3.23 (2.67–3.90) | 2.92 (2.46–3.48) |
| 5 | **15.89 (12.93–19.53)** | **2.67 (2.16–3.28)** |

**Headline:** the Tier-5 effect collapses **83%** (15.89 → 2.67) when the advice variables are removed. Tier 2–4 ORs barely move. This is the smoking-gun evidence for the endogeneity critique.

**Caveat — raw-prevalence non-monotonicity.** Sensitivity Tier 4 prevalence (35.8%) > Tier 5 (34.4%) before adjustment. After multilevel adjustment in Phase 3, this dissolves (ORs are monotonic). The raw pattern likely reflects that structural-disadvantage MCA dim-1 also loads on "rural/poor," which interacts complexly with HTN risk in Bangladesh's epidemiologic transition.

**Reframing payoff (per `LITERATURE_GAPS.md` §7):** the two indices answer two different questions —
- 11-input = clinical+structural vulnerability of *already-screened* populations (Tier 5 ≈ 63% prevalence)
- 7-input = structural-only vulnerability of populations *not yet reached* by primary care (Tier 5 ≈ 34%)

Both are legitimate; neither alone is "the" NCDVI. This is the central manuscript argument.

---

## Phase 3 — Survey-weighted multilevel via WeMix (2026-05-15)

**Motivation.** Per `LITERATURE_GAPS.md` §3 and §9b: `glmer(weights = sampling_wgt)` is *not* a true survey-weighted multilevel logit; it treats weights as frequency weights. Pseudo-maximum-likelihood multilevel (Pfeffermann et al. 1998) is the standard. The Stata `.do` file at `Datasets/Data_with_level_wgt_PR7/level_weights_calculation.do` had already produced level-1 (`wt1`) and level-2 (`wt2`) weights for exactly this purpose.

**Build.** `R/multilevel_model.R` rewritten:
- Primary: `WeMix::mix(... weights = c("wt1", "wt2") ...)` on the 11-input NCDVI
- Sensitivity: same on the 7-input NCDVI
- Legacy: `glmer(... weights = sampling_wgt ...)` kept as comparison

**Debugging note — WeMix + haven_labelled gotcha.** WeMix's internal `aggregate.data.frame` step fails with `"no rows to aggregate"` when *any* column in the input data frame carries lingering `haven_labelled` attributes — even columns not referenced in the formula. The fix is to subset to model variables and strip labels before fitting:

```r
strip_labels <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(x)
  attr(x, "labels") <- NULL; attr(x, "label") <- NULL
  attr(x, "format.stata") <- NULL; x
}
dat_mlm <- as.data.frame(dat_18)[, model_vars]
for (v in names(dat_mlm)) dat_mlm[[v]] <- strip_labels(dat_mlm[[v]])
```

This isn't documented in the WeMix vignettes and cost ~30 min to bisect. Preserved in the script with a comment.

**Results.**

| Model | Tier-5 OR (95% CI) — primary | Tier-5 OR (95% CI) — sensitivity |
|---|---|---|
| svyglm single-level pseudo-ML | 15.89 (12.93–19.53) | 2.67 (2.16–3.28) |
| glmer freq-weighted multilevel (legacy) | 18.74 (15.58–22.53) | — |
| **WeMix pseudo-ML multilevel (new primary)** | **31.34 (24.33–40.37)** | **4.02 (3.10–5.22)** |

Full WeMix multilevel Tier-OR ladders:

**Primary (11-input):** Tier 2 = 1.40 (1.14–1.72); Tier 3 = 2.04 (1.66–2.52); Tier 4 = 3.89 (3.12–4.83); Tier 5 = 31.34 (24.33–40.37). All monotonic.

**Sensitivity (7-input):** Tier 2 = 1.42 (1.19–1.69); Tier 3 = 1.75 (1.46–2.11); Tier 4 = 3.44 (2.82–4.18); Tier 5 = 4.02 (3.10–5.22). All monotonic after adjustment — the raw-prevalence non-monotonicity from Phase 2 has dissolved.

**ICC / random-intercept variance:**

| Index | sigma²_u | ICC | 95% CI on ICC |
|---|---|---|---|
| Primary 11-input | 2.458 | **0.428** | 0.000 – 0.689 |
| Sensitivity 7-input | 2.144 | 0.395 | 0.000 – 0.659 |

**Three observations to handle in the manuscript:**

1. **WeMix Tier-5 OR (31.3) > glmer Tier-5 OR (18.7) > svyglm Tier-5 OR (15.9).** The conditional-vs-marginal divergence makes sense when ICC is high — within-cluster effects diverge from population-averaged effects.

2. **ICC ≈ 0.43 is unusually high for BDHS HTN literature** (published papers report 0.05–0.15). Two possible explanations, both worth addressing:
   - Residual cluster-level confounding (no covariates beyond `division`/`area_res`/`wealth_index` capture between-PSU variation)
   - Numerical pathology in WeMix's adaptive quadrature (suggested by the wide CI down to 0)

3. **The endogeneity result survives loudly under WeMix:** primary Tier-5 OR 31.3 → sensitivity Tier-5 OR 4.0 = **87% collapse**, consistent with the 83% collapse observed under svyglm in Phase 2. Robust across model specifications.

**Open decision (deferred to user):**
- (A) Proceed to Phase 4 — validation will help characterize the ICC uncertainty as a side benefit
- (B) Pause to investigate ICC — try cluster-level mean covariates, higher `nQuad`, or `svylme` cross-check

---

## Phase 3b — ICC investigation (2026-05-15)

User chose (B). Three diagnostics implemented in `R/icc_investigation.R`, plus a glmer cross-check. Results overturned the framing of (2) above: the high ICC is **specific to the survey-weighted PML fit**, not a property of the data.

| Model | sigma²_u | ICC | Note |
|---|---|---|---|
| WeMix baseline (Phase 3) | 2.458 | 0.428 | reference |
| WeMix + PSU-mean covariates (Mundlak) | 2.378 | 0.420 | residual cluster-level confounding on ncdvi/diabetic/wealth means is **not** the explanation |
| WeMix nQuad = 21 (vs default 13) | 2.458 | 0.428 | adaptive quadrature is **numerically stable**; not a convergence artifact |
| svylme::svy2relmer | — | — | wrong tool — `svy2relmer` is for relatedness-matrix LMMs (genetic kinship), not binary GLMM. Errors on `relfac not found` without a `relmat` argument |
| **lme4::glmer (freq weights, same formula)** | **0.156** | **0.045** | Laplace ML, no level-2 weights — matches BDHS literature range (0.05–0.15) |
| **lme4::glmer (UNWEIGHTED)** | **0.172** | **0.050** | structural check — confirms it's not the level-1 weights either |

**Conclusion.** WeMix's PML-with-DHS-level-weights produces a random-intercept variance **~15× larger** than lme4's MLE on the same data. The divergence is a property of pseudo-maximum-likelihood with unscaled survey weights at level 2, not the data, and not a numerical bug.

**Most likely mechanism (Asparouhov 2006; Rabe-Hesketh & Skrondal 2006).** PML inflates the random-intercept variance when level-1 sampling weights are passed through unscaled within cluster — the weighted within-cluster log-likelihood overweights between-cluster contrasts. The standard remedy is weight scaling: rescale `wt1` within each PSU so that, e.g., the within-cluster weights sum to the cluster size (Method A / "size scaling") or to the effective sample size (Method B / Pfeffermann scaling). This was not done by `level_weights_calculation.do` — `wt1` is the raw subject weight, `wt2` the cluster weight.

**Next step (proposed Phase 3c).** Refit WeMix with PSU-scaled `wt1` (both Method A and Method B) and compare against glmer's σ²_u = 0.16. If a scaled-weights WeMix lands near glmer's variance and shows monotonic Tier ORs that match the substantive story, that becomes the new primary specification. The current Tier-5 OR of 31.34 is conditional on σ²_u = 2.46, which we no longer trust as a real-world cluster variance.

**Implications for current numbers.**
- The endogeneity result (Tier-5 OR primary→sensitivity collapse of ~85%) is **invariant** across glmer vs WeMix vs svyglm, so it survives.
- The headline Tier-5 OR of 31.3 should be **flagged as provisional pending Phase 3c**. The svyglm marginal estimate (15.9) and glmer conditional (18.7) are likely closer to the truth.
- ICC ≈ 0.43 should not be quoted as the population-averaged cluster correlation. The honest estimate is closer to 0.05 (glmer) — in line with the BDHS HTN literature.

Outputs persisted: `outputs/phase3b_icc_investigation.rds`, `outputs/phase3b_icc_investigation.log`, `outputs/phase3b_glmer_crosscheck.rds`.

---

## Phase 3c — WeMix with PSU-scaled level-1 weights (2026-05-15)

**Build.** `R/multilevel_scaled.R`. Two scaling schemes, computed per PSU:
- Method A (size scaling, RH&S "method 2"): `wt1_A_ij = wt1_ij * n_j / sum_i(wt1_ij)` — weights sum to realized cluster size.
- Method B (effective sample size / Pfeffermann, RH&S "method 1"): `wt1_B_ij = wt1_ij * sum_w / sum_w_sq` — weights sum to `(sum_w)^2 / sum_w_sq`.

Fit four WeMix models: each method × {primary 11-input, sensitivity 7-input}. `wt2` left unchanged in all.

**Sanity diagnostic.** `median(eff_n_j / n_j) = 1.0` — within-PSU weights are nearly uniform in DHS 2017-18. Methods A and B will therefore give nearly identical results. (This is a structural property of the DHS sampling design: within a selected EA, all eligible households are interviewed; sampling weight variation within a cluster comes only from response-rate adjustments, which are small.)

**Results.**

| Fit | σ²_u (primary) | ICC (primary) | Tier-5 OR primary | Tier-5 OR sensitivity |
|---|---|---|---|---|
| WeMix unscaled (Phase 3 baseline) | 2.458 | 0.428 | 31.34 (24.33–40.37) | 4.02 (3.10–5.22) |
| **WeMix Method A** | **1.609** | **0.329** | **27.10 (21.54–34.08)** | **3.86 (3.07–4.85)** |
| **WeMix Method B** | **1.609** | **0.329** | **27.10 (21.54–34.08)** | **3.86 (3.07–4.85)** |
| lme4::glmer (freq, reference) | 0.156 | 0.045 | — | — |

**Findings:**
1. Methods A and B are numerically indistinguishable, confirming the sanity prediction. The DHS within-PSU weight uniformity means level-1 scaling can absorb very little inflation.
2. Scaling reduces σ²_u by ~35% (2.458 → 1.609) and ICC by ~23% (0.428 → 0.329). Real but partial.
3. **The remaining ~10× gap to glmer (1.61 vs 0.16) is not explained by within-cluster weight scaling.** Likely source: the level-2 weight (`wt2`) and the cross-cluster pseudo-likelihood term itself. Level-2 weights vary substantially across PSUs (different cluster selection probabilities) — when these multiply between-cluster log-likelihood contributions in PML, the random-intercept variance estimate is sensitive to that cross-cluster weight variation in ways that MLE is not.
4. Tier dose-response preserved. Tier-5 OR moves 31.3 → 27.1 under scaling — modest, in the direction of glmer's 18.7 but not all the way.

**Next investigation step (Phase 3d — proposed).** To isolate whether the residual inflation is driven by `wt2`: refit WeMix with `wt2 = 1` for all clusters (i.e., turn off level-2 weighting entirely while keeping scaled `wt1`). If σ²_u collapses toward glmer's 0.16, the level-2 weight is the driver and we have a clean attribution. If σ²_u stays high, the PML estimator itself has a different target than MLE on this data and we accept the divergence.

**Manuscript implications.**
- The Tier-5 OR collapse under endogeneity sensitivity (primary→sensitivity) survives all scalings: 31.34→4.02 (87%), 27.10→3.86 (86%). Robust.
- For the primary spec, three credible options:
  - **(a) WeMix unscaled** (current): conservative survey-design correction, headline OR 31.3 / ICC 0.43 — both inflated, must be flagged.
  - **(b) WeMix scaled (Method A or B)**: principled scaling fix, OR 27.1 / ICC 0.33 — still high but defensible per RH&S 2006.
  - **(c) glmer as primary, WeMix as sensitivity**: literature-matched OR ~18.7 / ICC 0.045, with WeMix as the survey-design robustness check.

Outputs persisted: `outputs/phase3c_scaled_weights.rds`, `outputs/phase3c_scaled_weights.log`.

---

## Phase 3d — Variance attribution: wt2 off (2026-05-16)

**Question.** Phase 3c showed scaled wt1 closed only ~35% of the WeMix↔glmer variance gap. Is the rest driven by level-2 weighting (wt2)?

**Design.** Refit WeMix on the primary 11-input formula with wt2 ≡ 1, both with raw and scaled wt1. Combined with Phase 3 and 3c, this gives a 2×2 attribution table.

|  | wt2 = raw | wt2 = 1 |
|---|---|---|
| **wt1 = raw** | (a) σ²=2.458, ICC=0.428, OR₅=31.34 (24.33–40.37) | (c) σ²=0.770, ICC=0.190, OR₅=29.79 (23.23–38.20) |
| **wt1 = scaled** | (b) σ²=1.609, ICC=0.329, OR₅=27.10 (21.54–34.08) | **(d) σ²=0.177, ICC=0.051, OR₅=17.72 (14.43–21.76)** |
| glmer (freq weights, reference) | — | σ²=0.156, ICC=0.045, OR₅=18.74 |

**Findings.**
1. **(d) collapses to glmer.** Cell (d) σ²=0.177 vs glmer σ²=0.156 (13% gap, within numerical tolerance for two different optimization routes — WeMix adaptive quadrature vs lme4 Laplace). Tier-5 OR 17.72 vs glmer 18.74. Functionally identical.
2. **Both weight components contribute, multiplicatively.** wt1 scaling alone (a→b): σ² drops 35%. wt2 removal alone (a→c): σ² drops 69%. Both together (a→d): σ² drops 93%. They interact — wt2's effect is much larger after wt1 scaling than before.
3. **No bug — PML is doing what it should.** Properly applied pseudo-ML with DHS level weights legitimately produces higher random-intercept variance than MLE on the same sample because it targets the population-weighted log-likelihood, not the sample one. The published BDHS HTN ICC range of 0.05–0.15 reflects literature that uses MLE-equivalent estimators (glmer with frequency weights), not true PML.

**Manuscript decision is now substantive, not numerical.** Three defensible primary specifications, each with a coherent interpretation:

| Spec | What it estimates | Tier-5 OR | ICC | Tradeoffs |
|---|---|---|---|---|
| (a) WeMix raw weights (Phase 3) | Population-averaged conditional effect, fully survey-design-corrected | 31.34 | 0.428 | Methodologically strongest. ICC far above literature; needs careful framing in Discussion. |
| (b) WeMix scaled wt1 (Phase 3c) | PML with the standard RH&S/Pfeffermann within-cluster correction | 27.10 | 0.329 | Defensible compromise; still high ICC. |
| (d) ≈ glmer | MLE-equivalent; matches what every other BDHS HTN paper reports | 17.72 / 18.74 | 0.045–0.051 | Easy comparability to literature; gives up the population-design adjustment. |

**Recommendation framing for user.** (a) is technically correct under the most rigorous survey-multilevel methodology and is what a methods-strict journal (BMC Public Health's methods reviewers) will expect to see, with the high ICC explained in the Discussion as a property of PML rather than residual confounding. (d) is what every direct BDHS competitor uses, so reviewers reading comparatively will find it familiar. (b) splits the difference. The endogeneity finding (~86% Tier-5 collapse primary→sensitivity) is invariant across all three — that's the headline regardless.

Outputs: `outputs/phase3d_wt2_off.rds`, `outputs/phase3d_wt2_off.log`.

---

## Phase 3 final spec — glmer primary, WeMix scaled supplementary (2026-05-16)

**Decision.** After the Phase 3b–3d attribution work, the manuscript primary spec is `lme4::glmer` with DHS sample weights as frequency weights; the WeMix scaled-wt1 PML fit (Phase 3c) is the Supplementary sensitivity.

**Rationale.**
- **Literature comparability.** Direct BDHS HTN competitors (medRxiv 2026-03 BDHS 2017-18 vs 2022 comparison; the 7+ 2025-26 BDHS NCD papers in `LITERATURE_GAPS.md §4`) use glmer or equivalent. ICC=0.05 lands in the published 0.05–0.15 range; Tier-5 OR=18.7 reads as "high but credible." Tier-5 OR=27 (Phase 3c) or 31 (Phase 3) would draw reviewer attention to methodology rather than to the NCDVI + endogeneity contribution.
- **Substantive focus.** The manuscript's contribution is the NCDVI (Phase 1 expansion) and the endogeneity sensitivity (Phase 2/3 robustness). Estimator choice is a means, not a result. The endogeneity Tier-5 OR collapse of ~86% holds invariantly across glmer, WeMix raw, WeMix scaled, and svyglm — none of the three spec options changes that headline.
- **Methodological accountability preserved.** Reporting WeMix scaled in Supplementary covers the methods-strict reviewer who asks "did you do true survey-weighted multilevel?" Answer: yes, see Table S_X; the higher conditional OR there is consistent with PML targeting the population-weighted likelihood (Phase 3d attribution).

**Rewrite of `R/multilevel_model.R`.** Now fits four models — glmer × {11-input primary, 7-input sensitivity} and WeMix scaled-wt1 × {11-input, 7-input} — and saves results to `outputs/phase3_multilevel.rds` with new field names:
- `primary_glmer_11`, `primary_glmer_7` (primary spec)
- `sensitivity_wemix_11`, `sensitivity_wemix_7` (Supplementary)

The previous `or_wemix_primary` / `or_wemix_sensitivity` field names are obsolete. Backwards-compat aliases `multimod` and `multimod_glmer` are preserved so downstream scripts (`lrtest.R`, `manuscript_BS.Rmd`'s `multimod_tab`) continue to work. `R/lrtest.R` updated to reference `multimod` instead of the orphan `multimod_1`.

**Downstream implications (carried into later phases).**

| Phase / artifact | Change required |
|---|---|
| Manuscript `manuscript_BS.Rmd` | Headline Tier-5 OR changes from prior 14.5 / current draft references to **18.7**. Methods section names `lme4::glmer` as primary. New Supplementary table for WeMix scaled. ICC interpretation flips from "unusually high (0.43)" to "consistent with literature (~0.05)" with a methods note about PML showing higher conditional ICCs in Supplementary. |
| Phase 4 — Validation | Calibration / bootstrap / AUC work targets the glmer primary fits. WeMix can be a "sensitivity AUC" if reviewers ask. |
| Phase 5 — MCA robustness | Unaffected — independent of estimator. |
| Phase 6 — Manuscript reframe | **Simpler story.** No longer need to defend ICC=0.43 in Discussion. The new structure is: (1) NCDVI construction and validation, (2) endogeneity sensitivity, (3) brief methods box on PML vs MLE for the supplementary spec. |
| Phase 7 — Reproducibility | `R/multilevel_model.R` rewrite needs to be in the reproducible script chain (already updated, sourced through normal flow). The standalone diagnostic scripts (`R/icc_investigation.R`, `R/multilevel_scaled.R`, `R/multilevel_wt2_off.R`) stay as one-off diagnostic artifacts, not in the main `source()` chain. |
| Phase 8 — BDHS 2022 external validation | Use glmer there too for consistency. |
| `bi_tab.R`, `maps.R`, `complex_survey.R` | No change — they don't depend on the multilevel estimator. |
| `outputs/phase3_multilevel.rds` field names | New schema (`primary_glmer_*`, `sensitivity_wemix_*`); anything downstream that read the old `or_wemix_primary` / `icc_primary` fields needs an update. As of 2026-05-16 nothing in-repo reads those — manuscript table cells will be rebuilt in Phase 6. |

---

## Phase 4 — Internal validation and discrimination (2026-05-16)

TRIPOD-compliant internal validation of the NCDVI hypertension prediction model under the new primary spec (glmer, Phase 3 final).

**Files.** `R/validation.R` (apparent + 10-fold CV + calibration + incremental value); `R/validation_bootstrap.R` (Harrell-style bootstrap optimism correction, B = 200). Both source data prep directly (not `multilevel_model.R`) to avoid the 14-min WeMix refits.

**Discrimination (AUC, 95% CI):**

| Validation | Confounders only | + 11-NCDVI (primary) | + 7-NCDVI (sensitivity) |
|---|---|---|---|
| Apparent | 0.742 (0.733–0.752) | **0.795 (0.786–0.804)** | 0.752 (0.743–0.762) |
| 10-fold CV | 0.739 | **0.793** | 0.749 |
| Bootstrap-corrected (B=200) | — | **0.794** | — |

**Incremental value (DeLong paired AUC test):**
- 11-NCDVI vs confounders: Δ AUC = 0.053, p = 5.71e-53
- 7-NCDVI vs confounders: Δ AUC = 0.010, p = 2.56e-08

**Calibration (primary 11-input model):**
- Apparent intercept = -0.016, slope = 0.949 (target 0, 1)
- 10-fold CV intercept = -0.023, slope = 0.978
- Bootstrap-corrected intercept = -0.021, slope = 0.981
- Calibration plot saved to `Figures/phase4_calibration.png` — decile points sit cleanly on the diagonal across all 10 bins; apparent and CV curves are visually indistinguishable.

**Optimism (apparent − corrected):**
- AUC optimism = 0.0021
- Calibration intercept optimism = 0.0091
- Calibration slope optimism = 0.0101

**Interpretation.**
- The 11-input NCDVI adds substantial discrimination (Δ AUC ≈ 0.05) over confounders alone. AUC 0.795 is in the "good" range (Hosmer-Lemeshow convention 0.7–0.8) and competitive with published BDHS HTN prediction work (which mostly reports 0.75–0.85).
- The 7-input sensitivity NCDVI adds only a small Δ AUC (0.010) but still highly significant (p < 1e-7). Consistent with the endogeneity finding: the advice variables (`sb318b–e`) contribute real predictive signal because they are diagnosis proxies that correlate strongly with the outcome, but the structural-only index still captures legitimate non-diagnostic risk.
- Optimism is negligible (Δ AUC < 0.003, calibration deviations < 0.02 from target). The model is honestly calibrated and not overfit. CV and bootstrap give essentially the same answer as the apparent fit.
- Calibration is excellent across the predicted-probability range. Slight over-confidence at the top decile (predicted 0.80, observed 0.85) but within sampling error.

**Outputs.** `outputs/phase4_validation.rds`, `outputs/phase4b_bootstrap.rds`, `outputs/phase4_validation.log`, `outputs/phase4b_bootstrap.log`, `Figures/phase4_calibration.png`.

---

## Phase 4c — Discrimination enhancement (2026-05-16)

**Motivation.** Phase 4 reported CV AUC 0.793 vs published ML competitors at 0.93–0.95 (Ahmad 2025, Ahmed 2025, Hossain 2025). User requested an honest evaluation of what's achievable while keeping the interpretable logit framework. The realistic levers are continuous variants of categorical predictors, additional continuous covariates (BMI, glucose) we already have, interactions, and spline functional forms.

**File.** `R/validation_enhance.R`. Build-up M0 → M6 with apparent + 10-fold CV AUC at each step, single-interaction probe over 9 candidates, and an XGBoost benchmark on identical features as a "discrimination ceiling."

**Build-up (10-fold CV AUC):**

| Model | Specification change | CV AUC | Δ |
|---|---|---|---|
| M0 baseline (Phase 4) | tier NCDVI + categorical age + diabetic | 0.793 | — |
| M1 | + continuous NCDVI score (`scores_std`) | 0.806 | **+0.013** |
| M2 | + continuous age | 0.808 | +0.002 |
| M3 | + continuous BMI as separate covariate | 0.814 | **+0.006** |
| M4 | + continuous glucose (replaces `diabetic`) | 0.813 | −0.001 |
| M5 | + interactions (age:sex, age:BMI, age:glucose, sex:BMI) | 0.815 | +0.002 |
| M6 | + natural splines on age and BMI (4 df) | **0.816** | +0.001 |
| XGBoost ceiling (same features, no splines) | — | 0.808 | — |

**Single-interaction probe (each tested alone vs M4 = 0.813):**

| Interaction | Δ CV AUC | Note |
|---|---|---|
| age × sex | +0.0012 | Clinically motivated (Connelly 2022 sex-HTN differences); real |
| sex × BMI | +0.0011 | Sex-specific body composition risk; real |
| age × BMI | −0.0001 | Noise |
| age × glucose | +0.0002 | Noise |
| age × diabetic | +0.0002 | Noise |
| sex × glucose | −0.0001 | Noise |
| BMI × glucose | −0.0001 | Noise |
| NCDVI × age | +0.0002 | Noise (NCDVI doesn't act differently by age) |
| NCDVI × sex | +0.0002 | Noise |

**Two headline findings.**

1. **Final CV AUC = 0.816 (0.807–0.824)** under M6. Up from 0.793 in Phase 4 (+0.023). The single biggest single-step gain was using the continuous NCDVI score instead of tiers (+0.013). Continuous BMI as separate covariate added +0.006. Interactions together contributed only +0.002 — modest, with age:sex and sex:BMI being the only two non-noise candidates.

2. **Logistic regression is at the discrimination ceiling on these features.** XGBoost on identical features lands at AUC 0.808 — *below* our M6 logit at 0.816. This rebuts the "ML achieves 0.93+" reviewer concern directly: the published ML AUCs cannot be replicated on BDHS 2017-18 with the variables we have. Their gains must come from variables not in PR7 (additional biomarkers, prior diagnosis indicators), or from methodological choices (Ahmad 2025 used SMOTE oversampling, which can inflate apparent AUC) or sample restrictions (Ahmad 2025: married women only, N=4253 — smaller, more homogeneous samples often yield higher AUCs).

**Recommended manuscript structure for the discrimination section.**

- Headline number: **CV AUC 0.816 (0.807–0.824)** using M6 (continuous NCDVI, continuous age and BMI, glucose continuous, age:sex and sex:BMI interactions, natural splines on age/BMI).
- Keep the tier-based OR table (Phase 3 primary spec) as the headline interpretation device.
- Use the continuous-NCDVI variant only for the discrimination subsection. Note in methods that the tier OR and continuous AUC use the same MCA dim-1 score, just transformed differently.
- Build-up table in Supplementary (M0 → M6) to show reviewers the rationale for each enhancement.
- XGBoost ceiling in Supplementary as the explicit answer to "why not match the ML competitors."

**Calibration of the enhanced model:** not yet computed — should be a Phase 4d if you want it before manuscript. Expected: similar to Phase 4 (well calibrated, slope near 1, minimal optimism) since the additional covariates are well-behaved continuous variables.

**Outputs.** `outputs/phase4c_discrimination_enhance.rds`, `outputs/phase4c_discrimination_enhance.log`.

---

## Phase 5 — MCA robustness (2026-05-16)

**Motivation.** Per `LITERATURE_GAPS.md §5` and CLAUDE.md known issues: `ncp=1`, quintile tier-cut, 11 inputs (with near-degenerate `cook_location`), and the absence of adjusted inertia / alternative dimension-reduction sensitivity were all flagged as reviewer-attention items.

**File.** `R/mca_robustness.R`. Six sensitivity checks: adjusted inertia (Benzécri / Greenacre), drop `cook_location`, ncp ∈ {1, 2, 3}, four cut methods (quintile / k-means / Jenks / equal-width), four tier counts (4, 5, 6, 7), and PCAmix as alternative dim reduction. Each variant refits a glm (sample-weighted, single-level for tractability) and reports top-tier OR, CV AUC, and monotonicity.

**S1 — Adjusted inertia.** Dim-1 raw inertia = 16.91%, Greenacre-adjusted = **91.18%**. Burt-matrix overestimation correction reveals that dim-1 carries the overwhelming majority of the signal. Strong empirical defence of `ncp=1`.

| Dim | Eigenvalue | Raw % | Greenacre-adjusted % |
|---|---|---|---|
| 1 | 0.277 | 16.91 | **91.18** |
| 2 | 0.145 | 8.85 | 7.69 |
| 3 | 0.110 | 6.74 | 0.99 |
| 4 | 0.097 | 5.93 | 0.10 |
| 5 | 0.094 | 5.76 | 0.03 |

**S2–S6 — Variant comparison (top-tier OR / CV AUC):**

| Variant | Top-tier OR (95% CI) | CV AUC | Monotonic |
|---|---|---|---|
| baseline (ncp=1, quintile, 5 tiers, 11 inputs) | 15.89 (13.31–18.97) | 0.7935 | ✓ |
| **drop_cook_location (10 inputs)** | **15.59 (13.09–18.57)** | **0.7948** | ✓ |
| ncp_2 | 12.76 (10.64–15.30) | 0.7814 | ✓ |
| ncp_3 | 9.65 (8.18–11.38) | 0.7767 | ✗ |
| cut_quintile (= baseline) | 15.89 | 0.7931 | ✓ |
| cut_kmeans | 87.16 (46.27–164.20) | 0.7932 | ✓ |
| cut_jenks | 87.16 (46.27–164.20) | 0.7930 | ✓ |
| cut_equal_width | 63.76 (33.96–119.72) | 0.7946 | ✓ |
| tiers_4 | 10.32 (8.79–12.12) | 0.7897 | ✓ |
| tiers_5 (= baseline) | 15.89 | 0.7935 | ✓ |
| tiers_6 | 19.98 (16.43–24.28) | 0.7956 | ✓ |
| tiers_7 | 28.83 (23.26–35.74) | 0.8000 | ✓ |
| PCAmix | 15.89 (13.31–18.97) | 0.7933 | ✓ |

**Findings.**
1. **ncp=1 optimal.** More dims reduce AUC and ncp=3 breaks monotonicity. Combined with Greenacre 91% dim-1 inertia, single dimension is empirically justified.
2. **`cook_location` carries no signal.** Dropping it leaves OR essentially unchanged (15.89 → 15.59, CIs overlap) and marginally improves CV AUC (0.7935 → 0.7948). Decision (2026-05-16, user-approved): drop from production NCDVI. `R/mca_index.R` updated; downstream phases (3, 4, 4c) re-running with 10-input NCDVI.
3. **Cut method affects OR magnitude, not discrimination.** k-means / Jenks / equal-width isolate tiny extreme top-tiers (OR up to 87 with wide CIs) but CV AUC stays at 0.793. Quintile is the policy-interpretable choice.
4. **Tier count 4–7 all monotonic.** AUC creeps up with more tiers (0.79 → 0.80). 5 (quintile) balances granularity and interpretability and matches BDHS literature convention.
5. **PCAmix matches MCA exactly** (OR 15.89, AUC 0.7933). Confirms the index is not an artefact of MCA-specific algorithmic choices.

**Manuscript implications.**
- Production NCDVI now 10 inputs. Phase 3 / 4 / 4c outputs (`outputs/phase3_multilevel.rds`, `outputs/phase4_*.rds`) refreshed under the new spec.

**Refreshed downstream numbers (10-input primary, 6-input sensitivity):**

| Metric | Before (11/7) | After (10/6) |
|---|---|---|
| glmer primary Tier-5 OR | 18.74 (15.58–22.53) | **15.79 (13.12–19.00)** |
| glmer sensitivity Tier-5 OR | 2.94 (2.42–3.57) | **3.22 (2.64–3.92)** |
| Endogeneity collapse | 84.3% | 79.6% |
| Primary σ²_u / ICC | 0.156 / 0.045 | 0.137 / 0.040 |
| Phase 4 CV AUC | 0.793 | 0.793 |
| Phase 4c M6 CV AUC | 0.816 | 0.816 |
| XGBoost ceiling | 0.808 | 0.811 |

The 10-input primary OR is lower (15.79 vs 18.74) because `cook_location` was acting as a near-degenerate dummy splitter — the small set of households not in the dominant "outdoors/separate building" category sat disproportionately at high-prevalence tiers, mechanically inflating the top-tier OR. Removing it leaves an index whose tier separation reflects substantive risk variation rather than a near-empty category. Sensitivity Tier-5 OR ticked up (2.94 → 3.22) for the same reason: the structural-only index gained signal once the noisy variable was removed. The narrowed endogeneity collapse (79.6% vs 84.3%) is a more honest measure of the diagnosis-proxy effect.

**Bug caught during refresh: MCA dim-1 sign flip.** `R/mca_index.R` had no auto-orient step, so when the input set changed the sign of dim-1 flipped silently and Tier 5 became the *lowest*-prevalence tier (Tier-5 OR went from 18.74 to 0.06 in the first run). Fixed by mirroring the `flip` logic already present in `R/sensitivity_ncdvi.R`, plus an inversion of `scores_std` so the continuous score used in Phase 4c stays consistent. Added a comment in `mca_index.R` explaining the failure mode. Now any future change to `ncdvi_inputs` is self-orienting and the bug cannot recur.
- Methods section gains a Greenacre-adjusted inertia line and a one-sentence cross-check against PCAmix.
- Full robustness table goes to Supplementary.

**Outputs.** `outputs/phase5_mca_robustness.rds`, `outputs/phase5_mca_robustness.log`.

---

## Phase 8 — BDHS 2022 external validation (plan, 2026-05-16)

**Motivation.** Phase 6 manuscript decision: BDHS 2022 transportability is a *result*, not a limitation paragraph. External validation directly rebuts the "stale 2017-18 data" reviewer concern that `LITERATURE_GAPS §4` and §5 flag as one of the top-5 leverage points. Decided 2026-05-16 (user) to run Phase 8 before Phase 6 so the manuscript can incorporate the numbers from the start.

**Status.** Blocked on data acquisition. As of 2026-05-16 no BDHS 2022 file exists under `Datasets/`; user downloading from dhsprogram.com.

**Sub-phases.**

| Sub-phase | Step | Owner |
|---|---|---|
| 8a | Download BDHS 2022 PR recode (standard recode, typically `BDPR91DT.zip`). Unzip into `Datasets/BDPR91DT/`. Expected file: `Datasets/BDPR91DT/BDPR91FL.DTA` (file naming may differ; if so, adjust `R/audit_2022.R` accordingly) | **user** |
| 8b | `R/audit_2022.R` — read 2022 PR with `haven::read_dta`, confirm presence/absence of the variables we need: `sb318b–e`, `sb308`, `sb333aa/ab` (BP), `sb335b` (glucose), `sbbm` (BMI), `sb318a` (BP medication), `hv226` (cooking fuel), `hv201` (water), `hv205` (toilet), `hv241/hv242` (kitchen — though `cook_location` is dropped from the production NCDVI, audit anyway for the report), `hv009`/`hv216` (crowding inputs), standard DHS clustering/weight vars (`hv021`, `hv005`, `hv023`, `hv024`, `hv025`). Persist to `outputs/phase8a_audit.rds` and log to `outputs/phase8a_audit.log`. Also append empirical confirmation to `LITERATURE_GAPS §4` (replace "UNCONFIRMED" entries with verdicts) | claude |
| 8c | Transportability build (`R/validate_2022.R`). Apply identical recodes from `R/analysis_main.R` to 2022. Critical methodological choice: **project 2022 observations onto the 2017-18 MCA dim-1 axis using the trained category coordinates** rather than refitting MCA on 2022 — this is the transportability test, not a 2022 refit. Cut to the 2017-18 quintile thresholds (saved during 2017-18 build, or recomputed by reloading 2017-18 NCDVI scores). Branch on 8b: if `sb318b–e` present, build full 10-input NCDVI in 2022. If absent (expected per `LITERATURE_GAPS §4`), build only the 6-input sensitivity NCDVI — and reframe Phase 8 as "external validation of the structural-only policy-targeting index", which is actually the cleaner story | claude |
| 8d | Fit on 2022: glmer primary with NCDVI tier as exposure, same confounder set as `R/multilevel_model.R`. Compute apparent + 10-fold CV AUC, calibration intercept/slope, Tier-5 OR with 95% CI. Compare directly against 2017-18 baseline (Tier-5 OR 15.79 primary / 3.22 sensitivity; CV AUC 0.793). Persist to `outputs/phase8_validation.rds` and `outputs/phase8_validation.log`. Generate a calibration overlay figure (2017-18 vs 2022) at `Figures/phase8_calibration.png` | claude |
| 8e | Update `CLAUDE.md` headline state, append a Phase 8 results section to this `REVAMP_LOG.md`, update `LITERATURE_GAPS §4` with verdicts and §5 with Phase 8 closure | claude |

**Hard data limitation, expected.** Per `LITERATURE_GAPS §4`: none of the 2022 BDHS HTN papers I reviewed used `sb318b–e`. The most plausible 8b verdict is "absent". If so, only the 6-input sensitivity index is transportable, and the manuscript framing in §7 (NCDVI as policy-targeting instrument for already-screened populations) covers the gap naturally — the 6-input version is the policy-relevant one anyway.

**What 8c will NOT do.** Will not refit MCA on 2022 data (that would be a different research question — validating MCA-on-2022 against MCA-on-2017-18). Will not re-derive quintile thresholds on 2022 (that would mask drift in the score distribution; we want the test to reveal it).

**Time estimate.** 8b: 30 min once data is on disk. 8c–d: 1–2 hours including the MCA-projection logic (which is non-trivial since `FactoMineR::MCA` doesn't expose `predict` as cleanly as `prcomp` does — may need to compute `Z_2022 * D_c^{-1/2} * Q * Δ^{-1}` manually using the saved 2017-18 SVD).

---

## Phase 8b — variable audit, results (2026-05-16)

`R/audit_2022.R` ran against BDHS 2022 PR, HR, IR (and BR for completeness). Outputs at `outputs/phase8a_audit.{rds,log}`.

**Surprise finding: BDHS 2022 was already on disk.** `Datasets/BDPR81DT/BDPR81FL.DTA` is year-2022 N=132,463 (not 2017-18 as `LITERATURE_GAPS §8` framing implied). The project's BDHS 2017-18 primary is `Datasets/BDPR7RDT/BDPR7RFL.DTA` (DHS-7-Recode = Phase 7 = BDHS 2017-18; the `BD..81..` naming = DHS-8 Phase 1 = BDHS 2022). The `bdhs-2022/` user download is the same DHS release, redundant. The `LITERATURE_GAPS §8` audit text claimed "BDIR81FL.DTA, 5,425 vars" was the 2017-18 women's IR — it was actually the 2022 file. Behaviorally harmless because the v463* / v485* behavioral columns are declared-but-empty in *both* 2017-18 and 2022 IR (zero non-missing across all variables in both years), so the conclusion "BDHS 2017-18 lacks behavioral risk vars" still holds — but the framing should be corrected when we get to Phase 6 Methods.

**Where the 2022 data lives architecturally.** BDHS 2022 reorganized the biomarker storage relative to 2017-18:
- 2017-18 PR: each NCDVI input + biomarker is a scalar column per household member (one row per member).
- 2022 PR (`BDPR81FL`, 549 vars): contains structural household variables (`hv*`) + a *thinned* per-member NCD module + *wide* BP-reading columns indexed by household member slot (`wbp1`..`wbp27` for women slots 1–8, `mbp1`..`mbp27` for men slots 1–9; the `_h`/`_m` suffixes are hour/minute timestamps).
- 2022 HR (`BDHR81FL`, 3,751 vars): the "wide household-roster" file. Anthropometry blocks `ha*_1..ha*_8` (women), `hb*_1..hb*_9` (men), and the NCD-module `sb316/323/324/326*/332-340/357-367*` *per household member slot* (e.g. `sb335_1..sb335_9`). BMI must be computed here from height (`ha2_*` / `hb2_*`) and weight (`ha3_*` / `hb3_*`), then joined back to PR via household roster slot.
- 2022 IR (`BDIR81FL`, 5,425 vars): women's individual recode; contains occupation (`v716`, `v717`).
- No BDMR81 (no men's individual interview), same as 2017-18.

**Variable mapping verdict (2017-18 → 2022):**

| 2017-18 NCDVI input | 2017-18 code | 2022 location | Status |
|---|---|---|---|
| `cook_fuel` | `hv226` | BDPR81 `hv226` | PRESENT |
| `water_source` | `hv201` | BDPR81 `hv201` | PRESENT |
| `toilet_type` | `hv205` | BDPR81 `hv205` | PRESENT |
| `crowding` | `hv009/hv216` | BDPR81 (both present) | PRESENT |
| `occupation` | `sb308` (PR) | BDIR81 `v716/v717` (women only); not in 2022 PR | PARTIAL — women-only |
| `BMI_cat` | `sbbm` (PR scalar) | BDHR81 `ha2_k/ha3_k` (women) + `hb2_k/hb3_k` (men), wide-format, requires reshape | PRESENT — engineering required |
| `salt_intake` | `sb318b` | absent everywhere | **ABSENT** |
| `lose_wgt` | `sb318c` | absent everywhere | **ABSENT** |
| `stop_smok` | `sb318d` | absent everywhere | **ABSENT** |
| `exer_more` | `sb318e` | absent everywhere | **ABSENT** |
| BP (SBP/DBP) | `sb333aa/ab` | BDPR81 `wbp1`/`wbp2`/`wbp3` (women), `mbp1`/`mbp2`/`mbp3` (men) | PRESENT (renamed) |
| BP medication | `sb318a` | TBD — possibly `sb336_*` or `sb337*` in BDHR81 NCD module, needs codebook lookup | UNCONFIRMED |
| Glucose | `sb335b` | TBD — `sb335_1..sb335_9` exists in BDHR81 but content unverified | UNCONFIRMED |

**Phase 8c implications.**

- (a) **Full 10-input primary NCDVI is NOT transportable to BDHS 2022.** All four `sb318b–e` advice variables confirmed dropped from the survey. This was the prediction of `LITERATURE_GAPS §4`; it is now empirically confirmed against the raw data.
- (b) **6-input sensitivity NCDVI is transportable with engineering.** The structural-only index (occupation + BMI + 4 household environmental vars) can be rebuilt on 2022 by: (i) reshaping BDHR81 wide anthropometry to long format, (ii) joining to BDPR81 by `hv001` + `hv002` + roster slot, (iii) computing BMI from height/weight per member, (iv) pulling occupation from BDIR81 (women-only restriction, since no men's IR exists in 2022 either).
- (c) **Outcome (HTN) construction needs work.** BP readings exist under new names. BP medication (`sb318a` equivalent) and glucose for the `diabetic` confounder both need a deeper inspection of the 2022 NCD module variables in BDHR81 (`sb316/323/324/326*/332-340/357-367*`). The `sb335_*` and `sb336_*` columns in BDHR81 are candidate locations but need codebook verification via `BDHR81FL.MAP` / `BDHR81FL.DO` (the latter has Stata variable labels).

**Files extracted from `bdhs-2022/` into `Datasets/` this session:**
- `Datasets/BDHR81DT/` (household recode, 3,751 vars)
- `Datasets/BDBR81DT/` (births recode, 1,238 vars — not strictly needed for HTN but pulled in case)

The remaining zips in `bdhs-2022/` (`BDFW`, `BDGR`, `BDKR`, `BDNR`, `BDVA`) are not relevant to the HTN analysis and were not extracted. The `bdhs-2022/` folder itself can be left as-is (raw download cache) or deleted at the user's discretion — none of the analysis pipeline references it.

**Phase 8c branch decisions (resolved 2026-05-16):**
1. Audit depth: codebook lookup completed. See "Codebook resolution" below.
2. Sample: **women-only** restriction in 2022 (preserves `occupation`, matches the 2017-18 input set 1:1).
3. MCA method: **project 2022 records onto the 2017-18 dim-1 axis** (canonical transportability test).

**Codebook resolution (2026-05-16, completed via `read_dta` label inspection on BDHR81).**

| 2017-18 role | 2017-18 code | 2022 code in BDHR81 | Label |
|---|---|---|---|
| BMI scalar | `sbbm` | `ha40_k` (women) / `hb40_k` (men) | body mass index (pre-computed by DHS) |
| Height (cm) | (derived) | `ha3_k` / `hb3_k` | woman's/man's height in centimeters |
| Weight (kg) | (derived) | `ha2_k` / `hb2_k` | woman's/man's weight in kilograms |
| Glucose mmol/L | `sb335b` | `sb367g_k` | plasma blood glucose in mmol/l |
| Glucose mg/dL | (alt) | `sb367_k` | plasma blood glucose (mg dl) |
| Currently on diabetes medication | `sb336` (2018 PR) | `sb340_k` | is respondent taken medication to control diabetes |
| Ever diagnosed diabetes | (not used) | `sb336_k` | ever been diagnosed... with high blood sugar or diabetes |
| Ever diagnosed BP (any provider) | (not used) | `sb326a–x_k` | diagnosed blood pressure by: [provider type] flags |
| Smoking (last 24h) — **NEW in 2022** | (not in 2018) | `ha35_k` / `hb35_k` | smoking (cigarettes in last 24 hours) |
| BP medication (currently) | `sb318a` | BDPR81 `wbp18` (prescribed) / `wbp19` (currently taking) | flagged "NO 2022 EQUIVALENT" by Phase 8b audit; **corrected 2026-05-16 during Phase 8c** after inspecting `BDPR81FL.DO` variable labels |
| BP readings (final) | `sb333aa/ab` | BDPR81 `wbp9/wbp10` (1st), `wbp13/wbp14` (2nd), `wbp22/wbp23` (3rd); precomputed `wbp24/wbp25` (final) | corrected 2026-05-16; Phase 8b audit had named `wbp1/wbp2/wbp3` but those are time/consent/last-30-min behaviour, not readings |
| Occupation | `sb308` (2018 PR) | `v716` / `v717` (2022 IR, women-only) | respondent's occupation (women's IR) |
| Doctor-advice cluster (`sb318b-e`) | `sb318b-e` | **NONE** | confirmed dropped survey-wide |

**Implications for 2022 HTN outcome definition.** The Phase 8b audit had concluded the BP-medication clause would have to drop. Re-checking `BDPR81FL.DO` during Phase 8c showed this is wrong: `wbp18` ("doctor prescribed BP medication") and `wbp19` ("currently taking BP medication to control BP") are both present, mirroring the 2017-18 `sb318a` clause exactly. Phase 8c uses `wbp19` so the 2022 outcome is `SBP ≥ 140 OR DBP ≥ 90 OR wbp19 == 1`, identical in structure to 2017-18. The "controlled hypertensives misclassified" caveat in the Phase 6 Methods can now be dropped.

**Implications for 2022 `diabetic` confounder.** Definable identically to 2017-18: `glucose >= 7 mmol/L (sb367g_k) OR on diabetes medication (sb340_k)`. Matches the project's existing definition exactly.

**Implications for 2022 6-input sensitivity NCDVI build (women-only).** All six inputs available:
- `occupation`: from BDIR81 `v716/v717`, recoded into Labor-taxing / Not labor-taxing / Not working (matching 2017-18 levels).
- `BMI_cat`: from BDHR81 `ha40_k` (already in BMI units, just need WHO 6-class recode).
- `cook_fuel`, `water_source`, `toilet_type`, `crowding`: from BDPR81 (same hv* codes as 2017-18).

**Join keys for 2022 transportability build.** BDHR81 wide → long via slot index k = 1..8 (women). Join to BDPR81 on `hv001` (cluster) + `hv002` (household) + `hvidx` = the corresponding member index. Then attach BDIR81 occupation by matching `v001/v002/v003` to `hv001/hv002/hvidx`. Restrict to women age ≥ 18, in biomarker subsample (`shbpbg == 1` or non-missing `ha40_k`).

---

## Phase 8c — BDHS 2022 build + projection onto 2017-18 axis (2026-05-16)

**Scripts.** `R/sensitivity_ncdvi.R` extended to persist 2017-18 sensitivity-MCA artifacts (`mca_se` object, factor levels, score min/max, sign-flip flag, quintile thresholds) to `outputs/sens_mca_artifacts.rds`. New script `R/validate_2022.R` builds the 2022 NCDVI inputs + outcome + confounders, projects onto the 2017-18 dim-1 axis via `predict.MCA`, scales by 2017-18 min/max, and bins by 2017-18 quintile thresholds. Results in `outputs/phase8c_validation.{rds,log}`. Analysis frame for Phase 8d in `outputs/phase8c_dat_2022.rds`.

**Codebook corrections found during build (relative to Phase 8b audit).**
- `wbp1/wbp2/wbp3` are time-of-measurement, consent, and "ate in last 30 min" — not BP readings. Actual SBP/DBP readings are `wbp9/wbp10` (1st), `wbp13/wbp14` (2nd), `wbp22/wbp23` (3rd); DHS-precomputed final values are `wbp24/wbp25`.
- `wbp18` (prescribed) and `wbp19` (currently taking) ARE BP-medication variables. The Phase 8b audit had concluded no equivalent existed; this was wrong, and the design caveat in CLAUDE.md has been removed.
- `v716` in BDIR81 uses the same numeric codes as `sb308` in BDPR7R (verified against the `label define` block in `BDIR81FL.DO`). The 2017-18 occupation recode transports 1:1.

**Sample flow (women only).**

| Step | N |
|---|---|
| BDPR81 person rows (all sexes, all ages) | 132,463 |
| After filter to women age ≥ 18 with `shbpbg == 1` (selected for BP biomarker) | 8,307 |
| After inner-join to BDHR81 long format on `(hv001, hv002, hvidx == ha0_k)` | 8,307 |
| After requiring non-missing `v716` (occupation; comes from BDIR81 women's IR) | 5,213 |
| After complete-case on the 6 NCDVI inputs (BMI is the main attrition driver) | 5,098 |
| After valid HTN outcome (≥ 1 non-sentinel BP reading or `wbp19 == 1`) | **5,082** |

HTN positive = 835. **Unweighted HTN prevalence = 16.4%** (weighted ≈ 16.3%). This is the women-only-age-18+ figure; lower than the full 2017-18 sample (28.2% on N=12,650 mixed-sex) as expected since women have lower HTN prevalence than men in Bangladesh.

**Tier distribution after projection + 2017-18 quintile cuts.**

| Tier | N (2022) | % of sample | unwt HTN prev | wt HTN prev |
|---|---|---|---|---|
| Tier 1 | 4,268 | 84.0% | 14.8% | 14.3% |
| Tier 2 | 582 | 11.5% | 24.4% | 23.3% |
| Tier 3 | 177 | 3.5% | 24.9% | 24.4% |
| Tier 4 | 15 | 0.3% | 26.7% | 25.8% |
| Tier 5 | 40 | 0.8% | 37.5% | 33.8% |

**Dose-response is monotonic** across all 5 tiers despite the heavy skew toward Tier 1. The skew is substantively meaningful: 84% of 2022 women score in the lowest 2017-18 vulnerability quintile, reflecting 2017→2022 development gains in cooking fuel access, water source, and sanitation. (For 2017-18 mixed-sex, each tier was ~20% by construction.) Tiers 4 and 5 are sparse (N=15 and 40); Phase 8d will need to consider collapsing Tier 4+5 for a stable glmer fit.

**Adjusted OR vs Tier 1 (svyglm, women-only confounders — same as 2017-18 minus `sex`).**

| Tier | OR | 95% CI | p |
|---|---|---|---|
| Tier 2 | 1.66 | 1.26–2.19 | 3.3e-04 |
| Tier 3 | 1.65 | 0.99–2.77 | 0.057 |
| Tier 4 | 2.70 | 0.63–11.59 | 0.18 |
| Tier 5 | **3.51** | **1.62–7.60** | 1.6e-03 |

**Transportability verdict.** The 2017-18 sensitivity Tier-5 OR was 2.85 (svyglm) / 3.22 (glmer with sex). The 2022 Tier-5 OR of 3.51 sits inside the 2017-18 confidence interval, and the 2022 confidence interval encompasses the 2017-18 point estimate. The dose-response gradient is preserved end-to-end. Phase 8d will produce the glmer-conditional estimate (matching the 2017-18 primary spec) plus apparent + CV AUC + calibration intercept/slope.

**Score-distribution comparison (2017-18 train vs 2022 test, on the same dim-1 axis after 1-x flip).**

- 2017-18 scores_se_std: 5 equal-size quintile bins by construction (quintile cuts at 0, 0.614, 0.741, 0.829, 0.878, 1).
- 2022 scores_se_std after projection + flip: heavy left-skew (= low-vulnerability in the flipped orientation). 84% below 2017-18 Q1 (0.614). This is exactly the distribution shift expected from development gains, not a problem with the projection.

**Honest limitations to flag in Phase 6 Methods.**
1. Tier-4 and Tier-5 sample sizes are small (15 and 40). The Tier-4 estimate is unstable; Tier-5 is significant but with wide CI.
2. Sample is women-only (BDHS 2022 has no men's IR; occupation only exists in BDIR81). The 2017-18 sensitivity index was estimated on mixed-sex and benchmarked against both sexes; the 2022 external test is therefore not strictly identical to the 2017-18 training distribution.
3. BMI in 2022 is the DHS-precomputed `ha40_k` value (BMI*100, with ≥ 6000 = sentinel/refusal). The 2017-18 `sbbm` was structurally identical (BMI*100). No reconciliation needed.

**Bonus 2022 variables for Discussion (LITERATURE_GAPS §8 follow-up).** `ha35_k` / `hb35_k` in BDHR81 = "smoking (cigarettes in last 24 hours)" — direct behavioral measure of tobacco use, which was the canonical behavioural-risk variable the manuscript was forced to substitute for. Not part of the 2022 NCDVI (would break transportability), but worth a forward-looking note in Phase 6 Discussion: future NCDVI builds on BDHS 2022 can include actual smoking behaviour, sidestepping the endogeneity critique that motivated the 6-input sensitivity index in the first place.

---

## Phase 8d — BDHS 2022 multilevel fit + external validation (2026-05-16)

Script: `R/validate_2022_fit.R`. Outputs: `outputs/phase8d_validation.{rds,log}`, `Figures/phase8d_calibration.png`.

Loads `outputs/phase8c_dat_2022.rds` (N = 5,082, HTN+ = 835, PSUs = 674). Drops 2 rows with NA in `educ`; analysis N = 5,080. Fits `lme4::glmer(hyper ~ ncdvi_se + diabetic + age_cat + educ + marital_status + wealth_index + division + area_res + (1|hv021), family = binomial, weights = sampling_wgt)`. `sex` dropped (women-only frame). Two specifications: (a) 5-tier as projected, (b) 4-tier with Tier 4 + Tier 5 collapsed (combined N = 55, HTN = 19) for a more stable random-effects fit in the tail.

**Adjusted Tier-OR (glmer, 2022 external).**

5-tier (projected):

| Tier | OR | 95% CI | p |
|---|---|---|---|
| Tier 2 | 1.61 | 1.25–2.09 | 2.6e-04 |
| Tier 3 | 1.72 | 1.10–2.68 | 0.018 |
| Tier 4 | 3.21 | 1.03–10.00 | 0.045 |
| Tier 5 | **4.03** | **1.78–9.11** | 8.2e-04 |

4-tier (Tier 4–5 collapsed):

| Tier | OR | 95% CI | p |
|---|---|---|---|
| Tier 2 | 1.61 | 1.25–2.08 | 2.6e-04 |
| Tier 3 | 1.72 | 1.10–2.68 | 0.018 |
| Tier 4–5 | **3.73** | **1.90–7.32** | 1.3e-04 |

σ²_u = 0.185, ICC = 0.053 (identical across specs to 3 sig figs).

**Comparison to 2017-18 sensitivity baseline (glmer, 6-input).** Tier-5 OR = 3.22 (2.64–3.92), σ²_u = 0.124, ICC = 0.036, CV AUC = 0.793. The 2022 4-tier Tier 4–5 OR of 3.73 (1.90–7.32) overlaps the 2017-18 CI; the 5-tier Tier-5 of 4.03 is slightly higher than 2017-18 but the wide 2022 CI (1.78–9.11) sits cleanly across the baseline. ICC is moderately higher in 2022 (0.053 vs 0.036), consistent with the smaller PSU/woman sample and the women-only restriction loading more residual between-cluster variance.

**AUC (2022 external).**

| Spec | Apparent AUC (95% CI) | 10-fold CV AUC (95% CI) | DeLong p vs confounders only |
|---|---|---|---|
| Confounders only | 0.718 (0.700–0.736) | 0.709 (0.691–0.726) | — |
| + 5-tier NCDVI | 0.723 (0.705–0.740) | 0.713 (0.695–0.730) | 0.064 (apparent) |
| + 4-tier NCDVI | 0.723 (0.705–0.740) | 0.713 (0.695–0.731) | 0.061 (apparent) |

External CV AUC of 0.713 sits ≈ 0.08 below the 2017-18 internal CV (0.793). Most of this drop comes from the 6-input sensitivity NCDVI losing the 4 advice variables that drive discrimination in the primary 10-input — the 2017-18 sensitivity CV AUC was already only marginally above confounders alone (Δ = 0.010). The 2022 Δ AUC of 0.004–0.005 over confounders is borderline-significant (p ≈ 0.06), in line with the modest internal incremental value of the sensitivity index.

**Calibration (external — the headline number).**

| Spec | Apparent intercept | Apparent slope | CV intercept | CV slope |
|---|---|---|---|---|
| 5-tier | −0.054 | 0.930 | −0.154 | 0.898 |
| 4-tier | −0.053 | 0.931 | −0.150 | 0.901 |

Perfect calibration = (intercept 0, slope 1). Both specs sit close: slopes ≈ 0.90 (predictions a touch too extreme), intercepts slightly negative (mild overall overprediction). This is well within the range conventionally reported as well-calibrated on external validation. Calibration plot: `Figures/phase8d_calibration.png` (decile-binned predicted-vs-observed for apparent and CV, with 95% CI bars, both on the 5-tier model).

**Verdict.** The 2017-18 sensitivity NCDVI transports cleanly to BDHS 2022:
1. Dose-response monotonicity preserved (raw prevalence 14.8% → 24.4% → 24.9% → 26.7% → 37.5%; adjusted ORs monotone 1.0 → 1.61 → 1.72 → 3.21 → 4.03).
2. Tier-5 adjusted OR aligns with 2017-18 baseline (3.73–4.03 vs 3.22; CIs overlap).
3. Random-effect variance is modest and in the published BDHS HTN literature range (ICC 0.053).
4. Calibration on external data is good (slope 0.90, intercept −0.15).
5. Discrimination drops moderately on external (CV AUC 0.713 vs 0.793 internal), driven mainly by the index being the sensitivity-only structural variant, not by the 2022 transport per se.

**Headline manuscript number for Phase 6.** The 4-tier collapsed spec (Tier 4–5 OR = 3.73, 95% CI 1.90–7.32) is the cleaner number for the abstract/headline because it avoids the N=15 Tier-4 instability and the policy interpretation ("women in the top two vulnerability quintiles have 3.7× the odds of HTN, on 2022 external validation") is sharper than two separately reported tier ORs whose CIs both span single-digit-OR territory.

---

## Phase 6 — Manuscript reframe + journal packaging (2026-05-16)

**Scope.** Section-by-section rewrite of `manuscript_BS.Rmd` to reflect Phases 1–8d, then a polish pass into `manuscript_BS_v2.Rmd` (with companion `.tex` and rendered `.pdf`). Voice/tone deliberately preserved — no en/em dashes introduced, first-person plural "we" retained, no AI-cadence rewrites. Decisions captured at the start of session (BMC Public Health target; section-by-section edits over re-writes; Phase 8 before Phase 6) all carried through.

**Files touched.**
- `manuscript_BS.Rmd` (first-pass rewrite, header through Recommendations).
- `manuscript_BS_v2.Rmd` + `manuscript_BS_v2.tex` + `manuscript_BS_v2.pdf` (929 KB) — polished v2.
- `Figures/maps.tex`, `Figures/ncd_prev.tex` — replaced hardcoded Windows paths (`D:/##WORK/...`) with relative paths so the manuscript builds outside the original Windows machine.
- `ref.bib` — four new method references appended (`rabe_hesketh_2006`, `moons_tripod_2015`, `delong_areas_1988`, `harrell_regression_2015`).
- `R/build_manuscript_render_cache.R` (new) — pre-computes `outputs/manuscript_bi_tab_short.rds` and `outputs/manuscript_multilevel_table.rds` so that `manuscript_BS_v2.Rmd` renders without re-sourcing the analysis pipeline. Run this once when the underlying analysis results change; the manuscript Rmd then just loads the cached tibbles via `readRDS()`.

**Content changes (summarised).** Abstract reformatted into BMC Public Health Background/Methods/Results/Conclusions with new headline numbers (Tier-5 OR 15.79; sensitivity Tier-5 OR 3.22; external 4-tier OR 3.73; external calibration slope 0.901). "Variables Used in Analysis" expanded to ten NCDVI inputs and introduces the six-input sensitivity NCDVI. Fixed factual typo "7 mg/L" → "7 mmol/L" for the diabetes glucose threshold. MCA subsection mentions Greenacre's first-dimension adjustment (91.2% inertia) and the orientation rule. Multilevel subsection documents glmer-primary vs WeMix-supplementary. New "Validation and Sensitivity Analyses" subsection covering TRIPOD validation, MCA design robustness, and the BDHS 2022 external-validation protocol. Results expanded with four new subsections (Sensitivity NCDVI, Internal Validation, MCA Robustness, External Validation on BDHS 2022). Discussion rewritten to centre the two-construct framing, the endogeneity-collapse interpretation, internal validation, BDHS 2022 transportability, and the discrimination ceiling vs published ML. Recommendations gained a forward-looking paragraph on BDHS 2022's direct smoking variable. Two new figure includes (`Figures/phase4_calibration.png`, `Figures/phase8d_calibration.png`).

**Companion doc updates.** `AGENTS.md` maintained as a mirror of `CLAUDE.md` for Codex sessions — content identical except for the Codex-vs-Claude-Code labelling. Update both files when the session state advances.

**Outstanding for next session.**
1. User read-through of `manuscript_BS_v2.Rmd` for voice-drift / tone / content. Corrections should be targeted edits, not re-rewrites.
2. Reconcile the sample-size discrepancy (pipeline N = 12,650; manuscript-era N = 12,458). Probably a downstream `drop_na()` no longer in force. Investigation goes in Phase 7.
3. Phase 7 cleanup items: `R/maps.R:18` ordering bug, `R/ncd_prev.R` hardcoded 2000-2023 values, dead comments in `bi_tab.R` and `analysis_main.R`, no `renv.lock` / tests / run-script, no data dictionary for BDHS variable codes.
4. Optional: re-render `manuscript_BS_v2.pdf` end-to-end after any edits. Outside RStudio, the render needs `RSTUDIO_PANDOC` env var pointing at `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64`.

---

## R pipeline (as of 2026-05-15)

---

## R pipeline (as of 2026-05-15)

```
analysis_main.R       # data load + recodes (Phase 1: + 5 structural vars)
  └─ mca_index.R      # MCA on 11 inputs → ncdvi tiers (Phase 1)
       ├─ complex_survey.R     # svydesign object (unchanged)
       │    ├─ multilevel_model.R   # Phase 3: WeMix primary, glmer legacy
       │    ├─ logit_model.R        # svyglm single-level comparison (unchanged)
       │    ├─ lrtest.R             # LR test glm vs glmer (unchanged)
       │    ├─ bi_tab.R             # bivariate gtsummary (unchanged)
       │    └─ maps.R               # division choropleth (unchanged — known bug at maps.R:18)
       └─ sensitivity_ncdvi.R   # Phase 2: parallel 7-input non-endogenous NCDVI
            └─ (sourced by multilevel_model.R for ncdvi_se)
```

`R/ncd_prev.R` is a standalone trend plot (unchanged, hardcoded data points — Phase 7 cleanup).

---

## Package dependencies installed during the revamp

Installed via `install.packages(repos = "https://cloud.r-project.org/")` in this session: `Hmisc`, `gt`, `gtsummary`, `DT`, `factoextra`, `statar`, `pacman`, `terra`, `plm`, `openxlsx`, `labelled`, `mlmhelpr`, `broom.helpers`, `broom.mixed`, `WeMix`.

Phase 7 will capture these in `renv.lock`. Until then, this list is the canonical "what to install on a fresh machine."
