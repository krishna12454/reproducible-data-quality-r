# PRD — Reproducible Research: Data Quality & Analysis (R)

## Problem statement
Build an academic CS project "Reproducible Research Data Quality and Analysis"
as a genuine R-based statistical workflow (tidyverse, janitor, ggplot2) with a
reproducible R Markdown report. Import a synthetic sleep/wellbeing CSV, validate
and clean it (preserving the original), compute descriptive stats / frequency
tables / correlations, produce publication figures and a report, add automated
tests, README, requirements, data dictionary, and clear structure. All data
synthetic. No invented affiliations/publications.

## Decisions
- Standalone R project (user choice 1a). R installed & verified in-environment.
- Report: R Markdown (`report/report.Rmd`). Dataset ~1000 rows. Tests: testthat.
- Synthetic data deliberately messy (missing/dupes/inconsistent labels/invalid).

## Architecture
- `R/` functions: utils, generate_data, validate (read-only), clean (preserves
  original), analysis, figures.
- `scripts/` runners: make_dataset, run_analysis, run_tests.
- `tests/testthat/` with known-answer tests.
- `report/report.Rmd` reproducible report. `outputs/` figures + tables.

## Implemented (2026-06) — verified end-to-end in-environment
- R 4.2.2 + packages installed; `make_dataset.R`, `run_analysis.R` run clean.
- 1020 raw rows (incl. 20 dupes) -> 1000 cleaned; invalid entries nulled;
  categories canonicalised; sentinels -> NA.
- Correlations sensible: sleep +0.50, stress -0.48, exercise +0.23 vs wellbeing.
- 4 ggplot2 figures + 8 summary CSV tables generated.
- `scripts/run_tests.R`: all testthat tests pass (validate/clean/analysis).
- `report/report.html` renders with methodology/results/limitations.
- README, requirements-R.txt, setup/install.R, data_dictionary.md complete.

## Backlog (P1/P2)
- Optional Quarto (.qmd) variant of the report.
- Optional renv lockfile for exact package pinning.
- Optional Shiny/Plumber interface that shells out to the real R pipeline.
