# bim_shiny.R -- Shiny launcher for htaBIM
# Part of htaBIM package

#' Launch the htaBIM interactive Shiny dashboard
#'
#' @description
#' Opens the `htaBIM` interactive budget impact modelling dashboard in the
#' default web browser. Requires the `shiny` package to be installed.
#'
#' @param ... Additional arguments passed to [shiny::runApp()].
#'
#' @return Called for its side effect (launches a Shiny app). Returns
#'   invisibly.
#'
#' @examples
#' if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
#'   launch_shiny()
#' }
#'
#' @export
launch_shiny <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE))
    stop(
      "Package 'shiny' is required. Install it with: install.packages('shiny')",
      call. = FALSE
    )
  app_dir <- system.file("shiny", "htaBIM_app", package = "htaBIM")
  if (!nzchar(app_dir) || !file.exists(app_dir))
    stop("Shiny app not found. Please reinstall htaBIM.", call. = FALSE)
  shiny::runApp(app_dir, ...)
}
