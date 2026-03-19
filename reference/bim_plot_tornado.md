# Tornado diagram for DSA results

Draws a horizontal tornado plot from the output of
[`bim_run_dsa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_dsa.md),
showing the range of budget impact for each parameter varied.

## Usage

``` r
bim_plot_tornado(
  dsa,
  top_n = 10L,
  currency = "GBP",
  currency_millions = TRUE,
  title = NULL,
  col_low = "#2171B5",
  col_high = "#CB181D"
)
```

## Arguments

- dsa:

  A `bim_dsa` data frame from
  [`bim_run_dsa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_dsa.md).

- top_n:

  `integer(1)`. Maximum number of parameters to show. Default `10L`.

- currency:

  `character(1)`. Currency label for x-axis. Default `"GBP"`.

- currency_millions:

  `logical(1)`. Default `TRUE`.

- title:

  `character(1)` or `NULL`. Plot title.

- col_low:

  `character(1)`. Bar colour for low values. Default blue.

- col_high:

  `character(1)`. Bar colour for high values. Default red.

## Value

Called for side effects. Returns invisibly.
