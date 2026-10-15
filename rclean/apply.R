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

suppressPackageStartupMessages({ library(dplyr); library(readr); library(stringr); library(jsonlite); library(ggplot2) })

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

# ---- publication-style ggplot2 figures of the CLEANED data (base64 PNG) ---
render_b64 <- function(p, w = 6, h = 3.4) {
  tf <- tempfile(fileext = ".png")
  suppressMessages(ggsave(tf, p, width = w, height = h, dpi = 110, bg = "white"))
  on.exit(unlink(tf), add = TRUE)
  raw_bytes <- readBin(tf, "raw", file.info(tf)$size)
  paste0("data:image/png;base64,", jsonlite::base64_enc(raw_bytes))
}
theme_c <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

figures <- list()
clean <- res$clean

try({
  miss <- vapply(clean, function(x) sum(is.na(x)), integer(1))
  md <- data.frame(column = names(miss), missing = as.integer(miss))
  md <- md[order(-md$missing), ]
  md$column <- factor(md$column, levels = rev(md$column))
  p <- ggplot(md, aes(column, missing)) +
    geom_col(fill = "#1E3A8A") + coord_flip() +
    labs(title = "Missing values per column (after cleaning)", x = NULL, y = "Missing (NA) count") +
    theme_c
  figures[[length(figures) + 1]] <- list(title = "Missingness by column", src = render_b64(p))
}, silent = TRUE)

try({
  num_cols <- names(clean)[vapply(clean, is.numeric, logical(1))]
  if (length(num_cols) > 0) {
    col1 <- num_cols[1]
    d <- data.frame(v = clean[[col1]]); d <- d[!is.na(d$v), , drop = FALSE]
    if (nrow(d) > 1) {
      p2 <- ggplot(d, aes(v)) +
        geom_histogram(bins = 30, fill = "#059669", color = "white") +
        labs(title = paste0("Distribution of ", col1, " (cleaned)"), x = col1, y = "Count") +
        theme_c
      figures[[length(figures) + 1]] <- list(title = paste0("Distribution: ", col1), src = render_b64(p2))
    }
  }
}, silent = TRUE)

cat(toJSON(list(
  rows_before = nrow(raw),
  rows_after  = nrow(res$clean),
  n_cols      = ncol(res$clean),
  columns     = names(res$clean),
  audit       = res$audit,
  preview     = head(res$clean, 15),
  cleaned_csv = readr::format_csv(res$clean),
  figures     = figures,
  script      = script_text
), auto_unbox = TRUE, na = "null", dataframe = "rows", digits = 6))
