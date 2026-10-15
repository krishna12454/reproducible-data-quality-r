# ===========================================================================
# rclean/engine.R
# Generic, deterministic CSV cleaning engine driven by a "rules" list.
# The SAME engine is used by the backend and embedded into the auto-generated
# reproducible script, so a run can always be reproduced exactly.
# ===========================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

# Base-R column-name standardiser (snake_case), so we don't depend on janitor.
rc_clean_names <- function(nms) {
  x <- tolower(trimws(nms))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  x <- gsub("_+", "_", x)
  x[x == "" | is.na(x)] <- "x"
  make.unique(x, sep = "_")
}

rc_default_sentinels <- c("", "NA", "N/A", "na", "n/a", "null", "NULL",
                          "none", "None", "-", "?", ".")

rc_coerce_numeric <- function(x) {
  x <- stringr::str_replace_all(as.character(x), "[^0-9eE.+-]", "")
  x <- dplyr::na_if(x, "")
  suppressWarnings(as.numeric(x))
}

# Robust date parsing: never errors, tries common formats, picks the best fit.
rc_parse_date <- function(x, fmt = NULL) {
  if (!is.null(fmt) && nzchar(fmt)) return(suppressWarnings(as.Date(x, format = fmt)))
  fmts <- c("%Y-%m-%d", "%Y/%m/%d", "%d-%m-%Y", "%d/%m/%Y", "%m/%d/%Y", "%Y%m%d")
  best <- as.Date(rep(NA, length(x))); bestn <- -1L
  for (f in fmts) {
    d <- suppressWarnings(as.Date(x, format = f))
    n <- sum(!is.na(d))
    if (n > bestn) { bestn <- n; best <- d }
  }
  best
}

#' Apply a list of cleaning rules to a (character) data frame.
#' Returns list(clean = <tibble>, audit = <list of operations>).
rc_apply_rules <- function(df, rules) {
  audit <- list()
  add <- function(op, col, n, detail = "") {
    audit[[length(audit) + 1]] <<- list(operation = op,
                                        column = if (is.null(col)) NA else col,
                                        cells_changed = as.integer(n),
                                        detail = detail)
  }

  sentinels <- unlist(rules$na_sentinels)
  if (is.null(sentinels)) sentinels <- rc_default_sentinels

  # 1. sentinel strings -> NA across all character columns
  nmiss <- 0L
  df[] <- lapply(df, function(x) {
    if (!is.character(x)) return(x)
    y <- stringr::str_trim(x)
    y[y %in% sentinels] <- NA_character_
    nmiss <<- nmiss + sum(!is.na(x) & is.na(y))
    y
  })
  add("standardize_missing", NULL, nmiss,
      paste("sentinels:", paste(sentinels, collapse = ", ")))

  # 2. per-column transformations
  for (col in rules$columns) {
    nm <- col$name
    if (is.null(df[[nm]])) next
    x <- df[[nm]]
    type <- col$type %||% "text"

    if (isTRUE(col$trim_whitespace) && is.character(x)) {
      x2 <- stringr::str_squish(x)
      n <- sum(x2 != x, na.rm = TRUE)
      x <- x2
      if (n > 0) add("trim_whitespace", nm, n)
    }

    if (type %in% c("numeric", "integer")) {
      before_na <- sum(is.na(x))
      v <- rc_coerce_numeric(x)
      lo <- col$numeric_min %||% -Inf
      hi <- col$numeric_max %||% Inf
      if (is.finite(lo) || is.finite(hi)) {
        inv <- !is.na(v) & (v < lo | v > hi)
        if (sum(inv) > 0) add("flag_out_of_range", nm, sum(inv),
                              sprintf("[%s, %s]", lo, hi))
        v[inv] <- NA
      }
      if (type == "integer") v <- round(v)
      add("coerce_numeric", nm, max(sum(is.na(v)) - before_na, 0))
      df[[nm]] <- v

    } else if (type == "date") {
      fmt <- col$date_format
      d <- rc_parse_date(x, fmt)
      add("coerce_date", nm, sum(is.na(d) & !is.na(x)))
      df[[nm]] <- d

    } else if (type == "category") {
      lm <- col$label_map
      if (!is.null(lm) && length(lm) > 0) {
        canon <- unlist(lm, use.names = TRUE)
        key_l <- tolower(stringr::str_squish(names(canon)))
        xl <- tolower(stringr::str_squish(x))
        idx <- match(xl, key_l)
        mapped <- ifelse(!is.na(idx), unname(canon)[idx], x)
        changed <- sum(!is.na(idx) & mapped != x, na.rm = TRUE)
        add("normalize_labels", nm, changed, paste(length(canon), "mappings"))
        df[[nm]] <- mapped
      } else {
        df[[nm]] <- x
      }

    } else {
      df[[nm]] <- x
    }
  }

  # 3. flag statistical outliers (IQR rule) — non-destructive, reported in audit
  if (isTRUE(rules$flag_outliers)) {
    for (nm in names(df)) {
      x <- df[[nm]]
      if (is.numeric(x)) {
        q <- stats::quantile(x, c(0.25, 0.75), na.rm = TRUE)
        iqr <- q[2] - q[1]
        if (is.finite(iqr) && iqr > 0) {
          lo <- q[1] - 1.5 * iqr; hi <- q[2] + 1.5 * iqr
          n <- sum(!is.na(x) & (x < lo | x > hi))
          if (n > 0) add("flag_outliers", nm, n,
                         sprintf("IQR: %d value(s) outside [%.2f, %.2f]", n, lo, hi))
        }
      }
    }
  }

  # 4. remove exact duplicate rows
  if (isTRUE(rules$remove_duplicate_rows)) {
    before <- nrow(df)
    df <- dplyr::distinct(df)
    add("remove_duplicate_rows", NULL, before - nrow(df))
  }

  # 5. standardise column names (done last so rules can use original names)
  if (isTRUE(rules$clean_column_names)) {
    old <- names(df)
    names(df) <- rc_clean_names(names(df))
    add("clean_column_names", NULL, sum(old != names(df)))
  }

  list(clean = df, audit = audit)
}
