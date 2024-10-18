source("R/complex_survey.R")
library(lme4)
#library(WeMix)

multimod_1 <- glmer(hyper ~ ncdvi + diabetic + age_cat +
                      sex + educ + marital_status + wealth_index +
                      division + area_res + (1|hv021),
                    data = dat_18,
                    weights = sampling_wgt,
                    family = binomial(link = "logit")
                    )


# multimod_2 <- mix(hyper ~ ncdvi + diabetic + age_cat +
#                       sex + educ + marital_status + wealth_index +
#                       division + area_res + (1|hv021),
#                     data = dat_18,
#                     weights = c("wt1", "wt2"),
#                     family = binomial(link = "logit")
# )

library(mlmhelpr)
icc(multimod_1)

## Reg Table

# function for putting CI in brackets
# put_vector_in_parentheses <- function(values){
#   put_value_in_parentheses <- function(value){
#     if(is.na(value)){
#       return(value)
#     }
#     else{
#       return(paste0("(", value, ")"))
#     }
#   }
#   new_values <- sapply(values, put_value_in_parentheses)
#   return(new_values)
# }

## tab for model
library(broom.helpers)

multimod_tab <- tbl_regression(multimod_1, exponentiate = TRUE) %>% 
  bold_labels() %>% 
  bold_p() %>% 
  # NOTE: the following line puts the CI in parentheses using the function above
  # modify_table_body(~ .x %>%
  #                     mutate(ci = put_vector_in_parentheses(ci))) %>%
  # turning off footnotes:
  modify_footnote(... = list(everything() ~ NA), abbreviation = TRUE)

