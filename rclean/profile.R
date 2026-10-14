#!/usr/bin/env Rscript
# ===========================================================================
# rclean/profile.R <input.csv>
# Inspect ANY uploaded CSV and emit a JSON profile of its columns:
# inferred type, missing counts, distinct counts, sample values and (for
# low-cardinality columns) the raw category labels. Emitted on stdout.
# ===========================================================================

suppressPackageStartupMessages({ library(dplyr); library(readr); library(stringr); library(jsonlite) })

args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else NA

if (!is.na(path)) {
  raw <- readr::read_csv(path, col_types = cols(.default = col_character()),
                         name_repair = "minimal")
} else {
  txt <- paste(readLines(file("stdin"), warn = FALSE), collapse = "\n")
  raw <- readr::read_csv(I(txt), col_types = cols(.default = col_character()),
                         name_repair = "minimal")
}
n <- nrow(raw)
sentinels <- c("", "NA", "N/A", "na", "n/a", "null", "NULL", "none", "-", "?", ".")

is_miss <- function(x) is.na(x) | stringr::str_trim(x) %in% sentinels

guess_type <- function(x) {
  v <- stringr::str_trim(x[!is_miss(x)])
  if (length(v) == 0) return("text")
  num <- suppressWarnings(as.numeric(stringr::str_replace_all(v, "[^0-9eE.+-]", "")))
  if (mean(!is.na(num)) > 0.8) return("numeric")
  fmts <- c("%Y-%m-%d", "%Y/%m/%d", "%d-%m-%Y", "%d/%m/%Y", "%m/%d/%Y", "%Y%m%d")
  best <- 0
  for (f in fmts) {
    d <- suppressWarnings(as.Date(v, format = f))
    best <- max(best, mean(!is.na(d)))
  }
  if (best > 0.8) return("date")
  if (dplyr::n_distinct(v) <= max(2, min(25, 0.5 * length(v)))) return("category")
  "text"
}

cols <- lapply(names(raw), function(nm) {
  x <- raw[[nm]]
  miss <- sum(is_miss(x))
  clean_vals <- stringr::str_trim(x[!is_miss(x)])
  t <- guess_type(x)
  ndist <- dplyr::n_distinct(clean_vals)
  labels <- NULL
  if (ndist > 0 && ndist <= 50) {
    tb <- sort(table(clean_vals), decreasing = TRUE)
    tb <- head(tb, 50)
    labels <- lapply(names(tb), function(k) list(label = k, n = unname(as.integer(tb[k]))))
  }
  list(
    name = nm,
    inferred_type = t,
    n_missing = miss,
    pct_missing = round(100 * miss / n, 1),
    n_distinct = ndist,
    sample = head(unique(clean_vals), 8),
    labels = labels
  )
})

dupes <- nrow(raw) - nrow(dplyr::distinct(raw))

cat(toJSON(list(n_rows = n, n_cols = ncol(raw), duplicate_rows = dupes,
                columns = cols),
           auto_unbox = TRUE, na = "null", dataframe = "rows"))
