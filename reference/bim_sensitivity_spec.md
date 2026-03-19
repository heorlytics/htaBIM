# Specify a deterministic sensitivity analysis for a budget impact model

Defines parameter ranges for a deterministic sensitivity analysis (DSA)
on a
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md).
Each parameter is varied individually from its low to high value while
all others are held at their base case value.

## Usage

``` r
bim_sensitivity_spec(
  prevalence_range = NULL,
  diagnosed_rate_range = NULL,
  treated_rate_range = NULL,
  eligible_rate_range = NULL,
  new_drug_share_range = NULL,
  drug_cost_multiplier_range = c(0.85, 1.15),
  extra_params = NULL
)
```

## Arguments

- prevalence_range:

  `numeric(2)` or `NULL`. Low and high values for disease prevalence
  (proportion).

- diagnosed_rate_range:

  `numeric(2)` or `NULL`. Low and high values for diagnosed rate.

- treated_rate_range:

  `numeric(2)` or `NULL`. Low and high values for treated rate.

- eligible_rate_range:

  `numeric(2)` or `NULL`. Low and high values for eligible rate.

- new_drug_share_range:

  `numeric(2)` or `NULL`. Low and high values for new drug market share
  (applied uniformly across years).

- drug_cost_multiplier_range:

  `numeric(2)` or `NULL`. Low and high multipliers applied to the new
  drug cost (e.g. `c(0.85, 1.15)` for plus/minus 15%). Default
  `c(0.85, 1.15)`.

- extra_params:

  Named `list` or `NULL`. Additional parameter ranges as named elements,
  each a `list(label, base, low, high)`.

## Value

An object of class `bim_sensitivity_spec`.

## See also

[`bim_run_dsa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_dsa.md),
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)

## Examples

``` r
sens <- bim_sensitivity_spec(
  prevalence_range        = c(0.002, 0.005),
  eligible_rate_range     = c(0.20, 0.45),
  new_drug_share_range    = c(0.10, 0.30),
  drug_cost_multiplier_range = c(0.85, 1.15)
)
```
