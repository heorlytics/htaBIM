# tests/testthat/test-market-share.R

.make_pop <- function(years = 1:3) {
  bim_population(
    indication  = "Test",
    country     = "custom",
    years       = years,
    prevalence  = 0.01,
    n_total_pop = 1e6
  )
}

test_that("bim_market_share returns correct class", {
  pop <- .make_pop()
  ms  <- bim_market_share(
    population     = pop,
    treatments     = c("A", "B"),
    new_drug       = "B",
    shares_current = c(A = 1.0, B = 0.0),
    shares_new     = c(A = 0.8, B = 0.2)
  )
  expect_s3_class(ms, "bim_market_share")
})

test_that("bim_market_share errors when shares don't sum to 1", {
  pop <- .make_pop()
  expect_error(
    bim_market_share(
      population     = pop,
      treatments     = c("A", "B"),
      new_drug       = "B",
      shares_current = c(A = 0.6, B = 0.6),
      shares_new     = c(A = 0.8, B = 0.2)
    ),
    "sum to 1"
  )
})

test_that("bim_market_share errors when new_drug not in treatments", {
  pop <- .make_pop()
  expect_error(
    bim_market_share(
      population     = pop,
      treatments     = c("A", "B"),
      new_drug       = "C",
      shares_current = c(A = 1.0, B = 0.0),
      shares_new     = c(A = 0.8, B = 0.2)
    ),
    "must be an element"
  )
})

test_that("linear dynamics produces increasing new drug share", {
  pop <- .make_pop(1:5)
  ms  <- bim_market_share(
    population     = pop,
    treatments     = c("A", "B"),
    new_drug       = "B",
    shares_current = c(A = 1.0, B = 0.0),
    shares_new     = c(A = 0.8, B = 0.2),
    dynamics       = "linear",
    uptake_params  = list(ramp_years = 4)
  )
  base_b <- ms$shares[ms$shares$treatment == "B" & ms$shares$scenario == "base", ]
  shares_b <- base_b[order(base_b$year), "share"]
  expect_true(all(diff(shares_b) >= 0))
})

test_that("scenarios are recorded", {
  pop <- .make_pop()
  ms  <- bim_market_share(
    population     = pop,
    treatments     = c("A", "B"),
    new_drug       = "B",
    shares_current = c(A = 1.0, B = 0.0),
    shares_new     = c(A = 0.8, B = 0.2),
    scenarios      = list(low = c(A = 0.9, B = 0.1))
  )
  expect_true("low" %in% ms$meta$scenarios)
})

test_that("print.bim_market_share does not error", {
  pop <- .make_pop()
  ms  <- bim_market_share(
    population     = pop,
    treatments     = c("A", "B"),
    new_drug       = "B",
    shares_current = c(A = 1.0, B = 0.0),
    shares_new     = c(A = 0.8, B = 0.2)
  )
  expect_output(print(ms), "htaBIM Market Share")
})
