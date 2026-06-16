# Manuscript Review: Research Findings + Sanity Check

**Date:** 2026-06-08
**Target file:** `manuscript_BS_v2.Rmd`
**Inputs:** Perplexity web/scholar research (methodology best practices and reviewer expectations) summarized via NotebookLM, plus a numeric sanity check of the manuscript against the stored analysis outputs (`outputs/*.rds`).
**NotebookLM notebook:** "BS_project - NCDVI Hypertension Literature Review" (`dcde81d4`); source: "Perplexity Findings - NCDVI Methodology" (`c33f1293`).

This is a suggestions document for the authors to review, not a set of applied changes.

---

## 1. NotebookLM grounded summary of the research findings

**Executive summary.** Modern (2024-2026) prediction-index manuscripts are expected to follow TRIPOD / TRIPOD+AI: define the index's intended use (screening triage vs risk stratification vs policy targeting), report calibration and decision-theoretic utility (net benefit) alongside discrimination, and handle complex survey weights consistently across development and validation. MCA-based indices draw skepticism on construct validity, so authors are expected to show the index captures latent risk rather than only a socioeconomic gradient.

**Prioritized criticisms most likely to trigger major revision (per NotebookLM, grounded in the source):**
1. Reporting only discrimination (AUC) without calibration plots and decision curve analysis (DCA) / net benefit.
2. Survey-weight and clustering mismatches: unclear weight rescaling, or resampling that does not preserve PSU clusters, which can invalidate optimism corrections; also double-counting clustering (robust SEs plus a PSU random intercept).
3. Overfitting via data-driven tiers: MCA quintile cutpoints not recomputed within each resample, or leaked from training into external validation.
4. Endogeneity / reverse causation from clinician-advice variables, if not addressed via sensitivity analysis ("interpretation creep").
5. Lack of justification that MCA beats simpler alternatives (regularized logistic regression, factor analysis / IRT, wealth-index PCA).

**Strongest single defensive analysis to add (per NotebookLM):** a sensitivity analysis comparing MCA-tier performance against an alternative composite construction, culminating in a Decision Curve Analysis plotting net benefit of the NCDVI across threshold probabilities versus treat-all / treat-none.

---

## 2. Assessment: manuscript vs findings

The manuscript is already strong on several axes that the literature flags as common failure points. The gaps are concentrated in decision-utility reporting and a few validation-pipeline details.

### Already covered well (strengths)
- **TRIPOD adherence.** Cites Moons et al. 2015, includes a TRIPOD checklist (Appendix C / Supplementary File 1), defines outcome, population, and intended use. Good.
- **Calibration is reported.** Calibration intercept and slope plus decile calibration plots, both internally (intercept near 0, slope 0.95-0.99) and externally (intercept -0.150, slope 0.901). This pre-empts the single most common criticism (AUC-only reporting). Strong.
- **Endogeneity is handled head-on.** The six-input sensitivity index versus ten-input primary, and the two-construct framing (screening tool vs structural-targeting tool), is exactly the Model A vs Model B sensitivity analysis reviewers ask for. This is ahead of the typical paper in this space and is the manuscript's clearest methodological contribution.
- **External validation with a fixed pipeline.** BDHS 2022 tiers are assigned using 2017-18 cutoffs and the supplementary-points projection with no refit of cutpoints, which is the correct transportability protocol.
- **MCA design robustness.** Dimensions retained, cutoff method, tier count, and PCAmix substitution are all varied. Greenacre adjustment (91.2%) is reported to defend ncp = 1.
- **Discrimination-ceiling argument.** The extended logit (CV AUC 0.816) versus gradient boosting (0.811) directly answers "why not ML," showing the interpretable model is at the feature-set ceiling.

### Gaps to address (prioritized)

**HIGH - Decision curve analysis / net benefit is absent.** The manuscript reports AUC and calibration but no DCA or net benefit, while explicitly framing both indices as screening / triage / policy-targeting tools. This is the literature's number-one current expectation and the most likely major-revision trigger. Recommended: add DCA for the ten-input (internal) and six-input (internal + external) models versus treat-all / treat-none.

**MEDIUM - Possible information leakage in internal validation tiers.** The MCA is fit once on the full sample and the quintile cutpoints are then carried into ten-fold CV and the bootstrap. Reviewers increasingly ask whether the MCA scoring and quintile cutpoints were recomputed inside each fold/resample; if not, apparent and CV performance are mildly optimistic. The reported optimism (0.002) is small, but the manuscript should state explicitly whether the MCA step was inside or outside the resampling loop, and ideally show a fold-internal-MCA variant.

**MEDIUM - Survey weights treated as frequency weights.** The primary spec uses `glmer` with the BDHS individual weight as a frequency weight on the binomial likelihood. This is defended as the BDHS-literature convention and the WeMix PML supplementary is provided, but treating sampling weights as frequency weights can understate standard errors (the very tight primary CIs, e.g. Tier 5 OR 15.79 [13.12, 19.00], are partly a consequence). Two specific reviewer points to pre-empt: (a) state whether CV/bootstrap resampled individuals or PSU clusters and how weights were preserved; (b) confirm the same weighting scheme is used in development and validation. Consider citing the design-weight multilevel guidance (e.g. PMC2717116; JRSS-A 169:805) in the weights paragraph.

**LOW-MEDIUM - MCA not benchmarked against a simpler composite.** Robustness substitutes PCAmix (close cousin of MCA) but does not compare against a wealth-index-style PCA or regularized logistic regression on the raw items, nor a factor-analytic / IRT construction. A one-row comparison would close the "is MCA worth it" question and address construct validity (that the index is more than a socioeconomic gradient).

**LOW - Positioning against specific 2024-2026 BDHS competitors.** The Discussion references "ML classifiers at AUC 0.90+" generically. Naming and citing the recent BDHS 2017-18 / 2022 hypertension papers (including the double-machine-learning causal paper and any 2026 multilevel BDHS comparison) would sharpen novelty positioning. See `LITERATURE_GAPS.md` for the competitor list already compiled.

---

## 3. Data sanity check (manuscript numbers vs stored outputs)

Every headline number checked in `manuscript_BS_v2.Rmd` matches the stored analysis artifacts. Verified by reading `outputs/phase3_multilevel.rds`, `outputs/phase4_validation.rds`, and `outputs/phase8d_validation.rds`.

| Claim in manuscript | Manuscript value | Stored output | Match |
|---|---|---|---|
| Primary 10-input Tier 5 OR | 15.79 (13.12, 19.00) | `primary_glmer_11`: 15.79 (13.12, 19.00) | yes |
| Primary Tier 3 / Tier 4 OR | 1.66 / 2.69 (2.28, 3.18) | 1.66 / 2.69 (2.28, 3.18) | yes |
| Primary sigma2_u / ICC | 0.137 / 0.040 | 0.137 / 0.0401 | yes |
| Sensitivity 6-input tier ORs | 1.25, 1.32, 2.46, 3.22 (2.64, 3.92) | `primary_glmer_7`: 1.25, 1.32, 2.46, 3.22 (2.64, 3.92) | yes |
| Sensitivity sigma2_u / ICC | 0.124 / 0.036 | 0.1237 / 0.0362 | yes |
| Internal apparent AUC | 0.796 (0.787, 0.805) | `phase4$apparent` primary: 0.7867 / 0.7956 / 0.8045 | yes |
| Internal CV AUC | 0.793 | `phase4$cv10` primary: 0.7935 | yes |
| Delta AUC primary vs confounders | 0.053 | 0.7956 - 0.7421 = 0.0535 | yes |
| Delta AUC sensitivity vs confounders | 0.008 | 0.7503 - 0.7421 = 0.0082 | yes |
| External sample N / HTN+ | 5,080 / 835 | `phase8d`: 5080 / 835 (prev 0.164) | yes |
| External 5-tier Tier 5 OR | 4.03 (1.78, 9.11) | `fit5`: 4.03 (1.78, 9.11) | yes |
| External 4-tier Tier 4-5 OR | 3.73 (1.90, 7.32) | `fit4`: 3.73 (1.90, 7.32) | yes |
| External sigma2_u / ICC | 0.185 / 0.053 | 0.1848 / 0.0532 | yes |
| External CV AUC | 0.713 (0.695, 0.731) | `fit5` cv10: 0.6947 / 0.7125 / 0.7303 | yes |

**Numeric integrity verdict:** high. The v2 draft faithfully reports the pipeline outputs; no transcription errors found in the headline results.

### Data items still open (not errors, but worth resolving before submission)
- **Sample-size reconciliation.** The abstract and Methods report N = 12,650 for BDHS 2017-18. The project's own notes flag a manuscript-era figure of 12,458, attributed to a downstream `drop_na()` no longer in force. This is unreconciled in the repo (a Phase 6/7 TODO). A reviewer will expect a STROBE-style participant flow that lands on a single, traceable N.
- **External top-tier sparsity.** In the 2022 five-tier spec, Tier 4 has N = 15 (OR 3.21 with CI 1.03 to 10.00) and Tier 5 is also thin. The manuscript correctly collapses to a four-tier spec for the headline (Tier 4-5 OR 3.73), which is the right call; just ensure the sparsity and the collapse rationale are stated where the five-tier number appears.

### Minor textual issues spotted while reading
- Table caption (multilevel results) reads "analysis of hyphenation on NCD Vulnerability Index" - "hyphenation" should be "hypertension."

---

## 4. Suggested next actions (in priority order)
1. Add Decision Curve Analysis / net benefit (internal ten-input and six-input; external six-input). Highest payoff for reviewer expectations.
2. State explicitly whether MCA scoring and quintile cutpoints sit inside or outside the CV/bootstrap loop; add a fold-internal-MCA optimism check if feasible.
3. Tighten the survey-weights paragraph: clarify resampling-with-weights handling, confirm consistent weighting across development and validation, and cite design-weight multilevel guidance.
4. Add a one-row benchmark of the MCA tiers against a simpler composite (wealth-index PCA or penalized logistic on raw items) to defend construct and predictive validity.
5. Reconcile the 12,650 vs 12,458 sample size and add a participant-flow paragraph.
6. Cite specific 2024-2026 BDHS hypertension competitors in the Discussion.
7. Fix the "hyphenation" caption typo.
