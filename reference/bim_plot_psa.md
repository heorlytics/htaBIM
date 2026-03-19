# Plot PSA results

Produces a histogram of simulated budget impacts with the base-case
value and 95 \\

## Usage

``` r
bim_plot_psa(
  psa,
  currency_millions = TRUE,
  title = NULL,
  col_bar = "#AEC6E8",
  col_base = "#1a3a5c",
  col_ci = "#D6604D"
)
```

## Arguments

- psa:

  A `bim_psa` object from
  [`bim_run_psa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_psa.md).

- currency_millions:

  `logical(1)`. Express values in millions. Default `TRUE`.

- title:

  `character(1)` or `NULL`. Plot title.

- col_bar:

  `character(1)`. Histogram bar fill colour. Default light blue.

- col_base:

  `character(1)`. Colour for base-case line. Default dark blue.

- col_ci:

  `character(1)`. Colour for credible interval lines. Default
  orange-red.

## Value

Called for side effects. Returns invisibly.
