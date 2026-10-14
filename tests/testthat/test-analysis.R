# Tests for analysis.R
# Each test uses a tiny dataset with a KNOWN expected result.

test_that("descriptive_stats computes correct summaries and counts missing", {
  df <- tibble(x = c(1, 2, 3, NA))
  res <- descriptive_stats(df, "x")
  expect_equal(res$mean, 2)
  expect_equal(res$median, 2)
  expect_equal(res$n, 3)
  expect_equal(res$missing, 1)
  expect_equal(res$min, 1)
  expect_equal(res$max, 3)
})

test_that("correlation_matrix detects a perfect positive correlation", {
  df <- tibble(a = 1:10, b = 2 * (1:10))
  m <- correlation_matrix(df, c("a", "b"))
  expect_equal(unname(m["a", "b"]), 1)
})

test_that("frequency_table counts categories correctly", {
  df <- tibble(g = c("Male", "Male", "Female"))
  ft <- frequency_table(df, g)
  expect_equal(ft$n[ft$g == "Male"], 2)
  expect_equal(ft$n[ft$g == "Female"], 1)
})

test_that("cor_test_pair returns an estimate and p-value on complete pairs", {
  df <- tibble(x = c(1, 2, 3, 4, 5), y = c(2, 4, 6, 8, 10))
  res <- cor_test_pair(df, "x", "y")
  expect_equal(res$estimate, 1)
  expect_equal(res$n, 5)
  expect_true(res$p_value < 0.05)
})
