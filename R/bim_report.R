# bim_report.R -- Report generation for htaBIM
# Part of htaBIM package

#' Generate a budget impact model report
#'
#' @description
#' Produces a structured text summary report of a budget impact model,
#' written to a file or returned as a character vector. For Word (.docx)
#' or HTML output, install the suggested packages `officer` and `rmarkdown`.
#'
#' @param model A `bim_model` object.
#' @param output_file `character(1)` or `NULL`. File path for the output
#'   report. If `NULL`, returns the report as a character vector (default).
#' @param format `character(1)`. Output format: `"text"` (default), `"html"`,
#'   or `"docx"`. For `"html"` and `"docx"`, the `rmarkdown` and `officer`
#'   packages must be installed.
#' @param title `character(1)` or `NULL`. Report title. Defaults to the
#'   model label.
#' @param author `character(1)` or `NULL`. Author name for the report header.
#' @param date `Date` or `character(1)`. Report date. Default `Sys.Date()`.
#' @param scenario `character(1)`. Scenario to report. Default `"base"`.
#'
#' @return If `output_file` is `NULL`, a character vector of report lines.
#'   Otherwise, the path to the written file, invisibly.
#'
#' @examples
#' pop <- bim_population(
#'   indication    = "Disease X",
#'   country       = "GB",
#'   years         = 1:3,
#'   prevalence    = 0.003,
#'   n_total_pop   = 42e6,
#'   eligible_rate = 0.30
#' )
#' ms <- bim_market_share(
#'   population     = pop,
#'   treatments     = c("RASi", "NewDrug"),
#'   new_drug       = "NewDrug",
#'   shares_current = c(RASi = 1.0, NewDrug = 0.0),
#'   shares_new     = c(RASi = 0.8, NewDrug = 0.2)
#' )
#' costs <- bim_costs(
#'   treatments = c("RASi", "NewDrug"),
#'   drug_costs = c(RASi = 500, NewDrug = 25000)
#' )
#' model <- bim_model(pop, ms, costs)
#'
#' # Return as character vector
#' rpt <- bim_report(model)
#' cat(rpt, sep = "\n")
#'
#' @export
bim_report <- function(
    model,
    output_file = NULL,
    format      = c("text", "html", "docx"),
    title       = NULL,
    author      = NULL,
    date        = Sys.Date(),
    scenario    = "base"
) {
  if (!inherits(model, "bim_model"))
    stop("'model' must be a bim_model object.", call. = FALSE)
  format <- match.arg(format)

  if (format %in% c("html", "docx")) {
    for (pkg in c("rmarkdown", if (format == "docx") "officer")) {
      if (!requireNamespace(pkg, quietly = TRUE))
        stop(sprintf(
          "Package '%s' is required for format = '%s'. Install it with: install.packages('%s')",
          pkg, format, pkg
        ), call. = FALSE)
    }
  }

  m   <- model$meta
  ann <- model$results$annual
  cum <- model$results$cumulative
  cur <- m$currency

  sc_ann <- ann[ann$scenario == scenario, , drop = FALSE]
  sc_cum <- cum[cum$scenario == scenario, , drop = FALSE]

  if (nrow(sc_ann) == 0L)
    stop(sprintf("Scenario '%s' not found.", scenario), call. = FALSE)

  report_title  <- title  %||% m$label
  report_author <- author %||% "htaBIM"
  report_date   <- format(as.Date(date), "%d %B %Y")

  .line <- function(...) paste0(...)
  .rule <- function(char = "=", n = 60L) paste(rep(char, n), collapse = "")
  .fmt  <- function(x) format(round(x), big.mark = ",", scientific = FALSE)
  .pct  <- function(x) sprintf("%.1f%%", x)

  lines <- c(
    .rule("="),
    .line("  ", report_title),
    .line("  Budget Impact Analysis Report"),
    .rule("="),
    "",
    .line("Author  : ", report_author),
    .line("Date    : ", report_date),
    .line("Model   : htaBIM v", utils::packageVersion("htaBIM")),
    "",
    .rule("-"),
    "1. MODEL OVERVIEW",
    .rule("-"),
    .line("Indication  : ", m$indication),
    .line("Country     : ", m$country),
    .line("New drug    : ", m$new_drug),
    .line("Currency    : ", cur, " (", m$price_year, " prices)"),
    .line("Payer       : ", model$payer$name),
    .line("Discount    : ", sprintf("%.1f%%", m$discount_rate * 100)),
    .line("Scenario    : ", scenario),
    "",
    .rule("-"),
    "2. POPULATION",
    .rule("-"),
    .line("Approach    : ", model$population$meta$approach),
    ""
  )

  pop_ann <- model$population$annual
  for (i in seq_len(nrow(pop_ann))) {
    r <- pop_ann[i, ]
    lines <- c(lines, sprintf(
      "  Year %d : %s eligible patients (of %s total)",
      r$year,
      .fmt(r$n_eligible),
      .fmt(r$n_total_pop)
    ))
  }

  lines <- c(lines,
    "",
    .rule("-"),
    "3. MARKET SHARE (with new drug, base case)",
    .rule("-"),
    ""
  )

  ms_yr1 <- model$market_share$shares[
    model$market_share$shares$scenario == scenario &
      model$market_share$shares$year == min(m$years), , drop = FALSE
  ]
  for (i in seq_len(nrow(ms_yr1)))
    lines <- c(lines, sprintf("  %-25s : %.1f%%",
                              ms_yr1$treatment[i], ms_yr1$share[i] * 100))

  lines <- c(lines,
    "",
    .rule("-"),
    "4. BUDGET IMPACT RESULTS",
    .rule("-"),
    "",
    sprintf("  %-6s  %-18s  %-18s  %-15s  %-8s",
            "Year", paste(cur, "Current"), paste(cur, "New"),
            "Budget impact", "Impact %")
  )

  for (i in seq_len(nrow(sc_ann))) {
    r <- sc_ann[i, ]
    lines <- c(lines, sprintf(
      "  %-6d  %-18s  %-18s  %-15s  %-8s",
      r$year,
      .fmt(r$budget_current),
      .fmt(r$budget_new),
      .fmt(r$budget_impact),
      .pct(r$budget_impact_pct)
    ))
  }

  lines <- c(lines,
    "",
    sprintf("  %d-year cumulative budget impact: %s %s",
            max(m$years), cur,
            .fmt(sc_cum$cumulative_total)),
    "",
    .rule("-"),
    "5. COST INPUTS (annual per patient, Year 1)",
    .rule("-"),
    ""
  )

  cost_yr1 <- model$costs$total[model$costs$total$year == min(m$years), ]
  for (i in seq_len(nrow(cost_yr1)))
    lines <- c(lines, sprintf("  %-25s : %s %s",
                              cost_yr1$treatment[i],
                              cur,
                              .fmt(cost_yr1$total_cost_per_patient[i])))

  lines <- c(lines,
    "",
    .rule("-"),
    "6. REFERENCES",
    .rule("-"),
    "",
    "  Sullivan SD et al. (2014). Budget impact analysis--principles of good",
    "  practice: report of the ISPOR 2012 Budget Impact Analysis Good Practice",
    "  II Task Force. Value Health, 17(1):5-14.",
    "  doi:10.1016/j.jval.2013.08.2291",
    "",
    "  Mauskopf JA et al. (2007). Principles of good practice for budget impact",
    "  analysis. Value Health, 10(5):336-347.",
    "  doi:10.1111/j.1524-4733.2007.00187.x",
    "",
    .rule("="),
    .line("  Generated by htaBIM | ", format(Sys.time(), "%Y-%m-%d %H:%M")),
    .rule("=")
  )

  if (is.null(output_file)) {
    return(lines)
  }

  if (format == "text") {
    writeLines(lines, con = output_file)
  } else if (format == "html") {
    html_body <- paste0(
      "<!DOCTYPE html>\n<html>\n<head>\n",
      "<meta charset='UTF-8'>\n",
      "<title>", report_title, "</title>\n",
      "<style>body{font-family:Arial,sans-serif;max-width:900px;margin:auto;",
      "padding:2em}pre{background:#f5f5f5;padding:1em;border-radius:4px}",
      "h1{color:#1a3a5c}h2{color:#2166ac;border-bottom:1px solid #ccc}",
      "</style>\n</head>\n<body>\n",
      "<h1>", report_title, "</h1>\n",
      "<p><strong>Author:</strong> ", report_author, " | ",
      "<strong>Date:</strong> ", report_date, "</p>\n",
      "<pre>", paste(lines, collapse = "\n"), "</pre>\n",
      "</body>\n</html>"
    )
    writeLines(html_body, con = output_file)
  } else {
    stop("For 'docx' format, use bim_report_docx() with officer installed.",
         call. = FALSE)
  }

  message(sprintf("Report written to: %s", output_file))
  invisible(output_file)
}
