# Define a payer perspective for a budget impact model

Specifies which costs are borne by the budget holder and the coverage
fraction applied to drug costs. Pre-built payer functions cover the most
common HTA settings.

## Usage

``` r
bim_payer(
  name,
  perspective = c("healthcare_system", "payer", "societal"),
  cost_coverage = 1,
  description = NULL
)
```

## Arguments

- name:

  `character(1)`. Descriptive payer name (e.g. `"NHS England"`).

- perspective:

  `character(1)`. One of `"healthcare_system"`, `"payer"`, or
  `"societal"`. Informational; affects reporting only.

- cost_coverage:

  `numeric(1)`. Proportion of costs covered by this payer. Must be in
  `[0, 1]`. Default `1.0` (100%).

- description:

  `character(1)` or `NULL`. Optional free-text description appended to
  outputs.

## Value

An object of class `bim_payer`.

## See also

[`bim_payer_nhs()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_nhs.md),
[`bim_payer_default()`](https://heorlytics.github.io/htaBIM/reference/bim_payer_default.md),
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)

## Examples

``` r
p <- bim_payer(
  name         = "NHS England",
  perspective  = "healthcare_system",
  cost_coverage = 1.0
)
print(p)
#> 
#> -- htaBIM Payer Perspective --
#> 
#> Name        : NHS England
#> Perspective : healthcare_system
#> Coverage    : 100%
```
