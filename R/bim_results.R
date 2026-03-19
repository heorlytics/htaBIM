# bim_results.R -- Results extraction and table generation
# Part of htaBIM package

#' Extract tidy results from a budget impact model
#'
#' @description
#' Returns a tidy `data.frame` of budget impact results from a [bim_model()]
#' object, optionally filtered to a specific level of aggregation.
#'
#' @param model A `bim_model` object.
#' @param level `character(1)`. Level of aggregation:
#'   * `"annual"` -- annual budget impact by year and scenario (default).
#'   * `"cumulative"` -- cumulative totals by scenario.
#' @param scenario `character` or `"all"`. Scenarios to include.
#'   Default `"all"`.
#'
#' @return A `data.frame`.
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
#' bim_extract(model, level = "annual")
#' bim_extract(model, level = "cumulative")
#'
#' @export
bim_extract <- function(model,
                         level    = c("annual", "cumulative"),
                         scenario = "all") {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)
  level <- match.arg(level)

  df <- switch(level,
    annual     = model$results$annual,
    cumulative = model$results$cumulative
  )

  if (!identical(scenario, "all")) {
    df <- df[df$scenario %in% scenario, , drop = FALSE]
  }
  df
}

#' Generate a formatted budget impact summary table
#'
#' @description
#' Produces a formatted HTML or plain-text summary table of annual and/or
#' cumulative budget impact, suitable for inclusion in RMarkdown reports or
#' HTA dossiers.
#'
#' @param model A `bim_model` object.
#' @param format `character(1)`. Table format: `"annual"`, `"cumulative"`,
#'   or `"both"`. Default `"both"`.
#' @param scenario `character(1)`. Scenario to display. Default `"base"`.
#' @param digits `integer(1)`. Rounding digits. Default `0`.
#' @param caption `character(1)` or `NULL`. Table caption.
#' @param footnote `character(1)` or `NULL`. Table footnote.
#'
#' @return A `data.frame` formatted for display.
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
#' tab <- bim_table(model)
#' print(tab)
#'
#' @export
bim_table <- function(
    model,
    format   = c("both", "annual", "cumulative"),
    scenario = "base",
    digits   = 0L,
    caption  = NULL,
    footnote = NULL
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)
  format   <- match.arg(format)
  cur      <- model$meta$currency

  .fmt <- function(x) {
    paste(cur, format(round(x, digits), big.mark = ",", nsmall = digits))
  }
  .pct <- function(x) sprintf("%.1f%%", x)

  ann <- model$results$annual
  sc  <- ann[ann$scenario == scenario, , drop = FALSE]
  if (nrow(sc) == 0L)
    stop(sprintf("Scenario '%s' not found.", scenario), call. = FALSE)

  annual_tab <- data.frame(
    Year                 = sc$year,
    "Budget (current)"   = .fmt(sc$budget_current),
    "Budget (with drug)" = .fmt(sc$budget_new),
    "Budget impact"      = .fmt(sc$budget_impact),
    "Impact (%)"         = .pct(sc$budget_impact_pct),
    "Eligible patients"  = format(sc$n_eligible, big.mark = ","),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  cum <- model$results$cumulative
  sc_cum <- cum[cum$scenario == scenario, , drop = FALSE]
  yr_cols <- grep("^cum_yr", names(sc_cum), value = TRUE)
  cum_tab <- data.frame(
    Metric = c(sprintf("Cumulative impact (Year %s)",
                       gsub("cum_yr", "", yr_cols)),
               "Total cumulative"),
    Value  = c(
      sapply(yr_cols, function(col) .fmt(sc_cum[[col]])),
      .fmt(sc_cum$cumulative_total)
    ),
    stringsAsFactors = FALSE
  )

  out <- switch(format,
    annual     = annual_tab,
    cumulative = cum_tab,
    both       = list(annual = annual_tab, cumulative = cum_tab)
  )

  if (!is.null(caption)) attr(out, "caption") <- caption
  if (!is.null(footnote)) attr(out, "footnote") <- footnote
  out
}
