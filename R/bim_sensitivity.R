# bim_sensitivity.R -- Scenario and sensitivity analysis
# Part of htaBIM package

#' Specify a deterministic sensitivity analysis for a budget impact model
#'
#' @description
#' Defines parameter ranges for a deterministic sensitivity analysis (DSA)
#' on a [bim_model()]. Each parameter is varied individually from its low
#' to high value while all others are held at their base case value.
#'
#' @param prevalence_range `numeric(2)` or `NULL`. Low and high values for
#'   disease prevalence (proportion).
#' @param diagnosed_rate_range `numeric(2)` or `NULL`. Low and high values for
#'   diagnosed rate.
#' @param treated_rate_range `numeric(2)` or `NULL`. Low and high values for
#'   treated rate.
#' @param eligible_rate_range `numeric(2)` or `NULL`. Low and high values for
#'   eligible rate.
#' @param new_drug_share_range `numeric(2)` or `NULL`. Low and high values for
#'   new drug market share (applied uniformly across years).
#' @param drug_cost_multiplier_range `numeric(2)` or `NULL`. Low and high
#'   multipliers applied to the new drug cost (e.g. `c(0.85, 1.15)` for
#'   plus/minus 15%). Default `c(0.85, 1.15)`.
#' @param extra_params Named `list` or `NULL`. Additional parameter ranges as
#'   named elements, each a `list(label, base, low, high)`.
#'
#' @return An object of class `bim_sensitivity_spec`.
#'
#' @examples
#' sens <- bim_sensitivity_spec(
#'   prevalence_range        = c(0.002, 0.005),
#'   eligible_rate_range     = c(0.20, 0.45),
#'   new_drug_share_range    = c(0.10, 0.30),
#'   drug_cost_multiplier_range = c(0.85, 1.15)
#' )
#'
#' @seealso [bim_run_dsa()], [bim_model()]
#' @export
bim_sensitivity_spec <- function(
    prevalence_range           = NULL,
    diagnosed_rate_range       = NULL,
    treated_rate_range         = NULL,
    eligible_rate_range        = NULL,
    new_drug_share_range       = NULL,
    drug_cost_multiplier_range = c(0.85, 1.15),
    extra_params               = NULL
) {
  .range_ok <- function(x, name) {
    if (!is.null(x)) {
      if (!is.numeric(x) || length(x) != 2L || x[1L] >= x[2L])
        stop(sprintf("'%s' must be a numeric vector of length 2 with low < high.",
                     name), call. = FALSE)
    }
  }
  .range_ok(prevalence_range,           "prevalence_range")
  .range_ok(diagnosed_rate_range,       "diagnosed_rate_range")
  .range_ok(treated_rate_range,         "treated_rate_range")
  .range_ok(eligible_rate_range,        "eligible_rate_range")
  .range_ok(new_drug_share_range,       "new_drug_share_range")
  .range_ok(drug_cost_multiplier_range, "drug_cost_multiplier_range")

  params <- list(
    prevalence = if (!is.null(prevalence_range))
      list(label = "Prevalence", low = prevalence_range[1L],
           high = prevalence_range[2L], type = "population"),
    diagnosed_rate = if (!is.null(diagnosed_rate_range))
      list(label = "Diagnosed rate", low = diagnosed_rate_range[1L],
           high = diagnosed_rate_range[2L], type = "population"),
    treated_rate = if (!is.null(treated_rate_range))
      list(label = "Treated rate", low = treated_rate_range[1L],
           high = treated_rate_range[2L], type = "population"),
    eligible_rate = if (!is.null(eligible_rate_range))
      list(label = "Eligible rate", low = eligible_rate_range[1L],
           high = eligible_rate_range[2L], type = "population"),
    new_drug_share = if (!is.null(new_drug_share_range))
      list(label = "New drug market share", low = new_drug_share_range[1L],
           high = new_drug_share_range[2L], type = "market_share"),
    drug_cost_multiplier = if (!is.null(drug_cost_multiplier_range))
      list(label = "New drug cost (multiplier)", low = drug_cost_multiplier_range[1L],
           high = drug_cost_multiplier_range[2L], type = "cost")
  )
  params <- Filter(Negate(is.null), params)
  if (!is.null(extra_params)) params <- c(params, extra_params)

  structure(
    list(params = params),
    class = "bim_sensitivity_spec"
  )
}

#' Run a deterministic sensitivity analysis on a budget impact model
#'
#' @description
#' Executes a one-way deterministic sensitivity analysis (DSA) by varying
#' each parameter in a [bim_sensitivity_spec()] individually across its
#' low/high range while holding all others at their base values.
#'
#' @param model A `bim_model` object.
#' @param sensitivity A `bim_sensitivity_spec` object from
#'   [bim_sensitivity_spec()].
#' @param year `integer(1)`. The projection year on which DSA results are
#'   evaluated. Default is the final year in the model.
#' @param scenario `character(1)`. Which scenario to use as base case.
#'   Default `"base"`.
#'
#' @return A `data.frame` with columns `parameter`, `label`, `low_value`,
#'   `high_value`, `bi_low`, `bi_base`, `bi_high`, `range`, sorted by
#'   `range` descending (largest impact first). Can be passed directly to
#'   [bim_plot_tornado()].
#'
#' @examples
#' pop <- bim_population(
#'   indication    = "Example",
#'   country       = "GB",
#'   years         = 1:3,
#'   prevalence    = 0.003,
#'   n_total_pop   = 42e6,
#'   eligible_rate = 0.30
#' )
#' ms <- bim_market_share(
#'   population     = pop,
#'   treatments     = c("RASi", "NewDrug"),
#'   new_drug       = "NewDrug",
#'   shares_current = c(RASi = 1.0, NewDrug = 0.0),
#'   shares_new     = c(RASi = 0.8, NewDrug = 0.2)
#' )
#' costs <- bim_costs(
#'   treatments = c("RASi", "NewDrug"),
#'   drug_costs = c(RASi = 500, NewDrug = 25000)
#' )
#' model <- bim_model(pop, ms, costs)
#'
#' sens <- bim_sensitivity_spec(
#'   prevalence_range        = c(0.002, 0.005),
#'   eligible_rate_range     = c(0.20, 0.45),
#'   drug_cost_multiplier_range = c(0.85, 1.15)
#' )
#' dsa <- bim_run_dsa(model, sens, year = 3L)
#' print(dsa)
#'
#' @seealso [bim_sensitivity_spec()], [bim_plot_tornado()]
#' @export
bim_run_dsa <- function(model, sensitivity, year = NULL, scenario = "base") {
  if (!inherits(model,       "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)
  if (!inherits(sensitivity, "bim_sensitivity_spec"))
    stop("'sensitivity' must be a bim_sensitivity_spec object.", call. = FALSE)
  if (is.null(year))
    year <- max(model$meta$years)
  year <- as.integer(year)
  if (!year %in% model$meta$years)
    stop(sprintf("'year' (%d) is not in the model's year range.", year),
         call. = FALSE)

  # Base case budget impact for the chosen year and scenario
  bi_base <- .extract_bi(model, year, scenario)

  params  <- sensitivity$params
  results <- vector("list", length(params))

  for (i in seq_along(params)) {
    p      <- params[[i]]
    p_name <- names(params)[i]

    # Rebuild model with low and high parameter values
    bi_low  <- .dsa_vary(model, p_name, p$low,  year, scenario)
    bi_high <- .dsa_vary(model, p_name, p$high, year, scenario)

    results[[i]] <- data.frame(
      parameter  = p_name,
      label      = p$label,
      low_value  = p$low,
      high_value = p$high,
      bi_low     = bi_low,
      bi_base    = bi_base,
      bi_high    = bi_high,
      range      = abs(bi_high - bi_low),
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, results)
  out <- out[order(out$range, decreasing = TRUE), ]
  rownames(out) <- NULL
  class(out)    <- c("bim_dsa", "data.frame")
  out
}

#' @noRd
.extract_bi <- function(model, year, scenario) {
  ann <- model$results$annual
  row <- ann[ann$year == year & ann$scenario == scenario, ]
  if (nrow(row) == 0L)
    stop(sprintf("Scenario '%s' not found in model results.", scenario),
         call. = FALSE)
  row$budget_impact[1L]
}

#' @noRd
.dsa_vary <- function(model, param_name, value, year, scenario) {
  pop  <- model$population
  ms   <- model$market_share
  cost <- model$costs

  if (param_name == "prevalence") {
    pop$params$prevalence <- value
    pop <- do.call(bim_population, pop$params)
  } else if (param_name == "diagnosed_rate") {
    pop$params$diagnosed_rate <- value
    pop <- do.call(bim_population, pop$params)
  } else if (param_name == "treated_rate") {
    pop$params$treated_rate <- value
    pop <- do.call(bim_population, pop$params)
  } else if (param_name == "eligible_rate") {
    pop$params$eligible_rate <- value
    pop <- do.call(bim_population, pop$params)
  } else if (param_name == "new_drug_share") {
    nd <- ms$meta$new_drug
    sn <- ms$params$shares_new
    diff <- value - sn[[nd]]
    # Adjust new drug share; redistribute delta proportionally from others
    others <- setdiff(names(sn), nd)
    total_others <- sum(sn[others])
    sn[[nd]] <- value
    if (total_others > 0) {
      for (o in others)
        sn[[o]] <- sn[[o]] - diff * (sn[[o]] / total_others)
      sn[others] <- pmax(sn[others], 0)
      sn <- sn / sum(sn)
    }
    ms_params           <- ms$params
    ms_params$shares_new <- sn
    ms_params$population <- pop
    ms <- do.call(bim_market_share, ms_params)
  } else if (param_name == "drug_cost_multiplier") {
    nd         <- ms$meta$new_drug
    cost_params <- cost$params
    if (!is.null(cost_params$drug_costs) && nd %in% names(cost_params$drug_costs))
      cost_params$drug_costs[[nd]] <- cost_params$drug_costs[[nd]] * value
    cost <- do.call(bim_costs, cost_params)
  }

  new_model <- suppressMessages(
    bim_model(pop, ms, cost, model$payer, model$meta$discount_rate)
  )
  .extract_bi(new_model, year, scenario)
}

#' Print method for bim_dsa
#' @param x A `bim_dsa` object.
#' @param ... Further arguments (ignored).
#' @return Invisibly returns \code{x}. Called for its side effect of printing a
#'   formatted summary of the deterministic sensitivity analysis results to the
#'   console.
#' @export
print.bim_dsa <- function(x, ...) {
  cat("\n-- htaBIM DSA Results --\n\n")
  cat(sprintf("%-30s  %-12s  %-12s  %-12s\n",
              "Parameter", "BI (low)", "BI (base)", "BI (high)"))
  cat(rep("-", 72), "\n", sep = "")
  for (i in seq_len(nrow(x))) {
    cat(sprintf("%-30s  %-12s  %-12s  %-12s\n",
                x$label[i],
                format(round(x$bi_low[i]),  big.mark = ","),
                format(round(x$bi_base[i]), big.mark = ","),
                format(round(x$bi_high[i]), big.mark = ",")))
  }
  invisible(x)
}
