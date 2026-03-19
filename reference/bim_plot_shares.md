# Market share stacked bar chart

Displays market shares as stacked bars – one panel for the current
scenario (without new drug) and one for the new drug scenario – across
years.

## Usage

``` r
bim_plot_shares(model, scenario = "base", colours = NULL, title = NULL)
```

## Arguments

- model:

  A `bim_model` object.

- scenario:

  `character(1)`. New drug scenario. Default `"base"`.

- colours:

  `character` or `NULL`. Named vector of colours by treatment.

- title:

  `character(1)` or `NULL`. Plot title.

## Value

Called for side effects. Returns invisibly.
