# bim_model.R -- Core model assembly and budget impact computation
# Part of htaBIM package

#' Assemble and run a budget impact model
#'
#' @description
#' Combines a [bim_population()], [bim_market_share()], and [bim_costs()]
#' object into a complete budget impact model and computes the annual and
#' cumulative budget impact across all scenarios.
#'
#' The budget impact for year *t* is defined as:
#'
#' \deqn{BI_t = \sum_i N_t \cdot s_i^{new}(t) \cdot c_i(t)
#'             - \sum_i N_t \cdot s_i^{current}(t) \cdot c_i(t)}
#'
#' where \eqn{N_t} is the number of eligible patients, \eqn{s_i(t)} is the
#' market share of treatment \eqn{i}, and \eqn{c_i(t)} is the cost per patient
#' for treatment \eqn{i}.
#'
#' @param population A `bim_population` object from [bim_population()].
#' @param market_share A `bim_market_share` object from [bim_market_share()].
#' @param costs A `bim_costs` object from [bim_costs()].
#' @param payer A `bim_payer` object from [bim_payer()] or one of the
#'   pre-built payer functions. Default is [bim_payer_default()].
#' @param discount_rate `numeric(1)`. Annual discount rate applied to Year 2+
#'   costs. Per ISPOR guidelines, the base case should be undiscounted
#'   (`0`). Default `0`.
#' @param label `character(1)` or `NULL`. Optional model label for reporting.
#'
#' @return An object of class `bim_model`, a list containing:
#' \describe{
#'   \item{`population`}{The input `bim_population` object.}
#'   \item{`market_share`}{The input `bim_market_share` object.}
#'   \item{`costs`}{The input `bim_costs` object.}
#'   \item{`payer`}{The input `bim_payer` object.}
#'   \item{`results`}{A list with `annual` and `cumulative` data frames.}
#'   \item{`meta`}{A list with model metadata.}
#' }
#'
#' @examples
#' pop <- bim_population(
#'   indication    = "Disease X",
#'   country       = "GB",
#'   years         = 1:3,
#'   prevalence    = 0.003,
#'   n_total_pop   = 42e6,
#'   eligible_rate = 0.30
#' )
#'
#' ms <- bim_market_share(
#'   population     = pop,
#'   treatments     = c("RASi", "Sparsentan", "Sibeprenlimab"),
#'   new_drug       = "Sibeprenlimab",
#'   shares_current = c(RASi = 0.75, Sparsentan = 0.25, Sibeprenlimab = 0.00),
#'   shares_new     = c(RASi = 0.60, Sparsentan = 0.20, Sibeprenlimab = 0.20)
#' )
#'
#' costs <- bim_costs(
#'   treatments = c("RASi", "Sparsentan", "Sibeprenlimab"),
#'   drug_costs = c(RASi = 200, Sparsentan = 22000, Sibeprenlimab = 28500)
#' )
#'
#' model <- bim_model(pop, ms, costs, label = "IgAN BIM")
#' summary(model)
#'
#' @seealso [bim_population()], [bim_market_share()], [bim_costs()],
#'   [bim_payer()], [plot.bim_model()], [bim_table()]
#' @export
bim_model <- function(
    population,
    market_share,
    costs,
    payer         = bim_payer_default(),
    discount_rate = 0,
    label         = NULL
) {
  # ?????? Validate ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  if (!inherits(population,   "bim_population"))
    stop("'population' must be a bim_population object.",   call. = FALSE)
  if (!inherits(market_share, "bim_market_share"))
    stop("'market_share' must be a bim_market_share object.", call. = FALSE)
  if (!inherits(costs,        "bim_costs"))
    stop("'costs' must be a bim_costs object.",              call. = FALSE)
  if (!inherits(payer,        "bim_payer"))
    stop("'payer' must be a bim_payer object.",              call. = FALSE)
  if (!is.numeric(discount_rate) || length(discount_rate) != 1L ||
      discount_rate < 0 || discount_rate > 1)
    stop("'discount_rate' must be a numeric in [0, 1].", call. = FALSE)

  # Check treatment consistency
  ms_treats    <- market_share$meta$treatments
  cost_treats  <- costs$meta$treatments
  missing_cost <- setdiff(ms_treats, cost_treats)
  if (length(missing_cost) > 0)
    stop(sprintf(
      "These treatments in market_share are missing from costs: %s",
      paste(missing_cost, collapse = ", ")
    ), call. = FALSE)

  years     <- population$annual$year
  scenarios <- setdiff(market_share$meta$scenarios, "current")
  ms_df     <- market_share$shares
  cost_df   <- costs$total

  # ?????? Compute budget impact ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  annual_list <- vector("list", length(scenarios))
  for (sc_idx in seq_along(scenarios)) {
    sc <- scenarios[sc_idx]

    # Per-year budget impact
    yr_rows <- vector("list", length(years))
    for (yi in seq_along(years)) {
      yr <- years[yi]
      disc <- 1 / ((1 + discount_rate) ^ (yi - 1L))

      ms_curr <- ms_df[ms_df$scenario == "current" & ms_df$year == yr, ]
      ms_new  <- ms_df[ms_df$scenario == sc        & ms_df$year == yr, ]

      tot_curr <- .budget_total(ms_curr, cost_df, yr, payer, disc)
      tot_new  <- .budget_total(ms_new,  cost_df, yr, payer, disc)

      n_elig <- population$annual$n_eligible[yi]

      yr_rows[[yi]] <- data.frame(
        year                   = yr,
        scenario               = sc,
        budget_current         = tot_curr,
        budget_new             = tot_new,
        budget_impact          = tot_new - tot_curr,
        budget_impact_pct      = ifelse(
          tot_curr == 0, NA_real_,
          (tot_new - tot_curr) / tot_curr * 100
        ),
        n_eligible             = n_elig,
        stringsAsFactors       = FALSE
      )
    }
    annual_list[[sc_idx]] <- do.call(rbind, yr_rows)
  }
  annual_df <- do.call(rbind, annual_list)
  rownames(annual_df) <- NULL

  # ?????? Cumulative results ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  cum_rows <- vector("list", length(scenarios))
  for (sc_idx in seq_along(scenarios)) {
    sc       <- scenarios[sc_idx]
    sc_ann   <- annual_df[annual_df$scenario == sc, , drop = FALSE]
    cum_all  <- sum(sc_ann$budget_impact)

    row_vals <- list(scenario = sc, cumulative_total = cum_all)
    for (yr in years) {
      sub_df <- sc_ann[sc_ann$year <= yr, , drop = FALSE]
      row_vals[[paste0("cum_yr", yr)]] <- sum(sub_df$budget_impact)
    }
    cum_rows[[sc_idx]] <- as.data.frame(row_vals, stringsAsFactors = FALSE)
  }
  cumulative_df <- do.call(rbind, cum_rows)
  rownames(cumulative_df) <- NULL

  structure(
    list(
      population   = population,
      market_share = market_share,
      costs        = costs,
      payer        = payer,
      results      = list(
        annual     = annual_df,
        cumulative = cumulative_df
      ),
      meta = list(
        label         = label %||% paste0(population$meta$indication, " BIM"),
        indication    = population$meta$indication,
        country       = population$meta$country,
        currency      = costs$meta$currency,
        price_year    = costs$meta$price_year,
        new_drug      = market_share$meta$new_drug,
        years         = years,
        scenarios     = scenarios,
        discount_rate = discount_rate,
        created       = Sys.time()
      )
    ),
    class = "bim_model"
  )
}

# ?????? Internal compute helper ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

#' @noRd
.budget_total <- function(ms_yr, cost_df, yr, payer, disc_factor) {
  total <- 0
  for (i in seq_len(nrow(ms_yr))) {
    trt <- ms_yr$treatment[i]
    n   <- ms_yr$n_patients[i]
    cpp_row <- cost_df[cost_df$treatment == trt & cost_df$year == yr, ]
    cpp <- if (nrow(cpp_row) > 0L) cpp_row$total_cost_per_patient[1L] else 0
    total <- total + n * cpp * payer$cost_coverage * disc_factor
  }
  round(total)
}

# ?????? S3 methods ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

#' Print method for bim_model
#' @param x A `bim_model` object.
#' @param ... Further arguments (ignored).
#' @return Invisibly returns \code{x}. Called for its side effect of printing a
#'   formatted summary of the budget impact model results to the console.
#' @export
print.bim_model <- function(x, ...) {
  cat("\n-- htaBIM Model --\n\n")
  cat("Label      :", x$meta$label, "\n")
  cat("Indication :", x$meta$indication, "\n")
  cat("Country    :", x$meta$country, "\n")
  cat("New drug   :", x$meta$new_drug, "\n")
  cat("Currency   :", x$meta$currency, "\n")
  cat("Years      :", paste(x$meta$years, collapse = ", "), "\n")
  cat("Scenarios  :", paste(x$meta$scenarios, collapse = ", "), "\n")
  cat("\nUse summary() for full results.\n")
  invisible(x)
}

#' Summary method for bim_model
#'
#' @param object A `bim_model` object.
#' @param digits `integer(1)`. Decimal digits for currency amounts. Default `0`.
#' @param ... Further arguments (ignored).
#' @return The `bim_model` object, invisibly.
#' @export
summary.bim_model <- function(object, digits = 0L, ...) {
  m   <- object$meta
  ann <- object$results$annual
  cum <- object$results$cumulative
  cur <- object$costs$meta$currency

  .fmt <- function(x) {
    format(round(x, digits), big.mark = ",", nsmall = digits)
  }

  cat("\n== htaBIM Model Summary ==\n")
  cat(rep("=", 55), "\n", sep = "")
  cat(sprintf("Label      : %s\n", m$label))
  cat(sprintf("Indication : %s\n", m$indication))
  cat(sprintf("Country    : %s\n", m$country))
  cat(sprintf("Currency   : %s (%d prices)\n", m$currency, m$price_year))
  cat(sprintf("New drug   : %s\n", m$new_drug))
  cat(sprintf("Payer      : %s\n", object$payer$name))
  cat(sprintf("Discount   : %.1f%%\n", m$discount_rate * 100))

  for (sc in m$scenarios) {
    sc_ann <- ann[ann$scenario == sc, , drop = FALSE]
    sc_cum <- cum[cum$scenario == sc, , drop = FALSE]

    cat(rep("-", 55), "\n", sep = "")
    cat(sprintf("Scenario: %s\n", toupper(sc)))
    cat(sprintf("%-6s  %-15s  %-15s  %-15s\n",
                "Year", "Budget (curr)", "Budget (new)", "Impact"))
    for (i in seq_len(nrow(sc_ann))) {
      r <- sc_ann[i, ]
      cat(sprintf("%-6d  %s %-11s  %s %-11s  %s %-11s\n",
                  r$year,
                  cur, .fmt(r$budget_current),
                  cur, .fmt(r$budget_new),
                  cur, .fmt(r$budget_impact)))
    }
    cat(sprintf("\nCumulative impact (%d yrs): %s %s\n\n",
                max(m$years), cur, .fmt(sc_cum$cumulative_total)))
  }
  invisible(object)
}
