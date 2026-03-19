# Specify treatment market shares for a budget impact model

Defines how treatment market shares evolve over time, both in the
current scenario (without the new drug) and in the new scenario (with
the new drug introduced). Supports constant, linear ramp, logistic
S-curve, and step uptake dynamics.

## Usage

``` r
bim_market_share(
  population,
  treatments,
  new_drug,
  shares_current,
  shares_new,
  dynamics = c("constant", "linear", "logistic", "step"),
  uptake_params = NULL,
  scenarios = NULL
)
```

## Arguments

- population:

  A `bim_population` object from
  [`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md).

- treatments:

  `character`. Vector of all treatment names, including the new drug.

- new_drug:

  `character(1)`. Name of the new intervention. Must be an element of
  `treatments`.

- shares_current:

  Named `numeric` vector. Market shares in the current scenario (without
  the new drug). Values must sum to 1 and all be in `[0, 1]`. Names must
  match `treatments`.

- shares_new:

  Named `numeric` vector. Market shares in the new scenario (with the
  new drug at full uptake). Values must sum to 1. Names must match
  `treatments`.

- dynamics:

  `character(1)`. How the new drug's uptake evolves:

  - `"constant"` – `shares_new` apply uniformly in all years (default).

  - `"linear"` – new drug ramps linearly from 0 to target share over
    `uptake_params$ramp_years` years.

  - `"logistic"` – S-curve uptake. Requires `uptake_params$year_50pct`
    and optionally `uptake_params$steepness`.

  - `"step"` – shares_new is a named list with one vector per year.

- uptake_params:

  `list` or `NULL`. Parameters controlling uptake dynamics:

  - For `"linear"`: `list(ramp_years = 3)`.

  - For `"logistic"`: `list(year_50pct = 2, steepness = 2)`.

- scenarios:

  Named `list` or `NULL`. Alternative market share vectors (named
  numerics, same structure as `shares_new`) for scenario analysis. E.g.
  `list(conservative = c(...), optimistic = c(...))`.

## Value

An object of class `bim_market_share`, a list containing:

- `shares`:

  A `data.frame` with columns `year`, `treatment`, `scenario`, `share`,
  `n_patients`.

- `params`:

  List of input parameters.

- `meta`:

  List with `treatments`, `new_drug`, `dynamics`.

## See also

[`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md),
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)

## Examples

``` r
pop <- bim_population(
  indication  = "IgA Nephropathy",
  country     = "GB",
  years       = 1:5,
  prevalence  = 0.003,
  n_total_pop = 42e6,
  eligible_rate = 0.30
)

ms <- bim_market_share(
  population     = pop,
  treatments     = c("RASi", "Sparsentan", "Sibeprenlimab"),
  new_drug       = "Sibeprenlimab",
  shares_current = c(RASi = 0.75, Sparsentan = 0.25, Sibeprenlimab = 0.00),
  shares_new     = c(RASi = 0.60, Sparsentan = 0.20, Sibeprenlimab = 0.20),
  dynamics       = "linear",
  uptake_params  = list(ramp_years = 3)
)
print(ms)
#> 
#> -- htaBIM Market Share --
#> 
#> Treatments : RASi, Sparsentan, Sibeprenlimab 
#> New drug   : Sibeprenlimab 
#> Dynamics   : linear 
#> Scenarios  : current, base 
#> 
#> Year 1 shares (base, with new drug):
#>   RASi                      : 70.0%
#>   Sparsentan                : 23.3%
#>   Sibeprenlimab             : 6.7%
```
