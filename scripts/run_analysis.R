#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/run_analysis.R
# End-to-end reproducible pipeline:
#   load raw -> validate -> clean -> analyse -> figures -> write outputs
# Run from the project root:  Rscript scripts/run_analysis.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

if (basename(getwd()) == "scripts") setwd("..")

# Load every function file
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

raw_path <- "data/raw/sleep_wellbeing_raw.csv"
if (!file.exists(raw_path)) {
  stop("Raw data not found. Run `Rscript scripts/make_dataset.R` first.")
}

# ---- 1. Load (everything as character, like a real messy CSV) -------------
raw <- readr::read_csv(raw_path, col_types = cols(.default = col_character()))
message("Loaded raw rows: ", nrow(raw))

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

# ---- 2. Validate -----------------------------------------------------------
report <- build_validation_report(raw)
print_validation_report(report)
readr::write_csv(report$missing, "outputs/tables/missing_report.csv")
readr::write_csv(report$out_of_range, "outputs/tables/invalid_entries_report.csv")

# ---- 3. Clean (original `raw` is preserved) -------------------------------
cleaned <- clean_dataset(raw)
readr::write_csv(cleaned, "data/processed/sleep_wellbeing_clean.csv")
readr::write_csv(utils::head(raw, 25), "outputs/tables/raw_preview.csv")
readr::write_csv(utils::head(cleaned, 25), "outputs/tables/cleaned_preview.csv")
message(sprintf("Cleaned rows: %d (removed %d duplicate rows)",
                nrow(cleaned), nrow(raw) - nrow(cleaned)))

# ---- 3b. Machine-readable validation summary (for the web UI) ------------
validation_summary <- tibble::tibble(
  metric = c("raw_rows", "cleaned_rows", "duplicate_rows_removed",
             "total_missing_cells", "total_invalid_entries",
             "distinct_raw_gender_labels", "distinct_raw_quality_labels"),
  value = c(nrow(raw), nrow(cleaned), nrow(raw) - nrow(cleaned),
            sum(report$missing$missing), sum(report$out_of_range$n_invalid),
            nrow(report$gender_labels), nrow(report$quality_labels))
)
readr::write_csv(validation_summary, "outputs/tables/validation_summary.csv")

# ---- 4. Analyse ------------------------------------------------------------
num_cols <- c("age", "sleep_hours", "caffeine_cups", "screen_time_hours",
              "exercise_days_per_week", "stress_level", "wellbeing_score")

desc <- descriptive_stats(cleaned, num_cols)
readr::write_csv(desc, "outputs/tables/descriptive_stats.csv")

readr::write_csv(as_tibble(frequency_table(cleaned, gender)),
                 "outputs/tables/gender_frequency.csv")
readr::write_csv(as_tibble(frequency_table(cleaned, sleep_quality)),
                 "outputs/tables/sleep_quality_frequency.csv")
readr::write_csv(as_tibble(frequency_table(cleaned, mood)),
                 "outputs/tables/mood_frequency.csv")

cor_mat <- correlation_matrix(cleaned, num_cols)
write.csv(round(cor_mat, 3), "outputs/tables/correlation_matrix.csv")

key_corr <- bind_rows(
  cor_test_pair(cleaned, "sleep_hours", "wellbeing_score"),
  cor_test_pair(cleaned, "stress_level", "wellbeing_score"),
  cor_test_pair(cleaned, "exercise_days_per_week", "wellbeing_score")
)
readr::write_csv(key_corr, "outputs/tables/key_correlations.csv")
print(key_corr)

# ---- 5. Figures ------------------------------------------------------------
save_figures(cleaned)

message("Done. See outputs/tables and outputs/figures.")
