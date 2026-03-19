# utils.R -- Internal utilities for htaBIM
# Part of htaBIM package

#' Null-coalescing operator
#' @param x Left-hand side value.
#' @param y Right-hand side default.
#' @return `x` if not `NULL`, otherwise `y`.
#' @noRd
`%||%` <- function(x, y) if (!is.null(x)) x else y

#' Check that a scalar numeric is in a given range
#' @noRd
.check_numeric_range <- function(x, name, lo = -Inf, hi = Inf) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < lo || x > hi)
    stop(sprintf("'%s' must be a single numeric in [%s, %s].",
                 name, lo, hi), call. = FALSE)
}

#' Format a number as currency string
#' @noRd
.fmt_currency <- function(x, currency = "GBP", digits = 0L) {
  paste(currency,
        format(round(x, digits), big.mark = ",", nsmall = digits,
               scientific = FALSE))
}

#' Validate that a named vector covers all required names
#' @noRd
.check_names_cover <- function(vec, required, vec_name) {
  missing <- setdiff(required, names(vec))
  if (length(missing) > 0L)
    stop(sprintf("'%s' is missing entries for: %s",
                 vec_name, paste(missing, collapse = ", ")),
         call. = FALSE)
}

#' Safe division (returns 0 when denominator is 0)
#' @noRd
.safe_div <- function(num, den) {
  ifelse(den == 0, 0, num / den)
}
