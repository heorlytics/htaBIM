# Line plot of annual budget impact over time

Plots the annual budget impact (or cumulative budget impact) over the
projection horizon, with one line per scenario.

## Usage

``` r
bim_plot_line(
  model,
  cumulative = FALSE,
  scenario = "base",
  currency_millions = TRUE,
  colours = NULL,
  title = NULL
)
```

## Arguments

- model:

  A `bim_model` object.

- cumulative:

  `logical(1)`. If `TRUE`, plot cumulative impact. Default `FALSE`.

- scenario:

  `character`. Scenarios to plot. Default `"base"`.

- currency_millions:

  `logical(1)`. Express values in millions. Default `TRUE`.

- colours:

  Named `character` vector. Line colours by scenario name. Defaults use
  the `htaBIM` colour palette.

- title:

  `character(1)` or `NULL`. Plot title.

## Value

Called for side effects (plot). Returns invisibly.
