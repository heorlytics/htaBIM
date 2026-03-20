# bim_population.R -- Population estimation for budget impact modelling
# Part of htaBIM package
# ISPOR Task Force on Budget Impact Analysis alignment

#' Estimate the annual eligible patient population for a budget impact model
#'
#' @description
#' Builds a year-by-year estimate of the number of patients eligible for a new
#' treatment, using an epidemiology-driven funnel approach aligned with ISPOR
#' Task Force guidelines (Sullivan et al., 2014). Supports prevalent, incident,
#' or combined population approaches.
#'
#' @param indication `character(1)`. Name of the disease or indication. Used
#'   in outputs and reports.
#' @param country `character(1)`. ISO 3166-1 alpha-2 country code (e.g. `"GB"`,
#'   `"US"`, `"CA"`, `"DE"`). Used to look up built-in population data if
#'   `n_total_pop` is `NULL`. Use `"custom"` to rely solely on `n_total_pop`.
#' @param years `integer`. Vector of projection years (e.g. `1:5`). Default
#'   is `1:5`.
#' @param prevalence `numeric(1)` or `NULL`. Point prevalence as a proportion
#'   (e.g. `0.002` for 0.2%). Required when `approach` is `"prevalent"` or
#'   `"both"`.
#' @param incidence `numeric(1)` or `NULL`. Annual incidence rate per 100,000.
#'   Required when `approach` is `"incident"` or `"both"`.
#' @param n_total_pop `numeric(1)` or `NULL`. Total reference population size.
#'   If `NULL` and `country` is recognised, uses built-in population data.
#' @param diagnosed_rate `numeric(1)`. Proportion of prevalent/incident cases
#'   that are diagnosed. Must be in `[0, 1]`. Default `1.0`.
#' @param treated_rate `numeric(1)`. Proportion of diagnosed patients receiving
#'   any systemic treatment. Must be in `[0, 1]`. Default `1.0`.
#' @param eligible_rate `numeric(1)`. Proportion of treated patients eligible
#'   for the new drug (e.g. meeting label criteria). Must be in `[0, 1]`.
#'   Default `1.0`.
#' @param growth_rate `numeric(1)`. Annual growth rate applied to the total
#'   population (e.g. `0.005` for 0.5% per year). Default `0.0`.
#' @param approach `character(1)`. Population approach: `"prevalent"` (stock
#'   population), `"incident"` (new cases per year), or `"both"` (sum of
#'   prevalent and incident). Default `"prevalent"`.
#' @param extra_filters `list` or `NULL`. Optional named list of additional
#'   filtering proportions applied sequentially **after** `eligible_rate`.
#'   Each element must be a single numeric in `[0, 1]`. The names become
#'   column labels in the output (e.g.
#'   `list(prior_therapy_failure = 0.6, biomarker_positive = 0.4)`).
#'   Ignored if `eligible_fn` is supplied.
#' @param eligible_fn `function` or `NULL`. Optional custom function that
#'   **replaces** the entire `treated_rate * eligible_rate * extra_filters`
#'   calculation. Must accept three arguments: `n_diagnosed` (numeric vector,
#'   one value per year), `n_treated` (numeric vector), and `params` (the list
#'   of all scalar inputs). Must return a numeric vector of the same length.
#'   Use this when your eligibility logic is not simple sequential
#'   multiplication (e.g. additive components, minimum/cap rules, lookup
#'   tables). See the examples below.
#' @param data_source `character(1)` or `NULL`. Citation for the epidemiology
#'   data, appended to outputs. Optional.
#'
#' @return An object of class `bim_population`, which is a list containing:
#' \describe{
#'   \item{`annual`}{A `data.frame` with columns `year`, `n_total_pop`,
#'     `n_prevalent_or_incident`, `n_diagnosed`, `n_treated`, and
#'     `n_eligible`. When `extra_filters` are supplied, one additional column
#'     per filter step is inserted before `n_eligible`, showing the
#'     intermediate patient count at each stage.}
#'   \item{`params`}{A list of all input parameters.}
#'   \item{`meta`}{A list with `indication`, `country`, `approach`,
#'     `data_source`.}
#' }
#'
#' @examples
#' # Standard funnel
#' pop <- bim_population(
#'   indication     = "Disease X",
#'   country        = "GB",
#'   years          = 1:5,
#'   prevalence     = 0.003,
#'   n_total_pop    = 42e6,
#'   diagnosed_rate = 0.60,
#'   treated_rate   = 0.45,
#'   eligible_rate  = 0.30
#' )
#' print(pop)
#' summary(pop)
#'
#' # Extra filters: add line-of-therapy and biomarker criteria after eligible_rate
#' pop2 <- bim_population(
#'   indication     = "Disease X",
#'   country        = "GB",
#'   years          = 1:5,
#'   prevalence     = 0.003,
#'   n_total_pop    = 42e6,
#'   diagnosed_rate = 0.60,
#'   treated_rate   = 0.45,
#'   eligible_rate  = 0.30,
#'   extra_filters  = list(second_line_plus = 0.55, biomarker_positive = 0.40)
#' )
#' pop2$annual
#'
#' # Custom formula: eligible = max of two additive subgroups, capped at treated
#' pop3 <- bim_population(
#'   indication     = "Disease X",
#'   country        = "GB",
#'   years          = 1:5,
#'   prevalence     = 0.003,
#'   n_total_pop    = 42e6,
#'   diagnosed_rate = 0.60,
#'   treated_rate   = 0.45,
#'   eligible_fn    = function(n_diagnosed, n_treated, params) {
#'     subgroup_a <- n_diagnosed * 0.20
#'     subgroup_b <- n_diagnosed * 0.15
#'     pmin(subgroup_a + subgroup_b, n_treated)
#'   }
#' )
#'
#' @references
#' Sullivan SD, Mauskopf JA, Augustovski F et al. (2014). Budget impact
#' analysis--principles of good practice: report of the ISPOR 2012 Budget
#' Impact Analysis Good Practice II Task Force. *Value Health*, 17(1):5-14.
#' \doi{10.1016/j.jval.2013.08.2291}
#'
#' @seealso [bim_market_share()], [bim_costs()], [bim_model()]
#' @export
bim_population <- function(
    indication,
    country        = "GB",
    years          = 1:5,
    prevalence     = NULL,
    incidence      = NULL,
    n_total_pop    = NULL,
    diagnosed_rate = 1.0,
    treated_rate   = 1.0,
    eligible_rate  = 1.0,
    growth_rate    = 0.0,
    approach       = c("prevalent", "incident", "both"),
    extra_filters  = list(),
    eligible_fn    = NULL,
    data_source    = NULL
) {
  approach <- match.arg(approach)

  # ?????? Validate inputs ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  if (!is.character(indication) || length(indication) != 1L || nchar(indication) == 0L)
    stop("'indication' must be a non-empty character string.", call. = FALSE)
  if (!is.numeric(years) || length(years) == 0L || any(years < 1L))
    stop("'years' must be a positive integer vector.", call. = FALSE)
  years <- as.integer(years)

  .validate_rate <- function(x, name) {
    if (!is.numeric(x) || length(x) != 1L || x < 0 || x > 1)
      stop(sprintf("'%s' must be a single numeric value in [0, 1].", name),
           call. = FALSE)
  }
  .validate_rate(diagnosed_rate, "diagnosed_rate")
  .validate_rate(treated_rate,   "treated_rate")
  .validate_rate(eligible_rate,  "eligible_rate")
  if (!is.numeric(growth_rate) || length(growth_rate) != 1L)
    stop("'growth_rate' must be a single numeric value.", call. = FALSE)

  # Validate extra_filters
  if (!is.null(extra_filters) && length(extra_filters) > 0L) {
    if (!is.list(extra_filters))
      stop("'extra_filters' must be a named list.", call. = FALSE)
    if (is.null(names(extra_filters)) || any(names(extra_filters) == ""))
      stop("All elements of 'extra_filters' must be named.", call. = FALSE)
    for (nm in names(extra_filters))
      .validate_rate(extra_filters[[nm]], paste0("extra_filters$", nm))
  }

  # Validate eligible_fn
  if (!is.null(eligible_fn) && !is.function(eligible_fn))
    stop("'eligible_fn' must be a function or NULL.", call. = FALSE)

  if (approach %in% c("prevalent", "both") && is.null(prevalence))
    stop("'prevalence' is required when approach is 'prevalent' or 'both'.",
         call. = FALSE)
  if (approach %in% c("incident", "both") && is.null(incidence))
    stop("'incidence' is required when approach is 'incident' or 'both'.",
         call. = FALSE)
  if (!is.null(prevalence)) {
    if (!is.numeric(prevalence) || length(prevalence) != 1L ||
        prevalence <= 0 || prevalence >= 1)
      stop("'prevalence' must be a single numeric in (0, 1).", call. = FALSE)
  }
  if (!is.null(incidence)) {
    if (!is.numeric(incidence) || length(incidence) != 1L || incidence <= 0)
      stop("'incidence' must be a positive numeric.", call. = FALSE)
  }

  # ?????? Resolve total population ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  if (is.null(n_total_pop)) {
    n_total_pop <- .lookup_population(country)
  }
  if (!is.numeric(n_total_pop) || length(n_total_pop) != 1L || n_total_pop <= 0)
    stop("'n_total_pop' must be a positive numeric.", call. = FALSE)

  # ?????? Build annual table ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
  n_years <- length(years)
  pop_vec <- n_total_pop * ((1 + growth_rate) ^ (seq_along(years) - 1L))

  prev_vec <- switch(approach,
    prevalent = prevalence * pop_vec,
    incident  = (incidence / 1e5) * pop_vec,
    both      = prevalence * pop_vec + (incidence / 1e5) * pop_vec
  )

  diag_vec  <- prev_vec * diagnosed_rate
  treat_vec <- diag_vec * treated_rate

  # Eligible calculation: custom function takes priority over sequential rates
  if (!is.null(eligible_fn)) {
    scalar_params <- list(
      prevalence     = prevalence,
      incidence      = incidence,
      n_total_pop    = n_total_pop,
      diagnosed_rate = diagnosed_rate,
      treated_rate   = treated_rate,
      eligible_rate  = eligible_rate,
      growth_rate    = growth_rate,
      approach       = approach
    )
    elig_vec <- eligible_fn(diag_vec, treat_vec, scalar_params)
    if (!is.numeric(elig_vec) || length(elig_vec) != length(years))
      stop("'eligible_fn' must return a numeric vector of length equal to 'years'.",
           call. = FALSE)
    extra_cols <- list()
  } else {
    extra_cols <- list()

    # Apply extra filters to treated population first, then eligible_rate last
    if (length(extra_filters) > 0L) {
      current <- treat_vec
      for (nm in names(extra_filters)) {
        current                        <- current * extra_filters[[nm]]
        extra_cols[[paste0("n_", nm)]] <- round(current)
      }
      elig_vec <- current * eligible_rate
    } else {
      elig_vec <- treat_vec * eligible_rate
    }
  }

  annual <- data.frame(
    year                    = years,
    n_total_pop             = round(pop_vec),
    n_prevalent_or_incident = round(prev_vec),
    n_diagnosed             = round(diag_vec),
    n_treated               = round(treat_vec),
    stringsAsFactors        = FALSE
  )
  # Insert extra filter columns before n_eligible
  for (col_nm in names(extra_cols))
    annual[[col_nm]] <- extra_cols[[col_nm]]
  annual[["n_eligible"]] <- round(elig_vec)

  params <- list(
    indication     = indication,
    country        = country,
    years          = years,
    prevalence     = prevalence,
    incidence      = incidence,
    n_total_pop    = n_total_pop,
    diagnosed_rate = diagnosed_rate,
    treated_rate   = treated_rate,
    eligible_rate  = eligible_rate,
    growth_rate    = growth_rate,
    approach       = approach,
    extra_filters  = extra_filters,
    eligible_fn    = eligible_fn
  )

  structure(
    list(
      annual = annual,
      params = params,
      meta   = list(
        indication  = indication,
        country     = country,
        approach    = approach,
        data_source = data_source
      )
    ),
    class = "bim_population"
  )
}

# ?????? Internal helper: look up reference population ???????????????????????????????????????????????????????????????????????????

#' @noRd
.lookup_population <- function(country) {
  pop_data <- list(
    GB = 56e6,   # England + Wales adult 18-75
    US = 258e6,  # US adult population
    CA = 31e6,   # Canada adult population
    DE = 70e6,   # Germany adult population
    FR = 53e6,   # France adult population
    IT = 50e6,   # Italy adult population
    AU = 20e6,   # Australia adult population
    JP = 105e6   # Japan adult population
  )
  if (country %in% names(pop_data)) {
    message(sprintf(
      "Using built-in reference population for '%s': %s adults.",
      country,
      format(pop_data[[country]], big.mark = ",", scientific = FALSE)
    ))
    return(pop_data[[country]])
  }
  stop(
    sprintf(
      paste0("No built-in population data for country '%s'. ",
             "Please supply 'n_total_pop' directly."),
      country
    ),
    call. = FALSE
  )
}

# ?????? S3 methods ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

#' Print method for bim_population
#' @param x A `bim_population` object.
#' @param ... Further arguments (ignored).
#' @export
print.bim_population <- function(x, ...) {
  cat("\n-- htaBIM Population --\n\n")
  cat("Indication :", x$meta$indication, "\n")
  cat("Country    :", x$meta$country, "\n")
  cat("Approach   :", x$meta$approach, "\n")
  cat("Years      :", min(x$annual$year), "to", max(x$annual$year), "\n")
  if (!is.null(x$meta$data_source))
    cat("Source     :", x$meta$data_source, "\n")
  cat("\nEligible patients:\n")
  cat(sprintf("  Year %-3d : %s\n",
              x$annual$year,
              format(x$annual$n_eligible, big.mark = ",")))
  invisible(x)
}

#' Summary method for bim_population
#' @param object A `bim_population` object.
#' @param ... Further arguments (ignored).
#' @return The `bim_population` object, invisibly.
#' @export
summary.bim_population <- function(object, ...) {
  cat("\n== Population Summary ==\n")
  cat(sprintf("Indication   : %s\n", object$meta$indication))
  cat(sprintf("Country      : %s\n", object$meta$country))
  cat(sprintf("Approach     : %s\n", object$meta$approach))
  cat("\nEpidemiological funnel (Year 1):\n")
  r1 <- object$annual[1L, , drop = FALSE]
  cat(sprintf("  Total pop          : %s\n",
              format(r1$n_total_pop, big.mark = ",")))
  cat(sprintf("  Prevalent/incident : %s\n",
              format(r1$n_prevalent_or_incident, big.mark = ",")))
  cat(sprintf("  Diagnosed          : %s\n",
              format(r1$n_diagnosed, big.mark = ",")))
  cat(sprintf("  Treated            : %s\n",
              format(r1$n_treated, big.mark = ",")))
  # Show any extra filter stages
  extra_cols <- setdiff(names(r1),
    c("year", "n_total_pop", "n_prevalent_or_incident",
      "n_diagnosed", "n_treated", "n_eligible"))
  for (col in extra_cols) {
    label <- gsub("^n_", "", col)
    label <- gsub("_", " ", label)
    cat(sprintf("  %-19s: %s\n",
                paste0("  ", label),
                format(r1[[col]], big.mark = ",")))
  }
  cat(sprintf("  Eligible           : %s\n",
              format(r1$n_eligible, big.mark = ",")))
  if (!is.null(object$meta$data_source))
    cat(sprintf("\nData source  : %s\n", object$meta$data_source))
  invisible(object)
}
