# Plot per-patient cost breakdown as a stacked bar chart

Draws a stacked horizontal bar chart of per-patient annual costs by cost
component, with one bar per treatment. Useful for visually comparing the
cost structure across treatments.

## Usage

``` r
bim_plot_cost_breakdown(model, year = NULL, colours = NULL, title = NULL)
```

## Arguments

- model:

  A `bim_model` object.

- year:

  `integer(1)` or `NULL`. Year to plot. Defaults to first available year
  in costs.

- colours:

  Named `character` vector of colours per cost category. Defaults use
  the `htaBIM` colour palette.

- title:

  `character(1)` or `NULL`. Plot title.

## Value

Called for side effects. Returns invisibly.
