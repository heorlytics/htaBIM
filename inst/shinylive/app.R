## inst/shinylive/app.R
## htaBIM Shinylive dashboard -- runs in browser via WebAssembly
## Deployed at: https://heorlytics.github.io/htaBIM/app/

# -- WebR / shinylive package installation ------------------------------------
# This block only executes inside a webR/shinylive browser session.
# WEBR_VERSION is an environment variable set automatically by webR.
if (nzchar(Sys.getenv("WEBR_VERSION"))) {
  webr::install(
    c("shiny", "bslib", "DT"),
    repos = "https://repo.r-wasm.org/"
  )
  # htaBIM and bsicons are built by r-universe as webR binaries
  webr::install(
    c("bsicons", "htaBIM"),
    repos = c(
      "https://heorlytics.r-universe.dev",
      "https://repo.r-wasm.org/"
    )
  )
}

library(shiny)
library(bslib)
library(bsicons)
library(DT)
library(htaBIM)

# -- Helpers ------------------------------------------------------------------

tooltip_ <- function(label, tip) {
  tags$span(label, title = tip)
}

.fmt_bi <- function(x, currency) {
  if (is.null(x) || is.na(x)) return("--")
  abs_m  <- abs(x) / 1e6
  sign_s <- if (x < 0) "-" else "+"
  sprintf("%s%s %.2fM", sign_s, currency, abs_m)
}

.kpi_card <- function(title, value, subtitle = NULL, color = "#2166AC") {
  tags$div(
    style = sprintf(
      "background:#fff; border-left:5px solid %s; border-radius:6px;
       padding:14px 18px; box-shadow:0 1px 4px rgba(0,0,0,.08);", color
    ),
    tags$div(style = "font-size:0.78rem; color:#666; text-transform:uppercase;
                      letter-spacing:.04em;", title),
    tags$div(style = sprintf("font-size:1.6rem; font-weight:700; color:%s;
                              margin-top:4px;", color), value),
    if (!is.null(subtitle))
      tags$div(style = "font-size:0.75rem; color:#888; margin-top:2px;",
               subtitle)
  )
}

# -- UI -----------------------------------------------------------------------

ui <- page_navbar(
  title = "htaBIM",
  theme = bs_theme(
    version      = 5,
    bootswatch   = "flatly",
    primary      = "#2166AC",
    heading_font = "Inter, system-ui, sans-serif",
    base_font    = "Inter, system-ui, sans-serif"
  ),
  header = tags$head(
    tags$link(
      rel  = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap"
    )
  ),
  bg       = "#1a3a5c",
  inverse  = TRUE,
  fillable = FALSE,

  # -- Tab 1: Inputs -----------------------------------------------------------
  nav_panel(
    "Model Setup",
    icon = bsicons::bs_icon("sliders"),

    layout_columns(
      col_widths = c(4, 4, 4),

      # Population card
      card(
        card_header(class = "bg-primary text-white", tags$b("Eligible Population")),
        card_body(
          textInput("indication", "Indication / disease",
                    value = "Disease X", placeholder = "e.g. Disease X"),
          tooltip(
            selectInput("country", "Reference country",
                        choices = c("GB", "US", "CA", "DE", "FR", "IT",
                                    "AU", "JP", "custom"),
                        selected = "custom"),
            "Select a country to use built-in population data, or 'custom' to enter manually."
          ),
          conditionalPanel(
            "input.country == 'custom'",
            numericInput("n_total_pop", "Reference population size",
                         value = 42e6, min = 1e4, step = 1e5)
          ),
          numericInput("prevalence", "Prevalence (proportion of population)",
                       value = 0.003, min = 1e-5, max = 0.5, step = 0.0005),
          numericInput("diagnosed_rate",
                       tooltip_("Diagnosed rate",
                                "Proportion of prevalent patients who receive a diagnosis."),
                       value = 0.60, min = 0, max = 1, step = 0.05),
          numericInput("treated_rate",
                       tooltip_("Treated rate",
                                "Proportion of diagnosed patients who receive any treatment."),
                       value = 0.45, min = 0, max = 1, step = 0.05),
          numericInput("eligible_rate",
                       tooltip_("Eligible rate",
                                "Proportion of treated patients eligible for the new drug."),
                       value = 0.30, min = 0, max = 1, step = 0.05),
          numericInput("growth_rate", "Annual population growth rate",
                       value = 0.005, min = 0, max = 0.1, step = 0.001),
          sliderInput("years", "Projection horizon (years)",
                      min = 1, max = 10, value = 5, step = 1)
        )
      ),

      # Treatments card
      card(
        card_header(class = "bg-primary text-white", tags$b("Treatments & Market Shares")),
        card_body(
          h6("New drug", class = "text-primary fw-bold"),
          textInput("new_drug_name", "Drug name", value = "Drug A"),
          numericInput("new_drug_share_yr_end",
                       "Target market share at end of horizon (%)",
                       value = 20, min = 1, max = 99, step = 1),
          selectInput("dynamics", "Uptake dynamics",
                      choices = c("Linear ramp"        = "linear",
                                  "Logistic (S-curve)" = "logistic",
                                  "Step change"        = "step",
                                  "Constant"           = "constant"),
                      selected = "linear"),
          tags$hr(),
          h6("Comparators", class = "text-primary fw-bold"),
          textInput("comp1_name", "Comparator 1 name", value = "Drug C (SoC)"),
          numericInput("comp1_share", "Comparator 1 share in current world (%)",
                       value = 80, min = 1, max = 99, step = 1),
          checkboxInput("add_comp2", "Add second comparator", value = FALSE),
          conditionalPanel(
            "input.add_comp2",
            textInput("comp2_name", "Comparator 2 name", value = "Drug B"),
            numericInput("comp2_share", "Comparator 2 share in current world (%)",
                         value = 20, min = 0, max = 99, step = 1)
          ),
          tags$hr(),
          h6("Scenario variants", class = "text-primary fw-bold"),
          numericInput("share_conservative", "Conservative peak share (%)",
                       value = 10, min = 1, max = 99, step = 1),
          numericInput("share_optimistic", "Optimistic peak share (%)",
                       value = 30, min = 1, max = 99, step = 1)
        )
      ),

      # Costs + payer card
      card(
        card_header(class = "bg-primary text-white", tags$b("Costs & Payer")),
        card_body(
          h6("Drug costs (annual, list price)", class = "text-primary fw-bold"),
          numericInput("new_drug_cost", "New drug cost",    value = 28000, min = 0, step = 500),
          numericInput("comp1_cost",    "Comparator 1 cost", value = 1500,  min = 0, step = 100),
          conditionalPanel(
            "input.add_comp2",
            numericInput("comp2_cost", "Comparator 2 cost", value = 10000, min = 0, step = 500)
          ),
          tags$hr(),
          h6("Additional costs (new drug)", class = "text-primary fw-bold"),
          numericInput("new_drug_admin",      "Administration cost (annual)",       value = 480,  min = 0, step = 50),
          numericInput("new_drug_monitoring", "Monitoring cost (annual)",           value = 1900, min = 0, step = 100),
          numericInput("new_drug_ae",         "Adverse event cost (annual expected)", value = 240, min = 0, step = 50),
          numericInput("new_drug_rebate",     "Confidential rebate on new drug (%)", value = 0,   min = 0, max = 99, step = 1),
          tags$hr(),
          h6("Payer & currency", class = "text-primary fw-bold"),
          selectInput("payer_type", "Payer perspective",
                      choices = c("Generic (healthcare system)" = "default",
                                  "NHS England (NICE)"          = "nhs",
                                  "CADTH (Canada)"              = "cadth",
                                  "US commercial insurer"       = "us_commercial"),
                      selected = "default"),
          selectInput("currency", "Currency",
                      choices = c("GBP", "USD", "EUR", "CAD", "AUD", "JPY"),
                      selected = "GBP"),
          numericInput("discount_rate", "Annual discount rate (Year 2+)",
                       value = 0, min = 0, max = 0.1, step = 0.01)
        )
      )
    ),

    br(),
    layout_columns(
      col_widths = c(3, 9),
      actionButton("run", "Run model", icon = icon("play"),
                   class = "btn-primary btn-lg w-100"),
      uiOutput("run_status")
    )
  ),

  # -- Tab 2: Results ----------------------------------------------------------
  nav_panel(
    "Results",
    icon = bsicons::bs_icon("bar-chart-line"),
    uiOutput("results_ui")
  ),

  # -- Tab 3: Market Shares ----------------------------------------------------
  nav_panel(
    "Market Shares",
    icon = bsicons::bs_icon("pie-chart"),
    card(
      card_header("Market share evolution by scenario"),
      card_body(plotOutput("plot_shares", height = "420px"))
    )
  ),

  # -- Tab 4: Sensitivity ------------------------------------------------------
  nav_panel(
    "Sensitivity",
    icon = bsicons::bs_icon("tornado"),

    layout_columns(
      col_widths = c(4, 8),

      card(
        card_header("DSA parameters"),
        card_body(
          h6("Prevalence range",      class = "text-primary fw-bold"),
          numericInput("prev_lo", "Low",  value = 0.001, min = 1e-5, max = 0.5, step = 0.0005),
          numericInput("prev_hi", "High", value = 0.006, min = 1e-5, max = 0.5, step = 0.0005),
          tags$hr(),
          h6("Diagnosed rate range",  class = "text-primary fw-bold"),
          numericInput("diag_lo", "Low",  value = 0.40, min = 0, max = 1, step = 0.05),
          numericInput("diag_hi", "High", value = 0.80, min = 0, max = 1, step = 0.05),
          tags$hr(),
          h6("Eligible rate range",   class = "text-primary fw-bold"),
          numericInput("elig_lo", "Low",  value = 0.20, min = 0, max = 1, step = 0.05),
          numericInput("elig_hi", "High", value = 0.50, min = 0, max = 1, step = 0.05),
          tags$hr(),
          h6("New drug cost multiplier range", class = "text-primary fw-bold"),
          numericInput("cost_lo", "Low",  value = 0.85, min = 0.1, max = 0.99, step = 0.05),
          numericInput("cost_hi", "High", value = 1.15, min = 1.01, max = 3.0,  step = 0.05),
          tags$hr(),
          selectInput("dsa_year", "Year for DSA", choices = NULL),
          actionButton("run_dsa", "Run DSA", icon = icon("play"),
                       class = "btn-info w-100")
        )
      ),

      card(
        card_header("Tornado diagram"),
        card_body(plotOutput("plot_tornado", height = "380px")),
        card_footer(uiOutput("dsa_table_ui"))
      )
    ),

    br(),
    card(
      card_header("Probabilistic Sensitivity Analysis (PSA)"),
      layout_columns(
        col_widths = c(4, 8),
        card_body(
          numericInput("psa_n",       "Number of simulations",      value = 200, min = 50, step = 50),
          numericInput("psa_prev_se", "Prevalence SE",              value = 0.0005, min = 0, step = 0.0001),
          numericInput("psa_elig_se", "Eligible rate SE",           value = 0.05,   min = 0, step = 0.01),
          numericInput("psa_cost_cv", "Cost coefficient of variation", value = 0.10, min = 0, max = 1, step = 0.01),
          actionButton("run_psa", "Run PSA", icon = icon("play"),
                       class = "btn-warning w-100"),
          br(), br(),
          uiOutput("psa_summary_ui")
        ),
        card_body(plotOutput("plot_psa", height = "320px"))
      )
    )
  ),

  # -- Tab 5: Scenario comparison ----------------------------------------------
  nav_panel(
    "Scenarios",
    icon = bsicons::bs_icon("table"),

    card(
      card_header("Cross-scenario budget impact comparison"),
      card_body(uiOutput("scenario_table_ui"))
    ),

    br(),
    card(
      card_header("Per-patient cost breakdown"),
      layout_columns(
        col_widths = c(6, 6),
        card_body(plotOutput("plot_cost_breakdown", height = "320px")),
        card_body(uiOutput("cost_breakdown_table_ui"))
      )
    )
  ),

  # -- Tab 6: Report -----------------------------------------------------------
  nav_panel(
    "Report",
    icon = bsicons::bs_icon("file-earmark-text"),

    card(
      card_header("Export model report"),
      card_body(
        p("Generate and download a structured report of the current model run.",
          class = "text-muted"),
        layout_columns(
          col_widths = c(3, 3, 6),
          downloadButton("dl_txt",  "Download .txt",  class = "btn-outline-secondary w-100"),
          downloadButton("dl_html", "Download .html", class = "btn-outline-primary w-100"),
          tags$span()
        ),
        br(),
        verbatimTextOutput("report_preview")
      )
    )
  )
)

# -- Server -------------------------------------------------------------------

server <- function(input, output, session) {

  # -- Build model -------------------------------------------------------------
  model_rv <- eventReactive(input$run, {

    req(input$prevalence, input$new_drug_cost, input$comp1_cost)

    years_vec <- seq_len(as.integer(input$years))
    trt_new   <- input$new_drug_name
    trt_comp1 <- input$comp1_name

    use_comp2 <- isTRUE(input$add_comp2) &&
      nchar(trimws(input$comp2_name)) > 0

    treatments <- if (use_comp2)
      c(trt_comp1, input$comp2_name, trt_new)
    else
      c(trt_comp1, trt_new)

    target        <- input$new_drug_share_yr_end / 100
    c1_share_curr <- input$comp1_share / 100

    if (use_comp2) {
      c2_share_curr <- input$comp2_share / 100
      total_curr    <- c1_share_curr + c2_share_curr
      if (total_curr > 1) {
        c1_share_curr <- c1_share_curr / total_curr
        c2_share_curr <- c2_share_curr / total_curr
      }
      shares_curr <- stats::setNames(
        c(c1_share_curr, c2_share_curr, 0),
        c(trt_comp1, input$comp2_name, trt_new)
      )
      ratio      <- c1_share_curr / (c1_share_curr + c2_share_curr)
      shares_new <- stats::setNames(
        c(c1_share_curr - target * ratio,
          c2_share_curr - target * (1 - ratio),
          target),
        c(trt_comp1, input$comp2_name, trt_new)
      )
    } else {
      shares_curr <- stats::setNames(c(1 - 0,      0),      c(trt_comp1, trt_new))
      shares_new  <- stats::setNames(c(1 - target, target), c(trt_comp1, trt_new))
    }

    target_cons <- input$share_conservative / 100
    target_opt  <- input$share_optimistic   / 100

    make_scenario_shares <- function(tgt) {
      if (use_comp2) {
        ratio <- c1_share_curr / (c1_share_curr + c2_share_curr)
        stats::setNames(
          c(c1_share_curr - tgt * ratio,
            c2_share_curr - tgt * (1 - ratio),
            tgt),
          c(trt_comp1, input$comp2_name, trt_new)
        )
      } else {
        stats::setNames(c(1 - tgt, tgt), c(trt_comp1, trt_new))
      }
    }

    n_pop <- if (input$country == "custom") {
      req(input$n_total_pop)
      input$n_total_pop
    } else {
      NULL
    }

    pop <- tryCatch(
      suppressMessages(bim_population(
        indication     = input$indication,
        country        = input$country,
        years          = years_vec,
        prevalence     = input$prevalence,
        n_total_pop    = n_pop,
        diagnosed_rate = input$diagnosed_rate,
        treated_rate   = input$treated_rate,
        eligible_rate  = input$eligible_rate,
        growth_rate    = input$growth_rate
      )),
      error = function(e) {
        showNotification(paste("Population error:", conditionMessage(e)), type = "error")
        NULL
      }
    )
    req(pop)

    ms <- tryCatch(
      bim_market_share(
        population     = pop,
        treatments     = treatments,
        new_drug       = trt_new,
        shares_current = shares_curr,
        shares_new     = shares_new,
        dynamics       = input$dynamics,
        uptake_params  = list(ramp_years = as.integer(input$years)),
        scenarios      = list(
          conservative = make_scenario_shares(target_cons),
          optimistic   = make_scenario_shares(target_opt)
        )
      ),
      error = function(e) {
        showNotification(paste("Market share error:", conditionMessage(e)), type = "error")
        NULL
      }
    )
    req(ms)

    drug_costs <- if (use_comp2) {
      stats::setNames(
        c(input$comp1_cost, input$comp2_cost, input$new_drug_cost),
        c(trt_comp1, input$comp2_name, trt_new)
      )
    } else {
      stats::setNames(c(input$comp1_cost, input$new_drug_cost), c(trt_comp1, trt_new))
    }

    admin_v <- stats::setNames(rep(0, length(treatments)), treatments)
    admin_v[trt_new] <- input$new_drug_admin

    mon_v <- stats::setNames(rep(0, length(treatments)), treatments)
    mon_v[trt_new] <- input$new_drug_monitoring

    ae_v <- stats::setNames(rep(0, length(treatments)), treatments)
    ae_v[trt_new] <- input$new_drug_ae

    rebates_v <- if (input$new_drug_rebate > 0)
      stats::setNames(input$new_drug_rebate / 100, trt_new)
    else
      NULL

    costs <- tryCatch(
      bim_costs(
        treatments       = treatments,
        currency         = input$currency,
        price_year       = as.integer(format(Sys.Date(), "%Y")),
        drug_costs       = drug_costs,
        admin_costs      = admin_v,
        monitoring_costs = mon_v,
        ae_costs         = ae_v,
        rebates          = rebates_v
      ),
      error = function(e) {
        showNotification(paste("Cost error:", conditionMessage(e)), type = "error")
        NULL
      }
    )
    req(costs)

    payer_fn <- switch(input$payer_type,
                       nhs           = bim_payer_nhs,
                       cadth         = bim_payer_cadth,
                       us_commercial = bim_payer_us_commercial,
                       bim_payer_default)

    model <- tryCatch(
      bim_model(pop, ms, costs,
                payer         = payer_fn(),
                discount_rate = input$discount_rate,
                label         = paste(input$new_drug_name, "BIM")),
      error = function(e) {
        showNotification(paste("Model error:", conditionMessage(e)), type = "error")
        NULL
      }
    )
    req(model)

    updateSelectInput(session, "dsa_year",
                      choices  = model$meta$years,
                      selected = max(model$meta$years))
    model
  })

  # -- Run status --------------------------------------------------------------
  output$run_status <- renderUI({
    if (is.null(model_rv())) return(NULL)
    tags$div(class = "alert alert-success mb-0",
             icon("check-circle"), " Model built -- navigate to Results.")
  })

  # -- Results tab -------------------------------------------------------------
  output$results_ui <- renderUI({
    req(model_rv())
    m   <- model_rv()
    ann <- m$results$annual
    cum <- m$results$cumulative
    cur <- m$meta$currency
    yrs <- m$meta$years
    v1  <- ann$budget_impact[ann$scenario == "base" & ann$year == min(yrs)]
    vN  <- ann$budget_impact[ann$scenario == "base" & ann$year == max(yrs)]
    vc  <- cum$cumulative_total[cum$scenario == "base"]

    tagList(
      layout_columns(
        col_widths = c(4, 4, 4),
        .kpi_card("Year 1 budget impact",    .fmt_bi(v1, cur), sprintf("vs current world, %s", cur), "#2166AC"),
        .kpi_card(sprintf("Year %d budget impact", max(yrs)), .fmt_bi(vN, cur), "Base case", "#4DAC26"),
        .kpi_card("Cumulative budget impact", .fmt_bi(vc, cur), sprintf("Years %d-%d", min(yrs), max(yrs)), "#D6604D")
      ),
      br(),
      layout_columns(
        col_widths = c(7, 5),
        card(card_header("Annual budget impact by scenario"),
             card_body(plotOutput("plot_line",       height = "300px"))),
        card(card_header("Cumulative budget impact"),
             card_body(plotOutput("plot_cumulative", height = "300px")))
      ),
      br(),
      card(card_header("Annual results table"),
           card_body(DTOutput("results_dt")))
    )
  })

  output$plot_line <- renderPlot({
    req(model_rv())
    m <- model_rv()
    bim_plot_line(m, scenario = m$meta$scenarios, currency_millions = TRUE,
                  title = paste(input$new_drug_name, "-- annual budget impact"))
  })

  output$plot_cumulative <- renderPlot({
    req(model_rv())
    m <- model_rv()
    bim_plot_line(m, cumulative = TRUE, scenario = m$meta$scenarios,
                  currency_millions = TRUE, title = "Cumulative budget impact")
  })

  output$results_dt <- renderDT({
    req(model_rv())
    tab <- bim_extract(model_rv(), level = "annual")
    tab$budget_impact <- round(tab$budget_impact / 1e6, 3)
    names(tab)[names(tab) == "budget_impact"] <-
      paste0("Budget impact (", model_rv()$meta$currency, " M)")
    datatable(tab, rownames = FALSE, filter = "top",
              options = list(pageLength = 10, scrollX = TRUE))
  })

  # -- Market shares tab -------------------------------------------------------
  output$plot_shares <- renderPlot({
    req(model_rv())
    bim_plot_shares(model_rv(), title = "Market share evolution")
  })

  # -- DSA ---------------------------------------------------------------------
  dsa_rv <- eventReactive(input$run_dsa, {
    req(model_rv())
    spec <- bim_sensitivity_spec(
      prevalence_range           = c(input$prev_lo, input$prev_hi),
      diagnosed_rate_range       = c(input$diag_lo, input$diag_hi),
      eligible_rate_range        = c(input$elig_lo, input$elig_hi),
      drug_cost_multiplier_range = c(input$cost_lo, input$cost_hi)
    )
    bim_run_dsa(model_rv(), spec, year = as.integer(input$dsa_year))
  })

  output$plot_tornado <- renderPlot({
    req(dsa_rv())
    bim_plot_tornado(dsa_rv(), currency = isolate(model_rv()$meta$currency),
                     title = paste("DSA -- Year", input$dsa_year))
  })

  output$dsa_table_ui <- renderUI({
    req(dsa_rv())
    d   <- as.data.frame(dsa_rv())
    cur <- isolate(model_rv()$meta$currency)
    for (col in c("bi_low", "bi_base", "bi_high"))
      d[[col]] <- formatC(round(d[[col]] / 1e6, 2), format = "f", digits = 2, big.mark = ",")
    names(d)[names(d) %in% c("bi_low", "bi_base", "bi_high")] <-
      paste0(c("Low", "Base", "High"), sprintf(" (%s M)", cur))
    tagList(
      tags$h6("DSA results table", class = "text-muted mt-3"),
      renderDT(datatable(d[, c("label", grep("M\\)", names(d), value = TRUE), "range")],
                         rownames = FALSE, options = list(pageLength = 8, dom = "tp")))
    )
  })

  # -- PSA ---------------------------------------------------------------------
  psa_rv <- eventReactive(input$run_psa, {
    req(model_rv())
    showNotification("Running PSA -- this may take a moment...",
                     duration = NULL, id = "psa_msg", type = "message")
    on.exit(removeNotification("psa_msg"))
    bim_run_psa(
      model_rv(),
      n_sim            = as.integer(input$psa_n),
      prevalence_se    = input$psa_prev_se,
      eligible_rate_se = input$psa_elig_se,
      cost_cv          = input$psa_cost_cv,
      year             = max(model_rv()$meta$years)
    )
  })

  output$psa_summary_ui <- renderUI({
    req(psa_rv())
    p   <- psa_rv()
    cur <- model_rv()$meta$currency
    tagList(
      tags$b("PSA summary"),
      tags$table(
        class = "table table-sm table-bordered mt-2",
        tags$tbody(
          tags$tr(tags$td("Mean"),          tags$td(.fmt_bi(p$summary$mean,     cur))),
          tags$tr(tags$td("Median"),        tags$td(.fmt_bi(p$summary$median,   cur))),
          tags$tr(tags$td("SD"),            tags$td(.fmt_bi(p$summary$sd,       cur))),
          tags$tr(tags$td("95% CrI lower"), tags$td(.fmt_bi(p$summary$ci_lower, cur))),
          tags$tr(tags$td("95% CrI upper"), tags$td(.fmt_bi(p$summary$ci_upper, cur)))
        )
      )
    )
  })

  output$plot_psa <- renderPlot({
    req(psa_rv())
    bim_plot_psa(psa_rv(), title = "PSA distribution of budget impact")
  })

  # -- Scenario comparison -----------------------------------------------------
  output$scenario_table_ui <- renderUI({
    req(model_rv())
    st <- bim_scenario_table(model_rv())
    tagList(
      tags$p(attr(st, "caption"), class = "text-muted small"),
      renderDT(datatable(st, rownames = FALSE, options = list(dom = "t")))
    )
  })

  output$plot_cost_breakdown <- renderPlot({
    req(model_rv())
    bim_plot_cost_breakdown(model_rv())
  })

  output$cost_breakdown_table_ui <- renderUI({
    req(model_rv())
    cb <- bim_cost_breakdown(model_rv())
    tagList(
      tags$p(attr(cb, "caption"), class = "text-muted small"),
      renderDT(datatable(cb, rownames = FALSE, options = list(dom = "t")))
    )
  })

  # -- Report ------------------------------------------------------------------
  output$report_preview <- renderText({
    req(model_rv())
    paste(bim_report(model_rv()), collapse = "\n")
  })

  output$dl_txt <- downloadHandler(
    filename = function() paste0("BIM_report_", format(Sys.Date(), "%Y%m%d"), ".txt"),
    content  = function(file) bim_report(model_rv(), output_file = file, format = "text")
  )

  output$dl_html <- downloadHandler(
    filename = function() paste0("BIM_report_", format(Sys.Date(), "%Y%m%d"), ".html"),
    content  = function(file) bim_report(model_rv(), output_file = file, format = "html")
  )
}

shinyApp(ui = ui, server = server)
