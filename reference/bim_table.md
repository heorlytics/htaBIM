# Generate a formatted budget impact summary table

Produces a formatted HTML or plain-text summary table of annual and/or
cumulative budget impact, suitable for inclusion in RMarkdown reports or
HTA dossiers.

## Usage

``` r
bim_table(
  model,
  format = c("both", "annual", "cumulative"),
  scenario = "base",
  digits = 0L,
  caption = NULL,
  footnote = NULL
)
```

## Arguments

- model:

  A `bim_model` object.

- format:

  `character(1)`. Table format: `"annual"`, `"cumulative"`, or `"both"`.
  Default `"both"`.

- scenario:

  `character(1)`. Scenario to display. Default `"base"`.

- digits:

  `integer(1)`. Rounding digits. Default `0`.

- caption:

  `character(1)` or `NULL`. Table caption.

- footnote:

  `character(1)` or `NULL`. Table footnote.

## Value

A `data.frame` formatted for display.

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
tab <- bim_table(model)
print(tab)
#> $annual
#>   Year Budget (current) Budget (with drug)   Budget impact Impact (%)
#> 1    1   GBP 18,900,000    GBP 204,120,000 GBP 185,220,000     980.0%
#> 2    2   GBP 18,900,000    GBP 204,120,000 GBP 185,220,000     980.0%
#> 3    3   GBP 18,900,000    GBP 204,120,000 GBP 185,220,000     980.0%
#>   Eligible patients
#> 1            37,800
#> 2            37,800
#> 3            37,800
#> 
#> $cumulative
#>                             Metric           Value
#> cum_yr1 Cumulative impact (Year 1) GBP 185,220,000
#> cum_yr2 Cumulative impact (Year 2) GBP 370,440,000
#> cum_yr3 Cumulative impact (Year 3) GBP 555,660,000
#>                   Total cumulative GBP 555,660,000
#> 
```
