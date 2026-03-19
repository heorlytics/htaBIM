# Calculate per-patient adverse event costs from AE rates and unit costs

Computes the expected annual cost of adverse event management per
patient, as the sum of (AE rate ?? unit cost) across all adverse events.

## Usage

``` r
bim_costs_ae(treatment, ae_table)
```

## Arguments

- treatment:

  `character(1)`. Treatment name.

- ae_table:

  A `data.frame` with columns:

  `ae_name`

  :   `character`. Name of the adverse event.

  `rate`

  :   `numeric`. Probability of the AE per patient-year.

  `unit_cost`

  :   `numeric`. Cost per AE episode.

## Value

A named `numeric` vector of length 1: expected annual AE cost per
patient, suitable for use in
[`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md).

## Examples

``` r
ae_table <- data.frame(
  ae_name   = c("Injection site reaction", "Fatigue", "URTI"),
  rate      = c(0.07, 0.12, 0.09),
  unit_cost = c(180, 95, 65),
  stringsAsFactors = FALSE
)
bim_costs_ae("Sibeprenlimab", ae_table)
#> Sibeprenlimab 
#>         29.85 
```
