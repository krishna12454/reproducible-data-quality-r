#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/subset_analysis.R <gender> <sleep_quality>
# Recompute descriptive stats + key correlations in R on a FILTERED subset of
# the cleaned data, and emit the result as JSON on stdout. Used by the web UI
# to prove the analysis runs live on demand for any subset.
#   Rscript scripts/subset_analysis.R Male Good
#   Rscript scripts/subset_analysis.R all all
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(tidyverse); library(jsonlite) })

if (basename(getwd()) == "scripts") setwd("..")
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

args <- commandArgs(trailingOnly = TRUE)
f_gender  <- if (length(args) >= 1) args[1] else "all"
f_quality <- if (length(args) >= 2) args[2] else "all"

clean_path <- "data/processed/sleep_wellbeing_clean.csv"
if (!file.exists(clean_path)) stop("Cleaned data not found. Run run_analysis.R first.")

d <- readr::read_csv(clean_path, show_col_types = FALSE)
if (f_gender != "all")  d <- dplyr::filter(d, gender == f_gender)
if (f_quality != "all") d <- dplyr::filter(d, as.character(sleep_quality) == f_quality)

num_cols <- c("age", "sleep_hours", "caffeine_cups", "screen_time_hours",
              "exercise_days_per_week", "stress_level", "wellbeing_score")

safe_cor <- function(x, y) {
  out <- tryCatch(cor_test_pair(d, x, y),
                  error = function(e) tibble(x = x, y = y, method = "pearson",
                                             n = 0, estimate = NA, statistic = NA,
                                             p_value = NA))
  out
}

result <- list(
  n = nrow(d),
  gender = f_gender,
  sleep_quality = f_quality,
  descriptive = if (nrow(d) > 0) descriptive_stats(d, num_cols) else tibble(),
  key_correlations = if (nrow(d) > 2) bind_rows(
    safe_cor("sleep_hours", "wellbeing_score"),
    safe_cor("stress_level", "wellbeing_score"),
    safe_cor("exercise_days_per_week", "wellbeing_score")
  ) else tibble()
)

cat(jsonlite::toJSON(result, dataframe = "rows", na = "null", auto_unbox = TRUE,
                     digits = 6))
