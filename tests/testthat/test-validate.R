# Tests for validate.R
# Each test uses a tiny dataset with a KNOWN expected result.

test_that("detect_missing counts NA and sentinel strings", {
  df <- tibble(a = c("1", "", "NA", "x"),
               b = c("NA", "N/A", "3", "4"))
  res <- detect_missing(df)
  expect_equal(res$missing[res$variable == "a"], 2)  # "" and "NA"
  expect_equal(res$missing[res$variable == "b"], 2)  # "NA" and "N/A"
})

test_that("detect_duplicates returns all copies of exact duplicate rows", {
  df <- tibble(id = c("1", "1", "2"), v = c("a", "a", "b"))
  res <- detect_duplicates(df)
  expect_equal(nrow(res), 2)       # both copies of id=1 returned
  expect_true(all(res$id == "1"))
})

test_that("detect_out_of_range returns indices of invalid numeric values", {
  df <- tibble(age = c("30", "200", "-5", "45"))
  idx <- detect_out_of_range(df, "age", 0, 120)
  expect_equal(idx, c(2, 3))       # 200 and -5 are out of [0,120]
})

test_that("summarise_labels exposes inconsistent category labels", {
  df <- tibble(gender = c("Male", "male", "M", "Female"))
  res <- summarise_labels(df, "gender")
  expect_equal(nrow(res), 4)       # four distinct raw labels
})
