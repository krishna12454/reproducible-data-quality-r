# ---------------------------------------------------------------------------
# utils.R
# Shared helpers used across the analysis pipeline.
# ALL DATA IN THIS PROJECT IS SYNTHETIC / FICTIONAL.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

# Strings that should be treated as missing values when found in the raw data.
NA_SENTINELS <- c("", "NA", "N/A", "na", "n/a", "null", "NULL", "none",
                  "None", "-", "?", ".")

#' Convert sentinel strings to proper NA
#'
#' Trims surrounding whitespace, then replaces any value matching a known
#' missing-value sentinel with NA. Non-missing values are returned unchanged.
to_na <- function(x, sentinels = NA_SENTINELS) {
  x <- stringr::str_trim(as.character(x))
  x[x %in% sentinels] <- NA_character_
  x
}

#' Coerce a messy character vector to numeric
#'
#' Strips any characters that are not part of a number (e.g. "3 cups" -> "3",
#' "7.5 hrs" -> "7.5"). Values that contain no digits (e.g. "two") become NA.
coerce_numeric <- function(x) {
  x <- stringr::str_replace_all(as.character(x), "[^0-9eE.+-]", "")
  x <- dplyr::na_if(x, "")
  suppressWarnings(as.numeric(x))
}

#' Replace out-of-range numeric values with NA
flag_out_of_range <- function(x, lo, hi) {
  x[!is.na(x) & (x < lo | x > hi)] <- NA
  x
}
