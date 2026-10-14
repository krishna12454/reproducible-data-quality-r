#!/usr/bin/env Rscript
# ===========================================================================
# rclean/apply.R <rules.json>   (CSV is streamed on stdin)
# Deterministically APPLY approved cleaning rules in R and print a JSON
# summary on stdout containing:
#   rows_before, rows_after, columns, audit,
#   preview (first rows), cleaned_csv (full cleaned CSV as text),
#   script (a STANDALONE reproducible R script as text).
# Nothing is written to disk — outputs are returned inline.
# ===========================================================================

suppressPackageStartupMessages({ library(dplyr); library(readr); library(stringr); library(jsonlite) })

args <- commandArgs(trailingOnly = TRUE)
rules_path <- args[1]

source("rclean/engine.R")

txt <- paste(readLines(file("stdin"), warn = FALSE), collapse = "\n")
raw <- readr::read_csv(I(txt), col_types = cols(.default = col_character()),
                       name_repair = "minimal")
rules <- jsonlite::fromJSON(rules_path, simplifyVector = FALSE)

res <- rc_apply_rules(raw, rules)

# ---- build a standalone, reproducible cleaning script (as text) -----------
engine_src <- readLines("rclean/engine.R")
rules_json <- toJSON(rules, auto_unbox = TRUE, pretty = TRUE)
rules_inline <- gsub("'", "\\\\'", paste(rules_json, collapse = "\n"))

header <- c(
  "#!/usr/bin/env Rscript",
  "# ==========================================================================",
  "# AUTO-GENERATED reproducible cleaning script.",
  "# Produced by the Universal CSV Cleaner. Re-run it any time to reproduce the",
  "# exact same cleaning on the same (or new) data:",
  "#   Rscript cleaning_script.R <input.csv> <output.csv>",
  "# Requires R packages: dplyr, readr, stringr, tibble, jsonlite.",
  "# ==========================================================================",
  ""
)
footer <- c(
  "",
  "# ---- approved cleaning rules (embedded) ----",
  paste0("rules_json <- '", rules_inline, "'"),
  "rules <- jsonlite::fromJSON(rules_json, simplifyVector = FALSE)",
  "",
  "args   <- commandArgs(trailingOnly = TRUE)",
  "input  <- if (length(args) >= 1) args[1] else 'input.csv'",
  "output <- if (length(args) >= 2) args[2] else 'cleaned.csv'",
  "",
  "raw <- readr::read_csv(input, col_types = readr::cols(.default = readr::col_character()), name_repair = 'minimal')",
  "res <- rc_apply_rules(raw, rules)",
  "readr::write_csv(res$clean, output)",
  "message('Cleaned ', nrow(raw), ' rows -> ', nrow(res$clean), ' rows. Wrote ', output)"
)
script_text <- paste(c(header, engine_src, footer), collapse = "\n")

cat(toJSON(list(
  rows_before = nrow(raw),
  rows_after  = nrow(res$clean),
  n_cols      = ncol(res$clean),
  columns     = names(res$clean),
  audit       = res$audit,
  preview     = head(res$clean, 15),
  cleaned_csv = readr::format_csv(res$clean),
  script      = script_text
), auto_unbox = TRUE, na = "null", dataframe = "rows", digits = 6))
