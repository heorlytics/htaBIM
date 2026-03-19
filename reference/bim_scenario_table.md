# Cross-scenario budget impact comparison table

Produces a side-by-side summary table of budget impact results across
all scenarios in a model, showing Year 1, mid-point, final year, and
cumulative totals. This is the standard tabular format for dossier
submissions following ISPOR Task Force guidelines.

## Usage

``` r
bim_scenario_table(model, years = NULL, currency_millions = TRUE, digits = 2L)
```

## Arguments

- model:

  A `bim_model` object.

- years:

  `integer` vector. Years to include as columns. If `NULL` (default),
  uses Year 1, the middle year, and the last year.

- currency_millions:

  `logical(1)`. Express values in millions. Default `TRUE`.

- digits:

  `integer(1)`. Decimal places for formatted values. Default `2L`.

## Value

A `data.frame` with one row per scenario and columns for each selected
year plus cumulative total, formatted as character strings. The
`data.frame` carries a `"caption"` attribute suitable for passing to
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html).

## See also

[`bim_table()`](https://heorlytics.github.io/htaBIM/reference/bim_table.md),
[`bim_extract()`](https://heorlytics.github.io/htaBIM/reference/bim_extract.md)

## Examples

``` r
pop <- bim_population(
  indication  = "Disease X", country = "custom",
  years = 1:5, prevalence = 0.003, n_total_pop = 42e6,
  diagnosed_rate = 0.60, treated_rate = 0.45, eligible_rate = 0.30
)
ms <- bim_market_share(
  population     = pop,
  treatments     = c("Drug C (SoC)", "Drug A (new)"),
  new_drug       = "Drug A (new)",
  shares_current = c("Drug C (SoC)" = 1.0, "Drug A (new)" = 0.0),
  shares_new     = c("Drug C (SoC)" = 0.8, "Drug A (new)" = 0.2),
  scenarios      = list(
    conservative = c("Drug C (SoC)" = 0.9, "Drug A (new)" = 0.1),
    optimistic   = c("Drug C (SoC)" = 0.7, "Drug A (new)" = 0.3)
  )
)
costs <- bim_costs(
  treatments = c("Drug C (SoC)", "Drug A (new)"),
  drug_costs = c("Drug C (SoC)" = 500, "Drug A (new)" = 25000)
)
model <- bim_model(pop, ms, costs)
st <- bim_scenario_table(model)
print(st)
#>       Scenario Year 1 (GBP millions) Year 3 (GBP millions)
#> 1         Base                 50.00                 50.00
#> 2 Conservative                 25.01                 25.01
#> 3   Optimistic                 75.02                 75.02
#>   Year 5 (GBP millions) Cumulative (GBP millions)
#> 1                 50.00                    250.02
#> 2                 25.01                    125.07
#> 3                 75.02                    375.10
```
