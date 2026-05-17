# BDHS 2022 variable audit: confirms which 2017-18 NCDVI variables transport
# to BDHS 2022, and where (PR/HR/IR) the analogues live.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
})

files <- list(
  PR_2018 = "Datasets/BDPR7RDT/BDPR7RFL.DTA",
  PR_2022 = "Datasets/BDPR81DT/BDPR81FL.DTA",
  IR_2018 = "Datasets/BDIR7RDT/BDIR7RFL.DTA",
  IR_2022 = "Datasets/BDIR81DT/BDIR81FL.DTA",
  HR_2022 = "Datasets/BDHR81DT/BDHR81FL.DTA",
  BR_2022 = "Datasets/BDBR81DT/BDBR81FL.DTA"
)

file_meta <- lapply(files, function(f) {
  meta_var <- if (grepl("^BDP|^BDH", basename(f))) "hv007" else "v007"
  d <- read_dta(f, col_select = all_of(meta_var))
  list(path = f, nrows = nrow(d),
       years = paste(sort(unique(d[[meta_var]])), collapse = ","))
})

col_lists <- lapply(files, function(f) names(read_dta(f, n_max = 0)))

# Direct presence by 2017-18 variable name
project_vars <- c(
  sb308   = "occupation",
  sb318b  = "advised reduce salt",
  sb318c  = "advised lose weight",
  sb318d  = "advised stop smoking",
  sb318e  = "advised exercise more",
  sbbm    = "BMI scalar",
  hv226   = "cooking fuel",
  hv201   = "water source",
  hv205   = "toilet type",
  hv241   = "kitchen has separate room (dropped Phase 5)",
  hv242   = "kitchen location (dropped Phase 5)",
  hv009   = "household members (crowding numerator)",
  hv216   = "sleeping rooms (crowding denominator)",
  sb333aa = "BP reading 1 (2017-18 code)",
  sb333ab = "BP reading 2 (2017-18 code)",
  sb318a  = "currently on BP medication",
  sb335b  = "glucose mmol/L",
  hv001 = "PSU", hv005 = "household weight",
  hv021 = "PSU (strat)", hv023 = "stratum",
  hv024 = "division", hv025 = "urban/rural",
  hv104 = "sex", hv105 = "age",
  hv106 = "education", hv115 = "marital status",
  hv270 = "wealth index"
)
presence <- data.frame(
  var = names(project_vars),
  label = unname(project_vars),
  PR_2018 = vapply(names(project_vars), function(v) v %in% col_lists$PR_2018, logical(1)),
  PR_2022 = vapply(names(project_vars), function(v) v %in% col_lists$PR_2022, logical(1)),
  HR_2022 = vapply(names(project_vars), function(v) v %in% col_lists$HR_2022, logical(1)),
  IR_2022 = vapply(names(project_vars), function(v) v %in% col_lists$IR_2022, logical(1)),
  stringsAsFactors = FALSE
)

# BDHS 2022 stores biomarkers/NCD module under different naming. Identify by pattern.
twentytwo_patterns <- list(
  women_BP_readings_2022   = list(file="PR_2022", regex="^wbp[0-9]+$"),
  men_BP_readings_2022     = list(file="PR_2022", regex="^mbp[0-9]+$"),
  women_anthro_HR_2022     = list(file="HR_2022", regex="^ha[0-9]+(a|b)?_[0-9]+$"),
  men_anthro_HR_2022       = list(file="HR_2022", regex="^hb[0-9]+(a|b)?_[0-9]+$"),
  ncd_module_PR_2022       = list(file="PR_2022", regex="^sb3"),
  ncd_module_HR_2022_wide  = list(file="HR_2022", regex="^sb3[0-9]+[a-z]?_[0-9]+$"),
  ncd_selection_indicator  = list(file="PR_2022", regex="^shbpbg$|^sbpbg$"),
  biomarker_sel_IR_2022    = list(file="IR_2022", regex="^v754")
)
pattern_hits <- lapply(twentytwo_patterns, function(p) {
  grep(p$regex, col_lists[[p$file]], value = TRUE)
})

mapping <- data.frame(
  ncdvi_role = c(
    "occupation", "BMI_cat", "salt_intake (advice)", "lose_wgt (advice)",
    "stop_smok (advice)", "exer_more (advice)",
    "cook_fuel", "water_source", "toilet_type", "crowding",
    "outcome: SBP+DBP+meds", "diabetic (glucose)"
  ),
  var_2018_in_PR = c(
    "sb308", "sbbm",
    "sb318b","sb318c","sb318d","sb318e",
    "hv226","hv201","hv205","hv009/hv216",
    "sb333aa,ab + sb318a","sb335b"
  ),
  location_2022 = c(
    "BDIR81 v716 (women only)",
    "BDHR81 ha40_k (BMI*100, wide per slot)",
    "ABSENT", "ABSENT", "ABSENT", "ABSENT",
    "BDPR81 hv226", "BDPR81 hv201", "BDPR81 hv205", "BDPR81 hv009/hv216",
    "BDPR81 wbp9/10, wbp13/14, wbp22/23 + wbp19",
    "BDHR81 sb367g_k (glucose*10) + sb340_k (med)"
  ),
  status = c(
    "PARTIAL (women only via BDIR81)",
    "PRESENT (wide format requires reshape)",
    "ABSENT", "ABSENT", "ABSENT", "ABSENT",
    "PRESENT", "PRESENT", "PRESENT", "PRESENT",
    "PRESENT",
    "PRESENT"
  ),
  stringsAsFactors = FALSE
)

v463_2022 <- intersect(grep("^v463|^v485", col_lists$IR_2022, value = TRUE),
                       grep("^v463|^v485", col_lists$IR_2022, value = TRUE))

audit <- list(
  run_at = Sys.time(),
  file_meta = file_meta,
  col_counts = sapply(col_lists, length),
  direct_presence = presence,
  pattern_hits = pattern_hits,
  mapping = mapping,
  verdict_full10  = "ABSENT (sb318b-e dropped)",
  verdict_sens6   = "TRANSPORTABLE with engineering (BDHR81 wide reshape + BDIR81 women-only occupation)",
  verdict_outcome = "PRESENT: wbp9/10/13/14/22/23 + wbp19 in BDPR81",
  behavioral_2022_empty = v463_2022
)
saveRDS(audit, "outputs/phase8a_audit.rds")
