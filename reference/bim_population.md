# Estimate the annual eligible patient population for a budget impact model

Builds a year-by-year estimate of the number of patients eligible for a
new treatment, using an epidemiology-driven funnel approach aligned with
ISPOR Task Force guidelines (Sullivan et al., 2014). Supports prevalent,
incident, or combined population approaches.

## Usage

``` r
bim_population(
  indication,
  country = "GB",
  years = 1:5,
  prevalence = NULL,
  incidence = NULL,
  n_total_pop = NULL,
  diagnosed_rate = 1,
  treated_rate = 1,
  eligible_rate = 1,
  growth_rate = 0,
  approach = c("prevalent", "incident", "both"),
  data_source = NULL
)
```

## Arguments

- indication:

  `character(1)`. Name of the disease or indication. Used in outputs and
  reports.

- country:

  `character(1)`. ISO 3166-1 alpha-2 country code (e.g. `"GB"`, `"US"`,
  `"CA"`, `"DE"`). Used to look up built-in population data if
  `n_total_pop` is `NULL`. Use `"custom"` to rely solely on
  `n_total_pop`.

- years:

  `integer`. Vector of projection years (e.g. `1:5`). Default is `1:5`.

- prevalence:

  `numeric(1)` or `NULL`. Point prevalence as a proportion (e.g. `0.002`
  for 0.2%). Required when `approach` is `"prevalent"` or `"both"`.

- incidence:

  `numeric(1)` or `NULL`. Annual incidence rate per 100,000. Required
  when `approach` is `"incident"` or `"both"`.

- n_total_pop:

  `numeric(1)` or `NULL`. Total reference population size. If `NULL` and
  `country` is recognised, uses built-in population data.

- diagnosed_rate:

  `numeric(1)`. Proportion of prevalent/incident cases that are
  diagnosed. Must be in `[0, 1]`. Default `1.0`.

- treated_rate:

  `numeric(1)`. Proportion of diagnosed patients receiving any systemic
  treatment. Must be in `[0, 1]`. Default `1.0`.

- eligible_rate:

  `numeric(1)`. Proportion of treated patients eligible for the new drug
  (e.g. meeting label criteria). Must be in `[0, 1]`. Default `1.0`.

- growth_rate:

  `numeric(1)`. Annual growth rate applied to the total population (e.g.
  `0.005` for 0.5% per year). Default `0.0`.

- approach:

  `character(1)`. Population approach: `"prevalent"` (stock population),
  `"incident"` (new cases per year), or `"both"` (sum of prevalent and
  incident). Default `"prevalent"`.

- data_source:

  `character(1)` or `NULL`. Citation for the epidemiology data, appended
  to outputs. Optional.

## Value

An object of class `bim_population`, which is a list containing:

- `annual`:

  A `data.frame` with columns `year`, `n_total_pop`,
  `n_prevalent_or_incident`, `n_diagnosed`, `n_treated`, `n_eligible`.

- `params`:

  A list of all input parameters.

- `meta`:

  A list with `indication`, `country`, `approach`, `data_source`.

## References

Sullivan SD, Mauskopf JA, Augustovski F et al. (2014). Budget impact
analysis–principles of good practice: report of the ISPOR 2012 Budget
Impact Analysis Good Practice II Task Force. *Value Health*, 17(1):5-14.
[doi:10.1016/j.jval.2013.08.2291](https://doi.org/10.1016/j.jval.2013.08.2291)

## See also

[`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md),
[`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md),
[`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)

## Examples

``` r
pop <- bim_population(
  indication     = "IgA Nephropathy",
  country        = "GB",
  years          = 1:5,
  prevalence     = 0.003,
  n_total_pop    = 42e6,
  diagnosed_rate = 0.60,
  treated_rate   = 0.45,
  eligible_rate  = 0.30
)
print(pop)
#> 
#> -- htaBIM Population --
#> 
#> Indication : IgA Nephropathy 
#> Country    : GB 
#> Approach   : prevalent 
#> Years      : 1 to 5 
#> 
#> Eligible patients:
#>   Year 1   : 10,206
#>    Year 2   : 10,206
#>    Year 3   : 10,206
#>    Year 4   : 10,206
#>    Year 5   : 10,206
summary(pop)
#> 
#> == Population Summary ==
#> Indication   : IgA Nephropathy
#> Country      : GB
#> Approach     : prevalent
#> 
#> Epidemiological funnel (Year 1):
#>   Total pop          : 4.2e+07
#>   Prevalent/incident : 126,000
#>   Diagnosed          : 75,600
#>   Treated            : 34,020
#>   Eligible           : 10,206
```
