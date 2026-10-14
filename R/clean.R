# ---------------------------------------------------------------------------
# clean.R
# Transparent, documented data-CLEANING functions.
#
# Design principle: the ORIGINAL dataset is always PRESERVED. Every function
# operates on a copy and returns a new object; nothing is mutated in place.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

# Plausible valid ranges for each numeric variable. Values outside these
# bounds are treated as invalid entries and set to NA during cleaning.
VALID_RANGES <- list(
  age                    = c(0, 120),
  sleep_hours            = c(0, 24),
  caffeine_cups          = c(0, 30),
  screen_time_hours      = c(0, 24),
  exercise_days_per_week = c(0, 7),
  stress_level           = c(1, 10),
  wellbeing_score        = c(0, 100)
)

#' Canonicalise gender labels to {Male, Female, Other, NA}
clean_gender <- function(x) {
  x <- stringr::str_to_lower(stringr::str_trim(as.character(x)))
  dplyr::case_when(
    x %in% c("m", "male")                         ~ "Male",
    x %in% c("f", "female")                       ~ "Female",
    x %in% c("o", "other", "nonbinary", "non-binary") ~ "Other",
    TRUE                                          ~ NA_character_
  )
}

#' Canonicalise sleep quality to an ordered factor Poor < Fair < Good < Excellent
clean_sleep_quality <- function(x) {
  x <- stringr::str_to_lower(stringr::str_trim(as.character(x)))
  lvl <- dplyr::case_when(
    x %in% c("poor", "bad")                       ~ "Poor",
    x %in% c("fair", "ok", "okay", "average")     ~ "Fair",
    x %in% c("good")                              ~ "Good",
    x %in% c("excellent", "great", "very good")   ~ "Excellent",
    TRUE                                          ~ NA_character_
  )
  factor(lvl, levels = c("Poor", "Fair", "Good", "Excellent"), ordered = TRUE)
}

#' Canonicalise mood labels
clean_mood <- function(x) {
  x <- stringr::str_to_lower(stringr::str_trim(as.character(x)))
  dplyr::case_when(
    x %in% c("happy", "content")             ~ "Happy",
    x %in% c("neutral", "ok", "okay")        ~ "Neutral",
    x %in% c("sad", "down")                  ~ "Sad",
    x %in% c("anxious", "stressed", "worried") ~ "Anxious",
    TRUE                                     ~ NA_character_
  )
}

#' Full cleaning pipeline
#'
#' Steps (each documented inline):
#'   1. Standardise column names (janitor::clean_names).
#'   2. Convert sentinel strings ("", "NA", "N/A", ...) to real NA.
#'   3. Coerce messy numeric columns to numeric and null out impossible values.
#'   4. Canonicalise categorical columns (gender, sleep_quality, mood).
#'   5. Parse the survey date.
#'   6. Remove exact duplicate rows.
#'
#' @param raw    A raw (character) tibble, e.g. from read_csv(col_character()).
#' @param ranges Named list of valid [lo, hi] numeric ranges.
#' @return A cleaned tibble. The input `raw` is NOT modified.
clean_dataset <- function(raw, ranges = VALID_RANGES) {
  stopifnot(is.data.frame(raw))

  cleaned <- raw %>%
    janitor::clean_names() %>%
    # (2) sentinel strings -> NA across all text columns
    mutate(across(where(is.character), ~ to_na(.x))) %>%
    # (3) numeric coercion + invalid-range handling
    mutate(
      age = flag_out_of_range(coerce_numeric(age),
                              ranges$age[1], ranges$age[2]),
      sleep_hours = flag_out_of_range(coerce_numeric(sleep_hours),
                                      ranges$sleep_hours[1], ranges$sleep_hours[2]),
      caffeine_cups = flag_out_of_range(coerce_numeric(caffeine_cups),
                                        ranges$caffeine_cups[1], ranges$caffeine_cups[2]),
      screen_time_hours = flag_out_of_range(coerce_numeric(screen_time_hours),
                                            ranges$screen_time_hours[1], ranges$screen_time_hours[2]),
      exercise_days_per_week = flag_out_of_range(coerce_numeric(exercise_days_per_week),
                                                 ranges$exercise_days_per_week[1], ranges$exercise_days_per_week[2]),
      stress_level = flag_out_of_range(coerce_numeric(stress_level),
                                       ranges$stress_level[1], ranges$stress_level[2]),
      wellbeing_score = flag_out_of_range(coerce_numeric(wellbeing_score),
                                          ranges$wellbeing_score[1], ranges$wellbeing_score[2]),
      # (4) categorical canonicalisation
      gender        = clean_gender(gender),
      sleep_quality = clean_sleep_quality(sleep_quality),
      mood          = clean_mood(mood),
      # (5) date parsing (invalid dates become NA)
      survey_date   = suppressWarnings(as.Date(stringr::str_trim(survey_date)))
    ) %>%
    # (6) drop exact duplicate rows
    distinct()

  cleaned
}
