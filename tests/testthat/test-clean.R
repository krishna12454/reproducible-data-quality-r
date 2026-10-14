# Tests for clean.R
# Each test uses a tiny dataset with a KNOWN expected result.

test_that("to_na converts sentinel strings to NA and keeps real values", {
  expect_true(is.na(to_na("NA")))
  expect_true(is.na(to_na("")))
  expect_true(is.na(to_na("  n/a ")))
  expect_equal(to_na("Male"), "Male")
})

test_that("coerce_numeric strips stray characters and nulls non-numbers", {
  expect_equal(coerce_numeric(c("7.5 hrs", "two", "-3", "12", " 4 ")),
               c(7.5, NA, -3, 12, 4))
})

test_that("flag_out_of_range sets values outside bounds to NA", {
  expect_equal(flag_out_of_range(c(-1, 5, 30), 0, 24), c(NA, 5, NA))
})

test_that("clean_gender canonicalises inconsistent labels", {
  expect_equal(
    clean_gender(c("M", "male", "FEMALE", "f ", "Other", "junk", NA)),
    c("Male", "Male", "Female", "Female", "Other", NA, NA)
  )
})

test_that("clean_sleep_quality returns an ordered factor", {
  f <- clean_sleep_quality(c("poor", "GOOD", "great", "average"))
  expect_s3_class(f, "ordered")
  expect_equal(as.character(f), c("Poor", "Good", "Excellent", "Fair"))
  expect_true(f[2] > f[1])         # Good > Poor
})

test_that("clean_dataset removes duplicates, nulls invalid entries, preserves original", {
  raw <- tibble(
    participant_id         = c("1", "1", "2"),
    survey_date            = c("2023-01-01", "2023-01-01", "2023-01-02"),
    age                    = c("30", "30", "200"),
    gender                 = c("M", "M", "female"),
    sleep_hours            = c("7", "7", "8"),
    sleep_quality          = c("good", "good", "poor"),
    caffeine_cups          = c("2", "2", "1"),
    screen_time_hours      = c("5", "5", "4"),
    exercise_days_per_week = c("3", "3", "4"),
    stress_level           = c("5", "5", "4"),
    mood                   = c("happy", "happy", "sad"),
    wellbeing_score        = c("60", "60", "70")
  )
  snapshot <- raw                       # for the preservation check
  cleaned <- clean_dataset(raw)

  expect_equal(nrow(cleaned), 2)        # the exact duplicate is removed
  expect_true(is.na(cleaned$age[cleaned$participant_id == "2"]))  # 200 invalid -> NA
  expect_equal(cleaned$gender[cleaned$participant_id == "2"], "Female")
  expect_identical(raw, snapshot)       # ORIGINAL untouched
})
