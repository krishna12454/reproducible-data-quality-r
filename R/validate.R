# ---------------------------------------------------------------------------
# validate.R
# Transparent data-quality VALIDATION functions.
# These functions only INSPECT the data; they never modify it.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

#' Count missing values per column (treating sentinel strings as missing)
#'
#' @return A tibble with one row per variable: variable, missing, pct_missing.
detect_missing <- function(df, sentinels = NA_SENTINELS) {
  n <- nrow(df)
  df %>%
    mutate(across(everything(), ~ to_na(.x, sentinels))) %>%
    summarise(across(everything(), ~ sum(is.na(.x)))) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "missing") %>%
    mutate(pct_missing = round(100 * missing / n, 2)) %>%
    arrange(desc(missing))
}

#' Return the exact duplicate rows present in the data
#'
#' Rows that are identical across every column (keeping all copies).
detect_duplicates <- function(df) {
  df %>%
    group_by(across(everything())) %>%
    filter(dplyr::n() > 1) %>%
    ungroup()
}

#' Return the row indices whose numeric value falls outside [lo, hi]
#'
#' The column is coerced to numeric first. Genuinely missing values are
#' ignored (reported separately by detect_missing()).
detect_out_of_range <- function(df, col, lo, hi) {
  v <- coerce_numeric(df[[col]])
  which(!is.na(v) & (v < lo | v > hi))
}

#' Summarise the raw category labels seen in a column
#'
#' Useful for spotting inconsistent labels, e.g. "Male"/"male"/"M".
summarise_labels <- function(df, col) {
  df %>%
    count(label = .data[[col]], name = "n", sort = TRUE)
}

#' Build a consolidated, human-readable validation report
#'
#' @return A named list of tibbles / values describing data-quality issues.
build_validation_report <- function(df,
                                     id_col = "participant_id",
                                     ranges = VALID_RANGES) {
  missing <- detect_missing(df)
  dupes <- detect_duplicates(df)

  out_of_range <- purrr::imap_dfr(ranges, function(rng, col) {
    if (!col %in% names(df)) return(NULL)
    idx <- detect_out_of_range(df, col, rng[1], rng[2])
    tibble(variable = col, n_invalid = length(idx),
           lower = rng[1], upper = rng[2])
  })

  list(
    n_rows          = nrow(df),
    n_cols          = ncol(df),
    missing         = missing,
    n_duplicate_rows = nrow(dupes),
    duplicate_rows  = dupes,
    out_of_range    = out_of_range,
    gender_labels   = if ("gender" %in% names(df)) summarise_labels(df, "gender") else NULL,
    quality_labels  = if ("sleep_quality" %in% names(df)) summarise_labels(df, "sleep_quality") else NULL
  )
}

#' Pretty-print a validation report to the console
print_validation_report <- function(rep) {
  cat("================ DATA VALIDATION REPORT (synthetic data) ===========\n")
  cat(sprintf("Rows: %d | Columns: %d\n", rep$n_rows, rep$n_cols))
  cat(sprintf("Exact duplicate rows: %d\n\n", rep$n_duplicate_rows))
  cat("-- Missing values per column --\n"); print(rep$missing, n = Inf)
  cat("\n-- Out-of-range (invalid) numeric entries --\n"); print(rep$out_of_range, n = Inf)
  if (!is.null(rep$gender_labels)) {
    cat("\n-- Raw gender labels --\n"); print(rep$gender_labels, n = Inf)
  }
  if (!is.null(rep$quality_labels)) {
    cat("\n-- Raw sleep_quality labels --\n"); print(rep$quality_labels, n = Inf)
  }
  cat("====================================================================\n")
  invisible(rep)
}
