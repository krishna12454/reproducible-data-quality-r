# ---------------------------------------------------------------------------
# analysis.R
# Descriptive statistics, frequency tables and correlations.
# All computations use real base-R / tidyverse statistics.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

#' Descriptive statistics for numeric columns
#'
#' @param df   A data frame.
#' @param cols Character vector of columns; defaults to all numeric columns.
#' @return A tibble: variable, n, missing, mean, sd, median, min, max.
descriptive_stats <- function(df, cols = NULL) {
  if (is.null(cols)) {
    cols <- df %>% select(where(is.numeric)) %>% names()
  }
  df %>%
    select(all_of(cols)) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
    group_by(variable) %>%
    summarise(
      n      = sum(!is.na(value)),
      missing = sum(is.na(value)),
      mean   = mean(value, na.rm = TRUE),
      sd     = sd(value, na.rm = TRUE),
      median = median(value, na.rm = TRUE),
      min    = min(value, na.rm = TRUE),
      max    = max(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(across(c(mean, sd, median, min, max), ~ round(.x, 2)))
}

#' Frequency table for a single categorical column (via janitor::tabyl)
#'
#' @return A tabyl/data.frame with counts and valid/overall percentages.
frequency_table <- function(df, col) {
  df %>%
    janitor::tabyl({{ col }}) %>%
    janitor::adorn_pct_formatting(digits = 1)
}

#' Correlation matrix for the chosen numeric columns
#'
#' @param method "pearson" (default), "spearman" or "kendall".
correlation_matrix <- function(df, cols, method = "pearson") {
  df %>%
    select(all_of(cols)) %>%
    cor(use = "pairwise.complete.obs", method = method)
}

#' Hypothesis test for the correlation between two numeric variables
#'
#' @return A tibble: x, y, method, n, estimate, statistic, p_value.
cor_test_pair <- function(df, x, y, method = "pearson") {
  cc <- df %>% select(all_of(c(x, y))) %>% tidyr::drop_na()
  res <- stats::cor.test(cc[[x]], cc[[y]], method = method)
  tibble(
    x = x, y = y, method = method, n = nrow(cc),
    estimate = unname(res$estimate),
    statistic = unname(res$statistic),
    p_value = res$p.value
  )
}
