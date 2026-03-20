# bim_funnel.R -- Population funnel visualisation and Excel export
# Part of htaBIM package

# ---- Shared internal helper -------------------------------------------------

#' @noRd
.funnel_stage_df <- function(pop, year) {
  yr_row <- pop$annual[pop$annual$year == as.integer(year), , drop = FALSE]
  if (nrow(yr_row) == 0L)
    stop(sprintf("Year %d not found in the population object.", as.integer(year)),
         call. = FALSE)

  fixed     <- c("n_total_pop", "n_prevalent_or_incident",
                 "n_diagnosed", "n_treated")
  extra_cols <- setdiff(names(yr_row), c("year", fixed, "n_eligible"))
  col_order  <- c(fixed, extra_cols, "n_eligible")

  approach_label <- switch(pop$meta$approach,
    prevalent = "Prevalent Cases",
    incident  = "Incident Cases",
    "Prev. + Inc. Cases"
  )

  make_label <- function(col) {
    switch(col,
      n_total_pop             = "Total Population",
      n_prevalent_or_incident = approach_label,
      n_diagnosed             = "Diagnosed",
      n_treated               = "Treated",
      n_eligible              = "Eligible", {
        lbl <- gsub("^n_", "", col)
        lbl <- gsub("_",   " ", lbl)
        paste0(toupper(substr(lbl, 1, 1)), substr(lbl, 2, nchar(lbl)))
      }
    )
  }

  n_vals   <- as.numeric(yr_row[col_order])
  labels   <- vapply(col_order, make_label, character(1L))
  n_stage  <- length(n_vals)

  pct_ret  <- c(NA_real_,
                round(n_vals[-1L] / n_vals[-n_stage] * 100, 1))

  data.frame(
    label   = labels,
    col_key = col_order,
    n       = n_vals,
    half_w  = n_vals / (2 * max(n_vals, na.rm = TRUE)),
    pct_ret = pct_ret,
    rank    = seq_len(n_stage),   # 1 = Total Pop (widest / top)
    stringsAsFactors = FALSE
  )
}


# ---- bim_plot_funnel --------------------------------------------------------

#' Plot the epidemiological patient funnel
#'
#' @description
#' Draws a publication-quality visualisation of the sequential patient-filtering
#' steps from total population down to the eligible patients, using a
#' `bim_population` object. Two display modes are available:
#'
#' * **`"funnel"`** -- classic centred bars that narrow at each stage, giving
#'   the traditional funnel appearance used in HTA dossiers.
#' * **`"flowchart"`** -- labelled boxes connected by downward arrows, useful
#'   for slide decks and regulatory submissions.
#'
#' Percentage-retained annotations can be toggled on or off.
#'
#' @param pop A `bim_population` object from [bim_population()].
#' @param year `integer(1)`. The projection year to display. Must be present
#'   in `pop$annual$year`. Default `1L`.
#' @param type `character(1)`. `"funnel"` (default) or `"flowchart"`.
#' @param show_pct `logical(1)`. If `TRUE` (default), annotates each transition
#'   arrow / gap with the percentage of the previous stage retained.
#' @param title `character(1)` or `NULL`. Plot title. A sensible default is
#'   constructed from the indication and year when `NULL`.
#' @param palette `character(2)`. Two hex colours used for the fill gradient:
#'   the first is applied to the widest (Total Population) bar / box, and the
#'   second to the narrowest (Eligible) stage.
#'   Default `c("#2166AC", "#AEC6E8")`.
#'
#' @return A `ggplot2` object, returned invisibly. The plot is printed as a
#'   side effect.
#'
#' @examples
#' pop <- bim_population(
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
#' bim_plot_funnel(pop)
#' bim_plot_funnel(pop, type = "flowchart")
#' bim_plot_funnel(pop, show_pct = FALSE, palette = c("#1B7837", "#A6DBA0"))
#'
#' @seealso [bim_population()], [bim_export_population()]
#' @export
bim_plot_funnel <- function(pop,
                             year    = 1L,
                             type    = c("funnel", "flowchart"),
                             show_pct = TRUE,
                             title   = NULL,
                             palette = c("#2166AC", "#AEC6E8")) {

  if (!inherits(pop, "bim_population"))
    stop("'pop' must be a bim_population object.", call. = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Install with install.packages('ggplot2').",
         call. = FALSE)
  if (length(palette) < 2L)
    stop("'palette' must contain at least two colour values.", call. = FALSE)

  type <- match.arg(type)

  df <- .funnel_stage_df(pop, year)

  plt_title <- if (!is.null(title)) title else {
    sprintf("Patient Funnel: %s (Year %d)",
            pop$meta$indication, as.integer(year))
  }

  if (type == "funnel") {
    .bim_funnel_bars(df, plt_title, show_pct, palette)
  } else {
    .bim_flowchart(df, plt_title, show_pct, palette)
  }
}


# ---- Internal: centred funnel bars ------------------------------------------

#' @noRd
.bim_funnel_bars <- function(df, title, show_pct, palette) {
  n_stage <- nrow(df)

  # Gradient: Total Pop = palette[1] (dark), Eligible = palette[2] (light)
  fills   <- colorRampPalette(palette)(n_stage)
  df$fill <- fills[df$rank]

  # Centred geometry: bars are centred at x = 0.5
  df$xmin   <- 0.5 - df$half_w
  df$xmax   <- 0.5 + df$half_w

  # y position: rank 1 (Total Pop) at top -> highest y value
  df$y_plot <- n_stage - df$rank + 1L

  gg <- ggplot2::ggplot(df) +
    ggplot2::geom_rect(
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax,
                   ymin = .data$y_plot - 0.38,
                   ymax = .data$y_plot + 0.38,
                   fill = .data$fill),
      colour    = "white",
      linewidth = 0.6
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::geom_text(
      ggplot2::aes(
        x     = 0.5,
        y     = .data$y_plot,
        label = paste0(.data$label, "\n",
                       format(.data$n, big.mark = ",", scientific = FALSE))
      ),
      colour   = "white",
      fontface = "bold",
      size     = 3.2,
      lineheight = 0.9
    ) +
    ggplot2::scale_x_continuous(limits = c(-0.05, 1.05), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(
      limits = c(0.4, n_stage + 0.6), expand = c(0, 0)
    ) +
    ggplot2::labs(title = title, x = NULL, y = NULL) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(face   = "bold",
                                           hjust  = 0.5,
                                           size   = 13,
                                           margin = ggplot2::margin(b = 10)),
      plot.margin = ggplot2::margin(12, 16, 12, 16)
    )

  # Percentage annotations between consecutive bars
  if (show_pct) {
    pct_df       <- df[!is.na(df$pct_ret), , drop = FALSE]
    pct_df$y_pct <- pct_df$y_plot + 0.5   # midpoint between this and above bar
    gg <- gg +
      ggplot2::geom_text(
        data = pct_df,
        ggplot2::aes(x     = 0.5,
                     y     = .data$y_pct,
                     label = paste0(.data$pct_ret, "% retained")),
        size     = 2.7,
        colour   = "grey35",
        fontface = "italic"
      )
  }

  print(gg)
  invisible(gg)
}


# ---- Internal: flowchart with boxes and arrows ------------------------------

#' @noRd
.bim_flowchart <- function(df, title, show_pct, palette) {
  n_stage <- nrow(df)
  box_h   <- 0.55    # half-height of each box
  gap     <- 1.9     # vertical distance between box centres

  # Top stage at highest y, bottom (Eligible) at y = 0
  df$y_ctr <- (n_stage - df$rank) * gap

  # Box half-width proportional to n (min 0.30, max 0.72)
  w_min <- 0.30; w_max <- 0.72
  df$box_hw <- w_min +
    (w_max - w_min) * (df$n - min(df$n)) / (max(df$n) - min(df$n) + 1)

  fills    <- colorRampPalette(palette)(n_stage)
  df$fill  <- fills[df$rank]

  gg <- ggplot2::ggplot() +
    # Boxes
    ggplot2::geom_rect(
      data = df,
      ggplot2::aes(xmin = -.data$box_hw, xmax = .data$box_hw,
                   ymin = .data$y_ctr - box_h, ymax = .data$y_ctr + box_h,
                   fill = .data$fill),
      colour    = "white",
      linewidth = 0.6
    ) +
    ggplot2::scale_fill_identity() +
    # Labels inside boxes
    ggplot2::geom_text(
      data = df,
      ggplot2::aes(
        x     = 0,
        y     = .data$y_ctr,
        label = paste0(.data$label, "\n",
                       format(.data$n, big.mark = ",", scientific = FALSE))
      ),
      colour   = "white",
      fontface = "bold",
      size     = 3.0,
      lineheight = 0.9
    )

  # Connecting arrows
  if (n_stage > 1L) {
    arr <- data.frame(
      x    = 0,
      xend = 0,
      y    = df$y_ctr[-n_stage]  - box_h,          # bottom of upper box
      yend = df$y_ctr[-1L]       + box_h + 0.08,   # just above lower box
      stringsAsFactors = FALSE
    )
    gg <- gg +
      ggplot2::geom_segment(
        data = arr,
        ggplot2::aes(x = .data$x, y = .data$y,
                     xend = .data$xend, yend = .data$yend),
        arrow     = ggplot2::arrow(length = ggplot2::unit(0.22, "cm"),
                                   type   = "closed"),
        colour    = "grey50",
        linewidth = 0.65
      )

    if (show_pct) {
      pct_df       <- df[!is.na(df$pct_ret), , drop = FALSE]
      # Place label at the midpoint of the gap
      pct_df$y_txt <- pct_df$y_ctr + box_h + (gap - 2 * box_h) / 2
      gg <- gg +
        ggplot2::geom_label(
          data = pct_df,
          ggplot2::aes(x     = 0.65,
                       y     = .data$y_txt,
                       label = paste0(.data$pct_ret, "% retained")),
          size          = 2.6,
          colour        = "grey25",
          fill          = "white",
          label.padding = ggplot2::unit(0.14, "lines"),
          label.size    = 0.25
        )
    }
  }

  yr   <- range(df$y_ctr)
  gg <- gg +
    ggplot2::labs(title = title, x = NULL, y = NULL) +
    ggplot2::coord_cartesian(
      xlim = c(-1.05, 1.35),
      ylim = c(yr[1] - box_h - 0.3, yr[2] + box_h + 0.6)
    ) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(face   = "bold",
                                           hjust  = 0.5,
                                           size   = 13,
                                           margin = ggplot2::margin(b = 10)),
      plot.margin = ggplot2::margin(12, 16, 12, 16)
    )

  print(gg)
  invisible(gg)
}


# ---- bim_export_population --------------------------------------------------

#' Export a population funnel to a formatted Excel workbook
#'
#' @description
#' Writes a formatted `.xlsx` workbook with three sheets:
#'
#' 1. **Annual Funnel** -- the full year-by-year patient count table, as a
#'    styled Excel table.
#' 2. **Parameters** -- every model input documented in a two-column table.
#' 3. **Funnel Snapshot** -- a single-year view with percentage retained at
#'    each stage and percentage of total population (highlighted Eligible row).
#'
#' Requires the **openxlsx** package.
#'
#' @param pop A `bim_population` object from [bim_population()].
#' @param file `character(1)`. Output file path including the `.xlsx`
#'   extension. The parent directory must already exist.
#' @param snapshot_year `integer(1)` or `NULL`. Year used for the
#'   `"Funnel Snapshot"` sheet. Pass `NULL` to omit that sheet.
#'   Default `1L`.
#' @param overwrite `logical(1)`. If `FALSE` (default) and `file` already
#'   exists, an error is raised. Set `TRUE` to silently overwrite.
#'
#' @return The file path `file`, invisibly. A message is printed on success.
#'
#' @examples
#' \dontrun{
#' pop <- bim_population(
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
#' bim_export_population(pop, file = "population_funnel.xlsx")
#' }
#'
#' @seealso [bim_population()], [bim_plot_funnel()]
#' @export
bim_export_population <- function(pop,
                                   file          = "population_funnel.xlsx",
                                   snapshot_year = 1L,
                                   overwrite     = FALSE) {

  if (!inherits(pop, "bim_population"))
    stop("'pop' must be a bim_population object.", call. = FALSE)
  if (!requireNamespace("openxlsx", quietly = TRUE))
    stop(paste0("Package 'openxlsx' is required. ",
                "Install with: install.packages('openxlsx')"), call. = FALSE)
  if (!overwrite && file.exists(file))
    stop(sprintf("File '%s' already exists. Set overwrite = TRUE to replace it.",
                 file), call. = FALSE)

  wb <- openxlsx::createWorkbook()

  # ---- Shared styles --------------------------------------------------------
  title_sty  <- openxlsx::createStyle(
    fontSize       = 13,
    textDecoration = "bold",
    fontColour     = "#2166AC"
  )
  num_sty    <- openxlsx::createStyle(numFmt = "#,##0", halign = "RIGHT")
  elig_sty   <- openxlsx::createStyle(
    fgFill         = "#D6E8FA",
    textDecoration = "bold"
  )

  # ---- Pretty column name helper --------------------------------------------
  col_pretty <- function(nm) {
    switch(nm,
      year                    = "Year",
      n_total_pop             = "Total Population",
      n_prevalent_or_incident = "Prevalent / Incident",
      n_diagnosed             = "Diagnosed",
      n_treated               = "Treated",
      n_eligible              = "Eligible", {
        lbl <- gsub("^n_", "", nm)
        lbl <- gsub("_", " ", lbl)
        paste0(toupper(substr(lbl, 1, 1)), substr(lbl, 2, nchar(lbl)))
      }
    )
  }

  # ==========================================================================
  # Sheet 1 -- Annual Funnel
  # ==========================================================================
  openxlsx::addWorksheet(wb, "Annual Funnel")

  openxlsx::writeData(
    wb, "Annual Funnel",
    x        = sprintf("Patient Funnel: %s  |  Country: %s  |  Approach: %s",
                       pop$meta$indication, pop$meta$country, pop$meta$approach),
    startRow = 1, startCol = 1
  )
  openxlsx::addStyle(wb, "Annual Funnel", title_sty, rows = 1, cols = 1)

  ann             <- pop$annual
  names(ann)      <- vapply(names(ann), col_pretty, character(1L))
  n_count_cols    <- seq_along(ann)[-1L]   # every column except Year

  openxlsx::writeDataTable(
    wb, "Annual Funnel", x = ann,
    startRow = 3, startCol = 1,
    tableStyle = "TableStyleMedium2",
    withFilter = FALSE
  )
  openxlsx::addStyle(
    wb, "Annual Funnel", num_sty,
    rows        = seq(4, 3 + nrow(ann)),
    cols        = n_count_cols,
    gridExpand  = TRUE
  )
  openxlsx::setColWidths(
    wb, "Annual Funnel",
    cols   = seq_along(ann),
    widths = c(6, rep(20, ncol(ann) - 1L))
  )

  # ==========================================================================
  # Sheet 2 -- Parameters
  # ==========================================================================
  openxlsx::addWorksheet(wb, "Parameters")

  openxlsx::writeData(
    wb, "Parameters",
    x = "Model Parameters", startRow = 1, startCol = 1
  )
  openxlsx::addStyle(wb, "Parameters", title_sty, rows = 1, cols = 1)

  p <- pop$params
  params_rows <- list(
    c("Indication",     p$indication),
    c("Country",        p$country),
    c("Approach",       p$approach),
    c("Total Population",
      format(p$n_total_pop, big.mark = ",", scientific = FALSE)),
    c("Prevalence",
      if (!is.null(p$prevalence))
        paste0(round(p$prevalence * 100, 4), "%") else "N/A"),
    c("Incidence (per 100,000)",
      if (!is.null(p$incidence)) as.character(p$incidence) else "N/A"),
    c("Diagnosed Rate",  paste0(round(p$diagnosed_rate * 100, 1), "%")),
    c("Treated Rate",    paste0(round(p$treated_rate   * 100, 1), "%")),
    c("Eligible Rate",   paste0(round(p$eligible_rate  * 100, 1), "%")),
    c("Annual Growth Rate", paste0(round(p$growth_rate * 100, 2), "%")),
    c("Projection Years",
      paste0(min(p$years), " to ", max(p$years)))
  )

  if (!is.null(pop$meta$data_source))
    params_rows <- c(params_rows,
                     list(c("Data Source", pop$meta$data_source)))

  if (length(p$extra_filters) > 0L) {
    for (nm in names(p$extra_filters))
      params_rows <- c(
        params_rows,
        list(c(paste0("Extra filter: ", gsub("_", " ", nm)),
               paste0(round(p$extra_filters[[nm]] * 100, 1), "%")))
      )
  }

  param_df <- as.data.frame(
    do.call(rbind, params_rows),
    stringsAsFactors = FALSE
  )
  names(param_df) <- c("Parameter", "Value")

  openxlsx::writeDataTable(
    wb, "Parameters", x = param_df,
    startRow = 3, startCol = 1,
    tableStyle = "TableStyleLight9",
    withFilter = FALSE
  )
  openxlsx::setColWidths(wb, "Parameters", cols = 1:2, widths = c(28, 26))

  # ==========================================================================
  # Sheet 3 -- Funnel Snapshot
  # ==========================================================================
  if (!is.null(snapshot_year)) {
    snap_yr <- as.integer(snapshot_year)
    yr_row  <- pop$annual[pop$annual$year == snap_yr, , drop = FALSE]

    if (nrow(yr_row) > 0L) {
      openxlsx::addWorksheet(wb, "Funnel Snapshot")

      openxlsx::writeData(
        wb, "Funnel Snapshot",
        x = sprintf("Funnel Snapshot: Year %d  |  %s",
                    snap_yr, pop$meta$indication),
        startRow = 1, startCol = 1
      )
      openxlsx::addStyle(wb, "Funnel Snapshot", title_sty, rows = 1, cols = 1)

      df_snap <- .funnel_stage_df(pop, snap_yr)
      n_vals  <- df_snap$n
      pct_tot <- round(n_vals / n_vals[1L] * 100, 1)
      pct_ret <- df_snap$pct_ret

      snap_df <- data.frame(
        Stage                      = df_snap$label,
        N                          = n_vals,
        `% Retained from Previous` = ifelse(is.na(pct_ret), "--",
                                            paste0(pct_ret, "%")),
        `% of Total Population`    = paste0(pct_tot, "%"),
        stringsAsFactors = FALSE, check.names = FALSE
      )

      openxlsx::writeDataTable(
        wb, "Funnel Snapshot", x = snap_df,
        startRow = 3, startCol = 1,
        tableStyle = "TableStyleMedium2",
        withFilter = FALSE
      )
      # Numeric format for N column
      openxlsx::addStyle(
        wb, "Funnel Snapshot", num_sty,
        rows = seq(4, 3 + nrow(snap_df)), cols = 2,
        gridExpand = TRUE
      )
      # Highlight Eligible row
      openxlsx::addStyle(
        wb, "Funnel Snapshot", elig_sty,
        rows = 3 + nrow(snap_df), cols = 1:4,
        gridExpand = TRUE
      )
      openxlsx::setColWidths(
        wb, "Funnel Snapshot",
        cols = 1:4, widths = c(26, 16, 26, 22)
      )
    }
  }

  # ==========================================================================
  openxlsx::saveWorkbook(wb, file = file, overwrite = TRUE)
  message("Population funnel exported to: ", normalizePath(file))
  invisible(file)
}
