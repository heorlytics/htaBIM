# tests/testthat/test-population.R

test_that("bim_population returns correct class", {
  pop <- bim_population(
    indication  = "Test",
    country     = "GB",
    years       = 1:3,
    prevalence  = 0.01,
    n_total_pop = 1e6
  )
  expect_s3_class(pop, "bim_population")
})

test_that("bim_population annual data.frame has correct columns", {
  pop <- bim_population(
    indication  = "Test",
    country     = "GB",
    years       = 1:3,
    prevalence  = 0.01,
    n_total_pop = 1e6
  )
  expect_true(all(c("year", "n_total_pop", "n_eligible") %in% names(pop$annual)))
})

test_that("bim_population funnel multiplication is correct", {
  pop <- bim_population(
    indication     = "Test",
    country        = "custom",
    years          = 1L,
    prevalence     = 0.01,
    n_total_pop    = 1e6,
    diagnosed_rate = 0.5,
    treated_rate   = 0.8,
    eligible_rate  = 0.5
  )
  expected <- round(1e6 * 0.01 * 0.5 * 0.8 * 0.5)
  expect_equal(pop$annual$n_eligible[1L], expected)
})

test_that("bim_population respects growth_rate", {
  pop <- bim_population(
    indication  = "Test",
    country     = "custom",
    years       = 1:3,
    prevalence  = 0.01,
    n_total_pop = 1e6,
    growth_rate = 0.10
  )
  expect_gt(pop$annual$n_eligible[3L], pop$annual$n_eligible[1L])
})

test_that("bim_population errors on bad inputs", {
  expect_error(
    bim_population("", "GB", 1:3, prevalence = 0.01, n_total_pop = 1e6),
    "non-empty"
  )
  expect_error(
    bim_population("T", "GB", 1:3, prevalence = 0.01, n_total_pop = 1e6,
                   diagnosed_rate = 1.5),
    "\\[0, 1\\]"
  )
  expect_error(
    bim_population("T", "custom", 1:3, n_total_pop = 1e6,
                   approach = "prevalent"),
    "prevalence.*required"
  )
})

test_that("bim_population incident approach works", {
  pop <- bim_population(
    indication  = "Test",
    country     = "custom",
    years       = 1:2,
    incidence   = 10,
    n_total_pop = 1e6,
    approach    = "incident"
  )
  expect_equal(pop$annual$n_prevalent_or_incident[1L], round(10 / 1e5 * 1e6))
})

test_that("print and summary do not error", {
  pop <- bim_population(
    indication  = "Test", country = "custom",
    years = 1:2, prevalence = 0.01, n_total_pop = 1e6
  )
  expect_output(print(pop),   "htaBIM Population")
  expect_output(summary(pop), "Population Summary")
})
