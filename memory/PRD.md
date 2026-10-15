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

## Vendor-neutral / portability (2026-06) — verified in-environment
- De-branded the codebase so it can be published as a standalone project:
  - Backend LLM swapped from `emergentintegrations`/`EMERGENT_LLM_KEY` to the
    standard `openai` SDK (`OPENAI_API_KEY` / `OPENAI_MODEL` / optional
    `OPENAI_BASE_URL`); deterministic R/Python fallback when no key is set, so
    the app runs fully offline. `requirements.txt` no longer has emergentintegrations.
  - `frontend/public/index.html`: removed emergent meta/script + PostHog block.
  - `frontend/craco.config.js`: rewritten without `@emergentbase/overlay` and
    `@emergentbase/visual-edits`; both removed from package.json/yarn.lock.
  - Neutralized testIds + comments; test default URLs now `http://localhost:8001`.
  - `.gitignore` now excludes all `.env*` (keeps `.env.example`), `.emergent/`,
    and R libs/outputs. Added `backend/.env.example` and `frontend/.env.example`.
  - Residual: `.emergent/` is git-TRACKED (emergent.yml + markers) and must be
    deleted from the public GitHub repo after pushing; cannot be removed in-pod.

## Presentation & diagnostics (2026-06) — verified in-environment
- Added regression model-assumption diagnostics (ggplot2): residuals-vs-fitted
  (`05_resid_fitted.png`) and normal Q-Q of residuals (`06_qq.png`), generated
  in `R/figures.R::save_figures` from the same lm model as `scripts/regression.R`.
  Exposed via `FIGURES` in server.py and the frontend figures gallery (new keys
  `resid_fitted`, `qq`). Both endpoints return HTTP 200 image/png.
- README: added a "Results showcase" section embedding the real ggplot2 outputs
  (`docs/figures/*.png`) and an animated `docs/demo.gif` built by `docs/make_gif.py`.
  (Real app-UI screenshots can't be written to the repo by the screenshot tool;
  genuine R result figures are used instead.)
- Added `LICENSE` (MIT) — copyright placeholder `[Your Name]` to be filled in.

## Backlog (P1/P2)
- Optional Quarto (.qmd) variant of the report.
- Optional renv lockfile for exact package pinning.
- Residual & QQ diagnostic plots (P1); seed control (P2).

## R engine resilience (2026-06) — verified in-environment
- Root cause of recurring "R engine unavailable": system shared lib
  `libuv.so.1` (needed by the `fs`/tidyverse packages) lives in `/usr/lib`,
  which is wiped on pod resets. The `/app/.Rlib` durable R-package fix did not
  cover system `.so` files.
- Fix: durable copy of `libuv.so.1` kept at `/app/.Rsys/lib`; all Rscript
  subprocesses run with `LD_LIBRARY_PATH` prepending it (`_r_env()` in
  server.py). Startup self-heal (`_ensure_r_syslib`) restores it from /usr if
  the durable copy is ever deleted. R now resolves libuv independent of /usr.
- `/api/health` now actually LOADS tidyverse/janitor/ggplot2/testthat (was only
  checking `installed.packages()`), so it no longer falsely reports healthy.
- Frontend: prominent "engine unavailable" banner with Retry (data-testid
  `engine-down-banner` / `retry-engine-btn`) + reusable `checkHealth()`.

## Web interface (added 2026-06) — verified 100% by testing agent
- FastAPI (`backend/server.py`) shells out to `Rscript` for real execution:
  /api/health, /api/analysis/run, /api/analysis/results, /api/tests/run,
  /api/analysis/figures/{key}, /api/dataset/download, /api/report.
- React dashboard (`frontend/src/App.js`) — scientific/Swiss design, dark/light,
  shows live validation metrics, raw-vs-cleaned, descriptive stats, frequency
  tables, correlation matrix + p-values, ggplot2 figure gallery, testthat
  runner with live R console output, and the R Markdown report link.
- Backend regression suite: `/app/backend/tests/test_r_pipeline.py` (10 tests).
- NOT hardcoded: every number/figure in the UI is produced live by R.
