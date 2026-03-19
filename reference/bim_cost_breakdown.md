# Per-patient cost breakdown by component and treatment

Extracts and formats the per-patient annual cost decomposed by cost
category (drug, admin, monitoring, adverse events, other) for each
treatment in the model. This supports transparency and helps reviewers
understand the drivers of differential costs between treatments.

The table is suitable for direct inclusion in HTA dossier appendices.

## Usage

``` r
bim_cost_breakdown(model, year = NULL, currency_millions = FALSE, digits = 0L)
```

## Arguments

- model:

  A `bim_model` object.

- year:

  `integer(1)`. Price year to extract costs for. Defaults to
  `model$costs$meta$price_year` (base price year, before inflation).

- currency_millions:

  `logical(1)`. Express values in millions. Default `FALSE` (per-patient
  costs are typically in whole currency units).

- digits:

  `integer(1)`. Decimal places. Default `0L`.

## Value

A `data.frame` with rows = cost categories and columns = treatments,
plus a **Total** row. Values are formatted character strings. Carries a
`"caption"` attribute.

## See also

[`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md),
[`bim_costs_drug()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_drug.md),
[`bim_costs_ae()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_ae.md)

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
  shares_new     = c("Drug C (SoC)" = 0.8, "Drug A (new)" = 0.2)
)
costs <- bim_costs(
  treatments       = c("Drug C (SoC)", "Drug A (new)"),
  drug_costs       = c("Drug C (SoC)" = 500,  "Drug A (new)" = 25000),
  monitoring_costs = c("Drug C (SoC)" = 200,  "Drug A (new)" = 1500),
  ae_costs         = c("Drug C (SoC)" = 50,   "Drug A (new)" = 300)
)
model <- bim_model(pop, ms, costs)
bim_cost_breakdown(model)
#>        Cost component Drug C (SoC) Drug A (new)
#> 1           Drug cost          500       25,000
#> 2 Administration cost            0            0
#> 3     Monitoring cost          200        1,500
#> 4  Adverse event cost           50          300
#> 5          Other cost            0            0
#> 6   Total per patient          750       26,800
```
