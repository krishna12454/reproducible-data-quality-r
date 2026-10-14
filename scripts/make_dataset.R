#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/make_dataset.R
# Generate the synthetic raw CSV and write it to data/raw/.
# Run from the project root:  Rscript scripts/make_dataset.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(tidyverse) })

# allow running from project root or from scripts/
if (basename(getwd()) == "scripts") setwd("..")

source("R/utils.R")
source("R/generate_data.R")

raw <- generate_sleep_wellbeing(n = 1000, seed = 42)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
out <- "data/raw/sleep_wellbeing_raw.csv"
readr::write_csv(raw, out)

message(sprintf("Wrote %d rows x %d cols to %s (SYNTHETIC data).",
                nrow(raw), ncol(raw), out))
