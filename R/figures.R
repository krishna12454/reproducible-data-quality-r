# ---------------------------------------------------------------------------
# figures.R
# Publication-style figures built with ggplot2.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

#' A clean, publication-oriented ggplot theme
theme_pub <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.subtitle    = ggplot2::element_text(color = "grey30"),
      panel.grid.minor = ggplot2::element_blank(),
      plot.background  = ggplot2::element_rect(fill = "white", color = NA),
      legend.position  = "bottom"
    )
}

SYNTH_TAG <- "Synthetic data \u2013 for demonstration only"

fig_sleep_hist <- function(df) {
  ggplot(df, aes(x = sleep_hours)) +
    geom_histogram(binwidth = 0.5, fill = "#2c7fb8", color = "white") +
    labs(title = "Distribution of nightly sleep",
         subtitle = SYNTH_TAG, x = "Sleep hours per night", y = "Participants") +
    theme_pub()
}

fig_sleep_wellbeing <- function(df) {
  ggplot(df, aes(x = sleep_hours, y = wellbeing_score)) +
    geom_point(alpha = 0.35, color = "#2c7fb8") +
    geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "#d95f0e") +
    labs(title = "Sleep hours vs. self-reported wellbeing",
         subtitle = SYNTH_TAG, x = "Sleep hours per night", y = "Wellbeing score (0-100)") +
    theme_pub()
}

fig_wellbeing_by_quality <- function(df) {
  d <- dplyr::filter(df, !is.na(sleep_quality))
  ggplot(d, aes(x = sleep_quality, y = wellbeing_score, fill = sleep_quality)) +
    geom_boxplot(show.legend = FALSE) +
    scale_fill_brewer(palette = "Blues") +
    labs(title = "Wellbeing by sleep-quality category",
         subtitle = SYNTH_TAG, x = "Sleep quality", y = "Wellbeing score (0-100)") +
    theme_pub()
}

fig_corr_heatmap <- function(df, cols) {
  m <- correlation_matrix(df, cols)
  dd <- as.data.frame(as.table(m))
  names(dd) <- c("Var1", "Var2", "r")
  ggplot(dd, aes(x = Var1, y = Var2, fill = r)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", r)), size = 3) +
    scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                         midpoint = 0, limits = c(-1, 1)) +
    labs(title = "Correlation matrix of numeric variables",
         subtitle = SYNTH_TAG, x = NULL, y = NULL, fill = "Pearson r") +
    theme_pub() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

#' Render and save all figures as PNGs
save_figures <- function(df, out_dir = "outputs/figures") {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  num_cols <- intersect(
    c("sleep_hours", "wellbeing_score", "stress_level",
      "exercise_days_per_week", "caffeine_cups", "screen_time_hours", "age"),
    names(df)
  )
  ggsave(file.path(out_dir, "01_sleep_hist.png"),
         fig_sleep_hist(df), width = 7, height = 4.5, dpi = 150)
  ggsave(file.path(out_dir, "02_sleep_wellbeing.png"),
         fig_sleep_wellbeing(df), width = 7, height = 4.5, dpi = 150)
  ggsave(file.path(out_dir, "03_wellbeing_by_quality.png"),
         fig_wellbeing_by_quality(df), width = 7, height = 4.5, dpi = 150)
  ggsave(file.path(out_dir, "04_corr_heatmap.png"),
         fig_corr_heatmap(df, num_cols), width = 7, height = 6, dpi = 150)
  invisible(out_dir)
}
