#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/regression.R
# Multiple linear regression of wellbeing_score on the numeric predictors,
# fitted with lm() on the CLEANED data. Emits the coefficient table, R-squared
# and the overall F test as JSON on stdout.
#   Rscript scripts/regression.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(tidyverse); library(jsonlite) })

if (basename(getwd()) == "scripts") setwd("..")

clean_path <- "data/processed/sleep_wellbeing_clean.csv"
if (!file.exists(clean_path)) stop("Cleaned data not found. Run run_analysis.R first.")

d <- readr::read_csv(clean_path, show_col_types = FALSE)

fit <- lm(wellbeing_score ~ sleep_hours + stress_level + exercise_days_per_week +
            caffeine_cups + screen_time_hours + age, data = d)
s <- summary(fit)
cm <- s$coefficients

coefs <- tibble(
  term = rownames(cm),
  estimate = round(cm[, "Estimate"], 3),
  std_error = round(cm[, "Std. Error"], 3),
  t_value = round(cm[, "t value"], 2),
  p_value = round(cm[, "Pr(>|t|)"], 4)
)

fstat <- s$fstatistic
f_p <- unname(pf(fstat[1], fstat[2], fstat[3], lower.tail = FALSE))

result <- list(
  formula = "wellbeing_score ~ sleep_hours + stress_level + exercise_days_per_week + caffeine_cups + screen_time_hours + age",
  n = nobs(fit),
  coefficients = coefs,
  r_squared = round(s$r.squared, 3),
  adj_r_squared = round(s$adj.r.squared, 3),
  f_statistic = round(unname(fstat[1]), 2),
  f_p = f_p
)

cat(jsonlite::toJSON(result, dataframe = "rows", na = "null",
                     auto_unbox = TRUE, digits = 6))
