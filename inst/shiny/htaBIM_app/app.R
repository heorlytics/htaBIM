## inst/shiny/htaBIM_app/app.R
## Interactive Shiny dashboard for htaBIM
## Launch with: htaBIM::launch_shiny()

if (!requireNamespace("shiny", quietly = TRUE))
  stop("Package 'shiny' is required. Install with: install.packages('shiny')")

library(shiny)
library(htaBIM)

# ── UI ─────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  title = "htaBIM — Budget Impact Model",

  tags$head(
    tags$style(HTML("
      body { font-family: Arial, sans-serif; }
      .sidebar { background-color: #f4f6f9; padding: 15px; border-radius: 6px; }
      h3 { color: #1a3a5c; border-bottom: 2px solid #2166ac; padding-bottom: 6px; }
      .result-box { background: #e8f4fd; border-left: 4px solid #2166ac;
                    padding: 12px; border-radius: 4px; margin-bottom: 10px; }
    "))
  ),

  # Header
  fluidRow(
    column(12,
      tags$div(style = "background:#1a3a5c; color:white; padding:16px 20px; margin-bottom:20px;",
        tags$h2(style = "margin:0;", "htaBIM"),
        tags$p(style = "margin:4px 0 0;",
          "Budget Impact Modelling for Health Technology Assessment")
      )
    )
  ),

  # Sidebar + main
  sidebarLayout(
    sidebarPanel(
      width = 3,
      class = "sidebar",

      h3("Population"),
      textInput("indication", "Indication", value = "Disease X"),
      numericInput("n_total_pop", "Reference population", value = 42e6,
                   min = 1e3, step = 1e5),
      numericInput("prevalence", "Prevalence (proportion)", value = 0.003,
                   min = 0.0001, max = 0.5, step = 0.0005),
      numericInput("diagnosed_rate", "Diagnosed rate", value = 0.60,
                   min = 0, max = 1, step = 0.05),
      numericInput("treated_rate", "Treated rate", value = 0.45,
                   min = 0, max = 1, step = 0.05),
      numericInput("eligible_rate", "Eligible rate", value = 0.30,
                   min = 0, max = 1, step = 0.05),
      numericInput("years", "Projection years", value = 5,
                   min = 1, max = 10, step = 1),

      tags$hr(),
      h3("New drug"),
      textInput("new_drug_name", "Drug name", value = "Drug A"),
      numericInput("new_drug_share_yr5", "Market share at Year 5 (%)",
                   value = 20, min = 1, max = 99, step = 1),
      numericInput("new_drug_cost", "Annual drug cost (list price)",
                   value = 28000, min = 0, step = 500),
      numericInput("new_drug_monitoring", "Annual monitoring cost",
                   value = 1900, min = 0, step = 100),

      tags$hr(),
      h3("Comparator"),
      textInput("comp_name", "Comparator name", value = "Drug C (SoC)"),
      numericInput("comp_cost", "Annual comparator cost",
                   value = 1500, min = 0, step = 100),
      selectInput("currency", "Currency",
                  choices = c("GBP", "USD", "EUR", "CAD"), selected = "GBP"),

      tags$hr(),
      actionButton("run", "Run model", class = "btn-primary btn-block",
                   style = "background:#2166ac; border-color:#1a3a5c;")
    ),

    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel("Results",
          br(),
          fluidRow(
            column(4, uiOutput("bi_yr1_box")),
            column(4, uiOutput("bi_yr3_box")),
            column(4, uiOutput("bi_cum_box"))
          ),
          br(),
          plotOutput("plot_line", height = "320px"),
          br(),
          tableOutput("results_table")
        ),
        tabPanel("Market shares",
          br(),
          plotOutput("plot_shares", height = "380px")
        ),
        tabPanel("Sensitivity",
          br(),
          sliderInput("prev_lo", "Prevalence — low",
                      min = 0.0005, max = 0.01, value = 0.001, step = 0.0005),
          sliderInput("prev_hi", "Prevalence — high",
                      min = 0.001, max = 0.02, value = 0.006, step = 0.0005),
          sliderInput("cost_mult_lo", "New drug cost multiplier — low",
                      min = 0.60, max = 0.99, value = 0.85, step = 0.05),
          sliderInput("cost_mult_hi", "New drug cost multiplier — high",
                      min = 1.01, max = 1.50, value = 1.15, step = 0.05),
          actionButton("run_dsa", "Run DSA", class = "btn-info"),
          br(), br(),
          plotOutput("plot_tornado", height = "320px")
        ),
        tabPanel("Report",
          br(),
          p("Download a plain-text summary report of the current model run."),
          downloadButton("download_report", "Download report (.txt)"),
          br(), br(),
          verbatimTextOutput("report_preview")
        )
      )
    )
  )
)

# ── Server ──────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Reactive: build model from inputs
  model_rv <- eventReactive(input$run, {
    req(input$n_total_pop, input$prevalence, input$new_drug_cost)

    years_vec <- seq_len(as.integer(input$years))
    trt_curr  <- input$comp_name
    trt_new   <- input$new_drug_name

    # New drug target share ramps linearly
    target_share <- input$new_drug_share_yr5 / 100

    pop <- suppressMessages(bim_population(
      indication  = input$indication,
      country     = "custom",
      years       = years_vec,
      prevalence  = input$prevalence,
      n_total_pop = input$n_total_pop,
      diagnosed_rate = input$diagnosed_rate,
      treated_rate   = input$treated_rate,
      eligible_rate  = input$eligible_rate
    ))

    ms <- bim_market_share(
      population     = pop,
      treatments     = c(trt_curr, trt_new),
      new_drug       = trt_new,
      shares_current = stats::setNames(c(1.0, 0.0), c(trt_curr, trt_new)),
      shares_new     = stats::setNames(
        c(1 - target_share, target_share), c(trt_curr, trt_new)
      ),
      dynamics       = "linear",
      uptake_params  = list(ramp_years = as.integer(input$years))
    )

    costs <- bim_costs(
      treatments       = c(trt_curr, trt_new),
      currency         = input$currency,
      price_year       = as.integer(format(Sys.Date(), "%Y")),
      drug_costs       = stats::setNames(
        c(input$comp_cost, input$new_drug_cost), c(trt_curr, trt_new)
      ),
      monitoring_costs = stats::setNames(
        c(0, input$new_drug_monitoring), c(trt_curr, trt_new)
      )
    )

    bim_model(pop, ms, costs,
              payer = bim_payer_default(),
              label = paste(input$new_drug_name, "BIM"))
  })

  # KPI boxes
  output$bi_yr1_box <- renderUI({
    req(model_rv())
    ann <- model_rv()$results$annual
    v1  <- ann$budget_impact[ann$scenario == "base" & ann$year == 1L]
    cur <- model_rv()$meta$currency
    div(class = "result-box",
        tags$strong("Year 1 budget impact"),
        tags$p(style = "font-size:20px; font-weight:bold; color:#1a3a5c;",
               paste(cur, format(round(v1), big.mark = ","))))
  })

  output$bi_yr3_box <- renderUI({
    req(model_rv())
    ann   <- model_rv()$results$annual
    yr_max <- min(3L, max(model_rv()$meta$years))
    v3  <- ann$budget_impact[ann$scenario == "base" & ann$year == yr_max]
    cur <- model_rv()$meta$currency
    div(class = "result-box",
        tags$strong(paste0("Year ", yr_max, " budget impact")),
        tags$p(style = "font-size:20px; font-weight:bold; color:#1a3a5c;",
               paste(cur, format(round(v3), big.mark = ","))))
  })

  output$bi_cum_box <- renderUI({
    req(model_rv())
    cum <- model_rv()$results$cumulative
    vc  <- cum$cumulative_total[cum$scenario == "base"]
    cur <- model_rv()$meta$currency
    div(class = "result-box",
        tags$strong("Cumulative budget impact"),
        tags$p(style = "font-size:20px; font-weight:bold; color:#2166ac;",
               paste(cur, format(round(vc), big.mark = ","))))
  })

  # Line plot
  output$plot_line <- renderPlot({
    req(model_rv())
    bim_plot_line(model_rv(), scenario = "base", currency_millions = FALSE,
                  title = paste(input$new_drug_name, "— annual budget impact"))
  })

  # Results table
  output$results_table <- renderTable({
    req(model_rv())
    tab <- bim_table(model_rv(), format = "annual", scenario = "base")
    tab
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  # Shares plot
  output$plot_shares <- renderPlot({
    req(model_rv())
    bim_plot_shares(model_rv(), title = "Market share evolution")
  })

  # DSA
  dsa_rv <- eventReactive(input$run_dsa, {
    req(model_rv())
    spec <- bim_sensitivity_spec(
      prevalence_range           = c(input$prev_lo, input$prev_hi),
      drug_cost_multiplier_range = c(input$cost_mult_lo, input$cost_mult_hi)
    )
    bim_run_dsa(model_rv(), spec,
                year = max(model_rv()$meta$years))
  })

  output$plot_tornado <- renderPlot({
    req(dsa_rv())
    bim_plot_tornado(dsa_rv(),
                     currency = isolate(model_rv()$meta$currency),
                     title    = paste("DSA — Year", max(isolate(model_rv()$meta$years))))
  })

  # Report download
  output$download_report <- downloadHandler(
    filename = function() {
      paste0("BIM_report_", format(Sys.Date(), "%Y%m%d"), ".txt")
    },
    content  = function(file) {
      req(model_rv())
      bim_report(model_rv(), output_file = file, format = "text")
    }
  )

  output$report_preview <- renderText({
    req(model_rv())
    paste(bim_report(model_rv()), collapse = "\n")
  })
}

shinyApp(ui = ui, server = server)
