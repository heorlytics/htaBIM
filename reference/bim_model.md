# Assemble and run a budget impact model

Combines a
[`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md),
[`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md),
and
[`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md)
object into a complete budget impact model and computes the annual and
cumulative budget impact across all scenarios.

The budget impact for year *t* is defined as:

\$\$BI_t = \sum_i N_t \cdot s_i^{new}(t) \cdot c_i(t) - \sum_i N_t \cdot
s_i^{current}(t) \cdot c_i(t)\$\$

where \\N_t\\ is the number of eligible patients, \\s_i(t)\\ is the
market share of treatment \\i\\, and \\c_i(t)\\ is the cost per patient
for treatment \\i\\.

## Usage

``` r
bim_model(
  population,
  market_share,
  costs,
  payer = bim_payer_default(),
  discount_rate = 0,
  label = NULL
)
```

## Arguments

- population:

  A `bim_population` object from
  [`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md).

- market_share:

  A `bim_market_share` object from
  [`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md).

- costs:

  A `bim_costs` object from
  [`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md).

- payer:

  A `bim_payer` object from
  [`bim_payer()`](https://heorlytics.github.io/htaBIM/reference/bim_payer.md)
  or one of the pre-built payer functions. Default is
  [`bim_payer_default()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_default.md).

- discount_rate:

  `numeric(1)`. Annual discount rate applied to Year 2+ costs. Per ISPOR
  guidelines, the base case should be undiscounted (`0`). Default `0`.

- label:

  `character(1)` or `NULL`. Optional model label for reporting.

## Value

An object of class `bim_model`, a list containing:

- `population`:

  The input `bim_population` object.

- `market_share`:

  The input `bim_market_share` object.

- `costs`:

  The input `bim_costs` object.

- `payer`:

  The input `bim_payer` object.

- `results`:

  A list with `annual` and `cumulative` data frames.

- `meta`:

  A list with model metadata.

## See also

[`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md),
[`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md),
[`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md),
[`bim_payer()`](https://heorlytics.github.io/htaBIM/reference/bim_payer.md),
[`plot.bim_model()`](https://heorlytics.github.io/htaBIM/reference/plot.bim_model.md),
[`bim_table()`](https://heorlytics.github.io/htaBIM/reference/bim_table.md)

## Examples

``` r
pop <- bim_population(
  indication    = "IgA Nephropathy",
  country       = "GB",
  years         = 1:3,
  prevalence    = 0.003,
  n_total_pop   = 42e6,
  eligible_rate = 0.30
)

ms <- bim_market_share(
  population     = pop,
  treatments     = c("RASi", "Sparsentan", "Sibeprenlimab"),
  new_drug       = "Sibeprenlimab",
  shares_current = c(RASi = 0.75, Sparsentan = 0.25, Sibeprenlimab = 0.00),
  shares_new     = c(RASi = 0.60, Sparsentan = 0.20, Sibeprenlimab = 0.20)
)

costs <- bim_costs(
  treatments = c("RASi", "Sparsentan", "Sibeprenlimab"),
  drug_costs = c(RASi = 200, Sparsentan = 22000, Sibeprenlimab = 28500)
)

model <- bim_model(pop, ms, costs, label = "IgAN BIM")
summary(model)
#> 
#> == htaBIM Model Summary ==
#> =======================================================
#> Label      : IgAN BIM
#> Indication : IgA Nephropathy
#> Country    : GB
#> Currency   : GBP (2026 prices)
#> New drug   : Sibeprenlimab
#> Payer      : Healthcare system (default)
#> Discount   : 0.0%
#> -------------------------------------------------------
#> Scenario: BASE
#> Year    Budget (curr)    Budget (new)     Impact         
#> 1       GBP 213,570,000  GBP 386,316,000  GBP 172,746,000
#> 2       GBP 213,570,000  GBP 386,316,000  GBP 172,746,000
#> 3       GBP 213,570,000  GBP 386,316,000  GBP 172,746,000
#> 
#> Cumulative impact (3 yrs): GBP 518,238,000
#> 
```
