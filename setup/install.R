#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# setup/install.R
# Install all R package dependencies for this project.
# Run once:  Rscript setup/install.R
# ---------------------------------------------------------------------------

pkgs <- c(
  "tidyverse",   # dplyr, tidyr, readr, stringr, purrr, ggplot2, tibble
  "janitor",     # clean_names, tabyl, get_dupes
  "testthat",    # automated tests
  "rmarkdown",   # render report.Rmd
  "knitr"        # report tables / knitting
)

installed <- rownames(installed.packages())
to_install <- setdiff(pkgs, installed)

if (length(to_install) > 0) {
  message("Installing: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

invisible(lapply(pkgs, function(p)
  suppressPackageStartupMessages(require(p, character.only = TRUE))))
message("Setup complete.")
