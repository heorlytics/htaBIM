# bim_scenario_table.R -- Cross-scenario comparison table for htaBIM
# Part of htaBIM package

#' Cross-scenario budget impact comparison table
#'
#' @description
#' Produces a side-by-side summary table of budget impact results across all
#' scenarios in a model, showing Year 1, mid-point, final year, and cumulative
#' totals. This is the standard tabular format for dossier submissions following
#' ISPOR Task Force guidelines.
#'
#' @param model A `bim_model` object.
#' @param years `integer` vector. Years to include as columns. If `NULL`
#'   (default), uses Year 1, the middle year, and the last year.
#' @param currency_millions `logical(1)`. Express values in millions.
#'   Default `TRUE`.
#' @param digits `integer(1)`. Decimal places for formatted values. Default
#'   `2L`.
#'
#' @return A `data.frame` with one row per scenario and columns for each
#'   selected year plus cumulative total, formatted as character strings.
#'   The `data.frame` carries a `"caption"` attribute suitable for passing
#'   to `knitr::kable()`.
#'
#' @examples
#' pop <- bim_population(
#'   indication  = "Disease X", country = "custom",
#'   years = 1:5, prevalence = 0.003, n_total_pop = 42e6,
#'   diagnosed_rate = 0.60, treated_rate = 0.45, eligible_rate = 0.30
#' )
#' ms <- bim_market_share(
#'   population     = pop,
#'   treatments     = c("Drug C (SoC)", "Drug A (new)"),
#'   new_drug       = "Drug A (new)",
#'   shares_current = c("Drug C (SoC)" = 1.0, "Drug A (new)" = 0.0),
#'   shares_new     = c("Drug C (SoC)" = 0.8, "Drug A (new)" = 0.2),
#'   scenarios      = list(
#'     conservative = c("Drug C (SoC)" = 0.9, "Drug A (new)" = 0.1),
#'     optimistic   = c("Drug C (SoC)" = 0.7, "Drug A (new)" = 0.3)
#'   )
#' )
#' costs <- bim_costs(
#'   treatments = c("Drug C (SoC)", "Drug A (new)"),
#'   drug_costs = c("Drug C (SoC)" = 500, "Drug A (new)" = 25000)
#' )
#' model <- bim_model(pop, ms, costs)
#' st <- bim_scenario_table(model)
#' print(st)
#'
#' @seealso [bim_table()], [bim_extract()]
#' @export
bim_scenario_table <- function(
    model,
    years             = NULL,
    currency_millions = TRUE,
    digits            = 2L
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  all_years  <- model$meta$years
  scenarios  <- model$meta$scenarios
  ann        <- model$results$annual
  cum        <- model$results$cumulative
  currency   <- model$meta$currency
  divisor    <- if (currency_millions) 1e6 else 1
  unit_label <- if (currency_millions)
    sprintf("%s millions", currency)
  else
    currency

  # Select columns years
  if (is.null(years)) {
    mid  <- all_years[ceiling(length(all_years) / 2)]
    years <- unique(c(min(all_years), mid, max(all_years)))
  }
  years <- as.integer(years)
  years <- years[years %in% all_years]

  # Build table row by row
  rows <- lapply(scenarios, function(sc) {
    yr_vals <- vapply(years, function(yr) {
      v <- ann$budget_impact[ann$scenario == sc & ann$year == yr]
      if (length(v) == 0L) NA_real_ else v[1L]
    }, numeric(1L))

    cum_v <- cum$cumulative_total[cum$scenario == sc]
    cum_v <- if (length(cum_v) == 0L) NA_real_ else cum_v[1L]

    fmt <- function(x) {
      if (is.na(x)) return("-")
      formatC(round(x / divisor, digits), format = "f", digits = digits,
              big.mark = ",")
    }

    row <- as.list(vapply(yr_vals, fmt, character(1L)))
    names(row) <- paste0("Year_", years)
    row$Cumulative <- fmt(cum_v)
    row$Scenario   <- .fmt_scenario_label(sc)
    as.data.frame(row, stringsAsFactors = FALSE)
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  # Reorder columns: Scenario first
  yr_cols  <- paste0("Year_", years)
  col_nms  <- c("Scenario", yr_cols, "Cumulative")
  out      <- out[, col_nms, drop = FALSE]

  # Rename year columns for display
  names(out)[names(out) %in% yr_cols] <-
    paste0("Year ", years, " (", unit_label, ")")
  names(out)[names(out) == "Cumulative"] <-
    paste0("Cumulative (", unit_label, ")")

  attr(out, "caption") <- sprintf(
    "Budget impact by scenario (%s)", unit_label
  )
  out
}

# Internal: prettify scenario label
.fmt_scenario_label <- function(sc) {
  sc <- gsub("_", " ", sc)
  paste0(toupper(substr(sc, 1, 1)), substr(sc, 2, nchar(sc)))
}
