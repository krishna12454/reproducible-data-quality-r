#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# scripts/group_comparison.R <factor>
# One-way ANOVA of wellbeing_score across the levels of a categorical factor
# ("sleep_quality", "gender" or "mood"), computed on the CLEANED data.
# Emits group means + the ANOVA F test (with eta-squared) as JSON on stdout.
#   Rscript scripts/group_comparison.R sleep_quality
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(tidyverse); library(jsonlite) })

if (basename(getwd()) == "scripts") setwd("..")

args <- commandArgs(trailingOnly = TRUE)
fac <- if (length(args) >= 1) args[1] else "sleep_quality"
if (!fac %in% c("sleep_quality", "gender", "mood")) {
  stop("factor must be sleep_quality, gender or mood")
}

clean_path <- "data/processed/sleep_wellbeing_clean.csv"
if (!file.exists(clean_path)) stop("Cleaned data not found. Run run_analysis.R first.")

d <- readr::read_csv(clean_path, show_col_types = FALSE) %>%
  select(group = all_of(fac), wellbeing_score) %>%
  tidyr::drop_na() %>%
  mutate(group = factor(group))

groups <- d %>%
  group_by(group) %>%
  summarise(n = dplyr::n(),
            mean = round(mean(wellbeing_score), 2),
            sd = round(sd(wellbeing_score), 2), .groups = "drop") %>%
  arrange(desc(mean))

fit <- aov(wellbeing_score ~ group, data = d)
s <- summary(fit)[[1]]
ss_between <- s[["Sum Sq"]][1]
ss_total <- sum(s[["Sum Sq"]])

anova <- list(
  factor = fac,
  df_between = s[["Df"]][1],
  df_within = s[["Df"]][2],
  f = round(s[["F value"]][1], 3),
  p = s[["Pr(>F)"]][1],
  eta_sq = round(ss_between / ss_total, 3)
)

# Tukey HSD post-hoc pairwise comparisons
tuk <- as.data.frame(TukeyHSD(fit)$group)
tukey <- tibble(
  pair = rownames(tuk),
  diff = round(tuk[["diff"]], 2),
  lwr = round(tuk[["lwr"]], 2),
  upr = round(tuk[["upr"]], 2),
  p_adj = round(tuk[["p adj"]], 4)
) %>% arrange(p_adj)

cat(jsonlite::toJSON(list(factor = fac, n = nrow(d), groups = groups,
                          anova = anova, tukey = tukey),
                     dataframe = "rows", na = "null", auto_unbox = TRUE, digits = 6))
