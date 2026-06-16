# Method note: Decision Curve Analysis under complex survey weights

Source: Perplexity (scholar+web), retrieved 2026-06-08, for the BS_project NCDVI manuscript.

## Net benefit definition
At threshold probability t, with risk score p_i and decision rule yhat_i(t) = 1[p_i >= t]:

NB(t) = TP/n - (FP/n) * (t/(1-t))

This is "net true positives per person"; the t/(1-t) term is the false-positive penalty (the odds at the threshold).

## Survey weights
Target estimand is population-level expected net benefit. Replace unweighted counts with survey-weighted counts using weight w_i:
- TP_w(t) = sum_i w_i * 1[Y_i=1 & p_i>=t]
- FP_w(t) = sum_i w_i * 1[Y_i=0 & p_i>=t]
- n_w = sum_i w_i
- NB_w(t) = TP_w(t)/n_w - (FP_w(t)/n_w) * (t/(1-t))

Normalization: either n_w = sum w_i (per representative population member) or normalize weights to sum to sample n (per sampled person). Be explicit which. For BDHS, sampling_wgt = hv005/1e6 averages ~1 so sum ~= N; "sum to n" keeps the curve on a per-sampled-person scale.

Clustering (PSU) affects coefficient estimation / standard errors, not the net-benefit algebra. For DCA confidence intervals use design-respecting resampling (cluster bootstrap / replicate weights); naive intervals are too narrow under clustering.

## Reference strategies (always plot)
- Treat-none: NB = 0 for all t.
- Treat-all: weighted event prevalence minus weighted non-event * t/(1-t):
  NB_all,w(t) = (events_w/n_w) - (nonevents_w/n_w)*(t/(1-t)).

A model has clinical utility where its NB curve sits above both treat-all and treat-none across a clinically relevant threshold range.

## Optimism
Use out-of-fold (cross-validated) predicted probabilities as DCA inputs to avoid optimistic net benefit, analogous to CV for discrimination/calibration. Fit within fold (weighted), predict held-out fold, pool OOF predictions, compute NB_w with survey weights. The project already stores pooled OOF predictions (phase4 oof_primary/oof_sensitivity/oof_conf; phase8d oof_5/oof_4/oof_conf).

## Scalar summary (optional)
Weighted area under the net benefit curve (AUNBC) has higher power for model comparison than the standard approach (PMC4949771).

## Sources
- Vickers & Elkin 2006 (net benefit definition / DCA).
- Van Calster et al.; Steyerberg (calibration + clinical utility reporting).
- Understanding DCA in clinical prediction modeling, Postgrad Med J 2024;100(1185):512.
- Weighted area under the net benefit curve, PMC4949771.
- Analysis of complex survey samples, J Stat Software v009i08 (survey design weighting).
