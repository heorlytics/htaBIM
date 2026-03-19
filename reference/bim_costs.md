# Build per-patient annual cost inputs for a budget impact model

Constructs a per-patient annual cost structure for each treatment and
cost category (drug, administration, monitoring, adverse events, other).
Supports optional inflation adjustment, discounting, and confidential
rebates.

## Usage

``` r
bim_costs(
  treatments,
  years = 1:5,
  drug_costs = NULL,
  admin_costs = NULL,
  monitoring_costs = NULL,
  ae_costs = NULL,
  other_costs = NULL,
  currency = "GBP",
  price_year = as.integer(format(Sys.Date(), "%Y")),
  inflation_rate = 0,
  rebates = NULL
)
```

## Arguments

- treatments:

  `character`. Vector of treatment names. Must match those in
  [`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md).

- years:

  `integer`. Projection years (default `1:5`).

- drug_costs:

  Named `numeric` vector or `NULL`. Annual drug cost per patient by
  treatment.

- admin_costs:

  Named `numeric` vector or `NULL`. Annual administration cost per
  patient (infusion, injection nurse, etc.).

- monitoring_costs:

  Named `numeric` vector or `NULL`. Annual monitoring costs (lab tests,
  clinic visits, imaging).

- ae_costs:

  Named `numeric` vector or `NULL`. Annual adverse event management
  costs per patient.

- other_costs:

  Named `numeric` vector or `NULL`. Any other direct medical costs not
  captured above.

- currency:

  `character(1)`. ISO 4217 currency code (e.g. `"GBP"`, `"USD"`,
  `"EUR"`, `"CAD"`). Default `"GBP"`.

- price_year:

  `integer(1)`. Reference price year. Default is the current calendar
  year.

- inflation_rate:

  `numeric(1)`. Annual inflation rate applied to non-drug costs for
  years beyond Year 1. Default `0.0`.

- rebates:

  Named `numeric` vector or `NULL`. Confidential rebates as proportions
  (e.g. `c(DrugA = 0.15)` for 15% rebate). Applied to `drug_costs` only
  and kept internal (not printed by default).

## Value

An object of class `bim_costs`, a list containing:

- `costs`:

  A `data.frame` with columns `treatment`, `year`, `category`,
  `unit_cost`, `total_annual_cost`.

- `total`:

  A `data.frame` with `treatment`, `year`, `total_cost_per_patient`.

- `params`:

  List of all input parameters (rebates stored but not printed).

- `meta`:

  List with `currency`, `price_year`, `treatments`.

## See also

[`bim_costs_drug()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_drug.md),
[`bim_costs_ae()`](https://heorlytics.github.io/htaBIM/reference/bim_costs_ae.md),
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)

## Examples

``` r
costs <- bim_costs(
  treatments = c("RASi", "Sparsentan", "Sibeprenlimab"),
  currency   = "GBP",
  price_year = 2025L,
  drug_costs = c(
    RASi          = 200,
    Sparsentan    = 22000,
    Sibeprenlimab = 28500
  ),
  monitoring_costs = c(
    RASi          = 650,
    Sparsentan    = 1500,
    Sibeprenlimab = 1900
  )
)
print(costs)
#> 
#> -- htaBIM Costs --
#> 
#> Currency   : GBP (2025 prices)
#> Treatments : RASi, Sparsentan, Sibeprenlimab
#> 
#> Total annual cost per patient (Year 1):
#>   RASi                      : GBP 850
#>   Sibeprenlimab             : GBP 30,400
#>   Sparsentan                : GBP 23,500
```
