# Changelog

## htaBIM 0.1.0

### Initial CRAN release (2026-03-01)

#### New functions

- [`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md)
  — epidemiology-driven patient population estimation with prevalent,
  incident, and combined approaches.
- [`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md)
  — treatment market share modelling with constant, linear, logistic,
  and step uptake dynamics.
- [`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md)
  — per-patient annual cost inputs across drug, administration,
  monitoring, adverse events, and other categories.
- [`bim_costs_drug()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_drug.md)
  — helper to derive drug costs from pack price and dosing.
- [`bim_costs_ae()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_ae.md)
  — helper to compute adverse event costs from rates.
- [`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)
  — assembles and runs the complete budget impact model.
- [`bim_payer()`](https://heorlytics.github.io/htaBIM/reference/bim_payer.md),
  [`bim_payer_default()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_default.md),
  [`bim_payer_nhs()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_nhs.md),
  [`bim_payer_cadth()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_cadth.md),
  [`bim_payer_us_commercial()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_us_commercial.md)
  — payer perspective tools.
- [`bim_sensitivity_spec()`](https://heorlytics.github.io/htaBIM/reference/bim_sensitivity_spec.md)
  — specify DSA parameter ranges.
- [`bim_run_dsa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_dsa.md)
  — run deterministic sensitivity analysis.
- [`bim_extract()`](https://heorlytics.github.io/htaBIM/reference/bim_extract.md)
  — extract tidy results from a model.
- [`bim_table()`](https://heorlytics.github.io/htaBIM/reference/bim_table.md)
  — formatted budget impact summary table.
- [`bim_report()`](https://heorlytics.github.io/htaBIM/reference/bim_report.md)
  — generate a text or HTML report.
- [`plot.bim_model()`](https://heorlytics.github.io/htaBIM/reference/plot.bim_model.md)
  — dispatch to `"line"`, `"bar"`, `"shares"`, `"tornado"`.
- [`bim_plot_line()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_line.md),
  [`bim_plot_bar()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_bar.md),
  [`bim_plot_shares()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_shares.md),
  [`bim_plot_tornado()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_tornado.md)
  — individual plot functions.
- [`launch_shiny()`](https://heorlytics.github.io/htaBIM/reference/launch_shiny.md)
  — launches the interactive Shiny dashboard.

#### Data

- `bim_example` — illustrative IgA Nephropathy BIM inputs for vignettes
  and testing.

#### Documentation

- Full roxygen2 documentation for all exported functions.
- Vignette: *Introduction to htaBIM*.
- Interactive Shiny app for stakeholder use.
