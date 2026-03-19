# Package index

## Population estimation

Functions to estimate the eligible patient population.

- [`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md)
  : Estimate the annual eligible patient population for a budget impact
  model

## Market share modelling

Functions to specify treatment market shares and uptake dynamics.

- [`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md)
  : Specify treatment market shares for a budget impact model

## Cost inputs

Functions to build per-patient cost inputs.

- [`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md)
  : Build per-patient annual cost inputs for a budget impact model
- [`bim_costs_drug()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_drug.md)
  : Calculate per-patient drug cost from pack size and dosing schedule
- [`bim_costs_ae()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_ae.md)
  : Calculate per-patient adverse event costs from AE rates and unit
  costs

## Model assembly

Assemble and run the budget impact model.

- [`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)
  : Assemble and run a budget impact model

## Payer perspectives

Define or select payer perspectives.

- [`bim_payer()`](https://heorlytics.github.io/htaBIM/reference/bim_payer.md)
  : Define a payer perspective for a budget impact model
- [`bim_payer_default()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_default.md)
  : Default payer perspective (healthcare system, 100% coverage)
- [`bim_payer_nhs()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_nhs.md)
  : NHS England payer perspective
- [`bim_payer_cadth()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_cadth.md)
  : CADTH Canadian public payer perspective
- [`bim_payer_us_commercial()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_us_commercial.md)
  : US commercial payer perspective

## Sensitivity analysis

Deterministic and probabilistic sensitivity analysis tools.

- [`bim_sensitivity_spec()`](https://heorlytics.github.io/htaBIM/reference/bim_sensitivity_spec.md)
  : Specify a deterministic sensitivity analysis for a budget impact
  model
- [`bim_run_dsa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_dsa.md)
  : Run a deterministic sensitivity analysis on a budget impact model
- [`bim_run_psa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_psa.md)
  : Run a probabilistic sensitivity analysis (PSA)

## Results and outputs

Extract results, tables, plots, and reports.

- [`bim_extract()`](https://heorlytics.github.io/htaBIM/reference/bim_extract.md)
  : Extract tidy results from a budget impact model
- [`bim_table()`](https://heorlytics.github.io/htaBIM/reference/bim_table.md)
  : Generate a formatted budget impact summary table
- [`bim_scenario_table()`](https://heorlytics.github.io/htaBIM/reference/bim_scenario_table.md)
  : Cross-scenario budget impact comparison table
- [`bim_cost_breakdown()`](https://heorlytics.github.io/htaBIM/reference/bim_cost_breakdown.md)
  : Per-patient cost breakdown by component and treatment
- [`bim_report()`](https://heorlytics.github.io/htaBIM/reference/bim_report.md)
  : Generate a budget impact model report

## Plots

Visualisation functions.

- [`plot(`*`<bim_model>`*`)`](https://heorlytics.github.io/htaBIM/reference/plot.bim_model.md)
  : Plot a budget impact model
- [`bim_plot_line()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_line.md)
  : Line plot of annual budget impact over time
- [`bim_plot_bar()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_bar.md)
  : Grouped bar chart of annual budget impact by year
- [`bim_plot_shares()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_shares.md)
  : Market share stacked bar chart
- [`bim_plot_tornado()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_tornado.md)
  : Tornado diagram for DSA results
- [`bim_plot_psa()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_psa.md)
  : Plot PSA results
- [`bim_plot_cost_breakdown()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_cost_breakdown.md)
  : Plot per-patient cost breakdown as a stacked bar chart

## Interactive app

Shiny dashboard.

- [`launch_shiny()`](https://heorlytics.github.io/htaBIM/reference/launch_shiny.md)
  : Launch the htaBIM interactive Shiny dashboard

## Print and summary methods

S3 print and summary methods for htaBIM objects.

- [`print(`*`<bim_population>`*`)`](https://heorlytics.github.io/htaBIM/reference/print.bim_population.md)
  : Print method for bim_population
- [`print(`*`<bim_market_share>`*`)`](https://heorlytics.github.io/htaBIM/reference/print.bim_market_share.md)
  : Print method for bim_market_share
- [`print(`*`<bim_costs>`*`)`](https://heorlytics.github.io/htaBIM/reference/print.bim_costs.md)
  : Print method for bim_costs
- [`print(`*`<bim_payer>`*`)`](https://heorlytics.github.io/htaBIM/reference/print.bim_payer.md)
  : Print method for bim_payer
- [`print(`*`<bim_model>`*`)`](https://heorlytics.github.io/htaBIM/reference/print.bim_model.md)
  : Print method for bim_model
- [`print(`*`<bim_dsa>`*`)`](https://heorlytics.github.io/htaBIM/reference/print.bim_dsa.md)
  : Print method for bim_dsa
- [`summary(`*`<bim_population>`*`)`](https://heorlytics.github.io/htaBIM/reference/summary.bim_population.md)
  : Summary method for bim_population
- [`summary(`*`<bim_model>`*`)`](https://heorlytics.github.io/htaBIM/reference/summary.bim_model.md)
  : Summary method for bim_model

## Data

Built-in example datasets.

- [`bim_example`](https://heorlytics.github.io/htaBIM/reference/bim_example.md)
  : Example budget impact model inputs: Disease X
