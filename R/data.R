# data.R -- Built-in dataset documentation for htaBIM
# Part of htaBIM package

#' Example budget impact model inputs: Disease X
#'
#' @description
#' A named list containing example inputs for a hypothetical budget impact
#' model for a new treatment (Drug A) in a chronic condition (Disease X),
#' for use in vignettes, examples, and testing. All values are illustrative
#' only and do not represent any real drug, price, or epidemiological estimate.
#'
#' @format A named `list` with three elements:
#' \describe{
#'   \item{`population_params`}{A `list` of arguments for [bim_population()].}
#'   \item{`market_share_params`}{A `list` of arguments for
#'     [bim_market_share()] (excluding `population`).}
#'   \item{`cost_params`}{A `list` of arguments for [bim_costs()].}
#' }
#'
#' @examples
#' data(bim_example)
#' str(bim_example)
#'
#' # Reconstruct the full model
#' pop   <- do.call(bim_population, bim_example$population_params)
#' ms    <- do.call(bim_market_share,
#'                  c(list(population = pop), bim_example$market_share_params))
#' costs <- do.call(bim_costs, bim_example$cost_params)
#' model <- bim_model(pop, ms, costs)
#' summary(model)
#'
#' @source Illustrative values only. Not based on any real submission data.
"bim_example"
