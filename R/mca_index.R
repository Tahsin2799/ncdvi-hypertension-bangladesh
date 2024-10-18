source("R/analysis_main.R")
library(statar)

mca <- MCA(dat_18 %>% 
             select(occupation,
                    BMI_cat,
                    salt_intake,
                    stop_smok,
                    lose_wgt,
                    exer_more),
           ncp = 1 #no. of dimensions
)

dat_18 <- dat_18 %>% 
  mutate(scores = mca$ind$coord) %>% 
  mutate(scores_std = (scores - min(scores))/(max(scores) - min(scores))) %>%  #standerdizing range to (0,1)
  arrange(scores_std) %>% 
  mutate(ncdvi = xtile(scores_std, n = 5)) %>% 
  mutate(ncdvi = factor(case_when(ncdvi == 1 ~ 0,
                                 ncdvi == 2 ~ 1,
                                 ncdvi == 3 ~ 2,
                                 ncdvi == 4 ~ 3,
                                 ncdvi == 5 ~ 4),
                       levels = c(0, 1, 2, 3, 4),
                       labels = c("Tier 1",
                                  "Tier 2",
                                  "Tier 3",
                                  "Tier 4",
                                  "Tier 5"))) 

labelled::var_label(dat_18$ncdvi) <- "NCD Vulnerability Index"

# write_dta(dat_18, "Datasets/Data_with_level_wgt_PR7/PR7_ready.dta")
# install.packages("declared")
# devtools::install_github("dusadrian/DDIwR")
# library(declared)
# library(DDIwR)
# df <- as.declared(dat_18)
# convert(df, to = "Datasets/Data_with_level_wgt_PR7/PR7_ready.dta")
