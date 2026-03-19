# Run a probabilistic sensitivity analysis (PSA)

Performs a Monte Carlo PSA by repeatedly sampling uncertain parameters
from their assumed statistical distributions and re-running the budget
impact model for each draw. This produces a distribution of budget
impact outcomes that reflects joint parameter uncertainty.

**Distributional assumptions**

- Prevalence, diagnosed rate, treated rate, eligible rate — **Beta**
  distribution parameterised from the base-case value and a standard
  error.

- Drug cost — **LogNormal** distribution parameterised from the
  base-case value and a coefficient of variation (CV).

## Usage

``` r
bim_run_psa(
  model,
  n_sim = 1000L,
  prevalence_se = NULL,
  diagnosed_rate_se = NULL,
  treated_rate_se = NULL,
  eligible_rate_se = NULL,
  cost_cv = NULL,
  year = NULL,
  scenario = "base",
  seed = NULL
)
```

## Arguments

- model:

  A `bim_model` object (base case).

- n_sim:

  `integer(1)`. Number of Monte Carlo simulations. Default `1000L`.

- prevalence_se:

  `numeric(1)`. Standard error for prevalence. If `NULL` (default),
  prevalence is held fixed.

- diagnosed_rate_se:

  `numeric(1)` or `NULL`. SE for diagnosed rate.

- treated_rate_se:

  `numeric(1)` or `NULL`. SE for treated rate.

- eligible_rate_se:

  `numeric(1)` or `NULL`. SE for eligible rate.

- cost_cv:

  `numeric(1)` or `NULL`. Coefficient of variation applied to all drug
  costs simultaneously. If `NULL`, costs are held fixed.

- year:

  `integer(1)`. Budget impact year to summarise. Defaults to the last
  year in the model.

- scenario:

  `character(1)`. Scenario to use. Default `"base"`.

- seed:

  `integer(1)` or `NULL`. Random seed for reproducibility.

## Value

An object of class `bim_psa`: a list with elements:

- `simulations`:

  `data.frame` with one row per simulation: `sim`, `budget_impact`, and
  the sampled parameter values.

- `summary`:

  `data.frame` with mean, SD, median, and 95 \\ interval of budget
  impact.

- `year`:

  The year summarised.

- `scenario`:

  The scenario used.

- `n_sim`:

  Number of simulations run.

- `base_bi`:

  Base-case budget impact for reference.

## See also

[`bim_plot_psa()`](https://heorlytics.github.io/htaBIM/reference/bim_plot_psa.md),
[`bim_run_dsa()`](https://heorlytics.github.io/htaBIM/reference/bim_run_dsa.md)

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
  treatments = c("Drug C (SoC)", "Drug A (new)"),
  drug_costs = c("Drug C (SoC)" = 500, "Drug A (new)" = 25000)
)
model <- bim_model(pop, ms, costs)
set.seed(1)
psa <- bim_run_psa(model, n_sim = 200L, prevalence_se = 0.0005,
                   eligible_rate_se = 0.05, cost_cv = 0.10)
print(psa)
#> htaBIM Probabilistic Sensitivity Analysis
#>   Year: 5 | Scenario: base | Simulations: 200 / 200 converged
#>   Base-case budget impact: GBP 50,004,500
#> 
#>   PSA summary (budget impact):
#>     Mean:   GBP 50,289,917
#>     Median: GBP 48,436,316
#>     SD:     GBP 12,182,224
#>     95% CrI: GBP 32,535,003  to  GBP 73,741,327
```
