# htaBIM 0.1.0

## Initial CRAN release (2026-03-01)

### New functions

* `bim_population()` — epidemiology-driven patient population estimation
  with prevalent, incident, and combined approaches.
* `bim_market_share()` — treatment market share modelling with constant,
  linear, logistic, and step uptake dynamics.
* `bim_costs()` — per-patient annual cost inputs across drug, administration,
  monitoring, adverse events, and other categories.
* `bim_costs_drug()` — helper to derive drug costs from pack price and dosing.
* `bim_costs_ae()` — helper to compute adverse event costs from rates.
* `bim_model()` — assembles and runs the complete budget impact model.
* `bim_payer()`, `bim_payer_default()`, `bim_payer_nhs()`,
  `bim_payer_cadth()`, `bim_payer_us_commercial()` — payer perspective tools.
* `bim_sensitivity_spec()` — specify DSA parameter ranges.
* `bim_run_dsa()` — run deterministic sensitivity analysis.
* `bim_extract()` — extract tidy results from a model.
* `bim_table()` — formatted budget impact summary table.
* `bim_report()` — generate a text or HTML report.
* `plot.bim_model()` — dispatch to `"line"`, `"bar"`, `"shares"`, `"tornado"`.
* `bim_plot_line()`, `bim_plot_bar()`, `bim_plot_shares()`,
  `bim_plot_tornado()` — individual plot functions.
* `launch_shiny()` — launches the interactive Shiny dashboard.

### Data

* `bim_example` — illustrative IgA Nephropathy BIM inputs for vignettes
  and testing.

### Documentation

* Full roxygen2 documentation for all exported functions.
* Vignette: *Introduction to htaBIM*.
* Interactive Shiny app for stakeholder use.
