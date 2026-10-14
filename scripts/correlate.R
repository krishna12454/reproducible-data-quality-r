#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/correlate.R <method>
# Recompute the correlation matrix and key correlations for a chosen method
# ("pearson" or "spearman") on the CLEANED data. Writes method-specific CSVs.
# Invoked on demand by the web backend to prove correlations are real R output.
#   Rscript scripts/correlate.R spearman
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(tidyverse) })

if (basename(getwd()) == "scripts") setwd("..")
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

args <- commandArgs(trailingOnly = TRUE)
method <- if (length(args) >= 1) tolower(args[1]) else "pearson"
if (!method %in% c("pearson", "spearman", "kendall")) {
  stop("method must be pearson, spearman or kendall")
}

clean_path <- "data/processed/sleep_wellbeing_clean.csv"
if (!file.exists(clean_path)) stop("Cleaned data not found. Run scripts/run_analysis.R first.")

cleaned <- readr::read_csv(clean_path, show_col_types = FALSE)
num_cols <- c("age", "sleep_hours", "caffeine_cups", "screen_time_hours",
              "exercise_days_per_week", "stress_level", "wellbeing_score")

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

cor_mat <- correlation_matrix(cleaned, num_cols, method = method)
write.csv(round(cor_mat, 3),
          sprintf("outputs/tables/correlation_matrix_%s.csv", method))

key <- bind_rows(
  cor_test_pair(cleaned, "sleep_hours", "wellbeing_score", method = method),
  cor_test_pair(cleaned, "stress_level", "wellbeing_score", method = method),
  cor_test_pair(cleaned, "exercise_days_per_week", "wellbeing_score", method = method)
)
readr::write_csv(key, sprintf("outputs/tables/key_correlations_%s.csv", method))

message(sprintf("Wrote %s correlations.", method))
