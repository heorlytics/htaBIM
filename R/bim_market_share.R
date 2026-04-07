# bim_market_share.R -- Market share modelling for BIM
# Part of htaBIM package

#' Specify treatment market shares for a budget impact model
#'
#' @description
#' Defines how treatment market shares evolve over time, both in the current
#' scenario (without the new drug) and in the new scenario (with the new drug
#' introduced). Supports constant, linear ramp, logistic S-curve, and step
#' uptake dynamics.
#'
#' @param population A `bim_population` object from [bim_population()].
#' @param treatments `character`. Vector of all treatment names, including the
#'   new drug.
#' @param new_drug `character(1)`. Name of the new intervention. Must be an
#'   element of `treatments`.
#' @param shares_current Named `numeric` vector. Market shares in the current
#'   scenario (without the new drug). Values must sum to 1 and all be in
#'   `[0, 1]`. Names must match `treatments`.
#' @param shares_new Named `numeric` vector. Market shares in the new scenario
#'   (with the new drug at full uptake). Values must sum to 1. Names must match
#'   `treatments`.
#' @param dynamics `character(1)`. How the new drug's uptake evolves:
#'   * `"constant"` -- `shares_new` apply uniformly in all years (default).
#'   * `"linear"` -- new drug ramps linearly from 0 to target share over
#'     `uptake_params$ramp_years` years.
#'   * `"logistic"` -- S-curve uptake. Requires `uptake_params$year_50pct` and
#'     optionally `uptake_params$steepness`.
#'   * `"step"` -- shares_new is a named list with one vector per year.
#' @param uptake_params `list` or `NULL`. Parameters controlling uptake dynamics:
#'   * For `"linear"`: `list(ramp_years = 3)`.
#'   * For `"logistic"`: `list(year_50pct = 2, steepness = 2)`.
#' @param scenarios Named `list` or `NULL`. Alternative market share vectors
#'   (named numerics, same structure as `shares_new`) for scenario analysis.
#'   E.g. `list(conservative = c(...), optimistic = c(...))`.
#'
#' @return An object of class `bim_market_share`, a list containing:
#' \describe{
#'   \item{`shares`}{A `data.frame` with columns `year`, `treatment`,
#'     `scenario`, `share`, `n_patients`.}
#'   \item{`params`}{List of input parameters.}
#'   \item{`meta`}{List with `treatments`, `new_drug`, `dynamics`.}
#' }
#'
#' @examples
#' pop <- bim_population(
#'   indication  = "Disease X",
#'   country     = "GB",
#'   years       = 1:5,
#'   prevalence  = 0.003,
#'   n_total_pop = 42e6,
#'   eligible_rate = 0.30
#' )
#'
#' ms <- bim_market_share(
#'   population     = pop,
#'   treatments     = c("RASi", "Sparsentan", "Sibeprenlimab"),
#'   new_drug       = "Sibeprenlimab",
#'   shares_current = c(RASi = 0.75, Sparsentan = 0.25, Sibeprenlimab = 0.00),
#'   shares_new     = c(RASi = 0.60, Sparsentan = 0.20, Sibeprenlimab = 0.20),
#'   dynamics       = "linear",
#'   uptake_params  = list(ramp_years = 3)
#' )
#' print(ms)
#'
#' @seealso [bim_population()], [bim_model()]
#' @export
bim_market_share <- function(
    population,
    treatments,
    new_drug,
    shares_current,
    shares_new,
    dynamics       = c("constant", "linear", "logistic", "step"),
    uptake_params  = NULL,
    scenarios      = NULL
) {
  if (!inherits(population, "bim_population"))
    stop("'population' must be a bim_population object.", call. = FALSE)
  dynamics <- match.arg(dynamics)
  years    <- population$annual$year

  # ?????? Validate treatments ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  if (!is.character(treatments) || length(treatments) < 2L)
    stop("'treatments' must be a character vector with at least 2 elements.",
         call. = FALSE)
  if (!new_drug %in% treatments)
    stop(sprintf("'new_drug' ('%s') must be an element of 'treatments'.",
                 new_drug), call. = FALSE)

  .validate_shares <- function(s, label) {
    if (!is.numeric(s) || is.null(names(s)))
      stop(sprintf("'%s' must be a named numeric vector.", label), call. = FALSE)
    missing_t <- setdiff(treatments, names(s))
    if (length(missing_t) > 0)
      stop(sprintf("'%s' is missing treatments: %s",
                   label, paste(missing_t, collapse = ", ")), call. = FALSE)
    s <- s[treatments]
    if (abs(sum(s) - 1) > 1e-6)
      stop(sprintf("'%s' must sum to 1 (got %.4f).", label, sum(s)),
           call. = FALSE)
    if (any(s < 0))
      stop(sprintf("All values in '%s' must be >= 0.", label), call. = FALSE)
    s
  }

  shares_current <- .validate_shares(shares_current, "shares_current")
  shares_new     <- .validate_shares(shares_new, "shares_new")

  if (shares_current[new_drug] != 0)
    warning(sprintf(
      "shares_current['%s'] = %.3f but new_drug should have 0 share currently.",
      new_drug, shares_current[new_drug]
    ), call. = FALSE)

  # ?????? Build uptake multiplier per year ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  n_years  <- length(years)
  uptake_f <- .build_uptake(dynamics, n_years, uptake_params)

  # ?????? Expand shares into data.frame ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  all_scenarios <- c(list(base = shares_new), if (!is.null(scenarios)) scenarios)

  results <- vector("list", length(all_scenarios) + 1L)
  idx <- 1L

  # Current scenario (without new drug)
  results[[idx]] <- .expand_shares(
    years        = years,
    shares_fixed = shares_current,
    shares_new   = NULL,
    new_drug     = new_drug,
    uptake_f     = rep(0, n_years),
    n_eligible   = population$annual$n_eligible,
    scenario     = "current"
  )
  idx <- idx + 1L

  # New + scenario variants
  for (sc_name in names(all_scenarios)) {
    sc_shares <- .validate_shares(all_scenarios[[sc_name]], sc_name)
    results[[idx]] <- .expand_shares(
      years        = years,
      shares_fixed = shares_current,
      shares_new   = sc_shares,
      new_drug     = new_drug,
      uptake_f     = uptake_f,
      n_eligible   = population$annual$n_eligible,
      scenario     = sc_name
    )
    idx <- idx + 1L
  }

  shares_df <- do.call(rbind, results[seq_len(idx - 1L)])
  rownames(shares_df) <- NULL

  structure(
    list(
      shares = shares_df,
      params = list(
        treatments    = treatments,
        new_drug      = new_drug,
        shares_current = shares_current,
        shares_new    = shares_new,
        dynamics      = dynamics,
        uptake_params = uptake_params,
        scenarios     = scenarios
      ),
      meta = list(
        treatments = treatments,
        new_drug   = new_drug,
        dynamics   = dynamics,
        years      = years,
        scenarios  = c("current", names(all_scenarios))
      )
    ),
    class = "bim_market_share"
  )
}

# ?????? Internal helpers ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

#' @noRd
.build_uptake <- function(dynamics, n_years, uptake_params) {
  switch(dynamics,
    constant = rep(1, n_years),
    linear = {
      ramp <- uptake_params$ramp_years %||% n_years
      pmin(seq_len(n_years) / ramp, 1)
    },
    logistic = {
      mid   <- uptake_params$year_50pct %||% ceiling(n_years / 2)
      steep <- uptake_params$steepness  %||% 2
      1 / (1 + exp(-steep * (seq_len(n_years) - mid)))
    },
    step = rep(1, n_years)   # handled separately if shares_new is a list
  )
}

#' @noRd
.expand_shares <- function(years, shares_fixed, shares_new, new_drug,
                           uptake_f, n_eligible, scenario) {
  n_years    <- length(years)
  treatments <- names(shares_fixed)
  n_treat    <- length(treatments)

  rows <- vector("list", n_years * n_treat)
  k    <- 1L
  for (i in seq_len(n_years)) {
    if (is.null(shares_new)) {
      # Current scenario
      sh_yr <- shares_fixed
    } else {
      # Blend from current to new via uptake factor
      f     <- uptake_f[i]
      sh_yr <- shares_fixed + f * (shares_new - shares_fixed)
      sh_yr <- pmax(sh_yr, 0)
      sh_yr <- sh_yr / sum(sh_yr)   # renormalise
    }
    for (t in treatments) {
      rows[[k]] <- data.frame(
        year        = years[i],
        treatment   = t,
        scenario    = scenario,
        share       = sh_yr[[t]],
        n_patients  = round(n_eligible[i] * sh_yr[[t]]),
        stringsAsFactors = FALSE
      )
      k <- k + 1L
    }
  }
  do.call(rbind, rows)
}

# ?????? S3 methods ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

#' Print method for bim_market_share
#' @param x A `bim_market_share` object.
#' @param ... Further arguments (ignored).
#' @return Invisibly returns \code{x}. Called for its side effect of printing a
#'   formatted summary of the market share inputs to the console.
#' @export
print.bim_market_share <- function(x, ...) {
  cat("\n-- htaBIM Market Share --\n\n")
  cat("Treatments :", paste(x$meta$treatments, collapse = ", "), "\n")
  cat("New drug   :", x$meta$new_drug, "\n")
  cat("Dynamics   :", x$meta$dynamics, "\n")
  cat("Scenarios  :", paste(x$meta$scenarios, collapse = ", "), "\n\n")

  base_new <- x$shares[x$shares$scenario == "base", , drop = FALSE]
  if (nrow(base_new) == 0L)
    base_new <- x$shares[x$shares$scenario == x$meta$scenarios[2L], , drop = FALSE]

  cat("Year 1 shares (base, with new drug):\n")
  yr1 <- base_new[base_new$year == min(x$meta$years), , drop = FALSE]
  for (i in seq_len(nrow(yr1)))
    cat(sprintf("  %-25s : %.1f%%\n", yr1$treatment[i], yr1$share[i] * 100))
  invisible(x)
}
