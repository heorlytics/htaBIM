# bim_costs.R -- Per-patient cost inputs for BIM
# Part of htaBIM package

#' Build per-patient annual cost inputs for a budget impact model
#'
#' @description
#' Constructs a per-patient annual cost structure for each treatment and cost
#' category (drug, administration, monitoring, adverse events, other). Supports
#' optional inflation adjustment, discounting, and confidential rebates.
#'
#' @param treatments `character`. Vector of treatment names. Must match those
#'   in [bim_market_share()].
#' @param years `integer`. Projection years (default `1:5`).
#' @param drug_costs Named `numeric` vector or `NULL`. Annual drug cost per
#'   patient by treatment.
#' @param admin_costs Named `numeric` vector or `NULL`. Annual administration
#'   cost per patient (infusion, injection nurse, etc.).
#' @param monitoring_costs Named `numeric` vector or `NULL`. Annual monitoring
#'   costs (lab tests, clinic visits, imaging).
#' @param ae_costs Named `numeric` vector or `NULL`. Annual adverse event
#'   management costs per patient.
#' @param other_costs Named `numeric` vector or `NULL`. Any other direct
#'   medical costs not captured above.
#' @param currency `character(1)`. ISO 4217 currency code (e.g. `"GBP"`,
#'   `"USD"`, `"EUR"`, `"CAD"`). Default `"GBP"`.
#' @param price_year `integer(1)`. Reference price year. Default is the
#'   current calendar year.
#' @param inflation_rate `numeric(1)`. Annual inflation rate applied to
#'   non-drug costs for years beyond Year 1. Default `0.0`.
#' @param rebates Named `numeric` vector or `NULL`. Confidential rebates as
#'   proportions (e.g. `c(DrugA = 0.15)` for 15% rebate). Applied to
#'   `drug_costs` only and kept internal (not printed by default).
#'
#' @return An object of class `bim_costs`, a list containing:
#' \describe{
#'   \item{`costs`}{A `data.frame` with columns `treatment`, `year`,
#'     `category`, `unit_cost`, `total_annual_cost`.}
#'   \item{`total`}{A `data.frame` with `treatment`, `year`,
#'     `total_cost_per_patient`.}
#'   \item{`params`}{List of all input parameters (rebates stored but not
#'     printed).}
#'   \item{`meta`}{List with `currency`, `price_year`, `treatments`.}
#' }
#'
#' @examples
#' costs <- bim_costs(
#'   treatments = c("RASi", "Sparsentan", "Sibeprenlimab"),
#'   currency   = "GBP",
#'   price_year = 2025L,
#'   drug_costs = c(
#'     RASi          = 200,
#'     Sparsentan    = 22000,
#'     Sibeprenlimab = 28500
#'   ),
#'   monitoring_costs = c(
#'     RASi          = 650,
#'     Sparsentan    = 1500,
#'     Sibeprenlimab = 1900
#'   )
#' )
#' print(costs)
#'
#' @seealso [bim_costs_drug()], [bim_costs_ae()], [bim_model()]
#' @export
bim_costs <- function(
    treatments,
    years            = 1:5,
    drug_costs       = NULL,
    admin_costs      = NULL,
    monitoring_costs = NULL,
    ae_costs         = NULL,
    other_costs      = NULL,
    currency         = "GBP",
    price_year       = as.integer(format(Sys.Date(), "%Y")),
    inflation_rate   = 0.0,
    rebates          = NULL
) {
  years <- as.integer(years)
  if (!is.character(treatments) || length(treatments) == 0L)
    stop("'treatments' must be a non-empty character vector.", call. = FALSE)
  if (!is.character(currency) || length(currency) != 1L)
    stop("'currency' must be a single character string.", call. = FALSE)
  if (!is.numeric(inflation_rate) || length(inflation_rate) != 1L || inflation_rate < 0)
    stop("'inflation_rate' must be a non-negative numeric.", call. = FALSE)

  categories <- c("drug", "admin", "monitoring", "ae", "other")
  cost_list  <- list(
    drug       = drug_costs,
    admin      = admin_costs,
    monitoring = monitoring_costs,
    ae         = ae_costs,
    other      = other_costs
  )

  # Apply rebates to drug costs
  if (!is.null(rebates) && !is.null(drug_costs)) {
    for (nm in names(rebates)) {
      if (nm %in% names(drug_costs)) {
        r <- rebates[[nm]]
        if (!is.numeric(r) || r < 0 || r > 1)
          stop(sprintf("Rebate for '%s' must be in [0, 1].", nm), call. = FALSE)
        cost_list$drug[[nm]] <- drug_costs[[nm]] * (1 - r)
      }
    }
  }

  # Build long-form cost data.frame
  rows <- vector("list", length(treatments) * length(years) * length(categories))
  k <- 1L
  for (trt in treatments) {
    for (yr_idx in seq_along(years)) {
      yr <- years[yr_idx]
      inf_factor <- (1 + inflation_rate) ^ (yr_idx - 1L)
      for (cat in categories) {
        cv <- cost_list[[cat]]
        base_cost <- if (!is.null(cv) && trt %in% names(cv)) {
          cv[[trt]]
        } else {
          0
        }
        # Drug costs not inflated; other categories may be
        inflated <- if (cat == "drug") base_cost else base_cost * inf_factor
        rows[[k]] <- data.frame(
          treatment        = trt,
          year             = yr,
          category         = cat,
          unit_cost        = base_cost,
          total_annual_cost = inflated,
          stringsAsFactors = FALSE
        )
        k <- k + 1L
      }
    }
  }
  costs_df <- do.call(rbind, rows)
  rownames(costs_df) <- NULL

  # Total per patient per year
  total_df <- stats::aggregate(
    total_annual_cost ~ treatment + year,
    data = costs_df,
    FUN  = sum
  )
  names(total_df)[3L] <- "total_cost_per_patient"

  structure(
    list(
      costs  = costs_df,
      total  = total_df,
      params = list(
        treatments    = treatments,
        years         = years,
        drug_costs    = drug_costs,
        admin_costs   = admin_costs,
        monitoring_costs = monitoring_costs,
        ae_costs      = ae_costs,
        other_costs   = other_costs,
        currency      = currency,
        price_year    = price_year,
        inflation_rate = inflation_rate,
        rebates       = rebates   # stored but not printed
      ),
      meta = list(
        currency    = currency,
        price_year  = price_year,
        treatments  = treatments,
        categories  = categories
      )
    ),
    class = "bim_costs"
  )
}

#' Calculate per-patient drug cost from pack size and dosing schedule
#'
#' @description
#' Helper function to derive an annual drug cost per patient from list price,
#' pack size, dose, and dosing frequency. Supports weight-based dosing.
#'
#' @param treatment `character(1)`. Treatment name.
#' @param list_price_per_pack `numeric(1)`. List price per pack or vial.
#' @param dose_per_admin `numeric(1)`. Dose per administration (in the units
#'   consistent with pack size).
#' @param admin_per_year `numeric(1)`. Number of administrations per year.
#' @param units_per_pack `numeric(1)`. Number of dose units per pack.
#'   Default `1`.
#' @param wastage_factor `numeric(1)`. Factor for vial/pack wastage (e.g. `1.0`
#'   for no wastage, `1.15` for 15% wastage). Default `1.0`.
#' @param body_weight_kg `numeric(1)` or `NULL`. Mean patient body weight
#'   (kg), if dosing is weight-based. Default `NULL`.
#'
#' @return A named `numeric` vector of length 1: annual drug cost per patient,
#'   suitable for use in [bim_costs()].
#'
#' @examples
#' sib_cost <- bim_costs_drug(
#'   treatment       = "Sibeprenlimab",
#'   list_price_per_pack = 2375,
#'   dose_per_admin  = 1,
#'   admin_per_year  = 12,
#'   units_per_pack  = 1
#' )
#' sib_cost
#'
#' @export
bim_costs_drug <- function(
    treatment,
    list_price_per_pack,
    dose_per_admin,
    admin_per_year,
    units_per_pack = 1,
    wastage_factor = 1.0,
    body_weight_kg = NULL
) {
  if (!is.character(treatment) || length(treatment) != 1L)
    stop("'treatment' must be a single character string.", call. = FALSE)
  for (nm in c("list_price_per_pack", "dose_per_admin", "admin_per_year")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1L || v <= 0)
      stop(sprintf("'%s' must be a positive numeric.", nm), call. = FALSE)
  }

  dose_total <- dose_per_admin * admin_per_year
  if (!is.null(body_weight_kg)) {
    if (!is.numeric(body_weight_kg) || body_weight_kg <= 0)
      stop("'body_weight_kg' must be a positive numeric.", call. = FALSE)
    dose_total <- dose_total * body_weight_kg
  }

  packs_per_year <- ceiling(dose_total / units_per_pack)
  annual_cost    <- packs_per_year * list_price_per_pack * wastage_factor

  stats::setNames(annual_cost, treatment)
}

#' Calculate per-patient adverse event costs from AE rates and unit costs
#'
#' @description
#' Computes the expected annual cost of adverse event management per patient,
#' as the sum of (AE rate ?? unit cost) across all adverse events.
#'
#' @param treatment `character(1)`. Treatment name.
#' @param ae_table A `data.frame` with columns:
#'   \describe{
#'     \item{`ae_name`}{`character`. Name of the adverse event.}
#'     \item{`rate`}{`numeric`. Probability of the AE per patient-year.}
#'     \item{`unit_cost`}{`numeric`. Cost per AE episode.}
#'   }
#'
#' @return A named `numeric` vector of length 1: expected annual AE cost per
#'   patient, suitable for use in [bim_costs()].
#'
#' @examples
#' ae_table <- data.frame(
#'   ae_name   = c("Injection site reaction", "Fatigue", "URTI"),
#'   rate      = c(0.07, 0.12, 0.09),
#'   unit_cost = c(180, 95, 65),
#'   stringsAsFactors = FALSE
#' )
#' bim_costs_ae("Sibeprenlimab", ae_table)
#'
#' @export
bim_costs_ae <- function(treatment, ae_table) {
  if (!is.character(treatment) || length(treatment) != 1L)
    stop("'treatment' must be a single character string.", call. = FALSE)
  required <- c("ae_name", "rate", "unit_cost")
  missing  <- setdiff(required, names(ae_table))
  if (length(missing) > 0)
    stop(sprintf("'ae_table' is missing columns: %s",
                 paste(missing, collapse = ", ")), call. = FALSE)
  if (any(ae_table$rate < 0) || any(ae_table$rate > 1))
    stop("All 'rate' values in 'ae_table' must be in [0, 1].", call. = FALSE)
  if (any(ae_table$unit_cost < 0))
    stop("All 'unit_cost' values in 'ae_table' must be >= 0.", call. = FALSE)

  annual_cost <- sum(ae_table$rate * ae_table$unit_cost)
  stats::setNames(annual_cost, treatment)
}

# ?????? S3 methods ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

#' Print method for bim_costs
#' @param x A `bim_costs` object.
#' @param ... Further arguments (ignored).
#' @return Invisibly returns \code{x}. Called for its side effect of printing a
#'   formatted summary of the cost inputs to the console.
#' @export
print.bim_costs <- function(x, ...) {
  cat("\n-- htaBIM Costs --\n\n")
  cat(sprintf("Currency   : %s (%d prices)\n",
              x$meta$currency, x$meta$price_year))
  cat(sprintf("Treatments : %s\n\n",
              paste(x$meta$treatments, collapse = ", ")))

  # Show Year 1 total per patient
  yr1 <- x$total[x$total$year == min(x$total$year), , drop = FALSE]
  cat("Total annual cost per patient (Year 1):\n")
  for (i in seq_len(nrow(yr1)))
    cat(sprintf("  %-25s : %s %s\n",
                yr1$treatment[i],
                x$meta$currency,
                format(round(yr1$total_cost_per_patient[i]),
                       big.mark = ",")))
  invisible(x)
}
