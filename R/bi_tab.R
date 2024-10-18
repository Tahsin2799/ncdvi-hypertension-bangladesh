source("R/complex_survey.R")
library(kableExtra, cardx)

# bi_tab <- tbl_svysummary(
#   by = hyper,
#   data = dat_dhs,
#   include = c(ncdvi, diabetic, age_cat, sex, educ, marital_status,
#              wealth_index, division, area_res),
#   type = everything() ~ "categorical",
#   percent = "row",
#   statistic = list(
#     all_categorical() ~ "{n} ({p}%)"
#   )
# ) %>%
#   bold_labels() %>%
#   add_p() %>%
#   separate_p_footnotes() %>%
#   modify_footnote(update = list("stat_1" ~ NA,
#                                 "stat_2" ~ NA))
# 
# as_kable_extra(a2,
#                booktabs = TRUE,
#                longtable = TRUE,
#                caption = "Bivariate Analysis Table",
#                linesep = "") %>%
#   kableExtra::kable_styling(latex_options = c("repeat_header")) %>%
#   kableExtra::add_header_above(c(" ", "Hypertensive" = 2, " "))

# NOTE: if the table is too wide, it can be printed in a landscape page:
# %>% landscape()

# OR, it can be scaled down to fit the page boundaries:
# %>% kableExtra::kable_styling(latex_options = "scale_down")

# OR, the font size of the table can be made smaller (not tested by me yet):
# %>% kableExtra::kable_styling(font_size = 10)

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

