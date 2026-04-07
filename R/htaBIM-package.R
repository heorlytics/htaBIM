#' htaBIM: Budget Impact Modelling for Health Technology Assessment
#'
#' @description
#' The `htaBIM` package implements a structured, reproducible framework for
#' budget impact modelling (BIM) in health technology assessment (HTA),
#' following the ISPOR Task Force guidelines.
#'
#' @details
#' ## Workflow
#'
#' A complete `htaBIM` analysis follows five steps:
#'
#' 1. **Population** -- estimate the annual eligible patient population using
#'    [bim_population()]
#' 2. **Market share** -- specify treatment shares with and without the new
#'    drug using [bim_market_share()]
#' 3. **Costs** -- build per-patient annual costs by treatment and category
#'    using [bim_costs()]
#' 4. **Model** -- assemble and run the BIM using [bim_model()]
#' 5. **Outputs** -- extract tables, plots, and reports using [bim_table()],
#'    [plot.bim_model()], and [bim_report()]
#'
#' ## Key references
#'
#' Sullivan SD, Mauskopf JA, Augustovski F et al. (2014). Budget impact
#' analysis--principles of good practice: report of the ISPOR 2012 Budget
#' Impact Analysis Good Practice II Task Force. *Value Health*, 17(1):5-14.
#' \doi{10.1016/j.jval.2013.08.2291}
#'
#' Mauskopf JA, Sullivan SD, Annemans L et al. (2007). Principles of good
#' practice for budget impact analysis. *Value Health*, 10(5):336-347.
#' \doi{10.1111/j.1524-4733.2007.00187.x}
#'
#' @keywords internal
#' @importFrom grDevices colorRampPalette
#' @importFrom rlang .data
"_PACKAGE"
