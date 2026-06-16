---
title: "Additional file 3: Supplementary Sensitivity Tables"
geometry: margin=2.2cm
---

# Additional file 3. Supplementary Sensitivity Tables

Supplementary tables for the manuscript *"A Multiple Correspondence Analysis Approach to Mitigate the Non-Communicable Disease (NCD) Epidemic: Introducing a Health-Related Behavior-Based NCD Vulnerability Index."*

## Table S1. Multilevel estimator comparison on the ten-input primary NCDVI

The primary specification (`glmer` with the sample weight as a frequency weight) is the literature-matched estimator. The supplementary specification (`WeMix::mix` pseudo maximum likelihood with cluster-scaled level-one weight) is the fully survey-design-corrected estimator.

| Specification | Tier 5 OR | 95% CI | Var(u) | ICC |
|---|---|---|---|---|
| glmer, weights as frequency weights (primary) | 15.79 | [13.12, 19.00] | 0.137 | 0.040 |
| WeMix::mix, scaled level-one weight (supplementary) | 27.10 | [21.54, 34.08] | 1.609 | 0.329 |

## Table S2. MCA design alternatives

Each row varies a single design choice. The production specification is the first row.

| Variant | Tier 5 OR | CV AUC | Monotonic? |
|---|---|---|---|
| ncp=1, quintile cut, 5 tiers, MCA (production) | 15.79 | 0.793 | Yes |
| ncp=2 | 14.6 | 0.791 | Yes |
| ncp=3 | 12.4 | 0.789 | No |
| Equal-width cut | 18.2 | 0.793 | Yes |
| Jenks natural-break cut | 16.5 | 0.792 | Yes |
| k-means cut | 17.1 | 0.793 | Yes |
| 4 tiers | 12.0 | 0.793 | Yes |
| 6 tiers | 18.0 | 0.793 | Yes |
| 7 tiers | 20.1 | 0.793 | Yes |
| PCAmix instead of MCA | 15.8 | 0.793 | Yes |
| Cooking location removed | 15.79 | 0.793 | Yes |

## Table S3. Endogeneity sensitivity: Tier 5 odds ratio across NCDVI versions

| NCDVI | Inputs | Tier 5 OR | 95% CI | Tier 5 collapse vs ten-input |
|---|---|---|---|---|
| Ten-input primary | All 10 | 15.79 | [13.12, 19.00] | reference |
| Six-input sensitivity, 2017-18 | Structural only | 3.22 | [2.64, 3.92] | -80% |
| Six-input sensitivity, BDHS 2022, 5-tier | Structural only | 4.03 | [1.78, 9.11] | -75% |
| Six-input sensitivity, BDHS 2022, 4-tier collapsed | Structural only | 3.73 | [1.90, 7.32] | -76% |

## Table S4. Discrimination ceiling: M0 to M6 build-up and gradient-boosted comparison

| Model | Cross-validated AUC |
|---|---|
| M0: confounders only | 0.740 |
| M1: M0 plus categorical NCDVI tier | 0.793 |
| M2: M1 with continuous NCDVI score | 0.806 |
| M3: M2 plus continuous BMI | 0.812 |
| M4: M3 plus age-by-sex interaction | 0.814 |
| M5: M4 plus sex-by-BMI interaction | 0.815 |
| M6: M5 plus natural splines on age and BMI | 0.816 |
| Gradient-boosted tree on the M6 feature set | 0.811 |
