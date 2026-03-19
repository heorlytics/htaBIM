# Calculate per-patient drug cost from pack size and dosing schedule

Helper function to derive an annual drug cost per patient from list
price, pack size, dose, and dosing frequency. Supports weight-based
dosing.

## Usage

``` r
bim_costs_drug(
  treatment,
  list_price_per_pack,
  dose_per_admin,
  admin_per_year,
  units_per_pack = 1,
  wastage_factor = 1,
  body_weight_kg = NULL
)
```

## Arguments

- treatment:

  `character(1)`. Treatment name.

- list_price_per_pack:

  `numeric(1)`. List price per pack or vial.

- dose_per_admin:

  `numeric(1)`. Dose per administration (in the units consistent with
  pack size).

- admin_per_year:

  `numeric(1)`. Number of administrations per year.

- units_per_pack:

  `numeric(1)`. Number of dose units per pack. Default `1`.

- wastage_factor:

  `numeric(1)`. Factor for vial/pack wastage (e.g. `1.0` for no wastage,
  `1.15` for 15% wastage). Default `1.0`.

- body_weight_kg:

  `numeric(1)` or `NULL`. Mean patient body weight (kg), if dosing is
  weight-based. Default `NULL`.

## Value

A named `numeric` vector of length 1: annual drug cost per patient,
suitable for use in
[`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md).

## Examples

``` r
sib_cost <- bim_costs_drug(
  treatment       = "Sibeprenlimab",
  list_price_per_pack = 2375,
  dose_per_admin  = 1,
  admin_per_year  = 12,
  units_per_pack  = 1
)
sib_cost
#> Sibeprenlimab 
#>         28500 
```
