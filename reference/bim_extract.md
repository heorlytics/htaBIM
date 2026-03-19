# Extract tidy results from a budget impact model

Returns a tidy `data.frame` of budget impact results from a
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)
object, optionally filtered to a specific level of aggregation.

## Usage

``` r
bim_extract(model, level = c("annual", "cumulative"), scenario = "all")
```

## Arguments

- model:

  A `bim_model` object.

- level:

  `character(1)`. Level of aggregation:

  - `"annual"` – annual budget impact by year and scenario (default).

  - `"cumulative"` – cumulative totals by scenario.

- scenario:

  `character` or `"all"`. Scenarios to include. Default `"all"`.

## Value

A `data.frame`.

## Examples

``` r
pop <- bim_population(
  indication    = "Example",
  country       = "GB",
  years         = 1:3,
  prevalence    = 0.003,
  n_total_pop   = 42e6,
  eligible_rate = 0.30
)
ms <- bim_market_share(
  population     = pop,
  treatments     = c("RASi", "NewDrug"),
  new_drug       = "NewDrug",
  shares_current = c(RASi = 1.0, NewDrug = 0.0),
  shares_new     = c(RASi = 0.8, NewDrug = 0.2)
)
costs <- bim_costs(
  treatments = c("RASi", "NewDrug"),
  drug_costs = c(RASi = 500, NewDrug = 25000)
)
model <- bim_model(pop, ms, costs)
bim_extract(model, level = "annual")
#>   year scenario budget_current budget_new budget_impact budget_impact_pct
#> 1    1     base       18900000  204120000     185220000               980
#> 2    2     base       18900000  204120000     185220000               980
#> 3    3     base       18900000  204120000     185220000               980
#>   n_eligible
#> 1      37800
#> 2      37800
#> 3      37800
bim_extract(model, level = "cumulative")
#>   scenario cumulative_total   cum_yr1   cum_yr2   cum_yr3
#> 1     base        555660000 185220000 370440000 555660000
```
