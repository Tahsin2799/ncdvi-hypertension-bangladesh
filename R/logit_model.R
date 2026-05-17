source("R/complex_survey.R")

mod_logit_svy <- svyglm(formula = hyper ~ ncdvi + diabetic + age_cat +
                      sex + educ + marital_status + wealth_index +
                      division + area_res,
                    family = quasibinomial(link = "logit"),
                    design = dat_dhs)

