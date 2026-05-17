library(tidyverse)
library(foreign)
library(haven)
library(FactoMineR)
library(DT)
library(factoextra)
library(Hmisc)
library(gt)
library(gtsummary)
library(survey)
pacman::p_load(sf, terra, dplyr, tidyr, ggplot2, broom, plm, openxlsx)

# data
dat_18 <- read_dta("Datasets/Data_with_level_wgt_PR7/PR7_with_level_wgt.dta")


# response
dat_18 <- dat_18 %>% 
  filter(is.na(sb333aa) == FALSE | is.na(sb333ab) == FALSE) %>% 
  mutate(sbp = sb333aa,
         dbp = sb333ab,
         pres_med = case_when(sb318a == 1 ~ 1,
                              sb318a == 0 | is.na(sb318a) == TRUE ~ 0)) %>%
  mutate(hyper = if_else(sbp >= 140 | dbp >= 90 | pres_med == 1, 1, 0)) %>% 
  mutate(hyper = factor(hyper,
                        levels = c(0, 1),
                        labels = c("No", "Yes"))) 

labelled::var_label(dat_18$hyper) <- "Hypertensive"


# index inputs

## occupation
dat_18 <- dat_18 %>% 
  filter(is.na(sb308) == FALSE & sb308 != 96 & sb308 != 98) %>%
  mutate(occupation = case_when(sb308 %in% c(12,13,14,15,16,21,22,23,31) ~ 0,
                                sb308 %in% c(11,41,51,52) ~ 1,
                                sb308 %in% c(0,61,62) ~ 2)) %>% 
  mutate(occupation = factor(occupation,
                             levels = c(0, 1, 2),
                             labels = c("Labor Taxing Job",
                                        "Not a Labor Taxing Job",
                                        "Not Working"))) 

labelled::var_label(dat_18$occupation) <- "Occupation Type"

## bmi_cat
dat_18 <- dat_18 %>% 
  filter(is.na(sbbm) == FALSE) %>% 
  mutate(BMI = sbbm/100) %>% 
  mutate(BMI_cat = case_when(BMI <= 18.5 ~ 0,
                             18.5 < BMI & BMI <= 24.9 ~ 1,
                             24.9 < BMI & BMI <= 29.9 ~ 2,
                             29.9 < BMI & BMI <= 34.9 ~ 3,
                             34.9 < BMI & BMI <= 39.9 ~ 4,
                             BMI > 39.9 ~ 5)) %>% 
  mutate(BMI_cat = factor(BMI_cat,
                          levels = c(0, 1, 2, 3, 4, 5),
                          labels = c("Underweight",
                                     "Normal weight",
                                     "Pre-obesity",
                                     "Obesity class I",
                                     "Obesity class II",
                                     "Obesity class III"))) 

labelled::var_label(dat_18$BMI_cat) <- "BMI Categories"

## salt_intake, stop_smk, lose_wgt, exer_more
dat_18 <- dat_18 %>% 
  mutate(salt_intake = if_else(sb318b == 0 | is.na(sb318b) == T, 0, 1),
         lose_wgt = if_else(sb318c == 0 | is.na(sb318c) == T, 0, 1),
         stop_smok = if_else(sb318d == 0 | is.na(sb318d) == T, 0, 1),
         exer_more = if_else(sb318e == 0 | is.na(sb318e) == T, 0, 1)) %>% 
  mutate(across(c(salt_intake, lose_wgt, stop_smok, exer_more),
                function(x){
                  factor(x, 
                         levels = c(0, 1),
                         labels = c("Otherwise", "Yes"))
                }))
  
labelled::var_label(dat_18$salt_intake) <- "Advised to Reduce Salt for High BP"
labelled::var_label(dat_18$lose_wgt) <- "Advised to Lose Weight for High BP"
labelled::var_label(dat_18$stop_smok) <- "Advised to Stop Smoking for High BP"
labelled::var_label(dat_18$exer_more) <- "Advised to Exercise More for High BP"

# Confounders

## diabetic
dat_18 <- dat_18 %>% 
  filter(is.na(sb335b) == F) %>% 
  mutate(glucose = sb335b/10,
         med_diab = case_when(sb327a == 1 ~ 1,
                              sb327a == 0 | is.na(sb327a) == TRUE ~ 0)) %>% 
  mutate(diabetic = if_else(glucose >= 7 | med_diab == 1, 1, 0)) %>% 
  mutate(diabetic = factor(diabetic,
                           levels = c(0, 1),
                           labels = c("No", "Yes"))) 

labelled::var_label(dat_18$diabetic) <- "Diabetic"

## age
dat_18 <- dat_18 %>% 
  mutate(age = hv105,
         age_cat = case_when(hv105 <= 25 ~ 0,
                             hv105 > 25 & hv105 <= 35 ~ 1,
                             hv105 > 35 & hv105 <= 50 ~ 2,
                             hv105 > 50 & hv105 <= 65 ~ 3,
                             hv105 > 65 & hv105 <= 75 ~ 4,
                             hv105 > 75 ~ 5)) %>% 
  mutate(age_cat = factor(age_cat,
                          levels = c(0, 1, 2, 3, 4, 5),
                          labels = c("18-25", "25-35", "35-50", "50-65", "65-75", "75+")))

labelled::var_label(dat_18$age) <- "Age of Household Members"
labelled::var_label(dat_18$age_cat) <- "Age Categories"

## sex, educ, marital, wi, div, area
dat_18 <- dat_18 %>% 
  filter(hv106 != 8) %>% 
  mutate(sex = factor(case_when(hv104 == 2 ~ 0,
                                hv104 == 1 ~ 1),
                      labels = c("Female" , "Male"),
                      levels = c(0, 1)),
         educ = factor(hv106, 
                       labels = c("No Education, Preschool",
                                  "Primary",
                                  "Secondary",
                                  "Higher"),
                       levels = c(0, 1, 2, 3)),
         marital_status = factor(case_when(hv115 == 1 ~ 0,
                                           hv115 %in% c(0, 3, 4) ~ 1),
                                 levels = c(0, 1),
                                 labels = c("Married", "Single")),
         wealth_index = factor(case_when(hv270 == 1 ~ 0,
                                         hv270 == 2 ~ 1,
                                         hv270 == 3 ~ 2,
                                         hv270 == 4 ~ 3,
                                         hv270 == 5 ~ 4),
                               levels = c(0, 1, 2, 3, 4),
                               labels = c("Poorest",
                                          "Poorer",
                                          "Middle",
                                          "Richer",
                                          "Richest")),
         division = factor(case_when(hv024 == 1 ~ 0,
                                     hv024 == 2 ~ 1,
                                     hv024 == 3 ~ 2,
                                     hv024 == 4 ~ 3,
                                     hv024 == 5 ~ 4,
                                     hv024 == 6 ~ 5,
                                     hv024 == 7 ~ 6,
                                     hv024 == 8 ~ 7),
                           levels = c(0, 1, 2, 3, 4, 5, 6, 7),
                           labels = c("Barisal",
                                      "Chittagong",
                                      "Dhaka",
                                      "Khulna",
                                      "Mymensingh",
                                      "Rajshahi",
                                      "Rangpur",
                                      "Sylhet")),
         area_res = factor(case_when(hv025 == 2 ~ 0, hv025 == 1 ~ 1),
                           levels = c(0, 1),
                           labels = c("Rural", "Urban")))

labelled::var_label(dat_18$sex) <- "Sex of Household Member"
labelled::var_label(dat_18$educ) <- "Education Level"
labelled::var_label(dat_18$marital_status) <- "Marital Status"
labelled::var_label(dat_18$wealth_index) <- "Wealth Index"
labelled::var_label(dat_18$area_res) <- "Area of Residence"
labelled::var_label(dat_18$division) <- "Division"

# structural / household-environmental inputs
# NA on a household-roster item treated as least-vulnerable category
# (same convention as sb318b-e above).

## cook_fuel: clean (electricity/LPG/natural gas/biogas) vs solid/polluting
dat_18 <- dat_18 %>%
  mutate(cook_fuel = case_when(hv226 %in% c(1, 2, 3, 4) ~ 0,
                               hv226 %in% c(5, 6, 7, 8, 9, 10, 11) ~ 1,
                               TRUE ~ 0)) %>%
  mutate(cook_fuel = factor(cook_fuel,
                            levels = c(0, 1),
                            labels = c("Clean Fuel", "Solid/Polluting Fuel")))

labelled::var_label(dat_18$cook_fuel) <- "Cooking Fuel Type"

## water_source: piped/treated vs tubewell vs unimproved
dat_18 <- dat_18 %>%
  mutate(water_source = case_when(hv201 %in% c(11, 12, 13, 14, 51) ~ 0,
                                  hv201 %in% c(21, 31, 41, 43) ~ 1,
                                  hv201 %in% c(32, 42, 61, 62, 71, 96) ~ 2,
                                  TRUE ~ 0)) %>%
  mutate(water_source = factor(water_source,
                               levels = c(0, 1, 2),
                               labels = c("Piped/Treated",
                                          "Tubewell/Protected",
                                          "Unimproved/Surface")))

labelled::var_label(dat_18$water_source) <- "Drinking Water Source"

## toilet_type: JMP-improved vs unimproved
dat_18 <- dat_18 %>%
  mutate(toilet_type = case_when(hv205 %in% c(11, 12, 13, 21, 22, 31, 41) ~ 0,
                                 hv205 %in% c(14, 15, 23, 42, 43, 51, 96) ~ 1,
                                 TRUE ~ 0)) %>%
  mutate(toilet_type = factor(toilet_type,
                              levels = c(0, 1),
                              labels = c("Improved", "Unimproved")))

labelled::var_label(dat_18$toilet_type) <- "Toilet Facility Type"

## cook_location (hv241 + hv242): indoor-air-pollution exposure proxy
dat_18 <- dat_18 %>%
  mutate(cook_location = case_when(hv241 == 1 & (hv242 == 0 | is.na(hv242)) ~ 2,
                                   hv241 == 1 & hv242 == 1 ~ 1,
                                   hv241 %in% c(2, 3, 7) ~ 0,
                                   TRUE ~ 0)) %>%
  mutate(cook_location = factor(cook_location,
                                levels = c(0, 1, 2),
                                labels = c("Outdoors/Separate Building",
                                           "In House, Separate Kitchen",
                                           "In House, No Separate Kitchen")))

labelled::var_label(dat_18$cook_location) <- "Cooking Location"

## crowding: members / sleeping rooms > 3 (WHO)
dat_18 <- dat_18 %>%
  mutate(crowding = case_when(hv216 == 0 ~ 1,
                              !is.na(hv009) & !is.na(hv216) & hv216 > 0 & (hv009 / hv216) > 3 ~ 1,
                              TRUE ~ 0)) %>%
  mutate(crowding = factor(crowding,
                           levels = c(0, 1),
                           labels = c("Not Crowded", "Crowded")))

labelled::var_label(dat_18$crowding) <- "Household Crowding (>3 per Sleeping Room)"
