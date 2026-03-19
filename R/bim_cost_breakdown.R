# bim_cost_breakdown.R -- Cost component breakdown for htaBIM
# Part of htaBIM package

#' Per-patient cost breakdown by component and treatment
#'
#' @description
#' Extracts and formats the per-patient annual cost decomposed by cost
#' category (drug, admin, monitoring, adverse events, other) for each
#' treatment in the model. This supports transparency and helps reviewers
#' understand the drivers of differential costs between treatments.
#'
#' The table is suitable for direct inclusion in HTA dossier appendices.
#'
#' @param model A `bim_model` object.
#' @param year `integer(1)`. Price year to extract costs for. Defaults to
#'   `model$costs$meta$price_year` (base price year, before inflation).
#' @param currency_millions `logical(1)`. Express values in millions.
#'   Default `FALSE` (per-patient costs are typically in whole currency units).
#' @param digits `integer(1)`. Decimal places. Default `0L`.
#'
#' @return A `data.frame` with rows = cost categories and columns =
#'   treatments, plus a **Total** row. Values are formatted character strings.
#'   Carries a `"caption"` attribute.
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
#'   shares_new     = c("Drug C (SoC)" = 0.8, "Drug A (new)" = 0.2)
#' )
#' costs <- bim_costs(
#'   treatments       = c("Drug C (SoC)", "Drug A (new)"),
#'   drug_costs       = c("Drug C (SoC)" = 500,  "Drug A (new)" = 25000),
#'   monitoring_costs = c("Drug C (SoC)" = 200,  "Drug A (new)" = 1500),
#'   ae_costs         = c("Drug C (SoC)" = 50,   "Drug A (new)" = 300)
#' )
#' model <- bim_model(pop, ms, costs)
#' bim_cost_breakdown(model)
#'
#' @seealso [bim_costs()], [bim_costs_drug()], [bim_costs_ae()]
#' @export
bim_cost_breakdown <- function(
    model,
    year              = NULL,
    currency_millions = FALSE,
    digits            = 0L
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  costs_obj  <- model$costs
  treatments <- costs_obj$meta$treatments
  categories <- costs_obj$meta$categories
  currency   <- costs_obj$meta$currency
  divisor    <- if (currency_millions) 1e6 else 1

  year <- year %||% costs_obj$meta$price_year %||% min(model$meta$years)
  year <- as.integer(year)

  # Pull per-patient costs from costs$costs for the requested year
  cost_df <- costs_obj$costs

  # Use the closest available year if exact year not present
  avail_years <- unique(cost_df$year)
  if (!year %in% avail_years) year <- min(avail_years)

  sub <- cost_df[cost_df$year == year, , drop = FALSE]

  fmt <- function(x) {
    if (is.na(x)) return("-")
    formatC(round(x / divisor, digits), format = "f", digits = digits,
            big.mark = ",")
  }

  # Build matrix: rows = categories, cols = treatments
  cat_labels <- c(
    drug       = "Drug cost",
    admin      = "Administration cost",
    monitoring = "Monitoring cost",
    ae         = "Adverse event cost",
    other      = "Other cost"
  )

  rows <- lapply(categories, function(cat) {
    vals <- vapply(treatments, function(t) {
      v <- sub$unit_cost[sub$treatment == t & sub$category == cat]
      if (length(v) == 0L) 0 else v[1L]
    }, numeric(1L))

    row_df <- as.data.frame(
      as.list(vapply(vals, fmt, character(1L))),
      stringsAsFactors = FALSE
    )
    names(row_df) <- treatments
    row_df$`Cost component` <- cat_labels[cat] %||% cat
    row_df
  })

  out <- do.call(rbind, rows)

  # Total row
  totals <- costs_obj$total
  tot_sub <- totals[totals$year == year, , drop = FALSE]
  tot_vals <- vapply(treatments, function(t) {
    v <- tot_sub$total_cost_per_patient[tot_sub$treatment == t]
    if (length(v) == 0L) NA_real_ else v[1L]
  }, numeric(1L))

  tot_row <- as.data.frame(
    as.list(vapply(tot_vals, fmt, character(1L))),
    stringsAsFactors = FALSE
  )
  names(tot_row) <- treatments
  tot_row$`Cost component` <- "Total per patient"
  out <- rbind(out, tot_row)

  # Reorder columns
  out <- out[, c("Cost component", treatments), drop = FALSE]
  rownames(out) <- NULL

  unit_label <- if (currency_millions)
    sprintf("%s millions", currency)
  else
    currency

  attr(out, "caption") <- sprintf(
    "Per-patient annual cost by component (%s, Year %d)",
    unit_label, year
  )
  out
}

#' Plot per-patient cost breakdown as a stacked bar chart
#'
#' @description
#' Draws a stacked horizontal bar chart of per-patient annual costs by cost
#' component, with one bar per treatment. Useful for visually comparing the
#' cost structure across treatments.
#'
#' @param model A `bim_model` object.
#' @param year `integer(1)` or `NULL`. Year to plot. Defaults to first
#'   available year in costs.
#' @param colours Named `character` vector of colours per cost category.
#'   Defaults use the `htaBIM` colour palette.
#' @param title `character(1)` or `NULL`. Plot title.
#'
#' @return Called for side effects. Returns invisibly.
#' @export
bim_plot_cost_breakdown <- function(
    model,
    year    = NULL,
    colours = NULL,
    title   = NULL
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  costs_obj  <- model$costs
  treatments <- costs_obj$meta$treatments
  categories <- costs_obj$meta$categories
  currency   <- costs_obj$meta$currency
  cost_df    <- costs_obj$costs

  avail_years <- unique(cost_df$year)
  year <- as.integer(year %||% min(avail_years))
  if (!year %in% avail_years) year <- min(avail_years)

  sub <- cost_df[cost_df$year == year, , drop = FALSE]

  cat_labels <- c(
    drug       = "Drug",
    admin      = "Administration",
    monitoring = "Monitoring",
    ae         = "Adverse events",
    other      = "Other"
  )

  # Matrix: rows = categories, cols = treatments
  mat <- matrix(0,
                nrow = length(categories),
                ncol = length(treatments),
                dimnames = list(categories, treatments))
  for (cat in categories) {
    for (t in treatments) {
      v <- sub$unit_cost[sub$category == cat & sub$treatment == t]
      if (length(v) > 0L) mat[cat, t] <- v[1L]
    }
  }

  pal <- .bim_palette(length(categories))
  if (!is.null(colours)) pal[seq_along(colours)] <- colours

  row_labs <- vapply(categories, function(c)
    cat_labels[c] %||% c, character(1L))

  plot_title <- title %||%
    sprintf("Per-patient annual cost breakdown (Year %d, %s)", year, currency)

  old_mar <- graphics::par("mar")
  on.exit(graphics::par(mar = old_mar), add = TRUE)
  max_nchar <- max(nchar(treatments))
  graphics::par(mar = c(5, pmax(4, max_nchar * 0.6), 4, 8))

  graphics::barplot(
    mat,
    horiz   = TRUE,
    col     = pal,
    main    = plot_title,
    xlab    = sprintf("Annual cost per patient (%s)", currency),
    las     = 1,
    border  = NA,
    cex.names = 0.85
  )
  graphics::legend(
    x      = "right",
    legend = row_labs,
    fill   = pal,
    bty    = "n",
    cex    = 0.78,
    xpd    = TRUE,
    inset  = c(-0.28, 0)
  )
  invisible(model)
}
