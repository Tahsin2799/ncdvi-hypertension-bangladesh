# Literature gaps and improvement directions

Synthesis of a 2026-05-15 scan of 2023–2026 literature relevant to the NCDVI manuscript. Cites only URLs I retrieved live this session — no fabrications.

---

## 1. The single biggest issue (flag before anything else)

**Endogeneity in the NCDVI construction.** Four of the six index inputs — *advised to reduce salt* (`sb318b`), *advised to lose weight* (`sb318c`), *advised to stop smoking* (`sb318d`), *advised to exercise more* (`sb318e`) — only fire if a person has **already been seen by a clinician for elevated BP or related conditions**. In other words, the "vulnerability index" is partly a proxy for *already being a diagnosed patient*.

This plausibly explains the headline OR of 14.5 (Tier 5 vs Tier 1) and the cliff from Tier 4 (26% prev) → Tier 5 (72% prev). A reviewer will frame it as: "you've predicted hypertension using variables that exist *because* people have hypertension." It also conflicts with the framing of "early detection / vulnerability before disease onset."

**Mitigations the manuscript can deploy:**
- Sensitivity analysis: rebuild NCDVI using only `occupation` and `BMI_cat` (the two non-advice variables) and report whether the dose-response pattern survives.
- Reframe the index honestly: it's a *clinical vulnerability flag*, useful for tier-3-onward intervention prioritization in already-screened populations, not a pre-screening tool.
- Better: pre-register a *prospective* validation by holding out a random 30% of clusters, fitting MCA on 70%, scoring the 30%, and reporting calibration + discrimination. Don't just refit on the same data.
- If keeping the advice variables, explicitly model the selection: who *gets* advice in the first place? Probably wealth + urban + educated. This is itself an inequality finding worth a paragraph.

---

## 2. Direct competition / overlap (must cite + differentiate)

These were published since the manuscript was conceived and use the same data or near-identical methodology:

- **OVERLAP** — Ahmad et al. (PLOS One, 2025), *"Predicting hypertension and identifying most important factors among married women in Bangladesh using machine learning approach,"* uses **BDHS 2017-18**, N=4,253 married women, ExtraTrees+SMOTE, AUC 0.95. ([journal](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0335442)) — Differentiate: their unit is married women only; manuscript covers all adults. Their goal is prediction accuracy; yours is interpretable vulnerability tiering.
- **OVERLAP** — Ahmed et al. (PLOS Comp Bio, 2025), *"Identifying predictors and assessing causal effect on hypertension risk among adults using Double Machine Learning models: Insights from BDHS,"* pooled **BDHS 2011–2022** (4 waves). RF AUC ~0.93. ([journal](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1013211)) — Differentiate: they emphasize causal inference of body weight on HTN; yours is a composite-index design with explicit policy targeting.
- **OVERLAP (heaviest)** — Anonymous, medRxiv preprint 2026, *"Shifting Prevalence and Risk Factors of Non-Communicable Diseases in Bangladesh: A Comparative Multilevel Analysis of Nationally Representative BDHS Data (2017-2022)."* ([medRxiv](https://www.medrxiv.org/content/10.64898/2026.03.31.26349897v1)) — This essentially performs the cross-wave multilevel comparison. If the user proceeds with BDHS 2022 work, this paper *must* be cited and the contribution sharpened (e.g., your contribution = composite index, not single-risk-factor change).
- **OVERLAP** — Resma et al. (J Diabetes Research, 2026), *"Machine-Learning-Based Prediction of Hypertension and Its Risk Factors Among Adults in the Northern Region of Bangladesh,"* community survey N=1026. ([journal](https://onlinelibrary.wiley.com/doi/10.1155/jdr/1799434)) — Differentiate: theirs is subnational; yours is national.
- **OVERLAP** — Hossain et al. (medRxiv 2025), *"Application of Machine Learning Approaches to Develop Predictive Models for Diabetes and Hypertension among Bangladesh Adults"* using **BDHS 2022**. ([medRxiv](https://www.medrxiv.org/content/10.1101/2025.05.30.25328660v1.full)) — Newest. They use 2022, you use 2017-18. Cite to defend the data choice or motivate a 2022 sensitivity run.
- **OVERLAP** — *"Risk factors for non-communicable diseases among Bangladeshi adults: an application of generalised linear mixed model on multilevel demographic and health survey data."* ([PMC11927428](https://pmc.ncbi.nlm.nih.gov/articles/PMC11927428/)) — Same exact multilevel-GLMM methodology applied to NCDs on BDHS. Must cite.
- **OVERLAP** — Hasan et al. (BDHS 2022 women's HTN, ScienceDirect, 2025), *"Prevalence and modifiable determinants of hypertension among women in Bangladesh: A modified Poisson regression."* ([ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0033350625004068)) — Recent, BDHS 2022, robust-variance Poisson rather than logit.
- **EXTENDS** — Frontiers Public Health (2026), *"Pre-hypertension in Bangladesh: evidence from BDHS 2022."* ([Frontiers](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2026.1777932/full)) — Looks at pre-HTN as outcome; NCDVI could be tested against pre-HTN as a secondary outcome.

**Verdict on positioning:** The manuscript is no longer first-mover. To stay journal-competitive, it needs a clean differentiator: the composite-index approach (MCA-derived NCDVI) for policy-actionable tiering is the unique angle. Lean into it; don't try to compete on prediction accuracy with the ML papers.

---

## 3. Methodology: what reviewers will likely demand

- **METHOD** — `glmer` with `weights=sampling_wgt` is **not** a true survey-weighted multilevel logit. Pseudo-likelihood is the standard. ([WeMix CRAN](https://cran.r-project.org/web/packages/WeMix/index.html), [svylme](https://cran.r-project.org/web/packages/svylme/svylme.pdf), [Lumley 2024 Stat](https://onlinelibrary.wiley.com/doi/full/10.1002/sta4.657)) — The commented `WeMix::mix` block in `R/multilevel_model.R` shows awareness. Switch to it; quote both single-level (svyglm) and multilevel pseudo-ML in a sensitivity table. This is reviewer-defense, not optional.
- **METHOD** — MCA on Burt matrix overestimates total inertia; use *adjusted inertias* (Benzécri or Greenacre correction) or report joint correspondence analysis as a sensitivity. ([Frontiers Public Health 2024](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2024.1362699/full)) — Current `FactoMineR::MCA` with `ncp = 1` is a strong assumption; report scree/cumulative inertia and justify dimensionality.
- **METHOD** — ICC reported (in the model code) but not in the manuscript text. Show variance partition coefficient (VPC) and the 95% CI for the random-intercept variance.
- **METHOD** — No calibration plot or discrimination metric (C-statistic). For an "index for early detection," reviewers expect both. Add Hosmer-Lemeshow and AUC with bootstrap CI.
- **METHOD** — No internal validation. With ML competitors at AUC 0.93–0.95, your logit-based NCDVI needs at least k-fold cross-validation of the OR estimates and a bootstrap of the tier cut-points.

---

## 4. BDHS 2022 — variable-by-variable audit

Cannot inspect the recode manual directly (no PDF tools available; the report PDF `Data_reports/FR386.pdf` is on disk but I can't render it), so this is built from journal articles using the 2022 data.

| Variable family | 2017-18 names | 2022 status | Source |
|---|---|---|---|
| BP measurements (3 readings) | `sb333aa`, `sb333ab` | **Confirmed present** — "BP measured three times ≥5 minutes apart with automated device, mean of 2nd and 3rd used" | [Frontiers 2026](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2026.1777932/full), [FR386 indirect](https://www.dhsprogram.com/pubs/pdf/FR386/FR386.pdf) |
| Fasting glucose | `sb335b` | **Confirmed present** — measured in biomarker subsample (~5,392 households, ~13,835 adults with biomarker data) | [diabetes BDHS 2017-22 study](https://pmc.ncbi.nlm.nih.gov/articles/PMC10021925/) |
| BMI / height / weight | `sbbm` | **Confirmed present** in biomarker module | [GHDx record](https://ghdx.healthdata.org/record/bangladesh-demographic-and-health-survey-2022) |
| BP medication | `sb318a` | **Confirmed present** (hypertension defined per JNC-8/AHA-2017 in 2022 papers) | [medRxiv 2025 women HTN](https://www.medrxiv.org/content/10.1101/2025.09.16.25335939v1) |
| Doctor-advised: salt / weight / smoking / exercise | `sb318b–e` | **UNCONFIRMED** — none of the 2022 papers I reviewed used these specific variables; these were country-specific additions to the standard DHS-7 questionnaire and may have been dropped or renamed in DHS-8/2022 | Recode manual not inspected |
| Occupation | `sb308` | **Likely present** but coding may differ between rounds | Inspection needed |
| Standard DHS vars (`hv001, hv005, hv021, hv023, hv024, hv025, hv104, hv105, hv106, hv115, hv270`) | unchanged | **Confirmed unchanged** — these are standardized across all DHS rounds | [DHS Recode Manual](https://dhsprogram.com/publications/publication-dhsg4-dhs-questionnaires-and-manuals.cfm) |

**Verdict:** (c) BDHS 2022 *probably* supports the analysis at the core (BP, glucose, BMI, demographics all present and on a *larger* biomarker subsample than 2017-18), but the **advice variables `sb318b-e` are the open question**. Until those are confirmed, the manuscript's "2017-18 chosen for more detailed NCD info" claim is plausible but unverified.

**Recommended path:**
1. Either download the BDHS 2022 PR recode (free with DHS Program approval) and check the variable list, or
2. Frame the paper as 2017-18 *primary analysis* + 2022 *external validation on the subset of variables present* (BMI + occupation + outcome). This actually strengthens the manuscript more than a wholesale switch.

---

## 5. Top 5 concrete improvements (ranked by leverage for journal acceptance)

| # | Change | Effort | Leverage | Touch points |
|---|---|---|---|---|
| 1 | **Endogeneity sensitivity** — rebuild NCDVI without advice variables; report dose-response and discrimination | Low | **Critical** | `R/mca_index.R`, manuscript Discussion |
| 2 | **Proper survey-weighted multilevel** via `WeMix::mix` or `svylme`; report both estimates in a sensitivity table | Medium | **High** | `R/multilevel_model.R`, manuscript Methods + Results |
| 3 | **BDHS 2022 external validation** on the subset of variables confirmed to exist (BMI, BP, glucose, occupation, demographics). Even partial validation rebuts the "stale 2017-18 data" reviewer comment | Medium-High | High | New `R/validate_2022.R`, new manuscript subsection |
| 4 | **Internal validation + calibration** — 5-fold CV of tier definitions; bootstrap CI on OR estimates; ROC/AUC vs ML competitors; Hosmer-Lemeshow | Medium | High | New `R/validation.R`, manuscript Results |
| 5 | **MCA robustness** — adjusted inertias (Greenacre correction); test `ncp=2`; compare to PCAmix or FAMD; report cumulative inertia | Low-Medium | Medium | `R/mca_index.R`, manuscript Methods |
| 6 | **Expand NCDVI inputs with structural variables** — add `hv226` (cooking fuel), `hv201` (water source), `hv205` (toilet), `hv241/hv242` (kitchen), and a crowding measure to the MCA. Shifts the index from 2/6 → 7/11 non-endogenous inputs and directly blunts the §1 endogeneity critique. See §8 for the variable-availability audit. | Low | **High** | `R/analysis_main.R` (new recodes), `R/mca_index.R` (input list), manuscript Methods + Variables table |

Optional bonus: **Outcome alternatives** — refit using JNC-8 (≥130/80) AND current (140/90) cutoffs as sensitivity; refit on pre-HTN as a secondary outcome (engages [Frontiers 2026](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2026.1777932/full)).

---

## 6. Code issues to fix in passing (not research-novel, but needed before submission)

- `R/maps.R:18` — `geom_sf(aes(fill = div_hyper_prop$prop))` uses external vector by row order. Join `div_hyper_prop` onto `div_map` by division name explicitly; otherwise figure caption is unverifiable.
- `R/ncd_prev.R` — five hardcoded NCD-prevalence points (2000–2023) without source citation. Either drop the figure or sub in WHO Global Burden of Disease numbers with citation.
- Centralize variable recodes in one place (`R/recode.R`) and have all downstream scripts import a clean tibble. This is research-relevant because reviewer requests for sensitivity analyses will need rapid re-runs.
- Add `renv.lock` so the reviewer can reproduce.

---

## 7. Suggested manuscript-level reframing (one paragraph for the Discussion)

The NCDVI is best positioned not as a "vulnerability prediction tool for the general population" (where it overlaps with ML competitors and has the endogeneity issue) but as a **policy-targeting instrument for the already-screened population**: among adults who have been seen by a clinician and received behavioral advice, the NCDVI tiers identify who is most likely to be hypertensive *now* and therefore warrants intensified follow-up — particularly Tier 5, where prevalence approaches 72%. This is a defensible, narrower contribution that survives the endogeneity critique and is complementary to (not competing with) the BDHS ML prediction papers.

---

## 8. Variable expansion audit — what BDHS 2017-18 actually contains (2026-05-15 follow-up)

A direct inspection of `Datasets/Data_with_level_wgt_PR7/PR7_with_level_wgt.dta` (PR7, 432 vars) and `Datasets/BDIR81DT/BDIR81FL.DTA` (women's IR, 5,425 vars) was performed to find non-endogenous candidates that could replace or supplement the four `sb318b–e` advice variables. The finding is a binding constraint, not a wishlist.

### 8a. Behavioral risk variables — NOT collected in BDHS 2017-18

The DHS-standard behavioral risk modules were either dropped from BDHS 2017-18 or never administered:

| Wishlist variable | Standard DHS code | BDHS 2017-18 status |
|---|---|---|
| Current cigarette smoking | `v463a` | Flagged `na` in BDIR81FL — question dropped |
| Smokeless tobacco (paan/zarda/gul) | `v463c`, `v463h`, `v463i` | All `na` — dropped |
| Alcohol consumption | `v485a`, `v485b` | `na` — dropped (also rare in Bangladesh) |
| Secondhand smoke exposure | `hv252` | `na` — not collected |
| Fruit & vegetable intake (frequency) | n/a (country-specific) | Not collected |
| Physical activity (GPAQ / IPAQ) | n/a | Not collected |
| Sleep duration | n/a | Not collected |
| Family history of HTN / DM / stroke | n/a | Not collected |
| Waist circumference / WHR | n/a | Not collected (only `sbbm` BMI) |
| Mental health / perceived stress | n/a | Not collected for adult NCD (only postpartum items for recent-birth women) |
| Self-reported chronic conditions other than DM | n/a | Not collected as standalone items |
| Men's tobacco / behavioral data | n/a | **No men's recode (BDMR) exists** — BDHS 2017-18 did not run a men's individual interview |

Implication: the manuscript's vulnerability index *cannot* be augmented with the canonical INTERHEART / WHO HEARTS / Globorisk behavioral inputs using BDHS 2017-18. This is a hard data limitation, not an analyst choice, and should be stated explicitly in the Methods.

### 8b. Non-endogenous candidates that DO exist (recommended additions)

Structural/environmental variables in the PR7 recode that are upstream of clinical contact:

| # | Variable | BDHS code | Rationale | Expected effect |
|---|---|---|---|---|
| 1 | **Cooking fuel (clean vs solid biomass)** | `hv226` | Indoor air pollution is a Tier-1 NCD risk factor in South Asia. Published BDHS 2017-18 evidence: Khan et al. 2022 (Springer, doi:10.1007/s11356-021-15344-w) shows AOR ~1.2–1.6 for HTN among women cooking with solid fuel. Captures rural/poor exposure not absorbed by `wealth_index` or `area_res`. | Strong, well-documented |
| 2 | **Drinking water source** | `hv201` | Tubewell vs municipal/treated — proxies arsenic exposure in many Bangladesh districts, a known cardiometabolic risk. | Moderate, region-conditional |
| 3 | **Kitchen separation / location** | `hv241`, `hv242` | Modifies the indoor-air-pollution exposure from `hv226`. Cheap to pair. | Moderate |
| 4 | **Toilet facility type** | `hv205` | Sanitation correlates with chronic infection burden → low-grade inflammation → HTN. Indirect but documented. | Weak-moderate |
| 5 | **Household crowding** | derived from `hv009` (members) and `hv216` (sleeping rooms) | Chronic-stress proxy and an independent SES axis beyond `hv270`. | Weak-moderate |

Adopting #1–#5 shifts the index from 2/6 non-endogenous (occupation + BMI) to 7/11 non-endogenous inputs. This materially blunts the §1 endogeneity critique without changing the survey or losing the existing tier structure.

### 8c. Coverage table vs established NCD risk frameworks

Y = standard input; P = proxy; – = not used.

| Framework | Age | Sex | Smoking | BP | Glucose | BMI/Waist | Lipids | Phys-Act | Diet | Fam-Hx | Environ | SES |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| WHO HEARTS (lab) | Y | Y | Y | Y | Y | – | Y | – | – | – | – | – |
| Globorisk non-lab | Y | Y | Y | Y | – | BMI | – | – | – | – | – | – |
| Framingham / ASCVD | Y | Y | Y | Y | Y | – | Y | – | – | – | – | – |
| INTERHEART Modifiable | Y | Y | Y+SHS | P | P | WHR | – | Y | Y | Y | – | – |
| Current NCDVI | – | – | P (advice) | P (advice) | – | BMI | – | P (advice) | P (advice) | – | – | – |
| **Proposed NCDVI** | – | – | P (advice) | P (advice) | – | BMI | – | P (advice) | P (advice) | – | **Y** | **Y** |

(Age, sex, glucose, division, wealth, education enter the multilevel model as separate adjustments — they are *not* in the index itself, by design.)

### 8d. Strategic implication

The proposed expansion does NOT make the NCDVI competitive with WHO HEARTS or INTERHEART on their own terms (those frameworks rely on behavioral data BDHS 2017-18 doesn't have). Instead, it carves out a different niche: a **clinical-advice + structural-household vulnerability index** that is *complementary to* (not duplicative of) the established clinical scores. Reviewers will accept this if it is stated honestly. The manuscript should:

1. Add a Methods sub-paragraph naming the BDHS 2017-18 omissions (tobacco, diet, PA, family history) as a data limitation.
2. Justify the structural additions (`hv226` etc.) as the available proxy for the SES-environmental risk axis.
3. Cite the South-Asian cooking-fuel HTN literature when introducing `hv226` as an input.

### 8e. Sources retrieved this session

- [BDHS 2017-18 Final Report FR344](https://dhsprogram.com/pubs/pdf/FR344/FR344.pdf) (link only — Cloudflare 403 on direct fetch)
- [Khan et al. 2022 — Cooking fuels and HTN among Bangladeshi women, BDHS 2017-18 (Springer)](https://link.springer.com/article/10.1007/s11356-021-15344-w)
- [ResearchGate mirror of cooking-fuel HTN study](https://www.researchgate.net/publication/378026656)
- [INTERHEART Modifiable Risk Score, Eur Heart J 2011](https://academic.oup.com/eurheartj/article/32/5/581/426790)
- [WHO CVD risk charts, Lancet Global Health 2019](https://www.thelancet.com/journals/langlo/article/PIIS2214-109X(19)30318-3/fulltext)
- [Globorisk Bangladesh validation, PMC8358158](https://pmc.ncbi.nlm.nih.gov/articles/PMC8358158/)
- [WHO PEN package](https://iris.who.int/bitstream/handle/10665/334186/9789240009226-eng.pdf)
- Direct inspection of PR7 (`PR7_with_level_wgt.dta`, 432 vars) and women's IR (`BDIR81FL.DTA`, 5,425 vars) via `haven::read_dta` — primary empirical evidence.

---

## Sources (live retrievals, 2026-05-15)

- [PLOS One 2025 — Married women HTN ML on BDHS 2017-18](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0335442)
- [PLOS Comp Bio 2025 — Double ML on BDHS 2011-2022](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1013211)
- [medRxiv 2026 — Shifting NCD prev BDHS 2017-2022 multilevel](https://www.medrxiv.org/content/10.64898/2026.03.31.26349897v1)
- [J Diabetes Research 2026 — ML HTN N Bangladesh](https://onlinelibrary.wiley.com/doi/10.1155/jdr/1799434)
- [medRxiv 2025 — ML HTN + DM on BDHS 2022](https://www.medrxiv.org/content/10.1101/2025.05.30.25328660v1.full)
- [PMC11927428 — GLMM on multilevel DHS for NCDs](https://pmc.ncbi.nlm.nih.gov/articles/PMC11927428/)
- [ScienceDirect 2025 — Modified Poisson HTN women BDHS 2022](https://www.sciencedirect.com/science/article/abs/pii/S0033350625004068)
- [Frontiers 2026 — Pre-HTN BDHS 2022](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2026.1777932/full)
- [Frontiers 2024 — Role of correspondence analysis in medical research](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2024.1362699/full)
- [WeMix R package — pseudo-ML multilevel](https://cran.r-project.org/web/packages/WeMix/index.html)
- [svylme R package — mixed models complex survey](https://cran.r-project.org/web/packages/svylme/svylme.pdf)
- [Lumley 2024 Stat — pairwise likelihood survey LMM](https://onlinelibrary.wiley.com/doi/full/10.1002/sta4.657)
- [BDHS 2022 Final Report FR386](https://www.dhsprogram.com/pubs/pdf/FR386/FR386.pdf)
- [DHS Recode Manual DHSG4](https://dhsprogram.com/publications/publication-dhsg4-dhs-questionnaires-and-manuals.cfm)
- [diabetes BDHS biomarker measurement](https://pmc.ncbi.nlm.nih.gov/articles/PMC10021925/)

---

## 9. Target journals & engineering standards for the revamp (2026-05-15)

### 9a. Ranked submission targets

| # | Journal | IF | APC | Fit | Why |
|---|---|---|---|---|---|
| 1 | **BMC Public Health** (Springer/BMC) | 3.6 | ~$3,190 | 5/5 | Highest-volume home for BDHS multilevel observational papers; methodologically permissive; long-form allowed |
| 2 | **PLOS Global Public Health** | 2.5 | ~$2,496 (waivers via Global Equity) | 5/5 | LMIC-first OA; competitor BDHS HTN-disparities papers already there; matches "policy targeting in underserved populations" framing |
| 3 | **BMJ Open** | 2.3 | £2,390 | 4/5 | Strict transparent-reporting culture; mandatory Strengths/Limitations box + PPI statement; engineering to this venue's strictness makes the other two easy down-targets |
| 4 | Frontiers in Public Health | 3.4 | ~$3,500 | 4/5 | A 2026 competitor (Pre-HTN BDHS 2022) landed here; fast turnaround |
| 5 | J. Epidemiology and Global Health (Springer) | 3.1 | ~$2,790 | 4/5 | Topical LMIC epi venue; less crowded than BMC/PLOS by competitors |
| 6 | SSM – Population Health (Elsevier) | 3.1 | ~$2,630 | 3/5 | Strong methodological venue if positioning leans social-epi inequality angle |

**Not advanced:** PLOS One (competitor saturation), Lancet Reg. Health SE Asia (too selective for incremental finding), BMC Cardiovascular Disorders / J. Hypertension (too clinical), PLOS Medicine (too selective), BMC Med Res Methodology (would require repositioning as a methods paper).

**Submission sequencing:** BMC Public Health → PLOS GPH → BMJ Open.

### 9b. Engineering standards (strictest across top-3, so submission to any of the three is no-rewrite)

**Reporting:**
- Complete **STROBE cross-sectional checklist** end-to-end (mandatory for BMJ Open & PLOS GPH; strongly recommended for BMC). Upload as supplementary.
- If validation/AUC/calibration added, also complete **TRIPOD checklist** — frame NCDVI as a *prognostic index*.

**Statistical methods:**
- 95% CIs on every effect; exact p-values to 3 decimals; use `p < 0.001` only when truly smaller.
- Document software + version + package citations.
- MCA dimensionality justified with sensitivity for `ncp=2` and PCAmix/FAMD alternative.
- Tier cut-point sensitivity (quintile vs quartile vs k-means).

**Survey-design handling:**
- Replace `glmer(weights=)` with **pseudo-likelihood survey-weighted multilevel logit** — primary `WeMix::mix` (or `svylme`); supplementary `svyglm` cross-check.
- Declare `svydesign(ids=~hv021, strata=~hv023, weights=~hv005/1e6, nest=TRUE)`.
- Report design effects and effective sample size.

**Validation evidence:**
- 10-fold CV; 1,000-iter bootstrap CIs on Tier-5 vs Tier-1 OR; calibration plot; AUC with 95% CI via `pROC`.
- External validation on BDHS 2022 carry-over subset.
- Endogeneity sensitivity: rebuild NCDVI without `sb318b–e`; report dose-response.

**Reproducibility:**
- GitHub repo + Zenodo tagged release with DOI; cite DOI in Code Availability Statement.
- `renv.lock` for environment reproducibility.
- Canonical Data Availability wording: "The BDHS 2017-18 dataset is publicly available from the DHS Program (https://dhsprogram.com/data) on registration and approval of a data request. Derived variables and analysis code are available at <Zenodo DOI>."
- Canonical Ethics wording: "BDHS 2017-18 received ethical approval from the Bangladesh Medical Research Council and the ICF Institutional Review Board; the present study is a secondary analysis of de-identified public-use data and required no additional ethics approval."

**Manuscript structure (binding from BMJ Open):**
- Body text **≤ 4,000 words**.
- **Structured abstract ≤ 300 words** with BMJ Open headings: Objectives / Design / Setting / Participants / Outcome measures / Results / Conclusions.
- **Strengths & Limitations box** — 3–5 bullets after the abstract.
- **PPI statement** — even if "no patient or public involvement."
- 6–8 figures/tables, Vancouver references, ORCIDs for all authors.
- Preprint to medRxiv before submission (all three accept this).

### 9c. Sources (Track-3 retrievals)

- [PLOS GPH submission guidelines](https://journals.plos.org/globalpublichealth/s/submission-guidelines)
- [BMJ Open formatting (secondary, 2026-03)](https://manusights.com/blog/bmj-open-formatting-requirements)
- [BMC Public Health landing](https://link.springer.com/journal/12889)
- [J. Epidemiology and Global Health author guidelines](https://link.springer.com/journal/44197/submission-guidelines)
- [SSM-Population Health author guide](https://www.sciencedirect.com/journal/ssm-population-health/publish/guide-for-authors)
- [PLOS GPH BDHS HTN-disparities competitor](https://journals.plos.org/globalpublichealth/article?id=10.1371%2Fjournal.pgph.0003496)
