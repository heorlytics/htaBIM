# tests/testthat/test-costs.R

test_that("bim_costs returns correct class", {
  c1 <- bim_costs(
    treatments = c("A", "B"),
    drug_costs = c(A = 100, B = 5000)
  )
  expect_s3_class(c1, "bim_costs")
})

test_that("bim_costs total per patient is sum of categories", {
  c1 <- bim_costs(
    treatments       = c("A"),
    drug_costs       = c(A = 1000),
    monitoring_costs = c(A = 200),
    ae_costs         = c(A = 50)
  )
  yr1 <- c1$total[c1$total$year == 1L & c1$total$treatment == "A", ]
  expect_equal(yr1$total_cost_per_patient, 1250)
})

test_that("rebates reduce drug costs", {
  c1 <- bim_costs(
    treatments = c("A"),
    drug_costs = c(A = 1000),
    rebates    = c(A = 0.20)
  )
  drug_row <- c1$costs[c1$costs$treatment == "A" &
                         c1$costs$category == "drug" &
                         c1$costs$year == 1L, ]
  expect_equal(drug_row$total_annual_cost, 800)
})

test_that("bim_costs_drug calculates annual cost correctly", {
  cost <- bim_costs_drug(
    treatment           = "X",
    list_price_per_pack = 100,
    dose_per_admin      = 1,
    admin_per_year      = 12,
    units_per_pack      = 1
  )
  expect_equal(as.numeric(cost), 1200)
})

test_that("bim_costs_ae calculates expected AE cost", {
  ae_tab <- data.frame(
    ae_name   = c("AE1", "AE2"),
    rate      = c(0.10, 0.20),
    unit_cost = c(100,  200)
  )
  ae_cost <- bim_costs_ae("D", ae_tab)
  expect_equal(as.numeric(ae_cost), 0.10 * 100 + 0.20 * 200)
})

test_that("print.bim_costs does not error", {
  c1 <- bim_costs(
    treatments = c("A", "B"),
    drug_costs = c(A = 200, B = 5000)
  )
  expect_output(print(c1), "htaBIM Costs")
})

# ── Model tests ──────────────────────────────────────────────────────────────

.make_minimal_model <- function() {
  pop <- bim_population(
    indication  = "Test",
    country     = "custom",
    years       = 1:3,
    prevalence  = 0.01,
    n_total_pop = 1e6
  )
  ms <- bim_market_share(
    population     = pop,
    treatments     = c("Drug C", "Drug A"),
    new_drug       = "Drug A",
    shares_current = c("Drug C" = 1.0, "Drug A" = 0.0),
    shares_new     = c("Drug C" = 0.8, "Drug A" = 0.2)
  )
  costs <- bim_costs(
    treatments = c("Drug C", "Drug A"),
    drug_costs = c("Drug C" = 500, "Drug A" = 25000)
  )
  bim_model(pop, ms, costs)
}

test_that("bim_model returns correct class", {
  model <- .make_minimal_model()
  expect_s3_class(model, "bim_model")
})

test_that("bim_model results contain annual and cumulative", {
  model <- .make_minimal_model()
  expect_true("annual"     %in% names(model$results))
  expect_true("cumulative" %in% names(model$results))
})

test_that("budget impact is positive when new drug is more expensive", {
  model <- .make_minimal_model()
  ann   <- model$results$annual
  base  <- ann[ann$scenario == "base", ]
  expect_true(all(base$budget_impact > 0))
})

test_that("budget impact is 0 when shares_new equals shares_current", {
  pop <- bim_population(
    indication  = "Test",
    country     = "custom",
    years       = 1:2,
    prevalence  = 0.01,
    n_total_pop = 1e6
  )
  ms <- bim_market_share(
    population     = pop,
    treatments     = c("A", "B"),
    new_drug       = "B",
    shares_current = c(A = 0.8, B = 0.2),
    shares_new     = c(A = 0.8, B = 0.2)
  )
  costs <- bim_costs(
    treatments = c("A", "B"),
    drug_costs = c(A = 1000, B = 5000)
  )
  model <- bim_model(pop, ms, costs)
  ann   <- model$results$annual
  base  <- ann[ann$scenario == "base", ]
  expect_true(all(base$budget_impact == 0))
})

test_that("summary.bim_model prints without error", {
  model <- .make_minimal_model()
  expect_output(summary(model), "htaBIM Model Summary")
})

test_that("print.bim_model prints without error", {
  model <- .make_minimal_model()
  expect_output(print(model), "htaBIM Model")
})

# ── Payer tests ───────────────────────────────────────────────────────────────

test_that("bim_payer_default returns bim_payer", {
  p <- bim_payer_default()
  expect_s3_class(p, "bim_payer")
})

test_that("bim_payer validates cost_coverage range", {
  expect_error(bim_payer("X", cost_coverage = 1.5), "\\[0, 1\\]")
  expect_error(bim_payer("X", cost_coverage = -0.1), "\\[0, 1\\]")
})

test_that("pre-built payers return valid objects", {
  expect_s3_class(bim_payer_nhs(),          "bim_payer")
  expect_s3_class(bim_payer_cadth(),        "bim_payer")
  expect_s3_class(bim_payer_us_commercial(), "bim_payer")
})

# ── Sensitivity tests ─────────────────────────────────────────────────────────

test_that("bim_sensitivity_spec returns correct class", {
  spec <- bim_sensitivity_spec(
    prevalence_range    = c(0.005, 0.015),
    eligible_rate_range = c(0.20, 0.50)
  )
  expect_s3_class(spec, "bim_sensitivity_spec")
})

test_that("bim_run_dsa returns data.frame with correct columns", {
  model <- .make_minimal_model()
  spec  <- bim_sensitivity_spec(
    prevalence_range           = c(0.005, 0.015),
    eligible_rate_range        = c(0.50, 0.90),
    drug_cost_multiplier_range = c(0.85, 1.15)
  )
  dsa <- bim_run_dsa(model, spec, year = 3L)
  expect_s3_class(dsa, "bim_dsa")
  expect_true(all(c("parameter", "bi_low", "bi_base", "bi_high", "range") %in%
                    names(dsa)))
})

test_that("DSA results are sorted by range descending", {
  model <- .make_minimal_model()
  spec  <- bim_sensitivity_spec(
    prevalence_range           = c(0.005, 0.015),
    drug_cost_multiplier_range = c(0.70, 1.30)
  )
  dsa <- bim_run_dsa(model, spec)
  expect_true(all(diff(dsa$range) <= 0))
})

# ── Results / table tests ─────────────────────────────────────────────────────

test_that("bim_extract returns data.frame for annual level", {
  model <- .make_minimal_model()
  out   <- bim_extract(model, level = "annual")
  expect_true(is.data.frame(out))
  expect_true("budget_impact" %in% names(out))
})

test_that("bim_extract returns data.frame for cumulative level", {
  model <- .make_minimal_model()
  out   <- bim_extract(model, level = "cumulative")
  expect_true(is.data.frame(out))
  expect_true("cumulative_total" %in% names(out))
})

test_that("bim_table returns data.frame or list", {
  model <- .make_minimal_model()
  tab   <- bim_table(model, format = "annual")
  expect_true(is.data.frame(tab))
  both  <- bim_table(model, format = "both")
  expect_true(is.list(both))
})

# ── Report tests ──────────────────────────────────────────────────────────────

test_that("bim_report returns character vector when output_file is NULL", {
  model <- .make_minimal_model()
  rpt   <- bim_report(model)
  expect_true(is.character(rpt))
  expect_true(length(rpt) > 10L)
})

test_that("bim_report writes text file", {
  model <- .make_minimal_model()
  tmp   <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp), add = TRUE)
  bim_report(model, output_file = tmp, format = "text")
  expect_true(file.exists(tmp))
  expect_gt(file.size(tmp), 0L)
})

# ── Plot tests (non-interactive, just ensure no errors) ───────────────────────

test_that("plot.bim_model line type runs without error", {
  model <- .make_minimal_model()
  expect_silent({
    grDevices::pdf(file = tempfile())
    plot(model, type = "line")
    grDevices::dev.off()
  })
})

test_that("plot.bim_model bar type runs without error", {
  model <- .make_minimal_model()
  expect_silent({
    grDevices::pdf(file = tempfile())
    plot(model, type = "bar")
    grDevices::dev.off()
  })
})

test_that("bim_plot_shares runs without error", {
  model <- .make_minimal_model()
  expect_silent({
    grDevices::pdf(file = tempfile())
    bim_plot_shares(model)
    grDevices::dev.off()
  })
})

test_that("bim_plot_tornado runs without error", {
  model <- .make_minimal_model()
  spec  <- bim_sensitivity_spec(
    prevalence_range           = c(0.005, 0.015),
    drug_cost_multiplier_range = c(0.85, 1.15)
  )
  dsa <- bim_run_dsa(model, spec)
  expect_silent({
    grDevices::pdf(file = tempfile())
    bim_plot_tornado(dsa)
    grDevices::dev.off()
  })
})

# ── Example dataset ───────────────────────────────────────────────────────────

test_that("bim_example dataset loads and rebuilds model", {
  data("bim_example", package = "htaBIM")
  pop   <- do.call(bim_population, bim_example$population_params)
  ms    <- do.call(bim_market_share,
                   c(list(population = pop), bim_example$market_share_params))
  costs <- do.call(bim_costs, bim_example$cost_params)
  model <- bim_model(pop, ms, costs)
  expect_s3_class(model, "bim_model")
  ann   <- model$results$annual
  expect_true(all(ann$budget_impact[ann$scenario == "base"] > 0))
})
