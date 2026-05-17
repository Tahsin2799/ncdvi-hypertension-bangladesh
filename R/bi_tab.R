source("R/complex_survey.R")
library(kableExtra, cardx)

bi_tab_short <- tbl_svysummary(
  by = hyper,
  data = dat_dhs,
  include = c(ncdvi),
  type = everything() ~ "categorical",
  percent = "row",
  statistic = list(
    all_categorical() ~ "{n} ({p}%)"
  )
) %>%
  bold_labels() %>%
  add_p() %>%
  bold_p() %>%
  modify_footnote(everything() ~ NA) %>%
  modify_spanning_header(all_stat_cols() ~ "**Hypertensive**")
