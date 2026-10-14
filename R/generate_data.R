# ---------------------------------------------------------------------------
# generate_data.R
# Deterministically generate a SYNTHETIC, intentionally messy dataset of
# hypothetical sleep patterns and self-reported wellbeing.
#
# !!! ALL DATA IS SYNTHETIC / FICTIONAL. It does not describe real people. !!!
#
# This file only DEFINES the generator. Use scripts/make_dataset.R to write
# the CSV to disk.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

#' Generate a synthetic (messy) sleep & wellbeing dataset
#'
#' The underlying "true" signal is: more sleep and more exercise improve
#' wellbeing, while higher stress and caffeine reduce it. Realistic data
#' quality problems are then injected on purpose so that the cleaning and
#' validation workflow has something genuine to detect and fix.
#'
#' @param n    Number of participants (rows) before duplicates are added.
#' @param seed Random seed for full reproducibility.
#' @return A tibble of character columns (as it would be read from a raw CSV).
generate_sleep_wellbeing <- function(n = 1000, seed = 42) {
  set.seed(seed)

  participant_id <- sprintf("P%04d", seq_len(n))

  age <- pmax(round(rnorm(n, 35, 12)), 18)
  sleep_hours <- round(rnorm(n, 7, 1.2), 1)
  stress_level <- pmin(pmax(round(rnorm(n, 5, 2)), 1), 10)
  exercise_days_per_week <- pmin(rpois(n, 2), 7)
  caffeine_cups <- pmin(rpois(n, 2), 10)
  screen_time_hours <- round(pmax(rnorm(n, 5, 2), 0), 1)

  wellbeing_score <- 50 +
    5.0 * (sleep_hours - 7) -
    3.0 * (stress_level - 5) +
    2.0 * exercise_days_per_week -
    1.2 * caffeine_cups +
    rnorm(n, 0, 8)
  wellbeing_score <- round(pmin(pmax(wellbeing_score, 0), 100))

  sleep_quality <- as.character(cut(
    sleep_hours + rnorm(n, 0, 0.4),
    breaks = c(-Inf, 5.5, 6.5, 7.5, Inf),
    labels = c("Poor", "Fair", "Good", "Excellent")
  ))

  gender <- sample(c("Male", "Female", "Other"), n, replace = TRUE,
                   prob = c(0.48, 0.48, 0.04))
  mood <- sample(c("Happy", "Neutral", "Sad", "Anxious"), n, replace = TRUE)
  survey_date <- as.character(as.Date("2023-01-01") +
                                sample(0:120, n, replace = TRUE))

  df <- tibble(
    participant_id, survey_date, age, gender, sleep_hours, sleep_quality,
    caffeine_cups, screen_time_hours, exercise_days_per_week, stress_level,
    mood, wellbeing_score
  )
  # Treat everything as text, exactly like a raw CSV import, so that the
  # injected messiness survives.
  df <- df %>% mutate(across(everything(), as.character))

  # --- (1) inconsistent category labels -----------------------------------
  gi <- sample(seq_len(n), floor(0.25 * n))
  df$gender[gi] <- sample(c("male", "female", "M", "F", "MALE", "Female ", "m", " f"),
                          length(gi), replace = TRUE)
  sqi <- sample(seq_len(n), floor(0.20 * n))
  df$sleep_quality[sqi] <- sample(c("good", "GOOD", "poor", "Fair ", "excellent",
                                    "great", "average"),
                                  length(sqi), replace = TRUE)
  mi <- sample(seq_len(n), floor(0.15 * n))
  df$mood[mi] <- sample(c("happy", "SAD", "neutral ", "anxious", "stressed"),
                        length(mi), replace = TRUE)

  # --- (2) missing values (various sentinels) -----------------------------
  inject_na <- function(col, frac, sentinels = c("", "NA", "N/A", "na")) {
    idx <- sample(seq_len(n), floor(frac * n))
    df[[col]][idx] <<- sample(sentinels, length(idx), replace = TRUE)
  }
  inject_na("wellbeing_score", 0.05)
  inject_na("sleep_hours", 0.04)
  inject_na("caffeine_cups", 0.03)
  inject_na("mood", 0.03)
  inject_na("age", 0.02)

  # --- (3) invalid / impossible numeric entries ---------------------------
  df$sleep_hours[sample(seq_len(n), 8)] <- sample(c("30", "-2", "99", "25.5"),
                                                  8, replace = TRUE)
  df$age[sample(seq_len(n), 5)] <- sample(c("200", "-5", "0", "999"),
                                          5, replace = TRUE)
  df$wellbeing_score[sample(seq_len(n), 5)] <- sample(c("150", "-10"),
                                                      5, replace = TRUE)
  df$exercise_days_per_week[sample(seq_len(n), 4)] <- sample(c("10", "-1"),
                                                            4, replace = TRUE)
  df$caffeine_cups[sample(seq_len(n), 4)] <- c("two", "3 cups", "-1", "99")

  # --- (4) stray whitespace in a numeric-looking column -------------------
  sti <- sample(seq_len(n), 10)
  df$screen_time_hours[sti] <- paste0("  ", df$screen_time_hours[sti], "  ")

  # --- (5) duplicate records (~2%) ----------------------------------------
  dup_idx <- sample(seq_len(n), floor(0.02 * n))
  df <- bind_rows(df, df[dup_idx, ])

  # shuffle row order
  df[sample(seq_len(nrow(df))), ]
}
