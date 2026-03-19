# bim_psa.R -- Probabilistic Sensitivity Analysis for htaBIM
# Part of htaBIM package

#' Run a probabilistic sensitivity analysis (PSA)
#'
#' @description
#' Performs a Monte Carlo PSA by repeatedly sampling uncertain parameters from
#' their assumed statistical distributions and re-running the budget impact
#' model for each draw. This produces a distribution of budget impact outcomes
#' that reflects joint parameter uncertainty.
#'
#' **Distributional assumptions**
#' \itemize{
#'   \item Prevalence, diagnosed rate, treated rate, eligible rate — **Beta**
#'     distribution parameterised from the base-case value and a standard error.
#'   \item Drug cost — **LogNormal** distribution parameterised from the
#'     base-case value and a coefficient of variation (CV).
#' }
#'
#' @param model A `bim_model` object (base case).
#' @param n_sim `integer(1)`. Number of Monte Carlo simulations. Default
#'   `1000L`.
#' @param prevalence_se `numeric(1)`. Standard error for prevalence. If `NULL`
#'   (default), prevalence is held fixed.
#' @param diagnosed_rate_se `numeric(1)` or `NULL`. SE for diagnosed rate.
#' @param treated_rate_se `numeric(1)` or `NULL`. SE for treated rate.
#' @param eligible_rate_se `numeric(1)` or `NULL`. SE for eligible rate.
#' @param cost_cv `numeric(1)` or `NULL`. Coefficient of variation applied to
#'   all drug costs simultaneously. If `NULL`, costs are held fixed.
#' @param year `integer(1)`. Budget impact year to summarise. Defaults to the
#'   last year in the model.
#' @param scenario `character(1)`. Scenario to use. Default `"base"`.
#' @param seed `integer(1)` or `NULL`. Random seed for reproducibility.
#'
#' @return An object of class `bim_psa`: a list with elements:
#' \describe{
#'   \item{`simulations`}{`data.frame` with one row per simulation:
#'     `sim`, `budget_impact`, and the sampled parameter values.}
#'   \item{`summary`}{`data.frame` with mean, SD, median, and 95 \% credible
#'     interval of budget impact.}
#'   \item{`year`}{The year summarised.}
#'   \item{`scenario`}{The scenario used.}
#'   \item{`n_sim`}{Number of simulations run.}
#'   \item{`base_bi`}{Base-case budget impact for reference.}
#' }
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
#'   treatments = c("Drug C (SoC)", "Drug A (new)"),
#'   drug_costs = c("Drug C (SoC)" = 500, "Drug A (new)" = 25000)
#' )
#' model <- bim_model(pop, ms, costs)
#' set.seed(1)
#' psa <- bim_run_psa(model, n_sim = 200L, prevalence_se = 0.0005,
#'                    eligible_rate_se = 0.05, cost_cv = 0.10)
#' print(psa)
#'
#' @seealso [bim_plot_psa()], [bim_run_dsa()]
#' @export
bim_run_psa <- function(
    model,
    n_sim            = 1000L,
    prevalence_se    = NULL,
    diagnosed_rate_se = NULL,
    treated_rate_se  = NULL,
    eligible_rate_se = NULL,
    cost_cv          = NULL,
    year             = NULL,
    scenario         = "base",
    seed             = NULL
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)

  n_sim <- as.integer(n_sim)
  if (n_sim < 10L) stop("'n_sim' must be >= 10.", call. = FALSE)

  if (!is.null(seed)) set.seed(seed)

  year <- year %||% max(model$meta$years)

  # -- Extract base-case parameters ------------------------------------------
  pop_params  <- model$population$params
  ms_params   <- model$market_share$params
  cost_params <- model$costs$params

  base_prev  <- pop_params$prevalence %||% 0
  base_diag  <- pop_params$diagnosed_rate
  base_treat <- pop_params$treated_rate
  base_elig  <- pop_params$eligible_rate

  base_drug_costs <- cost_params$drug_costs

  # -- Beta sampler (method of moments) --------------------------------------
  .rbeta_mm <- function(n, mu, se) {
    if (is.null(se) || se <= 0) return(rep(mu, n))
    # clamp mu away from boundaries
    mu <- pmin(pmax(mu, 1e-6), 1 - 1e-6)
    v  <- se^2
    if (v >= mu * (1 - mu)) v <- mu * (1 - mu) * 0.9
    alpha <- mu * (mu * (1 - mu) / v - 1)
    beta  <- (1 - mu) * (mu * (1 - mu) / v - 1)
    stats::rbeta(n, alpha, beta)
  }

  # -- LogNormal sampler (parameterised by mean and CV) ----------------------
  .rlnorm_cv <- function(n, mu, cv) {
    if (is.null(cv) || cv <= 0) return(rep(mu, n))
    sigma2 <- log(cv^2 + 1)
    mu_ln  <- log(mu) - sigma2 / 2
    stats::rlnorm(n, meanlog = mu_ln, sdlog = sqrt(sigma2))
  }

  # -- Simulation loop --------------------------------------------------------
  results <- vector("list", n_sim)

  for (i in seq_len(n_sim)) {
    # Sample parameters
    s_prev  <- .rbeta_mm(1, base_prev,  prevalence_se)
    s_diag  <- .rbeta_mm(1, base_diag,  diagnosed_rate_se)
    s_treat <- .rbeta_mm(1, base_treat, treated_rate_se)
    s_elig  <- .rbeta_mm(1, base_elig,  eligible_rate_se)

    # Rebuild population
    pop_args <- pop_params
    pop_args$prevalence     <- s_prev
    pop_args$diagnosed_rate <- s_diag
    pop_args$treated_rate   <- s_treat
    pop_args$eligible_rate  <- s_elig

    pop_i <- tryCatch(
      suppressMessages(do.call(bim_population, pop_args)),
      error = function(e) NULL
    )
    if (is.null(pop_i)) next

    # Sample costs
    s_drug_costs <- if (!is.null(cost_cv) && cost_cv > 0) {
      stats::setNames(
        vapply(base_drug_costs, function(mu)
          .rlnorm_cv(1, mu, cost_cv), numeric(1L)),
        names(base_drug_costs)
      )
    } else {
      base_drug_costs
    }

    cost_args <- cost_params
    cost_args$drug_costs <- s_drug_costs

    costs_i <- tryCatch(
      do.call(bim_costs, cost_args),
      error = function(e) NULL
    )
    if (is.null(costs_i)) next

    # Re-use market share (shares are held fixed in PSA by default)
    ms_args <- ms_params
    ms_args$population <- pop_i

    ms_i <- tryCatch(
      do.call(bim_market_share, ms_args),
      error = function(e) NULL
    )
    if (is.null(ms_i)) next

    # Run model
    model_i <- tryCatch(
      bim_model(pop_i, ms_i, costs_i,
                payer         = model$payer,
                discount_rate = model$meta$discount_rate,
                label         = model$meta$label),
      error = function(e) NULL
    )
    if (is.null(model_i)) next

    bi <- .extract_bi_psa(model_i, year, scenario)

    results[[i]] <- data.frame(
      sim          = i,
      budget_impact = bi,
      prevalence   = s_prev,
      diagnosed_rate = s_diag,
      treated_rate = s_treat,
      eligible_rate = s_elig,
      drug_cost_index = mean(s_drug_costs / base_drug_costs)
    )
  }

  sim_df <- do.call(rbind, results[!vapply(results, is.null, logical(1L))])
  rownames(sim_df) <- NULL

  # -- Summary ----------------------------------------------------------------
  bi_vec <- sim_df$budget_impact
  smry <- data.frame(
    mean     = mean(bi_vec),
    sd       = stats::sd(bi_vec),
    median   = stats::median(bi_vec),
    ci_lower = stats::quantile(bi_vec, 0.025, names = FALSE),
    ci_upper = stats::quantile(bi_vec, 0.975, names = FALSE)
  )

  base_bi <- .extract_bi_psa(model, year, scenario)

  structure(
    list(
      simulations = sim_df,
      summary     = smry,
      year        = year,
      scenario    = scenario,
      n_sim       = n_sim,
      n_converged = nrow(sim_df),
      base_bi     = base_bi,
      currency    = model$meta$currency
    ),
    class = "bim_psa"
  )
}

# Internal helper
.extract_bi_psa <- function(model, year, scenario) {
  ann <- model$results$annual
  v   <- ann$budget_impact[ann$year == year & ann$scenario == scenario]
  if (length(v) == 0L) return(NA_real_)
  v[1L]
}

#' @export
print.bim_psa <- function(x, ...) {
  cat("htaBIM Probabilistic Sensitivity Analysis\n")
  cat(sprintf("  Year: %d | Scenario: %s | Simulations: %d / %d converged\n",
              x$year, x$scenario, x$n_converged, x$n_sim))
  cat(sprintf("  Base-case budget impact: %s %s\n",
              x$currency, format(round(x$base_bi), big.mark = ",")))
  cat("\n  PSA summary (budget impact):\n")
  s <- x$summary
  cat(sprintf("    Mean:   %s %s\n", x$currency, format(round(s$mean),   big.mark = ",")))
  cat(sprintf("    Median: %s %s\n", x$currency, format(round(s$median), big.mark = ",")))
  cat(sprintf("    SD:     %s %s\n", x$currency, format(round(s$sd),     big.mark = ",")))
  cat(sprintf("    95%% CrI: %s %s  to  %s %s\n",
              x$currency, format(round(s$ci_lower), big.mark = ","),
              x$currency, format(round(s$ci_upper), big.mark = ",")))
  invisible(x)
}

#' Plot PSA results
#'
#' @description
#' Produces a histogram of simulated budget impacts with the base-case value
#' and 95 \% credible interval marked.
#'
#' @param psa A `bim_psa` object from [bim_run_psa()].
#' @param currency_millions `logical(1)`. Express values in millions.
#'   Default `TRUE`.
#' @param title `character(1)` or `NULL`. Plot title.
#' @param col_bar `character(1)`. Histogram bar fill colour. Default light blue.
#' @param col_base `character(1)`. Colour for base-case line. Default dark blue.
#' @param col_ci `character(1)`. Colour for credible interval lines.
#'   Default orange-red.
#'
#' @return Called for side effects. Returns invisibly.
#' @export
bim_plot_psa <- function(
    psa,
    currency_millions = TRUE,
    title             = NULL,
    col_bar           = "#AEC6E8",
    col_base          = "#1a3a5c",
    col_ci            = "#D6604D"
) {
  if (!inherits(psa, "bim_psa"))
    stop("'psa' must be a bim_psa object from bim_run_psa().", call. = FALSE)

  divisor  <- if (currency_millions) 1e6 else 1
  x_label  <- if (currency_millions)
    sprintf("Budget impact (%s millions)", psa$currency)
  else
    sprintf("Budget impact (%s)", psa$currency)

  plot_title <- title %||%
    sprintf("PSA distribution — Year %d budget impact (%d simulations)",
            psa$year, psa$n_converged)

  bi   <- psa$simulations$budget_impact / divisor
  base <- psa$base_bi / divisor
  cil  <- psa$summary$ci_lower / divisor
  ciu  <- psa$summary$ci_upper / divisor

  graphics::hist(
    bi,
    breaks = 30,
    col    = col_bar,
    border = "white",
    main   = plot_title,
    xlab   = x_label,
    ylab   = "Frequency"
  )
  graphics::abline(v = base, col = col_base, lwd = 2.5, lty = 1)
  graphics::abline(v = cil,  col = col_ci,   lwd = 1.8, lty = 2)
  graphics::abline(v = ciu,  col = col_ci,   lwd = 1.8, lty = 2)
  graphics::legend(
    "topright",
    legend = c("Base case", "95% credible interval"),
    col    = c(col_base, col_ci),
    lwd    = c(2.5, 1.8),
    lty    = c(1, 2),
    bty    = "n",
    cex    = 0.85
  )
  invisible(psa)
}
