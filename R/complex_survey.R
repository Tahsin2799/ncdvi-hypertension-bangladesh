source("R/analysis_main.R")
source("R/mca_index.R")

dat_18 <- dat_18 %>%
  mutate(sampling_wgt = hv005 / 1e6)

dat_dhs <- svydesign(id = dat_18$hv021,
                     strata = dat_18$hv023,
                     weights = dat_18$sampling_wgt,
                     data = dat_18)
