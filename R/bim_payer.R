# bim_payer.R -- Payer perspective for BIM
# Part of htaBIM package

#' Define a payer perspective for a budget impact model
#'
#' @description
#' Specifies which costs are borne by the budget holder and the coverage
#' fraction applied to drug costs. Pre-built payer functions cover the most
#' common HTA settings.
#'
#' @param name `character(1)`. Descriptive payer name (e.g. `"NHS England"`).
#' @param perspective `character(1)`. One of `"healthcare_system"`,
#'   `"payer"`, or `"societal"`. Informational; affects reporting only.
#' @param cost_coverage `numeric(1)`. Proportion of costs covered by this
#'   payer. Must be in `[0, 1]`. Default `1.0` (100%).
#' @param description `character(1)` or `NULL`. Optional free-text description
#'   appended to outputs.
#'
#' @return An object of class `bim_payer`.
#'
#' @examples
#' p <- bim_payer(
#'   name         = "NHS England",
#'   perspective  = "healthcare_system",
#'   cost_coverage = 1.0
#' )
#' print(p)
#'
#' @seealso [bim_payer_nhs()], [bim_payer_default()], [bim_model()]
#' @export
bim_payer <- function(
    name,
    perspective   = c("healthcare_system", "payer", "societal"),
    cost_coverage = 1.0,
    description   = NULL
) {
  perspective <- match.arg(perspective)
  if (!is.character(name) || length(name) != 1L || nchar(name) == 0L)
    stop("'name' must be a non-empty character string.", call. = FALSE)
  if (!is.numeric(cost_coverage) || length(cost_coverage) != 1L ||
      cost_coverage < 0 || cost_coverage > 1)
    stop("'cost_coverage' must be a numeric in [0, 1].", call. = FALSE)

  structure(
    list(
      name          = name,
      perspective   = perspective,
      cost_coverage = cost_coverage,
      description   = description
    ),
    class = "bim_payer"
  )
}

#' Default payer perspective (healthcare system, 100% coverage)
#'
#' @description
#' Returns a [bim_payer()] representing a generic healthcare system
#' perspective with full cost coverage. Used as the default in [bim_model()].
#'
#' @return A `bim_payer` object.
#' @export
bim_payer_default <- function() {
  bim_payer(
    name        = "Healthcare system (default)",
    perspective = "healthcare_system",
    cost_coverage = 1.0,
    description = "Generic healthcare system perspective with full cost coverage."
  )
}

#' NHS England payer perspective
#'
#' @description
#' Returns a [bim_payer()] representing the NHS England perspective,
#' appropriate for NICE Technology Appraisal submissions.
#'
#' @return A `bim_payer` object.
#' @export
bim_payer_nhs <- function() {
  bim_payer(
    name        = "NHS England",
    perspective = "healthcare_system",
    cost_coverage = 1.0,
    description = "NHS England / NICE TA perspective. Full cost coverage, no patient co-pay."
  )
}

#' CADTH Canadian public payer perspective
#'
#' @description
#' Returns a [bim_payer()] representing the Canadian Drug Review (CDR)
#' public payer perspective used in CADTH submissions.
#'
#' @return A `bim_payer` object.
#' @export
bim_payer_cadth <- function() {
  bim_payer(
    name        = "CADTH (Canadian public payer)",
    perspective = "payer",
    cost_coverage = 1.0,
    description = "Canadian public payer perspective per CADTH pharmacoeconomic guidelines (2021)."
  )
}

#' US commercial payer perspective
#'
#' @description
#' Returns a [bim_payer()] representing a US commercial insurer perspective.
#'
#' @return A `bim_payer` object.
#' @export
bim_payer_us_commercial <- function() {
  bim_payer(
    name        = "US commercial insurer",
    perspective = "payer",
    cost_coverage = 1.0,
    description = "US commercial payer perspective covering drug and medical costs."
  )
}

#' Print method for bim_payer
#' @param x A `bim_payer` object.
#' @param ... Further arguments (ignored).
#' @return Invisibly returns \code{x}. Called for its side effect of printing a
#'   formatted summary of the payer perspective settings to the console.
#' @export
print.bim_payer <- function(x, ...) {
  cat("\n-- htaBIM Payer Perspective --\n\n")
  cat(sprintf("Name        : %s\n", x$name))
  cat(sprintf("Perspective : %s\n", x$perspective))
  cat(sprintf("Coverage    : %.0f%%\n", x$cost_coverage * 100))
  if (!is.null(x$description))
    cat(sprintf("Description : %s\n", x$description))
  invisible(x)
}
