source("R/multilevel_model.R")
library(lmtest)

mod_logit <- glm(hyper ~ ncdvi + diabetic + age_cat + sex + educ + 
                       marital_status + wealth_index + division + area_res,
                     data = dat_18,
                     weights = sampling_wgt,
                     family = binomial(link = "logit"))

lrtest_table <- lrtest(mod_logit, multimod_1)
