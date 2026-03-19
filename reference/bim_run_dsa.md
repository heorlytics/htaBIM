# Run a deterministic sensitivity analysis on a budget impact model

Executes a one-way deterministic sensitivity analysis (DSA) by varying
each parameter in a
[`bim_sensitivity_spec()`](https://heorlytics.github.io/htaBIM/reference/bim_sensitivity_spec.md)
individually across its low/high range while holding all others at their
base values.

## Usage

``` r
bim_run_dsa(model, sensitivity, year = NULL, scenario = "base")
```

## Arguments

- model:

  A `bim_model` object.

- sensitivity:

  A `bim_sensitivity_spec` object from
  [`bim_sensitivity_spec()`](https://heorlytics.github.io/htaBIM/reference/bim_sensitivity_spec.md).

- year:

  `integer(1)`. The projection year on which DSA results are evaluated.
  Default is the final year in the model.

- scenario:

  `character(1)`. Which scenario to use as base case. Default `"base"`.

## Value

A `data.frame` with columns `parameter`, `label`, `low_value`,
`high_value`, `bi_low`, `bi_base`, `bi_high`, `range`, sorted by `range`
descending (largest impact first). Can be passed directly to
[`bim_plot_tornado()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_tornado.md).

## See also

[`bim_sensitivity_spec()`](https://heorlytics.github.io/htaBIM/reference/bim_sensitivity_spec.md),
[`bim_plot_tornado()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_tornado.md)

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

sens <- bim_sensitivity_spec(
  prevalence_range        = c(0.002, 0.005),
  eligible_rate_range     = c(0.20, 0.45),
  drug_cost_multiplier_range = c(0.85, 1.15)
)
dsa <- bim_run_dsa(model, sens, year = 3L)
print(dsa)
#> 
#> -- htaBIM DSA Results --
#> 
#> Parameter                       BI (low)      BI (base)     BI (high)   
#> ------------------------------------------------------------------------
#> New drug cost (multiplier)      156,870,000   185,220,000   213,570,000 
#> Prevalence                      185,220,000   185,220,000   185,220,000 
#> Eligible rate                   185,220,000   185,220,000   185,220,000 
```
