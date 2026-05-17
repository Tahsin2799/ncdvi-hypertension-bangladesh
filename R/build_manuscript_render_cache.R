# Build lightweight tables used by manuscript_BS.Rmd / manuscript_BS_v2.Rmd
# so the render can readRDS() instead of re-sourcing the analysis pipeline.
# Re-run only when the underlying analysis outputs change.

suppressPackageStartupMessages({
  library(dplyr)
  library(gtsummary)
})

format_p <- function(p) {
  ifelse(is.na(p), "",
         ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}

# Bivariate table cache (sources the pipeline; only run when rebuilding).
suppressPackageStartupMessages(source("R/bi_tab.R"))
bi_body <- as_tibble(bi_tab_short$table_body)
bi_p <- bi_body$p.value[bi_body$row_type == "label"][1]
bi_table <- bind_rows(
  tibble::tibble(
    Characteristic = bi_body$var_label[bi_body$row_type == "label"][1],
    Level = "",
    `No` = "",
    `Yes` = "",
    `p-value` = format_p(bi_p)
  ),
  bi_body %>%
    filter(row_type == "level") %>%
    transmute(
      Characteristic = "",
      Level = label,
      `No` = stat_1,
      `Yes` = stat_2,
      `p-value` = ""
    )
)
saveRDS(bi_table, "outputs/manuscript_bi_tab_short.rds")

phase3 <- readRDS("outputs/phase3_multilevel.rds")
coef_mat <- phase3$primary_glmer_11$coef

format_or <- function(est) sprintf("%.2f", exp(est))
format_ci <- function(est, se) {
  sprintf("[%.2f, %.2f]",
          exp(est - 1.96 * se),
          exp(est + 1.96 * se))
}

term_map <- c(
  "ncdviTier 2" = "Tier 2",
  "ncdviTier 3" = "Tier 3",
  "ncdviTier 4" = "Tier 4",
  "ncdviTier 5" = "Tier 5",
  "diabeticYes" = "Yes",
  "age_cat25-35" = "25-35",
  "age_cat35-50" = "35-50",
  "age_cat50-65" = "50-65",
  "age_cat65-75" = "65-75",
  "age_cat75+" = "75+",
  "sexMale" = "Male",
  "educPrimary" = "Primary",
  "educSecondary" = "Secondary",
  "educHigher" = "Higher",
  "marital_statusSingle" = "Single",
  "wealth_indexPoorer" = "Poorer",
  "wealth_indexMiddle" = "Middle",
  "wealth_indexRicher" = "Richer",
  "wealth_indexRichest" = "Richest",
  "divisionChittagong" = "Chittagong",
  "divisionDhaka" = "Dhaka",
  "divisionKhulna" = "Khulna",
  "divisionMymensingh" = "Mymensingh",
  "divisionRajshahi" = "Rajshahi",
  "divisionRangpur" = "Rangpur",
  "divisionSylhet" = "Sylhet",
  "area_resUrban" = "Urban"
)

term_group <- c(
  "ncdvi" = "NCD Vulnerability Index",
  "diabetic" = "Diabetic",
  "age_cat" = "Age Categories",
  "sex" = "Sex of Household Member",
  "educ" = "Education Level",
  "marital_status" = "Marital Status",
  "wealth_index" = "Wealth Index",
  "division" = "Division",
  "area_res" = "Area of Residence"
)

reference_rows <- tibble::tribble(
  ~group, ~label,
  "ncdvi", "Tier 1",
  "diabetic", "No",
  "age_cat", "18-25",
  "sex", "Female",
  "educ", "No Education, Preschool",
  "marital_status", "Married",
  "wealth_index", "Poorest",
  "division", "Barisal",
  "area_res", "Rural"
)

coef_df <- as.data.frame(coef_mat) %>%
  tibble::rownames_to_column("term") %>%
  filter(term != "(Intercept)") %>%
  mutate(
    group = sub("^(ncdvi|diabetic|age_cat|sex|educ|marital_status|wealth_index|division|area_res).*",
                "\\1", term),
    label = unname(term_map[term]),
    OR = format_or(Estimate),
    `95% CI` = format_ci(Estimate, `Std. Error`),
    `p-value` = format_p(`Pr(>|z|)`)
  ) %>%
  select(group, label, OR, `95% CI`, `p-value`)

table_order <- names(term_group)
multilevel_table <- bind_rows(
  lapply(table_order, function(g) {
    bind_rows(
      tibble::tibble(
        Characteristic = term_group[[g]],
        Level = reference_rows$label[reference_rows$group == g],
        OR = "Reference",
        `95% CI` = "",
        `p-value` = ""
      ),
      coef_df %>%
        filter(group == g) %>%
        transmute(Characteristic = "", Level = label, OR, `95% CI`, `p-value`)
    )
  })
)

saveRDS(multilevel_table, "outputs/manuscript_multilevel_table.rds")
