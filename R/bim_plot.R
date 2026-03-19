# bim_plot.R -- Visualisation functions for budget impact models
# Part of htaBIM package
# Uses base R graphics (grDevices, graphics) for CRAN compliance with no
# hard dependency on ggplot2.

#' Plot a budget impact model
#'
#' @description
#' Dispatcher for the various `htaBIM` plot types. Calls the appropriate
#' plotting function based on the `type` argument.
#'
#' @param x A `bim_model` object.
#' @param type `character(1)`. Plot type:
#'   * `"line"` -- annual budget impact over time (default).
#'   * `"bar"` -- grouped bar chart by year and scenario.
#'   * `"tornado"` -- DSA tornado diagram (requires `dsa` argument).
#'   * `"shares"` -- market share stacked bar chart.
#' @param ... Additional arguments passed to the specific plot function.
#' @return Called for side effects (plot). Returns `x` invisibly.
#'
#' @examples
#' pop <- bim_population(
#'   indication    = "IgA Nephropathy",
#'   country       = "GB",
#'   years         = 1:5,
#'   prevalence    = 0.003,
#'   n_total_pop   = 42e6,
#'   eligible_rate = 0.30
#' )
#' ms <- bim_market_share(
#'   population     = pop,
#'   treatments     = c("RASi", "Sparsentan", "Sibeprenlimab"),
#'   new_drug       = "Sibeprenlimab",
#'   shares_current = c(RASi = 0.75, Sparsentan = 0.25, Sibeprenlimab = 0.00),
#'   shares_new     = c(RASi = 0.60, Sparsentan = 0.20, Sibeprenlimab = 0.20)
#' )
#' costs <- bim_costs(
#'   treatments = c("RASi", "Sparsentan", "Sibeprenlimab"),
#'   drug_costs = c(RASi = 200, Sparsentan = 22000, Sibeprenlimab = 28500)
#' )
#' model <- bim_model(pop, ms, costs)
#' plot(model, type = "line")
#' plot(model, type = "bar")
#' plot(model, type = "shares")
#'
#' @seealso [bim_plot_line()], [bim_plot_bar()], [bim_plot_tornado()],
#'   [bim_plot_shares()]
#' @export
plot.bim_model <- function(x, type = c("line", "bar", "tornado", "shares"), ...) {
  type <- match.arg(type)
  switch(type,
    line    = bim_plot_line(x, ...),
    bar     = bim_plot_bar(x, ...),
    tornado = bim_plot_tornado(x, ...),
    shares  = bim_plot_shares(x, ...)
  )
  invisible(x)
}

#' Line plot of annual budget impact over time
#'
#' @description
#' Plots the annual budget impact (or cumulative budget impact) over the
#' projection horizon, with one line per scenario.
#'
#' @param model A `bim_model` object.
#' @param cumulative `logical(1)`. If `TRUE`, plot cumulative impact.
#'   Default `FALSE`.
#' @param scenario `character`. Scenarios to plot. Default `"base"`.
#' @param currency_millions `logical(1)`. Express values in millions.
#'   Default `TRUE`.
#' @param colours Named `character` vector. Line colours by scenario name.
#'   Defaults use the `htaBIM` colour palette.
#' @param title `character(1)` or `NULL`. Plot title.
#'
#' @return Called for side effects (plot). Returns invisibly.
#' @export
bim_plot_line <- function(
    model,
    cumulative        = FALSE,
    scenario          = "base",
    currency_millions = TRUE,
    colours           = NULL,
    title             = NULL
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  ann  <- model$results$annual
  sc   <- intersect(scenario, model$meta$scenarios)
  if (length(sc) == 0L) sc <- model$meta$scenarios[1L]
  ann  <- ann[ann$scenario %in% sc, , drop = FALSE]

  y_vals <- if (cumulative) {
    # Compute cumulative per scenario
    y_list <- lapply(sc, function(s) {
      a <- ann[ann$scenario == s, , drop = FALSE]
      cumsum(a$budget_impact)
    })
    unlist(y_list)
  } else {
    ann$budget_impact
  }

  divisor <- if (currency_millions) 1e6 else 1
  y_label <- if (currency_millions) {
    sprintf("Budget impact (%s millions)", model$meta$currency)
  } else {
    sprintf("Budget impact (%s)", model$meta$currency)
  }

  pal <- .bim_palette(length(sc))
  if (!is.null(colours)) pal[seq_along(colours)] <- colours

  plot_title <- title %||%
    sprintf("%s -- %s budget impact",
            model$meta$new_drug,
            if (cumulative) "cumulative" else "annual")

  years <- model$meta$years
  y_range <- range(y_vals / divisor, na.rm = TRUE)
  if (diff(y_range) == 0) y_range <- y_range + c(-1, 1)

  graphics::plot(
    x    = years,
    y    = rep(NA, length(years)),
    type = "n",
    xlab = "Year",
    ylab = y_label,
    main = plot_title,
    ylim = y_range,
    xaxt = "n"
  )
  graphics::axis(1, at = years, labels = years)
  graphics::abline(h = 0, col = "grey80", lty = 2)
  graphics::grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

  for (i in seq_along(sc)) {
    s <- sc[i]
    a <- ann[ann$scenario == s, , drop = FALSE]
    yv <- if (cumulative) cumsum(a$budget_impact) else a$budget_impact
    graphics::lines(a$year, yv / divisor, col = pal[i], lwd = 2)
    graphics::points(a$year, yv / divisor, col = pal[i], pch = 19, cex = 0.8)
  }

  if (length(sc) > 1L)
    graphics::legend("topleft", legend = sc, col = pal, lwd = 2,
                     lty = 1, bty = "n", cex = 0.85)
  invisible(model)
}

#' Grouped bar chart of annual budget impact by year
#'
#' @description
#' Displays the annual budget impact as grouped bars, with one group per year
#' and one bar per scenario.
#'
#' @param model A `bim_model` object.
#' @param currency_millions `logical(1)`. Default `TRUE`.
#' @param colours `character` or `NULL`. Bar colours per scenario.
#' @param title `character(1)` or `NULL`.
#'
#' @return Called for side effects. Returns invisibly.
#' @export
bim_plot_bar <- function(
    model,
    currency_millions = TRUE,
    colours           = NULL,
    title             = NULL
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  ann      <- model$results$annual
  years    <- model$meta$years
  scenarios <- model$meta$scenarios
  divisor  <- if (currency_millions) 1e6 else 1

  mat <- matrix(0, nrow = length(scenarios), ncol = length(years),
                dimnames = list(scenarios, as.character(years)))
  for (s in scenarios) {
    for (yr in years) {
      v <- ann$budget_impact[ann$scenario == s & ann$year == yr]
      if (length(v) > 0L) mat[s, as.character(yr)] <- v[1L]
    }
  }

  pal <- .bim_palette(length(scenarios))
  if (!is.null(colours)) pal[seq_along(colours)] <- colours

  y_label <- if (currency_millions)
    sprintf("Budget impact (%s millions)", model$meta$currency)
  else
    sprintf("Budget impact (%s)", model$meta$currency)

  plot_title <- title %||%
    sprintf("%s -- annual budget impact by scenario", model$meta$new_drug)

  graphics::barplot(
    mat / divisor,
    beside  = TRUE,
    col     = pal,
    xlab    = "Year",
    ylab    = y_label,
    main    = plot_title,
    legend  = length(scenarios) > 1L,
    args.legend = list(bty = "n", cex = 0.85)
  )
  graphics::abline(h = 0, col = "grey60")
  invisible(model)
}

#' Tornado diagram for DSA results
#'
#' @description
#' Draws a horizontal tornado plot from the output of [bim_run_dsa()],
#' showing the range of budget impact for each parameter varied.
#'
#' @param dsa A `bim_dsa` data frame from [bim_run_dsa()].
#' @param top_n `integer(1)`. Maximum number of parameters to show.
#'   Default `10L`.
#' @param currency `character(1)`. Currency label for x-axis.
#'   Default `"GBP"`.
#' @param currency_millions `logical(1)`. Default `TRUE`.
#' @param title `character(1)` or `NULL`. Plot title.
#' @param col_low `character(1)`. Bar colour for low values. Default blue.
#' @param col_high `character(1)`. Bar colour for high values. Default red.
#'
#' @return Called for side effects. Returns invisibly.
#' @export
bim_plot_tornado <- function(
    dsa,
    top_n             = 10L,
    currency          = "GBP",
    currency_millions = TRUE,
    title             = NULL,
    col_low           = "#2171B5",
    col_high          = "#CB181D"
) {
  if (!inherits(dsa, "bim_dsa"))
    stop("'dsa' must be a bim_dsa object from bim_run_dsa().", call. = FALSE)

  top_n   <- min(top_n, nrow(dsa))
  d       <- dsa[seq_len(top_n), , drop = FALSE]
  divisor <- if (currency_millions) 1e6 else 1
  base    <- d$bi_base[1L] / divisor

  lo <- d$bi_low  / divisor - base
  hi <- d$bi_high / divisor - base

  x_rng <- range(c(lo, hi, 0), na.rm = TRUE)
  buf   <- diff(x_rng) * 0.15
  x_rng <- x_rng + c(-buf, buf)

  y_pos <- rev(seq_len(top_n))
  labs  <- rev(d$label)

  x_lab <- if (currency_millions)
    sprintf("Change in budget impact vs base (%s millions)", currency)
  else
    sprintf("Change in budget impact vs base (%s)", currency)

  plot_title <- title %||% "Deterministic sensitivity analysis -- tornado plot"

  old_mar <- graphics::par("mar")
  on.exit(graphics::par(mar = old_mar), add = TRUE)
  max_lab <- max(nchar(labs))
  graphics::par(mar = c(5, pmax(4, max_lab * 0.5), 4, 2))

  graphics::plot(
    x    = c(0, 0),
    y    = c(0.5, top_n + 0.5),
    type = "n",
    xlim = x_rng,
    ylim = c(0.5, top_n + 0.5),
    xlab = x_lab,
    ylab = "",
    main = plot_title,
    yaxt = "n"
  )
  graphics::axis(2, at = y_pos, labels = labs, las = 1, cex.axis = 0.8)
  graphics::abline(v = 0, col = "grey60", lwd = 1.5)
  graphics::grid(nx = NULL, ny = NA, col = "grey92", lty = 1)

  half_h <- 0.35
  for (i in seq_len(top_n)) {
    y <- y_pos[i]
    l_val <- if (is.na(rev(lo)[i])) 0 else rev(lo)[i]
    h_val <- if (is.na(rev(hi)[i])) 0 else rev(hi)[i]

    graphics::rect(pmin(l_val, 0), y - half_h, 0, y + half_h,
                   col = col_low, border = NA)
    graphics::rect(0, y - half_h, pmax(h_val, 0), y + half_h,
                   col = col_high, border = NA)
  }

  graphics::legend("topright",
                   legend = c("Low parameter value", "High parameter value"),
                   fill   = c(col_low, col_high),
                   bty    = "n", cex = 0.8)
  invisible(dsa)
}

#' Market share stacked bar chart
#'
#' @description
#' Displays market shares as stacked bars -- one panel for the current scenario
#' (without new drug) and one for the new drug scenario -- across years.
#'
#' @param model A `bim_model` object.
#' @param scenario `character(1)`. New drug scenario. Default `"base"`.
#' @param colours `character` or `NULL`. Named vector of colours by treatment.
#' @param title `character(1)` or `NULL`. Plot title.
#'
#' @return Called for side effects. Returns invisibly.
#' @export
bim_plot_shares <- function(
    model,
    scenario = "base",
    colours  = NULL,
    title    = NULL
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  ms_df   <- model$market_share$shares
  treats  <- model$market_share$meta$treatments
  years   <- model$meta$years
  pal     <- .bim_palette(length(treats))
  if (!is.null(colours)) pal[seq_along(colours)] <- colours
  names(pal) <- treats

  plot_title <- title %||%
    sprintf("%s -- market share evolution", model$meta$new_drug)

  old_par <- graphics::par(mfrow = c(1L, 2L), mar = c(5, 4, 3, 1))
  on.exit(graphics::par(old_par), add = TRUE)

  .draw_share_panel <- function(sc, panel_title) {
    sub_df <- ms_df[ms_df$scenario == sc, , drop = FALSE]
    mat    <- matrix(0, nrow = length(treats), ncol = length(years),
                     dimnames = list(treats, as.character(years)))
    for (t in treats) {
      for (yr in years) {
        v <- sub_df$share[sub_df$treatment == t & sub_df$year == yr]
        if (length(v) > 0L) mat[t, as.character(yr)] <- v[1L]
      }
    }
    graphics::barplot(
      mat * 100,
      col   = pal[treats],
      ylim  = c(0, 100),
      xlab  = "Year",
      ylab  = "Market share (%)",
      main  = panel_title,
      names.arg = years
    )
  }

  .draw_share_panel("current", "Without new drug")
  .draw_share_panel(scenario, "With new drug")

  graphics::mtext(plot_title, outer = TRUE, cex = 1, line = -1.5)

  graphics::legend(
    x      = "topright",
    legend = treats,
    fill   = pal[treats],
    bty    = "n",
    cex    = 0.75
  )
  invisible(model)
}

# Colour palette -- 8-colour accessible ramp

#' @noRd
.bim_palette <- function(n) {
  pal <- c("#2166AC", "#D6604D", "#4DAC26", "#8073AC",
           "#E08214", "#1B7837", "#762A83", "#BF812D")
  rep_len(pal, n)
}
