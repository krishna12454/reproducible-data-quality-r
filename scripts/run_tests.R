#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/run_tests.R
# Run the automated testthat suite.
# Run from the project root:  Rscript scripts/run_tests.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(testthat)
  library(tidyverse)
  library(janitor)
})

if (basename(getwd()) == "scripts") setwd("..")

# Load the functions under test into the global environment
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

testthat::test_dir("tests/testthat", reporter = "summary", stop_on_failure = TRUE)
message("All tests passed.")
