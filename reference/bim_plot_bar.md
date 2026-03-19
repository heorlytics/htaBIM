# Grouped bar chart of annual budget impact by year

Displays the annual budget impact as grouped bars, with one group per
year and one bar per scenario.

## Usage

``` r
bim_plot_bar(model, currency_millions = TRUE, colours = NULL, title = NULL)
```

## Arguments

- model:

  A `bim_model` object.

- currency_millions:

  `logical(1)`. Default `TRUE`.

- colours:

  `character` or `NULL`. Bar colours per scenario.

- title:

  `character(1)` or `NULL`.

## Value

Called for side effects. Returns invisibly.
